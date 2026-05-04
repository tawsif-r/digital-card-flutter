import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cards_provider.dart';
import '../../../core/router/routes.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../share/screens/share_bottom_sheet.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return cardsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Card not found.')),
      ),
      data: (cards) {
        final matching = cards.where((c) => c.id == cardId);
        final card = matching.isEmpty ? null : matching.first;

        if (card == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Card not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(card.data.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Routes.cardEditPath(cardId)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CardWidget(data: card.data),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(Routes.publicCardPath(card.slug)),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showShare(context, card.slug, card.data.name),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Slug: ${card.slug}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShare(BuildContext context, String slug, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareBottomSheet(slug: slug, name: name),
    );
  }
}
