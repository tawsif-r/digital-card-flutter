import 'package:dio/dio.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/mock_service.dart';

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    if (AppConfig.useMock) return MockService.getUserProfile();
    final res = await _dio.get('/api/user/profile');
    return UserProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (AppConfig.useMock) return MockService.updateUserProfile(profile);
    final res = await _dio.put('/api/user/profile', data: profile.toJson());
    return UserProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserSettings> getSettings() async {
    if (AppConfig.useMock) return MockService.getUserSettings();
    final res = await _dio.get('/api/user/settings');
    return UserSettings.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserSettings> updateSettings(UserSettings settings) async {
    if (AppConfig.useMock) return MockService.updateUserSettings(settings);
    final res = await _dio.put('/api/user/settings', data: settings.toJson());
    return UserSettings.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
