# Laedt die Haendler-Logos (Wikipedia-Seitenbilder bzw. direkte
# Wikimedia-Commons-Dateien) und konvertiert sie mit ffmpeg zu WebP nach
# assets/logos/<id>.webp. Neu ausfuehren, wenn eine Kette dazukommt.
#
#   powershell -File tool/fetch_retailer_logos.ps1
#
# Die Logos sind Marken der jeweiligen Unternehmen und werden nur zur
# Kennzeichnung des Haendlers in der App angezeigt.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$rawDir = Join-Path $root 'build\logo_fetch'
$outDir = Join-Path $root 'assets\logos'
New-Item -ItemType Directory -Force $rawDir | Out-Null
New-Item -ItemType Directory -Force $outDir | Out-Null

# Quellen je kanonischer Haendler-ID. Zwei Formen:
#   wiki   = Seitenbild eines Wikipedia-Artikels ('<sprache>:<titel>')
#   datei  = direkte Commons-Datei (SVG wird als PNG gerastert)
# Die Artikel-Seitenbilder sind nicht immer Logos (bei Rossmann kam ein
# Portraet, bei famila/Norma/Mueller Filialfotos), daher die Datei-Eintraege.
$sources = [ordered]@{
  'aldi-nord'       = @{ wiki = 'de:Aldi Nord' }        # kombiniertes Bild, wird unten zugeschnitten
  'aldi-sued'       = @{ wiki = 'de:Aldi Süd' }         # dito
  'citti'           = @{ datei = 'Citti-Logo.svg' }
  'dm'              = @{ wiki = 'de:Dm-drogerie markt' }
  'edeka'           = @{ wiki = 'de:Edeka' }
  'famila-nordost'  = @{ datei = 'Famila logo.svg' }
  'famila-nordwest' = @{ datei = 'Famila logo.svg' }
  'globus'          = @{ wiki = 'de:Globus Holding' }
  'hit'             = @{ wiki = 'de:HIT Handelsgruppe' }
  'kaufland'        = @{ wiki = 'de:Kaufland' }
  'lidl'            = @{ wiki = 'de:Lidl' }
  'mueller'         = @{ datei = 'Logo Drogerie Mueller.svg' }
  'netto'           = @{ wiki = 'de:Netto Marken-Discount' }
  'norma'           = @{ datei = 'Norma Logo.svg' }
  'penny'           = @{ wiki = 'en:Penny (supermarket)' }
  'rewe'            = @{ wiki = 'de:Rewe' }
  'rossmann'        = @{ datei = 'Rossmann Logo.svg' }
  'tegut'           = @{ wiki = 'de:Tegut' }
  'xxxlutz'         = @{ wiki = 'de:XXXLutz' }
}

$headers = @{ 'User-Agent' = 'ZuhausApp/1.0 (private Haushalts-App; Logo-Abruf; Kontakt: lokal)' }

# Wikimedia drosselt schnelle Abrufe (HTTP 429): zwischen Requests warten
# und bei Drosselung mit Pause erneut versuchen.
function Get-WithRetry([string]$Uri, [string]$OutFile) {
  for ($attempt = 1; $attempt -le 4; $attempt++) {
    try {
      Start-Sleep -Milliseconds 800
      if ($OutFile) {
        Invoke-WebRequest -Uri $Uri -Headers $headers -OutFile $OutFile
        return $true
      }
      return Invoke-RestMethod -Uri $Uri -Headers $headers
    } catch {
      if ($attempt -eq 4) { throw }
      Start-Sleep -Seconds (5 * $attempt)
    }
  }
}

$failed = @()
foreach ($id in $sources.Keys) {
  $raw = Join-Path $rawDir "$id.png"
  $spec = $sources[$id]
  try {
    if ($spec.datei) {
      $uri = 'https://commons.wikimedia.org/wiki/Special:FilePath/' +
        [uri]::EscapeDataString($spec.datei) + '?width=512'
      Get-WithRetry $uri $raw | Out-Null
      Write-Host "${id}: Commons $($spec.datei)"
    } else {
      $lang, $title = $spec.wiki -split ':', 2
      $uri = "https://$lang.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&pithumbsize=512&redirects=1&titles=" +
        [uri]::EscapeDataString($title)
      $json = Get-WithRetry $uri $null
      $page = $json.query.pages.PSObject.Properties.Value |
        Where-Object { $_.thumbnail } | Select-Object -First 1
      if (-not $page) { throw "kein Seitenbild fuer $title" }
      Get-WithRetry $page.thumbnail.source $raw | Out-Null
      Write-Host "${id}: $($spec.wiki) ($($page.thumbnail.width)x$($page.thumbnail.height))"
    }
  } catch {
    $failed += $id
    Write-Host "${id}: FEHLER $($_.Exception.Message)" -ForegroundColor Yellow
    continue
  }

  # PNG -> WebP, laengste Kante 256, verlustfrei (Logos sind Flaechen).
  # Die Aldi-Artikel tragen ein kombiniertes Bild (Nord links, Sued rechts),
  # das hier in die jeweilige Haelfte zugeschnitten wird.
  $out = Join-Path $outDir "$id.webp"
  $filter = switch ($id) {
    'aldi-nord' { "crop=250:283:0:0,scale='min(256,iw)':-2" }
    'aldi-sued' { "crop=254:283:258:0,scale='min(256,iw)':-2" }
    default     { "scale='min(256,iw)':-2" }
  }
  ffmpeg -y -loglevel error -i $raw -vf $filter -c:v libwebp -lossless 1 $out
}

if ($failed.Count -gt 0) {
  Write-Host "OHNE Logo geblieben: $($failed -join ', ')" -ForegroundColor Yellow
} else {
  Write-Host 'Alle Logos geladen.' -ForegroundColor Green
}
