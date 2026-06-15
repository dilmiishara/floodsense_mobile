import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/prediction_alert.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class PredictionAlertService {
  Future<List<PredictionAlert>> getPredictionAlerts() async {
    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        final response = await http
            .get(
              Uri.parse(ApiConfig.activeAlerts),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] ?? body;

          // ✅ Save to cache
          await CacheService.saveCache(
              CacheService.activeAlerts, data);

          return data
              .map((json) => PredictionAlert.fromJson(json))
              .toList();
        }
      } catch (e) {
        // Fall through to cache
      }
    }

    // ✅ Load from cache
    final cached =
        await CacheService.loadCache(CacheService.activeAlerts);
    if (cached != null) {
      final List<dynamic> data = cached;
      return data
          .map((json) => PredictionAlert.fromJson(json))
          .toList();
    }

    return [];
  }

  Future<List<PredictionAlert>> getHistoryAlerts() async {
    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        final response = await http
            .get(
              Uri.parse(ApiConfig.historyAlerts),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final List<dynamic> data = body['data'] ?? body;
          return data
              .map((json) => PredictionAlert.fromJson(json))
              .toList();
        }
      } catch (e) {
        // ignore
      }
    }

    return [];
  }
}


Future<List<PredictionAlert>> getHistoryAlerts() async {
  final online = await ConnectivityService.isOnline();

  if (online) {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.historyAlerts),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? body;

        // ✅ Save to cache
        await CacheService.saveCache(
            CacheService.historyAlerts, data);

        return data
            .map((json) => PredictionAlert.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Fall through to cache
    }
  }

  // ✅ Load from cache when offline
  final cached =
      await CacheService.loadCache(CacheService.historyAlerts);
  if (cached != null) {
    final List<dynamic> data = cached;
    return data
        .map((json) => PredictionAlert.fromJson(json))
        .toList();
  }

  return [];
}