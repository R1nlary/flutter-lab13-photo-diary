import 'package:intl/intl.dart';

/// `43.2389° N` / `33.8688° S`.
String formatLatitude(double latitude, {int fractionDigits = 4}) =>
    '${latitude.abs().toStringAsFixed(fractionDigits)}° '
    '${latitude < 0 ? 'S' : 'N'}';

/// `76.8897° E` / `122.4194° W`.
String formatLongitude(double longitude, {int fractionDigits = 4}) =>
    '${longitude.abs().toStringAsFixed(fractionDigits)}° '
    '${longitude < 0 ? 'W' : 'E'}';

/// `43.2389° N, 76.8897° E`.
String formatCoordinates(
  double latitude,
  double longitude, {
  int fractionDigits = 4,
}) =>
    '${formatLatitude(latitude, fractionDigits: fractionDigits)}, '
    '${formatLongitude(longitude, fractionDigits: fractionDigits)}';

/// `± 12.5 m`.
String formatAccuracy(double metres) => '± ${metres.toStringAsFixed(1)} m';

/// `812.4 m`.
String formatAltitude(double metres) => '${metres.toStringAsFixed(1)} m';

final DateFormat _timeFormat = DateFormat('d MMM yyyy, HH:mm');
final DateFormat _timeWithSecondsFormat = DateFormat('d MMM yyyy, HH:mm:ss');

/// `27 Nov 2026, 14:05` in the device time zone.
String formatTimestamp(DateTime time, {bool withSeconds = false}) =>
    (withSeconds ? _timeWithSecondsFormat : _timeFormat).format(time.toLocal());
