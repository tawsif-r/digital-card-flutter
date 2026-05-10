import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';

class SettingsState {
  const SettingsState({
    required this.profile,
    required this.settings,
  });

  final UserProfile profile;
  final UserSettings settings;

  SettingsState copyWith({UserProfile? profile, UserSettings? settings}) =>
      SettingsState(
        profile: profile ?? this.profile,
        settings: settings ?? this.settings,
      );
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) throw StateError('Not authenticated');
    return _fetch();
  }

  Future<SettingsState> _fetch() async {
    final repo = ref.read(settingsRepositoryProvider);
    final results = await Future.wait([
      repo.getProfile(),
      repo.getSettings(),
    ]);
    return SettingsState(
      profile: results[0] as UserProfile,
      settings: results[1] as UserSettings,
    );
  }

  Future<(bool, String?)> updateProfile(UserProfile profile) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(previous.copyWith(profile: profile));
    }
    try {
      final updated = await ref.read(settingsRepositoryProvider).updateProfile(profile);
      state = AsyncData((state.valueOrNull ?? previous)!.copyWith(profile: updated));
      return (true, null);
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return (false, 'Failed to update profile. Try again.');
    }
  }

  Future<(bool, String?)> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ref.read(settingsRepositoryProvider).updatePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      return (true, null);
    } catch (e) {
      return (false, 'Failed to update password. Check current password and try again.');
    }
  }

  Future<(bool, String?)> updateSettings(UserSettings settings) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(previous.copyWith(settings: settings));
    }
    try {
      final updated = await ref.read(settingsRepositoryProvider).updateSettings(settings);
      state = AsyncData((state.valueOrNull ?? previous)!.copyWith(settings: updated));
      return (true, null);
    } catch (e) {
      if (previous != null) state = AsyncData(previous);
      return (false, 'Failed to save settings. Try again.');
    }
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
