/// Anzeigename der App. Zentral, damit ein Umbenennen ein Handgriff ist.
///
/// Aendert die im UI sichtbaren Texte. Der technische Paketname
/// (de.lukas.multiapp) und der Fenster-/App-Titel des Betriebssystems liegen
/// getrennt (AndroidManifest, windows/runner) und werden dort gepflegt.
const String appName = 'Zuhaus';

/// Anzeige-Version der App. Beim Versionsbump in pubspec.yaml mitziehen.
const String appVersion = '0.24.5';
