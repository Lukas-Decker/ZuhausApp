# Prüft, ob sich das eingebaute Kotlin von AGP 9 inzwischen einschalten lässt.
#
#   powershell -File tool/check_kgp.ps1
#
# Warum ein echter Probebau und keine Suche in den Plugin-Dateien: Der
# Flutter-Gradle-Loader richtet Kotlin für jedes Plugin-Modul ein, unabhängig
# davon, ob das Plugin selbst Kotlin nutzt. Der Bau scheitert deshalb schon am
# ersten Plugin (zuletzt app_links, das nur Java-Quellen hat), während die
# Warnung von Flutter ganz andere Plugins nennt. Verlässlich ist nur: Flag
# umschalten und bauen.
#
# Das Skript setzt android/gradle.properties in jedem Fall wieder zurück.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$propsFile = Join-Path $root 'android\gradle.properties'
$original = [IO.File]::ReadAllText($propsFile)

if ($original -notmatch 'android\.builtInKotlin=false') {
  Write-Host 'android.builtInKotlin steht nicht auf false, nichts zu prüfen.'
  return
}

Write-Host 'Probebau mit android.builtInKotlin=true ...' -ForegroundColor Cyan
try {
  [IO.File]::WriteAllText(
    $propsFile,
    $original.Replace('android.builtInKotlin=false', 'android.builtInKotlin=true')
  )

  Push-Location $root
  try {
    # Debug-Bau für eine Prozessorart genügt: es geht nur darum, ob die
    # Gradle-Konfiguration durchläuft.
    $ausgabe = & flutter build apk --debug --target-platform android-arm64 2>&1
    $erfolg = $LASTEXITCODE -eq 0
  } finally {
    Pop-Location
  }
} finally {
  [IO.File]::WriteAllText($propsFile, $original)
}

if ($erfolg) {
  Write-Host 'Der Bau läuft mit eingebautem Kotlin durch.' -ForegroundColor Green
  Write-Host 'android.builtInKotlin kann dauerhaft auf true, siehe docs/android-kotlin.md.'
  exit 0
}

Write-Host 'Noch nicht möglich, der Bau bricht ab:' -ForegroundColor Yellow
$ausgabe |
  Select-String -Pattern 'KGP|kotlin\.android|Build file|no longer required' |
  Select-Object -First 6 |
  ForEach-Object { '  ' + $_.Line.Trim() }
Write-Host 'android.builtInKotlin bleibt auf false.'
# Eigener Code, damit ein Aufrufer "noch nicht so weit" von einem echten
# Skriptfehler unterscheiden kann.
exit 2
