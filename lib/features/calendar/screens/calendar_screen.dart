import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/calendar_notes_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  final DateTime _lastDay = DateTime.utc(2030, 12, 31);
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notesAsync = ref.watch(calendarNotesProvider);
    final selectedDay = _selectedDay;

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Failed to load notes',
            style: tt.bodyMedium?.copyWith(color: cs.error),
          ),
        ),
        data: (notesMap) {
          final noteText = selectedDay == null
              ? null
              : _noteForDay(selectedDay, notesMap);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    eventLoader: (day) {
                      final note = _noteForDay(day, notesMap);
                      if (note == null) return const [];
                      return [note];
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final note = _noteForDay(day, notesMap);
                        if (note == null) return null;
                        return _NoteDayCell(day: day);
                      },
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        final note = events.first.toString();
                        return Tooltip(
                          message: note,
                          waitDuration: const Duration(milliseconds: 400),
                          child: const _NoteMarker(),
                        );
                      },
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(color: Colors.white),
                      markersMaxCount: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected day',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                selectedDay == null ? 'No day selected' : _formatDate(selectedDay),
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _NotesCard(
                noteText: noteText,
                onAddEdit: selectedDay == null
                    ? null
                    : () => _openNoteEditor(context, selectedDay, noteText),
                onClear: selectedDay == null || noteText == null
                    ? null
                    : () => _clearNote(context, selectedDay),
              ),
            ],
          );
        },
      ),
    );
  }

  String _dateKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDate(DateTime day) {
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$d';
  }

  String? _noteForDay(DateTime day, Map<String, String> notesMap) {
    final note = notesMap[_dateKey(day)];
    if (note == null || note.trim().isEmpty) return null;
    return note;
  }

  Future<void> _openNoteEditor(
      BuildContext context, DateTime day, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Note', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a note for this day…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    if (result.isEmpty) {
      await ref.read(calendarNotesProvider.notifier).removeNote(_dateKey(day));
    } else {
      await ref.read(calendarNotesProvider.notifier).upsertNote(_dateKey(day), result);
    }
  }

  Future<void> _clearNote(BuildContext context, DateTime day) async {
    await ref.read(calendarNotesProvider.notifier).removeNote(_dateKey(day));
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.noteText, this.onAddEdit, this.onClear});

  final String? noteText;
  final VoidCallback? onAddEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final hasNote = noteText != null && noteText!.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Note', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: onAddEdit,
                  child: Text(hasNote ? 'Edit' : 'Add'),
                ),
                if (hasNote)
                  IconButton(
                    tooltip: 'Clear note',
                    onPressed: onClear,
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasNote ? noteText! : 'No note for this day yet.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDayCell extends StatelessWidget {
  const _NoteDayCell({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: tt.bodySmall?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoteMarker extends StatelessWidget {
  const _NoteMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
