import 'thread_model.dart';
import 'message_model.dart';

class ThreadWithPeer {
  const ThreadWithPeer({
    required this.thread,
    required this.peerId,
    required this.peerName,
    this.peerEmail,
    this.peerAvatarUrl,
    this.unreadCount = 0,
    this.lastMessage,
  });

  final ThreadModel thread;
  final String peerId;
  final String peerName;
  final String? peerEmail;
  final String? peerAvatarUrl;
  final int unreadCount;
  final MessageModel? lastMessage;

  static int _parseUnreadCount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  factory ThreadWithPeer.fromJson(Map<String, dynamic> json) {
    final thread = ThreadModel.fromJson(
      (json['thread'] ?? json) as Map<String, dynamic>,
    );
    // API may return peer as 'peer', 'other_user', or flat peer_id/peer_name
    final peer = (json['peer'] ?? json['other_user']) as Map<String, dynamic>?;
    return ThreadWithPeer(
      thread: thread,
      peerId: (peer?['id'] ?? json['peer_id'] ?? '') as String,
      peerName: (peer?['name'] ??
          peer?['full_name'] ??
          json['peer_name'] ??
          'Unknown') as String,
      peerEmail: (peer?['email'] ?? json['peer_email']) as String?,
      peerAvatarUrl:
          (peer?['avatar_url'] ?? json['peer_avatar_url']) as String?,
      unreadCount: _parseUnreadCount(json['unread_count']),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
    );
  }

  ThreadWithPeer copyWith({
    ThreadModel? thread,
    int? unreadCount,
    MessageModel? lastMessage,
  }) =>
      ThreadWithPeer(
        thread: thread ?? this.thread,
        peerId: peerId,
        peerName: peerName,
        peerEmail: peerEmail,
        peerAvatarUrl: peerAvatarUrl,
        unreadCount: unreadCount ?? this.unreadCount,
        lastMessage: lastMessage ?? this.lastMessage,
      );
}
