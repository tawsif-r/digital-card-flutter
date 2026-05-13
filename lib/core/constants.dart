import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl {
    final dotenvUrl = dotenv.env['API_BASE_URL'];
    if (dotenvUrl != null && dotenvUrl.isNotEmpty) return dotenvUrl;

    final dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;

    if (kIsWeb) return 'API_BASE_URL';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3001',
      _ => 'API_BASE_URL',
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

//http://192.168.3.35:3001