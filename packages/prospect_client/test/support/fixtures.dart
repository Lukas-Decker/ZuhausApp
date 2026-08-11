import 'dart:convert';
import 'dart:io';

/// Laedt eingefrorene, echte API-Antworten aus `test/fixtures`.
///
/// Bewusst echte Antworten und keine handgeschriebenen Beispiele: die
/// Eigenheiten dieser Quellen, etwa `pre_price: null`, HTML-Entities in
/// Beschreibungen oder Polygone statt Rechtecken, faende man sich sonst nie
/// selbst aus, und genau daran scheitert das Mapping im Betrieb.
class Fixtures {
  static const String _dir = 'test/fixtures';

  static String raw(String name) => File('$_dir/$name').readAsStringSync();

  static List<Map<String, Object?>> list(String name) =>
      (jsonDecode(raw(name)) as List).cast<Map<String, Object?>>();

  static Map<String, Object?> object(String name) =>
      jsonDecode(raw(name)) as Map<String, Object?>;

  // Tjek
  static List<Map<String, Object?>> get tjekCatalogs => list('tjek_catalogs.json');
  static List<Map<String, Object?>> get tjekPages => list('tjek_pages.json');
  static List<Map<String, Object?>> get tjekHotspots => list('tjek_hotspots.json');
  static List<Map<String, Object?>> get tjekOffers => list('tjek_offers.json');
  static List<Map<String, Object?>> get tjekStores => list('tjek_stores.json');

  // Schwarz
  static Map<String, Object?> get schwarzFlyerKaufland =>
      object('schwarz_flyer_kaufland.json');
  static Map<String, Object?> get schwarzOverviewLidl =>
      object('schwarz_overview_lidl.json');
}
