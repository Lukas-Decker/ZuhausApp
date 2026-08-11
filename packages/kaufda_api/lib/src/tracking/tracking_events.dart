import 'package:meta/meta.dart';

import '../models/json.dart';
import '../session.dart';
import '../util/iso_datetime.dart';
import '../util/uuid.dart';
import 'tracking_context.dart';

/// Basis aller Events fuer `tk.kaufda.de/v3s`.
///
/// Ein Event liefert nur seine spezifischen Felder; Kanal, Session, Standort
/// und Consent kommen aus dem [TrackingContext].
@immutable
abstract class TrackingEvent {
  const TrackingEvent({
    required this.name,
    this.category = 'time_series',
    this.uuid,
    this.localDateTime,
    this.webPage,
  });

  /// Wird als Query-Parameter `eventName` und als `event_name` gesendet.
  final String name;

  /// Bisher nur `time_series` beobachtet.
  final String category;

  /// `event_uuid`. Wird erzeugt, wenn nicht gesetzt.
  final String? uuid;

  /// `event_local_datetime`. Standard ist der Sendezeitpunkt.
  final DateTime? localDateTime;

  /// Ueberschreibt die Seite aus dem Kontext.
  final TrackingWebPage? webPage;

  /// Die eventspezifischen Bloecke.
  Map<String, dynamic> details();

  /// Das vollstaendige Event, so wie es der Endpunkt erwartet.
  Map<String, dynamic> toJson(TrackingContext context, KaufdaSession session) {
    final effective =
        webPage == null ? context : context.copyWith(webPage: webPage);
    return compact({
      ...effective.envelope(session),
      'event_name': name,
      'event_version': context.eventVersion,
      'event_category': category,
      'event_local_datetime':
          formatLocalIso8601(localDateTime ?? DateTime.now()),
      'event_uuid': uuid ?? newUuidV4(),
      ...details(),
    });
  }
}

/// Beliebiges Event, falls ein Eventtyp hier noch nicht abgebildet ist.
class RawTrackingEvent extends TrackingEvent {
  const RawTrackingEvent({
    required super.name,
    required Map<String, dynamic> payload,
    super.category,
    super.uuid,
    super.localDateTime,
    super.webPage,
  }) : _payload = payload;

  final Map<String, dynamic> _payload;

  @override
  Map<String, dynamic> details() => _payload;
}

/// `web_page_view`: Aufruf einer Seite im Viewer.
class WebPageViewEvent extends TrackingEvent {
  const WebPageViewEvent({super.uuid, super.localDateTime, super.webPage})
      : super(name: 'web_page_view');

  @override
  Map<String, dynamic> details() => const {};
}

/// Gemeinsame Felder von `brochure_engagement` und `brochure_view_update`.
@immutable
class BrochureEngagementDetails {
  const BrochureEngagementDetails({
    required this.engagementId,
    required this.brochureId,
    this.brochureType = 'static_brochure',
    this.publisherId,
    this.pageNumbers = const [1],
    this.preview = false,
    this.badgeStatus,
    this.interactionType,
  });

  /// UUID, die alle Events einer Prospektsitzung zusammenhaelt.
  final String engagementId;
  final String brochureId;
  final String brochureType;
  final String? publisherId;

  /// Einsbasierte Seitennummern, so wie das Frontend sie sendet.
  final List<int> pageNumbers;
  final bool preview;

  /// z. B. `new`, `popular`, `valid_soon`.
  final String? badgeStatus;

  /// Nur bei `brochure_view_update`, z. B. `brochure_enter`.
  final String? interactionType;

  Map<String, dynamic> toJson() => compact({
        'engagement_id': engagementId,
        'page_num': pageNumbers,
        'brochure_id': brochureId,
        'brochure_type': brochureType,
        'preview': preview,
        'publisher_id': publisherId,
        'badge_status': badgeStatus,
        'interaction_type': interactionType,
      });
}

/// `brochure_engagement`: Nutzer oeffnet einen Prospekt.
class BrochureEngagementEvent extends TrackingEvent {
  const BrochureEngagementEvent({
    required this.engagement,
    this.ad,
    this.screen = const TrackingScreen(name: 'UNKNOWN', source: 'UNKNOWN'),
    this.feature = 'brochure_shelf',
    this.action = 'click',
    this.userPreview = false,
    super.uuid,
    super.localDateTime,
    super.webPage,
  }) : super(name: 'brochure_engagement');

  final BrochureEngagementDetails engagement;
  final TrackingAd? ad;
  final TrackingScreen screen;

  /// `ui_interaction_details.feature`, z. B. `brochure_shelf`.
  final String feature;

  /// `ui_interaction_details.action`, z. B. `click`.
  final String action;
  final bool userPreview;

  @override
  Map<String, dynamic> details() => compact({
        'screen': screen.toJson(),
        'ui_interaction_details': {'feature': feature, 'action': action},
        'brochure_engagement_details': engagement.toJson(),
        'ad': ad?.toJson(),
        'closed_brochure_preview': {'user_preview': userPreview},
      });
}

/// `brochure_view_update`: Fortschritt innerhalb eines Prospekts,
/// z. B. `brochure_enter` oder ein Seitenwechsel.
class BrochureViewUpdateEvent extends TrackingEvent {
  const BrochureViewUpdateEvent({
    required this.engagement,
    this.userPreview = false,
    super.uuid,
    super.localDateTime,
    super.webPage,
  }) : super(name: 'brochure_view_update');

  final BrochureEngagementDetails engagement;
  final bool userPreview;

  @override
  Map<String, dynamic> details() => {
        'closed_brochure_preview': {'user_preview': userPreview},
        'brochure_engagement_details': engagement.toJson(),
      };
}

/// Der `content_engagement`-Block der Impression-Events.
@immutable
class ContentEngagement {
  const ContentEngagement({
    required this.contentId,
    required this.contentType,
    this.advertiserId,
    this.badgeStatus,
    this.parentContentId,
    this.parentContentType,
    this.preview,
    this.brochureEngagementId,
  });

  final String contentId;

  /// `static_brochure` oder `offer`.
  final String contentType;

  /// Publisher-ID, z. B. `DE-1013`.
  final String? advertiserId;
  final String? badgeStatus;
  final String? parentContentId;
  final String? parentContentType;
  final bool? preview;
  final String? brochureEngagementId;

  Map<String, dynamic> toJson() => compact({
        'content_id': contentId,
        'content_type': contentType,
        'advertiser_id': advertiserId,
        'badge_status': badgeStatus,
        'parent_content_id': parentContentId,
        'parent_content_type': parentContentType,
        'preview': preview,
        'brochure_engagement_id': brochureEngagementId,
      });
}

/// Gemeinsame Basis von `brochure_impression` und `offer_impression`.
abstract class ImpressionEvent extends TrackingEvent {
  const ImpressionEvent({
    required super.name,
    required this.content,
    required this.screen,
    required this.feature,
    this.ad,
    this.position,
    super.uuid,
    super.localDateTime,
    super.webPage,
  });

  final ContentEngagement content;
  final TrackingScreen screen;
  final TrackingAd? ad;

  /// `ui_impression_details.feature`, z. B. `brochure_viewer_page`.
  final String feature;

  /// Einsbasierte Position innerhalb der Liste bzw. Seite.
  final int? position;

  @override
  Map<String, dynamic> details() => compact({
        'ad': ad?.toJson(),
        'content_engagement': content.toJson(),
        'screen': screen.toJson(),
        'ui_impression_details': compact({
          'feature': feature,
          'position': position,
        }),
      });
}

/// `brochure_impression`: eine Prospektkachel wurde sichtbar.
class BrochureImpressionEvent extends ImpressionEvent {
  const BrochureImpressionEvent({
    required super.content,
    required super.screen,
    super.feature = 'brochure_viewer_related_content_sidebar',
    super.ad,
    super.position,
    super.uuid,
    super.localDateTime,
    super.webPage,
  }) : super(name: 'brochure_impression');
}

/// `offer_impression`: ein Angebot auf einer Prospektseite wurde sichtbar.
class OfferImpressionEvent extends ImpressionEvent {
  const OfferImpressionEvent({
    required super.content,
    required super.screen,
    super.feature = 'brochure_viewer_page',
    super.ad,
    super.position,
    super.uuid,
    super.localDateTime,
    super.webPage,
  }) : super(name: 'offer_impression');
}
