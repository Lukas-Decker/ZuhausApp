import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/diagnostics/debug_log.dart';
import '../domain/release_manifest.dart';
import 'update_service.dart';

/// Laedt das Paket herunter und uebergibt es dem Betriebssystem.
///
/// Android bekommt die APK ueber den System-Installer (wie bei Telegram);
/// Windows kann sich nicht selbst ueberschreiben, waehrend es laeuft, deshalb
/// entpacken wir daneben und lassen ein kleines Skript nach dem Beenden
/// tauschen und neu starten.
class UpdateInstaller {
  UpdateInstaller({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const MethodChannel _channel = MethodChannel(
    'de.lukas.multiapp/installer',
  );

  /// Nur Android und Windows bekommen Pakete vom eigenen Server.
  bool get isSupported => Platform.isAndroid || Platform.isWindows;

  /// Prozessorarten des Geraets, beste zuerst (z. B. arm64-v8a, armeabi-v7a).
  ///
  /// Auf allem ausser Android leer: dort gibt es nur ein Paket.
  Future<List<String>> supportedAbis() async {
    if (!Platform.isAndroid) return const [];
    try {
      final abis = await _channel.invokeListMethod<String>('supportedAbis');
      return abis ?? const [];
    } on PlatformException catch (error) {
      DebugLog.instance.add(
        'update',
        'supportedAbis: $error',
        level: LogLevel.error,
      );
      // Aeltere Builds ohne diese Kanal-Methode: die mit Abstand
      // haeufigste Prozessorart annehmen.
      return const ['arm64-v8a'];
    }
  }

  /// Auf Android muss "Unbekannte Apps installieren" fuer diese App erlaubt
  /// sein. Vor Android 8 gilt das als globale Systemeinstellung.
  Future<bool> canInstall() async {
    if (!Platform.isAndroid) return isSupported;
    try {
      return await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
    } on PlatformException catch (error) {
      DebugLog.instance.add(
        'update',
        'canInstallPackages: $error',
        level: LogLevel.error,
      );
      return false;
    }
  }

  /// Oeffnet die Systemeinstellung, in der die Erlaubnis erteilt wird.
  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openInstallPermissionSettings');
    } on PlatformException catch (error) {
      DebugLog.instance.add(
        'update',
        'Einstellung: $error',
        level: LogLevel.error,
      );
    }
  }

  /// Laedt die Datei in den Zwischenspeicher und meldet den Fortschritt.
  ///
  /// Ist die Datei schon vollstaendig und mit passender Pruefsumme vorhanden,
  /// wird sie wiederverwendet (praktisch nach einem Abbruch).
  Future<File> download(
    ReleaseAsset asset, {
    required void Function(int received, int total) onProgress,
  }) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final target = File('${dir.path}/${asset.fileName}');

    if (target.existsSync() && await _isReusable(target, asset)) {
      final size = await target.length();
      onProgress(size, size);
      return target;
    }

    final partial = File('${target.path}.part');
    if (partial.existsSync()) partial.deleteSync();

    final response = await _client
        .send(http.Request('GET', asset.url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw UpdateException(
        'Download fehlgeschlagen (HTTP ${response.statusCode}).',
      );
    }

    final total = asset.sizeBytes ?? response.contentLength ?? 0;
    var received = 0;
    final sink = partial.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (!await _matchesChecksum(partial, asset.sha256)) {
      // Der Rest bleibt nicht liegen: sonst wuerde er beim naechsten Versuch
      // vielleicht als fertig durchgehen.
      partial.deleteSync();
      throw const UpdateException(
        'Prüfsumme stimmt nicht, Download verworfen.',
      );
    }

    if (target.existsSync()) target.deleteSync();
    await partial.rename(target.path);
    return target;
  }

  /// Uebergibt die geladene Datei an das System.
  ///
  /// Auf Windows beendet sich die App dabei selbst; der Aufrufer bekommt
  /// dort keine Rueckkehr mehr.
  Future<void> install(File file) async {
    if (Platform.isAndroid) return _installApk(file);
    if (Platform.isWindows) return _installWindowsZip(file);
    throw const UpdateException(
      'Automatische Installation ist auf dieser Plattform nicht möglich.',
    );
  }

  Future<bool> _matchesChecksum(File file, String? expected) async {
    if (!file.existsSync()) return false;
    if (expected == null || expected.isEmpty) return true;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected;
  }

  /// Ob eine schon vorhandene Datei ohne neuen Download taugt.
  ///
  /// Ohne Pruefsumme im Manifest bleibt nur die Groesse als Anhaltspunkt;
  /// fehlt auch die, wird sicherheitshalber neu geladen.
  Future<bool> _isReusable(File file, ReleaseAsset asset) async {
    final expected = asset.sha256;
    if (expected != null && expected.isNotEmpty) {
      return _matchesChecksum(file, expected);
    }
    final size = asset.sizeBytes;
    return size != null && await file.length() == size;
  }

  Future<void> _installApk(File apk) async {
    try {
      await _channel.invokeMethod<void>('installApk', {'path': apk.path});
    } on PlatformException catch (error) {
      throw UpdateException(
        'Installer konnte nicht gestartet werden (${error.message}).',
      );
    }
  }

  Future<void> _installWindowsZip(File zip) async {
    final exePath = Platform.resolvedExecutable;
    final targetDir = File(exePath).parent.path;
    final workDir = Directory('${zip.parent.path}/entpackt');
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }

    final extract = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      'Expand-Archive -LiteralPath ${_psLiteral(zip.path)} '
          '-DestinationPath ${_psLiteral(workDir.path)} -Force',
    ]);
    if (extract.exitCode != 0) {
      throw UpdateException('Entpacken fehlgeschlagen: ${extract.stderr}');
    }

    final script = File('${zip.parent.path}/apply_update.ps1');
    await script.writeAsString(_windowsUpdaterScript);

    DebugLog.instance.add('update', 'Windows-Update: $targetDir wird ersetzt');

    await Process.start('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-WindowStyle',
      'Hidden',
      '-File',
      script.path,
      '-AppPid',
      '$pid',
      '-SourceDir',
      workDir.path,
      '-TargetDir',
      targetDir,
      '-ExePath',
      exePath,
      '-ZipPath',
      zip.path,
    ], mode: ProcessStartMode.detached);

    // Das Skript wartet auf das Ende dieses Prozesses und startet die App
    // danach neu.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    exit(0);
  }

  /// Setzt einen Pfad als PowerShell-Literal in einfache Anfuehrungszeichen.
  static String _psLiteral(String value) =>
      "'${value.replaceAll("'", "''")}'";

  void dispose() => _client.close();
}

/// Tauscht die Programmdateien, sobald die App beendet ist, und startet sie
/// neu. Alle Pfade kommen als absolute Parameter herein.
const String _windowsUpdaterScript = r'''
param(
  [Parameter(Mandatory = $true)][int]$AppPid,
  [Parameter(Mandatory = $true)][string]$SourceDir,
  [Parameter(Mandatory = $true)][string]$TargetDir,
  [Parameter(Mandatory = $true)][string]$ExePath,
  [string]$ZipPath = ''
)

$ErrorActionPreference = 'Stop'
$log = Join-Path (Split-Path -Parent $PSCommandPath) 'update.log'

function Write-Log([string]$message) {
  "{0}  {1}" -f (Get-Date -Format 's'), $message | Add-Content -LiteralPath $log
}

Write-Log "Start: $SourceDir -> $TargetDir (PID $AppPid)"

# 1. Warten, bis die laufende App wirklich beendet ist.
try {
  Wait-Process -Id $AppPid -Timeout 90 -ErrorAction Stop
} catch {
  Write-Log "Warten auf Prozess: $($_.Exception.Message)"
}
Start-Sleep -Milliseconds 800

# 2. Dateien uebernehmen. Direkt nach dem Beenden koennen DLLs noch kurz
#    gesperrt sein, deshalb mehrere Anlaeufe.
$copied = $false
for ($i = 1; $i -le 15; $i++) {
  try {
    Copy-Item -Path (Join-Path $SourceDir '*') -Destination $TargetDir -Recurse -Force
    $copied = $true
    break
  } catch {
    Write-Log "Versuch $i fehlgeschlagen: $($_.Exception.Message)"
    Start-Sleep -Seconds 2
  }
}

if (-not $copied) {
  Write-Log 'Kopieren endgueltig fehlgeschlagen. Ordner wird geoeffnet.'
  Start-Process explorer.exe $SourceDir
  exit 1
}

Write-Log 'Dateien uebernommen, App wird gestartet.'
Start-Process -FilePath $ExePath

# 3. Aufraeumen. Beide Pfade sind absolut und kommen als Parameter herein.
try { Remove-Item -LiteralPath $SourceDir -Recurse -Force } catch { Write-Log $_.Exception.Message }
if ($ZipPath -and (Test-Path -LiteralPath $ZipPath)) {
  try { Remove-Item -LiteralPath $ZipPath -Force } catch { Write-Log $_.Exception.Message }
}
Write-Log 'Fertig.'
''';
