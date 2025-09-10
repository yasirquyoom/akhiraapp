class Endpoints {
  Endpoints._();

  static const String baseUrl = 'https://ebook-app-nznb.onrender.com/api';

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
