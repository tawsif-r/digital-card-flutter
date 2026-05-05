import 'package:dio/dio.dart';
import '../domain/activity_item.dart';
import '../domain/dashboard_overview.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardOverview> getOverview() async {
    final res = await _dio.get('/dashboard/overview');
    return DashboardOverview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActivityItem>> getActivity({int limit = 20, int offset = 0}) async {
    final res = await _dio.get('/activity', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return (res.data as List)
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
