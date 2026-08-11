import 'package:meta/meta.dart';

/// Wie lange eine bestimmte Art von Antwort als frisch gilt.
///
/// Die Werte orientieren sich an der real gemessenen Aenderungsfrequenz der
/// Quellen, nicht an einem Pauschalwert: Haendlerstammdaten aendern sich
/// praktisch nie, Prospektlisten woechentlich, ein einmal veroeffentlichter
/// Prospekt gar nicht mehr.
@immutable
class CachePolicy {
  const CachePolicy({
    required this.retailers,
    required this.brochureList,
    required this.brochureDetail,
    required this.stores,
    required this.search,
  });

  /// Standardwerte fuer den Produktivbetrieb.
  static const CachePolicy defaults = CachePolicy(
    retailers: Duration(days: 7),
    brochureList: Duration(hours: 6),
    brochureDetail: Duration(hours: 24),
    stores: Duration(days: 30),
    search: Duration(hours: 1),
  );

  /// Nichts wird als frisch betrachtet. Erzwingt bedingte Requests, nutzt aber
  /// weiterhin ETags. Fuer `--refresh`.
  static const CachePolicy alwaysRevalidate = CachePolicy(
    retailers: Duration.zero,
    brochureList: Duration.zero,
    brochureDetail: Duration.zero,
    stores: Duration.zero,
    search: Duration.zero,
  );

  final Duration retailers;
  final Duration brochureList;
  final Duration brochureDetail;
  final Duration stores;
  final Duration search;

  Duration forKind(CacheKind kind) => switch (kind) {
        CacheKind.retailers => retailers,
        CacheKind.brochureList => brochureList,
        CacheKind.brochureDetail => brochureDetail,
        CacheKind.stores => stores,
        CacheKind.search => search,
      };
}

enum CacheKind { retailers, brochureList, brochureDetail, stores, search }
