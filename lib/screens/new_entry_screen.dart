import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/diary_entry.dart';
import '../models/geo_fix.dart';
import '../services/diary_services.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../widgets/location_card.dart';
import '../widgets/photo_preview.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/settings_dialog.dart';

/// Capture a photo, tag it with GPS, add a caption, save.
/// Pops with the saved [DiaryEntry], or `null` if the user backs out.
class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key, required this.services});

  final DiaryServices services;

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _caption = TextEditingController();

  XFile? _photo;
  GeoFix? _fix;
  bool _isLastKnown = false;
  bool _locating = false;
  bool _saving = false;
  String? _locationMessage;

  DiaryServices get _services => widget.services;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- photo --

  Future<void> _chooseSource() async {
    final source = await showPhotoSourceSheet(context);
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final allowed = source == ImageSource.camera
        ? await _ensureCameraAccess()
        : await _ensureGalleryAccess();
    if (!allowed || !mounted) return;

    XFile? picked;
    try {
      picked = await _services.photos.pick(source);
    } on PlatformException catch (e) {
      // e.g. the iOS Simulator has no camera, or access was revoked meanwhile.
      _snack(
        e.code == 'camera_access_denied'
            ? 'Camera access was denied.'
            : 'Could not open the ${source.name}: ${e.message ?? e.code}',
      );
      return;
    } catch (e) {
      _snack('Could not open the ${source.name}: $e');
      return;
    }
    if (picked == null || !mounted) return; // user cancelled
    setState(() => _photo = picked);

    // Tag the new photo automatically unless we already have a fix.
    if (_fix == null && !_locating) await _fetchLocation();
  }

  Future<bool> _ensureCameraAccess() async {
    final status = await _services.permissions.requestCamera();
    if (!mounted) return false;
    switch (status) {
      case AccessStatus.granted:
        return true;
      case AccessStatus.denied:
        _snack(
          'Camera permission is needed to take a photo.',
          actionLabel: 'Try again',
          onAction: () => _pickPhoto(ImageSource.camera),
        );
        return false;
      case AccessStatus.permanentlyDenied:
        final open = await showSettingsDialog(
          context,
          icon: Icons.no_photography_outlined,
          title: 'Camera access is off',
          message:
              'You chose not to be asked again, so the app cannot show '
              'the permission dialog any more. Turn the camera on for '
              'Photo Diary in Settings.',
          actionLabel: 'Open Settings',
        );
        if (open) await _services.permissions.openSettings();
        return false;
      case AccessStatus.restricted:
        _snack('The camera is restricted on this device.');
        return false;
    }
  }

  /// The system photo picker (Android 13+ Photo Picker, iOS PHPicker) only
  /// hands over the one photo the user taps, so it works even without
  /// library access. A denial is explained, not treated as a dead end.
  Future<bool> _ensureGalleryAccess() async {
    final status = await _services.permissions.requestPhotos();
    if (!mounted) return false;
    switch (status) {
      case AccessStatus.granted:
        return true;
      case AccessStatus.denied:
      case AccessStatus.restricted:
        _snack('No full library access - only the photo you pick is shared.');
        return true;
      case AccessStatus.permanentlyDenied:
        _snack(
          'Photo library access is off. Only the photo you pick is shared.',
          actionLabel: 'Settings',
          onAction: _services.permissions.openSettings,
        );
        return true;
    }
  }

  // ------------------------------------------------------------- location --

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    final result = await _services.location.fetchCurrent();
    if (!mounted) return;

    switch (result) {
      case LocationSuccess(:final fix, :final isLastKnown):
        setState(() {
          _locating = false;
          _fix = fix;
          _isLastKnown = isLastKnown;
        });
      case LocationFailure(:final reason, :final details):
        setState(() {
          _locating = false;
          _locationMessage = _failureText(reason, details);
        });
        await _explainFailure(reason);
    }
  }

  String _failureText(LocationFailureReason reason, String? details) {
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        return 'Location services (GPS) are turned off.';
      case LocationFailureReason.denied:
        return 'Location permission was denied. The entry can still be saved '
            'without coordinates.';
      case LocationFailureReason.deniedForever:
        return 'Location permission is permanently denied. Enable it in the '
            'app settings.';
      case LocationFailureReason.timeout:
        return 'No GPS fix in time. Move closer to a window and try again.';
      case LocationFailureReason.error:
        return 'Could not get the location${details == null ? '' : ': $details'}';
    }
  }

  Future<void> _explainFailure(LocationFailureReason reason) async {
    final location = _services.location;
    switch (reason) {
      case LocationFailureReason.serviceDisabled:
        if (!location.canOpenSettings) {
          _snack('Turn on location for this browser and try again.');
          return;
        }
        final open = await showSettingsDialog(
          context,
          icon: Icons.location_off_outlined,
          title: 'Turn on GPS',
          message:
              'Location services are disabled on this device. Enable '
              'GPS so the photo can be tagged with where it was taken.',
          actionLabel: 'Open location settings',
        );
        if (open) await location.openLocationSettings();
      case LocationFailureReason.deniedForever:
        if (!location.canOpenSettings) {
          _snack(
            'Location is blocked for this site. Allow it in the '
            'browser\'s site settings.',
          );
          return;
        }
        final open = await showSettingsDialog(
          context,
          icon: Icons.location_disabled_outlined,
          title: 'Location access is off',
          message:
              'The permission was denied permanently, so the system '
              'dialog will not appear again. Allow location for Photo Diary '
              'in its settings page.',
          actionLabel: 'Open app settings',
        );
        if (open) await location.openAppSettings();
      case LocationFailureReason.denied:
        _snack(
          'Location permission denied.',
          actionLabel: 'Try again',
          onAction: _fetchLocation,
        );
      case LocationFailureReason.timeout:
      case LocationFailureReason.error:
        break; // The message in the card is enough.
    }
  }

  // ----------------------------------------------------------------- save --

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    try {
      final storedPath = await _services.photos.persist(photo, id);
      if (!mounted) return;
      Navigator.pop(
        context,
        DiaryEntry(
          id: id,
          photoPath: storedPath,
          caption: _caption.text.trim(),
          createdAt: now,
          location: _fix,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Could not save the photo: $e');
    }
  }

  void _snack(String text, {String? actionLabel, VoidCallback? onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New entry')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            PhotoPreview(photo: _photo, onTap: _chooseSource),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Web demo: Camera opens the phone camera on mobile browsers '
                  'and a file chooser on desktop.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            LocationCard(
              fix: _fix,
              loading: _locating,
              message: _locationMessage,
              isLastKnown: _isLastKnown,
              onFetch: _fetchLocation,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Caption',
                hintText: 'What is happening here?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _photo == null || _saving || _locating ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Entry'),
            ),
            if (_photo == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Add a photo to enable saving.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
