import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/di/service_locator.dart';
import '../../router/app_router.dart';
import '../api/endpoints.dart';
import '../services/storage_service.dart';

class DioClient {
  final Dio _dio;
  DioClient(this._dio) {
    initialize();
  }

  void initialize() async {
    // Get stored access token
    final token = await StorageService.getAccessToken();

    final authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Authorization header if token exists
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await _logoutUser();
          return; // prevent further handling
        }
        return handler.reject(error);
      },
    );

    _dio
      ..options.baseUrl = Endpoints.baseUrl
      ..options.responseType = ResponseType.json
      ..interceptors.addAll([
        authInterceptor,
        PrettyDioLogger(
          requestBody: true,
          requestHeader: true,
          responseBody: true,
        ),
      ]);
  }

  Future<void> _logoutUser() async {
    // Navigate to splash and clear any state if needed
    getIt<AppRouter>().router.go('/');
  }

  // Retry method can be reintroduced when token refresh is implemented.

  Future<void> updateAccessToken(String? token) async {
    if (token != null) {
      _dio.options.headers["Authorization"] = token;
    }
  }

  Future<Response<Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<Map<String, dynamic>>(
        uri,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> patch(
    String uri, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch<Map<String, dynamic>>(
        uri,
        data: data,
        options: options,
        queryParameters: queryParameters,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<Map<String, dynamic>>(
        uri,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<Response<Map<String, dynamic>>> delete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<Map<String, dynamic>>(
        uri,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (_) {
      rethrow;
    }
  }
}
