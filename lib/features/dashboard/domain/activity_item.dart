enum ActivityType { message, meeting, connection, cardView, task }

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        id: json['id'] as String,
        type: ActivityType.values.firstWhere(
          (e) => e.name == (json['type'] as String),
          orElse: () => ActivityType.message,
        ),
        title: json['title'] as String,
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
