<#
.SYNOPSIS
  Baut die App und legt die Artefakte unter dist/ ab:
    dist/Windows-<version>.zip   (gezippter Release-Ordner)
    dist/Android-<version>.apk   (Release-APK)

.DESCRIPTION
  Die Version wird aus pubspec.yaml gelesen (ohne Build-Nummer nach dem +).
  Liegt eine env.json im Projekt-Root, wird sie per
  --dart-define-from-file an den Build weitergereicht, damit Supabase im
  fertigen Build konfiguriert ist.

.PARAMETER Target
  Was gebaut wird: 'windows', 'android' oder 'all' (Standard).

.PARAMETER SkipBuild
  Ueberspringt 'flutter build' und verpackt nur die bereits vorhandenen
  Build-Ausgaben (praktisch beim erneuten Zippen).

.EXAMPLE
  ./tool/package.ps1
  ./tool/package.ps1 -Target windows
  ./tool/package.ps1 -Target android -SkipBuild
#>
[CmdletBinding()]
param(
  [ValidateSet('all', 'windows', 'android')]
  [string]$Target = 'all',
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

# Projekt-Root ist der Ordner ueber tool/.
$root = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $root 'dist'

function Get-AppVersion {
  $pubspec = Join-Path $root 'pubspec.yaml'
  $line = Select-String -Path $pubspec -Pattern '^version:\s*(.+)$' | Select-Object -First 1
  if (-not $line) { throw "Keine version in pubspec.yaml gefunden." }
  # 0.11.0+18 -> 0.11.0
  return $line.Matches[0].Groups[1].Value.Trim().Split('+')[0]
}

function Get-DefineArgs {
  $envFile = Join-Path $root 'env.json'
  if (Test-Path $envFile) {
    Write-Host "env.json gefunden, wird in den Build uebernommen." -ForegroundColor DarkGray
    return @("--dart-define-from-file=env.json")
  }
  Write-Host "Keine env.json, Build laeuft im Gastmodus (ohne Supabase)." -ForegroundColor Yellow
  return @()
}

function Invoke-Flutter {
  param([string[]]$FlutterArgs)
  Write-Host "flutter $($FlutterArgs -join ' ')" -ForegroundColor Cyan
  & flutter @FlutterArgs
  if ($LASTEXITCODE -ne 0) { throw "flutter build fehlgeschlagen (Exit $LASTEXITCODE)." }
}

function New-WindowsPackage {
  param([string]$Version, [string[]]$DefineArgs)

  if (-not $SkipBuild) {
    Invoke-Flutter (@('build', 'windows', '--release') + $DefineArgs)
  }

  # Ausgabepfad haengt von der Flutter-Version ab; beide Varianten pruefen.
  $candidates = @(
    (Join-Path $root 'build/windows/x64/runner/Release'),
    (Join-Path $root 'build/windows/runner/Release')
  )
  $releaseDir = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $releaseDir) {
    throw "Windows-Release-Ordner nicht gefunden. Erst bauen (ohne -SkipBuild)."
  }

  $zip = Join-Path $distDir "Windows-$Version.zip"
  if (Test-Path $zip) { Remove-Item $zip -Force }
  Write-Host "Packe $releaseDir -> $zip" -ForegroundColor Green
  Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zip -CompressionLevel Optimal
}

function New-AndroidPackage {
  param([string]$Version, [string[]]$DefineArgs)

  if (-not $SkipBuild) {
    Invoke-Flutter (@('build', 'apk', '--release') + $DefineArgs)
  }

  $apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
  if (-not (Test-Path $apk)) {
    throw "APK nicht gefunden ($apk). Erst bauen (ohne -SkipBuild)."
  }

  $dest = Join-Path $distDir "Android-$Version.apk"
  if (Test-Path $dest) { Remove-Item $dest -Force }
  Write-Host "Kopiere APK -> $dest" -ForegroundColor Green
  Copy-Item $apk $dest -Force
}

$version = Get-AppVersion
$defineArgs = Get-DefineArgs
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Write-Host "MultiApp $version -> $distDir" -ForegroundColor Magenta

if ($Target -in @('all', 'windows')) { New-WindowsPackage -Version $version -DefineArgs $defineArgs }
if ($Target -in @('all', 'android')) { New-AndroidPackage -Version $version -DefineArgs $defineArgs }

Write-Host "Fertig. Inhalt von dist/:" -ForegroundColor Magenta
Get-ChildItem $distDir | Format-Table Name, @{Name='MB'; Expression={ [math]::Round($_.Length / 1MB, 1) }}, LastWriteTime
