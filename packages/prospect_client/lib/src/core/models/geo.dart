import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Geografischer Punkt in WGS84.
@immutable
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Parst `"52.52,13.405"`. Gibt null zurueck statt zu werfen, damit
  /// CLI-Eingaben ohne try/catch validiert werden koennen.
  static GeoPoint? tryParse(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return GeoPoint(lat, lng);
  }

  /// Grosskreisdistanz in Metern (Haversine).
  double distanceTo(GeoPoint other) {
    const earthRadius = 6371000.0;
    final dLat = _rad(other.latitude - latitude);
    final dLng = _rad(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(latitude)) *
            math.cos(_rad(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double degrees) => degrees * math.pi / 180.0;

  Map<String, Object?> toJson() => {'lat': latitude, 'lng': longitude};

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '$latitude,$longitude';
}
