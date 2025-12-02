import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KppProgressRepository {
  static const _storageKey = 'kpp_progress_v1';

  /// Returns a map where key is question ID and value is status (true=correct, false=incorrect)
  Future<Map<int, bool>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return {};
    
    try {
      final Map<String, dynamic> decoded = json.decode(data);
      // Convert String keys back to Int
      return decoded.map((key, value) => MapEntry(int.parse(key), value as bool));
    } catch (e) {
      return {};
    }
  }

  Future<void> saveProgress(Map<int, bool> progress) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert Int keys to String for JSON
    final Map<String, bool> stringKeyMap = progress.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_storageKey, json.encode(stringKeyMap));
  }
  
  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
