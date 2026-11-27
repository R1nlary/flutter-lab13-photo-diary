import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';

/// Stores the diary offline as one JSON string in SharedPreferences
/// (NSUserDefaults on iOS, SharedPreferences XML on Android, localStorage on
/// the web). Photos themselves live in files, see `PhotoService`.
class DiaryRepository {
  const DiaryRepository();

  static const storageKey = 'photo_diary.entries.v1';

  Future<List<DiaryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return DiaryEntry.decodeList(raw);
    } catch (e) {
      // A broken value must not crash the app on start.
      debugPrint('DiaryRepository: ignoring unreadable data: $e');
      return [];
    }
  }

  /// Returns false when the platform refused to write (e.g. browser quota).
  Future<bool> save(List<DiaryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(storageKey, DiaryEntry.encodeList(entries));
    } catch (e) {
      debugPrint('DiaryRepository: save failed: $e');
      return false;
    }
  }
}
