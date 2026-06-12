import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PredictionService {
  Future<List<Map<String, dynamic>>> getLatestPredictions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.latestPredictions),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> raw = data['data'];
        return raw.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}