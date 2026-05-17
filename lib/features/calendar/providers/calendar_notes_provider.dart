import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/calendar_note_repository.dart';
import '../domain/calendar_note_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/providers/session_provider.dart';

final calendarNoteRepositoryProvider = Provider<CalendarNoteRepository>((ref) {
  return CalendarNoteRepository(ref.watch(dioProvider));
});

final calendarNotesListProvider =
    FutureProvider<List<CalendarNoteModel>>((ref) async {
  final userId = ref.watch(userSessionProvider);
  if (userId == null) return const [];
  final notes = await ref.watch(calendarNoteRepositoryProvider).getAll();
  notes.sort((a, b) => b.date.compareTo(a.date));
  return notes;
});

final calendarNotesProvider =
    AsyncNotifierProvider<CalendarNotesNotifier, Map<String, String>>(
        CalendarNotesNotifier.new);

class CalendarNotesNotifier extends AsyncNotifier<Map<String, String>> {
  // dateKey → db id, kept in sync with state
  final Map<String, String> _noteIds = {};

  @override
  Future<Map<String, String>> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return {};
    final notes = await ref.watch(calendarNoteRepositoryProvider).getAll();
    _noteIds
      ..clear()
      ..addEntries(notes.map((n) => MapEntry(n.date, n.id)));
    return {for (final n in notes) n.date: n.content};
  }

  Future<void> upsertNote(String dateKey, String note) async {
    final repo = ref.read(calendarNoteRepositoryProvider);
    final current = Map<String, String>.from(state.valueOrNull ?? {});
    final existingId = _noteIds[dateKey];

    final CalendarNoteModel saved;
    if (existingId != null) {
      saved = await repo.update(existingId, note);
    } else {
      saved = await repo.create(dateKey, note);
    }

    _noteIds[saved.date] = saved.id;
    current[dateKey] = saved.content;
    state = AsyncData(current);
  }

  Future<void> removeNote(String dateKey) async {
    final id = _noteIds[dateKey];
    if (id == null) return;

    final repo = ref.read(calendarNoteRepositoryProvider);
    final previous = Map<String, String>.from(state.valueOrNull ?? {});

    // Optimistic remove
    _noteIds.remove(dateKey);
    state = AsyncData(Map<String, String>.from(previous)..remove(dateKey));

    try {
      await repo.delete(id);
    } catch (_) {
      // Rollback on failure
      _noteIds[dateKey] = id;
      state = AsyncData(previous);
    }
  }
}
