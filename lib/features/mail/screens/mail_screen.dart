import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/mail_provider.dart';

class MailScreen extends ConsumerStatefulWidget {
  const MailScreen({super.key});

  @override
  ConsumerState<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends ConsumerState<MailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _subjectController = TextEditingController();
  final _textBodyController = TextEditingController();
  final _htmlBodyController = TextEditingController();
  final _recipientFocus = FocusNode();

  final List<String> _recipients = [];
  bool _sending = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _textBodyController.dispose();
    _htmlBodyController.dispose();
    _recipientFocus.dispose();
    super.dispose();
  }

  void _addRecipient() {
    final raw = _recipientController.text.trim().replaceAll(',', '').replaceAll(';', '');
    if (raw.isEmpty) return;
    if (!raw.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid email'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_recipients.contains(raw)) {
      _recipientController.clear();
      return;
    }
    setState(() => _recipients.add(raw));
    _recipientController.clear();
    _recipientFocus.requestFocus();
  }

  void _removeRecipient(String email) => setState(() => _recipients.remove(email));

  Future<void> _send() async {
    _addRecipient(); // commit any typed-but-not-added recipient
    if (_recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one recipient'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      await ref.read(mailProvider.notifier).send(
            to: List.from(_recipients),
            subject: _subjectController.text.trim(),
            textBody: _textBodyController.text.trim().isEmpty ? null : _textBodyController.text.trim(),
            htmlBody: _htmlBodyController.text.trim().isEmpty ? null : _htmlBodyController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _recipients.clear());
      _subjectController.clear();
      _textBodyController.clear();
      _htmlBodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('New Message', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: cs.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('To *', tt, cs),
                      const SizedBox(height: 6),
                      _RecipientsField(
                        recipients: _recipients,
                        controller: _recipientController,
                        focusNode: _recipientFocus,
                        onAdd: _addRecipient,
                        onRemove: _removeRecipient,
                        cs: cs,
                        tt: tt,
                      ),
                      const SizedBox(height: 16),
                      _label('Subject *', tt, cs),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _subjectController,
                        decoration: _dec(cs, hint: 'e.g. Hello from digital card'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Text Body', tt, cs),
                      const SizedBox(height: 4),
                      Text('Plain text fallback', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _textBodyController,
                        minLines: 5,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        decoration: _dec(cs, hint: 'Plain text content'),
                      ),
                      const SizedBox(height: 16),
                      _label('HTML Body', tt, cs),
                      const SizedBox(height: 4),
                      Text('Overrides text body in HTML-capable clients', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _htmlBodyController,
                        minLines: 5,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        decoration: _dec(cs, hint: '<p>HTML content</p>'),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(_sending ? 'Sending...' : 'Send'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, TextTheme tt, ColorScheme cs) => Text(
        text,
        style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
      );

  InputDecoration _dec(ColorScheme cs, {required String hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error, width: 1.5)),
      );
}

class _RecipientsField extends StatelessWidget {
  const _RecipientsField({
    required this.recipients,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
    required this.cs,
    required this.tt,
  });

  final List<String> recipients;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipients.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recipients
                  .map((e) => Chip(
                        label: Text(e, style: tt.labelSmall),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => onRemove(e),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        labelStyle: TextStyle(color: AppColors.primary),
                        deleteIconColor: AppColors.primary,
                      ))
                  .toList(),
            ),
          if (recipients.isNotEmpty) const SizedBox(height: 6),
          KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) {
              if (e is KeyDownEvent) {
                if (e.logicalKey == LogicalKeyboardKey.enter ||
                    e.logicalKey == LogicalKeyboardKey.comma) {
                  onAdd();
                }
              }
            },
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              decoration: InputDecoration(
                hintText: recipients.isEmpty ? 'user@example.com, another@example.com' : 'Add another...',
                hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixIcon: controller.text.isNotEmpty
                    ? null
                    : null,
              ),
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Press Enter or comma to add each recipient',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
