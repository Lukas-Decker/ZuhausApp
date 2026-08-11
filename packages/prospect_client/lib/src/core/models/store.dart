import 'package:meta/meta.dart';

import 'geo.dart';

/// Eine Filiale.
///
/// Nur Tjek liefert echte Filialdaten mit Koordinaten. Schwarz arbeitet
/// ausschliesslich mit Regionscodes, dort bleibt diese Liste leer. Der Adapter
/// meldet das ueber [SourceCapabilities.supportsStores], statt zu werfen.
@immutable
class Store {
  const Store({
    required this.id,
    required this.retailerId,
    this.name,
    this.street,
    this.zipCode,
    this.city,
    this.countryCode = 'DE',
    this.location,
  });

  final String id;

  /// Kanonische Haendler-ID.
  final String retailerId;

  final String? name;
  final String? street;
  final String? zipCode;
  final String? city;
  final String countryCode;
  final GeoPoint? location;

  /// Einzeilige Adresse, leere Bestandteile werden ausgelassen.
  String get address {
    final parts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      [
        if (zipCode != null && zipCode!.isNotEmpty) zipCode!,
        if (city != null && city!.isNotEmpty) city!,
      ].join(' ').trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'retailerId': retailerId,
        if (name != null) 'name': name,
        if (street != null) 'street': street,
        if (zipCode != null) 'zipCode': zipCode,
        if (city != null) 'city': city,
        'countryCode': countryCode,
        if (location != null) 'location': location!.toJson(),
      };

  static Store fromJson(Map<String, Object?> json) {
    final loc = json['location'] as Map<String, Object?>?;
    final lat = loc?['lat'];
    final lng = loc?['lng'];
    return Store(
      id: json['id']! as String,
      retailerId: json['retailerId'] as String? ?? 'unknown',
      name: json['name'] as String?,
      street: json['street'] as String?,
      zipCode: json['zipCode'] as String?,
      city: json['city'] as String?,
      countryCode: json['countryCode'] as String? ?? 'DE',
      location: lat is num && lng is num
          ? GeoPoint(lat.toDouble(), lng.toDouble())
          : null,
    );
  }

  @override
  String toString() => 'Store($id, $address)';
}
