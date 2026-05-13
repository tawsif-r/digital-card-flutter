class CalendarNoteModel {
  const CalendarNoteModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String date;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CalendarNoteModel.fromJson(Map<String, dynamic> json) =>
      CalendarNoteModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: json['date'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
