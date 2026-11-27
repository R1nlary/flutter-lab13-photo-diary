import 'package:flutter_lab13_photo_diary/models/diary_entry.dart';
import 'package:flutter_lab13_photo_diary/services/diary_repository.dart';
import 'package:flutter_lab13_photo_diary/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  const repo = DiaryRepository();

  test('empty storage gives an empty diary', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await repo.load(), isEmpty);
  });

  test('save then load returns the same entries', () async {
    SharedPreferences.setMockInitialValues({});
    final entries = [
      DiaryEntry(
        id: 'a',
        photoPath: 'photos/a.jpg',
        caption: 'Kok-Tobe',
        createdAt: DateTime.utc(2026, 11, 27, 10),
        location: testFix,
      ),
    ];
    expect(await repo.save(entries), isTrue);
    expect(await repo.load(), entries);
  });

  test('corrupted JSON does not crash, it is ignored', () async {
    SharedPreferences.setMockInitialValues({
      DiaryRepository.storageKey: '{not json',
    });
    expect(await repo.load(), isEmpty);
  });

  test('permission_handler statuses map to what the UI needs', () {
    expect(
      HandlerPermissionService.mapStatus(PermissionStatus.granted),
      AccessStatus.granted,
    );
    expect(
      HandlerPermissionService.mapStatus(PermissionStatus.limited),
      AccessStatus.granted,
    );
    expect(
      HandlerPermissionService.mapStatus(PermissionStatus.denied),
      AccessStatus.denied,
    );
    expect(
      HandlerPermissionService.mapStatus(PermissionStatus.permanentlyDenied),
      AccessStatus.permanentlyDenied,
    );
    expect(
      HandlerPermissionService.mapStatus(PermissionStatus.restricted),
      AccessStatus.restricted,
    );
  });
}
