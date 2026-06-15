import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class SyncService {
  // Sync all data
  static Future<bool> syncAll() async {
    final online = await ConnectivityService.isOnline();
    if (!online) {
      print('📵 Offline — skipping sync');
      return false;
    }

    print('🔄 Syncing all data...');

    bool success = false;

    // Run all syncs in parallel
    final results = await Future.wait([
      _syncWaterLevels(),
      _syncActiveAlerts(),
      _syncHistoryAlerts(),
      _syncSafeLocations(),
      _syncPredictions(),
    ]);

    success = results.any((r) => r == true);
    print('✅ Sync complete');
    return success;
  }


  static Future<bool> _syncHistoryAlerts() async {
  try {
    final response = await http
        .get(
          Uri.parse(ApiConfig.historyAlerts),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'] ?? body;
      await CacheService.saveCache(
          CacheService.historyAlerts, data);
      print('✅ History alerts synced');
      return true;
    }
  } catch (e) {
    print('❌ History alerts sync failed: $e');
  }
  return false;
}

  // Sync water levels
  static Future<bool> _syncWaterLevels() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.latestWaterLevels),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];
        await CacheService.saveCache(CacheService.waterLevels, data);
        print('✅ Water levels synced');
        return true;
      }
    } catch (e) {
      print('❌ Water levels sync failed: $e');
    }
    return false;
  }

  // Sync active alerts
  static Future<bool> _syncActiveAlerts() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.activeAlerts),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        await CacheService.saveCache(CacheService.activeAlerts, data);
        print('✅ Active alerts synced');
        return true;
      }
    } catch (e) {
      print('❌ Active alerts sync failed: $e');
    }
    return false;
  }

  // Sync safe locations
  static Future<bool> _syncSafeLocations() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.safeLocations),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await CacheService.saveCache(
            CacheService.safeLocations, data);
        print('✅ Safe locations synced');
        return true;
      }
    } catch (e) {
      print('❌ Safe locations sync failed: $e');
    }
    return false;
  }

  // Sync predictions
  static Future<bool> _syncPredictions() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.latestPredictions),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];
        await CacheService.saveCache(
            CacheService.predictions, data);
        print('✅ Predictions synced');
        return true;
      }
    } catch (e) {
      print('❌ Predictions sync failed: $e');
    }
    return false;
  }
}