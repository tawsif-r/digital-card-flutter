import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/activity_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';

class DashboardState {
  const DashboardState({required this.activity});

  final List<ActivityItem> activity;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return const DashboardState(activity: []);
    return _fetch();
  }

  Future<DashboardState> _fetch() async {
    final repo = ref.read(dashboardRepositoryProvider);
    final activity = await repo.getActivity();
    return DashboardState(activity: activity);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
