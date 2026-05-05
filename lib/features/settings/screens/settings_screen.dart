import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/validators.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
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
        ),
      ),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({required this.profile, required this.settings});

  final UserProfile profile;
  final UserSettings settings;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _designation;
  late final TextEditingController _department;
  late final TextEditingController _company;

  late bool _showOnlineStatus;
  late bool _allowAudioCalls;
  late bool _allowVideoCalls;

  bool _savingProfile = false;
  bool _savingSettings = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.profile.fullName ?? '');
    _phone = TextEditingController(text: widget.profile.phone ?? '');
    _designation = TextEditingController(text: widget.profile.designation ?? '');
    _department = TextEditingController(text: widget.profile.department ?? '');
    _company = TextEditingController(text: widget.profile.company ?? '');

    _showOnlineStatus = widget.settings.showOnlineStatus;
    _allowAudioCalls = widget.settings.allowAudioCalls;
    _allowVideoCalls = widget.settings.allowVideoCalls;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _designation.dispose();
    _department.dispose();
    _company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                icon: Icons.person_outline,
                title: 'Profile Information',
                subtitle: 'Update your personal and professional details.',
              ),
              const SizedBox(height: 16),
              _ProfileField(
                label: 'Full Name',
                controller: _fullName,
                hint: 'John Doe',
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                label: 'Phone',
                controller: _phone,
                hint: '+880 1234-567890',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _ProfileField(
                label: 'Designation',
                controller: _designation,
                hint: 'Software Engineer',
              ),
              const SizedBox(height: 12),
              _ProfileField(
                label: 'Department',
                controller: _department,
                hint: 'Engineering',
              ),
              const SizedBox(height: 12),
              _ProfileField(
                label: 'Company',
                controller: _company,
                hint: 'DigitalCard Inc',
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
                subtitle: 'Let your connections see when you\'re active.',
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
      ),
    );
  }

  Future<void> _saveProfile(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);

    final updated = widget.profile.copyWith(
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim(),
      designation: _designation.text.trim(),
      department: _department.text.trim(),
      company: _company.text.trim(),
    );

    final (ok, err) = await ref.read(settingsProvider.notifier).updateProfile(updated);

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
            color: AppColors.primary.withOpacity(0.12),
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
            hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.5)),
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
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
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
          _shimmerBox(180, 22, cs),
          const SizedBox(height: 8),
          _shimmerBox(260, 14, cs),
          const SizedBox(height: 20),
          ...List.generate(5, (_) => Padding(
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
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
