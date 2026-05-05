enum TaskStatus { pending, inProgress, done }

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: TaskStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String),
          orElse: () => TaskStatus.pending,
        ),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null) 'description': description,
        'status': status.name,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
