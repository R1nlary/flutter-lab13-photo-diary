import 'package:flutter/material.dart';
import 'package:flutter_lab13_photo_diary/app.dart';
import 'package:flutter_lab13_photo_diary/services/location_service.dart';
import 'package:flutter_lab13_photo_diary/services/permission_service.dart';
import 'package:flutter_lab13_photo_diary/services/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// A phone-sized screen (360 x 800 logical pixels).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> openNewEntry(WidgetTester tester) async {
  await tester.tap(find.text('New entry'));
  await tester.pumpAndSettle();
}

/// Scrolls the form until [text] is on screen, then taps it.
Future<void> tapText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('smoke: empty feed, then the new-entry form', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(PhotoDiaryApp(services: fakeServices()));
    await tester.pumpAndSettle();

    expect(find.text('Photo Diary'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);

    await openNewEntry(tester);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.text('No photo yet'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Fetch GPS'), findsOneWidget);
    expect(find.text('Save Entry'), findsOneWidget);

    final save = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Save Entry'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(save.onPressed, isNull, reason: 'no photo yet');
  });

  testWidgets('Fetch GPS shows latitude, longitude, accuracy, altitude', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(PhotoDiaryApp(services: fakeServices()));
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tapText(tester, 'Fetch GPS');
    await tester.pumpAndSettle();

    expect(find.text('43.238949° N'), findsOneWidget);
    expect(find.text('76.889709° E'), findsOneWidget);
    expect(find.text('± 4.8 m'), findsOneWidget);
    expect(find.text('812.3 m'), findsOneWidget);
  });

  testWidgets('camera photo -> automatic GPS -> caption -> saved in feed', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final photos = FakePhotoService();
    final location = FakeLocationService(LocationSuccess(testFix));
    await tester.pumpWidget(
      PhotoDiaryApp(
        services: fakeServices(photos: photos, location: location),
      ),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(photos.picked, [ImageSource.camera]);
    expect(location.fetchCalls, 1, reason: 'GPS is fetched after capture');
    expect(find.text('No photo yet'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Narxoz campus');
    await tapText(tester, 'Save Entry');
    await tester.pumpAndSettle();

    expect(find.text('Narxoz campus'), findsOneWidget);
    expect(find.text('43.2389° N, 76.8897° E'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    // Persisted offline.
    final stored = await const DiaryRepository().load();
    expect(stored.single.caption, 'Narxoz campus');
    expect(stored.single.location, testFix);
  });

  testWidgets('bottom sheet offers Camera and Gallery', (tester) async {
    usePhoneScreen(tester);
    final photos = FakePhotoService();
    await tester.pumpWidget(
      PhotoDiaryApp(services: fakeServices(photos: photos)),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tester.tap(find.text('No photo yet'));
    await tester.pumpAndSettle();
    expect(find.text('Take a new photo'), findsOneWidget);
    await tester.tap(find.text('Choose an existing photo'));
    await tester.pumpAndSettle();
    expect(photos.picked, [ImageSource.gallery]);
  });

  testWidgets('GPS switched off -> dialog opens location settings', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final location = FakeLocationService(
      const LocationFailure(LocationFailureReason.serviceDisabled),
    );
    await tester.pumpWidget(
      PhotoDiaryApp(services: fakeServices(location: location)),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tapText(tester, 'Fetch GPS');
    await tester.pumpAndSettle();
    expect(find.text('Turn on GPS'), findsOneWidget);
    await tester.tap(find.text('Open location settings'));
    await tester.pumpAndSettle();
    expect(location.locationSettingsOpened, 1);
    expect(
      find.text('Location services (GPS) are turned off.'),
      findsOneWidget,
    );
  });

  testWidgets('location denied forever -> dialog opens app settings', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final location = FakeLocationService(
      const LocationFailure(LocationFailureReason.deniedForever),
    );
    await tester.pumpWidget(
      PhotoDiaryApp(services: fakeServices(location: location)),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tapText(tester, 'Fetch GPS');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open app settings'));
    await tester.pumpAndSettle();
    expect(location.appSettingsOpened, 1);
  });

  testWidgets('camera denied -> SnackBar, picker is not opened', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final photos = FakePhotoService();
    await tester.pumpWidget(
      PhotoDiaryApp(
        services: fakeServices(
          photos: photos,
          permissions: FakePermissionService(camera: AccessStatus.denied),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tester.tap(find.text('Camera'));
    await tester.pump();
    expect(
      find.text('Camera permission is needed to take a photo.'),
      findsOneWidget,
    );
    expect(photos.picked, isEmpty);
  });

  testWidgets('camera permanently denied -> Open Settings dialog', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final permissions = FakePermissionService(
      camera: AccessStatus.permanentlyDenied,
    );
    await tester.pumpWidget(
      PhotoDiaryApp(services: fakeServices(permissions: permissions)),
    );
    await tester.pumpAndSettle();
    await openNewEntry(tester);

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera access is off'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(permissions.settingsOpened, 1);
  });

  testWidgets('entries saved earlier are loaded on start', (tester) async {
    usePhoneScreen(tester);
    SharedPreferences.setMockInitialValues({
      DiaryRepository.storageKey:
          '[{"id":"1","photoPath":"photos/1.jpg","caption":"Saved before",'
          '"createdAt":"2026-11-27T09:00:00.000Z","location":null}]',
    });
    await tester.pumpWidget(PhotoDiaryApp(services: fakeServices()));
    await tester.pumpAndSettle();
    expect(find.text('Saved before'), findsOneWidget);
    expect(find.text('Location unavailable'), findsOneWidget);
  });
}
