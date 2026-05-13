import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/contacts_provider.dart';
import '../domain/contact_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/widgets/contact_avatar.dart';

class PendingRequestsScreen extends ConsumerWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Requests',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
            dividerColor: cs.outlineVariant,
          ),
        ),
        body: const TabBarView(
          children: [
            _ReceivedTab(),
            _SentTab(),
          ],
        ),
      ),
    );
  }
}

// ── Received Tab ──────────────────────────────────────────────────────────────

class _ReceivedTab extends ConsumerWidget {
  const _ReceivedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Failed to load requests', style: tt.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.refresh(pendingRequestsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (requests) => requests.isEmpty
          ? const _EmptyRequests(
              icon: Icons.inbox_outlined,
              message: 'No incoming requests',
              hint: 'When someone sends you a connection request, it will appear here.',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(pendingRequestsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PendingTile(request: requests[i]),
              ),
            ),
    );
  }
}

// ── Sent Tab ──────────────────────────────────────────────────────────────────

class _SentTab extends ConsumerWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentAsync = ref.watch(sentRequestsProvider);
    final myId = ref.watch(userSessionProvider) ?? '';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return sentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Failed to load sent requests', style: tt.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.refresh(sentRequestsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (sent) => sent.isEmpty
          ? const _EmptyRequests(
              icon: Icons.outbox_outlined,
              message: 'No sent requests',
              hint: 'Requests you send will appear here until they are accepted.',
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.refresh(sentRequestsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: sent.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _SentTile(contact: sent[i], myId: myId),
              ),
            ),
    );
  }
}

// ── Shared Empty State ────────────────────────────────────────────────────────

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({
    required this.icon,
    required this.message,
    required this.hint,
  });
  final IconData icon;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text(message, style: tt.titleMedium),
            const SizedBox(height: 8),
            Text(hint,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Pending (Received) Tile ───────────────────────────────────────────────────

class _PendingTile extends ConsumerStatefulWidget {
  const _PendingTile({required this.request});
  final ContactModel request;

  @override
  ConsumerState<_PendingTile> createState() => _PendingTileState();
}

class _PendingTileState extends ConsumerState<_PendingTile> {
  bool _accepting = false;
  bool _rejecting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final err = await ref.read(pendingRequestsProvider.notifier).accept(widget.request.id);
    if (!mounted) return;
    setState(() => _accepting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _reject() async {
    setState(() => _rejecting = true);
    final err = await ref.read(pendingRequestsProvider.notifier).reject(widget.request.id);
    if (!mounted) return;
    setState(() => _rejecting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final myId = ref.watch(userSessionProvider) ?? '';
    final peer = widget.request.peer(myId);
    final displayName = peer?.displayName ?? '—';
    final subtitle = [
      peer?.displayTitle,
      peer?.displayCompany,
    ].whereType<String>().join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ContactAvatar(
                  displayName: displayName,
                  photoUrl: peer?.photoUrl,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      Text(peer?.displayEmail ?? '',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_accepting || _rejecting) ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: _rejecting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: (_accepting || _rejecting) ? null : _accept,
                    child: _accepting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sent Tile ─────────────────────────────────────────────────────────────────

class _SentTile extends ConsumerStatefulWidget {
  const _SentTile({required this.contact, required this.myId});
  final ContactModel contact;
  final String myId;

  @override
  ConsumerState<_SentTile> createState() => _SentTileState();
}

class _SentTileState extends ConsumerState<_SentTile> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    final err =
        await ref.read(sentRequestsProvider.notifier).cancel(widget.contact.id);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final peer = widget.contact.peer(widget.myId);
    final displayName = peer?.displayName ?? '—';
    final subtitle = [
      peer?.displayTitle,
      peer?.displayCompany,
    ].whereType<String>().join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ContactAvatar(
              displayName: displayName,
              photoUrl: peer?.photoUrl,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text(peer?.displayEmail ?? '',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Pending',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 4),
            _cancelling
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancel,
                    tooltip: 'Cancel request',
                    color: cs.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
          ],
        ),
      ),
    );
  }
}
