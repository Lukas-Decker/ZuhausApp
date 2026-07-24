import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/household/household_role.dart';
import '../household_actions.dart';

/// Konfiguriert eine neue Einladung und zeigt den erzeugten Code.
class InviteEditor extends ConsumerStatefulWidget {
  const InviteEditor({
    super.key,
    required this.householdId,
    required this.myRole,
  });

  final String householdId;
  final HouseholdRole myRole;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String householdId,
    required HouseholdRole myRole,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => InviteEditor(householdId: householdId, myRole: myRole),
    );
  }

  @override
  ConsumerState<InviteEditor> createState() => _InviteEditorState();
}

class _InviteEditorState extends ConsumerState<InviteEditor> {
  HouseholdRole _role = HouseholdRole.member;
  int _validityDays = 7;
  bool _limitUses = false;
  int _maxUses = 1;

  String? _createdCode;
  bool _busy = false;

  /// Rollen, die vergeben werden koennen (kein owner; Admin nur durch Owner).
  List<HouseholdRole> get _assignableRoles => HouseholdRole.values
      .where((r) => r != HouseholdRole.owner && widget.myRole.canAssign(r))
      .toList();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _createdCode == null ? _buildForm(context) : _buildResult(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Einladung erstellen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        Text('Rolle der eingeladenen Person', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<HouseholdRole>(
          segments: [
            for (final r in _assignableRoles)
              ButtonSegment(value: r, label: Text(r.label)),
          ],
          selected: {_assignableRoles.contains(_role) ? _role : _assignableRoles.first},
          onSelectionChanged: (s) => setState(() => _role = s.first),
        ),
        const SizedBox(height: 8),
        Text(
          _role.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Text('Gueltigkeit', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _validityDays,
          decoration: const InputDecoration(labelText: 'Laeuft ab nach'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 Tag')),
            DropdownMenuItem(value: 7, child: Text('7 Tage')),
            DropdownMenuItem(value: 30, child: Text('30 Tage')),
            DropdownMenuItem(value: 0, child: Text('Nie')),
          ],
          onChanged: (value) => setState(() => _validityDays = value ?? 7),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _limitUses,
          onChanged: (value) => setState(() => _limitUses = value),
          title: const Text('Anzahl Nutzungen begrenzen'),
        ),
        if (_limitUses)
          Row(
            children: [
              const Text('Maximal '),
              IconButton.filledTonal(
                onPressed: _maxUses <= 1 ? null : () => setState(() => _maxUses--),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_maxUses',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _maxUses >= 50 ? null : () => setState(() => _maxUses++),
                icon: const Icon(Icons.add_rounded),
              ),
              const Text(' Personen'),
            ],
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: const Text('Code erzeugen'),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final code = _createdCode!;
    final pretty = code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
    final link = '${AppConfig.authRedirectScheme}://join?code=$code';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.check_circle_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Einladung bereit',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SelectableText(
                pretty,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copy(pretty, 'Code kopiert'),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Code'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copy(link, 'Einladungslink kopiert'),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Link'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Teile den Code oder den Link. Auf einem Gerät mit der App öffnet '
          'der Link direkt den Beitritt.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    final code = await runHouseholdAction(
      context,
      ref,
      () => ref.read(householdActionsProvider).createInvite(
        householdId: widget.householdId,
        role: _role,
        expiresAt: _validityDays == 0
            ? null
            : DateTime.now().add(Duration(days: _validityDays)),
        maxUses: _limitUses ? _maxUses : null,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _createdCode = code;
    });
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
