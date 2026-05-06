import 'package:dio/dio.dart';
import '../domain/mail_model.dart';

class MailRepository {
  MailRepository(this._dio);

  final Dio _dio;

  Future<void> send({
    required List<String> to,
    required String subject,
    String? textBody,
    String? htmlBody,
  }) async {
    await _dio.post('/mail/send', data: {
      'to': to,
      'subject': subject,
      if (textBody != null && textBody.isNotEmpty) 'textBody': textBody,
      if (htmlBody != null && htmlBody.isNotEmpty) 'htmlBody': htmlBody,
    });
  }

  Future<List<MailModel>> getSent({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/mail', queryParameters: {'page': page, 'limit': limit});
    final list = res.data is List ? res.data as List : (res.data['data'] as List);
    return list.map((e) => MailModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> delete(String id) => _dio.delete('/mail/$id');
}
