class ApiConfig {
  static const String baseUrl = 'http://10.10.6.39:8000';

  // Safe Locations
  static const String safeLocations = '$baseUrl/api/safe-locations';

  // Predictions
  static const String latestPredictions = '$baseUrl/api/predictions/latest';
  static const String activeAlerts = '$baseUrl/api/predictions/active-alerts';
  static const String historyAlerts = '$baseUrl/api/predictions/history-alerts';

  // FCM
  static const String saveFcmToken = '$baseUrl/api/fcm/save-token';
  static const String deleteFcmToken = '$baseUrl/api/fcm/delete-token';
  static const String sendNotification = '$baseUrl/api/alerts/send-notification';

  // Mobile Auth
  static const String register = '$baseUrl/api/mobile/register';
  static const String login = '$baseUrl/api/mobile/login';
  static const String logout = '$baseUrl/api/mobile/logout';
  static const String profile = '$baseUrl/api/mobile/profile';
  static const String forgotPassword = '$baseUrl/api/mobile/forgot-password';
  static const String verifyOtp = '$baseUrl/api/mobile/verify-otp';
  static const String resetPassword = '$baseUrl/api/mobile/reset-password';
  static const String updateProfile = '$baseUrl/api/mobile/profile/update';

}