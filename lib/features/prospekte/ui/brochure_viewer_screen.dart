import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prospect_client/prospect_client.dart';

import '../prospekte_providers.dart';

/// Blättert durch die Seiten eines Prospekts.
///
/// [brochureRef] ist die serialisierte [BrochureId] (`kaufda:72a3...`),
/// [initialPage] die 1-basierte Startseite, etwa aus einem Suchtreffer.
class BrochureViewerScreen extends ConsumerStatefulWidget {
  const BrochureViewerScreen({
    super.key,
    required this.brochureRef,
    this.initialPage,
  });

  final String brochureRef;
  final int? initialPage;

  @override
  ConsumerState<BrochureViewerScreen> createState() =>
      _BrochureViewerScreenState();
}

class _BrochureViewerScreenState extends ConsumerState<BrochureViewerScreen> {
  PageController? _controller;
  int _current = 1;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(Brochure brochure) {
    if (_controller != null) return _controller!;
    final start = (widget.initialPage ?? 1).clamp(1, brochure.pages.length);
    _current = start;
    return _controller = PageController(initialPage: start - 1);
  }

  void _goTo(int page, int pageCount) {
    final target = page.clamp(1, pageCount);
    _controller?.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(brochureDetailProvider(widget.brochureRef));

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.title ?? 'Prospekt'),
        toolbarHeight: 44,
        actions: [
          if (detail.value != null &&
              detail.value!.validUntil != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'bis ${DateFormat('d.M.').format(detail.value!.validUntil!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Der Prospekt konnte nicht geladen werden.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .invalidate(brochureDetailProvider(widget.brochureRef)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (brochure) {
          if (brochure.pages.isEmpty) {
            return const Center(child: Text('Dieser Prospekt hat keine Seiten.'));
          }
          final controller = _controllerFor(brochure);
          final pageCount = brochure.pages.length;
          return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _goTo(_current + 1, pageCount);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _goTo(_current - 1, pageCount);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Am Desktop blaettert ein PageView standardmaessig
                      // nicht per Maus, deshalb Maus/Trackpad ausdruecklich
                      // als Zieh-Geraete zulassen.
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: PageView.builder(
                          controller: controller,
                          itemCount: pageCount,
                          onPageChanged: (index) =>
                              setState(() => _current = index + 1),
                          itemBuilder: (context, index) =>
                              _PageView(page: brochure.pages[index]),
                        ),
                      ),
                      _PageArrow(
                        alignment: Alignment.centerLeft,
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Vorherige Seite',
                        onPressed: _current <= 1
                            ? null
                            : () => _goTo(_current - 1, pageCount),
                      ),
                      _PageArrow(
                        alignment: Alignment.centerRight,
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Nächste Seite',
                        onPressed: _current >= pageCount
                            ? null
                            : () => _goTo(_current + 1, pageCount),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Seite $_current von $pageCount',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Halbtransparenter Blaetterpfeil am Seitenrand.
class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
        ),
      ),
    );
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final BrochurePage page;

  @override
  Widget build(BuildContext context) {
    final uri = page.images.normal ?? page.images.best;
    if (uri == null) {
      return const Center(child: Icon(Icons.image_not_supported_outlined));
    }
    return InteractiveViewer(
      maxScale: 5,
      child: Center(
        child: Image.network(
          uri.toString(),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}
