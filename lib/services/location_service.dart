import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_fix.dart';

enum LocationFailureReason {
  /// GPS / Location Services switched off on the device.
  serviceDisabled,

  /// The user tapped "Don't allow" this time.
  denied,

  /// `LocationPermission.deniedForever`: only the app settings page can fix it.
  deniedForever,

  /// No fix within the time limit (indoors, airplane mode, ...).
  timeout,

  /// Anything else the platform threw.
  error,
}

sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.fix, {this.isLastKnown = false});
  final GeoFix fix;

  /// True when the live fix timed out and the cached last position was used.
  final bool isLastKnown;
}

class LocationFailure extends LocationResult {
  const LocationFailure(this.reason, [this.details]);
  final LocationFailureReason reason;
  final String? details;
}

abstract interface class LocationService {
  Future<LocationResult> fetchCurrent();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();

  /// The browser has no "Settings" page we can open.
  bool get canOpenSettings;
}

/// Real implementation backed by `geolocator`.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({
    this.timeLimit = const Duration(seconds: 20),
  });

  final Duration timeLimit;

  @override
  bool get canOpenSettings => !kIsWeb;

  @override
  Future<LocationResult> fetchCurrent() async {
    try {
      // 1. Safety check: is GPS switched on at all?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationFailure(LocationFailureReason.serviceDisabled);
      }

      // 2. Check, then request only if we have not been asked before.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationFailure(LocationFailureReason.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationFailure(LocationFailureReason.deniedForever);
      }

      // 3. One high-accuracy fix. `desiredAccuracy` is the API from the
      // assignment; geolocator 14 marks it deprecated in favour of
      // `locationSettings: LocationSettings(accuracy: LocationAccuracy.high)`.
      final position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeLimit);
      return LocationSuccess(_toFix(position));
    } on TimeoutException {
      return _lastKnownOr(LocationFailureReason.timeout);
    } on LocationServiceDisabledException {
      return const LocationFailure(LocationFailureReason.serviceDisabled);
    } on PermissionDeniedException catch (e) {
      return LocationFailure(LocationFailureReason.denied, e.message);
    } catch (e) {
      return LocationFailure(LocationFailureReason.error, e.toString());
    }
  }

  Future<LocationResult> _lastKnownOr(LocationFailureReason reason) async {
    if (kIsWeb) return LocationFailure(reason);
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LocationSuccess(_toFix(last), isLastKnown: true);
    } catch (_) {
      // Fall through to the original failure.
    }
    return LocationFailure(reason);
  }

  static GeoFix _toFix(Position p) => GeoFix(
    latitude: p.latitude,
    longitude: p.longitude,
    accuracy: p.accuracy,
    altitude: p.altitude,
    timestamp: p.timestamp,
  );

  @override
  Future<bool> openLocationSettings() =>
      kIsWeb ? Future.value(false) : Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() =>
      kIsWeb ? Future.value(false) : Geolocator.openAppSettings();
}
