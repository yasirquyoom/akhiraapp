import 'package:dio/dio.dart';
import '../api/endpoints.dart';
import '../helper/dio_client.dart';
import '../models/collection_response.dart';
import '../models/redeem_request.dart';

class CollectionRepository {
  final DioClient _dioClient;

  CollectionRepository(this._dioClient);

  Future<CollectionResponse> getCollections({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dioClient.get(
        Endpoints.collections,
        queryParameters: {'skip': skip, 'limit': limit},
      );

      return CollectionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return CollectionResponse.fromJson(e.response!.data);
        } catch (_) {
          return CollectionResponse(
            status: e.response?.statusCode ?? 500,
            message:
                e.response?.data?['message'] ?? 'Failed to fetch collections',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<CollectionResponse> redeemBook(RedeemRequest request) async {
    try {
      final response = await _dioClient.post(
        Endpoints.redeemBook,
        data: request.toJson(),
      );

      return CollectionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          return CollectionResponse.fromJson(e.response!.data);
        } catch (_) {
          return CollectionResponse(
            status: e.response?.statusCode ?? 500,
            message: e.response?.data?['message'] ?? 'Failed to redeem book',
          );
        }
      }
      throw Exception('Network error occurred');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }
}
