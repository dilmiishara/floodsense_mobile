import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/prediction_alert.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class PredictionService {
  Future<List<Map<String, dynamic>>> getLatestPredictions() async {
    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        final response = await http
            .get(
              Uri.parse(ApiConfig.latestPredictions),
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
              CacheService.predictions, data);

          return data
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (e) {
        // Fall through to cache
      }
    }

    // ✅ Load from cache when offline
    final cached =
        await CacheService.loadCache(CacheService.predictions);
    if (cached != null) {
      final List<dynamic> data = cached;
      return data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }
}