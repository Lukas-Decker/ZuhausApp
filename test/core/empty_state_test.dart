import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/widgets/empty_state.dart';

/// Rendert den Leerzustand in einer festen Flaeche und liefert die Position
/// des Symbols.
Future<double> _iconTop(WidgetTester tester, EmptyState state) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SizedBox(height: 600, child: state))),
  );
  return tester.getTopLeft(find.byType(Icon)).dy;
}

void main() {
  testWidgets(
    'Symbol steht unabhaengig von Textlaenge und Knopf an derselben Stelle',
    (tester) async {
      final short = await _iconTop(
        tester,
        const EmptyState(
          icon: Icons.pets_outlined,
          title: 'Noch keine Tiere',
          message: 'Kurz.',
        ),
      );

      final long = await _iconTop(
        tester,
        EmptyState(
          icon: Icons.kitchen_outlined,
          title: 'Noch nichts erfasst',
          message:
              'Ein deutlich laengerer Satz, der ueber mehrere Zeilen laeuft '
              'und den Leerzustand sonst nach oben schieben wuerde.',
          action: FilledButton(onPressed: () {}, child: const Text('Anlegen')),
        ),
      );

      expect(long, short);
    },
  );
}
