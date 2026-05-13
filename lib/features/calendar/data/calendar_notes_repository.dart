import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarNotesRepository {
  CalendarNotesRepository(this._prefs, {required this.userId});

  static const String _notesKey = 'calendar_notes_v1';

  final SharedPreferences _prefs;
  final String userId;

  String get _keyForUser => '${_notesKey}_$userId';

  Future<Map<String, String>> loadNotes() async {
    final raw = _prefs.getString(_keyForUser);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveNotes(Map<String, String> notes) async {
    final encoded = jsonEncode(notes);
    await _prefs.setString(_keyForUser, encoded);
  }
}
