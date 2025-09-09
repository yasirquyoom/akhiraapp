import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../helper/dio_client.dart';
import '../models/book_content_response.dart';

class BookContentRepository {
  final DioClient _dioClient;

  BookContentRepository(this._dioClient);

  Future<BookContentResponse> getBookContent({
    required String bookId,
    String? contentType,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (contentType != null) {
        queryParams['content_type'] = contentType;
      }

      final response = await _dioClient.get(
        Endpoints.bookContent(bookId),
        queryParameters: queryParams,
      );

      return BookContentResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return BookContentResponse.fromJson(e.response!.data);
        } catch (_) {
          return BookContentResponse(
            status: e.response?.statusCode ?? 500,
            message:
                e.response?.data?['message'] ?? 'Failed to fetch book content',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
