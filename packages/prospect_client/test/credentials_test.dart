import 'package:prospect_client/prospect_client.dart';
import 'package:prospect_client/src/sources/marktguru/marktguru_api.dart';
import 'package:test/test.dart';

import 'support/fake_http_client.dart';

void main() {
  group('SourceCredentials', () {
    test('liest die bekannten Variablen aus der Umgebung', () {
      final creds = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': 'a',
        'MARKTGURU_CLIENT_KEY': 'b',
        'UNBETEILIGT': 'c',
      });

      expect(creds[CredentialKey.marktguruApiKey], 'a');
      expect(creds[CredentialKey.marktguruClientKey], 'b');
      expect(creds.has(CredentialKey.schwarzStoresApiKey), isFalse);
    });

    test('behandelt leere und nur aus Leerzeichen bestehende Werte als fehlend',
        () {
      final creds = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': '',
        'MARKTGURU_CLIENT_KEY': '   ',
      });
      expect(creds.has(CredentialKey.marktguruApiKey), isFalse);
      expect(creds.has(CredentialKey.marktguruClientKey), isFalse);
    });

    test('schneidet Leerzeichen ab', () {
      // Kopierte Schluessel tragen haeufig ein Leerzeichen oder Zeilenende mit.
      final creds = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': '  geheim  ',
      });
      expect(creds[CredentialKey.marktguruApiKey], 'geheim');
    });

    test('meldet fehlende Variablen mit ihrem Umgebungsnamen', () {
      final creds = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': 'a',
      });

      expect(creds.hasAll(MarktguruApi.requiredCredentials), isFalse);
      expect(
        creds.missingFor(MarktguruApi.requiredCredentials),
        ['MARKTGURU_CLIENT_KEY'],
      );
    });

    test('erlaubt Nachtragen aus einem sicheren Speicher', () {
      final creds = const SourceCredentials.none()
          .withValues({CredentialKey.marktguruApiKey: 'a'});
      expect(creds[CredentialKey.marktguruApiKey], 'a');
    });

    test('gibt in toString keine Werte preis', () {
      // Ein versehentlich geloggtes Credentials-Objekt darf kein Geheimnis
      // ausplaudern.
      final creds = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': 'streng-geheim',
      });
      expect(creds.toString(), isNot(contains('streng-geheim')));
      expect(creds.configuredKeys, ['marktguruApiKey']);
    });
  });

  group('Registrierung von Quellen', () {
    ApiClient client() => ApiClient(
          cache: MemoryCacheStore(),
          httpClient: FakeHttpClient.json(const []),
          minRequestInterval: Duration.zero,
        );

    test('laesst Marktguru ohne Zugangsdaten weg', () {
      expect(
        MarktguruSource.maybe(client(), const SourceCredentials.none()),
        isNull,
      );
    });

    test('laesst Marktguru bei unvollstaendigen Zugangsdaten weg', () {
      final partial =
          SourceCredentials.fromEnvironment({'MARKTGURU_API_KEY': 'a'});
      expect(MarktguruSource.maybe(client(), partial), isNull);
    });

    test('registriert Marktguru mit vollstaendigen Zugangsdaten', () {
      final full = SourceCredentials.fromEnvironment({
        'MARKTGURU_API_KEY': 'a',
        'MARKTGURU_CLIENT_KEY': 'b',
      });
      final source = MarktguruSource.maybe(client(), full);

      expect(source, isNotNull);
      expect(source!.id, 'marktguru');
      expect(source.capabilities.supportsPostalCode, isTrue);
      expect(source.capabilities.supportsGeoSearch, isFalse,
          reason: 'Marktguru kennt nur Postleitzahlen');
    });

    test('ProspectClient meldet inaktive Quellen mit fehlenden Variablen', () {
      final client = ProspectClient.create(
        cacheStore: MemoryCacheStore(),
        credentials: const SourceCredentials.none(),
      );
      addTearDown(client.close);

      expect(client.repository.sources.map((s) => s.id),
          ['tjek', 'schwarz', 'kaufda']);
      expect(client.inactiveSources['marktguru'],
          ['MARKTGURU_API_KEY', 'MARKTGURU_CLIENT_KEY']);
    });

    test('ProspectClient registriert Marktguru mit Zugangsdaten', () {
      final client = ProspectClient.create(
        cacheStore: MemoryCacheStore(),
        credentials: SourceCredentials.fromEnvironment({
          'MARKTGURU_API_KEY': 'a',
          'MARKTGURU_CLIENT_KEY': 'b',
        }),
      );
      addTearDown(client.close);

      expect(
        client.repository.sources.map((s) => s.id),
        ['tjek', 'schwarz', 'kaufda', 'marktguru'],
      );
      expect(client.inactiveSources, isEmpty);
    });
  });

  group('Schluessel gelangen in die Anfrage', () {
    test('sendet x-apikey und x-clientkey', () async {
      final http = FakeHttpClient.json(const []);
      final api = MarktguruApi(
        ApiClient(
          cache: MemoryCacheStore(),
          httpClient: http,
          minRequestInterval: Duration.zero,
        ),
        apiKey: 'schluessel',
        clientKey: 'mandant',
      );

      await api.searchOffers(zipCode: '10115');

      expect(http.requests.single.headers['x-apikey'], 'schluessel');
      expect(http.requests.single.headers['x-clientkey'], 'mandant');
      expect(
        http.requests.single.url.queryParameters['zipCode'],
        '10115',
      );
    });

    test('holt Bilder ohne Zugangsdaten vom CDN', () {
      final api = MarktguruApi(
        ApiClient(
          cache: MemoryCacheStore(),
          httpClient: FakeHttpClient.json(const []),
          minRequestInterval: Duration.zero,
        ),
        apiKey: 'a',
        clientKey: 'b',
      );

      expect(
        api.leafletPageImage('5759348', 0).toString(),
        'https://cdn.marktguru.de/api/v1/leaflets/5759348/images/pages/0/large.webp',
      );
      expect(
        api.offerImage('24389293', size: 'small').toString(),
        'https://cdn.marktguru.de/api/v1/offers/24389293/images/default/0/small.webp',
      );
      expect(
        api.retailerLogo('126802').toString(),
        'https://cdn.marktguru.de/api/v1/retailers/126802/images/logos/0/medium.webp',
      );
    });
  });
}
