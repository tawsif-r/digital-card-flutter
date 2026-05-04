import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureStorage _storage;

  // Set by AuthNotifier after initialization
  void Function()? onUnauthenticated;

  bool _isRefreshing = false;
  final List<_PendingRequest> _queue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestPath = err.requestOptions.path;

    if (response?.statusCode != 401 || requestPath.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _queue.add(_PendingRequest(err.requestOptions, handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(StorageKeys.refreshToken);
      if (refreshToken == null) throw Exception('No refresh token');

      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final res = await dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      final newAccess = res.data['access_token'] as String;
      final newRefresh = res.data['refresh_token'] as String;

      await _storage.write(StorageKeys.accessToken, newAccess);
      await _storage.write(StorageKeys.refreshToken, newRefresh);

      await _retryRequest(err.requestOptions, newAccess, handler);
      for (final pending in _queue) {
        await _retryRequest(pending.options, newAccess, pending.handler);
      }
      _queue.clear();
    } catch (_) {
      await _storage.clearAll();
      onUnauthenticated?.call();
      handler.next(err);
      for (final pending in _queue) {
        pending.handler.next(DioException(requestOptions: pending.options));
      }
      _queue.clear();
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _retryRequest(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      options.headers['Authorization'] = 'Bearer $token';
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

class _PendingRequest {
  _PendingRequest(this.options, this.handler);
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
}
