import 'reaction_model.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.createdAt,
    required this.updatedAt,
    this.body,
    this.editedAt,
    this.deletedAt,
    this.clientNonce,
    this.pending = false,
    this.failed = false,
    this.reactions = const [],
    this.replyToId,
    this.replyToBody,
    this.replyToSenderId,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String? body;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReactionModel> reactions;
  final String? replyToId;
  final String? replyToBody;
  final String? replyToSenderId;

  final String? clientNonce;
  final bool pending;
  final bool failed;

  bool get isDeleted => deletedAt != null;
  bool get isEdited => editedAt != null;
  bool isMine(String currentUserId) => senderId == currentUserId;

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        threadId: (json['thread_id'] ?? '') as String,
        senderId: (json['sender_id'] ?? '') as String,
        body: json['body'] as String?,
        editedAt: json['edited_at'] != null
            ? DateTime.parse(json['edited_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.parse(json['created_at'] as String),
        reactions: (json['reactions'] as List<dynamic>? ?? [])
            .map((r) => ReactionModel.fromJson(r as Map<String, dynamic>))
            .toList(),
        replyToId: json['reply_to_id'] as String?,
        replyToBody: json['reply_to_body'] as String?,
        replyToSenderId: json['reply_to_sender_id'] as String?,
      );

  MessageModel copyWith({
    String? body,
    DateTime? editedAt,
    DateTime? deletedAt,
    String? clientNonce,
    bool? pending,
    bool? failed,
    List<ReactionModel>? reactions,
    String? replyToId,
    String? replyToBody,
    String? replyToSenderId,
  }) =>
      MessageModel(
        id: id,
        threadId: threadId,
        senderId: senderId,
        body: body ?? this.body,
        editedAt: editedAt ?? this.editedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        clientNonce: clientNonce ?? this.clientNonce,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        reactions: reactions ?? this.reactions,
        replyToId: replyToId ?? this.replyToId,
        replyToBody: replyToBody ?? this.replyToBody,
        replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      );
}
