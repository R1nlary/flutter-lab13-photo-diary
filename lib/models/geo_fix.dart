/// One GPS reading taken by `Geolocator.getCurrentPosition`.
///
/// Kept separate from geolocator's `Position` so the rest of the app (and the
/// tests) do not depend on the plugin.
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy radius in metres (the "±" value).
  final double accuracy;

  /// Metres above the WGS84 ellipsoid. 0 when the device does not report it.
  final double altitude;

  /// When the fix was taken.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };

  /// JSON numbers that happen to be whole (e.g. `0`) come back as `int`,
  /// so every number goes through `num.toDouble()`.
  factory GeoFix.fromJson(Map<String, dynamic> json) => GeoFix(
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lng'] as num).toDouble(),
    accuracy: (json['accuracy'] as num? ?? 0).toDouble(),
    altitude: (json['altitude'] as num? ?? 0).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is GeoFix &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracy == accuracy &&
      other.altitude == altitude &&
      other.timestamp.isAtSameMomentAs(timestamp);

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    accuracy,
    altitude,
    timestamp.millisecondsSinceEpoch,
  );
}
