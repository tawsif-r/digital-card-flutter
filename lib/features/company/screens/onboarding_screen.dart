import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_provider.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/utils/validators.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref.read(companyProvider.notifier).onboard(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          size: int.parse(_sizeCtrl.text.trim()),
        );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = 'Failed to save company. Please try again.';
      });
    } else {
      context.go(Routes.company);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Your Company'), automaticallyImplyLeading: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome!', style: tt.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Tell us about your company before issuing cards.',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Company Name',
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.business_outlined),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'What does your company do?',
                    controller: _descCtrl,
                    textInputAction: TextInputAction.next,
                    maxLines: 3,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Headcount',
                    controller: _sizeCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.people_outline),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Enter a valid number';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
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
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save & Continue'),
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
