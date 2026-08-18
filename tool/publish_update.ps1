<#
.SYNOPSIS
  Veroeffentlicht die Pakete aus dist/ im eigenen Update-Kanal
  (oeffentlicher Supabase-Storage-Bucket "releases").

.DESCRIPTION
  Laedt hoch:
    Android-<version>-<abi>.apk   (je Prozessorart eine)
    Windows-<version>.zip
    manifest.json   (Version, Pflichtversion, Aenderungen, Pruefsummen)

  Android wird pro Prozessorart gebaut: eine APK fuer alles waere ueber
  80 MB und damit groesser als das Upload-Limit des Free-Plans (50 MB).
  Das Manifest fuehrt alle auf, das Geraet nimmt die passende.

  Die App fragt manifest.json ab, vergleicht mit ihrer eigenen Version und
  bietet das Update an. Die Version kommt aus pubspec.yaml.

  Nach dem Hochladen holt das Skript jede Datei ueber die oeffentliche URL
  zurueck und vergleicht Groesse und SHA-256 mit dem Original. Erst wenn das
  fuer alle Pakete und das Manifest stimmt, wird alles Aeltere aus dem Bucket
  geloescht - der Speicher im Free-Plan ist knapp. -KeepOld laesst die alten
  Dateien liegen.

  Zum Hochladen wird ein geheimer Schluessel gebraucht, der die
  Zugriffsregeln umgeht. Im Dashboard unter Settings -> API Keys:

    - neu:    "Secret keys" -> sb_secret_...   (ggf. erst anlegen)
    - alt:    Tab "Legacy API keys" -> service_role (JWT, eyJ...)

  Beides funktioniert. Der Schluessel darf NIE in die App, in env.json oder
  ins Repo. Er kommt aus der Umgebungsvariable SUPABASE_SECRET_KEY bzw.
  SUPABASE_SERVICE_KEY oder aus dem Parameter -ServiceKey.

.PARAMETER Notes
  Aenderungen dieser Version, eine Zeile pro Punkt. Ohne Angabe wird
  dist/notes-<version>.txt gelesen, falls vorhanden; sonst der Abschnitt
  der Version aus CHANGELOG.md. Das Changelog ist der Normalweg, der
  Parameter nur noch der Ausnahme-Override.

.PARAMETER MinVersion
  Kleinste noch erlaubte Version. Wer darunter liegt, bekommt ein
  Pflicht-Update. Ohne Angabe bleibt der Wert des bisherigen Manifests.

.PARAMETER Build
  Vorher tool/package.ps1 laufen lassen.

.PARAMETER KeepOld
  Nicht aufraeumen: die Dateien aelterer Versionen bleiben im Bucket.

.EXAMPLE
  $env:SUPABASE_SECRET_KEY = 'sb_secret_...'
  ./tool/publish_update.ps1 -Notes "Live-Updates eingebaut"
  ./tool/publish_update.ps1 -Build -MinVersion 0.20.0
#>
[CmdletBinding()]
param(
  [string]$Notes = '',
  [string]$MinVersion = '',
  [string]$ServiceKey = '',
  [string]$SupabaseUrl = '',
  [switch]$Build,
  [switch]$KeepOld
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\_konsole_utf8.ps1"

$root = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $root 'dist'
$bucket = 'releases'

function Get-AppVersion {
  $pubspec = Join-Path $root 'pubspec.yaml'
  $line = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' | Select-Object -First 1
  if (-not $line) { throw "Keine version in pubspec.yaml gefunden." }
  return $line.Matches[0].Groups[1].Value.Trim().Split('+')[0]
}

function Get-SupabaseUrl {
  if ($SupabaseUrl) { $raw = $SupabaseUrl }
  else {
    $envFile = Join-Path $root 'env.json'
    if (-not (Test-Path $envFile)) {
      throw "Keine env.json gefunden. Supabase-URL mit -SupabaseUrl angeben."
    }
    $raw = (Get-Content $envFile -Raw -Encoding UTF8 | ConvertFrom-Json).SUPABASE_URL
  }
  if (-not $raw) { throw "SUPABASE_URL ist leer." }
  $uri = [Uri]$raw
  return "$($uri.Scheme)://$($uri.Host)"
}

function New-AssetInfo {
  param([string]$Path, [string]$PublicBase)
  $file = Get-Item -LiteralPath $Path
  $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
  return [ordered]@{
    url    = "$PublicBase/$($file.Name)"
    file   = $file.Name
    size   = [int64]$file.Length
    sha256 = $hash
  }
}

function Send-StorageObject {
  param(
    [string]$Path,
    [string]$Name,
    [string]$ContentType,
    [string]$BaseUrl,
    [string]$Key,
    [string]$CacheControl = 'max-age=3600'
  )
  $url = "$BaseUrl/storage/v1/object/$bucket/$Name"
  $sizeMb = [math]::Round((Get-Item -LiteralPath $Path).Length / 1MB, 1)
  Write-Host "Lade hoch: $Name ($sizeMb MB)" -ForegroundColor Green
  # apikey UND Authorization mit demselben Wert: der alte service_role-JWT
  # braucht Authorization, die neuen sb_secret_-Schluessel den apikey-Header
  # (und dulden Authorization nur, wenn er exakt gleich lautet).
  $headers = @{
    'apikey'        = $Key
    Authorization   = "Bearer $Key"
    'x-upsert'      = 'true'
    'cache-control' = $CacheControl
  }
  try {
    Invoke-WebRequest -Uri $url -Method Post -Headers $headers `
      -ContentType $ContentType -InFile $Path -UseBasicParsing | Out-Null
  } catch {
    $detail = $_.Exception.Message
    if ($_.ErrorDetails) { $detail = $_.ErrorDetails.Message }
    throw "Upload von $Name fehlgeschlagen: $detail"
  }
}

function Get-PublishedManifest {
  param([string]$PublicBase)
  try {
    return Invoke-RestMethod -Uri "$PublicBase/manifest.json?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -UseBasicParsing
  } catch {
    return $null
  }
}

function Test-UploadedObject {
  <#
    Holt die Datei ueber die oeffentliche URL zurueck und stellt sie gegen das
    Original: erst die Byte-Groesse, dann SHA-256. Der Zeitstempel in der URL
    umgeht den Cache, damit wirklich das geprueft wird, was im Bucket liegt.
    Stimmt etwas nicht, fliegt eine Ausnahme - der Aufrufer bricht dann ab,
    bevor irgendetwas geloescht wird.
  #>
  param(
    [string]$Path,
    [string]$Name,
    [string]$PublicBase
  )
  $local = Get-Item -LiteralPath $Path
  $expectedHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
  $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) `
    ("zuhaus-verify-{0}.tmp" -f [guid]::NewGuid().ToString('n'))
  $url = "$PublicBase/$Name" + "?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
  $sizeMb = [math]::Round($local.Length / 1MB, 1)
  Write-Host "Pruefe: $Name ($sizeMb MB)" -ForegroundColor Cyan
  $vorherigerFortschritt = $ProgressPreference
  $ProgressPreference = 'SilentlyContinue'
  try {
    try {
      Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing
    } catch {
      $detail = $_.Exception.Message
      if ($_.ErrorDetails) { $detail = $_.ErrorDetails.Message }
      throw "$Name laesst sich nicht wieder herunterladen: $detail"
    }
    $remote = Get-Item -LiteralPath $tempFile
    if ($remote.Length -ne $local.Length) {
      throw ("{0} liegt unvollstaendig im Bucket: {1} statt {2} Bytes." -f `
          $Name, $remote.Length, $local.Length)
    }
    $remoteHash = (Get-FileHash -LiteralPath $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($remoteHash -ne $expectedHash) {
      throw ("{0} stimmt nicht mit dem Original ueberein: SHA-256 {1} statt {2}." -f `
          $Name, $remoteHash, $expectedHash)
    }
  } finally {
    $ProgressPreference = $vorherigerFortschritt
    if (Test-Path -LiteralPath $tempFile) {
      Remove-Item -LiteralPath $tempFile -Force
    }
  }
}

function Get-StorageObjectNames {
  <#
    Listet den Bucket seitenweise auf. Ordner-Eintraege (ohne id) und
    Platzhalter mit fuehrendem Punkt bleiben aussen vor.
  #>
  param([string]$BaseUrl, [string]$Key)
  $headers = @{ 'apikey' = $Key; Authorization = "Bearer $Key" }
  $seitengroesse = 100
  $offset = 0
  $namen = @()
  while ($true) {
    $body = @{
      prefix = ''
      limit  = $seitengroesse
      offset = $offset
      sortBy = @{ column = 'name'; order = 'asc' }
    } | ConvertTo-Json
    try {
      $antwort = Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/list/$bucket" -Method Post `
        -Headers $headers -ContentType 'application/json' -Body $body -UseBasicParsing
    } catch {
      $detail = $_.Exception.Message
      if ($_.ErrorDetails) { $detail = $_.ErrorDetails.Message }
      throw "Bucket-Inhalt laesst sich nicht lesen: $detail"
    }
    # PowerShell 7 reicht die JSON-Liste als ein einziges Element durch,
    # @() macht daraus kein flaches Array. += packt sie sauber aus, und in
    # Windows PowerShell 5.1 (dort kommt sie schon flach) stimmt es auch.
    $seite = @()
    if ($null -ne $antwort) { $seite += $antwort }
    if ($seite.Count -eq 0) { break }
    foreach ($eintrag in $seite) {
      if (-not $eintrag.id) { continue }
      if ($eintrag.name.StartsWith('.')) { continue }
      $namen += $eintrag.name
    }
    if ($seite.Count -lt $seitengroesse) { break }
    $offset += $seitengroesse
  }
  return $namen
}

function Remove-StorageObjects {
  <#
    Loescht die genannten Objekte, in Haeppchen von 50. Das JSON wird von Hand
    gebaut: ConvertTo-Json macht aus einem einelementigen Array eine
    Zeichenkette, und die nimmt Supabase nicht an.
  #>
  param([string[]]$Names, [string]$BaseUrl, [string]$Key)
  $headers = @{ 'apikey' = $Key; Authorization = "Bearer $Key" }
  for ($i = 0; $i -lt $Names.Count; $i += 50) {
    $ende = [math]::Min($i + 49, $Names.Count - 1)
    $teil = @($Names[$i..$ende])
    $eintraege = ($teil | ForEach-Object { ConvertTo-Json -InputObject $_ }) -join ','
    $body = "{""prefixes"":[$eintraege]}"
    try {
      Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/$bucket" -Method Delete `
        -Headers $headers -ContentType 'application/json' -Body $body -UseBasicParsing | Out-Null
    } catch {
      $detail = $_.Exception.Message
      if ($_.ErrorDetails) { $detail = $_.ErrorDetails.Message }
      throw "Aufraeumen fehlgeschlagen: $detail"
    }
  }
}

if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SECRET_KEY }
if (-not $ServiceKey) { $ServiceKey = $env:SUPABASE_SERVICE_KEY }
if (-not $ServiceKey) {
  throw @"
Kein geheimer Schluessel gesetzt. Im Dashboard unter Settings -> API Keys:
  - Tab "Legacy API keys" -> service_role (eyJ...), oder
  - "Secret keys" -> sb_secret_... (ggf. erst anlegen)
Dann: `$env:SUPABASE_SECRET_KEY = '...'   (oder -ServiceKey '...')
"@
}

$version = Get-AppVersion
$baseUrl = Get-SupabaseUrl
$publicBase = "$baseUrl/storage/v1/object/public/$bucket"

Write-Host "Zuhaus $version -> $publicBase" -ForegroundColor Magenta

if ($Build) {
  & (Join-Path $PSScriptRoot 'package.ps1')
  if ($LASTEXITCODE -ne 0) { throw "package.ps1 fehlgeschlagen." }
}

$abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')
$zipPath = Join-Path $distDir "Windows-$version.zip"

$manifest = [ordered]@{
  latestVersion = $version
  publishedAt   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

# Pflichtversion: Parameter schlaegt den bisherigen Wert, sonst bleibt er.
$published = Get-PublishedManifest -PublicBase $publicBase
if ($MinVersion) {
  $manifest['minVersion'] = $MinVersion
} elseif ($published -and $published.minVersion) {
  $manifest['minVersion'] = $published.minVersion
}

# Changelog: alle Versionsabschnitte aus CHANGELOG.md ins Manifest legen.
# Die App zeigt daraus genau die Abschnitte, die neuer sind als die
# installierte Version - wer mehrere Updates übersprungen hat, sieht alles.
$changelogFile = Join-Path $root 'CHANGELOG.md'
$entries = @()
if (Test-Path $changelogFile) {
  $lines = @(Get-Content $changelogFile -Encoding UTF8)
  # Zeilennummern der Versions-Überschriften einsammeln, dann die Blöcke
  # dazwischen als Änderungstext nehmen.
  $heads = @()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^##\s+v?(\d+\.\d+(?:\.\d+)?)\s*(?:[-–]\s*(\d{4}-\d{2}-\d{2}))?\s*$') {
      $heads += , @{ index = $i; version = $Matches[1]; date = $Matches[2] }
    }
  }
  for ($h = 0; $h -lt $heads.Count; $h++) {
    $from = $heads[$h].index + 1
    $to = if ($h + 1 -lt $heads.Count) { $heads[$h + 1].index - 1 } else { $lines.Count - 1 }
    if ($to -lt $from) { continue }
    $text = (($lines[$from..$to] -join "`n")).Trim()
    if (-not $text) { continue }
    $entry = [ordered]@{ version = $heads[$h].version; notes = $text }
    if ($heads[$h].date) { $entry['date'] = $heads[$h].date }
    $entries += , $entry
  }
}

if ($entries.Count -gt 0) {
  $manifest['changelog'] = $entries
  Write-Host "$($entries.Count) Changelog-Abschnitte übernommen."
  if (-not ($entries | Where-Object { $_.version -eq $version })) {
    Write-Warning "CHANGELOG.md hat keinen Abschnitt für $version."
  }
}

# notes: Änderungen der neuesten Version. Parameter schlägt
# dist/notes-<version>.txt, sonst der passende Changelog-Abschnitt.
# Bleibt erhalten, damit ältere App-Versionen weiterhin etwas anzeigen.
if (-not $Notes) {
  $notesFile = Join-Path $distDir "notes-$version.txt"
  if (Test-Path $notesFile) {
    $Notes = (Get-Content $notesFile -Raw -Encoding UTF8).Trim()
  }
}
if (-not $Notes) {
  $match = $entries | Where-Object { $_.version -eq $version } | Select-Object -First 1
  if ($match) { $Notes = $match.notes }
}
if ($Notes) { $manifest['notes'] = $Notes }

$uploads = @()

# Android: je Prozessorart eine APK, im Manifest unter ihrem ABI-Namen.
$android = [ordered]@{}
foreach ($abi in $abis) {
  $name = "Android-$version-$abi.apk"
  $path = Join-Path $distDir $name
  if (-not (Test-Path $path)) { continue }
  $android[$abi] = New-AssetInfo -Path $path -PublicBase $publicBase
  $uploads += , @($path, $name, 'application/vnd.android.package-archive')
}
if ($android.Count -gt 0) {
  $manifest['android'] = $android
} else {
  Write-Host "Keine Android-Pakete in dist/ - Android bekommt kein Update angeboten." -ForegroundColor Yellow
}
if (Test-Path $zipPath) {
  $manifest['windows'] = New-AssetInfo -Path $zipPath -PublicBase $publicBase
  $uploads += , @($zipPath, "Windows-$version.zip", 'application/zip')
} else {
  Write-Host "Kein Windows-Paket in dist/ - Windows bekommt kein Update angeboten." -ForegroundColor Yellow
}
if ($uploads.Count -eq 0) {
  throw "Nichts zu veröffentlichen. Erst bauen: ./tool/package.ps1"
}

foreach ($upload in $uploads) {
  # Lieber vorher klar sagen als hinterher ein 413 vom Server.
  $mb = (Get-Item -LiteralPath $upload[0]).Length / 1MB
  if ($mb -gt 50) {
    throw ("{0} ist {1} MB groß. Supabase Storage nimmt im Free-Plan " +
      "hoechstens 50 MB je Datei.") -f $upload[1], [math]::Round($mb, 1)
  }
  Send-StorageObject -Path $upload[0] -Name $upload[1] -ContentType $upload[2] `
    -BaseUrl $baseUrl -Key $ServiceKey
}

# Erst nachweisen, dann ankuendigen: jedes Paket kommt ueber die oeffentliche
# URL zurueck und muss in Groesse und SHA-256 dem Original entsprechen.
Write-Host ""
Write-Host "Prüfe die hochgeladenen Pakete..." -ForegroundColor Magenta
foreach ($upload in $uploads) {
  Test-UploadedObject -Path $upload[0] -Name $upload[1] -PublicBase $publicBase
}

# Manifest zuletzt, damit nie eine Version angekuendigt wird, deren Datei noch
# fehlt. UTF-8 ohne BOM, sonst stolpert der JSON-Leser ueber die Umlaute.
# Minifiert: die App holt das Manifest alle sechs Stunden, Einrueckung bringt
# ihr nichts. Auf der Konsole steht weiter die lesbare Fassung.
$manifestPath = Join-Path $distDir 'manifest.json'
$json = $manifest | ConvertTo-Json -Depth 5 -Compress
$jsonLesbar = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Send-StorageObject -Path $manifestPath -Name 'manifest.json' -ContentType 'application/json' `
  -BaseUrl $baseUrl -Key $ServiceKey -CacheControl 'max-age=60'

Test-UploadedObject -Path $manifestPath -Name 'manifest.json' -PublicBase $publicBase

# Aufraeumen. Jetzt liegt nachweislich alles vollstaendig oben, also fliegt
# raus, was nicht zur neuen Version gehoert: der Speicher im Free-Plan ist
# knapp, und alte Pakete braucht niemand mehr - die App laedt immer die
# Version aus dem Manifest.
if ($KeepOld) {
  Write-Host ""
  Write-Host "-KeepOld gesetzt: ältere Dateien bleiben im Bucket liegen." -ForegroundColor Yellow
} else {
  $behalten = @('manifest.json')
  foreach ($upload in $uploads) { $behalten += $upload[1] }
  $veraltet = @(Get-StorageObjectNames -BaseUrl $baseUrl -Key $ServiceKey |
      Where-Object { $behalten -notcontains $_ })
  Write-Host ""
  if ($veraltet.Count -eq 0) {
    Write-Host "Nichts aufzuräumen, im Bucket liegt nur $version." -ForegroundColor DarkGray
  } else {
    Write-Host "Lösche $($veraltet.Count) Datei(en) älterer Versionen:" -ForegroundColor Magenta
    foreach ($name in $veraltet) { Write-Host "  - $name" }
    Remove-StorageObjects -Names $veraltet -BaseUrl $baseUrl -Key $ServiceKey
    $rest = @(Get-StorageObjectNames -BaseUrl $baseUrl -Key $ServiceKey |
        Where-Object { $behalten -notcontains $_ })
    if ($rest.Count -gt 0) {
      Write-Warning "Diese Dateien liegen weiterhin im Bucket: $($rest -join ', ')"
    } else {
      Write-Host "Bucket aufgeräumt." -ForegroundColor Green
    }
  }
}

Write-Host ""
Write-Host "Veröffentlicht:" -ForegroundColor Magenta
Write-Host $jsonLesbar
Write-Host ""
Write-Host "Manifest: $publicBase/manifest.json" -ForegroundColor DarkGray
