import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/prediction_alert.dart';

class AlertService {
  Future<List<PredictionAlert>> getActiveAlerts() async {
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
        return data
            .map((json) => PredictionAlert.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}