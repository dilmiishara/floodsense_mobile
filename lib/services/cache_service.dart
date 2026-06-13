import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  // Save any data to cache
  static Future<void> saveCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    // Save timestamp
    await prefs.setString(
        '${key}_time', DateTime.now().toIso8601String());
  }

  // Load data from cache
  static Future<dynamic> loadCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // Check if cache exists
  static Future<bool> hasCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // Get cache time
  static Future<String?> getCacheTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${key}_time');
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await prefs.remove('${key}_time');
  }

  // Cache keys
  static const String waterLevels = 'cache_water_levels';
  static const String activeAlerts = 'cache_active_alerts';
  static const String safeLocations = 'cache_safe_locations';
  static const String predictions = 'cache_predictions';
}