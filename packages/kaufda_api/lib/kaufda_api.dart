/// Dart-Client fuer die interne kaufDA Content-Viewer-API.
///
/// Abgedeckt sind alle Endpunkte unter `https://content-viewer-be.kaufda.de/v1`,
/// der Session-Bootstrap ueber `https://www.kaufda.de/sessionData` sowie das
/// Event-Tracking unter `https://tk.kaufda.de/v3s`.
library;

export 'src/client.dart';
export 'src/exceptions.dart';
export 'src/geo.dart';
export 'src/models/brochure.dart';
export 'src/models/common.dart';
export 'src/models/offer.dart';
export 'src/models/page.dart';
export 'src/models/search.dart';
export 'src/models/shelf.dart';
export 'src/models/store.dart';
export 'src/session.dart';
export 'src/tracking/tracking_client.dart';
export 'src/tracking/tracking_context.dart';
export 'src/tracking/tracking_events.dart';
export 'src/util/uuid.dart' show newUuidV4;
