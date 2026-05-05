import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../domain/user_profile.dart';
import '../domain/user_settings.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final profileAsync = ref.watch(userProfileProvider);
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Profile Information', style: tt.titleMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: profileAsync.when(
                loading: () => _ProfileFormSkeleton(cs: cs),
                error: (e, _) => _SectionError(
                  message: 'Failed to load profile.',
                  onRetry: () => ref.invalidate(userProfileProvider),
                  cs: cs,
                  tt: tt,
                ),
                data: (profile) => _ProfileForm(profile: profile, cs: cs, tt: tt),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Privacy & Communication', style: tt.titleMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverToBoxAdapter(
              child: settingsAsync.when(
                loading: () => _SettingsSkeleton(cs: cs),
                error: (e, _) => _SectionError(
                  message: 'Failed to load settings.',
                  onRetry: () => ref.invalidate(userSettingsProvider),
                  cs: cs,
                  tt: tt,
                ),
                data: (settings) => _PrivacySection(settings: settings, cs: cs, tt: tt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile, required this.cs, required this.tt});
  final UserProfile profile;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _designation;
  late final TextEditingController _department;
  late final TextEditingController _company;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.profile.fullName ?? '');
    _phone = TextEditingController(text: widget.profile.phone ?? '');
    _designation = TextEditingController(text: widget.profile.designation ?? '');
    _department = TextEditingController(text: widget.profile.department ?? '');
    _company = TextEditingController(text: widget.profile.company ?? '');
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await ref.read(userProfileProvider.notifier).save({
      'fullName': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'designation': _designation.text.trim(),
      'department': _department.text.trim(),
      'company': _company.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile saved.' : 'Failed to save profile.'),
        backgroundColor: ok ? AppColors.success : widget.cs.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.cs.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LabeledField(
              label: 'Full Name',
              controller: _fullName,
              hint: 'e.g. Alex Johnson',
              cs: widget.cs,
              tt: widget.tt,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Phone',
              controller: _phone,
              hint: 'e.g. +1 555 123 4567',
              keyboardType: TextInputType.phone,
              cs: widget.cs,
              tt: widget.tt,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Designation',
              controller: _designation,
              hint: 'e.g. Senior Engineer',
              cs: widget.cs,
              tt: widget.tt,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Department',
              controller: _department,
              hint: 'e.g. Engineering',
              cs: widget.cs,
              tt: widget.tt,
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Company',
              controller: _company,
              hint: 'e.g. Acme Corp',
              cs: widget.cs,
              tt: widget.tt,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.cs,
    required this.tt,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final ColorScheme cs;
  final TextTheme tt;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection({required this.settings, required this.cs, required this.tt});
  final UserSettings settings;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          _ToggleTile(
            title: 'Show Online Status',
            subtitle: 'Let others see when you are active.',
            value: settings.showOnlineStatus,
            onChanged: (v) => ref
                .read(userSettingsProvider.notifier)
                .toggle({'showOnlineStatus': v}),
            cs: cs,
            tt: tt,
            isFirst: true,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
          _ToggleTile(
            title: 'Allow Audio Calls',
            subtitle: 'Let connections call you via audio.',
            value: settings.allowAudioCalls,
            onChanged: (v) => ref
                .read(userSettingsProvider.notifier)
                .toggle({'allowAudioCalls': v}),
            cs: cs,
            tt: tt,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
          _ToggleTile(
            title: 'Allow Video Calls',
            subtitle: 'Let connections call you via video.',
            value: settings.allowVideoCalls,
            onChanged: (v) => ref
                .read(userSettingsProvider.notifier)
                .toggle({'allowVideoCalls': v}),
            cs: cs,
            tt: tt,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.cs,
    required this.tt,
    this.isFirst = false,
    this.isLast = false,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4 : 0,
        bottom: isLast ? 4 : 0,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        title: Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: tt.bodySmall),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _ProfileFormSkeleton extends StatelessWidget {
  const _ProfileFormSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({
    required this.message,
    required this.onRetry,
    required this.cs,
    required this.tt,
  });
  final String message;
  final VoidCallback onRetry;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: tt.bodyMedium)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
