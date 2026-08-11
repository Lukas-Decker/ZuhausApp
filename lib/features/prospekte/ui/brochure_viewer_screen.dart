import 'package:flutter/material.dart';
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
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: brochure.pages.length,
                  onPageChanged: (index) =>
                      setState(() => _current = index + 1),
                  itemBuilder: (context, index) =>
                      _PageView(page: brochure.pages[index]),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Seite $_current von ${brochure.pages.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          );
        },
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
