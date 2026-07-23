import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../auth/auth_providers.dart';
import '../auth/ui/auth_screen.dart';
import 'household_actions.dart';

/// Lauscht auf Einladungs-Deep-Links `de.lukas.multiapp://join?code=...` und
/// oeffnet den Beitritts-Dialog.
///
/// Liegt einmal ueber der App. Nutzt den globalen Navigator-Schluessel, um von
/// ausserhalb des Widget-Baums Dialoge zu zeigen. Auth-Callbacks (Login)
/// behandelt supabase_flutter selbst; hier geht es nur um Beitritts-Links.
class JoinLinkListener extends ConsumerStatefulWidget {
  const JoinLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JoinLinkListener> createState() => _JoinLinkListenerState();
}

class _JoinLinkListenerState extends ConsumerState<JoinLinkListener> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(_onUri, onError: (_) {});
    _handleInitial();
  }

  Future<void> _handleInitial() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _onUri(uri);
    } catch (_) {
      // Kein Startlink.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onUri(Uri uri) {
    if (uri.host != 'join') return;
    final code = uri.queryParameters['code'];
    if (code == null || code.trim().isEmpty) return;
    // Kurz warten, bis Navigator/Router bereit sind (v.a. bei Kaltstart).
    Future<void>.delayed(const Duration(milliseconds: 400), () => _join(code));
  }

  Future<void> _join(String code) async {
    if (_handling) return;
    _handling = true;
    try {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;

      // Beitreten braucht ein Konto.
      if (ref.read(currentUserProvider) == null) {
        if (!ref.read(authConfiguredProvider)) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.group_add_rounded),
            title: const Text('Einladung erhalten'),
            content: const Text(
              'Um dem Haushalt beizutreten, brauchst du ein Konto. Jetzt '
              'anmelden?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Spaeter'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Anmelden'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
        final authContext = rootNavigatorKey.currentContext;
        if (authContext == null) return;
        // Bewusst der globale Navigator-Kontext, frisch geholt.
        // ignore: use_build_context_synchronously
        await AuthScreen.show(authContext);
        if (ref.read(currentUserProvider) == null) return;
      }

      if (!mounted) return;
      final joinContext = rootNavigatorKey.currentContext;
      if (joinContext == null) return;
      // ignore: use_build_context_synchronously
      await showJoinHouseholdDialog(joinContext, ref, initialCode: code);
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
