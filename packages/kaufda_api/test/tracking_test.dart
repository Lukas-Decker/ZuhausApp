import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaufda_api/kaufda_api.dart';
import 'package:test/test.dart';

const _location = GeoLocation(
  lat: 49.6378338,
  lng: 7.1113922,
  zip: '55767',
  city: 'Brücken',
);

const _context = TrackingContext(
  userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Test',
  browser: 'Firefox',
  browserVersion: '153.0',
  pageType: 'SHELF_PAGE',
  visitOriginType: 'WEB_REFERRER_SEO',
  sourceType: 'PORTAL_WIDGET',
  sourceValue: 'Lidl',
  geo: _location,
  webPage: TrackingWebPage(
    url: 'https://www.kaufda.de/contentViewer/static/72a3b683',
    referrer: 'https://www.kaufda.de/shelf',
    title: 'kaufDA - Lidl',
  ),
);

SessionProvider _session() => StaticSessionProvider.fromToken(
      'header.payload.signature',
      visitId: 'd5b6f05c-588d-45ab-a8b2-868589c128a9',
    );

void main() {
  group('TrackingClient', () {
    test('sendet ein Einzelevent mit vollstaendigem Rumpf', () async {
      late http.Request seen;
      final tracking = TrackingClient(
        sessionProvider: _session(),
        context: _context,
        httpClient: MockClient((request) async {
          seen = request;
          return http.Response('OK', 200);
        }),
      );

      await tracking.send(const WebPageViewEvent());

      expect(seen.method, 'POST');
      expect(seen.url.path, '/v3s/compound-event');
      expect(seen.url.queryParameters['eventName'], 'web_page_view');
      expect(seen.headers['Authorization'], 'Bearer header.payload.signature');
      expect(seen.headers['Bonial-Api-Consumer'], 'web-user-sdk');

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['event_name'], 'web_page_view');
      expect(body['event_version'], '3.5');
      expect(body['event_category'], 'time_series');
      expect(body['delivery_channel'], 'dest.kaufda');
      expect(body['environment'], 'p');
      expect(body['market'], 'de');
      expect(body['team'], 'w3');
      expect(
        body['event_local_datetime'],
        matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'),
      );
      expect(
        body['event_uuid'],
        matches(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      );

      final session = body['user_session'] as Map<String, dynamic>;
      expect(session['session_id'], 'd5b6f05c-588d-45ab-a8b2-868589c128a9');
      expect(session['web_id'], session['session_id']);
      expect(session['browser'], 'Firefox');

      final permissions = body['permissions_setting'] as Map<String, dynamic>;
      expect(permissions['tracking_opt_in'], 0);
      expect(permissions['external_tracking_opt_in'], 0);

      final custom = body['custom'] as Map<String, dynamic>;
      expect(custom['partner'], 'kaufda_web');
      expect(custom['device_type'], 'web_browser');
      expect(custom['session_token'], startsWith('Bearer '));
      expect(custom['page_type'], 'SHELF_PAGE');

      final geo = body['geo'] as Map<String, dynamic>;
      expect(geo['lat'], 49.6378338);
      expect(geo['user_zip'], '55767');

      final webPage = body['web_page'] as Map<String, dynamic>;
      expect(webPage['page_type'], 'SHELF_PAGE');
      expect(webPage['referrer'], 'https://www.kaufda.de/shelf');
    });

    test('brochure_engagement enthaelt alle Detailbloecke', () async {
      late Map<String, dynamic> body;
      final tracking = TrackingClient(
        sessionProvider: _session(),
        context: _context,
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('OK', 200);
        }),
      );

      await tracking.send(
        BrochureEngagementEvent(
          engagement: const BrochureEngagementDetails(
            engagementId: '51b13a8b-6621-47e3-a9da-3b246a37c590',
            brochureId: '72a3b683-90ff-4d09-9815-6baebe0a1b1d',
            publisherId: 'DE-1013',
            badgeStatus: 'new',
          ),
          ad: const TrackingAd(
            unitId: '72a3b683-90ff-4d09-9815-6baebe0a1b1d',
            placement: 'ad_placement__shelf_fixed_position_1',
            format: 'ad_format__brochure_card_cover',
            instance: '9fdbdc3b-2868-4eb5-901b-1d2ceda657bf',
          ),
        ),
      );

      final details =
          body['brochure_engagement_details'] as Map<String, dynamic>;
      expect(details['engagement_id'], '51b13a8b-6621-47e3-a9da-3b246a37c590');
      expect(details['brochure_type'], 'static_brochure');
      expect(details['page_num'], [1]);
      expect(details['preview'], false);
      expect(details['badge_status'], 'new');

      expect((body['ui_interaction_details'] as Map)['action'], 'click');
      expect((body['ad'] as Map)['placement'],
          'ad_placement__shelf_fixed_position_1');
      expect((body['closed_brochure_preview'] as Map)['user_preview'], false);
      expect((body['screen'] as Map)['name'], 'UNKNOWN');
    });

    test('offer_impression bildet content_engagement ab', () async {
      late Map<String, dynamic> body;
      final tracking = TrackingClient(
        sessionProvider: _session(),
        context: _context,
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('OK', 200);
        }),
      );

      await tracking.send(
        const OfferImpressionEvent(
          content: ContentEngagement(
            contentId: 'eb1789b6-74cb-4961-b2e1-0d1f19d58224',
            contentType: 'offer',
            advertiserId: 'DE-1013',
            parentContentId: '72a3b683-90ff-4d09-9815-6baebe0a1b1d',
            parentContentType: 'static_brochure',
            preview: false,
            brochureEngagementId: '51b13a8b-6621-47e3-a9da-3b246a37c590',
          ),
          screen: TrackingScreen(
            name: 'brochure_viewer',
            uuid: '846283bf-43c9-4f53-908f-790bb861a851',
          ),
          position: 1,
        ),
      );

      expect(body['event_name'], 'offer_impression');
      final engagement = body['content_engagement'] as Map<String, dynamic>;
      expect(engagement['content_type'], 'offer');
      expect(engagement['parent_content_type'], 'static_brochure');
      final impression = body['ui_impression_details'] as Map<String, dynamic>;
      expect(impression['feature'], 'brochure_viewer_page');
      expect(impression['position'], 1);
    });

    test('Batch verpackt Events und liest die Statusliste', () async {
      late Map<String, dynamic> body;
      final tracking = TrackingClient(
        sessionProvider: _session(),
        context: _context,
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.path, '/v3s/batch-compound-event');
          return http.Response('{"nb_events":2,"events":["OK","OK"]}', 200);
        }),
      );

      final result = await tracking.sendBatch(const [
        WebPageViewEvent(),
        BrochureViewUpdateEvent(
          engagement: BrochureEngagementDetails(
            engagementId: 'a',
            brochureId: 'b',
            interactionType: 'brochure_enter',
          ),
        ),
      ]);

      expect((body['events'] as List), hasLength(2));
      expect(
        body['batch_local_datetime'],
        matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'),
      );
      expect(
        ((body['events'] as List)[1] as Map)['brochure_engagement_details'],
        containsPair('interaction_type', 'brochure_enter'),
      );
      expect(result.eventCount, 2);
      expect(result.allAccepted, isTrue);
    });

    test('leerer Batch loest keinen Request aus', () async {
      var calls = 0;
      final tracking = TrackingClient(
        sessionProvider: _session(),
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('OK', 200);
        }),
      );

      final result = await tracking.sendBatch(const []);

      expect(calls, 0);
      expect(result.eventCount, 0);
    });
  });
}
