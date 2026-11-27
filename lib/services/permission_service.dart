import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// What the UI needs to know after asking for a permission.
enum AccessStatus {
  granted,

  /// Denied this time; asking again will show the system dialog again.
  denied,

  /// Android "Don't ask again" / iOS denied once: the system dialog will not
  /// appear any more, the only way back is the app's page in Settings.
  permanentlyDenied,

  /// Blocked by parental controls / MDM. The user cannot change it.
  restricted,
}

/// Camera and photo library permissions (location is handled by geolocator,
/// see `LocationService`).
abstract interface class PermissionService {
  Future<AccessStatus> requestCamera();
  Future<AccessStatus> requestPhotos();
  Future<bool> openSettings();
}

/// Real implementation backed by `permission_handler`.
class HandlerPermissionService implements PermissionService {
  const HandlerPermissionService();

  @override
  Future<AccessStatus> requestCamera() => _request(Permission.camera);

  /// Android 13+: READ_MEDIA_IMAGES. iOS: NSPhotoLibraryUsageDescription.
  @override
  Future<AccessStatus> requestPhotos() => _request(Permission.photos);

  @override
  Future<bool> openSettings() => openAppSettings();

  Future<AccessStatus> _request(Permission permission) async {
    // In the browser there is no app-level permission: the <input type=file>
    // dialog that image_picker opens is the user's consent.
    if (kIsWeb) return AccessStatus.granted;
    final status = await permission.request();
    return mapStatus(status);
  }

  @visibleForTesting
  static AccessStatus mapStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited: // iOS 14+ "Selected photos only".
      case PermissionStatus.provisional:
        return AccessStatus.granted;
      case PermissionStatus.permanentlyDenied:
        return AccessStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AccessStatus.restricted;
      case PermissionStatus.denied:
        return AccessStatus.denied;
    }
  }
}
