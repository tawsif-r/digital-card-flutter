import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

Dio createDio(SecureStorage storage, void Function() onUnauthenticated) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage, onUnauthenticated));

  return dio;
}
