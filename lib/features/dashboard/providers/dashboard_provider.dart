import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/activity_item.dart';
import '../domain/dashboard_overview.dart';
import '../../../core/di/providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

final dashboardOverviewProvider =
    AsyncNotifierProvider<DashboardOverviewNotifier, DashboardOverview>(
        DashboardOverviewNotifier.new);

class DashboardOverviewNotifier
    extends AsyncNotifier<DashboardOverview> {
  @override
  Future<DashboardOverview> build() =>
      ref.watch(dashboardRepositoryProvider).getOverview();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(dashboardRepositoryProvider).getOverview());
  }
}

final activityProvider =
    AsyncNotifierProvider<ActivityNotifier, List<ActivityItem>>(
        ActivityNotifier.new);

class ActivityNotifier extends AsyncNotifier<List<ActivityItem>> {
  @override
  Future<List<ActivityItem>> build() =>
      ref.watch(dashboardRepositoryProvider).getActivity();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(dashboardRepositoryProvider).getActivity());
  }
}
