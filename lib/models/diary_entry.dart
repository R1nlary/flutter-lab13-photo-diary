import 'dart:convert';

import 'geo_fix.dart';

/// A saved diary entry: photo + caption + where and when it was taken.
class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.photoPath,
    required this.caption,
    required this.createdAt,
    this.location,
  });

  final String id;

  /// On Android/iOS: a path relative to the app documents directory
  /// (`photos/<id>.jpg`). On the web: a `data:` URL with the image bytes.
  final String photoPath;

  final String caption;
  final DateTime createdAt;

  /// `null` when GPS was unavailable or the user denied location access.
  final GeoFix? location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'photoPath': photoPath,
    'caption': caption,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'location': location?.toJson(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    return DiaryEntry(
      id: json['id'] as String,
      photoPath: json['photoPath'] as String,
      caption: json['caption'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      location: location is Map<String, dynamic>
          ? GeoFix.fromJson(location)
          : null,
    );
  }

  static String encodeList(List<DiaryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<DiaryEntry> decodeList(String source) {
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      other is DiaryEntry &&
      other.id == id &&
      other.photoPath == photoPath &&
      other.caption == caption &&
      other.createdAt.isAtSameMomentAs(createdAt) &&
      other.location == location;

  @override
  int get hashCode => Object.hash(
    id,
    photoPath,
    caption,
    createdAt.millisecondsSinceEpoch,
    location,
  );
}
