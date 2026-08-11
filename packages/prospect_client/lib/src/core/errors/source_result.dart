import 'package:meta/meta.dart';

import 'prospect_exception.dart';

/// Ergebnis einer Abfrage ueber potenziell mehrere Quellen.
///
/// Kern der Fehlerstrategie: faellt Tjek aus, liefert Schwarz trotzdem. Die
/// UI bekommt Daten plus eine Liste dessen, was nicht geklappt hat, statt einer
/// Exception, die alles verwirft.
@immutable
class SourceResult<T> {
  const SourceResult({
    required this.data,
    this.errors = const [],
    this.isStale = false,
    this.warnings = const [],
  });

  const SourceResult.ok(this.data)
      : errors = const [],
        isStale = false,
        warnings = const [];

  final T data;

  /// Fehler je Quelle. Nicht leer heisst nicht, dass [data] unbrauchbar ist.
  final List<ProspectException> errors;

  /// True, wenn mindestens ein Teil aus einem abgelaufenen Cache stammt, weil
  /// das Netz nicht erreichbar war. Die App kann darauf hinweisen.
  final bool isStale;

  /// Nicht fehlerhafte Auffaelligkeiten, z.B. uebersprungene Einzeleintraege.
  final List<String> warnings;

  /// True, wenn mindestens eine Quelle ausgefallen ist.
  bool get isPartial => errors.isNotEmpty;

  /// True, wenn nichts geliefert werden konnte.
  bool get isEmpty => switch (data) {
        final Iterable<Object?> it => it.isEmpty,
        null => true,
        _ => false,
      };

  /// True, wenn alle Quellen ausgefallen sind und keine Daten vorliegen.
  bool get isTotalFailure => isEmpty && errors.isNotEmpty;

  SourceResult<R> map<R>(R Function(T) transform) => SourceResult<R>(
        data: transform(data),
        errors: errors,
        isStale: isStale,
        warnings: warnings,
      );

  Map<String, Object?> toJson(Object? Function(T) encodeData) => {
        'data': encodeData(data),
        if (errors.isNotEmpty)
          'errors': errors.map((e) => e.toJson()).toList(),
        if (warnings.isNotEmpty) 'warnings': warnings,
        'partial': isPartial,
        'stale': isStale,
      };

  @override
  String toString() =>
      'SourceResult(${isPartial ? '${errors.length} Fehler' : 'ok'}${isStale ? ', stale' : ''})';
}

/// Sammelt Ergebnisse mehrerer Adapter zu einem [SourceResult].
class SourceResultBuilder<T> {
  final List<T> _items = [];
  final List<ProspectException> _errors = [];
  final List<String> _warnings = [];
  bool _stale = false;

  void addAll(Iterable<T> items) => _items.addAll(items);

  void addError(ProspectException error) => _errors.add(error);

  void addWarning(String warning) => _warnings.add(warning);

  void markStale() => _stale = true;

  int get itemCount => _items.length;

  SourceResult<List<T>> build({int Function(T, T)? sort}) {
    final items = List<T>.from(_items);
    if (sort != null) items.sort(sort);
    return SourceResult(
      data: items,
      errors: List.unmodifiable(_errors),
      warnings: List.unmodifiable(_warnings),
      isStale: _stale,
    );
  }
}
