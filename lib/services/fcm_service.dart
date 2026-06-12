import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await saveTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      saveTokenToBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  Future<void> saveTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.saveFcmToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'device_type': 'android',
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token saved to backend successfully');
      } else {
        print('Failed to save FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  Future<void> deleteTokenFromBackend(String token) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.deleteFcmToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}