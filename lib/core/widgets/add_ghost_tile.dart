import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ein „Geister"-Element zum Hinzufuegen, das wie ein Skeleton/Platzhalter
/// aussieht (gestrichelter Rahmen) und beim Antippen die Add-Aktion ausloest.
///
/// Sitzt im Inhalt (z.B. am Ende einer Liste), nicht in der Navigationsleiste.
class AddGhostTile extends StatelessWidget {
  const AddGhostTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: scheme.outline, radius: 16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, this.radius = 16});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(_dash, metric.length - distance);
        dashed.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += _dash + _gap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
