import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/exceptions.dart';

/// Client HTTP production — JWT, refresh auto, erreurs métier.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    FlutterSecureStorage? storage,
    Dio? dio,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    _dio.interceptors.add(_JwtInterceptor(_storage, _dio));
  }

  final String baseUrl;
  final Dio _dio;
  final FlutterSecureStorage _storage;

  Dio get dio => _dio;
  FlutterSecureStorage get storage => _storage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

class _JwtInterceptor extends Interceptor {
  _JwtInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['noAuth'] == true) {
      handler.next(options);
      return;
    }
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final code = data is Map ? data['code'] as String? : null;

    if (status == 403 && code == 'ABONNEMENT_REQUIS') {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const SubscriptionException(),
          response: err.response,
          type: err.type,
        ),
      );
      return;
    }

    if (status == 409 && code == 'CONFLIT_SYNC') {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: SyncConflictException(
            remotePayload: data is Map
                ? Map<String, dynamic>.from(data['data'] as Map? ?? {})
                : null,
          ),
          response: err.response,
          type: err.type,
        ),
      );
      return;
    }

    if (status == 401 && err.requestOptions.extra['noRetry'] != true) {
      if (_refreshing) {
        handler.next(err);
        return;
      }
      _refreshing = true;
      try {
        final refresh = await _storage.read(key: 'refresh_token');
        if (refresh == null) {
          await _storage.deleteAll();
          handler.next(err);
          return;
        }
        final resp = await _dio.post<Map<String, dynamic>>(
          '/api/auth/token/refresh/',
          data: {'refresh': refresh},
          options: Options(extra: {'noAuth': true, 'noRetry': true}),
        );
        final newAccess = resp.data?['access'] as String? ??
            resp.data?['access_token'] as String?;
        final newRefresh = resp.data?['refresh'] as String? ??
            resp.data?['refresh_token'] as String?;
        if (newAccess == null) {
          await _storage.deleteAll();
          handler.next(err);
          return;
        }
        await _storage.write(key: 'access_token', value: newAccess);
        if (newRefresh != null) {
          await _storage.write(key: 'refresh_token', value: newRefresh);
        }
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retried = await _dio.fetch(err.requestOptions);
        handler.resolve(retried);
      } catch (_) {
        await _storage.deleteAll();
        handler.next(err);
      } finally {
        _refreshing = false;
      }
      return;
    }

    handler.next(err);
  }
}
