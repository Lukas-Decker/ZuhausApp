import 'package:meta/meta.dart';

import 'image_set.dart';

/// Verknuepfung eines Haendlers mit einer konkreten Datenquelle.
///
/// Kaufland ist der Grund fuer diese Indirektion: der Haendler ist ueber Tjek
/// (`L5IgL3`, mit Preisen) und ueber Schwarz (`kaufland/de-DE` mit `region_id`,
/// mehr Produkte, keine Preise) erreichbar. Eine feste Zuordnung Haendler zu
/// Quelle waere damit von Anfang an falsch.
@immutable
class SourceBinding {
  const SourceBinding({
    required this.sourceId,
    required this.nativeId,
    this.params = const {},
  });

  /// ID des Adapters, z.B. `tjek` oder `schwarz`.
  final String sourceId;

  /// ID des Haendlers innerhalb dieser Quelle.
  final String nativeId;

  /// Zusatzparameter, die der Adapter fuer diesen Haendler braucht.
  /// Bei Schwarz/Kaufland z.B. `{'region_id': '3000'}`.
  final Map<String, String> params;

  Map<String, Object?> toJson() => {
        'sourceId': sourceId,
        'nativeId': nativeId,
        if (params.isNotEmpty) 'params': params,
      };

  static SourceBinding fromJson(Map<String, Object?> json) => SourceBinding(
        sourceId: json['sourceId']! as String,
        nativeId: json['nativeId']! as String,
        params: (json['params'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
      );

  @override
  bool operator ==(Object other) =>
      other is SourceBinding &&
      other.sourceId == sourceId &&
      other.nativeId == nativeId;

  @override
  int get hashCode => Object.hash(sourceId, nativeId);

  @override
  String toString() => '$sourceId:$nativeId';
}

/// Ein Haendler, quellenunabhaengig.
@immutable
class Retailer {
  const Retailer({
    required this.id,
    required this.name,
    this.website,
    this.description,
    this.logo = ImageSet.empty,
    this.colorHex,
    this.countryCode = 'DE',
    this.bindings = const [],
  });

  /// Kanonische, stabile ID wie `netto` oder `aldi-sued`. Bewusst nicht die
  /// ID einer Quelle, damit sie sich beim Wechsel der Quelle nicht aendert.
  final String id;

  final String name;
  final String? website;
  final String? description;
  final ImageSet logo;

  /// Markenfarbe ohne fuehrendes `#`, so wie die Quellen sie liefern.
  final String? colorHex;

  final String countryCode;

  /// Alle Quellen, die diesen Haendler kennen.
  final List<SourceBinding> bindings;

  /// Binding fuer eine bestimmte Quelle, null wenn die Quelle ihn nicht kennt.
  SourceBinding? bindingFor(String sourceId) {
    for (final binding in bindings) {
      if (binding.sourceId == sourceId) return binding;
    }
    return null;
  }

  Retailer mergedWith(Retailer other) {
    final merged = <SourceBinding>[...bindings];
    for (final binding in other.bindings) {
      if (!merged.contains(binding)) merged.add(binding);
    }
    return Retailer(
      id: id,
      name: name,
      website: website ?? other.website,
      description: description ?? other.description,
      logo: logo.isEmpty ? other.logo : logo,
      colorHex: colorHex ?? other.colorHex,
      countryCode: countryCode,
      bindings: merged,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        if (website != null) 'website': website,
        if (description != null) 'description': description,
        if (!logo.isEmpty) 'logo': logo.toJson(),
        if (colorHex != null) 'colorHex': colorHex,
        'countryCode': countryCode,
        if (bindings.isNotEmpty)
          'bindings': bindings.map((b) => b.toJson()).toList(),
      };

  static Retailer fromJson(Map<String, Object?> json) => Retailer(
        id: json['id']! as String,
        name: json['name'] as String? ?? '',
        website: json['website'] as String?,
        description: json['description'] as String?,
        logo: json['logo'] == null
            ? ImageSet.empty
            : ImageSet.fromJson(json['logo']! as Map<String, Object?>),
        colorHex: json['colorHex'] as String?,
        countryCode: json['countryCode'] as String? ?? 'DE',
        bindings: (json['bindings'] as List?)
                ?.whereType<Map<String, Object?>>()
                .map(SourceBinding.fromJson)
                .toList() ??
            const [],
      );

  @override
  String toString() => 'Retailer($id, $name, ${bindings.length} Quelle(n))';
}
