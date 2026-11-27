import 'package:flutter_lab13_photo_diary/models/geo_fix.dart';
import 'package:flutter_lab13_photo_diary/services/diary_repository.dart';
import 'package:flutter_lab13_photo_diary/services/diary_services.dart';
import 'package:flutter_lab13_photo_diary/services/location_service.dart';
import 'package:flutter_lab13_photo_diary/services/permission_service.dart';
import 'package:flutter_lab13_photo_diary/services/photo_service.dart';
import 'package:image_picker/image_picker.dart';

final testFix = GeoFix(
  latitude: 43.238949,
  longitude: 76.889709,
  accuracy: 4.8,
  altitude: 812.3,
  timestamp: DateTime.utc(2026, 11, 27, 9, 5, 30),
);

class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  LocationResult result;
  int fetchCalls = 0;
  int locationSettingsOpened = 0;
  int appSettingsOpened = 0;

  @override
  bool get canOpenSettings => true;

  @override
  Future<LocationResult> fetchCurrent() async {
    fetchCalls++;
    return result;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

class FakePermissionService implements PermissionService {
  FakePermissionService({
    this.camera = AccessStatus.granted,
    this.photos = AccessStatus.granted,
  });

  AccessStatus camera;
  AccessStatus photos;
  int settingsOpened = 0;

  @override
  Future<AccessStatus> requestCamera() async => camera;

  @override
  Future<AccessStatus> requestPhotos() async => photos;

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

/// Returns an XFile pointing at a path that does not exist: the preview
/// falls back to its errorBuilder, which is fine for widget tests.
class FakePhotoService implements PhotoService {
  final picked = <ImageSource>[];
  final deleted = <String>[];

  @override
  Future<XFile?> pick(ImageSource source) async {
    picked.add(source);
    return XFile('/tmp/fake_${source.name}.jpg');
  }

  @override
  Future<String> persist(XFile photo, String id) async => 'photos/$id.jpg';

  @override
  String resolve(String storedPath) => '/docs/$storedPath';

  @override
  Future<void> delete(String storedPath) async => deleted.add(storedPath);
}

DiaryServices fakeServices({
  FakeLocationService? location,
  FakePermissionService? permissions,
  FakePhotoService? photos,
}) => DiaryServices(
  photos: photos ?? FakePhotoService(),
  location: location ?? FakeLocationService(LocationSuccess(testFix)),
  permissions: permissions ?? FakePermissionService(),
  repository: const DiaryRepository(),
);
