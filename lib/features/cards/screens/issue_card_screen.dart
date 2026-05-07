import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/card_data.dart';
import '../providers/cards_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/utils/validators.dart';

class IssueCardScreen extends ConsumerStatefulWidget {
  const IssueCardScreen({super.key, this.template});

  final CardData? template;

  @override
  ConsumerState<IssueCardScreen> createState() => _IssueCardScreenState();
}

class _IssueCardScreenState extends ConsumerState<IssueCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientEmailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  CardTemplate _template = CardTemplate.minimal;
  String _accentColor = '#1A73E8';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _titleCtrl.text = t.title ?? '';
      _companyCtrl.text = t.company ?? '';
      _websiteCtrl.text = t.website ?? '';
      _template = t.template;
      _accentColor = t.accentColor;
    }
  }

  @override
  void dispose() {
    _recipientEmailCtrl.dispose();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = CardData(
      name: _nameCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
      template: _template,
      accentColor: _accentColor,
    );
    final (_, err) = await ref.read(cardsProvider.notifier).issueCard(
          _recipientEmailCtrl.text.trim(),
          data,
        );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card issued — employee will receive an email.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasTemplate = widget.template != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Card')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTemplate) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: cs.onPrimaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            'Template pre-filled — just add employee details',
                            style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('Recipient', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'Employee Email',
                    controller: _recipientEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 24),
                  Text('Employee Details', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  AppTextField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: hasTemplate ? 'Job Title' : 'Job Title (optional)',
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: hasTemplate ? 'Company' : 'Company (optional)',
                    controller: _companyCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.business_outlined),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Phone (optional)',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Work Email (optional)',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Website (optional)',
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.link),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Template', style: tt.titleMedium),
                      if (hasTemplate) ...[
                        const SizedBox(width: 8),
                        Text('(from template)', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: CardTemplate.values.map((t) {
                      return ChoiceChip(
                        label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                        selected: _template == t,
                        onSelected: (_) => setState(() => _template = t),
                      );
                    }).toList(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: cs.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: cs.onErrorContainer))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_outlined),
                      label: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Issue Card'),
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
