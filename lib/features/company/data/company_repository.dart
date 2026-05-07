import 'package:dio/dio.dart';
import '../domain/company_model.dart';

class CompanyRepository {
  CompanyRepository(this._dio);

  final Dio _dio;

  Future<CompanyModel> onboard({
    required String name,
    required String description,
    required int size,
  }) async {
    final res = await _dio.post('/company/onboard', data: {
      'name': name,
      'description': description,
      'size': size,
    });
    return CompanyModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CompanyModel?> getMe() async {
    try {
      final res = await _dio.get('/company/me');
      return CompanyModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 400) return null;
      rethrow;
    }
  }
}
