import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/session_controller.dart';
import '../../features/authentication/presentation/screens/account_placeholder_screen.dart';
import '../../features/authentication/presentation/screens/check_email_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/recipes/domain/recipe.dart';
import '../../features/recipes/presentation/screens/recipe_detail_screen.dart';
import '../../features/recipes/presentation/screens/recipe_list_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_tab.dart';
import '../../shared/widgets/splash_screen.dart';
import 'app_routes.dart';

/// Re-runs the router's redirect whenever the session changes (login, logout, 401).
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      if (session.isLoading && !session.hasValue) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final loggedIn = session.valueOrNull != null;
      final onPublic = AppRoutes.public.contains(location);

      if (!loggedIn) return onPublic ? null : AppRoutes.login;
      if (onPublic || location == AppRoutes.splash) return AppRoutes.recipes;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkEmail,
        builder: (_, state) =>
            CheckEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kitchen,
                builder: (_, __) => const PlaceholderTab(
                  eyebrow: 'My kitchen',
                  heading: "What's in your kitchen?",
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recipes,
                builder: (_, __) => const RecipeListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => RecipeDetailScreen(
                      recipeId: state.pathParameters['id']!,
                      initialRecipe: state.extra is Recipe
                          ? state.extra as Recipe
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (_, __) => const PlaceholderTab(
                  eyebrow: 'Saved',
                  heading: 'Saved recipes',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (_, __) => const AccountPlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
