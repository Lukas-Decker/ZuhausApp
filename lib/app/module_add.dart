import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/inventory/ui/inventory_item_editor.dart';
import '../features/inventory/ui/inventory_screen.dart' show addItemByScan;
import '../features/meds/ui/medication_plan_editor.dart';
import '../features/notes/notes_providers.dart';
import '../features/notes/ui/note_editor_screen.dart';
import '../features/pets/ui/pet_editor.dart';
import '../features/shopping/shopping_providers.dart';
import '../features/shopping/ui/shopping_item_editor.dart';

/// Oeffnet den passenden „Hinzufuegen"-Dialog fuer das aktive Modul.
///
/// [index] ist die Position in der Tab-Reihenfolge (Inventar, Einkauf, Notizen,
/// Pillen, Tiere). Zentral gebuendelt, damit der Hinzufuegen-Eintrag in der
/// Navigation je nach Modul das Richtige tut.
Future<void> openAddForModule(
  BuildContext context,
  WidgetRef ref,
  int index,
) async {
  switch (index) {
    case 0:
      await _inventoryAdd(context, ref);
    case 1:
      final list = ref.read(activeShoppingListProvider);
      if (list != null) {
        await ShoppingItemEditor.show(context, listId: list.id);
      }
    case 2:
      await _notesAdd(context, ref);
    case 3:
      await MedicationPlanEditor.show(context);
    case 4:
      await PetEditor.show(context);
  }
}

Future<void> _inventoryAdd(BuildContext context, WidgetRef ref) async {
  final choice = await _chooser(context, const [
    (value: 'scan', icon: Icons.qr_code_scanner_rounded, label: 'Barcode scannen'),
    (value: 'manual', icon: Icons.edit_outlined, label: 'Manuell erfassen'),
  ]);
  if (!context.mounted || choice == null) return;
  if (choice == 'scan') {
    await addItemByScan(context, ref);
  } else {
    await InventoryItemEditor.show(context);
  }
}

Future<void> _notesAdd(BuildContext context, WidgetRef ref) async {
  final choice = await _chooser(context, const [
    (value: 'note', icon: Icons.notes_rounded, label: 'Notiz'),
    (value: 'checklist', icon: Icons.checklist_rounded, label: 'Checkliste'),
  ]);
  if (!context.mounted || choice == null) return;
  final id = await ref
      .read(notesRepositoryProvider)
      .createNote(
        scope: ref.read(activeScopeProvider),
        userId: ref.read(identityProvider).userId,
        isChecklist: choice == 'checklist',
      );
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: id)),
  );
}

/// Kleiner Auswahldialog fuer Module mit zwei Hinzufuegen-Varianten.
Future<String?> _chooser(
  BuildContext context,
  List<({String value, IconData icon, String label})> options,
) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            ListTile(
              leading: Icon(option.icon),
              title: Text(option.label),
              onTap: () => Navigator.of(sheetContext).pop(option.value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
