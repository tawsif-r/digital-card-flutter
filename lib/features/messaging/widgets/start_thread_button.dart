import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/threads_provider.dart';

class StartThreadButton extends ConsumerStatefulWidget {
  const StartThreadButton({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<StartThreadButton> createState() => _StartThreadButtonState();
}

class _StartThreadButtonState extends ConsumerState<StartThreadButton> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final (threadId, err) = await ref
          .read(threadsProvider.notifier)
          .createOrGetThread(contactId: widget.contactId);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      if (threadId == null) return;
      final isEmployee = ref.read(authProvider).user?.role == UserRole.employee;
      context.go(isEmployee
          ? Routes.employeeThreadDetailPath(threadId)
          : Routes.threadDetailPath(threadId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _start,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.chat_bubble_outline),
      label: Text(_busy ? 'Opening...' : 'Message'),
    );
  }
}
