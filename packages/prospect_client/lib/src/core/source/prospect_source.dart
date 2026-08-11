import 'package:meta/meta.dart';

import '../models/brochure.dart';
import '../models/geo.dart';
import '../models/offer.dart';
import '../models/retailer.dart';
import '../models/store.dart';

/// Was ein Adapter kann.
///
/// Verhindert, dass das Repository einen Adapter etwas fragt, was er nicht
/// leisten kann. Schwarz kennt zum Beispiel keine Umkreissuche, sondern nur
/// Regionscodes. Statt dort eine Exception zu werfen, wird die Quelle fuer
/// diese Abfrage schlicht uebersprungen.
@immutable
class SourceCapabilities {
  const SourceCapabilities({
    this.supportsGeoSearch = false,
    this.supportsPostalCode = false,
    this.supportsOfferSearch = false,
    this.supportsStores = false,
    this.providesPrices = false,
    this.providesPdf = false,
    this.requiresRegion = false,
  });

  /// True, wenn die Quelle mit Koordinaten umgehen kann.
  final bool supportsGeoSearch;

  /// True, wenn die Quelle mit Postleitzahlen arbeitet.
  ///
  /// Marktguru kennt ausschliesslich Postleitzahlen, Tjek ausschliesslich
  /// Koordinaten. Beides als "Ort" zusammenzufassen waere unsauber, weil eine
  /// Umrechnung einen Geocoding-Dienst braeuchte, den dieses Modul bewusst
  /// nicht mitbringt.
  final bool supportsPostalCode;
  final bool supportsOfferSearch;
  final bool supportsStores;
  final bool providesPrices;
  final bool providesPdf;

  /// True, wenn Prospektabrufe ohne Regionsangabe fehlschlagen.
  final bool requiresRegion;

  Map<String, Object?> toJson() => {
        'supportsGeoSearch': supportsGeoSearch,
        'supportsPostalCode': supportsPostalCode,
        'supportsOfferSearch': supportsOfferSearch,
        'supportsStores': supportsStores,
        'providesPrices': providesPrices,
        'providesPdf': providesPdf,
        'requiresRegion': requiresRegion,
      };
}

/// Abfrage nach Haendlern.
@immutable
class RetailerQuery {
  const RetailerQuery({
    this.near,
    this.postalCode,
    this.radiusMeters = 50000,
  });

  final GeoPoint? near;

  /// Postleitzahl, fuer Quellen die keine Koordinaten kennen.
  final String? postalCode;

  final int radiusMeters;
}

/// Abfrage nach Prospekten.
@immutable
class BrochureQuery {
  const BrochureQuery({
    this.binding,
    this.near,
    this.postalCode,
    this.radiusMeters = 50000,
    this.includeExpired = false,
    this.includeOutOfArea = false,
    this.limit = 100,
  });

  /// Einschraenkung auf einen Haendler. Null bedeutet: alles, was die Quelle
  /// fuer die uebrigen Kriterien liefert.
  final SourceBinding? binding;

  final GeoPoint? near;

  /// Postleitzahl, fuer Quellen die keine Koordinaten kennen.
  final String? postalCode;

  final int radiusMeters;
  final bool includeExpired;

  /// Ob Prospekte mitgeliefert werden, deren Gueltigkeitsgebiet sich nicht
  /// bestimmen laesst.
  ///
  /// Standard ist false, und das aus einem handfesten Grund: ohne Ortsbezug
  /// liefert Tjek fuer HIT ueber 50 filialspezifische Wochenprospekte und
  /// Schwarz fuer Lidl rund 40 Regionalvarianten. Eine solche Liste ist fuer
  /// Nutzer wertlos, weil fast jeder Eintrag fuer eine andere Filiale gilt.
  /// Ohne Ort bleiben deshalb nur bundesweit gueltige Prospekte uebrig.
  ///
  /// True setzen, wenn bewusst alle Varianten gebraucht werden, etwa zur
  /// Analyse oder im Debugging.
  final bool includeOutOfArea;

  final int limit;
}

/// Abfrage nach Angeboten.
@immutable
class OfferQuery {
  const OfferQuery({
    required this.query,
    this.binding,
    this.near,
    this.postalCode,
    this.radiusMeters = 50000,
    this.limit = 50,
  });

  final String query;
  final SourceBinding? binding;
  final GeoPoint? near;

  /// Postleitzahl, fuer Quellen die keine Koordinaten kennen.
  final String? postalCode;

  final int radiusMeters;
  final int limit;
}

/// Abfrage nach Filialen.
@immutable
class StoreQuery {
  const StoreQuery({
    required this.binding,
    this.near,
    this.postalCode,
    this.radiusMeters = 50000,
    this.limit = 100,
  });

  final SourceBinding binding;
  final GeoPoint? near;

  /// Postleitzahl, fuer Quellen die keine Koordinaten kennen.
  final String? postalCode;

  final int radiusMeters;
  final int limit;
}

/// Ein Datenquellen-Adapter.
///
/// Eine neue Quelle anzubinden heisst: diese Schnittstelle implementieren und
/// den Adapter registrieren. Am Repository, am Cache, an der Fehlerbehandlung
/// und an der CLI wird nichts geaendert.
abstract interface class ProspectSource {
  /// Kurze, stabile ID. Geht in [BrochureId] ein und darf sich nicht aendern.
  String get id;

  /// Anzeigename fuer CLI und Debug-Ausgaben.
  String get displayName;

  SourceCapabilities get capabilities;

  /// Haendler, die diese Quelle kennt. Die zurueckgegebenen [Retailer] tragen
  /// bereits die kanonische ID und ein [SourceBinding] auf diese Quelle.
  Future<List<Retailer>> fetchRetailers(RetailerQuery query);

  /// Prospekte in der Listenansicht. `pages` und `offers` duerfen leer bleiben.
  Future<List<Brochure>> fetchBrochures(BrochureQuery query);

  /// Vollstaendiger Prospekt inklusive Seiten und, falls vorhanden, Angeboten.
  Future<Brochure> fetchBrochure(
    String nativeId, {
    Map<String, String> params = const {},
  });

  Future<List<Offer>> searchOffers(OfferQuery query);

  Future<List<Store>> fetchStores(StoreQuery query);

  /// Gibt Ressourcen frei. Nach dem Aufruf ist der Adapter nicht mehr nutzbar.
  void close();
}
