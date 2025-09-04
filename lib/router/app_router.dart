import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/pages/home_page.dart';
import '../views/pages/splash_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
}

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _noTransitionPage(const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _noTransitionPage(const HomePage()),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(child: Text('Route not found: \'${state.uri}\'')),
      );
    },
    redirect: (context, state) {
      // Add auth-based redirects later via DI
      return null;
    },
  );
}

CustomTransitionPage<void> _noTransitionPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}
