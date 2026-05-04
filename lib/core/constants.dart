class AppConstants {
  AppConstants._();

  // Change to your machine's local IP for physical device testing.
  // Use 10.0.2.2 for Android emulator.
  static const String baseUrl = 'http://localhost:3000';

  static const String appName = 'Digital Card';
}

class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
}
