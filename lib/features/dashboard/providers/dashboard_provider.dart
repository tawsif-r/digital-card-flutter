import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/activity_model.dart';
import '../../../core/di/providers.dart';

class DashboardState {
  const DashboardState({
    required this.activity,
    required this.pendingTaskCount,
  });

  final List<ActivityItem> activity;
  final int pendingTaskCount;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() => _fetch();

  Future<DashboardState> _fetch() async {
    final repo = ref.read(dashboardRepositoryProvider);
    final results = await Future.wait([
      repo.getActivity(),
      repo.getTaskCount(),
    ]);
    return DashboardState(
      activity: results[0] as List<ActivityItem>,
      pendingTaskCount: results[1] as int,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
