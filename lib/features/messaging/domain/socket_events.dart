enum SocketStatus { disconnected, connecting, connected, authError }

class MessageDeletedEvent {
  const MessageDeletedEvent({required this.id, required this.threadId});
  final String id;
  final String threadId;

  factory MessageDeletedEvent.fromJson(Map<String, dynamic> json) =>
      MessageDeletedEvent(
        id: json['id'] as String,
        threadId: json['thread_id'] as String,
      );
}

class ReadEvent {
  const ReadEvent({
    required this.threadId,
    required this.userId,
    required this.lastReadAt,
  });
  final String threadId;
  final String userId;
  final DateTime lastReadAt;

  factory ReadEvent.fromJson(Map<String, dynamic> json) => ReadEvent(
        threadId: json['threadId'] as String,
        userId: json['userId'] as String,
        lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      );
}

class TypingEvent {
  const TypingEvent({required this.threadId, required this.userId});
  final String threadId;
  final String userId;

  factory TypingEvent.fromJson(Map<String, dynamic> json) => TypingEvent(
        threadId: json['threadId'] as String,
        userId: json['userId'] as String,
      );
}

class ThreadBumpEvent {
  const ThreadBumpEvent({
    required this.threadId,
    required this.lastMessageAt,
    required this.unreadCount,
  });
  final String threadId;
  final DateTime lastMessageAt;
  final int unreadCount;

  factory ThreadBumpEvent.fromJson(Map<String, dynamic> json) =>
      ThreadBumpEvent(
        threadId: json['threadId'] as String,
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        unreadCount: (json['unread_count'] as int?) ?? 0,
      );
}
