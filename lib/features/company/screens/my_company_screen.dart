import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_provider.dart';
import '../domain/company_model.dart';
import '../../cards/providers/cards_provider.dart';
import '../../cards/domain/card_model.dart';
import '../../../core/router/routes.dart';

class MyCompanyScreen extends ConsumerWidget {
  const MyCompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider);

    return companyAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('My Company')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (company) {
        if (company == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.companyOnboard);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _CompanyView(company: company);
      },
    );
  }
}

class _CompanyView extends ConsumerStatefulWidget {
  const _CompanyView({required this.company});

  final CompanyModel company;

  @override
  ConsumerState<_CompanyView> createState() => _CompanyViewState();
}

class _CompanyViewState extends ConsumerState<_CompanyView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(issuedByCompanyProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final issuedAsync = ref.watch(issuedByCompanyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Company')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(issuedByCompanyProvider.notifier).refresh(),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Company header
            CircleAvatar(
              radius: 36,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.business, size: 36, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Center(child: Text(widget.company.name, style: tt.headlineSmall)),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${widget.company.size} employees',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),
            Text('About', style: tt.titleMedium),
            const SizedBox(height: 8),
            Text(widget.company.description, style: tt.bodyLarge),
            const SizedBox(height: 32),

            // Issued cards section
            issuedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Failed to load: $e',
                    style: tt.bodyMedium?.copyWith(color: cs.error)),
              ),
              data: (issued) => _IssuedSection(issued: issued),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssuedSection extends StatelessWidget {
  const _IssuedSection({required this.issued});

  final IssuedByCompanyState issued;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Issued Cards', style: tt.titleMedium),
            Text(
              '${issued.total} total',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (issued.cards.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.badge_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No cards issued yet',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          )
        else
          ...issued.cards.map((card) => _RecipientTile(card: card)),
        if (issued.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _RecipientTile extends ConsumerWidget {
  const _RecipientTile({required this.card});

  final CardModel card;

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Card'),
        content: Text(
          'Remove card issued to ${card.issuedToEmail ?? card.data.name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(issuedByCompanyProvider.notifier).revokeIssued(card.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to revoke card. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.person_outline, color: cs.onSecondaryContainer),
        ),
        title: Text(card.data.name, style: tt.bodyLarge),
        subtitle: Text(
          card.issuedToEmail ?? '',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.isAcknowledged)
              Tooltip(
                message: 'Acknowledged',
                child: Icon(Icons.check_circle_outline,
                    size: 18, color: cs.primary),
              )
            else
              Tooltip(
                message: 'Pending',
                child: Icon(Icons.schedule,
                    size: 18, color: cs.onSurfaceVariant),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
              tooltip: 'Revoke card',
              onPressed: () => _confirmRevoke(context, ref),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
        onTap: () => context.push(Routes.cardDetailPath(card.id)),
      ),
    );
  }
}
