// MultiApp v0.12: Kontoloeschung (DSGVO Recht auf Loeschung).
//
// Loescht das Konto des aufrufenden Nutzers endgueltig, inklusive aller
// personenbezogenen Serverdaten. Wird vom Client ueber
// supabase.functions.invoke('delete-account') aufgerufen.
//
// Ablauf:
//   1. Nutzer aus dem mitgeschickten JWT ermitteln.
//   2. Ist der Nutzer Eigentuemer eines Haushalts mit weiteren Mitgliedern,
//      wird abgelehnt (409): er muss die Eigentuemerschaft erst uebergeben,
//      sonst wuerden fremde Daten mitgeloescht.
//   3. sync_records des privaten Scopes und der allein besessenen Haushalte
//      loeschen (die haengen nicht per Fremdschluessel am Nutzer).
//   4. Auth-Nutzer loeschen. Haushalte (owner), Mitgliedschaften und
//      Familien-Ereignisse haengen per ON DELETE CASCADE und verschwinden mit.
//
// Deploy: supabase functions deploy delete-account
// (Service-Role-Key steht in Edge Functions automatisch zur Verfuegung.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "");
  if (!jwt) {
    return new Response(JSON.stringify({ error: "not_authenticated" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // 1. Aufrufer aus dem JWT bestimmen.
  const { data: userData, error: userError } = await admin.auth.getUser(jwt);
  const user = userData?.user;
  if (userError || !user) {
    return new Response(JSON.stringify({ error: "not_authenticated" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }
  const uid = user.id;

  try {
    // 2. Eigentuemerschaft pruefen.
    const { data: ownedRows, error: ownedError } = await admin
      .from("households")
      .select("id, name")
      .eq("owner_user_id", uid);
    if (ownedError) throw ownedError;

    const owned = ownedRows ?? [];
    const soloOwnedIds: string[] = [];
    const blocking: string[] = [];

    for (const h of owned) {
      const { count, error: countError } = await admin
        .from("household_members")
        .select("id", { count: "exact", head: true })
        .eq("household_id", h.id);
      if (countError) throw countError;
      if ((count ?? 0) > 1) {
        blocking.push(h.name as string);
      } else {
        soloOwnedIds.push(h.id as string);
      }
    }

    if (blocking.length > 0) {
      return new Response(
        JSON.stringify({ error: "owner_transfer_required", households: blocking }),
        { status: 409, headers: jsonHeaders },
      );
    }

    // 3. sync_records ohne Fremdschluessel-Bezug explizit loeschen.
    const { error: personalError } = await admin
      .from("sync_records")
      .delete()
      .eq("scope_kind", "personal")
      .eq("scope_id", uid);
    if (personalError) throw personalError;

    if (soloOwnedIds.length > 0) {
      const { error: householdError } = await admin
        .from("sync_records")
        .delete()
        .eq("scope_kind", "household")
        .in("scope_id", soloOwnedIds);
      if (householdError) throw householdError;
    }

    // 4. Auth-Nutzer loeschen; der Rest kaskadiert (Haushalte, Mitglieder,
    //    Ereignisse).
    const { error: deleteError } = await admin.auth.admin.deleteUser(uid);
    if (deleteError) throw deleteError;

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: jsonHeaders,
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: `${error?.message ?? error}` }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
