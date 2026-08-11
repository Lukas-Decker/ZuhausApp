import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prospect_client/prospect_client.dart';

import '../../../app/navigation.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../prospekte_providers.dart';
import 'location_dialog.dart';

/// Prospekte und Angebote: Unterseite des Einkauf-Moduls.
///
/// Die Suche steht bewusst an erster Stelle: der Hauptzweck ist, zu einem
/// gesuchten Artikel die aktuellen Angebote der Supermärkte zu sehen. Die
/// Prospektübersicht darunter ist der Einstieg zum Blättern.
class ProspekteScreen extends ConsumerStatefulWidget {
  const ProspekteScreen({super.key});

  @override
  ConsumerState<ProspekteScreen> createState() => _ProspekteScreenState();
}

class _ProspekteScreenState extends ConsumerState<ProspekteScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) => setState(() => _query = value.trim());

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(prospekteLocationProvider);

    return ModuleScaffold(
      title: 'Prospekte',
      actions: [
        IconButton(
          tooltip: location == null
              ? 'Standort festlegen'
              : 'Standort: ${location.label}',
          onPressed: () => showProspekteLocationDialog(context, ref),
          icon: Icon(
            location == null
                ? Icons.location_off_outlined
                : Icons.location_on_outlined,
          ),
        ),
      ],
      body: location == null
          ? EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Standort fehlt',
              message:
                  'Prospekte und Angebote gelten immer für einen Ort. '
                  'Lege deine Postleitzahl fest, um loszulegen.',
              action: FilledButton.icon(
                onPressed: () => showProspekteLocationDialog(context, ref),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Postleitzahl festlegen'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Angebote suchen, z.B. Kaffee',
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Suche leeren',
                              onPressed: () {
                                _searchController.clear();
                                _search('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                    onSubmitted: _search,
                  ),
                ),
                Expanded(
                  child: _query.isEmpty
                      ? const _BrochureGrid()
                      : _OfferResults(query: _query),
                ),
              ],
            ),
    );
  }
}

String _validityText(DateTime? from, DateTime? until) {
  final format = DateFormat('d.M.');
  if (from == null && until == null) return '';
  if (until == null) return 'ab ${format.format(from!)}';
  return 'bis ${format.format(until)}';
}

/// Hinweisbanner für Teilausfälle: Daten sind da, aber eine Quelle fehlte.
class _PartialWarning extends StatelessWidget {
  const _PartialWarning({required this.result});

  final SourceResult<Object?> result;

  @override
  Widget build(BuildContext context) {
    if (!result.isPartial) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Eine Quelle war nicht erreichbar, die Liste kann '
              'unvollständig sein.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Angebotssuche ----------------------------------------------------------

class _OfferResults extends ConsumerWidget {
  const _OfferResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(offerSearchProvider(query));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Die Suche ist fehlgeschlagen.',
        detail: '$error',
        onRetry: () => ref.invalidate(offerSearchProvider(query)),
      ),
      data: (result) {
        if (result.data.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Keine Angebote',
            message:
                'Zu "$query" gibt es gerade keine Angebote in deiner Nähe.',
          );
        }
        return Column(
          children: [
            _PartialWarning(result: result),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: result.data.length,
                itemBuilder: (context, index) =>
                    _OfferTile(offer: result.data[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = offer.price;
    final validity = _validityText(offer.validFrom, offer.validUntil);
    final subtitle = [
      if (offer.retailerName != null) offer.retailerName!,
      if (validity.isNotEmpty) validity,
    ].join(' · ');

    return ListTile(
      leading: _Thumb(uri: offer.image.smallest, icon: Icons.local_offer_outlined),
      title: Text(offer.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: price == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price.formatted ??
                      '${price.current.toStringAsFixed(2)} €',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (price.previous != null)
                  Text(
                    price.previous!.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
      onTap: offer.brochureRef == null
          ? null
          : () => context.go(
                Uri(
                  path: '${AppModule.shopping.path}/prospekte/ansicht',
                  queryParameters: {
                    'id': offer.brochureRef!,
                    if (offer.pageNumber != null)
                      'seite': '${offer.pageNumber}',
                  },
                ).toString(),
              ),
    );
  }
}

// --- Prospektübersicht ------------------------------------------------------

class _BrochureGrid extends ConsumerWidget {
  const _BrochureGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(nearbyBrochuresProvider);

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: 'Prospekte konnten nicht geladen werden.',
        detail: '$error',
        onRetry: () => ref.invalidate(nearbyBrochuresProvider),
      ),
      data: (result) {
        if (result.data.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Keine Prospekte',
            message: 'In deiner Nähe wurden gerade keine Prospekte gefunden.',
          );
        }
        final width = MediaQuery.sizeOf(context).width;
        final columns = (width / 180).floor().clamp(2, 6);
        return Column(
          children: [
            _PartialWarning(result: result),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: result.data.length,
                itemBuilder: (context, index) =>
                    _BrochureCard(brochure: result.data[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrochureCard extends StatelessWidget {
  const _BrochureCard({required this.brochure});

  final Brochure brochure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final validity = _validityText(brochure.validFrom, brochure.validUntil);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          Uri(
            path: '${AppModule.shopping.path}/prospekte/ansicht',
            queryParameters: {'id': brochure.id.toString()},
          ).toString(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Thumb(
                uri: brochure.cover.normal ?? brochure.cover.best,
                icon: Icons.menu_book_outlined,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brochure.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (validity.isNotEmpty)
                    Text(
                      validity,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Bausteine --------------------------------------------------------------

class _Thumb extends StatelessWidget {
  const _Thumb({required this.uri, required this.icon, this.fit});

  final Uri? uri;
  final IconData icon;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(icon, color: scheme.onSurfaceVariant),
    );
    if (uri == null) {
      return fit == null
          ? SizedBox(width: 48, height: 48, child: placeholder)
          : placeholder;
    }
    final image = Image.network(
      uri.toString(),
      fit: fit ?? BoxFit.contain,
      errorBuilder: (_, _, _) => placeholder,
    );
    return fit == null
        ? SizedBox(
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: image,
            ),
          )
        : image;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: message,
      message: detail,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Erneut versuchen'),
      ),
    );
  }
}
