import 'package:akhira/views/pages/account_page.dart';
import 'package:akhira/views/pages/audio_fullscreen_page.dart';
import 'package:akhira/views/pages/book_details_page.dart';
import 'package:akhira/views/pages/pdf_viewer_page.dart';
import 'package:akhira/views/pages/splash_page.dart';
import 'package:akhira/views/pages/video_fullscreen_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/pdf_model.dart';
import '../data/models/video_model.dart';
import '../data/models/book_model.dart';
import '../views/pages/book_content_page.dart';
import '../views/pages/create_account_page.dart';
import '../views/pages/email_sent_page.dart';
import '../views/pages/forgot_password_page.dart';
import '../views/pages/home_page.dart';
import '../views/pages/login_page.dart';
import '../views/pages/welcome_page.dart';
import '../data/cubits/audio/audio_cubit.dart';
import '../core/di/service_locator.dart';

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
  static const String videoFullscreen = '/video-fullscreen';
  static const String pdfViewer = '/pdf-viewer';
  static const String account = '/account';
}

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    observers: [_PauseAudioOnRouteObserver()],
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
        pageBuilder: (context, state) => _noTransitionPage(const HomePage()),
      ),
      GoRoute(
        path: AppRoutes.bookDetails,
        name: 'bookDetails',
        pageBuilder:
            (context, state) => _noTransitionPage(
              BookDetailsPage(book: state.extra as BookModel?),
            ),
      ),
      GoRoute(
        path: AppRoutes.bookContent,
        name: 'bookContent',
        pageBuilder: (context, state) {
          final tabIndex =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          final bookId = state.uri.queryParameters['bookId'];
          return _noTransitionPage(
            BookContentPage(initialTabIndex: tabIndex, bookId: bookId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.audioFullscreen,
        name: 'audioFullscreen',
        pageBuilder:
            (context, state) => _noTransitionPage(const AudioFullscreenPage()),
      ),
      GoRoute(
        path: AppRoutes.videoFullscreen,
        name: 'videoFullscreen',
        pageBuilder: (context, state) {
          // Get video data from extra parameter
          final videoData = state.extra as Map<String, dynamic>?;

          if (videoData != null) {
            final video = VideoModel(
              id: 'dynamic_${DateTime.now().millisecondsSinceEpoch}',
              title: videoData['title'] ?? 'Unknown Video',
              thumbnailUrl: videoData['thumbnailUrl'] ?? '',
              videoUrl: videoData['videoUrl'] ?? '',
              duration: '0:00', // We don't have duration from API
              description: 'Video from book content',
            );

            return _noTransitionPage(VideoFullscreenPage(video: video));
          }

          // Fallback to dummy video if no data provided
          return _noTransitionPage(
            VideoFullscreenPage(
              video: const VideoModel(
                id: '1',
                title: 'Sample Video',
                thumbnailUrl:
                    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&h=225&fit=crop',
                videoUrl:
                    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
                duration: '02:30',
                description: 'Sample video description',
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.pdfViewer,
        name: 'pdfViewer',
        pageBuilder: (context, state) {
          // Get PDF data from extra parameter
          final pdfData = state.extra as Map<String, dynamic>?;

          if (pdfData != null) {
            final pdf = PdfModel(
              id: pdfData['id'] ?? 'unknown',
              title: pdfData['title'] ?? 'Unknown PDF',
              pdfUrl: pdfData['pdfUrl'] ?? '',
              thumbnailUrl: pdfData['thumbnailUrl'] ?? '',
              description: pdfData['description'] ?? 'PDF from book content',
              totalPages: pdfData['totalPages'] ?? 0,
              author: pdfData['author'] ?? 'Unknown Author',
            );

            return _noTransitionPage(PdfViewerPage(pdf: pdf));
          }

          // Fallback to dummy PDF if no data provided
          return _noTransitionPage(
            PdfViewerPage(
              pdf: const PdfModel(
                id: '1',
                title: 'Introduction to Islamic Studies',
                pdfUrl:
                    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                thumbnailUrl:
                    'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=300&h=400&fit=crop',
                description:
                    'A comprehensive guide to Islamic studies covering fundamental concepts, history, and practices.',
                totalPages: 25,
                author: 'Dr. Ahmed Hassan',
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.account,
        name: 'account',
        pageBuilder: (context, state) => _noTransitionPage(const AccountPage()),
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

class _PauseAudioOnRouteObserver extends NavigatorObserver {
  void _maybePauseAudio() {
    try {
      final context = navigator?.context;
      if (context == null) return;
      final currentPath =
          getIt<AppRouter>().router.routeInformationProvider.value.uri.path;
      final onPermittedScreen =
          currentPath == AppRoutes.audioFullscreen ||
          currentPath == AppRoutes.bookContent;
      if (!onPermittedScreen) context.read<AudioCubit>().pauseTrack();
    } catch (_) {}
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _maybePauseAudio();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _maybePauseAudio();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _maybePauseAudio();
  }
}
