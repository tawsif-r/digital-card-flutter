import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/calendar_notes_repository.dart';
import '../../../core/providers/session_provider.dart';

final calendarNotesProvider =
    AsyncNotifierProvider<CalendarNotesNotifier, Map<String, String>>(
        CalendarNotesNotifier.new);

class CalendarNotesNotifier extends AsyncNotifier<Map<String, String>> {
  late final CalendarNotesRepository _repo;

  @override
  Future<Map<String, String>> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return {};
    final prefs = await SharedPreferences.getInstance();
    _repo = CalendarNotesRepository(prefs, userId: userId);
    return _repo.loadNotes();
  }

  Future<void> upsertNote(String dateKey, String note) async {
    final current = Map<String, String>.from(state.valueOrNull ?? {});
    current[dateKey] = note;
    state = AsyncData(current);
    await _repo.saveNotes(current);
  }

  Future<void> removeNote(String dateKey) async {
    final current = Map<String, String>.from(state.valueOrNull ?? {});
    if (!current.containsKey(dateKey)) return;
    current.remove(dateKey);
    state = AsyncData(current);
    await _repo.saveNotes(current);
  }
}
