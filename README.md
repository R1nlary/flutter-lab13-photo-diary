# Flutter Lab 13 — Narxoz Geotagged Photo Diary

An offline photo diary: take a photo or pick one from the gallery, tag it with a high-accuracy GPS
fix, add a caption and keep it on the device.

**Live web demo:** https://r1nlary.github.io/flutter-lab13-photo-diary/
(in the browser the camera button opens the phone camera on mobile and a file chooser on desktop;
the browser asks for location itself)

Packages: `image_picker`, `geolocator`, `permission_handler`, `shared_preferences`,
`path_provider`, `intl`.

## Features

1. **Permissions (Task 1)**
   - Camera and photo library go through `permission_handler`; location goes through `geolocator`
     (`isLocationServiceEnabled()` → `checkPermission()` → `requestPermission()`).
   - **GPS switched off** → dialog "Turn on GPS" → `Geolocator.openLocationSettings()`.
   - **Denied** → floating SnackBar with *Try again*; the app never crashes and an entry can still be
     saved without coordinates.
   - **Denied forever** (Android "Don't ask again") → dialog → `Geolocator.openAppSettings()` for
     location, `openAppSettings()` from permission_handler for the camera.
   - Gallery: Android 13+ Photo Picker and iOS PHPicker only share the one photo the user taps, so a
     denied library permission is explained, not treated as a dead end.
2. **Capture (Task 2)** — *Camera* (`ImageSource.camera`) and *Gallery* (`ImageSource.gallery`)
   buttons, plus a modal bottom sheet when the preview is tapped. `pickImage(imageQuality: 80,
   maxWidth: 1080)`. Live preview inside `ClipRRect(borderRadius: 20)` with `Image.file(File(path))`
   (web build: `Image.network(xfile.path)` behind `kIsWeb`). A camera icon placeholder is shown
   until there is a photo.
3. **GPS (Task 3)** — on *Fetch GPS* or automatically right after a photo is taken:
   `CircularProgressIndicator`, then `Geolocator.getCurrentPosition(desiredAccuracy:
   LocationAccuracy.high)` with a 20 s time limit (falls back to the last known position on mobile).
   Shows **Latitude, Longitude, Accuracy (± m), Altitude, Timestamp**.
4. **Diary (Task 4)** — caption `TextField` + **Save Entry**. Home screen is a `ListView` feed with a
   thumbnail, caption, coordinates (`43.2389° N, 76.8897° E`) and formatted time; tap an entry for
   details or to delete it. Material 3, light and dark theme.

### Offline storage

| What | Where |
| --- | --- |
| Entry metadata (id, photo path, caption, time, lat/lng/accuracy/altitude/GPS time) | JSON list in `shared_preferences` under `photo_diary.entries.v1` |
| Photo on Android / iOS | copied from the picker's temp file to `<app documents>/photos/<id>.jpg`; only the relative path is stored, because the iOS container path changes after app updates |
| Photo on the web | stored as a `data:` URL (a picked file's `blob:` URL dies with the tab) |

## Permissions

| Platform | Key / permission | Used for |
| --- | --- | --- |
| Android | `android.permission.CAMERA` | taking a photo |
| Android | `android.permission.ACCESS_FINE_LOCATION` | precise GPS fix |
| Android | `android.permission.ACCESS_COARSE_LOCATION` | approximate location |
| Android | `android.permission.READ_MEDIA_IMAGES` | photo library on Android 13+ |
| Android | `READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`) | legacy storage on Android 12 and older (there `Permission.photos` asks for nothing and the gallery uses the system picker) |
| iOS | `NSCameraUsageDescription` | camera |
| iOS | `NSPhotoLibraryUsageDescription` | photo library |
| iOS | `NSLocationWhenInUseUsageDescription` | location while the app is open |

Android: `compileSdk = 37`, because `permission_handler_android` 14.1 requires it.
On iOS this project uses Swift Package Manager; `permission_handler_apple` enables the
camera/photos/location code from the `NS*UsageDescription` keys found in `Info.plist`.

## Structure

```
lib/
  main.dart                    wires the real services and runs the app
  app.dart                     MaterialApp, Material 3 theme
  models/geo_fix.dart          lat, lng, accuracy, altitude, timestamp + JSON
  models/diary_entry.dart      photo path, caption, createdAt, GeoFix? + JSON
  services/permission_service.dart  permission_handler (camera, photos)
  services/location_service.dart    geolocator: service check, permission, getCurrentPosition
  services/photo_service.dart       image_picker + copy to app documents
  services/diary_repository.dart    shared_preferences JSON
  screens/diary_feed_screen.dart    ListView feed, details, delete
  screens/new_entry_screen.dart     photo, GPS, caption, Save Entry
  widgets/                     photo preview, source sheet, location card, entry tile, dialogs
  utils/formatters.dart        43.2389° N, 76.8897° E / ± 4.8 m / 27 Nov 2026, 14:05
```

Screens receive their services through a `DiaryServices` object, so the widget tests run the
whole flow with fakes instead of platform plugins.

## Run

```bash
flutter pub get
flutter run                      # Android / iOS device or simulator
flutter run -d chrome            # web
flutter test
```

The iOS Simulator has no camera: use *Gallery* there, and set a location in
Simulator → Features → Location.

## Tests

25 tests: `GeoFix` / `DiaryEntry` JSON round-trip (with and without location, int vs double),
coordinate formatting for all four hemispheres, repository save/load and broken JSON, status
mapping from permission_handler, and widget tests for the empty feed, the new-entry form, Fetch
GPS, photo → automatic GPS → caption → saved entry in the feed and in storage, the bottom sheet,
GPS-off and denied-forever dialogs, and camera denied / permanently denied.
