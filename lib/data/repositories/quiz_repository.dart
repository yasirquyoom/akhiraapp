import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../helper/dio_client.dart';
import '../models/quiz_response.dart';

class QuizRepository {
  final DioClient _dioClient;

  QuizRepository(this._dioClient);

  Future<QuizResponse> getBookQuizzes({
    required String bookId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      final response = await _dioClient.get(
        Endpoints.bookQuizzes(bookId),
        queryParameters: queryParams,
      );

      return QuizResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return QuizResponse.fromJson(e.response!.data);
        } catch (_) {
          return QuizResponse(
            status: e.response?.statusCode ?? 500,
            message:
                e.response?.data?['message'] ?? 'Failed to fetch book quizzes',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Response> submitAnswer({
    required String quizId,
    required String userAnswer,
  }) async {
    return _dioClient.post(
      Endpoints.submitQuizAnswer,
      data: {'quiz_id': quizId, 'user_answer': userAnswer},
    );
  }

  Future<Response> getScore({required String bookId}) {
    return _dioClient.get(Endpoints.quizScore(bookId));
  }

  Future<Response> resetAnswers({required String bookId}) {
    return _dioClient.delete(Endpoints.quizReset(bookId));
  }
}
