import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cards_provider.dart';
import '../domain/card_model.dart';
import '../../../core/router/routes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${user?.name ?? user?.email?.split('@').first ?? 'there'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileSheet(context, ref),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const CardListShimmer(),
        error: (e, _) => _ErrorView(onRetry: () => ref.read(cardsProvider.notifier).refresh()),
        data: (cards) => cards.isEmpty
            ? _EmptyState(onTap: () => context.push(Routes.cardNew))
            : _CardList(cards: cards),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.cardNew),
        icon: const Icon(Icons.add),
        label: const Text('New Card'),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user?.name != null)
              Text(user!.name!, style: Theme.of(context).textTheme.titleLarge),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardList extends ConsumerWidget {
  const _CardList({required this.cards});
  final List<CardModel> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(cardsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _CardTile(card: cards[i]),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card});
  final CardModel card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete card?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final ok = await ref.read(cardsProvider.notifier).deleteCard(card.id);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete card.')),
          );
        }
      },
      child: GestureDetector(
        onTap: () => context.push(Routes.cardDetailPath(card.id)),
        child: CardWidget(data: card.data),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text('No cards yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first digital business card.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Card'),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load cards.'),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
