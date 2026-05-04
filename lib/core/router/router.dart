import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cards/screens/home_screen.dart';
import '../../features/cards/screens/card_builder_screen.dart';
import '../../features/cards/screens/card_detail_screen.dart';
import '../../features/share/screens/public_card_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isLoading = authNotifier.state is AuthInitial || authNotifier.state is AuthLoading;
      final path = state.matchedLocation;

      // Always allow public card
      if (path.startsWith('/c/')) return null;

      // Splash: stay while loading, redirect when done
      if (path == Routes.splash) {
        if (isLoading) return null;
        return isAuthenticated ? Routes.home : Routes.login;
      }

      // Still loading — stay on splash
      if (isLoading) return Routes.splash;

      final isAuthRoute = path == Routes.login || path == Routes.register;

      if (!isAuthenticated && !isAuthRoute) return Routes.login;
      if (isAuthenticated && isAuthRoute) return Routes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.cardNew,
        builder: (_, __) => const CardBuilderScreen(),
      ),
      GoRoute(
        path: Routes.cardDetail,
        builder: (_, state) => CardDetailScreen(
          cardId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Routes.cardEdit,
        builder: (_, state) => CardBuilderScreen(
          cardId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: Routes.publicCard,
        builder: (_, state) => PublicCardScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
    ],
  );
});
