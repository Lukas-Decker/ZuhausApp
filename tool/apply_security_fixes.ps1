<#
.SYNOPSIS
  Rollt die Sicherheitskorrekturen F1, F2 und F3 aus der OWASP-/IDOR-Pruefung
  aus (siehe docs/sicherheitspruefung-owasp-idor.md).

.DESCRIPTION
  Drei Schritte, einzeln abschaltbar:

    1. Datenbank (F1 + F3)
       Spielt supabase/migrations/0007_security_fixes.sql ein.
       Mit psql und einer Datenbank-URL laeuft das automatisch, sonst legt
       das Skript die Datei in die Zwischenablage und oeffnet den SQL Editor.

    2. Geheimnis (F2)
       Erzeugt bei Bedarf ein langes Zufallsgeheimnis und hinterlegt es als
       Function-Secret FCM_WEBHOOK_SECRET (Supabase CLI).

    3. Function (F2)
       Deployt notify-fcm neu, damit die Pflichtpruefung greift.

  WICHTIG nach Schritt 2 und 3: Im Dashboard unter Database -> Webhooks muss
  der Webhook auf public.household_events den Header

      x-webhook-secret: <das Geheimnis>

  mitgeben. Ohne diesen Header antwortet die Function mit 403 und es geht
  kein Push mehr raus. Das Skript zeigt das Geheimnis am Ende noch einmal an.

  Alles ist wiederholbar: die SQL-Datei nutzt "create or replace", das
  Setzen des Geheimnisses und das Deploy sind ohnehin idempotent.

.PARAMETER DatabaseUrl
  Verbindungs-URL der Datenbank fuer psql, z.B.
    postgresql://postgres.<ref>:<passwort>@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
  Im Dashboard unter Connect -> Connection string (Session pooler).
  Ohne Angabe wird die Umgebungsvariable SUPABASE_DB_URL genommen; fehlt auch
  die, geht Schritt 1 den Weg ueber die Zwischenablage.

.PARAMETER Secret
  Vorgegebenes Webhook-Geheimnis. Ohne Angabe wird eines erzeugt (32 Byte,
  base64url). Ein bereits gesetztes Geheimnis wird NICHT ueberschrieben,
  ausser mit -RotateSecret.

.PARAMETER RotateSecret
  Erneuert das Geheimnis, auch wenn schon eines gesetzt ist. Danach muss der
  Webhook-Header im Dashboard angepasst werden.

.PARAMETER SkipSql
  Schritt 1 auslassen (Datenbank bleibt unveraendert).

.PARAMETER SkipFunction
  Schritte 2 und 3 auslassen (Geheimnis und Function bleiben unveraendert).

.EXAMPLE
  ./tool/apply_security_fixes.ps1
  ./tool/apply_security_fixes.ps1 -DatabaseUrl 'postgresql://postgres...'
  ./tool/apply_security_fixes.ps1 -SkipSql -RotateSecret
#>
[CmdletBinding()]
param(
  [string]$DatabaseUrl = '',
  [string]$Secret = '',
  [switch]$RotateSecret,
  [switch]$SkipSql,
  [switch]$SkipFunction
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_konsole_utf8.ps1"

$root = Split-Path -Parent $PSScriptRoot
$sqlFile = Join-Path $root 'supabase/migrations/0007_security_fixes.sql'
$functionName = 'notify-fcm'

function Write-Step([string]$text) {
  Write-Host ''
  Write-Host "== $text" -ForegroundColor Cyan
}

function Test-Command([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# Projektkennung (z.B. eiomgepnimqviodsplaq) aus der Supabase-URL in env.json.
# Wird nur fuer die Dashboard-Links und das CLI-Deploy gebraucht.
function Get-ProjectRef {
  $envFile = Join-Path $root 'env.json'
  if (-not (Test-Path $envFile)) { return '' }
  try {
    $url = (Get-Content $envFile -Raw -Encoding UTF8 | ConvertFrom-Json).SUPABASE_URL
    if (-not $url) { return '' }
    return ([Uri]$url).Host.Split('.')[0]
  } catch {
    return ''
  }
}

function New-Secret {
  $bytes = [byte[]]::new(32)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
  return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

if (-not (Test-Path -LiteralPath $sqlFile)) {
  throw "Migration nicht gefunden: $sqlFile"
}

$projectRef = Get-ProjectRef
Write-Host 'Sicherheitskorrekturen F1, F2, F3' -ForegroundColor Green
if ($projectRef) { Write-Host "Projekt: $projectRef" }

# =========================================================================
# Schritt 1: Datenbank (F1 push_record, F3 upsert_device_token)
# =========================================================================

if ($SkipSql) {
  Write-Step 'Schritt 1 (Datenbank) uebersprungen.'
} else {
  Write-Step 'Schritt 1: Datenbank (F1 + F3)'

  if (-not $DatabaseUrl) { $DatabaseUrl = $env:SUPABASE_DB_URL }

  if ($DatabaseUrl -and (Test-Command 'psql')) {
    Write-Host 'Spiele 0007_security_fixes.sql ueber psql ein ...'
    # ON_ERROR_STOP: bei einem Fehler nicht stillschweigend weiterlaufen.
    & psql $DatabaseUrl -v ON_ERROR_STOP=1 -f $sqlFile
    if ($LASTEXITCODE -ne 0) {
      throw "psql ist mit Code $LASTEXITCODE ausgestiegen. Nichts wurde uebernommen."
    }
    Write-Host 'Datenbank aktualisiert.' -ForegroundColor Green
  } else {
    if ($DatabaseUrl) {
      Write-Host 'psql ist nicht installiert.' -ForegroundColor Yellow
    } else {
      Write-Host 'Keine Datenbank-URL (-DatabaseUrl oder SUPABASE_DB_URL).' -ForegroundColor Yellow
    }
    try {
      Get-Content -LiteralPath $sqlFile -Raw -Encoding UTF8 | Set-Clipboard
      Write-Host 'Das SQL liegt in der Zwischenablage.' -ForegroundColor Green
    } catch {
      Write-Host "Datei zum Einfuegen: $sqlFile" -ForegroundColor Yellow
    }
    if ($projectRef) {
      $editor = "https://supabase.com/dashboard/project/$projectRef/sql/new"
      Write-Host "SQL Editor: $editor"
      Start-Process $editor
    }
    Write-Host 'Dort einfuegen und ausfuehren, dann hier weiter.' -ForegroundColor Yellow
  }
}

# =========================================================================
# Schritt 2 und 3: Webhook-Geheimnis und Function (F2)
# =========================================================================

$effectiveSecret = ''

if ($SkipFunction) {
  Write-Step 'Schritte 2 und 3 (Function) uebersprungen.'
} elseif (-not (Test-Command 'supabase')) {
  Write-Step 'Schritte 2 und 3: Supabase CLI fehlt'
  Write-Host 'Ohne CLI von Hand:' -ForegroundColor Yellow
  Write-Host '  npm i -g supabase        (oder scoop install supabase)'
  Write-Host '  supabase secrets set FCM_WEBHOOK_SECRET=<Zufallswert>'
  Write-Host "  supabase functions deploy $functionName --no-verify-jwt"
} else {
  Write-Step 'Schritt 2: Webhook-Geheimnis (F2)'

  $alreadySet = $false
  try {
    $list = & supabase secrets list 2>&1 | Out-String
    $alreadySet = $list -match 'FCM_WEBHOOK_SECRET'
  } catch {
    Write-Host 'Vorhandene Geheimnisse nicht lesbar, setze neu.' -ForegroundColor Yellow
  }

  if ($alreadySet -and -not $RotateSecret) {
    Write-Host 'FCM_WEBHOOK_SECRET ist bereits gesetzt, bleibt unveraendert.'
    Write-Host 'Erneuern mit -RotateSecret.'
  } else {
    if (-not $Secret) { $Secret = New-Secret }
    & supabase secrets set "FCM_WEBHOOK_SECRET=$Secret"
    if ($LASTEXITCODE -ne 0) {
      throw "Geheimnis konnte nicht gesetzt werden (Code $LASTEXITCODE)."
    }
    $effectiveSecret = $Secret
    Write-Host 'Geheimnis gesetzt.' -ForegroundColor Green
  }

  Write-Step 'Schritt 3: Function neu deployen (F2)'
  # --no-verify-jwt bleibt: der Datenbank-Webhook bringt kein Nutzer-Token mit.
  # Die Pruefung uebernimmt jetzt das Geheimnis in der Function selbst.
  & supabase functions deploy $functionName --no-verify-jwt
  if ($LASTEXITCODE -ne 0) {
    throw "Deploy von $functionName fehlgeschlagen (Code $LASTEXITCODE)."
  }
  Write-Host 'Function ist aktiv.' -ForegroundColor Green
}

# =========================================================================
# Abschluss
# =========================================================================

Write-Step 'Fertig'

if ($effectiveSecret) {
  Write-Host ''
  Write-Host 'Neues Webhook-Geheimnis (jetzt notieren, es wird nicht erneut angezeigt):' -ForegroundColor Yellow
  Write-Host "  $effectiveSecret" -ForegroundColor White
  Write-Host ''
  Write-Host 'Noch von Hand im Dashboard eintragen:' -ForegroundColor Yellow
  Write-Host '  Database -> Webhooks -> Webhook auf public.household_events'
  Write-Host '  HTTP-Header ergaenzen bzw. anpassen:'
  Write-Host "    x-webhook-secret: $effectiveSecret"
  Write-Host ''
  Write-Host 'Bis dahin antwortet notify-fcm mit 403 und es geht kein Push raus.' -ForegroundColor Yellow
  if ($projectRef) {
    Write-Host "  https://supabase.com/dashboard/project/$projectRef/integrations/webhooks/overview"
  }
} else {
  Write-Host 'Kein neues Geheimnis erzeugt. Der Webhook-Header bleibt wie er ist.'
}

Write-Host ''
Write-Host 'Kurz gegenpruefen:' -ForegroundColor Cyan
Write-Host '  1. App starten, etwas aendern -> Abgleich laeuft weiterhin durch.'
Write-Host '  2. Ein Familien-Ereignis ausloesen -> Push kommt an.'
Write-Host '  3. curl -X POST <function-url> ohne Header -> 403.'
