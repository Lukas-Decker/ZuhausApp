// Beispiel fuer die Anbindung an eine Flutter-App.
//
// Diese Datei ist bewusst kein Teil des Packages und wird nicht kompiliert:
// das Package selbst hat keine Flutter-Abhaengigkeit, und genau das ist der
// Punkt. Der Code hier gehoert in die App, nicht in das Modul.
//
// Kernaussage: die App kennt ausschliesslich ProspectRepository. Ob die Daten
// von Tjek, von Schwarz oder spaeter von einer weiteren Quelle kommen, taucht
// nirgends auf.
//
// ignore_for_file: unused_element, avoid_print
library;

/*
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prospect_client/prospect_client.dart';

/// Einmalige Verdrahtung, z.B. in main() oder einem DI-Container.
///
/// Der einzige plattformabhaengige Punkt des ganzen Moduls: das
/// Cache-Verzeichnis wird von aussen hereingereicht. Damit muss das Package
/// weder path_provider noch Flutter kennen.
Future<ProspectClient> createProspectClient() async {
  final dir = await getApplicationSupportDirectory();
  return ProspectClient.create(cacheDirectory: '${dir.path}/prospects');
}

/// Liste der Prospekte eines Haendlers.
///
/// Zeigt die drei Zustaende, die in der Praxis auftreten: Ladevorgang,
/// Teilausfall einer Quelle und veraltete Daten ohne Netz. Ein Fehlerzustand
/// mit leerem Bildschirm ist nicht dabei, weil das Repository auch bei
/// Teilausfaellen nutzbare Daten liefert.
class BrochureListPage extends StatefulWidget {
  const BrochureListPage({
    super.key,
    required this.repository,
    required this.retailerId,
  });

  final ProspectRepository repository;
  final String retailerId;

  @override
  State<BrochureListPage> createState() => _BrochureListPageState();
}

class _BrochureListPageState extends State<BrochureListPage> {
  late Future<SourceResult<List<Brochure>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getBrochures(retailerId: widget.retailerId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getBrochures(retailerId: widget.retailerId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.retailerId)),
      body: FutureBuilder<SourceResult<List<Brochure>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data!;

          // Auch das ist ein normaler Zustand und keine Ausnahme: alle Quellen
          // ausgefallen und kein Cache vorhanden.
          if (result.isTotalFailure) {
            return _ErrorView(errors: result.errors, onRetry: _refresh);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                if (result.isStale)
                  const _Banner(
                    icon: Icons.cloud_off,
                    text: 'Offline. Angezeigt werden zuletzt geladene Daten.',
                  ),
                if (result.isPartial)
                  _Banner(
                    icon: Icons.warning_amber,
                    text: '${result.errors.length} Quelle(n) nicht erreichbar. '
                        'Die Liste kann unvollstaendig sein.',
                  ),
                for (final brochure in result.data)
                  _BrochureTile(
                    brochure: brochure,
                    repository: widget.repository,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrochureTile extends StatelessWidget {
  const _BrochureTile({required this.brochure, required this.repository});

  final Brochure brochure;
  final ProspectRepository repository;

  @override
  Widget build(BuildContext context) {
    final cover = brochure.cover.smallest;

    return ListTile(
      leading: cover == null
          ? const Icon(Icons.article_outlined)
          : Image.network(
              cover.toString(),
              width: 48,
              fit: BoxFit.cover,
              // Fehlende Bilder sind haeufig und duerfen die Liste nicht
              // zerreissen.
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
      title: Text(brochure.title),
      subtitle: Text(_subtitle(brochure)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BrochureDetailPage(
            repository: repository,
            id: brochure.id,
          ),
        ),
      ),
    );
  }

  /// Der Inhaltsgrad entscheidet, was die App ueberhaupt anbieten kann.
  /// "unknown" darf dabei nicht als "keine Angebote" durchgehen.
  String _subtitle(Brochure brochure) => switch (brochure.contentLevel) {
        BrochureContentLevel.unknown => 'Tippen zum Oeffnen',
        BrochureContentLevel.imagesOnly => '${brochure.pageCount} Seiten',
        BrochureContentLevel.productsWithoutPrices =>
          '${brochure.pageCount} Seiten mit Produkten',
        BrochureContentLevel.productsWithPrices =>
          '${brochure.pageCount} Seiten, Angebote mit Preisen',
      };
}

class BrochureDetailPage extends StatefulWidget {
  const BrochureDetailPage({
    super.key,
    required this.repository,
    required this.id,
  });

  final ProspectRepository repository;
  final BrochureId id;

  @override
  State<BrochureDetailPage> createState() => _BrochureDetailPageState();
}

class _BrochureDetailPageState extends State<BrochureDetailPage> {
  late Future<Brochure> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getBrochure(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Brochure>(
        future: _future,
        builder: (context, snapshot) {
          // getBrochure betrifft genau eine Quelle, hier gibt es kein
          // sinnvolles Teilergebnis, deshalb wirft nur diese eine Methode.
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Center(
              child: Text(
                error is ProspectException
                    ? error.message
                    : 'Prospekt konnte nicht geladen werden.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final brochure = snapshot.data!;

          // Erst hier steht der Inhaltsgrad fest.
          if (!brochure.contentLevel.hasProducts) {
            return _PageViewer(brochure: brochure);
          }
          return _OfferList(brochure: brochure);
        },
      ),
    );
  }
}

class _PageViewer extends StatelessWidget {
  const _PageViewer({required this.brochure});

  final Brochure brochure;

  @override
  Widget build(BuildContext context) => PageView.builder(
        itemCount: brochure.pages.length,
        itemBuilder: (context, index) {
          final page = brochure.pages[index];
          final image = page.images.normal ?? page.images.large;
          if (image == null) {
            return const Center(child: Text('Seite ohne Bild'));
          }
          return InteractiveViewer(
            child: Image.network(
              image.toString(),
              // altText liefert Schwarz brauchbar mit, direkt als Label nutzbar.
              semanticLabel: page.altText,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
          );
        },
      );
}

class _OfferList extends StatelessWidget {
  const _OfferList({required this.brochure});

  final Brochure brochure;

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: brochure.offers.length,
        itemBuilder: (context, index) {
          final offer = brochure.offers[index];
          final price = offer.price;

          return ListTile(
            title: Text(offer.title),
            subtitle: offer.description == null ? null : Text(offer.description!),
            // Preis kann fehlen: Kaufland liefert ueber Schwarz Produkte ohne
            // Preisangabe. Kein Platzhalterpreis erfinden.
            trailing: price == null
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${price.current.toStringAsFixed(2)} ${price.currency}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (price.hasDiscount)
                        Text(
                          '${price.previous!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
          );
        },
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.errors, required this.onRetry});

  final List<ProspectException> errors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final retryable = errors.any((e) => e.isRetryable);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(errors.first.message, textAlign: TextAlign.center),
          if (retryable) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ],
      ),
    );
  }
}
*/
