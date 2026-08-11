/// Logo-Beschaffung mit Rueckfallkette.
///
/// Nicht jede Prospekt-Quelle liefert zu jedem Haendler ein Logo. Deshalb
/// werden mehrere Kandidaten in fester Reihenfolge versucht:
///
/// 1. Logo aus den Prospekt-Quellen (kaufDA, Tjek), quellenuebergreifend
///    zusammengefuehrt.
/// 2. Clearbit-Logo zur Haendler-Domain (grosse, saubere Markenlogos).
/// 3. Google-Favicon-Dienst zur selben Domain (liefert praktisch immer
///    etwas, notfalls klein).
///
/// Die Domain kommt aus der Tabelle bekannter Ketten, sonst aus der
/// Website, die eine Quelle am Haendler mitliefert.
library;

import 'package:prospect_client/prospect_client.dart';

/// Domains der gaengigen deutschen Ketten, Schluessel ist die kanonische
/// Haendler-ID aus der RetailerRegistry.
const Map<String, String> _knownDomains = {
  'aldi-nord': 'aldi-nord.de',
  'aldi-sued': 'aldi-sued.de',
  'citti': 'citti-markt.de',
  'dm': 'dm.de',
  'edeka': 'edeka.de',
  'famila-nordost': 'famila-nordost.de',
  'famila-nordwest': 'famila.de',
  'globus': 'globus.de',
  'hit': 'hit.de',
  'kaufland': 'kaufland.de',
  'lidl': 'lidl.de',
  'mueller': 'mueller.de',
  'netto': 'netto-online.de',
  'norma': 'norma-online.de',
  'penny': 'penny.de',
  'rewe': 'rewe.de',
  'rossmann': 'rossmann.de',
  'tegut': 'tegut.com',
  'xxxlutz': 'xxxlutz.de',
};

/// Logo-Kandidaten fuer einen Haendler, beste Quelle zuerst.
///
/// Die Liste kann leer sein, dann bleibt nur das neutrale Platzhalter-Icon.
List<Uri> retailerLogoCandidates(String retailerId, Retailer? retailer) {
  final sourceLogo = retailer?.logo.smallest;
  final domain = _knownDomains[retailerId] ?? _domainFromWebsite(retailer);

  return [
    ?sourceLogo,
    if (domain != null) ...[
      Uri.https('logo.clearbit.com', '/$domain'),
      Uri.https('www.google.com', '/s2/favicons', {
        'domain': domain,
        'sz': '128',
      }),
    ],
  ];
}

String? _domainFromWebsite(Retailer? retailer) {
  final website = retailer?.website;
  if (website == null || website.isEmpty) return null;
  final uri = Uri.tryParse(
    website.contains('://') ? website : 'https://$website',
  );
  final host = uri?.host ?? '';
  if (host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}
