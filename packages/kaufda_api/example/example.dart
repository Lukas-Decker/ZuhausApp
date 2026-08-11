// Beispiel: Prospekt laden, Angebote auswerten, Filiale anzeigen.
//
// Ausfuehren mit: dart run example/example.dart
import 'package:kaufda_api/kaufda_api.dart';

const brochureId = '72a3b683-90ff-4d09-9815-6baebe0a1b1d';
const location = GeoLocation(
  lat: 49.6378338,
  lng: 7.1113922,
  zip: '55767',
  city: 'Brücken',
);

Future<void> main() async {
  // Ohne sessionProvider holt sich der Client anonym einen Token von
  // https://www.kaufda.de/sessionData und erneuert ihn bei Ablauf selbst.
  final client = KaufdaClient(location: location);

  try {
    // Prospekte im Umkreis, ohne dass man vorher eine ID kennen muss.
    final umkreis = await client.shelfAll(onlyValid: true);
    print('${umkreis.length} Prospekte in der Naehe:');
    for (final prospekt in umkreis.take(5)) {
      print('  ${prospekt.publisher.name}: ${prospekt.title}');
    }
    print('');

    final brochure = await client.brochure(brochureId);
    print('${brochure.publisher.name}: ${brochure.title}');
    print('${brochure.pageCount} Seiten, gueltig bis ${brochure.validUntil}');

    final pages = await client.pages(brochureId);
    final offers = [for (final page in pages) ...page.offerContents];
    print('\n${offers.length} Angebote gefunden.');

    final guenstigste = offers.where((o) => o.bestDeal?.min != null).toList()
      ..sort((a, b) => a.bestDeal!.min!.compareTo(b.bestDeal!.min!));
    print('\nDie fuenf guenstigsten:');
    for (final offer in guenstigste.take(5)) {
      final deal = offer.bestDeal!;
      print('  ${deal.min!.toStringAsFixed(2)} ${deal.currencyCode}  '
          '${offer.displayName}');
    }

    final store = await client.nearestStore(brochureId);
    if (store != null) {
      print('\nNaechste Filiale: ${store.address} '
          '(${store.distance!.toStringAsFixed(1)} km, '
          '${store.isOpen ? 'offen' : 'geschlossen'})');
    }

    final related = await client.related(brochureId);
    print('\nWeitere Prospekte von ${brochure.publisher.name}:');
    for (final item in related.publisherBrochures) {
      print('  ${item.content.title} (${item.content.id})');
    }
  } finally {
    client.close();
  }
}
