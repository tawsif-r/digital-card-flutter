import 'dart:async';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/message_model.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSend,
    this.onTypingStart,
    this.onTypingStop,
    this.initialText,
    this.hintText = 'Type a message',
    this.replyTo,
    this.onCancelReply,
  });

  final Future<String?> Function(String body) onSend;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;
  final String? initialText;
  final String hintText;
  final MessageModel? replyTo;
  final VoidCallback? onCancelReply;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText ?? '');
  final _focus = FocusNode();
  Timer? _typingStopTimer;
  bool _isTyping = false;
  bool _sending = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _typingStopTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    final empty = value.trim().isEmpty;
    if (!empty && !_isTyping) {
      _isTyping = true;
      widget.onTypingStart?.call();
    }
    _typingStopTimer?.cancel();
    if (empty) {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingStop?.call();
      }
    } else {
      _typingStopTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping) {
          _isTyping = false;
          widget.onTypingStop?.call();
        }
      });
    }
    setState(() {});
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focus.requestFocus();
      setState(() => _showEmojiPicker = false);
    } else {
      _focus.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final err = await widget.onSend(text);
      if (err == null) {
        _controller.clear();
        _typingStopTimer?.cancel();
        if (_isTyping) {
          _isTyping = false;
          widget.onTypingStop?.call();
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = hasText && !_sending;
    final sendButtonBg =
        (_sending || hasText) ? AppColors.primary : cs.surfaceContainerHighest;
    final sendButtonFg =
        (_sending || hasText) ? Colors.white : cs.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview bar
          if (widget.replyTo != null)
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant),
                  left: const BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to message',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          widget.replyTo!.body != null
                              ? (widget.replyTo!.body!.length > 60
                                  ? '${widget.replyTo!.body!.substring(0, 60)}…'
                                  : widget.replyTo!.body!)
                              : '[deleted]',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onCancelReply,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: _toggleEmojiPicker,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _submit(),
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: canSend ? _submit : null,
                  style: IconButton.styleFrom(
                    backgroundColor: sendButtonBg,
                    foregroundColor: sendButtonFg,
                    disabledBackgroundColor: sendButtonBg,
                    disabledForegroundColor: sendButtonFg,
                    fixedSize: const Size(42, 42),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _controller,
                onEmojiSelected: (_, __) => setState(() {}),
                config: Config(
                  height: 250,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
