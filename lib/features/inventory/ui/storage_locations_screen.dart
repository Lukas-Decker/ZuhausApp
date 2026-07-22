import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../data/db/app_database.dart';
import '../domain/storage_icons.dart';
import '../inventory_providers.dart';

/// Verwaltung der Aufbewahrungsorte des aktiven Kontexts.
class StorageLocationsScreen extends ConsumerWidget {
  const StorageLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(storageLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orte'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ScopeChip(onTap: () {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Neuer Ort'),
      ),
      body: locations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final location = list[index];
            return ListTile(
              leading: Icon(storageIconFor(location.iconKey)),
              title: Text(location.name),
              onTap: () => _edit(context, ref, location),
              trailing: IconButton(
                tooltip: 'Löschen',
                onPressed: () => _delete(context, ref, location),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    StorageLocation? location,
  ) async {
    final result = await showDialog<({String name, String iconKey})>(
      context: context,
      builder: (_) => _LocationDialog(location: location),
    );
    if (result == null) return;

    final repository = ref.read(inventoryRepositoryProvider);
    final userId = ref.read(identityProvider).userId;

    if (location == null) {
      await repository.createLocation(
        scope: ref.read(activeScopeProvider),
        userId: userId,
        name: result.name,
        iconKey: result.iconKey,
      );
    } else {
      await repository.updateLocation(
        id: location.id,
        userId: userId,
        name: result.name,
        iconKey: result.iconKey,
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    StorageLocation location,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ort löschen?'),
        content: Text(
          'Vorräte in "${location.name}" bleiben erhalten und stehen danach '
          'unter "Ohne Ort".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(inventoryRepositoryProvider)
        .deleteLocation(location.id, ref.read(identityProvider).userId);
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({this.location});

  final StorageLocation? location;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.location?.name ?? '',
  );
  late String _iconKey = widget.location?.iconKey ?? 'shelf';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name: name, iconKey: _iconKey));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Neuer Ort' : 'Ort bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const Text('Symbol'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in storageIcons.entries)
                IconButton.filledTonal(
                  isSelected: _iconKey == entry.key,
                  onPressed: () => setState(() => _iconKey = entry.key),
                  icon: Icon(entry.value),
                  style: IconButton.styleFrom(
                    backgroundColor: _iconKey == entry.key
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    foregroundColor: _iconKey == entry.key
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Speichern')),
      ],
    );
  }
}
