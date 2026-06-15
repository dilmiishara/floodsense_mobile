import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/water_level_log.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class WaterLevelService {
  Future<List<WaterLevelLog>> getLatestPerStation() async {
    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        final response = await http
            .get(
              Uri.parse(ApiConfig.latestWaterLevels),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] ?? [];

          // ✅ Save to cache
          await CacheService.saveCache(
              CacheService.waterLevels, data);

          return data
              .map((json) => WaterLevelLog.fromJson(json))
              .toList();
        }
      } catch (e) {
        // Fall through to cache
      }
    }

    // ✅ Load from cache when offline or fetch failed
    final cached =
        await CacheService.loadCache(CacheService.waterLevels);
    if (cached != null) {
      final List<dynamic> data = cached;
      return data
          .map((json) => WaterLevelLog.fromJson(json))
          .toList();
    }

    return [];
  }
}