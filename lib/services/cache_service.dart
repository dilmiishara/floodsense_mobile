import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  // Cache keys
  static const String waterLevels = 'cache_water_levels';
  static const String activeAlerts = 'cache_active_alerts';
  static const String safeLocations = 'cache_safe_locations';
  static const String predictions = 'cache_predictions';
  static const String historyAlerts = 'cache_history_alerts';

  // Save data to cache
  static Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      await prefs.setString(
        '${key}_time',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Cache save error: $e');
    }
  }

  // Load data from cache
  static Future<dynamic> loadCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      if (data == null) return null;
      return jsonDecode(data);
    } catch (e) {
      print('Cache load error: $e');
      return null;
    }
  }

  // Check if cache exists
  static Future<bool> hasCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Get cache saved time
  static Future<String?> getCacheTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('${key}_time');
    } catch (e) {
      return null;
    }
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_time');
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  // Clear ALL cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(waterLevels);
      await prefs.remove(activeAlerts);
      await prefs.remove(safeLocations);
      await prefs.remove(predictions);
      print('🗑️ All cache cleared');
    } catch (e) {
      print('Cache clear all error: $e');
    }
  }
}