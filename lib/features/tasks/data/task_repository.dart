import 'package:dio/dio.dart';
import '../domain/task_model.dart';

class TaskRepository {
  TaskRepository(this._dio);

  final Dio _dio;

  Future<List<TaskModel>> getAll() async {
    final res = await _dio.get('/tasks');
    return (res.data as List)
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getCount() async {
    final res = await _dio.get('/tasks/count');
    return (res.data['count'] as num).toInt();
  }

  Future<TaskModel> create(String title, {String? description}) async {
    final res = await _dio.post('/tasks', data: {
      'title': title,
      if (description != null) 'description': description,
    });
    return TaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TaskModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/tasks/$id', data: data);
    return TaskModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/tasks/$id');
  }
}
