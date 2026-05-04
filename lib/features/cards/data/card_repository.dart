import 'package:dio/dio.dart';
import '../domain/card_model.dart';
import '../domain/card_data.dart';

class CardRepository {
  CardRepository(this._dio);

  final Dio _dio;

  Future<List<CardModel>> getAll() async {
    final res = await _dio.get('/cards');
    return (res.data as List).map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CardModel> getOne(String id) async {
    final res = await _dio.get('/cards/$id');
    return CardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CardModel> create(CardData data) async {
    final res = await _dio.post('/cards', data: data.toJson());
    return CardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CardModel> update(String id, CardData data) async {
    final res = await _dio.patch('/cards/$id', data: data.toJson());
    return CardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/cards/$id');
  }

  Future<CardModel> getPublic(String slug) async {
    final res = await _dio.get('/public/$slug');
    return CardModel.fromJson(res.data as Map<String, dynamic>);
  }
}
