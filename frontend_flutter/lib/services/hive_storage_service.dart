import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiveStorageService {
  static const String _migratedKey = '_migrated_v1';

  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('mykog_data');
    await _migrateFromSharedPreferences();
  }

  static Box get box => _box;

  // ── Migration depuis SharedPreferences ────────────────────────────────────

  static Future<void> _migrateFromSharedPreferences() async {
    if (_box.get(_migratedKey) == true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int migrated = 0;

      for (final key in keys) {
        if (key == _migratedKey) continue;
        try {
          final value = _readPrefValue(prefs, key);
          if (value != null) {
            await _box.put(key, value);
            migrated++;
          }
        } catch (e) {
          debugPrint('HiveMigration: échec clé $key — $e');
        }
      }

      await _box.put(_migratedKey, true);
      debugPrint('HiveMigration: $migrated clés migrées depuis SharedPreferences');
    } catch (e) {
      debugPrint('HiveMigration: erreur globale — $e');
    }
  }

  static dynamic _readPrefValue(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    if (value is String) {
      // Essayer de parser en JSON pour stocker structuré
      try {
        final parsed = jsonDecode(value);
        if (parsed is List || parsed is Map) return parsed;
      } catch (_) {}
      return value;
    }
    if (value is int) return value;
    if (value is double) return value;
    if (value is bool) return value;
    if (value is List<String>) return value;
    return null;
  }

  // ── Méthodes génériques ───────────────────────────────────────────────────

  static dynamic get(String key) => _box.get(key);

  static Future<void> put(String key, dynamic value) => _box.put(key, value);

  static Future<void> delete(String key) => _box.delete(key);

  static Future<int> clear() async {
    final count = _box.length;
    await _box.clear();
    return count;
  }

  static bool containsKey(String key) => _box.containsKey(key);

  // ── Méthodes typées ───────────────────────────────────────────────────────

  static String? getString(String key) {
    final value = _box.get(key);
    if (value is String) return value;
    if (value is List || value is Map) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> storeString(String key, String value) =>
      _box.put(key, value);

  static Map<String, dynamic>? getJson(String key) {
    final value = _box.get(key);
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> storeJson(String key, Map<String, dynamic> value) =>
      _box.put(key, value);

  static List<Map<String, dynamic>> getJsonList(String key) {
    final value = _box.get(key);
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .cast<Map<String, dynamic>>()
          .toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .cast<Map<String, dynamic>>()
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<void> storeJsonList(
          String key, List<Map<String, dynamic>> value) =>
      _box.put(key, value);

  static int getInt(String key, {int defaultValue = 0}) {
    final value = _box.get(key);
    if (value is int) return value;
    return defaultValue;
  }

  static Future<void> storeInt(String key, int value) =>
      _box.put(key, value);

  static bool getBool(String key, {bool defaultValue = false}) {
    final value = _box.get(key);
    if (value is bool) return value;
    return defaultValue;
  }

  static Future<void> storeBool(String key, bool value) =>
      _box.put(key, value);
}
