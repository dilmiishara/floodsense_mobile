import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/safe_location.dart';

class SafeLocationService {
  Future<List<SafeLocation>> getSafeLocations() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.safeLocations))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SafeLocation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load safe locations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}