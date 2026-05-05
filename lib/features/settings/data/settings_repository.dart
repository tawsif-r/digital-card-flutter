import 'package:dio/dio.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    final res = await _dio.get('/users/profile');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/users/profile', data: data);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserSettings> getSettings() async {
    final res = await _dio.get('/users/settings');
    return UserSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserSettings> updateSettings(Map<String, dynamic> data) async {
    final res = await _dio.put('/users/settings', data: data);
    return UserSettings.fromJson(res.data as Map<String, dynamic>);
  }
}
