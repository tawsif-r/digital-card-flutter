import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onLongPress,
  });

  final MessageModel message;
  final bool isMine;
  final VoidCallback? onLongPress;

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
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Text(
                  body,
                  style: tt.bodyMedium?.copyWith(
                    color: message.failed ? cs.onErrorContainer : fg,
                    fontStyle:
                        isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat.jm().format(message.createdAt.toLocal()),
                      style: tt.labelSmall?.copyWith(
                        color: (message.failed ? cs.onErrorContainer : fg)
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
                          size: 12, color: fg.withValues(alpha: 0.7)),
                    ],
                    if (message.failed) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.error_outline,
                          size: 12, color: cs.onErrorContainer),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
