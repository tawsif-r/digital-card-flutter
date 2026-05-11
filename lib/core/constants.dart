import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  // Optional override:
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://192.168.3.35:3000';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      _ => 'http://192.168.3.35:3000',
    };
  }

  static const String appName = 'Digital Card';
}

class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
}
