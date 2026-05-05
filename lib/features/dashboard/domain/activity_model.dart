enum ActivityType { message, meeting, connection, view, task }

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
        type: ActivityType.values.byName(json['type'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
