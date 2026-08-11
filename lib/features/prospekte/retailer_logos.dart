/// Haendler-Logos, fest in die App eingebacken.
///
/// Die Logos der gaengigen deutschen Ketten liegen als WebP unter
/// assets/logos/ (bezogen ueber Wikipedia/Wikimedia Commons, siehe
/// tool/fetch_retailer_logos.ps1). Eingebacken statt zur Laufzeit geladen,
/// weil die Prospekt-Quellen nicht zu jedem Haendler ein Logo liefern und
/// Favicon-Dienste zu kleine, pixelige Bilder ergeben.
///
/// Fuer Ketten ohne eingebautes Logo bleibt das Logo aus den
/// Prospekt-Quellen der Rueckfall, danach das neutrale Symbol.
library;

import 'package:prospect_client/prospect_client.dart';

/// Kanonische Haendler-IDs (RetailerRegistry), zu denen ein Logo unter
/// `assets/logos/<id>.webp` eingebacken ist.
const Set<String> _bakedLogoIds = {
  'aldi-nord',
  'aldi-sued',
  'citti',
  'dm',
  'edeka',
  'famila-nordost',
  'famila-nordwest',
  'globus',
  'hit',
  'ikea',
  'jysk',
  'kaufland',
  'kik',
  'lidl',
  'mediamarkt',
  'mueller',
  'netto',
  'norma',
  'penny',
  'rewe',
  'rossmann',
  'saturn',
  'tegut',
  'xxxlutz',
};

/// Asset-Pfad des eingebackenen Logos, null wenn keines vorliegt.
String? retailerLogoAsset(String retailerId) =>
    _bakedLogoIds.contains(retailerId)
        ? 'assets/logos/$retailerId.webp'
        : null;

/// Netzwerk-Rueckfall fuer Haendler ohne eingebautes Logo: das Logo, das
/// eine Prospekt-Quelle mitliefert. Kein Favicon-Dienst, die Bilder dort
/// sind zu klein und wirken pixelig.
List<Uri> retailerLogoCandidates(String retailerId, Retailer? retailer) {
  final sourceLogo = retailer?.logo.smallest;
  return [?sourceLogo];
}
