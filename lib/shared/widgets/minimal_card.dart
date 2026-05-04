import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/cards/domain/card_data.dart';
import '../utils/color_utils.dart';
import 'social_chip.dart';

class MinimalCard extends StatelessWidget {
  const MinimalCard({super.key, required this.data, this.scale = 1.0});

  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(data.accentColor);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border(left: BorderSide(color: accent, width: 4 * scale)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      padding: EdgeInsets.all(20 * scale),
      child: scale < 0.5
          ? _MiniContent(data: data, accent: accent, scale: scale)
          : _FullContent(data: data, accent: accent, scale: scale),
    );
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({required this.data, required this.accent, required this.scale});
  final CardData data;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (data.title != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [data.title, if (data.company != null) data.company].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (data.photoUrl != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: data.photoUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _AvatarPlaceholder(name: data.name, accent: accent),
                ),
              )
            else
              _AvatarPlaceholder(name: data.name, accent: accent),
          ],
        ),
        const Divider(height: 24),
        if (data.email != null)
          _ContactRow(Icons.email_outlined, data.email!),
        if (data.phone != null)
          _ContactRow(Icons.phone_outlined, data.phone!),
        if (data.website != null)
          _ContactRow(Icons.language_outlined, data.website!),
        if (data.socials.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: data.socials.map((s) => SocialChip(social: s)).toList(),
          ),
        ],
      ],
    );
  }
}

class _MiniContent extends StatelessWidget {
  const _MiniContent({required this.data, required this.accent, required this.scale});
  final CardData data;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (data.title != null)
          Text(
            data.title!,
            style: TextStyle(
              fontSize: 7 * scale,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.name, required this.accent});
  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: accent.withOpacity(0.15),
      child: Text(initials, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
    );
  }
}
