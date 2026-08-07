import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../update_providers.dart';
import 'update_sheet.dart';

/// Unsichtbarer Wächter im Rahmen der App: sobald eine Prüfung ein Update
/// meldet, zeigt er den Hinweis.
///
/// Pro Version nur einmal je Sitzung, und nur wenn sie nicht mit "Später"
/// übersprungen wurde. Pflicht-Updates fragen nicht.
class UpdatePrompt extends ConsumerStatefulWidget {
  const UpdatePrompt({super.key});

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  String? _shownFor;

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateStatus>(
      updateControllerProvider,
      (_, next) => _maybeShow(next),
    );
    return const SizedBox.shrink();
  }

  void _maybeShow(UpdateStatus status) {
    final manifest = status.manifest;
    if (manifest == null || !status.hasUpdate) return;

    final version = '${manifest.latest}';
    if (_shownFor == version) return;

    final mandatory = status.availability.isRequired;
    if (!mandatory) {
      final skipped = ref
          .read(updateControllerProvider.notifier)
          .skippedVersion;
      if (skipped == version) return;
    }

    _shownFor = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showUpdateSheet(context, mandatory: mandatory);
    });
  }
}
