import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/scope_banner.dart';
import '../../../data/db/app_database.dart';
import '../../inventory/domain/measurement_unit.dart';
import '../domain/shopping_category.dart';
import '../shopping_providers.dart';
import 'shopping_item_editor.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final active = ref.watch(activeShoppingListProvider);
    final items = ref.watch(shoppingItemsProvider);

    final open = (items.value ?? const []).where((i) => !i.isChecked).toList();
    final checked = (items.value ?? const []).where((i) => i.isChecked).toList();

    return ModuleScaffold(
      title: active?.name ?? 'Einkauf',
      actions: [
        if ((lists.value ?? const []).length > 1)
          _ListSwitcher(lists: lists.value ?? const []),
        IconButton(
          tooltip: 'Listen verwalten',
          onPressed: () => _manageLists(context, ref),
          icon: const Icon(Icons.playlist_add_rounded),
        ),
      ],
      body: active == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _QuickAddBar(listId: active.id),
                const _Suggestions(),
                Expanded(
                  child: open.isEmpty && checked.isEmpty
                      ? const EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Liste ist leer',
                          message:
                              'Tippe oben ein, was du brauchst. Knappe Vorräte '
                              'schlägt die App dir automatisch vor.',
                        )
                      : _ItemList(open: open, checked: checked),
                ),
                if (checked.isNotEmpty)
                  _FinishBar(listId: active.id, checkedCount: checked.length),
              ],
            ),
    );
  }

  Future<void> _manageLists(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ListManagerSheet(),
    );
  }
}

// --- Kopfbereich ------------------------------------------------------------

class _ListSwitcher extends ConsumerWidget {
  const _ListSwitcher({required this.lists});

  final List<ShoppingList> lists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeShoppingListProvider);
    return PopupMenuButton<String>(
      tooltip: 'Liste wechseln',
      icon: const Icon(Icons.list_alt_rounded),
      onSelected: ref.read(selectedShoppingListIdProvider.notifier).select,
      itemBuilder: (_) => [
        for (final list in lists)
          PopupMenuItem(
            value: list.id,
            child: Row(
              children: [
                Icon(
                  list.id == active?.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(list.name),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickAddBar extends ConsumerStatefulWidget {
  const _QuickAddBar({required this.listId});

  final String listId;

  @override
  ConsumerState<_QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<_QuickAddBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Tipp-Vorschlaege aktualisieren, waehrend getippt wird.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() => _addNamed(_controller.text);

  Future<void> _addNamed(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await ref
        .read(shoppingRepositoryProvider)
        .addItem(
          scope: ref.read(activeScopeProvider),
          listId: widget.listId,
          userId: ref.read(identityProvider).userId,
          name: trimmed,
          category: ShoppingCategory.guess(trimmed).name,
        );

    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(activeScopeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.add_rounded),
                    hintText: scope.isPersonal
                        ? 'Auf meine Liste setzen'
                        : 'Auf die Liste von ${scope.label}',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Mit Details anlegen',
                onPressed: () => ShoppingItemEditor.show(
                  context,
                  listId: widget.listId,
                  initialName: _controller.text.trim(),
                ).then((created) {
                  if (created == true) _controller.clear();
                }),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          _TypeAheadSuggestions(
            query: _controller.text.trim(),
            onPick: _addNamed,
          ),
        ],
      ),
    );
  }
}

/// Tipp-Vorschlaege unter der Schnell-Eingabe: passende Namen aus Produkten
/// und vorhandenen Vorraeten. Ein Tipp legt den Posten direkt an.
class _TypeAheadSuggestions extends ConsumerWidget {
  const _TypeAheadSuggestions({required this.query, required this.onPick});

  final String query;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) return const SizedBox.shrink();
    final suggestions =
        ref.watch(nameSuggestionsProvider(query)).value ?? const [];
    final filtered = suggestions
        .where((s) => s.toLowerCase() != query.toLowerCase())
        .take(6)
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final name in filtered)
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16),
              label: Text(name),
              onPressed: () => onPick(name),
            ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(shoppingSuggestionsProvider);
    final list = ref.watch(activeShoppingListProvider);
    if (suggestions.isEmpty || list == null) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Knapp:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(suggestion.name),
                  onPressed: () => ref
                      .read(shoppingRepositoryProvider)
                      .addItem(
                        scope: ref.read(activeScopeProvider),
                        listId: list.id,
                        userId: ref.read(identityProvider).userId,
                        name: suggestion.name,
                        category: ShoppingCategory.guess(suggestion.name).name,
                        inventoryItemId: suggestion.id,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Liste ------------------------------------------------------------------

class _ItemList extends StatelessWidget {
  const _ItemList({required this.open, required this.checked});

  final List<ShoppingItem> open;
  final List<ShoppingItem> checked;

  @override
  Widget build(BuildContext context) {
    final groups = <ShoppingCategory, List<ShoppingItem>>{};
    for (final item in open) {
      groups.putIfAbsent(ShoppingCategory.parse(item.category), () => []).add(item);
    }
    final ordered = ShoppingCategory.values
        .where(groups.containsKey)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final category in ordered) ...[
          _CategoryHeader.category(category, groups[category]!.length),
          for (final item in groups[category]!) _ShoppingTile(item: item),
        ],
        if (checked.isNotEmpty) ...[
          const SizedBox(height: 8),
          _CategoryHeader(
            icon: Icons.check_circle_outline_rounded,
            label: 'Erledigt',
            count: checked.length,
          ),
          for (final item in checked) _ShoppingTile(item: item),
        ],
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  _CategoryHeader.category(ShoppingCategory category, this.count)
    : icon = category.icon,
      label = category.label;

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ShoppingTile extends ConsumerWidget {
  const _ShoppingTile({required this.item});

  final ShoppingItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = MeasurementUnit.parse(item.unit);
    final scheme = Theme.of(context).colorScheme;
    final showQuantity = item.quantity != 1 || !unit.isCountable;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: scheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: scheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => ref
          .read(shoppingRepositoryProvider)
          .deleteItem(item.id, ref.read(identityProvider).userId),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (value) => ref
            .read(shoppingRepositoryProvider)
            .setChecked(
              id: item.id,
              checked: value ?? false,
              userId: ref.read(identityProvider).userId,
            ),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          item.name,
          style: item.isChecked
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: item.note == null && !showQuantity
            ? null
            : Text(
                [
                  if (showQuantity) unit.format(item.quantity),
                  if (item.note != null) item.note!,
                ].join(' · '),
              ),
        secondary: IconButton(
          tooltip: 'Bearbeiten',
          onPressed: () =>
              ShoppingItemEditor.show(context, listId: item.listId, item: item),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

// --- Abschluss --------------------------------------------------------------

class _FinishBar extends ConsumerStatefulWidget {
  const _FinishBar({required this.listId, required this.checkedCount});

  final String listId;
  final int checkedCount;

  @override
  ConsumerState<_FinishBar> createState() => _FinishBarState();
}

class _FinishBarState extends ConsumerState<_FinishBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.checkedCount} erledigt',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _finish(transfer: false),
                child: const Text('Nur entfernen'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : () => _finish(transfer: true),
                icon: const Icon(Icons.move_down_rounded),
                label: const Text('Ins Inventar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish({required bool transfer}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final userId = ref.read(identityProvider).userId;
    final repository = ref.read(shoppingRepositoryProvider);

    String message;
    if (transfer) {
      final result = await ref
          .read(shoppingTransferServiceProvider)
          .transferChecked(
            scope: ref.read(activeScopeProvider),
            listId: widget.listId,
            userId: userId,
          );
      message = 'Ins Inventar übernommen: ${result.summary}';
    } else {
      message = '${widget.checkedCount} Posten entfernt.';
    }

    await repository.deleteCheckedItems(widget.listId, userId);

    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

// --- Listenverwaltung -------------------------------------------------------

class _ListManagerSheet extends ConsumerWidget {
  const _ListManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider).value ?? const [];
    final active = ref.watch(activeShoppingListProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Einkaufslisten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const ScopeChip(),
              ],
            ),
            const SizedBox(height: 12),
            for (final list in lists)
              ListTile(
                leading: Icon(
                  list.id == active?.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(list.name),
                onTap: () {
                  ref
                      .read(selectedShoppingListIdProvider.notifier)
                      .select(list.id);
                  Navigator.of(context).pop();
                },
                trailing: lists.length < 2
                    ? null
                    : IconButton(
                        tooltip: 'Löschen',
                        onPressed: () => _delete(context, ref, list),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Neue Liste'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Neue Liste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'z.B. Drogerie',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final list = await ref
        .read(shoppingRepositoryProvider)
        .createList(
          scope: ref.read(activeScopeProvider),
          userId: ref.read(identityProvider).userId,
          name: trimmed,
        );
    ref.read(selectedShoppingListIdProvider.notifier).select(list.id);

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Liste löschen?'),
        content: Text('"${list.name}" und alle Posten darauf werden entfernt.'),
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

    ref.read(selectedShoppingListIdProvider.notifier).select(null);
    await ref
        .read(shoppingRepositoryProvider)
        .deleteList(list.id, ref.read(identityProvider).userId);
  }
}
