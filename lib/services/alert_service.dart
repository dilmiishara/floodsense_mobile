import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/alert.dart';

class AlertService {
  Future<List<Alert>> getActiveAlerts() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.activeAlerts))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Alert.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Alert>> getAlertHistory() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.alertHistory))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Alert.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load alert history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}