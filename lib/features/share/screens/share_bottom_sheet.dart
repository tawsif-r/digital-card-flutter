import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../features/cards/providers/cards_provider.dart';
import '../../../shared/utils/vcard.dart';

class ShareBottomSheet extends ConsumerStatefulWidget {
  const ShareBottomSheet({super.key, required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final String _shareUrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _shareUrl = '${AppConstants.baseUrl}/public/${widget.slug}';
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.slug,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'QR Code'),
              Tab(text: 'Link'),
              Tab(text: 'Contact'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _QrTab(url: _shareUrl),
                _LinkTab(url: _shareUrl),
                _VCardTab(slug: widget.slug),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrTab extends StatefulWidget {
  const _QrTab({required this.url});
  final String url;

  @override
  State<_QrTab> createState() => _QrTabState();
}

class _QrTabState extends State<_QrTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: widget.url,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Share.share(widget.url),
              icon: const Icon(Icons.share),
              label: const Text('Share QR Link'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTab extends StatelessWidget {
  const _LinkTab({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(url, style: Theme.of(context).textTheme.bodyMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Share.share(url),
            icon: const Icon(Icons.share),
            label: const Text('Share Link'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }
}

class _VCardTab extends ConsumerWidget {
  const _VCardTab({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);
    final matching = cardsAsync.valueOrNull?.where((c) => c.slug == slug);
    final card = (matching == null || matching.isEmpty) ? null : matching.first;

    if (card == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.contact_page_outlined, size: 64),
          const SizedBox(height: 16),
          Text('Export contact card', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Save to your contacts or share as a .vcf file.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final file = await writeVcfTemp(card.data);
              await Share.shareXFiles([XFile(file.path)], text: card.data.name);
            },
            icon: const Icon(Icons.download),
            label: const Text('Save Contact (.vcf)'),
          ),
        ],
      ),
    );
  }
}
