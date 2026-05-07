import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/user_model.dart';
import '../providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  UserRole _role = UserRole.employer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider).register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
          _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.watch(authProvider);
    final isLoading = authNotifier.state is AuthLoading;
    final error = authNotifier.state is AuthError
        ? (authNotifier.state as AuthError).message
        : null;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<AuthNotifier>(authProvider, (_, notifier) {
      if (notifier.state is AuthAuthenticated) {
        final user = notifier.user!;
        context.go(user.role == UserRole.employee ? Routes.issuedCards : Routes.home);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: () => ref.read(themeProvider.notifier).toggle(),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthLogo(),
                        const SizedBox(height: 40),
                        Text('Create an account', style: tt.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Set up your Digital Card profile',
                          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        Text('I am a…', style: tt.labelLarge),
                        const SizedBox(height: 8),
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.employer,
                              label: Text('Employer / HR'),
                              icon: Icon(Icons.business_outlined),
                            ),
                            ButtonSegment(
                              value: UserRole.employee,
                              label: Text('Employee'),
                              icon: Icon(Icons.badge_outlined),
                            ),
                          ],
                          selected: {_role},
                          onSelectionChanged: (s) => setState(() => _role = s.first),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Full Name (optional)',
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.person_outlined),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Password',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          validator: Validators.password,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          AuthErrorBanner(message: error),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Create Account'),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account?', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              TextButton(
                                onPressed: () => context.pop(),
                                child: const Text('Sign in'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
