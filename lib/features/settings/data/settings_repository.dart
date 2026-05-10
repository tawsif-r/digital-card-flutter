import 'package:dio/dio.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/services/mock_service.dart';

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> getProfile() async {
    final res = await _dio.get('/users/me');
    final data = res.data as Map<String, dynamic>;
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      fullName: data['name'] as String?,
    );
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final res = await _dio.patch('/users/me', data: {
      if (profile.fullName != null && profile.fullName!.isNotEmpty)
        'name': profile.fullName,
      'email': profile.email,
    });
    final data = res.data as Map<String, dynamic>;
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      fullName: data['name'] as String?,
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch('/users/me', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<UserSettings> getSettings() async {
    // TODO: wire to real endpoint when backend ready
    return MockService.getUserSettings();
  }

  Future<UserSettings> updateSettings(UserSettings settings) async {
    // TODO: wire to real endpoint when backend ready
    return MockService.updateUserSettings(settings);
  }
}
