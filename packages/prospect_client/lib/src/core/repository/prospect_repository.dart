import '../errors/prospect_exception.dart';
import '../errors/source_result.dart';
import '../models/brochure.dart';
import '../models/geo.dart';
import '../models/offer.dart';
import '../models/retailer.dart';
import '../models/store.dart';
import '../source/prospect_source.dart';

/// Die einzige Schnittstelle, die eine App kennen muss.
///
/// Es gibt bewusst keine Methode, die eine Quelle benennt. Die App fragt nach
/// Haendlern und Prospekten, nicht nach Tjek oder Schwarz. Welche Quelle
/// antwortet, entscheidet die Implementierung.
abstract interface class ProspectRepository {
  /// Alle bekannten Haendler. Mit [near] werden nur Haendler geliefert, die im
  /// Umkreis tatsaechlich Prospekte veroeffentlichen.
  Future<SourceResult<List<Retailer>>> getRetailers({
    GeoPoint? near,
    int radiusMeters = 50000,
  });

  /// Ein einzelner Haendler samt aller Quellenbindungen, null wenn unbekannt.
  Future<Retailer?> getRetailer(String retailerId, {GeoPoint? near});

  /// Prospekte in der Listenansicht. `pages` und `offers` bleiben leer, das
  /// spart bei Netto rund 300 Angebote pro Prospekt, die in einer Liste
  /// ohnehin niemand braucht.
  ///
  /// Der Ortsbezug ist wichtiger, als er aussieht: Prospekte sind ueberwiegend
  /// filialabhaengig. HIT veroeffentlicht denselben Wochenprospekt in ueber 50
  /// Filialvarianten, Lidl in rund 40 Regionalvarianten, Kaufland je Filiale.
  /// Ohne Ortsangabe kommen deshalb nur bundesweit gueltige Prospekte zurueck,
  /// zusammen mit einem Hinweis in [SourceResult.warnings].
  ///
  /// [near] und [postalCode] sind kein Duplikat: Tjek und Kaufland arbeiten mit
  /// Koordinaten, Marktguru ausschliesslich mit Postleitzahlen. Eine Umrechnung
  /// braeuchte einen Geocoding-Dienst, den dieses Modul nicht mitbringt. Wer
  /// alle Quellen ausschoepfen will, gibt beides an.
  ///
  /// [includeOutOfArea] hebt die Filterung auf und liefert alle Varianten.
  Future<SourceResult<List<Brochure>>> getBrochures({
    String? retailerId,
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
    bool includeExpired = false,
    bool includeOutOfArea = false,
    int limit = 100,
  });

  /// Filialen, in denen ein Prospekt gilt.
  ///
  /// Bei bundesweiten Prospekten leer, weil die Einschraenkung dort keine
  /// Aussage haette. Leer auch dann, wenn die Quelle die Zuordnung nicht
  /// preisgibt, etwa bei den Vertriebsgebieten von Lidl.
  Future<SourceResult<List<Store>>> getBrochureStores(Brochure brochure);

  /// Vollstaendiger Prospekt mit Seiten und, falls die Quelle sie hat,
  /// Angeboten.
  Future<Brochure> getBrochure(BrochureId id);

  /// Volltextsuche ueber Angebote aller Quellen, die das koennen.
  Future<SourceResult<List<Offer>>> searchOffers(
    String query, {
    String? retailerId,
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
    int limit = 50,
  });

  /// Filialen eines Haendlers. Leer, wenn keine Quelle Filialdaten liefert.
  Future<SourceResult<List<Store>>> getStores(
    String retailerId, {
    GeoPoint? near,
    String? postalCode,
    int radiusMeters = 50000,
  });

  /// Registrierte Adapter samt Faehigkeiten, fuer Diagnose und CLI.
  List<ProspectSource> get sources;

  /// Verwirft zwischengespeicherte Daten.
  Future<void> clearCache({bool expiredOnly = false});

  /// Gibt Ressourcen frei.
  void close();
}

/// Basisverhalten fuer Implementierungen, die mehrere Adapter buendeln.
///
/// Faengt jeden Adapterfehler ab und sammelt ihn, statt ihn nach oben zu
/// werfen. Damit ist die Zusage "keine Exception erreicht die UI" an einer
/// Stelle umgesetzt und nicht in jedem Adapter erneut.
mixin MultiSourceCollector {
  /// Fuehrt [action] fuer jeden Adapter aus und sammelt Ergebnisse und Fehler.
  Future<SourceResult<List<T>>> collect<T>(
    Iterable<ProspectSource> sources,
    Future<List<T>> Function(ProspectSource source) action, {
    bool Function(ProspectSource source)? filter,
    int Function(T, T)? sort,
  }) async {
    final builder = SourceResultBuilder<T>();

    final selected = filter == null ? sources : sources.where(filter);
    if (selected.isEmpty) {
      builder.addWarning('Keine Quelle unterstuetzt diese Abfrage');
      return builder.build(sort: sort);
    }

    // Parallel, weil die Quellen unabhaengig sind. Ein langsamer Adapter soll
    // die anderen nicht blockieren.
    final results = await Future.wait(
      selected.map((source) async {
        try {
          return (source: source, items: await action(source), error: null);
        } on ProspectException catch (e) {
          return (
            source: source,
            items: <T>[],
            error: e,
          );
        } on Object catch (e) {
          // Unerwartete Fehler werden eingepackt, damit auch ein Defekt im
          // Adapter nicht als roher Fehler bei der App landet.
          return (
            source: source,
            items: <T>[],
            error: ResponseParseFailure(
              'Unerwarteter Fehler in ${source.id}: $e',
              sourceId: source.id,
              cause: e,
            ) as ProspectException,
          );
        }
      }),
    );

    for (final result in results) {
      final error = result.error;
      if (error != null) {
        builder.addError(error);
      } else {
        builder.addAll(result.items);
      }
    }

    return builder.build(sort: sort);
  }
}
