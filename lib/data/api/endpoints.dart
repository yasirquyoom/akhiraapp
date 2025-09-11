import 'package:flutter/foundation.dart' show kIsWeb;

class Endpoints {
  Endpoints._();

  static const String _mobileBaseUrl =
      'http://q4g004cwocwso88okkwc4csg.217.76.48.185.sslip.io:8001/api';

  // Use a relative HTTPS-safe base on web to avoid mixed-content; Vercel rewrites /api → backend
  static String get baseUrl => kIsWeb ? '/api' : _mobileBaseUrl;

  // Auth
  static const String register = '/user/register';
  static const String login = '/user/login';
  static const String forgotPassword = '/user/forgot-password';
  static const String refreshToken = '/auth/refresh';

  // Collections
  static const String collections = '/user/collections';
  static const String redeemBook = '/user/collections/redeem';

  // Book Content
  static String bookContent(String bookId) =>
      '/user/collections/book/$bookId/content';

  // Quiz
  static String bookQuizzes(String bookId) =>
      '/user/collections/book/$bookId/quizzes';

  // Quiz actions
  static const String submitQuizAnswer = '/user/quiz/submit-answer';
  static String quizScore(String bookId) => '/user/quiz/book/$bookId/score';
  static String quizReset(String bookId) => '/user/quiz/book/$bookId/reset';
}
