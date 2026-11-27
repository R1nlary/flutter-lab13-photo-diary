import 'package:flutter/material.dart';

import 'app.dart';
import 'services/diary_repository.dart';
import 'services/diary_services.dart';
import 'services/location_service.dart';
import 'services/permission_service.dart';
import 'services/photo_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final photos = DevicePhotoService();
  await photos.init();
  runApp(
    PhotoDiaryApp(
      services: DiaryServices(
        photos: photos,
        location: const GeolocatorLocationService(),
        permissions: const HandlerPermissionService(),
        repository: const DiaryRepository(),
      ),
    ),
  );
}
