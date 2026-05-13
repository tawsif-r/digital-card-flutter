import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/session_provider.dart';
import '../domain/message_model.dart';
import '../domain/thread_with_peer.dart';
import '../providers/messaging_socket_provider.dart';
import '../providers/thread_messages_provider.dart';
import '../providers/threads_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

const _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

class ThreadDetailScreen extends ConsumerStatefulWidget {
  const ThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  MessageModel? _replyTo;

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

  Future<void> _toggleReaction(MessageModel m, String emoji) async {
    final userId = ref.read(userSessionProvider);
    if (userId == null) return;
    final alreadyReacted =
        m.reactions.any((r) => r.emoji == emoji && r.hasReacted(userId));
    final notifier =
        ref.read(threadMessagesProvider(widget.threadId).notifier);
    if (alreadyReacted) {
      await notifier.removeReaction(m.id, emoji);
    } else {
      await notifier.addReaction(m.id, emoji);
    }
  }

  Future<void> _showMessageOptions(MessageModel m, bool isMine) async {
    final userId = ref.read(userSessionProvider);
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick-react row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickEmojis.map((emoji) {
                  final reacted = userId != null &&
                      m.reactions.any(
                        (r) => r.emoji == emoji && r.hasReacted(userId),
                      );
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, 'react:$emoji'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reacted
                            ? Theme.of(ctx).colorScheme.primaryContainer
                            : Colors.transparent,
                      ),
                      child:
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(ctx, 'reply'),
            ),
            if (isMine && !m.isDeleted)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            if (!m.isDeleted)
              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: const Text('Forward'),
                onTap: () => Navigator.pop(ctx, 'forward'),
              ),
            if (!m.isDeleted)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(ctx, 'copy'),
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || selection == null) return;

    if (selection.startsWith('react:')) {
      final emoji = selection.substring(6);
      await _toggleReaction(m, emoji);
    } else if (selection == 'reply') {
      setState(() => _replyTo = m);
    } else if (selection == 'edit') {
      await _showEditDialog(m);
    } else if (selection == 'forward') {
      await _showForwardPicker(m);
    } else if (selection == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.body ?? ''));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 1)),
        );
      }
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _showForwardPicker(MessageModel m) async {
    final threads =
        ref.read(threadsProvider).valueOrNull?.threads ?? const [];
    if (threads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other conversations to forward to.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ThreadWithPeer>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Forward to…',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: threads.length,
                itemBuilder: (_, i) {
                  final t = threads[i];
                  // Skip current thread
                  if (t.thread.id == widget.threadId) return const SizedBox.shrink();
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        t.peerName.isNotEmpty
                            ? t.peerName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(t.peerName),
                    onTap: () => Navigator.pop(ctx, t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    final err = await ref
        .read(threadMessagesProvider(selected.thread.id).notifier)
        .sendMessage(m.body ?? '');

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Message forwarded'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userSessionProvider);
    final asyncState = ref.watch(threadMessagesProvider(widget.threadId));
    final typing =
        ref.watch(typingProvider(widget.threadId)).valueOrNull ??
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
                  itemCount:
                      s.messages.length + (s.isLoadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= s.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child:
                            Center(child: CircularProgressIndicator()),
                      );
                    }
                    final m = s.messages[i];
                    final isMine =
                        userId != null && m.isMine(userId);
                    return MessageBubble(
                      message: m,
                      isMine: isMine,
                      currentUserId: userId,
                      onLongPress: () => _showMessageOptions(m, isMine),
                      onSecondaryTap: () => _showMessageOptions(m, isMine),
                      onReact: (emoji) => _toggleReaction(m, emoji),
                    );
                  },
                );
              },
            ),
          ),
          TypingIndicator(show: peerTyping),
          Composer(
            replyTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
            onSend: (body) async {
              final replyTarget = _replyTo;
              setState(() => _replyTo = null);
              final err = await ref
                  .read(threadMessagesProvider(widget.threadId).notifier)
                  .sendMessage(
                    body,
                    replyToId: replyTarget?.id,
                    replyToMessage: replyTarget,
                  );
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
