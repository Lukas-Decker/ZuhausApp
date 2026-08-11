import 'package:meta/meta.dart';

import 'common.dart';
import 'json.dart';

/// Filiale aus `GET /v1/nearestStore`.
@immutable
class Store {
  const Store({
    required this.id,
    required this.name,
    this.street,
    this.streetNumber,
    this.zip,
    this.city,
    this.lat,
    this.lng,
    this.distance,
    this.openStatus,
    this.timeZone,
    this.contactDetails,
    this.openingHours,
    this.publisher,
    this.images = const [],
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        street: asString(json['street']),
        streetNumber: asString(json['streetNumber']),
        zip: asString(json['zip']),
        city: asString(json['city']),
        lat: asDouble(json['lat']),
        lng: asDouble(json['lng']),
        distance: asDouble(json['distance']),
        openStatus: asString(json['openStatus']),
        timeZone: asString(json['timeZone']),
        contactDetails: switch (asMap(json['contactDetails'])) {
          final Map<String, dynamic> m => ContactDetails.fromJson(m),
          null => null,
        },
        openingHours: switch (asMap(json['openingHours'])) {
          final Map<String, dynamic> m => OpeningHours.fromJson(m),
          null => null,
        },
        publisher: switch (asMap(json['publisher'])) {
          final Map<String, dynamic> m => Publisher.fromJson(m),
          null => null,
        },
        images: mapList(json['images'], ImageRef.fromJson),
      );

  final String id;
  final String name;
  final String? street;
  final String? streetNumber;
  final String? zip;
  final String? city;
  final double? lat;
  final double? lng;

  /// Luftlinie in Kilometern zur angefragten Position.
  final double? distance;

  /// Beobachtet: `open`, `closed`.
  final String? openStatus;
  final String? timeZone;
  final ContactDetails? contactDetails;
  final OpeningHours? openingHours;
  final Publisher? publisher;
  final List<ImageRef> images;

  bool get isOpen => openStatus == 'open';

  /// Einzeilige Adresse.
  String get address {
    final line1 = [street, streetNumber].where(_notEmpty).join(' ');
    final line2 = [zip, city].where(_notEmpty).join(' ');
    return [line1, line2].where((e) => e.isNotEmpty).join(', ');
  }

  static bool _notEmpty(String? value) => value != null && value.isNotEmpty;

  Map<String, dynamic> toJson() => compact({
        'id': id,
        'name': name,
        'street': street,
        'streetNumber': streetNumber,
        'zip': zip,
        'city': city,
        'lat': lat,
        'lng': lng,
        'distance': distance,
        'openStatus': openStatus,
        'timeZone': timeZone,
        'contactDetails': contactDetails?.toJson(),
        'openingHours': openingHours?.toJson(),
        'publisher': publisher?.toJson(),
        'images': images.map((e) => e.toJson()).toList(),
      });

  @override
  String toString() => 'Store($id, $name, $address)';
}

/// Kontaktdaten einer Filiale.
@immutable
class ContactDetails {
  const ContactDetails({this.telephoneNumbers = const [], this.emailAddress});

  factory ContactDetails.fromJson(Map<String, dynamic> json) => ContactDetails(
        telephoneNumbers: mapList(
          json['telephoneNumbers'],
          (m) => asString(m['number']) ?? '',
        ).where((e) => e.isNotEmpty).toList(growable: false),
        emailAddress: asString(json['emailAddress']),
      );

  final List<String> telephoneNumbers;
  final String? emailAddress;

  Map<String, dynamic> toJson() => compact({
        'telephoneNumbers': telephoneNumbers.map((e) => {'number': e}).toList(),
        'emailAddress': emailAddress,
      });

  @override
  String toString() => 'ContactDetails($telephoneNumbers, $emailAddress)';
}

/// Oeffnungszeiten einer Filiale.
@immutable
class OpeningHours {
  const OpeningHours({
    this.displayValue,
    this.regular = const [],
    this.special = const [],
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) => OpeningHours(
        displayValue: asString(json['displayValue']),
        regular:
            mapList(json['regularOpeningHours'], OpeningHoursSlot.fromJson),
        special: (json['specialOpeningHours'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList(growable: false) ??
            const [],
      );

  /// Vorformatierter Text der API, oft leer.
  final String? displayValue;
  final List<OpeningHoursSlot> regular;

  /// Sonderoeffnungszeiten. In der aufgezeichneten Probe immer leer, deshalb
  /// als Rohdaten durchgereicht.
  final List<Map<String, dynamic>> special;

  /// Alle Zeitfenster fuer einen Wochentag (1 = Montag ... 7 = Sonntag).
  List<OpeningHoursSlot> forWeekday(int weekday) =>
      regular.where((e) => e.dayOfWeek == weekday).toList(growable: false);

  Map<String, dynamic> toJson() => compact({
        'displayValue': displayValue,
        'regularOpeningHours': regular.map((e) => e.toJson()).toList(),
        'specialOpeningHours': special,
      });

  @override
  String toString() => 'OpeningHours(${regular.length} Zeitfenster)';
}

/// Ein Oeffnungszeitfenster an einem Wochentag.
@immutable
class OpeningHoursSlot {
  const OpeningHoursSlot({
    required this.dayOfWeek,
    required this.minutesFrom,
    required this.minutesTo,
  });

  factory OpeningHoursSlot.fromJson(Map<String, dynamic> json) =>
      OpeningHoursSlot(
        dayOfWeek: asInt(json['dayOfWeek']) ?? 0,
        minutesFrom: asInt(json['minutesFrom']) ?? 0,
        minutesTo: asInt(json['minutesTo']) ?? 0,
      );

  /// 1 = Montag ... 7 = Sonntag (entspricht `DateTime.weekday`).
  final int dayOfWeek;

  /// Minuten seit Mitternacht.
  final int minutesFrom;

  /// Minuten seit Mitternacht.
  final int minutesTo;

  Duration get from => Duration(minutes: minutesFrom);
  Duration get to => Duration(minutes: minutesTo);

  String get displayValue => '${_hhmm(minutesFrom)} - ${_hhmm(minutesTo)}';

  static String _hhmm(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'minutesFrom': minutesFrom,
        'minutesTo': minutesTo,
      };

  @override
  String toString() => 'OpeningHoursSlot($dayOfWeek, $displayValue)';
}
