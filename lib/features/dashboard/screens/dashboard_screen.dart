import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../domain/activity_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/routes.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, this.pendingRoute});

  final String? pendingRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(dashboardProvider.notifier).refresh(),
            ref.refresh(pendingRequestsProvider.future),
          ]);
        },
        child: dashAsync.when(
          loading: () => const _DashboardShimmer(),
          error: (_, __) => _ErrorView(
            onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
          ),
          data: (data) => _DashboardBody(
            state: data,
            pendingRoute: pendingRoute ?? Routes.contactPending,
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.state, required this.pendingRoute});

  final DashboardState state;
  final String pendingRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name?.split(' ').first ?? 'there';
    final greeting = _greeting();
    final pendingAsync = ref.watch(pendingRequestsProvider);
    final pendingCount = pendingAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _WelcomeHeader(greeting: greeting, name: name),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _StatsRow(
              activityCount: state.activity.length,
              pendingRequestCount: pendingCount,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _PendingRequestsCard(
              pendingCount: pendingCount,
              isLoading: pendingAsync.isLoading,
              pendingRoute: pendingRoute,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(title: 'Recent Activity', count: state.activity.length),
          ),
        ),
        if (state.activity.isEmpty)
          const SliverToBoxAdapter(child: _EmptyActivity())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.separated(
              itemCount: state.activity.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ActivityTile(item: state.activity[i]),
            ),
          ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name!',
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedDate(),
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.activityCount, required this.pendingRequestCount});

  final int activityCount;
  final int pendingRequestCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Activity',
            value: activityCount.toString(),
            icon: Icons.timeline_outlined,
            color: AppColors.mint,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending Requests',
            value: pendingRequestCount.toString(),
            icon: Icons.person_add_alt_outlined,
            color: AppColors.rose,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Connections',
            value: '24',
            icon: Icons.people_outline,
            color: AppColors.sage,
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color.withOpacity(0.9)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsCard extends StatelessWidget {
  const _PendingRequestsCard({
    required this.pendingCount,
    required this.isLoading,
    required this.pendingRoute,
  });

  final int pendingCount;
  final bool isLoading;
  final String pendingRoute;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_alt_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Loading requests…'
                      : pendingCount == 0
                          ? 'No pending requests'
                          : '$pendingCount pending request${pendingCount == 1 ? '' : 's'}',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  pendingCount == 0
                      ? "You're all caught up."
                      : 'Review incoming connection requests.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go(pendingRoute),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Review', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count', style: tt.labelSmall),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = _iconAndColor(item.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(item.timestamp),
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColor(ActivityType type) => switch (type) {
        ActivityType.message => (Icons.chat_bubble_outline, AppColors.mint),
        ActivityType.meeting => (Icons.calendar_today_outlined, AppColors.sage),
        ActivityType.connection => (Icons.people_outline, AppColors.primary),
        ActivityType.view => (Icons.visibility_outlined, const Color(0xFF7B8FA1)),
        ActivityType.task => (Icons.check_circle_outline, AppColors.success),
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_outlined, size: 48, color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No recent activity', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Activity from messages, meetings, and connections will appear here.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 52, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Failed to load dashboard', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(200, 28, cs),
          const SizedBox(height: 8),
          _shimmerBox(140, 16, cs),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _shimmerBox(double.infinity, 88, cs)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(double.infinity, 88, cs)),
              const SizedBox(width: 12),
              Expanded(child: _shimmerBox(double.infinity, 88, cs)),
            ],
          ),
          const SizedBox(height: 24),
          _shimmerBox(double.infinity, 80, cs),
          const SizedBox(height: 24),
          _shimmerBox(120, 20, cs),
          const SizedBox(height: 12),
          ...List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _shimmerBox(double.infinity, 72, cs),
          )),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, ColorScheme cs) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
      );
}
