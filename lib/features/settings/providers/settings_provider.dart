import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/di/providers.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
        UserProfileNotifier.new);

class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() =>
      ref.watch(settingsRepositoryProvider).getProfile();

  Future<bool> save(Map<String, dynamic> data) async {
    try {
      final updated =
          await ref.read(settingsRepositoryProvider).updateProfile(data);
      state = AsyncData(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(
        UserSettingsNotifier.new);

class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() =>
      ref.watch(settingsRepositoryProvider).getSettings();

  Future<void> toggle(Map<String, dynamic> patch) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final merged = UserSettings.fromJson({
      ...current.toJson(),
      ...patch,
    });
    state = AsyncData(merged);
    try {
      final updated =
          await ref.read(settingsRepositoryProvider).updateSettings(merged.toJson());
      state = AsyncData(updated);
    } catch (_) {
      state = AsyncData(current);
    }
  }
}
