import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging_socket_provider.dart';

class TypingNotifier extends FamilyAsyncNotifier<Set<String>, String> {
  final Map<String, Timer> _timers = {};

  @override
  Future<Set<String>> build(String threadId) async {
    final socket = ref.watch(messagingSocketProvider);

    final startSub = socket.typingStart$.listen((event) {
      if (event.threadId != threadId) return;
      _addUser(event.userId);
    });
    final stopSub = socket.typingStop$.listen((event) {
      if (event.threadId != threadId) return;
      _removeUser(event.userId);
    });
    ref.onDispose(() {
      startSub.cancel();
      stopSub.cancel();
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });

    return <String>{};
  }

  void _addUser(String userId) {
    final current = state.valueOrNull ?? <String>{};
    if (!current.contains(userId)) {
      state = AsyncData({...current, userId});
    }
    _timers[userId]?.cancel();
    _timers[userId] = Timer(const Duration(seconds: 3), () {
      _removeUser(userId);
    });
  }

  void _removeUser(String userId) {
    _timers.remove(userId)?.cancel();
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.contains(userId)) {
      state = AsyncData(current.difference({userId}));
    }
  }
}

final typingProvider =
    AsyncNotifierProvider.family<TypingNotifier, Set<String>, String>(
        TypingNotifier.new);
