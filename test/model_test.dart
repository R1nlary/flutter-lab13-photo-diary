import 'dart:convert';

import 'package:flutter_lab13_photo_diary/models/diary_entry.dart';
import 'package:flutter_lab13_photo_diary/models/geo_fix.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('GeoFix JSON', () {
    test('round-trips every field', () {
      final back = GeoFix.fromJson(
        jsonDecode(jsonEncode(testFix.toJson())) as Map<String, dynamic>,
      );
      expect(back, testFix);
      expect(back.accuracy, 4.8);
      expect(back.altitude, 812.3);
      expect(back.timestamp.isAtSameMomentAs(testFix.timestamp), isTrue);
    });

    test('accepts whole numbers stored as int', () {
      final fix = GeoFix.fromJson({
        'lat': 43,
        'lng': 77,
        'accuracy': 5,
        'altitude': 0,
        'timestamp': '2026-11-27T09:00:00.000Z',
      });
      expect(fix.latitude, 43.0);
      expect(fix.longitude, 77.0);
      expect(fix.altitude, 0.0);
    });
  });

  group('DiaryEntry JSON', () {
    final entry = DiaryEntry(
      id: '1764234330000000',
      photoPath: 'photos/1764234330000000.jpg',
      caption: 'Narxoz main building',
      createdAt: DateTime.utc(2026, 11, 27, 9, 5, 31),
      location: testFix,
    );

    test('round-trips with location', () {
      final back = DiaryEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(back, entry);
      expect(back.photoPath, 'photos/1764234330000000.jpg');
      expect(back.caption, 'Narxoz main building');
      expect(back.location, testFix);
    });

    test('round-trips without location', () {
      final noGps = DiaryEntry(
        id: '2',
        photoPath: 'photos/2.jpg',
        caption: '',
        createdAt: DateTime.utc(2026, 11, 27),
      );
      final back = DiaryEntry.fromJson(noGps.toJson());
      expect(back, noGps);
      expect(back.location, isNull);
    });

    test('a list survives encodeList / decodeList in order', () {
      final second = DiaryEntry(
        id: '2',
        photoPath: 'photos/2.jpg',
        caption: 'Second',
        createdAt: DateTime.utc(2026, 11, 26),
      );
      final decoded = DiaryEntry.decodeList(
        DiaryEntry.encodeList([entry, second]),
      );
      expect(decoded, [entry, second]);
    });

    test('createdAt is stored as UTC ISO-8601', () {
      final local = DiaryEntry(
        id: '3',
        photoPath: 'p',
        caption: 'c',
        createdAt: DateTime(2026, 11, 27, 14, 5),
      );
      final stored = local.toJson()['createdAt'] as String;
      expect(stored.endsWith('Z'), isTrue);
      expect(DateTime.parse(stored).isAtSameMomentAs(local.createdAt), isTrue);
    });
  });
}
