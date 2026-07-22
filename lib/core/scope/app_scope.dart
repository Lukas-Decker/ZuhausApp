import 'package:flutter/material.dart';

/// Unterscheidet, wem ein Datensatz gehoert.
///
/// Jeder Datensatz in der App haengt an genau einem [AppScope]. Der aktive
/// Scope wird global umgeschaltet und ist ueber Farbe und Dauerbanner sichtbar,
/// damit niemand versehentlich privat statt in den Haushalt schreibt.
enum ScopeKind {
  personal,
  household,
}

@immutable
class AppScope {
  const AppScope({
    required this.kind,
    required this.id,
    required this.label,
  });

  /// Der persoenliche Scope des angemeldeten Nutzers.
  factory AppScope.personal(String userId, {String label = 'Privat'}) =>
      AppScope(kind: ScopeKind.personal, id: userId, label: label);

  factory AppScope.household(String householdId, String label) =>
      AppScope(kind: ScopeKind.household, id: householdId, label: label);

  final ScopeKind kind;

  /// Nutzer-ID bei [ScopeKind.personal], Haushalts-ID bei [ScopeKind.household].
  final String id;

  /// Anzeigename, z.B. "Privat" oder "Familie Mueller".
  final String label;

  bool get isPersonal => kind == ScopeKind.personal;
  bool get isHousehold => kind == ScopeKind.household;

  /// Stabiler Schluessel fuer Persistenz und Datenbankspalten.
  String get key => '${kind.name}:$id';

  static AppScope? tryParse(String? value, List<AppScope> available) {
    if (value == null) return null;
    for (final scope in available) {
      if (scope.key == value) return scope;
    }
    return null;
  }

  AppScope copyWith({ScopeKind? kind, String? id, String? label}) => AppScope(
    kind: kind ?? this.kind,
    id: id ?? this.id,
    label: label ?? this.label,
  );

  @override
  bool operator ==(Object other) =>
      other is AppScope && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'AppScope($key, "$label")';
}
