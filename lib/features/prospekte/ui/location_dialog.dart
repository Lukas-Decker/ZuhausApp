import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prospekte_providers.dart';

/// Fragt die Postleitzahl ab und speichert den aufgelösten Standort.
Future<void> showProspekteLocationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = ref.read(prospekteLocationProvider);
  final location = await showDialog<ProspekteLocation>(
    context: context,
    builder: (_) => _LocationDialog(initialPlz: current?.plz),
  );
  if (location != null) {
    await ref.read(prospekteLocationProvider.notifier).set(location);
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({this.initialPlz});

  final String? initialPlz;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPlz ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final location = await resolvePlz(_controller.text);
    if (!mounted) return;
    if (location == null) {
      setState(() {
        _busy = false;
        _error = 'Postleitzahl nicht gefunden. Bitte prüfen.';
      });
      return;
    }
    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Standort für Prospekte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: InputDecoration(
              labelText: 'Postleitzahl',
              hintText: 'z.B. 55767',
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'Die Postleitzahl wird zur Ortsbestimmung an zippopotam.us '
            'gesendet. Prospekt-Abfragen übertragen die ermittelten '
            'Koordinaten (Ortsmitte, kein Gerätestandort) an die '
            'Prospekt-Anbieter.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Übernehmen'),
        ),
      ],
    );
  }
}
