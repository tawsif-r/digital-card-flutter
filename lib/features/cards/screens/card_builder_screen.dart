import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide colorToHex;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_builder_provider.dart';
import '../providers/cards_provider.dart';
import '../domain/card_data.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../../shared/widgets/template_picker.dart';
import '../../../shared/utils/color_utils.dart';
import '../../../shared/utils/validators.dart';

class CardBuilderScreen extends ConsumerStatefulWidget {
  const CardBuilderScreen({super.key, this.cardId});

  final String? cardId;

  @override
  ConsumerState<CardBuilderScreen> createState() => _CardBuilderScreenState();
}

class _CardBuilderScreenState extends ConsumerState<CardBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  CardData? _initialData;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    if (widget.cardId != null) {
      final cards = ref.read(cardsProvider).valueOrNull;
      final existing = cards?.firstWhere((c) => c.id == widget.cardId, orElse: () => throw Exception());
      if (existing != null) {
        setState(() => _initialData = existing.data);
      }
    }
  }

  CardBuilderNotifier get _notifier =>
      ref.read(cardBuilderProvider(_initialData).notifier);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = ref.read(cardBuilderProvider(_initialData));
    bool ok;
    if (widget.cardId != null) {
      ok = await ref.read(cardsProvider.notifier).updateCard(widget.cardId!, data);
    } else {
      final card = await ref.read(cardsProvider.notifier).createCard(data);
      ok = card != null;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save card. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = ref.watch(cardBuilderProvider(_initialData));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cardId != null ? 'Edit Card' : 'New Card'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Live preview banner
            _PreviewBanner(data: cardData),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader('Identity'),
                    _IdentitySection(data: cardData, notifier: _notifier),
                    _SectionHeader('Contact'),
                    _ContactSection(data: cardData, notifier: _notifier),
                    _SectionHeader('Socials'),
                    _SocialsSection(data: cardData, notifier: _notifier),
                    _SectionHeader('Appearance'),
                    _AppearanceSection(data: cardData, notifier: _notifier),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.data});
  final CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: CardWidget(key: ValueKey(data.hashCode), data: data),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.data, required this.notifier});
  final CardData data;
  final CardBuilderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AppTextField(
            label: 'Full Name *',
            initialValue: data.name,
            validator: (v) => Validators.required(v, field: 'Name'),
            onChanged: notifier.setName,
            prefixIcon: const Icon(Icons.person_outlined),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Job Title',
            initialValue: data.title,
            onChanged: notifier.setTitle,
            prefixIcon: const Icon(Icons.work_outline),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Company',
            initialValue: data.company,
            onChanged: notifier.setCompany,
            prefixIcon: const Icon(Icons.business_outlined),
          ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.data, required this.notifier});
  final CardData data;
  final CardBuilderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AppTextField(
            label: 'Phone',
            initialValue: data.phone,
            keyboardType: TextInputType.phone,
            onChanged: notifier.setPhone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Email',
            initialValue: data.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v != null && v.isNotEmpty ? Validators.email(v) : null,
            onChanged: notifier.setEmail,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Website',
            initialValue: data.website,
            keyboardType: TextInputType.url,
            validator: Validators.url,
            onChanged: notifier.setWebsite,
            prefixIcon: const Icon(Icons.language_outlined),
          ),
        ],
      ),
    );
  }
}

class _SocialsSection extends StatefulWidget {
  const _SocialsSection({required this.data, required this.notifier});
  final CardData data;
  final CardBuilderNotifier notifier;

  @override
  State<_SocialsSection> createState() => _SocialsSectionState();
}

class _SocialsSectionState extends State<_SocialsSection> {
  final _platformCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _platformCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final platform = _platformCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (platform.isEmpty || url.isEmpty) return;
    widget.notifier.addSocial(SocialLink(platform: platform, url: url));
    _platformCtrl.clear();
    _urlCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.data.socials.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.data.socials.asMap().entries.map((e) {
                return Chip(
                  label: Text('${e.value.platform}: ${e.value.url}', overflow: TextOverflow.ellipsis),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => widget.notifier.removeSocial(e.key),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _platformCtrl,
                  decoration: const InputDecoration(labelText: 'Platform', hintText: 'linkedin'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.data, required this.notifier});
  final CardData data;
  final CardBuilderNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Template', style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(height: 8),
        TemplatePicker(
          selected: data.template,
          baseData: data,
          onSelect: notifier.setTemplate,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Accent Color', style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              GestureDetector(
                onTap: () => _pickColor(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hexToColor(data.accentColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickColor(BuildContext context) {
    Color current = hexToColor(data.accentColor);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick accent color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => current = c,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              notifier.setAccentColor(colorToHex(current));
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
