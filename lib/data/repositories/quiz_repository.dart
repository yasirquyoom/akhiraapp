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
}
