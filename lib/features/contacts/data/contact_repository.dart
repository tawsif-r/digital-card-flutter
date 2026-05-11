import 'package:dio/dio.dart';
import '../domain/contact_model.dart';
import '../../../shared/domain/paged_result.dart';

class ContactRepository {
  ContactRepository(this._dio);
  final Dio _dio;

  Future<PagedResult<ContactModel>> getAccepted({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/contacts',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      },
    );
    return PagedResult.fromJson(res.data!, ContactModel.fromJson);
  }

  Future<List<ContactModel>> getPending() async {
    final res = await _dio.get<List<dynamic>>('/contacts/pending');
    return (res.data ?? [])
        .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ContactModel>> getSent() async {
    final res = await _dio.get<List<dynamic>>('/contacts/sent');
    return (res.data ?? [])
        .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContactModel> getOne(String id) async {
    final res = await _dio.get('/contacts/$id');
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> sendRequest(String addresseeId) async {
    final res = await _dio.post(
      '/contacts/request',
      data: {'addressee_id': addresseeId},
    );
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> accept(String id) async {
    final res = await _dio.post('/contacts/$id/accept');
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> reject(String id) async {
    await _dio.post('/contacts/$id/reject');
  }

  Future<ContactModel> block(String id) async {
    final res = await _dio.post('/contacts/$id/block');
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ContactModel> updateNotes(String id, String? notes) async {
    final res = await _dio.patch('/contacts/$id/notes', data: {'notes': notes});
    return ContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/contacts/$id');
  }

  Future<PagedResult<UserSearchResult>> searchUsers({
    required String q,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/users/search',
      queryParameters: {'q': q, 'page': page, 'limit': limit},
    );
    return PagedResult.fromJson(res.data!, UserSearchResult.fromJson);
  }
}
