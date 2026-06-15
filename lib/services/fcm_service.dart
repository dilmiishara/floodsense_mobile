import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/navigator_key.dart';
import 'package:flutter/material.dart';

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
      print('Foreground message body: ${message.notification?.body}');
      // Show snackbar when app is open
      if (message.notification != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message.notification!.body ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1a3a5c),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });

    // ✅ Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped — app in background');
      _handleNotificationTap(message);
    });

    // ✅ Handle notification tap when app was terminated
    RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('Notification tapped — app was terminated');
      // Small delay to ensure navigator is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(initialMessage);
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);
  }

  // ✅ Handle notification tap — navigate to correct screen
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    print('Notification data: $data');

    final type   = data['type']   ?? '';
    final screen = data['screen'] ?? '';

    if (type == 'emergency') {
      // Emergency notification → go to safe zones
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/safe-zones',
        (route) => route.isFirst,
      );
    } else if (screen == 'alerts') {
      // Flood alert → go to alerts screen
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/alerts',
        (route) => route.isFirst,
      );
    } else if (screen == 'home') {
      // Emergency cleared → go to home
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => route.isFirst,
      );
    }
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