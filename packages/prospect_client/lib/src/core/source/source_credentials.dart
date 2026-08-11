import 'dart:io';

import 'package:meta/meta.dart';

/// Zugangsdaten fuer Quellen, die welche verlangen.
///
/// Grundsatz: **kein Schluessel steht im Code oder im Repository.** Werte
/// kommen aus der Umgebung oder werden vom Aufrufer uebergeben. Das Modul
/// prueft nicht, ob ein hinterlegter Schluessel fuer die eigene Nutzung
/// lizenziert ist. Diese Beurteilung liegt bei dem, der ihn eintraegt.
///
/// Quellen ohne hinterlegte Zugangsdaten werden nicht registriert, statt zur
/// Laufzeit mit HTTP 401 zu scheitern. Welche fehlen und warum, sagt
/// [missingFor] und `prospect_client sources`.
@immutable
class SourceCredentials {
  const SourceCredentials(this._values);

  /// Leer. Alle Quellen, die Zugangsdaten brauchen, bleiben deaktiviert.
  const SourceCredentials.none() : _values = const {};

  /// Liest die bekannten Variablen aus der Prozessumgebung.
  ///
  /// Nicht gesetzte Variablen fehlen einfach, das ist kein Fehler.
  factory SourceCredentials.fromEnvironment([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    final values = <String, String>{};
    for (final key in CredentialKey.values) {
      final value = env[key.envName];
      if (value != null && value.trim().isNotEmpty) {
        values[key.name] = value.trim();
      }
    }
    return SourceCredentials(values);
  }

  final Map<String, String> _values;

  String? operator [](CredentialKey key) => _values[key.name];

  bool has(CredentialKey key) => _values.containsKey(key.name);

  /// True, wenn alle fuer eine Quelle noetigen Werte vorliegen.
  bool hasAll(Iterable<CredentialKey> keys) => keys.every(has);

  /// Fehlende Umgebungsvariablen fuer eine Quelle, als Namen zum Anzeigen.
  List<String> missingFor(Iterable<CredentialKey> keys) => keys
      .where((key) => !has(key))
      .map((key) => key.envName)
      .toList();

  /// Kopie mit zusaetzlichen Werten. Fuer Apps, die Schluessel aus einem
  /// sicheren Speicher laden statt aus der Umgebung.
  SourceCredentials withValues(Map<CredentialKey, String> values) =>
      SourceCredentials({
        ..._values,
        for (final entry in values.entries)
          if (entry.value.trim().isNotEmpty) entry.key.name: entry.value.trim(),
      });

  /// Namen der gesetzten Schluessel, ohne die Werte.
  ///
  /// Bewusst nur die Namen: ein versehentlich geloggtes Credentials-Objekt
  /// darf keine Geheimnisse preisgeben.
  List<String> get configuredKeys => _values.keys.toList()..sort();

  @override
  String toString() => 'SourceCredentials(${configuredKeys.join(', ')})';
}

/// Die vom Modul unterstuetzten Zugangsdaten.
enum CredentialKey {
  /// `x-apikey` fuer die Angebots- und Prospekt-API von Marktguru.
  marktguruApiKey('MARKTGURU_API_KEY'),

  /// `x-clientkey` fuer dieselbe API.
  marktguruClientKey('MARKTGURU_CLIENT_KEY'),

  /// `x-apikey` fuer die Filial-API der Schwarz-Gruppe unter
  /// `live.api.schwarz`. Wird nur fuer die Ortsaufloesung bei Lidl gebraucht.
  /// Kaufland kommt ohne aus, dessen Filialliste ist frei zugaenglich.
  schwarzStoresApiKey('SCHWARZ_STORES_API_KEY');

  const CredentialKey(this.envName);

  /// Name der Umgebungsvariable.
  final String envName;
}
