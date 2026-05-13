class ReactionModel {
  const ReactionModel({
    required this.emoji,
    required this.count,
    required this.userIds,
  });

  final String emoji;
  final int count;
  final List<String> userIds;

  bool hasReacted(String userId) => userIds.contains(userId);

  factory ReactionModel.fromJson(Map<String, dynamic> json) => ReactionModel(
        emoji: json['emoji'] as String,
        count: (json['count'] as num).toInt(),
        userIds: (json['user_ids'] as List<dynamic>).cast<String>(),
      );
}
