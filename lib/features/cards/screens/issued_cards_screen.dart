import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cards_provider.dart';
import '../domain/card_model.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/card_widget.dart';

class IssuedCardsScreen extends ConsumerWidget {
  const IssuedCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(issuedCardsProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge_outlined, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No cards yet', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Your employer will issue a card to your email.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(issuedCardsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _IssuedCardTile(card: cards[i]),
            ),
          );
        },
      ),
    );
  }
}

class _IssuedCardTile extends StatelessWidget {
  const _IssuedCardTile({required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.cardDetailPath(card.id)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CardWidget(data: card.data, scale: 0.85),
      ),
    );
  }
}
