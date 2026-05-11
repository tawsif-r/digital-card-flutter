class ThreadModel {
  const ThreadModel({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessageId,
    this.userALastReadAt,
    this.userBLastReadAt,
  });

  final String id;
  final String userAId;
  final String userBId;
  final DateTime? lastMessageAt;
  final String? lastMessageId;
  final DateTime? userALastReadAt;
  final DateTime? userBLastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String peerId(String currentUserId) =>
      currentUserId == userAId ? userBId : userAId;

  DateTime? myLastReadAt(String currentUserId) =>
      currentUserId == userAId ? userALastReadAt : userBLastReadAt;

  bool isParticipant(String userId) => userId == userAId || userId == userBId;

  factory ThreadModel.fromJson(Map<String, dynamic> json) => ThreadModel(
        id: json['id'] as String,
        userAId: (json['user_a_id'] ?? '') as String,
        userBId: (json['user_b_id'] ?? '') as String,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        lastMessageId: json['last_message_id'] as String?,
        userALastReadAt: json['user_a_last_read_at'] != null
            ? DateTime.parse(json['user_a_last_read_at'] as String)
            : null,
        userBLastReadAt: json['user_b_last_read_at'] != null
            ? DateTime.parse(json['user_b_last_read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.parse(json['created_at'] as String),
      );

  ThreadModel copyWith({
    DateTime? lastMessageAt,
    String? lastMessageId,
    DateTime? userALastReadAt,
    DateTime? userBLastReadAt,
  }) =>
      ThreadModel(
        id: id,
        userAId: userAId,
        userBId: userBId,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageId: lastMessageId ?? this.lastMessageId,
        userALastReadAt: userALastReadAt ?? this.userALastReadAt,
        userBLastReadAt: userBLastReadAt ?? this.userBLastReadAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
