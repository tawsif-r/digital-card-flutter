import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../constants.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/messaging/providers/threads_provider.dart';
import 'routes.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(navigationShell: navigationShell),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        width: 260,
        child: _SidebarContent(navigationShell: navigationShell),
      ),
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [_ThemeToggle()],
      ),
      body: navigationShell,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: _SidebarContent(navigationShell: navigationShell),
    );
  }
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;

    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_outlined, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConstants.appName,
                    style: tt.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(label: 'Dashboard', icon: Icons.grid_view_rounded, route: Routes.home, shell: navigationShell),
                _NavItem(label: 'Cards', icon: Icons.badge_outlined, route: Routes.cards, shell: navigationShell),
                _SectionLabel('Workspace'),
                _NavItem(label: 'My Company', icon: Icons.business_outlined, route: Routes.company, shell: navigationShell),
                _MessagesNavItem(shell: navigationShell, route: Routes.comms),
                _NavItem(label: 'Mail', icon: Icons.mail_outline, route: Routes.mail, shell: navigationShell),
                _NavItem(label: 'Others', icon: Icons.more_horiz, route: Routes.others, shell: navigationShell),
                _SectionLabel('Network'),
                _NavItem(label: 'Contacts', icon: Icons.contacts_outlined, route: Routes.contacts, shell: navigationShell),
                _NavItem(label: 'Networking', icon: Icons.people_outline, route: Routes.networking, shell: navigationShell),
                _SectionLabel('Personal'),
                _NavItem(label: 'Me', icon: Icons.person_outline, route: Routes.me, shell: navigationShell),
                _NavItem(label: 'Meetings', icon: Icons.calendar_today_outlined, route: Routes.meetings, shell: navigationShell),
                _NavItem(label: 'Calendar', icon: Icons.calendar_month_outlined, route: Routes.calendar, shell: navigationShell),
                _NavItem(label: 'Todos', icon: Icons.check_box_outlined, route: Routes.todos, shell: navigationShell),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          _NavItem(label: 'Settings', icon: Icons.settings_outlined, route: Routes.settings, shell: navigationShell),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            child: SafeArea(
              top: false,
              child: _UserTile(user: user, ref: ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.shell,
  });

  final String label;
  final IconData icon;
  final String route;
  final StatefulNavigationShell shell;

  bool _isActive(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return loc == route || loc.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(route);
            // Close drawer on narrow screens
            if (Scaffold.of(context).hasDrawer) {
              Scaffold.of(context).closeDrawer();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? AppColors.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      color: active ? AppColors.primary : cs.onSurface,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.ref});
  final dynamic user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials(user?.name ?? user?.email ?? '?'),
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user?.name != null)
                Text(user!.name!, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text(user?.email ?? '', style: tt.labelSmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
          onPressed: () => ref.read(themeProvider.notifier).toggle(),
          color: cs.onSurfaceVariant,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, size: 18),
          onPressed: () => ref.read(authProvider).logout(),
          color: cs.onSurfaceVariant,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeProvider.notifier).toggle(),
    );
  }
}

class _MessagesNavItem extends ConsumerWidget {
  const _MessagesNavItem({required this.shell, required this.route});
  final StatefulNavigationShell shell;
  final String route;

  bool _isActive(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return loc == route || loc.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadTotalProvider);
    final active = _isActive(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(route);
            if (Scaffold.of(context).hasDrawer) {
              Scaffold.of(context).closeDrawer();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.forum_outlined,
                    size: 18,
                    color: active ? AppColors.primary : cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Messages',
                    style: tt.bodyMedium?.copyWith(
                      color: active ? AppColors.primary : cs.onSurface,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: tt.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
