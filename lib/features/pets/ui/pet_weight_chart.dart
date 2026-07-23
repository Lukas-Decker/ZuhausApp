import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';

/// Einfaches Liniendiagramm des Gewichtsverlaufs ohne externe Bibliothek.
class PetWeightChart extends StatelessWidget {
  const PetWeightChart({super.key, required this.entries});

  final List<PetWeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.show_chart_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entries.isEmpty
                      ? 'Noch keine Messung.'
                      : 'Ab der zweiten Messung erscheint hier ein Verlauf.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weights = entries.map((e) => e.weightKg).toList();
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Verlauf', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  '${_fmt(weights.last)} kg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightPainter(
                  weights: weights,
                  lineColor: scheme.primary,
                  fillColor: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'min ${_fmt(min)} kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'max ${_fmt(max)} kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.weights,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> weights;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.001 ? 1.0 : max - min;

    Offset pointFor(int i) {
      final x = weights.length == 1
          ? size.width / 2
          : size.width * i / (weights.length - 1);
      final normalized = (weights[i] - min) / range;
      // Etwas Rand oben und unten, damit die Linie nicht klebt.
      final y = size.height * (1 - normalized) * 0.8 + size.height * 0.1;
      return Offset(x, y);
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < weights.length; i++) {
      final point = pointFor(i);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fill.moveTo(point.dx, size.height);
        fill.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fill.lineTo(point.dx, point.dy);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < weights.length; i++) {
      canvas.drawCircle(pointFor(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_WeightPainter oldDelegate) =>
      oldDelegate.weights != weights;
}
