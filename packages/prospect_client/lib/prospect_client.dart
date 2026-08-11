/// Digitale Prospekte deutscher Supermaerkte und Einzelhandelsketten.
///
/// Reines Dart, ohne Flutter-Abhaengigkeit. Die Kernlogik laeuft unveraendert
/// in der CLI, im Test und in einer Flutter-App.
///
/// Einstiegspunkt fuer Anwendungen ist [ProspectClient.create]:
///
/// ```dart
/// final client = ProspectClient.create(cacheDirectory: dir);
/// final result = await client.repository.getBrochures(retailerId: 'netto');
/// ```
library;

import 'dart:io';

import 'src/core/cache/cache_store.dart';
import 'src/core/cache/file_cache_store.dart';
import 'src/core/http/api_client.dart';
import 'src/core/http/cache_policy.dart';
import 'src/core/models/geo.dart';
import 'src/core/repository/default_prospect_repository.dart';
import 'src/core/repository/prospect_repository.dart';
import 'src/core/source/prospect_source.dart';
import 'src/core/source/source_credentials.dart';
import 'src/sources/kaufda/kaufda_source.dart';
import 'src/sources/marktguru/marktguru_api.dart';
import 'src/sources/marktguru/marktguru_source.dart';
import 'src/sources/schwarz/schwarz_source.dart';
import 'src/sources/tjek/tjek_source.dart';

export 'src/core/cache/cache_store.dart'
    show CacheEntry, CacheStats, CacheStore, MemoryCacheStore, NullCacheStore;
export 'src/core/cache/file_cache_store.dart' show FileCacheStore;
export 'src/core/errors/prospect_exception.dart';
export 'src/core/errors/source_result.dart' show SourceResult;
export 'src/core/http/api_client.dart' show ApiClient;
export 'src/core/http/cache_policy.dart' show CacheKind, CachePolicy;
export 'src/core/models/brochure.dart'
    show Brochure, BrochureContentLevel, BrochureCoverage, BrochureId;
export 'src/core/models/brochure_page.dart'
    show BrochurePage, Hotspot, PageDimensions;
export 'src/core/models/geo.dart' show GeoPoint;
export 'src/core/models/image_set.dart' show ImageSet;
export 'src/core/models/offer.dart' show Offer;
export 'src/core/models/price.dart' show Price, Quantity;
export 'src/core/models/retailer.dart' show Retailer, SourceBinding;
export 'src/core/models/store.dart' show Store;
export 'src/core/repository/prospect_repository.dart' show ProspectRepository;
export 'src/core/source/prospect_source.dart'
    show
        BrochureQuery,
        OfferQuery,
        ProspectSource,
        RetailerQuery,
        SourceCapabilities,
        StoreQuery;
export 'src/core/source/retailer_registry.dart' show RetailerRegistry;
export 'src/core/source/source_credentials.dart'
    show CredentialKey, SourceCredentials;
export 'src/sources/kaufda/kaufda_source.dart' show KaufdaSource;
export 'src/sources/marktguru/marktguru_source.dart' show MarktguruSource;
export 'src/sources/schwarz/schwarz_source.dart' show SchwarzSource;
export 'src/sources/tjek/tjek_source.dart' show TjekSource;

/// Fertig verdrahtete Instanz des Moduls.
///
/// Kapselt Cache, HTTP-Client und Adapter, damit eine App nur einen Aufruf
/// braucht und nicht die interne Verdrahtung kennen muss.
class ProspectClient {
  ProspectClient._({
    required this.repository,
    required ApiClient client,
    required this.cache,
    this.credentials = const SourceCredentials.none(),
  }) : _client = client;

  /// Verdrahtet alle standardmaessig verfuegbaren Adapter.
  ///
  /// [cacheDirectory] wird von aussen hereingereicht, damit das Package nichts
  /// ueber Flutter oder `path_provider` wissen muss. In einer App typischerweise
  /// `(await getApplicationSupportDirectory()).path`. Ohne Angabe wird ein
  /// Verzeichnis im Systemtemp genutzt.
  factory ProspectClient.create({
    String? cacheDirectory,
    CachePolicy policy = CachePolicy.defaults,
    CacheStore? cacheStore,
    Duration timeout = const Duration(seconds: 20),
    SourceCredentials? credentials,
    String defaultPostalCode = '10115',
    GeoPoint? defaultLocation,
  }) {
    final cache = cacheStore ??
        (cacheDirectory == null
            ? FileCacheStore.temporary()
            : FileCacheStore(Directory(cacheDirectory)));

    final client = ApiClient(cache: cache, policy: policy, timeout: timeout);
    final creds = credentials ?? SourceCredentials.fromEnvironment();

    // Nur registriert, wenn Zugangsdaten vorliegen. Eine Quelle, die bei
    // jedem Aufruf mit HTTP 401 scheitert, waere schlechter als gar keine.
    final marktguru =
        MarktguruSource.maybe(client, creds, defaultZipCode: defaultPostalCode);

    final sources = <ProspectSource>[
      TjekSource(client),
      SchwarzSource(client, credentials: creds),
      // Strikt ortsgebunden: ohne defaultLocation antwortet der Adapter nur
      // auf Abfragen, die selbst Koordinaten mitbringen.
      KaufdaSource(defaultLocation: defaultLocation),
      if (marktguru != null) marktguru,
    ];

    return ProspectClient._(
      repository: DefaultProspectRepository(
        sources: sources,
        cache: cache,
        client: client,
      ),
      client: client,
      cache: cache,
      credentials: creds,
    );
  }

  /// Quellen, die mangels Zugangsdaten nicht registriert wurden, mit den
  /// Namen der fehlenden Umgebungsvariablen.
  ///
  /// Fuer `prospect_client sources` und fuer Apps, die dem Nutzer erklaeren
  /// wollen, warum ein Haendler fehlt.
  Map<String, List<String>> get inactiveSources => {
        if (!credentials.hasAll(MarktguruApi.requiredCredentials))
          'marktguru': credentials.missingFor(MarktguruApi.requiredCredentials),
      };

  /// Variante fuer Tests und Sonderfaelle: die Adapter werden vorgegeben.
  factory ProspectClient.withSources({
    required List<ProspectSource> sources,
    required ApiClient client,
    required CacheStore cache,
  }) =>
      ProspectClient._(
        repository: DefaultProspectRepository(
          sources: sources,
          cache: cache,
          client: client,
        ),
        client: client,
        cache: cache,
      );

  /// Die einzige Schnittstelle, die eine App braucht.
  final ProspectRepository repository;

  final CacheStore cache;

  /// Die konfigurierten Zugangsdaten. Enthaelt nur, was hinterlegt wurde.
  final SourceCredentials credentials;

  final ApiClient _client;

  void close() {
    repository.close();
    _client.close();
  }
}
