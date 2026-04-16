import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userKey = 'user';
  static const String _teachingsKey = 'teachings';
  static const String _playlistsKey = 'playlists';
  static const String _currentPlayingKey = 'current_playing';
  static const String _queueKey = 'queue';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Generic methods for storing and retrieving data
  static Future<bool> storeString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  static String? getString(String key) {
    return prefs.getString(key);
  }

  static Future<bool> storeJson(String key, Map<String, dynamic> json) async {
    return await prefs.setString(key, jsonEncode(json));
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> storeJsonList(String key, List<Map<String, dynamic>> jsonList) async {
    return await prefs.setString(key, jsonEncode(jsonList));
  }

  static List<Map<String, dynamic>> getJsonList(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> storeBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<bool> storeInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  static int getInt(String key, {int defaultValue = 0}) {
    return prefs.getInt(key) ?? defaultValue;
  }

  static Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  static Future<bool> clear() async {
    return await prefs.clear();
  }

  // Specific data keys
  static String get userKey => _userKey;
  static String get teachingsKey => _teachingsKey;
  static String get playlistsKey => _playlistsKey;
  static String get currentPlayingKey => _currentPlayingKey;
  static String get queueKey => _queueKey;

  // Méthode pour effacer toutes les données d'enseignements
  static Future<void> clearAllTeachingsData() async {
    await remove(teachingsKey);
    await remove('cached_teachings');
    await remove('recently_played');
    await remove('favorites');
    print('Toutes les données d\'enseignements ont été effacées');
  }

  // Méthode pour réinitialiser complémentent le stockage
  static Future<void> resetAllStorage() async {
    await clear();
    print('Toutes les données de stockage ont été effacées');
  }
}