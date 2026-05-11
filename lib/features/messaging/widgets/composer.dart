import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSend,
    this.onTypingStart,
    this.onTypingStop,
    this.initialText,
    this.hintText = 'Type a message',
  });

  final Future<String?> Function(String body) onSend;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;
  final String? initialText;
  final String hintText;

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
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
    );
  }
}
