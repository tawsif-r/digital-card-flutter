import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/activity_item.dart';
import '../domain/dashboard_overview.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final activityAsync = ref.watch(activityProvider);
    final pendingCount = ref.watch(pendingTaskCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: () {
              ref.read(dashboardOverviewProvider.notifier).refresh();
              ref.read(activityProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(dashboardOverviewProvider.notifier).refresh();
          await ref.read(activityProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _GreetingSection(
                  name: user?.name ?? user?.email ?? 'there',
                  tt: tt,
                  cs: cs,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: overviewAsync.when(
                  loading: () => _StatsRowSkeleton(cs: cs),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (overview) => _StatsRow(
                    overview: overview,
                    pendingCount: pendingCount,
                    tt: tt,
                    cs: cs,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Recent Activity', style: tt.titleMedium),
              ),
            ),
            activityAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => _ActivityItemSkeleton(cs: cs),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorCard(
                    message: 'Failed to load activity.',
                    onRetry: () => ref.read(activityProvider.notifier).refresh(),
                    cs: cs,
                    tt: tt,
                  ),
                ),
              ),
              data: (items) => items.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptyActivity(cs: cs, tt: tt),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _ActivityTile(item: items[i], cs: cs, tt: tt),
                      ),
                    ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Tasks Overview', style: tt.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverToBoxAdapter(
                child: _TasksOverviewCard(
                  pendingCount: pendingCount,
                  onGoToTodos: () => context.go(Routes.todos),
                  cs: cs,
                  tt: tt,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.name, required this.tt, required this.cs});
  final String name;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(
          name.split(' ').first,
          style: tt.headlineSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.overview,
    required this.pendingCount,
    required this.tt,
    required this.cs,
  });
  final DashboardOverview overview;
  final int pendingCount;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'My Cards',
            value: '${overview.totalCards}',
            icon: Icons.badge_outlined,
            color: AppColors.primary,
            tt: tt,
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending Tasks',
            value: '$pendingCount',
            icon: Icons.check_box_outlined,
            color: AppColors.success,
            tt: tt,
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Card Views',
            value: '${overview.cardViewsThisWeek}',
            icon: Icons.visibility_outlined,
            color: const Color(0xFF5B8DB8),
            tt: tt,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tt,
    required this.cs,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: tt.titleLarge?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: tt.labelSmall, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.cs, required this.tt});
  final ActivityItem item;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(item.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_typeIcon(item.type), size: 16, color: _typeColor(item.type)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.description,
                    style: tt.bodySmall, overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_formatTime(item.timestamp), style: tt.labelSmall),
        ],
      ),
    );
  }

  IconData _typeIcon(ActivityType type) => switch (type) {
        ActivityType.message => Icons.chat_bubble_outline,
        ActivityType.meeting => Icons.calendar_today_outlined,
        ActivityType.connection => Icons.person_add_outlined,
        ActivityType.cardView => Icons.visibility_outlined,
        ActivityType.task => Icons.check_circle_outline,
      };

  Color _typeColor(ActivityType type) => switch (type) {
        ActivityType.message => AppColors.primary,
        ActivityType.meeting => const Color(0xFF5B8DB8),
        ActivityType.connection => AppColors.success,
        ActivityType.cardView => const Color(0xFF8B6DB8),
        ActivityType.task => const Color(0xFFB8904A),
      };

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _ActivityItemSkeleton extends StatelessWidget {
  const _ActivityItemSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 36, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No recent activity', style: tt.bodyMedium),
          const SizedBox(height: 4),
          Text('Activity will appear here as you use the app.',
              style: tt.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TasksOverviewCard extends StatelessWidget {
  const _TasksOverviewCard({
    required this.pendingCount,
    required this.onGoToTodos,
    required this.cs,
    required this.tt,
  });
  final int pendingCount;
  final VoidCallback onGoToTodos;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: pendingCount == 0
          ? Column(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 40, color: AppColors.success),
                const SizedBox(height: 12),
                Text('All caught up!', style: tt.titleSmall),
                const SizedBox(height: 4),
                Text('No pending tasks right now.',
                    style: tt.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onGoToTodos,
                  child: const Text('Go to Todos'),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$pendingCount',
                      style: tt.titleLarge?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pendingCount pending task${pendingCount == 1 ? '' : 's'}',
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text('Tap below to manage your tasks.',
                          style: tt.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onGoToTodos,
                  child: const Text('View'),
                ),
              ],
            ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.cs,
    required this.tt,
  });
  final String message;
  final VoidCallback onRetry;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: cs.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: tt.bodyMedium)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
