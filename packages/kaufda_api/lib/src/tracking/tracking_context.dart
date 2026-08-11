import 'package:meta/meta.dart';

import '../geo.dart';
import '../models/json.dart';
import '../session.dart';

/// Statischer Teil eines Tracking-Events, also alles, was sich waehrend einer
/// Sitzung nicht aendert.
///
/// Die Standardwerte entsprechen dem, was das kaufDA-Web-Frontend sendet.
@immutable
class TrackingContext {
  const TrackingContext({
    this.deliveryChannel = 'dest.kaufda',
    this.environment = 'p',
    this.market = 'de',
    this.team = 'w3',
    this.eventVersion = '3.5',
    this.userPlatformCategory = 'desktop.web.browser',
    this.userPlatformOs = 'windows',
    this.userPlatformOsVersion = 'NT 10.0',
    this.userAgent,
    this.browser,
    this.browserVersion,
    this.partner = 'kaufda_web',
    this.deviceType = 'web_browser',
    this.pageType,
    this.visitOriginType,
    this.sourceType,
    this.sourceValue,
    this.trackingOptIn = false,
    this.externalTrackingOptIn = false,
    this.webPage,
    this.geo,
    this.experiments = const [],
    this.customExtras = const {},
  });

  /// `p` fuer Produktion.
  final String environment;
  final String deliveryChannel;
  final String market;
  final String team;
  final String eventVersion;

  final String userPlatformCategory;
  final String userPlatformOs;
  final String userPlatformOsVersion;
  final String? userAgent;
  final String? browser;
  final String? browserVersion;

  final String partner;
  final String deviceType;

  /// z. B. `SHELF_PAGE`.
  final String? pageType;

  /// z. B. `WEB_REFERRER_SEO`.
  final String? visitOriginType;

  /// z. B. `PORTAL_WIDGET`.
  final String? sourceType;
  final String? sourceValue;

  final bool trackingOptIn;
  final bool externalTrackingOptIn;

  final TrackingWebPage? webPage;
  final GeoLocation? geo;
  final List<Map<String, dynamic>> experiments;

  /// Zusaetzliche Felder im `custom`-Block.
  final Map<String, dynamic> customExtras;

  TrackingContext copyWith({
    TrackingWebPage? webPage,
    GeoLocation? geo,
    String? pageType,
    String? sourceType,
    String? sourceValue,
    String? visitOriginType,
    Map<String, dynamic>? customExtras,
  }) =>
      TrackingContext(
        deliveryChannel: deliveryChannel,
        environment: environment,
        market: market,
        team: team,
        eventVersion: eventVersion,
        userPlatformCategory: userPlatformCategory,
        userPlatformOs: userPlatformOs,
        userPlatformOsVersion: userPlatformOsVersion,
        userAgent: userAgent,
        browser: browser,
        browserVersion: browserVersion,
        partner: partner,
        deviceType: deviceType,
        pageType: pageType ?? this.pageType,
        visitOriginType: visitOriginType ?? this.visitOriginType,
        sourceType: sourceType ?? this.sourceType,
        sourceValue: sourceValue ?? this.sourceValue,
        trackingOptIn: trackingOptIn,
        externalTrackingOptIn: externalTrackingOptIn,
        webPage: webPage ?? this.webPage,
        geo: geo ?? this.geo,
        experiments: experiments,
        customExtras: customExtras ?? this.customExtras,
      );

  /// Baut den gemeinsamen Rumpf eines Events.
  Map<String, dynamic> envelope(KaufdaSession session) => compact({
        'delivery_channel': deliveryChannel,
        'environment': environment,
        'market': market,
        'team': team,
        'user_platform_category': userPlatformCategory,
        'user_platform_os': userPlatformOs,
        'user_platform_os_ver': userPlatformOsVersion,
        'user_session': compact({
          'session_id': session.visitId,
          'user_agent': userAgent,
          'browser': browser,
          'browser_ver': browserVersion,
          'web_id': session.visitId,
        }),
        'permissions_setting': {
          'tracking_opt_in': trackingOptIn ? 1 : 0,
          'external_tracking_opt_in': externalTrackingOptIn ? 1 : 0,
        },
        'custom': compact({
          'partner': partner,
          'device_type': deviceType,
          'session_token': session.authorizationHeader,
          'page_type': pageType,
          'visit_origin_type': visitOriginType,
          'source_type': sourceType,
          'source_value': sourceValue,
          ...customExtras,
        }),
        'web_page': webPage?.toJson(pageType),
        'geo': switch (geo) {
          final GeoLocation g => compact({
              'lat': g.lat,
              'lng': g.lng,
              'user_zip': g.zip,
            }),
          null => null,
        },
        'test': {'experiments': experiments},
      });
}

/// Der `web_page`-Block eines Events.
@immutable
class TrackingWebPage {
  const TrackingWebPage({
    required this.url,
    this.referrer,
    this.title,
    this.pageType,
  });

  final String url;
  final String? referrer;
  final String? title;

  /// Ueberschreibt den `pageType` aus dem [TrackingContext].
  final String? pageType;

  Map<String, dynamic> toJson([String? fallbackPageType]) => compact({
        'referrer': referrer,
        'title': title,
        'url': url,
        'page_type': pageType ?? fallbackPageType,
      });
}

/// Der `ad`-Block: welche Anzeigeflaeche das Event ausgeloest hat.
@immutable
class TrackingAd {
  const TrackingAd({
    required this.unitId,
    this.placement,
    this.format,
    this.instance,
  });

  /// Content-ID der ausgespielten Einheit (Prospekt- oder Angebots-UUID).
  final String unitId;

  /// z. B. `ad_placement__brochure_bar`.
  final String? placement;

  /// z. B. `ad_format__brochure_card_cover`.
  final String? format;

  /// UUID der konkreten Einblendung.
  final String? instance;

  Map<String, dynamic> toJson() => compact({
        'unit_id': unitId,
        'placement': placement,
        'format': format,
        'instance': instance,
      });
}

/// Der `screen`-Block: auf welchem Screen das Event passiert ist.
@immutable
class TrackingScreen {
  const TrackingScreen({required this.name, this.uuid, this.source});

  /// z. B. `brochure_viewer` oder `UNKNOWN`.
  final String name;

  /// UUID der Screen-Instanz (bei Impressions gesetzt).
  final String? uuid;

  /// Herkunft des Screens (bei Interaktionen gesetzt).
  final String? source;

  Map<String, dynamic> toJson() =>
      compact({'name': name, 'uuid': uuid, 'source': source});
}
