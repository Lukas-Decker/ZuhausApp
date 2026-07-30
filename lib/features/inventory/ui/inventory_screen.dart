import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_info.dart';
import '../../../core/providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/widgets/add_ghost_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../data/open_food_facts_service.dart';
import '../domain/measurement_unit.dart';
import '../domain/storage_icons.dart';
import '../inventory_providers.dart';
import 'product_thumbnail.dart';
import 'barcode_scan.dart';
import 'inventory_item_editor.dart';
import 'storage_locations_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(inventoryItemsProvider);
    final filter = ref.watch(inventoryFilterProvider);
    final search = ref.watch(inventorySearchProvider);

    return ModuleScaffold(
      title: 'Inventar',
      actions: [
        IconButton(
          tooltip: 'Orte verwalten',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StorageLocationsScreen()),
          ),
          icon: const Icon(Icons.shelves),
        ),
      ],
      floatingActionButton: const _InventoryAddFab(),
      body: Column(
        children: [
          _SearchAndFilterBar(filter: filter, search: search),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Fehler beim Laden',
                message: '$error',
              ),
              data: (list) => list.isEmpty
                  ? _EmptyInventory(filter: filter, hasSearch: search.isNotEmpty)
                  : _InventoryList(entries: list),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Erfassung über Barcode -------------------------------------------------

/// Scannt einen Code und führt zum passenden nächsten Schritt.
///
/// Reihenfolge: bereits vorhandener Vorrat, dann lokal bekanntes Produkt,
/// dann Open Food Facts (nur mit Einwilligung), sonst leeres Formular.
Future<void> addItemByScan(BuildContext context, WidgetRef ref) async {
  final barcode = await scanBarcode(context);
  if (barcode == null || !context.mounted) return;

  final scope = ref.read(activeScopeProvider);
  final repository = ref.read(inventoryRepositoryProvider);

  final existing = await repository.findByBarcode(scope, barcode);
  if (existing != null) {
    if (!context.mounted) return;
    await _offerIncrease(context, ref, existing);
    return;
  }

  final known = await repository.findProduct(scope, barcode);
  if (known != null) {
    if (!context.mounted) return;
    await InventoryItemEditor.show(
      context,
      barcode: barcode,
      prefill: ProductLookupResult(
        barcode: barcode,
        name: known.name,
        brand: known.brand,
        imageUrl: known.imageUrl,
        category: known.category,
        unit: MeasurementUnit.parse(known.defaultUnit),
        quantity: known.defaultQuantity,
      ),
    );
    return;
  }

  if (!context.mounted) return;
  final consent = await _ensureOpenFoodFactsConsent(context, ref);
  if (!context.mounted) return;

  ProductLookupResult? lookup;
  if (consent) {
    lookup = await _lookupWithProgress(context, ref, barcode);
    if (!context.mounted) return;
  }

  await InventoryItemEditor.show(context, barcode: barcode, prefill: lookup);
}

Future<void> _offerIncrease(
  BuildContext context,
  WidgetRef ref,
  InventoryItem item,
) async {
  final unit = MeasurementUnit.parse(item.unit);
  final increase = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(item.name),
      content: Text(
        'Ist schon im Inventar (${unit.format(item.quantity)}). '
        'Bestand um 1 erhöhen?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Bearbeiten'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('+1'),
        ),
      ],
    ),
  );
  if (increase == null || !context.mounted) return;

  if (increase) {
    await ref
        .read(inventoryRepositoryProvider)
        .adjustQuantity(
          id: item.id,
          userId: ref.read(identityProvider).userId,
          delta: 1,
        );
  } else {
    await InventoryItemEditor.show(context, item: item);
  }
}

/// Holt bei Bedarf die Einwilligung für die Abfrage bei Open Food Facts.
Future<bool> _ensureOpenFoodFactsConsent(
  BuildContext context,
  WidgetRef ref,
) async {
  final settings = ref.read(appSettingsProvider);
  final consent = settings.openFoodFactsConsent;
  if (consent != null) return consent;

  final granted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Produktdaten abrufen?'),
      content: Text(
        'Für unbekannte Codes kann $appName den Barcode an Open Food Facts '
        'senden und Name, Marke und Größe übernehmen.\n\n'
        'Übertragen wird nur der Barcode, keine persönlichen Daten. Ohne '
        'Einwilligung legst du Produkte einfach selbst an. Du kannst die '
        'Entscheidung in den Einstellungen jederzeit ändern.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Nein, selbst anlegen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Ja, abrufen'),
        ),
      ],
    ),
  );

  final decision = granted ?? false;
  await ref
      .read(appSettingsProvider.notifier)
      .setOpenFoodFactsConsent(decision);
  return decision;
}

Future<ProductLookupResult?> _lookupWithProgress(
  BuildContext context,
  WidgetRef ref,
  String barcode,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await ref
        .read(openFoodFactsServiceProvider)
        .lookup(barcode);
    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Produkt nicht gefunden, bitte selbst benennen.'),
        ),
      );
    }
    return result;
  } on ProductLookupException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return null;
  }
}

// --- Bausteine --------------------------------------------------------------

/// Oeffnet die Hinzufuegen-Auswahl fuers Inventar (Scannen oder manuell).
Future<void> openInventoryAdd(BuildContext context, WidgetRef ref) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              isCameraScanSupported
                  ? Icons.qr_code_scanner_rounded
                  : Icons.keyboard_alt_outlined,
            ),
            title: Text(
              isCameraScanSupported ? 'Barcode scannen' : 'Barcode eingeben',
            ),
            onTap: () => Navigator.of(sheetContext).pop('scan'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Manuell erfassen'),
            onTap: () => Navigator.of(sheetContext).pop('manual'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'scan') {
    await addItemByScan(context, ref);
  } else {
    await InventoryItemEditor.show(context);
  }
}

/// Das Ghost-„Hinzufuegen"-Element am Listenende bzw. im Leerzustand.
Widget _inventoryAddGhost(WidgetRef ref) {
  return Builder(
    builder: (context) => AddGhostTile(
      label: 'Vorrat hinzufügen',
      onTap: () => openInventoryAdd(context, ref),
    ),
  );
}

/// Schwebender FAB, immer sichtbar.
class _InventoryAddFab extends ConsumerWidget {
  const _InventoryAddFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => openInventoryAdd(context, ref),
      tooltip: 'Hinzufügen',
      child: const Icon(Icons.add_rounded),
    );
  }
}

class _SearchAndFilterBar extends ConsumerStatefulWidget {
  const _SearchAndFilterBar({required this.filter, required this.search});

  final InventoryFilter filter;
  final String search;

  @override
  ConsumerState<_SearchAndFilterBar> createState() =>
      _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends ConsumerState<_SearchAndFilterBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.search,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowCount = (ref.watch(lowStockItemsProvider).value ?? const []).length;
    final expiringCount =
        (ref.watch(expiringItemsProvider).value ?? const []).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Suchen',
              suffixIcon: widget.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        ref.read(inventorySearchProvider.notifier).clear();
                      },
                    ),
            ),
            onChanged: ref.read(inventorySearchProvider.notifier).set,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final filter in InventoryFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: widget.filter == filter,
                    label: Text(
                      switch (filter) {
                        InventoryFilter.all => filter.label,
                        InventoryFilter.low => '${filter.label} ($lowCount)',
                        InventoryFilter.expiring =>
                          '${filter.label} ($expiringCount)',
                      },
                    ),
                    onSelected: (_) =>
                        ref.read(inventoryFilterProvider.notifier).set(filter),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyInventory extends ConsumerWidget {
  const _EmptyInventory({required this.filter, required this.hasSearch});

  final InventoryFilter filter;
  final bool hasSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget message = hasSearch
        ? const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nichts gefunden',
            message: 'Kein Vorrat passt zu deiner Suche.',
          )
        : switch (filter) {
            InventoryFilter.low => const EmptyState(
              icon: Icons.thumb_up_outlined,
              title: 'Nichts wird knapp',
              message:
                  'Alle Vorräte mit Mindestbestand sind ausreichend gefüllt.',
            ),
            InventoryFilter.expiring => const EmptyState(
              icon: Icons.event_available_rounded,
              title: 'Nichts läuft ab',
              message: 'In den nächsten Tagen verfällt nichts.',
            ),
            InventoryFilter.all => const EmptyState(
              icon: Icons.kitchen_outlined,
              title: 'Noch nichts erfasst',
              message:
                  'Scanne einen Barcode oder lege den ersten Vorrat von Hand an.',
            ),
          };

    return Column(
      children: [
        Expanded(child: message),
        _inventoryAddGhost(ref),
        const SizedBox(height: 96),
      ],
    );
  }
}

/// Liste, gruppiert nach Lagerort.
class _InventoryList extends ConsumerWidget {
  const _InventoryList({required this.entries});

  final List<InventoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = <String?, List<InventoryEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.item.locationId, () => []).add(entry);
    }

    final ordered = groups.entries.toList()
      ..sort((a, b) {
        final aOrder = a.value.first.location?.sortOrder ?? 999;
        final bOrder = b.value.first.location?.sortOrder ?? 999;
        return aOrder.compareTo(bOrder);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: ordered.length + 1,
      itemBuilder: (context, index) {
        // Letztes Element: das Ghost-„Hinzufuegen".
        if (index == ordered.length) return _inventoryAddGhost(ref);
        final group = ordered[index];
        final location = group.value.first.location;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GroupHeader(location: location, count: group.value.length),
            for (final entry in group.value) _InventoryTile(entry: entry),
          ],
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.location, required this.count});

  final StorageLocation? location;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(
            location == null
                ? Icons.help_outline_rounded
                : storageIconFor(location!.iconKey),
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            location?.name ?? 'Ohne Ort',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  const _InventoryTile({required this.entry});

  final InventoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = entry.item;
    final unit = MeasurementUnit.parse(item.unit);
    final scheme = Theme.of(context).colorScheme;
    final batchCount =
        ref.watch(batchAggregatesProvider).value?[item.id]?.count ?? 0;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context, item.name),
      onDismissed: (_) => _delete(context, ref),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () => InventoryItemEditor.show(context, item: item),
        leading: ProductThumbnail(imageUrl: entry.imageUrl),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: _Badges(entry: entry, batchCount: batchCount),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.quantity <= 0)
              _CompactIconButton(
                tooltip: 'Löschen',
                onPressed: () => _confirmAndDelete(context, ref),
                icon: Icons.delete_outline_rounded,
                color: scheme.error,
              )
            else
              _CompactIconButton(
                tooltip: batchCount > 0 ? 'Älteste Charge verbrauchen' : 'Weniger',
                onPressed: () => batchCount > 0
                    ? _consumeFifo(ref)
                    : _adjust(ref, -1),
                icon: Icons.remove_circle_outline_rounded,
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: Text(
                unit.format(item.quantity),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: entry.isLow ? scheme.error : null,
                ),
              ),
            ),
            _CompactIconButton(
              tooltip: 'Mehr',
              onPressed: () => _adjust(ref, 1),
              icon: Icons.add_circle_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _adjust(WidgetRef ref, double delta) {
    ref
        .read(inventoryRepositoryProvider)
        .adjustQuantity(
          id: entry.item.id,
          userId: ref.read(identityProvider).userId,
          delta: delta,
        );
  }

  void _consumeFifo(WidgetRef ref) {
    ref
        .read(inventoryRepositoryProvider)
        .consumeEarliest(
          itemId: entry.item.id,
          userId: ref.read(identityProvider).userId,
        );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vorrat löschen?'),
        content: Text('"$name" wird aus dem Inventar entfernt.'),
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
    return confirmed ?? false;
  }

  void _delete(BuildContext context, WidgetRef ref) {
    ref
        .read(inventoryRepositoryProvider)
        .deleteItem(entry.item.id, ref.read(identityProvider).userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${entry.item.name}" gelöscht')),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    if (await _confirmDelete(context, entry.item.name) && context.mounted) {
      _delete(context, ref);
    }
  }
}

/// Kompakter Icon-Button fuer die schlanken Inventar-Zeilen.
class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.entry, this.batchCount = 0});

  final InventoryEntry entry;
  final int batchCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badges = <Widget>[];

    if (batchCount > 0) {
      badges.add(
        _Badge(
          icon: Icons.inventory_rounded,
          text: '$batchCount ${batchCount == 1 ? 'Charge' : 'Chargen'}',
          color: scheme.primary,
        ),
      );
    }

    final days = entry.daysUntilExpiry;
    if (days != null) {
      final (text, color) = switch (days) {
        < 0 => ('Abgelaufen', scheme.error),
        0 => ('Läuft heute ab', scheme.error),
        1 => ('Läuft morgen ab', scheme.tertiary),
        <= InventoryRepository.expiryWarningDays => (
          'Noch $days Tage',
          scheme.tertiary,
        ),
        _ => (
          'Bis ${DateFormat('dd.MM.yy', 'de').format(entry.item.expiresAt!)}',
          scheme.onSurfaceVariant,
        ),
      };
      badges.add(_Badge(icon: Icons.event_rounded, text: text, color: color));
    }

    if (entry.isLow) {
      badges.add(
        _Badge(
          icon: Icons.trending_down_rounded,
          text: 'Knapp',
          color: scheme.error,
        ),
      );
    }

    final note = entry.item.note;
    if (note != null && note.isNotEmpty) {
      badges.add(
        _Badge(
          icon: Icons.notes_rounded,
          text: note,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 12, runSpacing: 4, children: badges),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
