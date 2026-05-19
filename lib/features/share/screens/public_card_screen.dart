import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../features/cards/data/card_repository.dart';
import '../../../features/cards/domain/card_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/contacts/providers/contacts_provider.dart';
import '../../../core/di/providers.dart';
import '../../../shared/widgets/card_widget.dart';
import '../../../shared/utils/vcard.dart';

final _publicCardProvider = FutureProvider.family<CardModel, String>((ref, slug) {
  return CardRepository(ref.watch(dioProvider)).getPublic(slug);
});

class PublicCardScreen extends ConsumerStatefulWidget {
  const PublicCardScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends ConsumerState<PublicCardScreen> {
  bool _connecting = false;

  Future<void> _connect(String ownerId) async {
    setState(() => _connecting = true);
    try {
      await ref.read(contactRepositoryProvider).sendRequest(ownerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send request')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(_publicCardProvider(widget.slug));
    final auth = ref.watch(authProvider);

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
                onPressed: () => ref.invalidate(_publicCardProvider(widget.slug)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (card) {
          final currentUserId = auth.user?.id;
          final canConnect = auth.isAuthenticated &&
              card.ownerId != null &&
              card.ownerId != currentUserId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CardWidget(data: card.data),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Export vCard'),
                    ),
                    if (canConnect) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _connecting ? null : () => _connect(card.ownerId!),
                        icon: _connecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_outlined),
                        label: const Text('Connect'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
