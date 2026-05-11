import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_provider.dart';
import '../data/messaging_repository.dart';
import '../domain/thread_with_peer.dart';
import 'messaging_repository_provider.dart';
import 'messaging_socket_provider.dart';

class ThreadsState {
  const ThreadsState({
    this.threads = const [],
    this.total = 0,
    this.page = 1,
    this.isLoadingMore = false,
  });

  final List<ThreadWithPeer> threads;
  final int total;
  final int page;
  final bool isLoadingMore;

  bool get hasMore => threads.length < total;
  int get totalUnread => threads.fold(0, (sum, t) => sum + t.unreadCount);

  ThreadsState copyWith({
    List<ThreadWithPeer>? threads,
    int? total,
    int? page,
    bool? isLoadingMore,
  }) =>
      ThreadsState(
        threads: threads ?? this.threads,
        total: total ?? this.total,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

class ThreadsNotifier extends AsyncNotifier<ThreadsState> {
  static const _limit = 20;
  static const _syncInterval = Duration(seconds: 8);

  Future<List<ThreadWithPeer>> _withUnreadCounts(
    List<ThreadWithPeer> threads,
  ) async {
    final repo = ref.read(messagingRepositoryProvider);
    return Future.wait(
      threads.map((thread) async {
        try {
          final unread = await repo.getUnreadCount(thread.thread.id);
          return thread.copyWith(unreadCount: unread);
        } catch (_) {
          return thread;
        }
      }),
    );
  }

  Future<void> _syncUnreadCounts() async {
    final current = state.valueOrNull;
    if (current == null || current.threads.isEmpty) return;
    final threads = await _withUnreadCounts(current.threads);
    state = AsyncData(current.copyWith(threads: threads));
  }

  @override
  Future<ThreadsState> build() async {
    final userId = ref.watch(userSessionProvider);
    if (userId == null) return const ThreadsState();

    final socket = ref.watch(messagingSocketProvider);
    final sub = socket.threadBumped$.listen((event) {
      final current = state.valueOrNull;
      if (current == null) return;
      final idx = current.threads.indexWhere(
        (t) => t.thread.id == event.threadId,
      );
      if (idx < 0) {
        refresh();
        return;
      }
      final updated = current.threads[idx].copyWith(
        thread: current.threads[idx].thread.copyWith(
          lastMessageAt: event.lastMessageAt,
        ),
        unreadCount: event.unreadCount,
      );
      final reordered = [
        updated,
        ...current.threads.where((t) => t.thread.id != event.threadId),
      ];
      state = AsyncData(current.copyWith(threads: reordered));
    });
    ref.onDispose(sub.cancel);

    final periodicSync = Timer.periodic(_syncInterval, (_) {
      _syncUnreadCounts();
    });
    ref.onDispose(periodicSync.cancel);

    return _fetchPage(1);
  }

  Future<ThreadsState> _fetchPage(int page) async {
    final result = await ref.read(messagingRepositoryProvider).listThreads(
          page: page,
          limit: _limit,
        );
    final threads = await _withUnreadCounts(result.data);
    return ThreadsState(
      threads: threads,
      total: result.total,
      page: result.page,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = current.page + 1;
      final result = await ref.read(messagingRepositoryProvider).listThreads(
            page: next,
            limit: _limit,
          );
      final nextThreads = await _withUnreadCounts(result.data);
      state = AsyncData(current.copyWith(
        threads: [...current.threads, ...nextThreads],
        total: result.total,
        page: result.page,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  void markThreadRead(String threadId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      threads: current.threads
          .map((t) => t.thread.id == threadId ? t.copyWith(unreadCount: 0) : t)
          .toList(),
    ));
  }

  Future<(String?, String?)> createOrGetThread({
    String? contactId,
    String? userId,
  }) async {
    try {
      final thread = await ref
          .read(messagingRepositoryProvider)
          .createOrGetThread(contactId: contactId, userId: userId);
      await refresh();
      return (thread.id, null);
    } catch (e) {
      return (null, extractMessagingError(e));
    }
  }
}

final threadsProvider =
    AsyncNotifierProvider<ThreadsNotifier, ThreadsState>(ThreadsNotifier.new);

final unreadTotalProvider = Provider<int>((ref) {
  return ref.watch(
    threadsProvider.select((s) => s.valueOrNull?.totalUnread ?? 0),
  );
});
