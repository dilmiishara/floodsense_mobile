import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'fcm_service.dart';

class LocationService {

  // testing
  //   static Future<Position?> getCurrentLocation() async {
  //   // TESTING ONLY — fake Rathnapura location
  //     // latitude: 6.690,
  //     // longitude: 80.380,
  //   return Position(
  //     latitude: 6.735,   // ← 0.5km from Ellagawa
  //     longitude: 80.218,
  //     timestamp: DateTime.now(),
  //     accuracy: 0,
  //     altitude: 0,
  //     altitudeAccuracy: 0,
  //     heading: 0,
  //     headingAccuracy: 0,
  //     speed: 0,
  //     speedAccuracy: 0,
  //   );
  // }

  // Get current GPS location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 Location services disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('📍 Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('📍 Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('📍 Location error: $e');
      return null;
    }
  }

  // Save location to Laravel
  static Future<void> saveLocationToServer(Position position) async {
    try {
      final fcmService = FCMService();
      final token = await fcmService.getToken();

      if (token == null) {
        print('📍 No FCM token available');
        return;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.saveUserLocation),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'fcm_token': token,
              'latitude': position.latitude,
              'longitude': position.longitude,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('📍 Location saved to server successfully');
      } else {
        print('📍 Failed to save location: ${response.statusCode}');
      }
    } catch (e) {
      print('📍 Save location error: $e');
    }
  }

  // Request location and save — main method
  static Future<void> requestAndSaveLocation() async {
    final position = await getCurrentLocation();
    if (position != null) {
      await saveLocationToServer(position);
    }
  }
}