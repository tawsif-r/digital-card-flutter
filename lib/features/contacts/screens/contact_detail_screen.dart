import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contacts_provider.dart';
import '../domain/contact_model.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../cards/providers/cards_provider.dart';
import '../../cards/domain/card_model.dart';
import '../../messaging/widgets/start_thread_button.dart';
import '../../../core/providers/session_provider.dart';

class ContactDetailScreen extends ConsumerWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactDetailProvider(contactId));

    return contactAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Contact not found or access denied.'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      data: (contact) => _ContactDetailView(contact: contact),
    );
  }
}

class _ContactDetailView extends ConsumerStatefulWidget {
  const _ContactDetailView({required this.contact});

  final ContactModel contact;

  @override
  ConsumerState<_ContactDetailView> createState() => _ContactDetailViewState();
}

class _ContactDetailViewState extends ConsumerState<_ContactDetailView> {
  late ContactModel _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_contact.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_contact.card != null) ...[
              CardWidget(data: _contact.card!.data),
              const SizedBox(height: 24),
            ] else ...[
              _DeletedCardBanner(slug: _contact.cardSlug),
              const SizedBox(height: 16),
            ],
            _SourceRow(source: _contact.source),
            const SizedBox(height: 16),
            _NotesSection(
              notes: _contact.notes,
              onEdit: () => _editNotes(context),
            ),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final selfId = ref.watch(userSessionProvider);
              final isSelf = _contact.contactUserId != null &&
                  _contact.contactUserId == selfId;
              if (isSelf) return const SizedBox.shrink();
              final hasAccount = _contact.contactUserId != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasAccount)
                    StartThreadButton(contactId: _contact.id)
                  else
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Message (not on Digital Card)'),
                    ),
                  if (!hasAccount) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invite them by sharing your card below.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              );
            }),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareMyCard(context),
                icon: const Icon(Icons.send_outlined, size: 16),
                label: const Text('Share My Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNotes(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: _contact.notes ?? '');
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Notes', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a note about this contact…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final notes = result.isEmpty ? null : result;
    final err = await ref.read(contactsProvider.notifier).updateNotes(_contact.id, notes);

    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      ref.invalidate(contactDetailProvider(_contact.id));
      setState(() => _contact = _contact.copyWith(notes: notes));
    }
  }

  Future<void> _shareMyCard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final cardsAsync = ref.read(cardsProvider);
    final myCards = cardsAsync.valueOrNull?.where((c) => c.isActive).toList() ?? [];

    if (myCards.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You have no active card to share.')),
      );
      return;
    }

    String? selectedCardId;
    if (myCards.length > 1) {
      selectedCardId = await _pickCard(context, myCards);
      if (selectedCardId == null || !mounted) return;
    } else {
      selectedCardId = myCards.first.id;
    }

    final (email, err) = await ref
        .read(contactsProvider.notifier)
        .shareMyCard(_contact.id, cardId: selectedCardId);

    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('Card shared with $email')));
    }
  }

  Future<String?> _pickCard(BuildContext context, List<CardModel> cards) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Choose which card to share',
                style: Theme.of(ctx).textTheme.titleMedium),
          ),
          ...cards.map(
            (c) => ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(c.data.name),
              subtitle: c.data.title != null ? Text(c.data.title!) : null,
              onTap: () => Navigator.pop(ctx, c.id),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove contact?'),
        content: Text('${_contact.displayName} will be removed from your contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final err = await ref.read(contactsProvider.notifier).delete(_contact.id);
    if (!mounted) return;

    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      router.pop();
    }
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final (label, icon) = switch (source) {
      'scan' => ('Added via QR scan', Icons.qr_code_2),
      'email_import' => ('Added via email', Icons.email_outlined),
      'phone_import' => ('Added via phone import', Icons.phone_outlined),
      _ => ('Added manually', Icons.person_add_outlined),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes, required this.onEdit});

  final String? notes;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: tt.labelLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (notes != null && notes!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(notes!, style: tt.bodyMedium),
          )
        else
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outline, width: 0.5),
              ),
              child: Text(
                'Tap to add a note…',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeletedCardBanner extends StatelessWidget {
  const _DeletedCardBanner({required this.slug});

  final String? slug;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slug != null
                  ? 'This contact removed their card (slug: $slug).'
                  : 'This contact\'s card is no longer available.',
              style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
