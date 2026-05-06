import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'app_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cards/screens/home_screen.dart';
import '../../features/cards/screens/card_builder_screen.dart';
import '../../features/cards/screens/card_detail_screen.dart';
import '../../features/share/screens/public_card_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/mail/screens/mail_screen.dart';
import '../../shared/screens/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isLoading = authNotifier.state is AuthInitial || authNotifier.state is AuthLoading;
      final path = state.matchedLocation;

      if (path.startsWith('/c/')) return null;

      if (path == Routes.splash) {
        if (isLoading) return null;
        return isAuthenticated ? Routes.home : Routes.login;
      }

      if (isLoading) return Routes.splash;

      final isAuthRoute = path == Routes.login || path == Routes.register;

      if (!isAuthenticated && !isAuthRoute) return Routes.login;
      if (isAuthenticated && isAuthRoute) return Routes.home;

      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: Routes.publicCard,
        builder: (_, state) => PublicCardScreen(slug: state.pathParameters['slug']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.cards,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(path: 'new', builder: (_, __) => const CardBuilderScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => CardDetailScreen(cardId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, state) => CardBuilderScreen(
                        cardId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.company,
              builder: (_, __) => const PlaceholderScreen(title: 'My Company', icon: Icons.business_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.comms,
              builder: (_, __) => const PlaceholderScreen(title: 'Communication Hub', icon: Icons.hub_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.others,
              builder: (_, __) => const PlaceholderScreen(title: 'Others', icon: Icons.more_horiz),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.contacts,
              builder: (_, __) => const PlaceholderScreen(title: 'Contacts', icon: Icons.contacts_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.networking,
              builder: (_, __) => const PlaceholderScreen(title: 'Networking', icon: Icons.people_outline),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.me,
              builder: (_, __) => const PlaceholderScreen(title: 'Me', icon: Icons.person_outline),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.meetings,
              builder: (_, __) => const PlaceholderScreen(title: 'Meetings', icon: Icons.calendar_today_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.todos,
              builder: (_, __) => const PlaceholderScreen(title: 'Todos', icon: Icons.check_box_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.mail,
              builder: (_, __) => const MailScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
