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
  final authNotifier = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authNotifier.isAuthenticated;
      final isInitial = authNotifier.state is AuthInitial;
      final path = state.matchedLocation;

      // Always allow public card and splash
      if (path.startsWith('/c/') || path == Routes.splash) return null;

      // Still initializing — stay on splash
      if (isInitial) return Routes.splash;

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
