import 'package:dio/dio.dart';
import '../domain/calendar_note_model.dart';

class CalendarNoteRepository {
  CalendarNoteRepository(this._dio);

  final Dio _dio;

  Future<List<CalendarNoteModel>> getAll() async {
    final res = await _dio.get<List<dynamic>>('/calendar-notes');
    return (res.data ?? [])
        .map((e) => CalendarNoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CalendarNoteModel> create(String date, String content) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/calendar-notes',
      data: {'date': date, 'content': content},
    );
    return CalendarNoteModel.fromJson(res.data!);
  }

  Future<CalendarNoteModel> update(String id, String content) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/calendar-notes/$id',
      data: {'content': content},
    );
    return CalendarNoteModel.fromJson(res.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/calendar-notes/$id');
  }
}
