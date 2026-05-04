import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../features/cards/data/card_repository.dart';
import '../../../features/cards/domain/card_model.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../../shared/utils/vcard.dart';

final _publicCardProvider = FutureProvider.family<CardModel, String>((ref, slug) {
  return CardRepository(ref.watch(dioProvider)).getPublic(slug);
});

class PublicCardScreen extends ConsumerWidget {
  const PublicCardScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(_publicCardProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: cardAsync.whenData((c) => c.data.name).valueOrNull != null
            ? Text(cardAsync.value!.data.name)
            : const Text('Digital Card'),
        actions: [
          if (cardAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final file = await writeVcfTemp(cardAsync.value!.data);
                await Share.shareXFiles([XFile(file.path)], text: cardAsync.value!.data.name);
              },
            ),
        ],
      ),
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('Card not found or inactive.'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(_publicCardProvider(slug)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (card) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CardWidget(data: card.data),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final file = await writeVcfTemp(card.data);
                  if (context.mounted) {
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      text: card.data.name,
                    );
                  }
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Save Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
