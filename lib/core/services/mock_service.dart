import 'dart:math';
import '../../features/settings/domain/user_profile.dart';
import '../../features/settings/domain/user_settings.dart';

class MockService {
  MockService._();

  static Future<void> delay() async {
    final ms = 300 + Random().nextInt(500);
    await Future.delayed(Duration(milliseconds: ms));
  }

  static Future<UserProfile> getUserProfile() async {
    await delay();
    return const UserProfile(
      id: 'mock_user_001',
      email: 'john.doe@digitalcard.io',
      fullName: 'John Doe',
      phone: '+880 1234-567890',
      designation: 'Software Engineer',
      department: 'Engineering',
      company: 'DigitalCard Inc',
    );
  }

  static Future<UserSettings> getUserSettings() async {
    await delay();
    return UserSettings.defaults;
  }

  static Future<UserProfile> updateUserProfile(UserProfile profile) async {
    await delay();
    return profile;
  }

  static Future<UserSettings> updateUserSettings(UserSettings settings) async {
    await delay();
    return settings;
  }
}
