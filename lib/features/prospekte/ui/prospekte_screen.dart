import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:prospect_client/prospect_client.dart';

import '../../../app/navigation.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../prospekte_providers.dart';
import '../retailer_logos.dart';
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
  // Immer der volle Zeitraum: ein blosses "bis 29.8." verschweigt, dass ein
  // Prospekt womoeglich erst naechste Woche startet.
  if (from != null && until != null) {
    return '${format.format(from)} - ${format.format(until)}';
  }
  if (until != null) return 'bis ${format.format(until)}';
  if (from != null) return 'ab ${format.format(from)}';
  return '';
}

/// Kurzform einer Filiale fuer Listenzeilen: Strasse und Ort, ohne PLZ.
String _storeShort(Store store) {
  final street = store.street ?? '';
  final city = store.city ?? '';
  if (street.isNotEmpty && city.isNotEmpty) return '$street, $city';
  if (street.isNotEmpty) return street;
  if (city.isNotEmpty) return city;
  return store.name ?? '';
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

    // Filiale je Prospekt aus der (ohnehin geladenen) Prospektuebersicht,
    // damit ein Angebot sagen kann, wo es in der Naehe gilt.
    final stores = <String, Store>{
      for (final brochure
          in ref.watch(nearbyBrochuresProvider).value?.data ?? const [])
        if (brochure.closestStore != null)
          brochure.id.toString(): brochure.closestStore!,
    };

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
                itemBuilder: (context, index) {
                  final offer = result.data[index];
                  return _OfferTile(
                    offer: offer,
                    store: stores[offer.brochureRef],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({required this.offer, this.store});

  final Offer offer;

  /// Naechstgelegene Filiale des zugehoerigen Prospekts, falls bekannt.
  final Store? store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = offer.price;
    final validity = _validityText(offer.validFrom, offer.validUntil);
    final storeLabel = store == null ? '' : _storeShort(store!);
    final subtitle = [
      [
        if (offer.retailerName != null) offer.retailerName!,
        if (validity.isNotEmpty) validity,
      ].join(' · '),
      if (storeLabel.isNotEmpty) storeLabel,
    ].where((line) => line.isNotEmpty).join('\n');

    return ListTile(
      isThreeLine: storeLabel.isNotEmpty,
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

        // Nach Haendler gruppieren: ALDI Sued bei ALDI Sued, Lidl bei Lidl.
        // Innerhalb der Gruppe laufende Prospekte zuerst, dann kommende.
        final now = DateTime.now();
        final groups = <String, List<Brochure>>{};
        for (final brochure in result.data) {
          groups.putIfAbsent(brochure.retailerId, () => []).add(brochure);
        }
        // Unbekannte Haendler-IDs sind Slugs wie "netto-city": als Rueckfall
        // huebsch machen statt den Prospekttitel als Haendlernamen zu zeigen.
        String prettify(String slug) => slug
            .split('-')
            .map((part) =>
                part.isEmpty ? part : part[0].toUpperCase() + part.substring(1))
            .join(' ');
        String nameFor(String retailerId, List<Brochure> brochures) =>
            RetailerRegistry.displayName(retailerId, prettify(retailerId));
        final orderedIds = groups.keys.toList()
          ..sort((a, b) => nameFor(a, groups[a]!)
              .toLowerCase()
              .compareTo(nameFor(b, groups[b]!).toLowerCase()));
        for (final brochures in groups.values) {
          brochures.sort((a, b) {
            final aActive = a.isActiveAt(now) ? 0 : 1;
            final bActive = b.isActiveAt(now) ? 0 : 1;
            if (aActive != bActive) return aActive - bActive;
            final aFrom = a.validFrom ?? now;
            final bFrom = b.validFrom ?? now;
            return aFrom.compareTo(bFrom);
          });
        }

        final retailers =
            ref.watch(retailerIndexProvider).value ?? const <String, Retailer>{};

        return Column(
          children: [
            _PartialWarning(result: result),
            Expanded(
              // Kompaktes Haendler-Grid nach dem Muster
              // repeat(auto-fit, minmax(140, 1fr)): so viele Spalten wie
              // hineinpassen, jede mindestens 140 und flexibel gestreckt.
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: orderedIds.length,
                itemBuilder: (context, index) {
                  final retailerId = orderedIds[index];
                  final brochures = groups[retailerId]!;
                  return _RetailerCard(
                    name: nameFor(retailerId, brochures),
                    logoAsset: retailerLogoAsset(retailerId),
                    logoCandidates: retailerLogoCandidates(
                      retailerId,
                      retailers[retailerId],
                    ),
                    brochures: brochures,
                    now: now,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Kompakte Haendler-Kachel: Logo gross, Name darunter, Prospekt-Anzahl.
/// Ein Tipp oeffnet die Prospektauswahl des Haendlers.
class _RetailerCard extends StatelessWidget {
  const _RetailerCard({
    required this.name,
    required this.logoAsset,
    required this.logoCandidates,
    required this.brochures,
    required this.now,
  });

  final String name;
  final String? logoAsset;
  final List<Uri> logoCandidates;
  final List<Brochure> brochures;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCurrent = brochures.any((b) => b.isActiveAt(now));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSelection(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: _LogoThumb(
                        asset: logoAsset,
                        candidates: logoCandidates,
                        size: 56,
                      ),
                    ),
                    if (hasCurrent)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Aktuell',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                brochures.length == 1
                    ? '1 Prospekt'
                    : '${brochures.length} Prospekte',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSelection(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 900),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _LogoThumb(
                    asset: logoAsset,
                    candidates: logoCandidates,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: brochures.length,
                itemBuilder: (context, index) {
                  final brochure = brochures[index];
                  return _BrochureCard(
                    brochure: brochure,
                    isCurrent: brochure.isActiveAt(now),
                    popBeforeOpen: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrochureCard extends StatelessWidget {
  const _BrochureCard({
    required this.brochure,
    this.isCurrent = false,
    this.popBeforeOpen = false,
  });

  final Brochure brochure;

  /// True, wenn der Prospekt gerade laeuft: farbiger Rahmen plus
  /// "Aktuell"-Marke, damit er zwischen kommenden Varianten hervorsticht.
  final bool isCurrent;

  /// True, wenn die Karte in einem Bottom-Sheet liegt: das Sheet muss zu,
  /// bevor der Viewer aufgeht, sonst bleibt es ueber ihm stehen.
  final bool popBeforeOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final validity = _validityText(brochure.validFrom, brochure.validUntil);
    final store = brochure.closestStore;
    final storeLabel = store == null ? '' : _storeShort(store);
    final infoLine = [
      if (validity.isNotEmpty) validity,
      if (storeLabel.isNotEmpty) storeLabel,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isCurrent
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: () {
          final router = GoRouter.of(context);
          if (popBeforeOpen) Navigator.of(context).pop();
          router.go(
            Uri(
              path: '${AppModule.shopping.path}/prospekte/ansicht',
              queryParameters: {'id': brochure.id.toString()},
            ).toString(),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumb(
                    uri: brochure.cover.normal ?? brochure.cover.best,
                    icon: Icons.menu_book_outlined,
                    fit: BoxFit.cover,
                  ),
                  if (isCurrent)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Aktuell',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
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
                  if (infoLine.isNotEmpty)
                    Text(
                      infoLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  /// Kantenlaenge, wenn kein [fit] gesetzt ist (feste Kachel).
  static const double size = 48;

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
          ? SizedBox(width: size, height: size, child: placeholder)
          : placeholder;
    }
    final image = Image.network(
      uri.toString(),
      fit: fit ?? BoxFit.contain,
      errorBuilder: (_, _, _) => placeholder,
    );
    return fit == null
        ? SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: image,
            ),
          )
        : image;
  }
}

/// Haendler-Logo mit Rueckfallkette: zuerst das eingebackene Asset, dann die
/// Netz-Kandidaten der Quellen, am Ende das neutrale Symbol.
class _LogoThumb extends StatefulWidget {
  const _LogoThumb({
    required this.asset,
    required this.candidates,
    required this.size,
  });

  final String? asset;
  final List<Uri> candidates;
  final double size;

  @override
  State<_LogoThumb> createState() => _LogoThumbState();
}

class _LogoThumbState extends State<_LogoThumb> {
  /// -1 steht fuer das Asset, ab 0 zaehlen die Netz-Kandidaten.
  late int _index = widget.asset != null ? -1 : 0;

  @override
  void didUpdateWidget(covariant _LogoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset ||
        oldWidget.candidates != widget.candidates) {
      _index = widget.asset != null ? -1 : 0;
    }
  }

  void _tryNext() {
    // Nicht mitten im Build umschalten: der errorBuilder laeuft im Build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _index < widget.candidates.length) {
        setState(() => _index++);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.storefront_outlined, color: scheme.onSurfaceVariant),
    );

    Widget child;
    if (_index == -1) {
      child = Image.asset(
        widget.asset!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          _tryNext();
          return placeholder;
        },
      );
    } else if (_index >= widget.candidates.length) {
      child = placeholder;
    } else {
      child = Image.network(
        widget.candidates[_index].toString(),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          _tryNext();
          return placeholder;
        },
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
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
