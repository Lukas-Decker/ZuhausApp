import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Schweregrad eines Protokolleintrags.
enum LogLevel { info, warning, error }

@immutable
class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.source,
    required this.message,
    this.details,
  });

  final DateTime time;
  final LogLevel level;

  /// Woher der Eintrag kommt, z.B. 'sync', 'notifications', 'flutter'.
  final String source;
  final String message;
  final String? details;

  @override
  String toString() {
    final stamp = time.toIso8601String().substring(11, 19);
    return '[$stamp] ${level.name.toUpperCase()} $source: $message'
        '${details == null ? '' : '\n$details'}';
  }
}

/// Sammelt Fehler und Ereignisse zur Laufzeit, damit sie in der App sichtbar
/// sind, ohne dass ein Rechner mit Konsole angeschlossen sein muss.
///
/// Bewusst ein Ringpuffer im Arbeitsspeicher: nichts wird gespeichert oder
/// verschickt, nach dem Beenden der App ist alles weg.
class DebugLog {
  DebugLog._();

  static final DebugLog instance = DebugLog._();

  static const int _maxEntries = 300;

  final Queue<LogEntry> _entries = Queue<LogEntry>();
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Meldet sich, wenn ein Eintrag dazukommt.
  Stream<void> get changes => _changes.stream;

  List<LogEntry> get entries => List.unmodifiable(_entries.toList().reversed);

  int get errorCount =>
      _entries.where((e) => e.level == LogLevel.error).length;

  void add(
    String source,
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stack,
  }) {
    final details = [
      if (error != null) '$error',
      if (stack != null) _shortStack(stack),
    ].join('\n');

    _entries.addLast(
      LogEntry(
        time: DateTime.now(),
        level: level,
        source: source,
        message: message,
        details: details.isEmpty ? null : details,
      ),
    );
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    if (!_changes.isClosed) _changes.add(null);
    debugPrint('[$source] $message${error == null ? '' : ' :: $error'}');
  }

  void error(String source, String message, {Object? error, StackTrace? stack}) =>
      add(source, message, level: LogLevel.error, error: error, stack: stack);

  void warn(String source, String message, {Object? error}) =>
      add(source, message, level: LogLevel.warning, error: error);

  void clear() {
    _entries.clear();
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Alles als Text, zum Kopieren und Weitergeben.
  String asText() => entries.map((e) => e.toString()).join('\n\n');

  /// Faengt nicht behandelte Fehler ein, damit auch Abstuerze im Protokoll
  /// landen. In `main()` aufrufen.
  static void captureGlobalErrors() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      instance.error(
        'flutter',
        details.exceptionAsString(),
        stack: details.stack,
      );
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      instance.error('dart', 'Nicht behandelter Fehler', error: error, stack: stack);
      return false;
    };
  }

  static String _shortStack(StackTrace stack) {
    final lines = stack.toString().split('\n');
    return lines.take(8).join('\n');
  }
}
