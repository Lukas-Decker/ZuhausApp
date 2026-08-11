/// Formatiert einen Zeitstempel als lokale ISO-8601-Zeit mit Offset,
/// z. B. `2026-08-10T23:33:06+02:00`.
///
/// `DateTime.toIso8601String()` haengt bei lokalen Zeiten keinen Offset an,
/// der Tracking-Endpunkt erwartet ihn aber genau so.
String formatLocalIso8601(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = _pad(absolute.inHours);
  final minutes = _pad(absolute.inMinutes.remainder(60));
  return '${_pad(local.year, 4)}-${_pad(local.month)}-${_pad(local.day)}'
      'T${_pad(local.hour)}:${_pad(local.minute)}:${_pad(local.second)}'
      '$sign$hours:$minutes';
}

String _pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');
