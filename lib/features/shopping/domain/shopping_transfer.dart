import '../../../core/scope/app_scope.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/shopping_repository.dart';

/// Was beim Übernehmen eines Einkaufs ins Inventar passiert ist.
class TransferResult {
  const TransferResult({required this.increased, required this.created});

  /// Posten, die einen vorhandenen Bestand erhöht haben.
  final int increased;

  /// Posten, die neu ins Inventar aufgenommen wurden.
  final int created;

  int get total => increased + created;

  String get summary {
    if (total == 0) return 'Nichts zu übernehmen.';
    final parts = <String>[
      if (created > 0) '$created neu angelegt',
      if (increased > 0) '$increased Bestand erhöht',
    ];
    return '${parts.join(', ')}.';
  }
}

/// Überträgt abgehakte Einkaufsposten in das Inventar desselben Kontexts.
///
/// Ein Posten, der aus einem knappen Vorrat entstanden ist, erhöht genau
/// diesen Bestand. Sonst wird über Barcode und Name gesucht; erst wenn nichts
/// passt, entsteht ein neuer Vorrat.
class ShoppingTransferService {
  const ShoppingTransferService({
    required this.inventory,
    required this.shopping,
  });

  final InventoryRepository inventory;
  final ShoppingRepository shopping;

  Future<TransferResult> transferChecked({
    required AppScope scope,
    required String listId,
    required String userId,
  }) async {
    final items = await shopping.checkedItems(listId);
    var increased = 0;
    var created = 0;

    for (final item in items) {
      final target = await _resolveTarget(scope, item);
      if (target != null) {
        await inventory.adjustQuantity(
          id: target.id,
          userId: userId,
          delta: item.quantity,
        );
        increased++;
      } else {
        await inventory.addItem(
          scope: scope,
          userId: userId,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          barcode: item.barcode,
          note: item.note,
        );
        created++;
      }
    }

    return TransferResult(increased: increased, created: created);
  }

  Future<InventoryItem?> _resolveTarget(
    AppScope scope,
    ShoppingItem item,
  ) async {
    final linkedId = item.inventoryItemId;
    if (linkedId != null) {
      final linked = await inventory.findById(linkedId);
      if (linked != null && linked.deletedAt == null) return linked;
    }
    return inventory.findMatching(
      scope,
      barcode: item.barcode,
      name: item.name,
    );
  }
}
