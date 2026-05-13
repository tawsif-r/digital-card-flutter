import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contacts_provider.dart';
import '../domain/contact_model.dart';
import '../../messaging/widgets/start_thread_button.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/contact_avatar.dart';

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
              OutlinedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
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
    final tt = Theme.of(context).textTheme;
    final myId = ref.watch(userSessionProvider) ?? '';
    final peer = _contact.peer(myId);
    final displayName = peer?.displayName ?? '—';
    final myNotes = _contact.myNotes(myId);
    final connectedSince = _contact.updatedAt;
    final isRequester = _contact.requesterId == myId;
    final isPending = _contact.status == ContactStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'notes') _editNotes(context, myId);
              if (value == 'remove') _confirmRemove(context);
              if (value == 'block') _confirmBlock(context);
              if (value == 'cancel') _confirmCancel(context);
            },
            itemBuilder: (_) => [
              if (_contact.status == ContactStatus.accepted) ...[
                const PopupMenuItem(value: 'notes', child: Text('Update Notes')),
                const PopupMenuItem(value: 'remove', child: Text('Remove Contact')),
                const PopupMenuItem(value: 'block', child: Text('Block')),
              ],
              if (isPending && isRequester)
                const PopupMenuItem(value: 'cancel', child: Text('Cancel Request')),
              if (isPending && !isRequester) ...[
                const PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name header ────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  ContactAvatar(
                    displayName: displayName,
                    photoUrl: peer?.photoUrl,
                    radius: 44,
                  ),
                  const SizedBox(height: 14),
                  Text(displayName,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  if (peer?.displayTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(peer!.displayTitle!,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  if (peer?.displayCompany != null) ...[
                    const SizedBox(height: 2),
                    Text(peer!.displayCompany!,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 16),
                  // ── Quick action row ──────────────────────────────────────
                  _QuickActions(
                    contactId: _contact.id,
                    phone: peer?.displayPhone,
                    email: peer?.displayEmail,
                    showMessage: _contact.status == ContactStatus.accepted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Card info ────────────────────────────────────────────────────
            if (peer?.card != null) ...[
              _InfoCard(peer: peer!),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This person hasn\'t set up their digital card yet.',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_contact.status == ContactStatus.accepted) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // ── Notes ─────────────────────────────────────────────────────
              _NotesSection(
                notes: myNotes,
                onEdit: () => _editNotes(context, myId),
              ),

              const SizedBox(height: 20),

              // ── Connected since ────────────────────────────────────────────
              Center(
                child: Text(
                  'Connected ${_timeAgo(connectedSince)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],

            if (isPending) ...[
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRequester ? 'Request sent — awaiting response' : 'Pending your response',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year(s) ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    return 'just now';
  }

  Future<void> _editNotes(BuildContext context, String myId) async {
    final messenger = ScaffoldMessenger.of(context);
    final current = _contact.myNotes(myId);
    final controller = TextEditingController(text: current ?? '');
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a note about this person…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                    child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    final notes = result.isEmpty ? null : result;
    final err =
        await ref.read(contactsProvider.notifier).updateNotes(_contact.id, notes);
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      ref.invalidate(contactDetailProvider(_contact.id));
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final myId = ref.read(userSessionProvider) ?? '';
    final peer = _contact.peer(myId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove connection?'),
        content: Text(
            '${peer?.displayName ?? 'This person'} will be removed from your contacts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err = await ref.read(contactsProvider.notifier).removeContact(_contact.id);
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      router.pop();
    }
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block this person?'),
        content: const Text('They will not be able to send you connection requests.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Block',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(contactRepositoryProvider).block(_contact.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Failed to block.')));
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('Your connection request will be withdrawn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cancel Request',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final err =
        await ref.read(sentRequestsProvider.notifier).cancel(_contact.id);
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      router.pop();
    }
  }
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────

class _QuickActions extends ConsumerStatefulWidget {
  const _QuickActions({
    required this.contactId,
    this.phone,
    this.email,
    required this.showMessage,
  });

  final String contactId;
  final String? phone;
  final String? email;
  final bool showMessage;

  @override
  ConsumerState<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends ConsumerState<_QuickActions> {
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final actions = <_QuickAction>[
      if (widget.phone != null)
        _QuickAction(
          icon: Icons.phone_outlined,
          label: 'Call',
          onTap: () => _launch('tel:${widget.phone}'),
        ),
      if (widget.email != null)
        _QuickAction(
          icon: Icons.email_outlined,
          label: 'Email',
          onTap: () => _launch('mailto:${widget.email}'),
        ),
      if (widget.showMessage)
        _QuickAction(
          icon: Icons.chat_bubble_outline,
          label: 'Message',
          widget: StartThreadButton(contactId: widget.contactId, compact: true),
        ),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: actions.map((a) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              a.widget ??
                  IconButton.outlined(
                    onPressed: a.onTap,
                    icon: Icon(a.icon, size: 22),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
              const SizedBox(height: 4),
              Text(a.label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.widget,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? widget;
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.peer});
  final ContactPeer peer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = peer.card!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (card.email != null)
            _InfoRow(
              icon: Icons.email_outlined,
              text: card.email!,
              onTap: () => launchUrl(Uri.parse('mailto:${card.email}')),
            ),
          if (card.phone != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.phone_outlined,
              text: card.phone!,
              onTap: () => launchUrl(Uri.parse('tel:${card.phone}')),
            ),
          ],
          if (card.company != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.business_outlined,
              text: card.company!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: tt.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
          if (onTap != null)
            Icon(Icons.open_in_new, size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ── Notes Section ─────────────────────────────────────────────────────────────

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
        const SizedBox(height: 6),
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
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text('Tap to add a note…',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
      ],
    );
  }
}
