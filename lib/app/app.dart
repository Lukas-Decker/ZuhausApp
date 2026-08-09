import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_info.dart';
import '../l10n/app_localizations.dart';
import '../core/providers.dart';
import '../core/security/app_lock_gate.dart';
import '../features/household/join_link_listener.dart';
import '../features/privacy/ui/consent_gate.dart';
import 'router.dart';
import 'theme.dart';

class MultiApp extends ConsumerWidget {
  const MultiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Das Theme hängt am aktiven Kontext: die ganze App wechselt die Farbe.
    final scopeKind = ref.watch(activeScopeProvider).kind;

    return JoinLinkListener(
      child: MaterialApp.router(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(scopeKind),
        darkTheme: AppTheme.dark(scopeKind),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        // Datenschutz-Hinweis (Erststart) aussen, App-Schloss innen.
        builder: (context, child) => ConsentGate(
          child: AppLockGate(child: child ?? const SizedBox.shrink()),
        ),
        locale: const Locale('de'),
        supportedLocales: const [Locale('de'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
