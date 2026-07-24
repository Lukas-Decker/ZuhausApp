import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_info.dart';
import '../../../data/db/app_database.dart';

/// Erstellt einen vollstaendigen Export aller lokalen Daten (DSGVO-Auskunft
/// und Datenmitnahme).
///
/// [build] ist bewusst rein und ohne Datei-/Plattformbezug, damit die
/// Zusammenstellung testbar bleibt; [exportAndShare] verpackt das Ergebnis als
/// JSON-Datei und oeffnet den Teilen-Dialog.
class DataExportService {
  DataExportService(this._db);

  final AppDatabase _db;

  /// Baut die Export-Struktur: pro Tabelle die Roh-Zeilen.
  Future<Map<String, dynamic>> build({String? appVersion}) async {
    final tables = <String, dynamic>{};
    for (final table in AppDatabase.dataTables) {
      final rows = await _db.customSelect('SELECT * FROM $table').get();
      tables[table] = [for (final row in rows) row.data];
    }
    return {
      'app': appName,
      'version': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'note':
          'Zeitstempel sind Unix-Sekunden. Dieser Export enthält alle auf '
          'diesem Gerät gespeicherten Daten.',
      'tables': tables,
    };
  }

  /// Schreibt den Export als JSON in eine temporaere Datei und oeffnet den
  /// Teilen-/Speichern-Dialog des Systems.
  Future<void> exportAndShare({String? appVersion}) async {
    final data = await build(appVersion: appVersion);
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/multiapp-export-$stamp.json');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: '$appName Datenexport',
        title: '$appName Datenexport',
      ),
    );
  }
}
