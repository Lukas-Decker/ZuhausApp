import 'package:flutter/material.dart';

import '../core/scope/app_scope.dart';

/// Farbwelt der App.
///
/// Der aktive Scope färbt die gesamte Oberfläche: Privat blau, Haushalt
/// grün. Das ist bewusst kein dezenter Akzent, sondern das Hauptsignal,
/// weil Nutzer Texthinweise überlesen.
abstract final class ScopePalette {
  static const Color personalSeed = Color(0xFF2563EB);
  static const Color householdSeed = Color(0xFF059669);

  static Color seedFor(ScopeKind kind) =>
      kind == ScopeKind.personal ? personalSeed : householdSeed;

  static IconData iconFor(ScopeKind kind) =>
      kind == ScopeKind.personal ? Icons.lock_person_rounded : Icons.groups_rounded;

  /// Kurzes Label für Banner und Buttons, immer in Grossbuchstaben gedacht.
  static String badgeFor(ScopeKind kind) =>
      kind == ScopeKind.personal ? 'PRIVAT' : 'HAUSHALT';
}

abstract final class AppTheme {
  static ThemeData light(ScopeKind scope) => _build(scope, Brightness.light);

  static ThemeData dark(ScopeKind scope) => _build(scope, Brightness.dark);

  static ThemeData _build(ScopeKind scope, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ScopePalette.seedFor(scope),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
