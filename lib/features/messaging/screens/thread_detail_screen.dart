import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_provider.dart';
import '../domain/message_model.dart';
import '../providers/messaging_socket_provider.dart';
import '../providers/thread_messages_provider.dart';
import '../providers/threads_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ThreadDetailScreen extends ConsumerStatefulWidget {
  const ThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(threadMessagesProvider(widget.threadId).notifier).markRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(threadMessagesProvider(widget.threadId).notifier).markRead();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(threadMessagesProvider(widget.threadId).notifier).loadMore();
    }
  }

  Future<void> _showMessageActions(MessageModel m) async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selection == 'edit') {
      await _showEditDialog(m);
    } else if (selection == 'delete') {
      final err = await ref
          .read(threadMessagesProvider(widget.threadId).notifier)
          .deleteMessage(m.id);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _showEditDialog(MessageModel m) async {
    final controller = TextEditingController(text: m.body ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final err = await ref
        .read(threadMessagesProvider(widget.threadId).notifier)
        .editMessage(m.id, result);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userSessionProvider);
    final asyncState = ref.watch(threadMessagesProvider(widget.threadId));
    final typing = ref.watch(typingProvider(widget.threadId)).valueOrNull ??
        const <String>{};

    final peerTyping = typing.any((id) => id != userId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: _PeerHeader(threadId: widget.threadId),
      ),
      body: Column(
        children: [
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 8),
                    Text('Could not load messages: $e'),
                  ],
                ),
              ),
              data: (s) {
                if (s.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: s.messages.length + (s.isLoadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= s.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final m = s.messages[i];
                    final isMine = userId != null && m.isMine(userId);
                    return MessageBubble(
                      message: m,
                      isMine: isMine,
                      onLongPress: isMine && !m.isDeleted
                          ? () => _showMessageActions(m)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          TypingIndicator(show: peerTyping),
          Composer(
            onSend: (body) async {
              final err = await ref
                  .read(threadMessagesProvider(widget.threadId).notifier)
                  .sendMessage(body);
              if (!context.mounted) return err;
              if (err != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
              }
              return err;
            },
            onTypingStart: () => ref
                .read(messagingSocketProvider)
                .sendTypingStart(widget.threadId),
            onTypingStop: () => ref
                .read(messagingSocketProvider)
                .sendTypingStop(widget.threadId),
          ),
        ],
      ),
    );
  }
}

class _PeerHeader extends ConsumerWidget {
  const _PeerHeader({required this.threadId});
  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final entry = ref.watch(threadsProvider.select((s) {
      final list = s.valueOrNull?.threads ?? const [];
      for (final t in list) {
        if (t.thread.id == threadId) return t;
      }
      return null;
    }));

    if (entry == null) {
      return Text(
        'Chat',
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: entry.peerAvatarUrl != null
              ? NetworkImage(entry.peerAvatarUrl!)
              : null,
          child: entry.peerAvatarUrl == null
              ? Text(entry.peerName.isNotEmpty
                  ? entry.peerName[0].toUpperCase()
                  : '?')
              : null,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            entry.peerName,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
