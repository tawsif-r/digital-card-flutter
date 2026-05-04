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
  CardData? _initialData;
  bool _saving = false;
  bool _dataReady = false; // false until initial data loaded (edit mode)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataReady) _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.cardId == null) {
      // New card — ready immediately
      setState(() => _dataReady = true);
      return;
    }
    final cards = ref.read(cardsProvider).valueOrNull;
    if (cards == null) return; // still loading — didChangeDependencies will retry
    try {
      final existing = cards.firstWhere((c) => c.id == widget.cardId);
      setState(() {
        _initialData = existing.data;
        _dataReady = true;
      });
    } catch (_) {
      // not in cache yet — fetch directly
      _fetchFromApi();
    }
  }

  Future<void> _fetchFromApi() async {
    try {
      final repo = ref.read(cardRepositoryProvider);
      final card = await repo.getOne(widget.cardId!);
      if (!mounted) return;
      setState(() {
        _initialData = card.data;
        _dataReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dataReady = true); // show empty form rather than infinite spinner
    }
  }

  CardBuilderNotifier get _notifier =>
      ref.read(cardBuilderProvider(_initialData).notifier);

  Future<void> _save(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = ref.read(cardBuilderProvider(_initialData));
    bool ok;
    String? errorMsg;
    if (widget.cardId != null) {
      final (success, err) = await ref.read(cardsProvider.notifier).updateCard(widget.cardId!, data);
      ok = success;
      errorMsg = err;
    } else {
      final (card, err) = await ref.read(cardsProvider.notifier).createCard(data);
      ok = card != null;
      errorMsg = err;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg ?? 'Failed to save card. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Card')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ValueKey forces form to fully rebuild when _initialData changes,
    // so TextFormField.initialValue is respected.
    return _CardBuilderForm(
      key: ValueKey(_initialData.hashCode),
      cardId: widget.cardId,
      initialData: _initialData,
      saving: _saving,
      notifier: _notifier,
      onSave: _save,
    );
  }
}

class _CardBuilderForm extends StatefulWidget {
  const _CardBuilderForm({
    super.key,
    required this.cardId,
    required this.initialData,
    required this.saving,
    required this.notifier,
    required this.onSave,
  });

  final String? cardId;
  final CardData? initialData;
  final bool saving;
  final CardBuilderNotifier notifier;
  final Future<void> Function(GlobalKey<FormState>) onSave;

  @override
  State<_CardBuilderForm> createState() => _CardBuilderFormState();
}

class _CardBuilderFormState extends State<_CardBuilderForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return _CardBuilderFormBody(
      formKey: _formKey,
      cardId: widget.cardId,
      initialData: widget.initialData,
      saving: widget.saving,
      notifier: widget.notifier,
      onSave: widget.onSave,
    );
  }
}

class _CardBuilderFormBody extends ConsumerWidget {
  const _CardBuilderFormBody({
    required this.formKey,
    required this.cardId,
    required this.initialData,
    required this.saving,
    required this.notifier,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final String? cardId;
  final CardData? initialData;
  final bool saving;
  final CardBuilderNotifier notifier;
  final Future<void> Function(GlobalKey<FormState>) onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardData = ref.watch(cardBuilderProvider(initialData));

    return Scaffold(
      appBar: AppBar(
        title: Text(cardId != null ? 'Edit Card' : 'New Card'),
        actions: [
          TextButton(
            onPressed: saving ? null : () => onSave(formKey),
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Column(
          children: [
            _PreviewBanner(data: cardData),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader('Identity'),
                    _IdentitySection(data: cardData, notifier: notifier),
                    _SectionHeader('Contact'),
                    _ContactSection(data: cardData, notifier: notifier),
                    _SectionHeader('Socials'),
                    _SocialsSection(data: cardData, notifier: notifier),
                    _SectionHeader('Appearance'),
                    _AppearanceSection(data: cardData, notifier: notifier),
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

  static const _palettes = [
    _Palette('Rose',      '#DC9B9B', '#E8B0B0', '#C47070'),
    _Palette('Mint',      '#C0E1D2', '#8ECFB8', '#5BB8A0'),
    _Palette('Sage',      '#7EA882', '#4D8155', '#A8C5A0'),
    _Palette('Sky',       '#6B9FD4', '#3D7CC9', '#89B4E8'),
    _Palette('Lavender',  '#9B8ED6', '#6B5FBF', '#C4B5F7'),
    _Palette('Gold',      '#D4A853', '#B8892A', '#E8C378'),
    _Palette('Slate',     '#6B8090', '#4A6275', '#8DAABB'),
    _Palette('Coral',     '#E07B5A', '#C45A35', '#F09A7C'),
    _Palette('Plum',      '#A0608A', '#7D3D6A', '#C480AC'),
    _Palette('Teal',      '#4AABB0', '#2D8E94', '#74C9CE'),
    _Palette('Sand',      '#C4A882', '#A07850', '#DCC4A0'),
    _Palette('Charcoal',  '#5A5755', '#3A3835', '#7A7775'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Template', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        TemplatePicker(
          selected: data.template,
          baseData: data,
          onSelect: notifier.setTemplate,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Color Scheme', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Pick a palette or tap a swatch to set the accent.', style: tt.bodySmall),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final palette in _palettes)
                _PaletteSwatch(
                  palette: palette,
                  selectedHex: data.accentColor,
                  onSelect: notifier.setAccentColor,
                ),
              _CustomSwatch(
                currentHex: data.accentColor,
                onSelect: notifier.setAccentColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Current accent', style: tt.bodySmall),
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: hexToColor(data.accentColor),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outline),
                ),
              ),
              const SizedBox(width: 6),
              Text(data.accentColor.toUpperCase(), style: tt.labelSmall?.copyWith(fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }
}

class _Palette {
  const _Palette(this.name, this.base, this.light, this.dark);
  final String name;
  final String base;
  final String light;
  final String dark;
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selectedHex,
    required this.onSelect,
  });
  final _Palette palette;
  final String selectedHex;
  final void Function(String) onSelect;

  bool get _isSelected =>
      selectedHex == palette.base ||
      selectedHex == palette.light ||
      selectedHex == palette.dark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isSelected ? cs.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(hex: palette.light, onTap: () => onSelect(palette.light)),
                _Dot(hex: palette.base, onTap: () => onSelect(palette.base)),
                _Dot(hex: palette.dark, onTap: () => onSelect(palette.dark)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(palette.name, style: tt.labelSmall),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.hex, required this.onTap});
  final String hex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        color: hexToColor(hex),
      ),
    );
  }
}

class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({required this.currentHex, required this.onSelect});
  final String currentHex;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            width: 86,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline),
              color: cs.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.colorize_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Custom', style: tt.labelSmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Custom', style: tt.labelSmall?.copyWith(color: Colors.transparent)),
      ],
    );
  }

  void _pick(BuildContext context) {
    Color current = hexToColor(currentHex);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom color'),
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
              onSelect(colorToHex(current));
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
