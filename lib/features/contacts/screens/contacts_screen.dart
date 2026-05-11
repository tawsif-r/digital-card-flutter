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
    final isEmployee =
        ref.watch(authProvider).user?.role == UserRole.employee;
    final addPath =
        isEmployee ? Routes.employeeContactAdd : Routes.contactAdd;
    String detailPath(String id) => isEmployee
        ? Routes.employeeContactDetailPath(id)
        : Routes.contactDetailPath(id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          _SourceFilterRow(
            selected: contactsAsync.valueOrNull?.sourceFilter,
            onChanged: (s) => ref.read(contactsProvider.notifier).setSourceFilter(s),
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
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: const Text('Add Contact'),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone…',
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

class _SourceFilterRow extends StatelessWidget {
  const _SourceFilterRow({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _filters = [
    (label: 'All', value: null),
    (label: 'Scan', value: 'scan'),
    (label: 'Email', value: 'email_import'),
    (label: 'Phone', value: 'phone_import'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final active = selected == f.value;
          return FilterChip(
            label: Text(f.label),
            selected: active,
            onSelected: (_) => onChanged(f.value),
            visualDensity: VisualDensity.compact,
          );
        },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = _initials(contact.displayName);
    final selfId = ref.watch(userSessionProvider);
    final isSelf = contact.contactUserId != null &&
        contact.contactUserId == selfId;
    final hasAccount = contact.contactUserId != null;
    final showMessageIcon = !isSelf;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push(detailPathFor(contact.id)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: tt.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
        title: Text(contact.displayName, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.displayCompany != null)
              Text(contact.displayCompany!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (contact.displayEmail != null)
              Text(contact.displayEmail!, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMessageIcon)
              _MessageIconButton(
                contactId: contact.id,
                hasAccount: hasAccount,
              ),
            _SourceBadge(source: contact.source),
          ],
        ),
        isThreeLine: contact.displayCompany != null && contact.displayEmail != null,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }
}

class _MessageIconButton extends ConsumerStatefulWidget {
  const _MessageIconButton({
    required this.contactId,
    required this.hasAccount,
  });

  final String contactId;
  final bool hasAccount;

  @override
  ConsumerState<_MessageIconButton> createState() => _MessageIconButtonState();
}

class _MessageIconButtonState extends ConsumerState<_MessageIconButton> {
  bool _busy = false;

  void _showInviteHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This contact is not on Digital Card yet. Open the contact and tap "Share My Card" to invite them.',
        ),
      ),
    );
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final (threadId, err) = await ref
          .read(threadsProvider.notifier)
          .createOrGetThread(contactId: widget.contactId);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      if (threadId == null) return;
      final isEmployee =
          ref.read(authProvider).user?.role == UserRole.employee;
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
    final cs = Theme.of(context).colorScheme;
    final iconColor =
        widget.hasAccount ? AppColors.primary : cs.onSurfaceVariant;
    return IconButton(
      tooltip: widget.hasAccount ? 'Message' : 'Not on Digital Card — invite',
      onPressed: _busy
          ? null
          : (widget.hasAccount ? _open : _showInviteHint),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              widget.hasAccount
                  ? Icons.chat_bubble_outline
                  : Icons.person_add_alt_1_outlined,
              size: 20,
              color: iconColor,
            ),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (source) {
      'scan' => ('Scan', Icons.qr_code_2),
      'email_import' => ('Email', Icons.email_outlined),
      'phone_import' => ('Phone', Icons.phone_outlined),
      _ => ('?', Icons.help_outline),
    };
    return Tooltip(
      message: label,
      child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              child: Icon(Icons.contacts_outlined, size: 40, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Text('No contacts yet', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add contacts by scanning a QR code, email lookup, or phone book import.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Your First Contact'),
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
