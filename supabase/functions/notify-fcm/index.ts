// MultiApp v0.13: FCM-Push bei geschlossener App (nur Android).
//
// Wird per Datenbank-Webhook aufgerufen, sobald ein Datensatz in
// household_events entsteht. Ermittelt die Zielpersonen, liest deren
// FCM-Tokens und schickt den Push ueber die FCM HTTP v1 API.
//
// Einrichtung:
//   1. Firebase-Projekt anlegen, Cloud Messaging aktivieren.
//   2. Service-Account-JSON (Firebase Admin) erzeugen und als Function-Secret
//      hinterlegen:
//        supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service.json)"
//      Das gemeinsame Geheimnis fuer den Webhook ist PFLICHT (die Function
//      laeuft ohne JWT-Pruefung, siehe unten):
//        supabase secrets set FCM_WEBHOOK_SECRET=<langer Zufallswert>
//   3. Deploy: supabase functions deploy notify-fcm --no-verify-jwt
//   4. Im Dashboard unter Database -> Webhooks einen Webhook auf INSERT von
//      public.household_events anlegen, Ziel = diese Function, und den Header
//      x-webhook-secret = FCM_WEBHOOK_SECRET mitgeben. Ohne diesen Header
//      antwortet die Function mit 403 und verschickt nichts.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

/// Vergleicht zwei Geheimnisse in konstanter Zeit.
///
/// Ein normaler Stringvergleich bricht beim ersten falschen Zeichen ab; aus den
/// Laufzeitunterschieden laesst sich das Geheimnis sonst zeichenweise erraten.
function timingSafeEquals(actual: string | null, expected: string): boolean {
  if (actual === null) return false;
  const a = new TextEncoder().encode(actual);
  const b = new TextEncoder().encode(expected);
  // Ungleiche Laenge ist ohnehin falsch, wird aber trotzdem durchgerechnet.
  let diff = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    diff |= (a[i] ?? 0) ^ (b[i] ?? 0);
  }
  return diff === 0;
}

function base64Url(input: string | Uint8Array): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(body);
  const buffer = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buffer[i] = binary.charCodeAt(i);
  return buffer.buffer;
}

// Mintet ein OAuth2-Access-Token fuer die FCM-API aus dem Service-Account.
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(claim))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64Url(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) {
    throw new Error(`Token-Fehler: ${JSON.stringify(json)}`);
  }
  return json.access_token as string;
}

Deno.serve(async (req) => {
  // Webhook-Schutz. Die Function laeuft mit --no-verify-jwt, weil der
  // Datenbank-Webhook kein Nutzer-Token mitbringt; das gemeinsame Geheimnis ist
  // damit die EINZIGE Huerde und deshalb Pflicht. Fehlt es, wird nichts
  // gesendet: sonst koennte jeder, der die Function-URL kennt, eine Meldung mit
  // beliebigem Text an ein fremdes Geraet ausloesen.
  const expectedSecret = Deno.env.get("FCM_WEBHOOK_SECRET");
  if (!expectedSecret) {
    console.error(
      "FCM_WEBHOOK_SECRET fehlt. Push ist deaktiviert, bis das Geheimnis " +
        "gesetzt und im Webhook-Header x-webhook-secret hinterlegt ist.",
    );
    return new Response("not_configured", { status: 500 });
  }
  if (!timingSafeEquals(req.headers.get("x-webhook-secret"), expectedSecret)) {
    return new Response("forbidden", { status: 403 });
  }

  const saRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!saRaw) {
    console.error("FIREBASE_SERVICE_ACCOUNT fehlt.");
    return new Response("not_configured", { status: 200 });
  }

  try {
    const sa = JSON.parse(saRaw) as ServiceAccount;
    const payload = await req.json();
    const record = payload.record ?? payload;
    const householdId = record.household_id as string | undefined;
    const targetUserId = record.target_user_id as string | null | undefined;
    const createdBy = record.created_by as string | undefined;
    const title = (record.title as string) ?? "MultiApp";
    const body = (record.body as string) ?? "";
    if (!householdId) return new Response("no_household", { status: 200 });

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // Empfaenger bestimmen: gezielt oder alle Mitglieder ausser dem Ausloeser.
    let userIds: string[];
    if (targetUserId) {
      userIds = [targetUserId];
    } else {
      const { data: members } = await admin
        .from("household_members")
        .select("user_id")
        .eq("household_id", householdId);
      userIds = (members ?? [])
        .map((m: { user_id: string }) => m.user_id)
        .filter((id: string) => id !== createdBy);
    }
    if (userIds.length === 0) return new Response("no_recipients", { status: 200 });

    const { data: tokenRows } = await admin
      .from("device_tokens")
      .select("token")
      .in("user_id", userIds);
    const tokens = (tokenRows ?? []).map((r: { token: string }) => r.token);
    if (tokens.length === 0) return new Response("no_tokens", { status: 200 });

    const accessToken = await getAccessToken(sa);
    const endpoint =
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    let sent = 0;
    for (const token of tokens) {
      const res = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: { token, notification: { title, body } },
        }),
      });
      if (res.ok) {
        sent++;
      } else if (res.status === 404 || res.status === 400) {
        // Token ungueltig/abgelaufen: aufraeumen.
        await admin.from("device_tokens").delete().eq("token", token);
      }
    }

    return new Response(JSON.stringify({ sent }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("notify-fcm Fehler:", error);
    // 200, damit der Webhook nicht in eine Wiederholungsschleife laeuft.
    return new Response("error", { status: 200 });
  }
});
