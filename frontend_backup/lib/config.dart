import 'package:flutter/foundation.dart';

class AppConfig {
  // Override for a deployed API or a physical phone:
  // flutter run --dart-define=API_BASE_URL=https://api.example.com/api
  static const configuredApiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (configuredApiBaseUrl.isNotEmpty) return configuredApiBaseUrl;
    // Android emulator -> host machine. Desktop, web, and iOS simulator ->
    // localhost. Physical phones should use the computer's LAN IP.
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'https://bookwise-api-9bsx.onrender.com/api';
  }
}

