import 'package:dio/dio.dart';
import '../domain/user_model.dart';
import '../../../core/constants.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  Future<UserModel> register({
    required String email,
    required String password,
    String? name,
    UserRole? role,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
      if (role != null) 'role': role.name,
    });
    await _saveTokens(res.data);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // best-effort server-side revocation
    } finally {
      await _storage.clearAll();
    }
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe({String? name}) async {
    final res = await _dio.patch('/users/me', data: {
      if (name != null) 'name': name,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(StorageKeys.accessToken, data['access_token'] as String);
    await _storage.write(StorageKeys.refreshToken, data['refresh_token'] as String);
    final user = data['user'] as Map<String, dynamic>;
    await _storage.write(StorageKeys.userId, user['id'] as String);
  }
}
