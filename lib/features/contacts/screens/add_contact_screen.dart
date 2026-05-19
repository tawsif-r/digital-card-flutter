import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contacts_provider.dart';
import '../domain/contact_model.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/widgets/contact_avatar.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(userSearchProvider.notifier).search(q);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      ref.read(userSearchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(userSearchProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Find People',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan card',
            onPressed: () => context.push(Routes.scan),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, email…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: searchAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(
                child: Text('Search failed. Try again.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              data: (state) {
                if (state.isEmpty) {
                  return _SentRequestsOrHint(cs: cs, tt: tt);
                }
                if (state.isLoading && state.results.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visible = state.results
                    .where((u) => u.relationStatus != ContactStatus.blocked)
                    .toList();
                if (visible.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48,
                            color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('No users found for "${state.query}"',
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: visible.length + (state.isLoading ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == visible.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _UserTile(user: visible[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SentRequestsOrHint extends ConsumerWidget {
  const _SentRequestsOrHint({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentAsync = ref.watch(sentRequestsProvider);
    final myId = ref.watch(userSessionProvider) ?? '';
    final sent = sentAsync.valueOrNull ?? [];

    if (sent.isEmpty) {
      return _SearchHint(cs: cs, tt: tt);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Pending Sent',
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ),
        ...sent.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SentRequestTile(contact: c, myId: myId),
            )),
        const Divider(height: 24),
        _SearchHint(cs: cs, tt: tt),
      ],
    );
  }
}

class _SentRequestTile extends ConsumerStatefulWidget {
  const _SentRequestTile({required this.contact, required this.myId});
  final ContactModel contact;
  final String myId;

  @override
  ConsumerState<_SentRequestTile> createState() => _SentRequestTileState();
}

class _SentRequestTileState extends ConsumerState<_SentRequestTile> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    final err = await ref
        .read(sentRequestsProvider.notifier)
        .cancel(widget.contact.id);
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ContactAvatar(
              displayName: displayName,
              photoUrl: peer?.photoUrl,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
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
              child: Icon(Icons.person_search_outlined, size: 36,
                  color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text('Find people to connect with',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Search by name or email address.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  const _UserTile({required this.user});
  final UserSearchResult user;

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    final err = await ref.read(userSearchProvider.notifier).sendRequest(widget.user.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = widget.user;
    final displayName = user.displayName;
    final subtitle = [
      user.displayTitle,
      user.displayCompany,
    ].whereType<String>().join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ContactAvatar(
              displayName: displayName,
              photoUrl: user.card?.photoUrl,
              radius: 22,
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
                  Text(user.email,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RelationButton(
              status: user.relationStatus,
              busy: _busy,
              onConnect: _connect,
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationButton extends StatelessWidget {
  const _RelationButton({
    required this.status,
    required this.busy,
    required this.onConnect,
  });

  final ContactStatus? status;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (busy) {
      return const SizedBox(
          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }

    return switch (status) {
      null => FilledButton(
          onPressed: onConnect,
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Connect', style: TextStyle(fontSize: 13)),
        ),
      ContactStatus.pending => OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 14),
          label: const Text('Pending', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: cs.onSurfaceVariant),
        ),
      ContactStatus.accepted => OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check, size: 14),
          label: const Text('Connected', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.green.shade600),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
