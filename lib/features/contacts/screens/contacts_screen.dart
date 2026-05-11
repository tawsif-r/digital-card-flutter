import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contacts_provider.dart';
import '../domain/contact_model.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../messaging/providers/threads_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
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

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(contactsProvider.notifier).search(query);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(contactsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEmployee = ref.watch(authProvider).user?.role == UserRole.employee;
    final addPath = isEmployee ? Routes.employeeContactAdd : Routes.contactAdd;
    final pendingPath = isEmployee ? Routes.employeeContactPending : Routes.contactPending;
    String detailPath(String id) => isEmployee
        ? Routes.employeeContactDetailPath(id)
        : Routes.contactDetailPath(id);

    final pendingCount = contactsAsync.valueOrNull?.pendingCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Connection Requests',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(pendingPath),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      pendingCount > 9 ? '9+' : '$pendingCount',
                      style: TextStyle(
                        color: cs.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(contactsProvider.notifier).refresh(),
              child: contactsAsync.when(
                loading: () => const CardListShimmer(),
                error: (e, _) => LayoutBuilder(
                  builder: (_, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: _ErrorView(
                        onRetry: () => ref.read(contactsProvider.notifier).refresh(),
                      ),
                    ),
                  ),
                ),
                data: (state) => state.contacts.isEmpty
                    ? LayoutBuilder(
                        builder: (_, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: _EmptyState(onAdd: () => context.push(addPath)),
                          ),
                        ),
                      )
                    : _ContactList(
                        state: state,
                        scrollController: _scrollController,
                        detailPathFor: detailPath,
                      ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(addPath),
        icon: const Icon(Icons.person_search_outlined, size: 20),
        label: const Text('Find People'),
        elevation: 2,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search contacts…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _ContactList extends ConsumerWidget {
  const _ContactList({
    required this.state,
    required this.scrollController,
    required this.detailPathFor,
  });

  final ContactsState state;
  final ScrollController scrollController;
  final String Function(String id) detailPathFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: state.contacts.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == state.contacts.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _ContactTile(
          contact: state.contacts[i],
          detailPathFor: detailPathFor,
        );
      },
    );
  }
}

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.contact, required this.detailPathFor});

  final ContactModel contact;
  final String Function(String id) detailPathFor;

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  static Color _avatarColor(String name) {
    final colors = [
      Colors.indigo.shade400,
      Colors.teal.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.cyan.shade500,
      Colors.green.shade500,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final myId = ref.watch(userSessionProvider) ?? '';
    final peer = contact.peer(myId);
    final displayName = peer?.displayName ?? '—';
    final avatarColor = _avatarColor(displayName);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => context.push(detailPathFor(contact.id)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            _initials(displayName),
            style: tt.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(displayName, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: _buildSubtitle(context, peer),
        trailing: _MessageIconButton(contactId: contact.id),
        isThreeLine: peer?.displayTitle != null && peer?.displayCompany != null,
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context, ContactPeer? peer) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lines = <String>[
      if (peer?.displayTitle != null) peer!.displayTitle!,
      if (peer?.displayCompany != null) peer!.displayCompany!,
    ];
    if (lines.isEmpty) return null;
    return Text(
      lines.join(' · '),
      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MessageIconButton extends ConsumerStatefulWidget {
  const _MessageIconButton({required this.contactId});
  final String contactId;

  @override
  ConsumerState<_MessageIconButton> createState() => _MessageIconButtonState();
}

class _MessageIconButtonState extends ConsumerState<_MessageIconButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final (threadId, err) = await ref
          .read(threadsProvider.notifier)
          .createOrGetThread(contactId: widget.contactId);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      if (threadId == null) return;
      final isEmployee = ref.read(authProvider).user?.role == UserRole.employee;
      if (!mounted) return;
      context.push(isEmployee
          ? Routes.employeeThreadDetailPath(threadId)
          : Routes.threadDetailPath(threadId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Message',
      onPressed: _busy ? null : _open,
      icon: _busy
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat_bubble_outline, size: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.people_outline_rounded, size: 40,
                  color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Text('No connections yet', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Find and connect with people. Tap "Find People" to search by name or email.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: const Text('Find People'),
              ),
            ),
          ],
        ),
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
          Text('Failed to load contacts', style: tt.titleMedium),
          const SizedBox(height: 8),
          Text('Check your connection and try again.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
