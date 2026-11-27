import 'package:flutter_lab13_photo_diary/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Almaty: northern and eastern hemispheres', () {
    expect(formatCoordinates(43.238949, 76.889709), '43.2389° N, 76.8897° E');
  });

  test('negative values become S and W', () {
    expect(formatCoordinates(-33.8688, 151.2093), '33.8688° S, 151.2093° E');
    expect(formatCoordinates(40.7128, -74.0060), '40.7128° N, 74.0060° W');
    expect(formatCoordinates(-22.9068, -43.1729), '22.9068° S, 43.1729° W');
  });

  test('equator and prime meridian count as N and E', () {
    expect(formatCoordinates(0, 0), '0.0000° N, 0.0000° E');
  });

  test('fractionDigits controls precision', () {
    expect(formatLatitude(43.238949, fractionDigits: 6), '43.238949° N');
    expect(formatLongitude(76.889709, fractionDigits: 2), '76.89° E');
  });

  test('accuracy and altitude', () {
    expect(formatAccuracy(4.84), '± 4.8 m');
    expect(formatAltitude(812.34), '812.3 m');
  });

  test('timestamp uses the device time zone', () {
    // A local DateTime, so the result is the same in any time zone.
    final t = DateTime(2026, 11, 27, 14, 5, 9);
    expect(formatTimestamp(t), '27 Nov 2026, 14:05');
    expect(formatTimestamp(t, withSeconds: true), '27 Nov 2026, 14:05:09');
  });
}
