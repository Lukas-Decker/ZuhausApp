import 'package:kaufda_api/kaufda_api.dart' as kd;
import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/sources/kaufda/kaufda_mapper.dart';
import 'package:test/test.dart';

void main() {
  const mapper = KaufdaMapper();

  test('Seiten werden 1-basiert, Hotspots auf Prozent skaliert', () {
    final meta = kd.Brochure.fromJson({
      'id': 'b-1',
      'title': 'Wochenangebote',
      'type': 'static_brochure',
      'publisher': {'id': 'DE-1013', 'name': 'Lidl'},
      'pageCount': 2,
    });
    final pages = [
      kd.BrochurePage.fromJson({
        'number': 0,
        'images': [
          {'url': 'https://img/x.jpg', 'size': '768x1024'},
        ],
        'offers': [
          {
            'content': {
              'id': 'o-1',
              'type': 'offer',
              'products': [
                {'name': 'Kaffee', 'brandName': 'Marke'},
              ],
              'deals': [
                {'type': 'SALES_PRICE', 'min': 4.99, 'max': 4.99, 'currencyCode': 'EUR'},
                {'type': 'REGULAR_PRICE', 'min': 6.99, 'max': 6.99, 'currencyCode': 'EUR'},
              ],
              'parentContent': {
                'id': 'b-1',
                'page': {
                  'number': 0,
                  'area': {
                    'topLeft': {'x': 0.1, 'y': 0.2},
                    'bottomRight': {'x': 0.5, 'y': 0.6},
                  },
                },
              },
            },
          },
        ],
      }),
    ];

    final brochure = mapper.brochureDetail(meta, pages);

    expect(brochure.id.toString(), 'kaufda:b-1');
    expect(brochure.retailerId, 'lidl');
    expect(brochure.contentLevel, BrochureContentLevel.productsWithPrices);
    expect(brochure.pages.single.number, 1);

    final hotspot = brochure.pages.single.hotspots.single;
    expect(hotspot.left, closeTo(10, 0.001));
    expect(hotspot.top, closeTo(20, 0.001));
    expect(hotspot.width, closeTo(40, 0.001));
    expect(hotspot.height, closeTo(40, 0.001));
    expect(hotspot.offerId, 'o-1');

    final offer = brochure.offers.single;
    expect(offer.title, 'Marke Kaffee');
    expect(offer.pageNumber, 1);
    expect(offer.price!.current, 4.99);
    expect(offer.price!.previous, 6.99);
  });

  test('Suchtreffer: Streichpreis 0 bedeutet kein Streichpreis', () {
    final offer = mapper.searchOffer(
      kd.SearchOffer.fromJson({
        'id': 's-1',
        'title': 'Butter',
        'prices': {'mainPrice': 1.99, 'secondaryPrice': 0.0},
      }),
    );
    expect(offer!.price!.current, 1.99);
    expect(offer.price!.previous, isNull);
  });
}
