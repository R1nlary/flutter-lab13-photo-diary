import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picking photos and keeping them after the picker's temp file is gone.
abstract interface class PhotoService {
  /// Returns `null` when the user closes the picker without choosing.
  Future<XFile?> pick(ImageSource source);

  /// Copies the picked photo somewhere permanent and returns the value to
  /// store in `DiaryEntry.photoPath`.
  Future<String> persist(XFile photo, String id);

  /// Turns a stored `photoPath` back into something `EntryImage` can show.
  String resolve(String storedPath);

  Future<void> delete(String storedPath);
}

class DevicePhotoService implements PhotoService {
  DevicePhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  String? _documentsDir;

  static const _photosFolder = 'photos';

  /// Call once before `runApp`, so `resolve` can stay synchronous.
  Future<void> init() async {
    if (kIsWeb) return;
    _documentsDir = (await getApplicationDocumentsDirectory()).path;
  }

  @override
  Future<XFile?> pick(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1080);

  @override
  Future<String> persist(XFile photo, String id) async {
    if (kIsWeb) {
      // A web XFile path is a blob: URL that dies with the tab, so the bytes
      // themselves go into storage.
      final bytes = await photo.readAsBytes();
      final mime = photo.mimeType ?? 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }
    // image_picker writes into a cache/tmp folder the OS may clear, so the
    // photo is copied into the app documents directory. Only the relative
    // path is stored: on iOS the absolute container path changes after an
    // app update.
    final relative = '$_photosFolder/$id.jpg';
    final target = File('$_documentsDir/$relative');
    await target.parent.create(recursive: true);
    await File(photo.path).copy(target.path);
    return relative;
  }

  @override
  String resolve(String storedPath) {
    if (kIsWeb || storedPath.startsWith('/') || _documentsDir == null) {
      return storedPath;
    }
    return '$_documentsDir/$storedPath';
  }

  @override
  Future<void> delete(String storedPath) async {
    if (kIsWeb) return;
    final file = File(resolve(storedPath));
    if (await file.exists()) await file.delete();
  }
}
