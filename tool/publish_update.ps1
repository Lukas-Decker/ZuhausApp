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
  [switch]$Build
)

$ErrorActionPreference = 'Stop'

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

# Änderungen: Parameter, sonst dist/notes-<version>.txt, sonst der
# Abschnitt dieser Version aus CHANGELOG.md (alles zwischen der
# "## <version>"-Überschrift und der nächsten "## "-Überschrift).
if (-not $Notes) {
  $notesFile = Join-Path $distDir "notes-$version.txt"
  if (Test-Path $notesFile) {
    $Notes = (Get-Content $notesFile -Raw -Encoding UTF8).Trim()
  }
}
if (-not $Notes) {
  $changelog = Join-Path $root 'CHANGELOG.md'
  if (Test-Path $changelog) {
    $inSection = $false
    $lines = foreach ($line in Get-Content $changelog -Encoding UTF8) {
      if ($line -match '^##\s') {
        $inSection = $line -match ("^##\s+" + [regex]::Escape($version) + "(\s|$)")
        continue
      }
      if ($inSection) { $line }
    }
    $Notes = (($lines -join "`n")).Trim()
    if ($Notes) {
      Write-Host "Änderungen aus CHANGELOG.md ($version) übernommen."
    } else {
      Write-Warning "CHANGELOG.md hat keinen Abschnitt für $version."
    }
  }
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
  throw "Nichts zu veroeffentlichen. Erst bauen: ./tool/package.ps1"
}

foreach ($upload in $uploads) {
  # Lieber vorher klar sagen als hinterher ein 413 vom Server.
  $mb = (Get-Item -LiteralPath $upload[0]).Length / 1MB
  if ($mb -gt 50) {
    throw ("{0} ist {1} MB gross. Supabase Storage nimmt im Free-Plan " +
      "hoechstens 50 MB je Datei.") -f $upload[1], [math]::Round($mb, 1)
  }
  Send-StorageObject -Path $upload[0] -Name $upload[1] -ContentType $upload[2] `
    -BaseUrl $baseUrl -Key $ServiceKey
}

# Manifest zuletzt, damit nie eine Version angekuendigt wird, deren Datei noch
# fehlt. UTF-8 ohne BOM, sonst stolpert der JSON-Leser ueber die Umlaute.
$manifestPath = Join-Path $distDir 'manifest.json'
$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Send-StorageObject -Path $manifestPath -Name 'manifest.json' -ContentType 'application/json' `
  -BaseUrl $baseUrl -Key $ServiceKey -CacheControl 'max-age=60'

Write-Host ""
Write-Host "Veroeffentlicht:" -ForegroundColor Magenta
Write-Host $json
Write-Host ""
Write-Host "Manifest: $publicBase/manifest.json" -ForegroundColor DarkGray
