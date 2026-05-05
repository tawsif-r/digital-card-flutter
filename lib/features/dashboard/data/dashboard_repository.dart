import 'package:dio/dio.dart';
import '../domain/activity_model.dart';
import '../domain/task_model.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/mock_service.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<List<ActivityItem>> getActivity() async {
    if (AppConfig.useMock) return MockService.getActivity();
    final res = await _dio.get('/api/activity');
    return (res.data['data'] as List)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getTaskCount() async {
    if (AppConfig.useMock) return MockService.getTaskCount();
    final res = await _dio.get('/api/tasks/count');
    return res.data['data']['pending'] as int;
  }

  Future<List<TaskModel>> getTasks() async {
    if (AppConfig.useMock) return MockService.getTasks();
    final res = await _dio.get('/api/tasks');
    return (res.data['data'] as List)
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
