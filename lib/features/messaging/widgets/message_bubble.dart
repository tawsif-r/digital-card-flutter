import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/message_model.dart';
import '../domain/reaction_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.currentUserId,
    this.onLongPress,
    this.onSecondaryTap,
    this.onReact,
  });

  final MessageModel message;
  final bool isMine;
  final String? currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final void Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bg = isMine ? AppColors.primary : cs.surfaceContainerHighest;
    final fg = isMine ? Colors.white : cs.onSurface;

    final body = message.isDeleted ? '[message deleted]' : (message.body ?? '');
    final isPlaceholder = message.isDeleted || (message.body?.isEmpty ?? true);

    return GestureDetector(
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: message.failed ? cs.errorContainer : bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMine ? 14 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quoted reply block
                    if (message.replyToId != null)
                      _QuotedReply(
                        body: message.replyToBody,
                        senderId: message.replyToSenderId,
                        isMine: isMine,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            body,
                            style: tt.bodyMedium?.copyWith(
                              color: message.failed
                                  ? cs.onErrorContainer
                                  : fg,
                              fontStyle: isPlaceholder
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat.jm()
                                    .format(message.createdAt.toLocal()),
                                style: tt.labelSmall?.copyWith(
                                  color: (message.failed
                                          ? cs.onErrorContainer
                                          : fg)
                                      .withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                              if (message.isEdited && !message.isDeleted) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(edited)',
                                  style: tt.labelSmall?.copyWith(
                                    color: fg.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                              if (message.pending) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.schedule,
                                    size: 12,
                                    color: fg.withValues(alpha: 0.7)),
                              ],
                              if (message.failed) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.error_outline,
                                    size: 12,
                                    color: cs.onErrorContainer),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: isMine ? 0 : 16,
                  right: isMine ? 16 : 0,
                  bottom: 2,
                ),
                child: Wrap(
                  spacing: 4,
                  children: message.reactions
                      .map((r) => _ReactionChip(
                            reaction: r,
                            reacted: currentUserId != null &&
                                r.hasReacted(currentUserId!),
                            onTap: onReact != null
                                ? () => onReact!(r.emoji)
                                : null,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuotedReply extends StatelessWidget {
  const _QuotedReply({
    required this.body,
    required this.senderId,
    required this.isMine,
  });

  final String? body;
  final String? senderId;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accentColor =
        isMine ? Colors.white.withValues(alpha: 0.6) : AppColors.primary;
    final bgColor = isMine
        ? Colors.black.withValues(alpha: 0.15)
        : cs.surfaceContainerLow;
    final fgColor =
        isMine ? Colors.white.withValues(alpha: 0.9) : cs.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (senderId != null)
            Text(
              senderId!.substring(0, 8), // short ID — replace with name if available
              style: tt.labelSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          Text(
            body != null ? (body!.length > 80 ? '${body!.substring(0, 80)}…' : body!) : '[deleted]',
            style: tt.bodySmall?.copyWith(
              color: fgColor,
              fontStyle: body == null ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.reacted,
    this.onTap,
  });

  final ReactionModel reaction;
  final bool reacted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: reacted
              ? AppColors.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reacted
                ? AppColors.primary.withValues(alpha: 0.6)
                : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          '${reaction.emoji} ${reaction.count}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
