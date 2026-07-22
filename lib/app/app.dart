import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import 'router.dart';
import 'theme.dart';

class MultiApp extends ConsumerWidget {
  const MultiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Das Theme hängt am aktiven Kontext: die ganze App wechselt die Farbe.
    final scopeKind = ref.watch(activeScopeProvider).kind;

    return MaterialApp.router(
      title: 'MultiApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(scopeKind),
      darkTheme: AppTheme.dark(scopeKind),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      locale: const Locale('de'),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
