import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Check if device is online
  static Future<bool> isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Stream of connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(
          (result) => result != ConnectivityResult.none,
        );
  }
}