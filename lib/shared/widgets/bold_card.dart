import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/cards/domain/card_data.dart';
import '../utils/color_utils.dart';
import 'social_chip.dart';

class BoldCard extends StatelessWidget {
  const BoldCard({super.key, required this.data, this.scale = 1.0});

  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(data.accentColor);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16 * scale,
              offset: Offset(0, 4 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent block — ~40% visual weight
            Container(
              color: accent,
              padding: EdgeInsets.all(20 * scale),
              child: scale < 0.5
                  ? _MiniHeader(data: data, scale: scale)
                  : _Header(data: data, scale: scale),
            ),
            if (scale >= 0.5)
              Padding(
                padding: EdgeInsets.all(20 * scale),
                child: _BottomSection(data: data),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data, required this.scale});
  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.name,
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (data.title != null)
                Text(
                  data.title!,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              if (data.company != null)
                Text(
                  data.company!,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ),
        if (data.photoUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: data.photoUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _WhiteAvatar(name: data.name),
            ),
          )
        else
          _WhiteAvatar(name: data.name),
      ],
    );
  }
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.data, required this.scale});
  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          style: TextStyle(fontSize: 10 * scale, fontWeight: FontWeight.w700, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (data.title != null)
          Text(
            data.title!,
            style: TextStyle(fontSize: 7 * scale, color: Colors.white.withOpacity(0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.data});
  final CardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.email != null) _Row(Icons.email_outlined, data.email!, theme),
        if (data.phone != null) _Row(Icons.phone_outlined, data.phone!, theme),
        if (data.website != null) _Row(Icons.language_outlined, data.website!, theme),
        if (data.socials.isNotEmpty) ...[
          const SizedBox(height: 8),
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

class _Row extends StatelessWidget {
  const _Row(this.icon, this.value, this.theme);
  final IconData icon;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _WhiteAvatar extends StatelessWidget {
  const _WhiteAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white.withOpacity(0.25),
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
