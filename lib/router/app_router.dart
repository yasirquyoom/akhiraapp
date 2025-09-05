import 'package:akhira/views/pages/audio_fullscreen_page.dart';
import 'package:akhira/views/pages/book_details_page.dart';
import 'package:akhira/views/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/service_locator.dart';
import '../data/cubits/home/home_cubit.dart';
import '../views/pages/book_content_page.dart';
import '../views/pages/create_account_page.dart';
import '../views/pages/email_sent_page.dart';
import '../views/pages/forgot_password_page.dart';
import '../views/pages/home_page.dart';
import '../views/pages/login_page.dart';
import '../views/pages/welcome_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String createAccount = '/create-account';
  static const String forgotPassword = '/forgot-password';
  static const String emailSent = '/email-sent';
  static const String home = '/home';
  static const String bookDetails = '/book-details';
  static const String bookContent = '/book-content';
  static const String audioFullscreen = '/audio-fullscreen';
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
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => _noTransitionPage(const WelcomePage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _noTransitionPage(const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        name: 'createAccount',
        pageBuilder:
            (context, state) => _noTransitionPage(const CreateAccountPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder:
            (context, state) => _noTransitionPage(const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.emailSent,
        name: 'emailSent',
        pageBuilder:
            (context, state) => _noTransitionPage(const EmailSentPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder:
            (context, state) => _noTransitionPage(
              BlocProvider(
                create: (context) => getIt<HomeCubit>(),
                child: const HomePage(),
              ),
            ),
      ),
      GoRoute(
        path: AppRoutes.bookDetails,
        name: 'bookDetails',
        pageBuilder:
            (context, state) => _noTransitionPage(const BookDetailsPage()),
      ),
      GoRoute(
        path: AppRoutes.bookContent,
        name: 'bookContent',
        pageBuilder: (context, state) {
          final tabIndex =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return _noTransitionPage(BookContentPage(initialTabIndex: tabIndex));
        },
      ),
      GoRoute(
        path: AppRoutes.audioFullscreen,
        name: 'audioFullscreen',
        pageBuilder:
            (context, state) => _noTransitionPage(const AudioFullscreenPage()),
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
