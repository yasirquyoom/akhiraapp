import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../core/di/service_locator.dart';
import '../../router/app_router.dart';
import '../api/endpoints.dart';
import '../services/storage_service.dart';

class DioClient {
  final Dio _dio;
  // Simple in-memory cache for GET requests
  final Map<String, _CachedResponse> _getCache = {};
  // Default TTL for cached GET responses
  Duration _defaultTtl = const Duration(minutes: 5);

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
      // Compose a cache key using url + sorted query params
      final cacheKey = _composeCacheKey(url, queryParameters);

      // Respect cache-control via options.extra if provided
      final disableCache = options?.extra?['disableCache'] == true;
      final ttlMs = options?.extra?['cacheTtlMs'] is int
          ? options!.extra!['cacheTtlMs'] as int
          : null;
      final ttl = ttlMs != null ? Duration(milliseconds: ttlMs) : _defaultTtl;

      if (!disableCache) {
        final cached = _getCache[cacheKey];
        if (cached != null && !cached.isExpired) {
          // Return a cloned Response to avoid mutations affecting cache
          return Response<Map<String, dynamic>>(
            data: cached.data,
            requestOptions: RequestOptions(path: url),
            statusCode: 200,
          );
        }
      }

      final resp = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      // Cache only successful responses with JSON bodies
      if (!disableCache && (resp.statusCode ?? 500) >= 200 && (resp.statusCode ?? 500) < 300) {
        _getCache[cacheKey] = _CachedResponse(
          data: resp.data,
          cachedAt: DateTime.now(),
          ttl: ttl,
        );
        _evictIfOverCapacity();
      }

      return resp;
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

  // Helper: compose deterministic cache key
  String _composeCacheKey(String url, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return url;
    final keys = query.keys.toList()..sort();
    final buf = StringBuffer(url);
    for (final k in keys) {
      final v = query[k];
      buf.write('|');
      buf.write(k);
      buf.write('=');
      buf.write(v);
    }
    return buf.toString();
  }

  // Naive capacity control: keep up to N entries, evict oldest
  static const int _maxCacheEntries = 128;
  void _evictIfOverCapacity() {
    if (_getCache.length <= _maxCacheEntries) return;
    // Sort by cachedAt and remove oldest 10%
    final entries = _getCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = (_getCache.length * 0.1).ceil();
    for (int i = 0; i < removeCount && i < entries.length; i++) {
      _getCache.remove(entries[i].key);
    }
  }
}

class _CachedResponse {
  final Map<String, dynamic>? data;
  final DateTime cachedAt;
  final Duration ttl;

  _CachedResponse({required this.data, required this.cachedAt, required this.ttl});

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
}
