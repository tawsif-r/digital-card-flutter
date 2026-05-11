import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_provider.dart';
import '../data/messaging_repository.dart';
import '../domain/message_model.dart';
import 'messaging_repository_provider.dart';
import 'messaging_socket_provider.dart';
import 'threads_provider.dart';

class MessagesState {
  const MessagesState({
    this.messages = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<MessageModel> messages;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  MessagesState copyWith({
    List<MessageModel>? messages,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      MessagesState(
        messages: messages ?? this.messages,
        nextCursor: nextCursor ?? this.nextCursor,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class ThreadMessagesNotifier
    extends FamilyAsyncNotifier<MessagesState, String> {
  static const _limit = 30;
  static const _nonceRandomMax = 0x3fffffff;
  final _rand = Random();

  String _newNonce() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _rand.nextInt(_nonceRandomMax).toRadixString(16);
    return '$timestamp-$randomPart';
  }

  @override
  Future<MessagesState> build(String threadId) async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return const MessagesState(hasMore: false);

    final socket = ref.watch(messagingSocketProvider);
    socket.joinThread(threadId);
    ref.onDispose(() => socket.leaveThread(threadId));

    final newSub = socket.messageNew$.listen((msg) {
      if (msg.threadId != threadId) return;
      final current = state.valueOrNull;
      if (current == null) return;
      final pendingIdx = current.messages.indexWhere(
        (m) =>
            m.id == msg.id ||
            (m.pending &&
                m.clientNonce != null &&
                msg.clientNonce != null &&
                m.clientNonce == msg.clientNonce),
      );
      if (pendingIdx >= 0) {
        final reconciled = [...current.messages];
        reconciled[pendingIdx] = msg.copyWith(pending: false);
        state = AsyncData(current.copyWith(messages: reconciled));
      } else {
        state = AsyncData(current.copyWith(
          messages: [msg, ...current.messages],
        ));
      }
    });
    ref.onDispose(newSub.cancel);

    final updSub = socket.messageUpdated$.listen((msg) {
      if (msg.threadId != threadId) return;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(current.copyWith(
        messages:
            current.messages.map((m) => m.id == msg.id ? msg : m).toList(),
      ));
    });
    ref.onDispose(updSub.cancel);

    final delSub = socket.messageDeleted$.listen((event) {
      if (event.threadId != threadId) return;
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(current.copyWith(
        messages: current.messages
            .map((m) => m.id == event.id
                ? m.copyWith(body: null, deletedAt: DateTime.now())
                : m)
            .toList(),
      ));
    });
    ref.onDispose(delSub.cancel);

    return _loadInitial(threadId);
  }

  Future<MessagesState> _loadInitial(String threadId) async {
    final page = await ref
        .read(messagingRepositoryProvider)
        .getMessages(threadId, limit: _limit);
    return MessagesState(
      messages: page.data,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref.read(messagingRepositoryProvider).getMessages(
            arg,
            cursor: current.nextCursor,
            limit: _limit,
          );
      state = AsyncData(current.copyWith(
        messages: [...current.messages, ...page.data],
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  List<MessageModel> _reconcileSentMessage({
    required List<MessageModel> messages,
    required String nonce,
    required MessageModel saved,
  }) {
    final list = [...messages];
    final pendingIdx = list.indexWhere((m) => m.clientNonce == nonce);
    final savedIdx = list.indexWhere((m) => m.id == saved.id);
    final normalized = saved.copyWith(pending: false, failed: false);

    if (pendingIdx >= 0 && savedIdx >= 0 && pendingIdx != savedIdx) {
      final keepIdx = pendingIdx < savedIdx ? pendingIdx : savedIdx;
      final removeIdx = pendingIdx < savedIdx ? savedIdx : pendingIdx;
      list[keepIdx] = normalized;
      list.removeAt(removeIdx);
      return list;
    }

    final targetIdx = pendingIdx >= 0 ? pendingIdx : savedIdx;
    if (targetIdx >= 0) {
      list[targetIdx] = normalized;
      return list;
    }

    return [normalized, ...list];
  }

  Future<String?> sendMessage(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Message cannot be empty.';

    final userId = ref.read(userSessionProvider);
    if (userId == null) return 'Not authenticated.';

    final nonce = _newNonce();
    final now = DateTime.now();
    final optimistic = MessageModel(
      id: 'pending-$nonce',
      threadId: arg,
      senderId: userId,
      body: trimmed,
      createdAt: now,
      updatedAt: now,
      clientNonce: nonce,
      pending: true,
    );

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(
        messages: [optimistic, ...current.messages],
      ));
    }

    try {
      final saved = await ref
          .read(messagingRepositoryProvider)
          .sendMessage(arg, trimmed, clientNonce: nonce);
      final next = state.valueOrNull;
      if (next != null) {
        final reconciled = _reconcileSentMessage(
          messages: next.messages,
          nonce: nonce,
          saved: saved,
        );
        state = AsyncData(next.copyWith(messages: reconciled));
      }
      return null;
    } catch (e) {
      final next = state.valueOrNull;
      if (next != null) {
        state = AsyncData(next.copyWith(
          messages: next.messages
              .map((m) => m.clientNonce == nonce
                  ? m.copyWith(pending: false, failed: true)
                  : m)
              .toList(),
        ));
      }
      return extractMessagingError(e);
    }
  }

  Future<String?> editMessage(String messageId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Message cannot be empty.';
    try {
      final updated = await ref
          .read(messagingRepositoryProvider)
          .editMessage(messageId, trimmed);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          messages: current.messages
              .map((m) => m.id == messageId ? updated : m)
              .toList(),
        ));
      }
      return null;
    } catch (e) {
      return extractMessagingError(e);
    }
  }

  Future<String?> deleteMessage(String messageId) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    try {
      await ref.read(messagingRepositoryProvider).deleteMessage(messageId);
      state = AsyncData(current.copyWith(
        messages: current.messages
            .map((m) => m.id == messageId
                ? m.copyWith(body: null, deletedAt: DateTime.now())
                : m)
            .toList(),
      ));
      return null;
    } catch (e) {
      return extractMessagingError(e);
    }
  }

  Future<void> markRead() async {
    try {
      final lastReadAt = await ref
          .read(messagingRepositoryProvider)
          .markRead(arg, lastReadAt: DateTime.now());
      ref.read(messagingSocketProvider).emitRead(arg, lastReadAt);
      ref.read(threadsProvider.notifier).markThreadRead(arg);
    } catch (_) {
      // Non-critical.
    }
  }
}

final threadMessagesProvider =
    AsyncNotifierProvider.family<ThreadMessagesNotifier, MessagesState, String>(
  ThreadMessagesNotifier.new,
);
