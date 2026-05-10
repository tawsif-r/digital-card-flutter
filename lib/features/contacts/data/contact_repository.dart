import 'package:dio/dio.dart';
import '../domain/contact_model.dart';
import '../../../shared/domain/paged_result.dart';

class ContactRepository {
  ContactRepository(this._dio);

  final Dio _dio;

  Future<PagedResult<ContactModel>> getAll({
    String? search,
    String? source,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/contacts',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (source != null) 'source': source,
        'page': page,
        'limit': limit,
      },
    );
    return PagedResult.fromJson(res.data!, ContactModel.fromJson);
  }

  Future<ContactModel> getOne(String id) async {
    final res = await _dio.get('/contacts/$id');
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> addBySlug(String slug, {String? notes}) async {
    final res = await _dio.post('/contacts/scan', data: {
      'slug': slug,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> addByEmail(String email, {String? notes}) async {
    final res = await _dio.post('/contacts/import/email', data: {
      'email': email,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PhoneImportResult> importFromPhone(
    List<Map<String, String?>> contacts,
  ) async {
    final res = await _dio.post('/contacts/import/phone', data: {
      'contacts': contacts,
    });
    return PhoneImportResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> updateNotes(String id, String? notes) async {
    final res = await _dio.patch('/contacts/$id', data: {'notes': notes});
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/contacts/$id');
  }

  Future<Map<String, String>> shareMyCard(
    String contactId, {
    String? cardId,
  }) async {
    final res = await _dio.post('/contacts/$contactId/share-my-card', data: {
      if (cardId != null) 'card_id': cardId,
    });
    final data = res.data as Map<String, dynamic>;
    return {
      'message': data['message'] as String,
      'recipient_email': data['recipient_email'] as String,
    };
  }
}
