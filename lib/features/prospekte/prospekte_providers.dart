import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:prospect_client/prospect_client.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';

/// Gespeicherter Standort für Prospekt-Abfragen.
///
/// Bewusst nur auf Postleitzahlen-Ebene: für die Frage "welche Angebote
/// gelten bei mir" reicht das, und es wird kein präziser Gerätestandort
/// erhoben oder übertragen.
@immutable
class ProspekteLocation {
  const ProspekteLocation({
    required this.plz,
    required this.place,
    required this.latitude,
    required this.longitude,
  });

  final String plz;
  final String place;
  final double latitude;
  final double longitude;

  String get label => '$plz $place';

  GeoPoint get point => GeoPoint(latitude, longitude);
}

class ProspekteLocationController extends Notifier<ProspekteLocation?> {
  static const _keyPlz = 'prospekte.location.plz';
  static const _keyPlace = 'prospekte.location.place';
  static const _keyLat = 'prospekte.location.lat';
  static const _keyLng = 'prospekte.location.lng';

  @override
  ProspekteLocation? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final plz = prefs.getString(_keyPlz);
    final place = prefs.getString(_keyPlace);
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    if (plz == null || place == null || lat == null || lng == null) return null;
    return ProspekteLocation(
      plz: plz,
      place: place,
      latitude: lat,
      longitude: lng,
    );
  }

  Future<void> set(ProspekteLocation location) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_keyPlz, location.plz);
    await prefs.setString(_keyPlace, location.place);
    await prefs.setDouble(_keyLat, location.latitude);
    await prefs.setDouble(_keyLng, location.longitude);
    state = location;
  }
}

final prospekteLocationProvider =
    NotifierProvider<ProspekteLocationController, ProspekteLocation?>(
      ProspekteLocationController.new,
    );

/// Löst eine deutsche Postleitzahl über Zippopotam (offene, schlüssellose
/// Geodaten-API) in Ort und Koordinaten auf. Übertragen wird nur die PLZ.
///
/// Gibt null zurück, wenn die PLZ unbekannt ist oder der Dienst nicht
/// erreichbar war.
Future<ProspekteLocation?> resolvePlz(String plz) async {
  final trimmed = plz.trim();
  if (!RegExp(r'^\d{5}$').hasMatch(trimmed)) return null;

  final uri = Uri.https('api.zippopotam.us', '/de/$trimmed');
  try {
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map<String, dynamic>) return null;
    final places = json['places'];
    if (places is! List || places.isEmpty) return null;
    final place = places.first as Map<String, dynamic>;
    final lat = double.tryParse(place['latitude'] as String? ?? '');
    final lng = double.tryParse(place['longitude'] as String? ?? '');
    if (lat == null || lng == null) return null;
    return ProspekteLocation(
      plz: trimmed,
      place: place['place name'] as String? ?? '',
      latitude: lat,
      longitude: lng,
    );
  } catch (_) {
    return null;
  }
}

/// Verdrahteter Prospekt-Client mit Datei-Cache im App-Support-Verzeichnis.
///
/// Wird bei einem Standortwechsel neu aufgebaut, damit alle Quellen mit dem
/// aktuellen Standardstandort arbeiten.
final prospectClientProvider = FutureProvider<ProspectClient>((ref) async {
  final location = ref.watch(prospekteLocationProvider);
  final support = await getApplicationSupportDirectory();
  final client = ProspectClient.create(
    cacheDirectory: '${support.path}/prospekte-cache',
    defaultLocation: location?.point,
    defaultPostalCode: location?.plz ?? '10115',
    // Schluessel aus env.json (--dart-define-from-file); leere Werte werden
    // ignoriert, die betroffene Quelle bleibt dann eingeschraenkt bzw. aus.
    credentials: SourceCredentials.fromEnvironment().withValues({
      CredentialKey.schwarzStoresApiKey: AppConfig.schwarzStoresApiKey,
    }),
  );
  ref.onDispose(client.close);
  return client;
});

/// Angebotssuche über alle Quellen, günstigster Preis zuerst.
final offerSearchProvider = FutureProvider.autoDispose
    .family<SourceResult<List<Offer>>, String>((ref, query) async {
      final client = await ref.watch(prospectClientProvider.future);
      final location = ref.watch(prospekteLocationProvider);
      final result = await client.repository.searchOffers(
        query,
        near: location?.point,
        postalCode: location?.plz,
      );

      final sorted = [...result.data]
        ..sort((a, b) {
          final pa = a.price?.current;
          final pb = b.price?.current;
          if (pa == null && pb == null) return a.title.compareTo(b.title);
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });

      return SourceResult(
        data: sorted,
        errors: result.errors,
        warnings: result.warnings,
        isStale: result.isStale,
      );
    });

/// Haendler samt Logo, aufgeschluesselt nach kanonischer ID.
///
/// Fuer die Gruppenkoepfe der Prospektuebersicht: Prospekte selbst tragen
/// kein Logo, die Haendlerliste der Quellen schon.
final retailerIndexProvider =
    FutureProvider.autoDispose<Map<String, Retailer>>((ref) async {
      final client = await ref.watch(prospectClientProvider.future);
      final location = ref.watch(prospekteLocationProvider);
      final result = await client.repository.getRetailers(
        near: location?.point,
      );
      return {for (final retailer in result.data) retailer.id: retailer};
    });

/// Aktuelle Prospekte rund um den gespeicherten Standort.
final nearbyBrochuresProvider =
    FutureProvider.autoDispose<SourceResult<List<Brochure>>>((ref) async {
      final client = await ref.watch(prospectClientProvider.future);
      final location = ref.watch(prospekteLocationProvider);
      return client.repository.getBrochures(
        near: location?.point,
        postalCode: location?.plz,
      );
    });

/// Vollständiger Prospekt (Seiten und Angebote) zu einer serialisierten
/// [BrochureId] wie `kaufda:72a3...`.
final brochureDetailProvider = FutureProvider.autoDispose
    .family<Brochure, String>((ref, serialized) async {
      final id = BrochureId.tryParse(serialized);
      if (id == null) {
        throw ArgumentError.value(serialized, 'id', 'keine gültige Prospekt-ID');
      }
      final client = await ref.watch(prospectClientProvider.future);
      return client.repository.getBrochure(id);
    });
