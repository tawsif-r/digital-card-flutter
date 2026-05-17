import 'package:dio/dio.dart';
import '../domain/activity_model.dart';
import '../domain/task_model.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/mock_service.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<List<ActivityItem>> getActivity() async {
    // TODO: wire to real endpoint when backend ready
    return MockService.getActivity();
  }

  Future<List<TaskModel>> getTasks() async {
    if (AppConfig.useMock) return MockService.getTasks();
    final res = await _dio.get('/api/tasks');
    return (res.data['data'] as List)
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
