import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/validators.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/domain/user_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final role = ref.watch(authProvider).user?.role;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const _SettingsShimmer(),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (state) => _SettingsBody(
          profile: state.profile,
          settings: state.settings,
          role: role,
        ),
      ),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({
    required this.profile,
    required this.settings,
    this.role,
  });

  final UserProfile profile;
  final UserSettings settings;
  final UserRole? role;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _email;

  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  late bool _showOnlineStatus;
  late bool _allowAudioCalls;
  late bool _allowVideoCalls;

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _savingSettings = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.profile.fullName ?? '');
    _email = TextEditingController(text: widget.profile.email);
    _showOnlineStatus = widget.settings.showOnlineStatus;
    _allowAudioCalls = widget.settings.allowAudioCalls;
    _allowVideoCalls = widget.settings.allowVideoCalls;
  }

  @override
  void didUpdateWidget(_SettingsBody old) {
    super.didUpdateWidget(old);
    if (old.profile.fullName != widget.profile.fullName) {
      _fullName.text = widget.profile.fullName ?? '';
    }
    if (old.profile.email != widget.profile.email) {
      _email.text = widget.profile.email;
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  UserProfile _liveProfile() => UserProfile(
        id: widget.profile.id,
        email: _email.text.trim().isNotEmpty ? _email.text.trim() : widget.profile.email,
        fullName: _fullName.text.trim().isNotEmpty ? _fullName.text.trim() : widget.profile.fullName,
        phone: widget.profile.phone,
        designation: widget.profile.designation,
        department: widget.profile.department,
        company: widget.profile.company,
      );

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([_fullName, _email]),
              builder: (_, __) => _ProfileCard(profile: _liveProfile(), role: widget.role),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.person_outline,
                    title: 'Profile Information',
                    subtitle: 'Update your name and email.',
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Full Name',
                    controller: _fullName,
                    hint: 'Tawsif Hasan',
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 12),
                  _ProfileField(
                    label: 'Email',
                    controller: _email,
                    hint: 'new@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingProfile ? null : () => _saveProfile(ref),
                      child: _savingProfile
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Enter your current password to set a new one.',
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    label: 'Current Password',
                    controller: _currentPassword,
                    hint: '••••••••',
                    obscure: !_showCurrentPw,
                    onToggle: () => setState(() => _showCurrentPw = !_showCurrentPw),
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    label: 'New Password',
                    controller: _newPassword,
                    hint: '••••••••',
                    obscure: !_showNewPw,
                    onToggle: () => setState(() => _showNewPw = !_showNewPw),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    label: 'Confirm New Password',
                    controller: _confirmPassword,
                    hint: '••••••••',
                    obscure: !_showConfirmPw,
                    onToggle: () => setState(() => _showConfirmPw = !_showConfirmPw),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _newPassword.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingPassword ? null : () => _savePassword(ref),
                      child: _savingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            _SectionLabel(
              icon: Icons.shield_outlined,
              title: 'Privacy & Communication',
              subtitle: 'Control who can contact you and see your status.',
            ),
            const SizedBox(height: 16),
            _ToggleTile(
              title: 'Show online status',
              subtitle: "Let your connections see when you're active.",
              value: _showOnlineStatus,
              onChanged: (v) => setState(() => _showOnlineStatus = v),
            ),
            _ToggleTile(
              title: 'Allow audio calls',
              subtitle: 'Connections can call you via audio.',
              value: _allowAudioCalls,
              onChanged: (v) => setState(() => _allowAudioCalls = v),
            ),
            _ToggleTile(
              title: 'Allow video calls',
              subtitle: 'Connections can call you via video.',
              value: _allowVideoCalls,
              onChanged: (v) => setState(() => _allowVideoCalls = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingSettings ? null : () => _saveSettings(ref),
                child: _savingSettings
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Privacy Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    final newEmail = _email.text.trim();
    final newName = _fullName.text.trim();
    final anyChanged = newEmail != widget.profile.email ||
        newName != (widget.profile.fullName ?? '');

    if (!anyChanged) return;

    final currentPassword = await _showPasswordDialog();
    if (currentPassword == null) return; // user cancelled

    setState(() => _savingProfile = true);

    final updated = widget.profile.copyWith(
      email: newEmail,
      fullName: newName,
    );

    final (ok, err) = await ref
        .read(settingsProvider.notifier)
        .updateProfile(updated, currentPassword: currentPassword);

    if (!mounted) return;
    setState(() => _savingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile saved.' : (err ?? 'Failed to save profile.')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    var obscure = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Confirm your password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your current password to save profile changes.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setStateDialog(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pw = controller.text.trim();
                if (pw.isEmpty) return;
                Navigator.of(ctx).pop(pw);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _savePassword(WidgetRef ref) async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);

    final (ok, err) = await ref.read(settingsProvider.notifier).updatePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );

    if (!mounted) return;
    setState(() => _savingPassword = false);

    if (ok) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Password updated.' : (err ?? 'Failed to update password.')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings(WidgetRef ref) async {
    setState(() => _savingSettings = true);

    final updated = UserSettings(
      showOnlineStatus: _showOnlineStatus,
      allowAudioCalls: _allowAudioCalls,
      allowVideoCalls: _allowVideoCalls,
    );

    final (ok, err) = await ref.read(settingsProvider.notifier).updateSettings(updated);

    if (!mounted) return;
    setState(() => _savingSettings = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Privacy settings saved.' : (err ?? 'Failed to save settings.')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, this.role});

  final UserProfile profile;
  final UserRole? role;

  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.isNotEmpty ? s[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final display = profile.fullName ?? profile.email;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(display),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.fullName != null)
                  Text(
                    profile.fullName!,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  profile.email,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
                if (role != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role == UserRole.employee ? 'Employee' : 'Employer',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error),
            ),
            filled: true,
            fillColor: cs.surface,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: onToggle,
              color: cs.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error),
            ),
            filled: true,
            fillColor: cs.surface,
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 52, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Failed to load settings', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SettingsShimmer extends StatelessWidget {
  const _SettingsShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(double.infinity, 80, cs),
          const SizedBox(height: 24),
          _shimmerBox(180, 22, cs),
          const SizedBox(height: 8),
          _shimmerBox(260, 14, cs),
          const SizedBox(height: 20),
          ...List.generate(2, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(80, 13, cs),
                const SizedBox(height: 6),
                _shimmerBox(double.infinity, 44, cs),
              ],
            ),
          )),
          _shimmerBox(double.infinity, 48, cs),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, ColorScheme cs) => Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
