import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory_providers.dart';

/// Zeigt das Produktbild (lokal zwischengespeichert) oder ersatzweise ein
/// Symbol, wenn kein Bild vorhanden ist.
class ProductThumbnail extends ConsumerWidget {
  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.size = 42,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    Widget fallback() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: scheme.onSurfaceVariant),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback();

    final image = ref.watch(productImageProvider(url));
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image.when(
        data: (file) => file == null
            ? fallback()
            : Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback(),
              ),
        loading: fallback,
        error: (_, _) => fallback(),
      ),
    );
  }
}
