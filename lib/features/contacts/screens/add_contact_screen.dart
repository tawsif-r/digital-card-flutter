import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contacts_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/validators.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Contact', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner, size: 18), text: 'Scan / Slug'),
            Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'By Email'),
            Tab(icon: Icon(Icons.phone_outlined, size: 18), text: 'Phone Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SlugTab(),
          _EmailTab(),
          _PhoneImportTab(),
        ],
      ),
    );
  }
}

// ── Slug / QR Tab ────────────────────────────────────────────────────────────

class _SlugTab extends ConsumerStatefulWidget {
  const _SlugTab();

  @override
  ConsumerState<_SlugTab> createState() => _SlugTabState();
}

class _SlugTabState extends ConsumerState<_SlugTab> {
  final _formKey = GlobalKey<FormState>();
  final _slugController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _slugController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final (contact, err) = await ref.read(contactsProvider.notifier).addBySlug(
          _slugController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact!.displayName} added to contacts.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter the card slug shown on a digital card (e.g. john-a3f2) or scan a QR code to get the slug.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Card Slug',
                hintText: 'e.g. john-a3f2',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.required(v, field: 'Slug'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Met at Dhaka Tech Summit',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Email Tab ─────────────────────────────────────────────────────────────────

class _EmailTab extends ConsumerStatefulWidget {
  const _EmailTab();

  @override
  ConsumerState<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends ConsumerState<_EmailTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final (contact, err) = await ref.read(contactsProvider.notifier).addByEmail(
          _emailController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact!.displayName} added to contacts.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'john@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_outlined, size: 18),
                label: const Text('Find & Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phone Import Tab ──────────────────────────────────────────────────────────

class _PhoneImportTab extends ConsumerStatefulWidget {
  const _PhoneImportTab();

  @override
  ConsumerState<_PhoneImportTab> createState() => _PhoneImportTabState();
}

class _PhoneImportTabState extends ConsumerState<_PhoneImportTab> {
  final _controller = TextEditingController();
  bool _loading = false;
  _ImportResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, String?>> _parseEntries(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split(',').map((p) => p.trim()).toList();
      final name = parts.isNotEmpty ? parts[0] : null;
      String? email;
      String? phone;
      for (final p in parts.skip(1)) {
        if (p.contains('@')) {
          email = p;
        } else if (p.startsWith('+') || RegExp(r'^\d').hasMatch(p)) {
          phone = p;
        }
      }
      return {'name': name, 'email': email, 'phone': phone};
    }).toList();
  }

  Future<void> _import() async {
    final entries = _parseEntries(_controller.text);
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid entries found.')),
      );
      return;
    }
    if (entries.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 500 entries per import.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    final (result, err) = await ref.read(contactsProvider.notifier).importFromPhone(entries);

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (result != null) {
      setState(() => _result = _ImportResult(
            matched: result.matched.length,
            notFound: result.notFound,
            skipped: result.skippedDuplicates,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'One contact per line. Format:\nName, email@example.com\nName, +8801700000001\nName, email@example.com, +8801700000001',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 10,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Alice, alice@example.com\nBob, +8801700000001',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _import,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Import Contacts'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ImportResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ImportResult {
  const _ImportResult({
    required this.matched,
    required this.notFound,
    required this.skipped,
  });
  final int matched;
  final int notFound;
  final int skipped;
}

class _ImportResultCard extends StatelessWidget {
  const _ImportResultCard({required this.result});

  final _ImportResult result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Results', style: tt.labelLarge),
          const SizedBox(height: 12),
          _ResultRow(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            label: 'Matched & added',
            count: result.matched,
          ),
          const SizedBox(height: 6),
          _ResultRow(
            icon: Icons.skip_next_outlined,
            color: cs.onSurfaceVariant,
            label: 'Already in contacts',
            count: result.skipped,
          ),
          const SizedBox(height: 6),
          _ResultRow(
            icon: Icons.person_off_outlined,
            color: cs.error,
            label: 'Not found on platform',
            count: result.notFound,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text('$count', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
      ],
    );
  }
}
