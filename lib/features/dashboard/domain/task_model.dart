enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: TaskStatus.values.byName(json['status'] as String),
        priority: TaskPriority.values.byName(json['priority'] as String),
        dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'status': status.name,
        'priority': priority.name,
        if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
      );
}
