import 'package:meta/meta.dart';

/// Standort, den die API fuer Filial- und Empfehlungslogik braucht.
///
/// Alle Content-Viewer-Endpunkte erwarten `lat` und `lng`. `zip` und `city`
/// werden nur vom Tracking verwendet.
@immutable
class GeoLocation {
  const GeoLocation(
      {required this.lat, required this.lng, this.zip, this.city});

  final double lat;
  final double lng;
  final String? zip;
  final String? city;

  /// Formatiert wie im Original-Frontend: unveraenderte Dezimaldarstellung.
  String get latParam => _format(lat);
  String get lngParam => _format(lng);

  static String _format(double value) {
    final asInt = value.toInt();
    return value == asInt ? '$asInt.0' : '$value';
  }

  GeoLocation copyWith({double? lat, double? lng, String? zip, String? city}) =>
      GeoLocation(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        zip: zip ?? this.zip,
        city: city ?? this.city,
      );

  @override
  bool operator ==(Object other) =>
      other is GeoLocation &&
      other.lat == lat &&
      other.lng == lng &&
      other.zip == zip &&
      other.city == city;

  @override
  int get hashCode => Object.hash(lat, lng, zip, city);

  @override
  String toString() => 'GeoLocation($lat, $lng${zip == null ? '' : ', $zip'})';
}
