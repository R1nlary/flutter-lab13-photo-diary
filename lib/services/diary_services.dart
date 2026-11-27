import 'diary_repository.dart';
import 'location_service.dart';
import 'permission_service.dart';
import 'photo_service.dart';

/// Everything the screens talk to, injected from `main()` so tests can pass
/// fakes instead of the platform plugins.
class DiaryServices {
  const DiaryServices({
    required this.photos,
    required this.location,
    required this.permissions,
    required this.repository,
  });

  final PhotoService photos;
  final LocationService location;
  final PermissionService permissions;
  final DiaryRepository repository;
}
