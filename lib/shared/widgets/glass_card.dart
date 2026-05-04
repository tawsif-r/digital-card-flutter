import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/cards/domain/card_data.dart';
import '../utils/color_utils.dart';
import 'social_chip.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.data, this.scale = 1.0});

  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(data.accentColor);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scale),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.6),
            accent.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 20 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * scale),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            padding: EdgeInsets.all(20 * scale),
            child: scale < 0.5
                ? _MiniContent(data: data, scale: scale)
                : _FullContent(data: data, scale: scale),
          ),
        ),
      ),
    );
  }
}

class _FullContent extends StatelessWidget {
  const _FullContent({required this.data, required this.scale});
  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (data.title != null)
                    Text(
                      data.title!,
                      style: TextStyle(fontSize: 14 * scale, color: Colors.white.withOpacity(0.85)),
                    ),
                  if (data.company != null)
                    Text(
                      data.company!,
                      style: TextStyle(fontSize: 12 * scale, color: Colors.white.withOpacity(0.7)),
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
                  errorWidget: (_, __, ___) => _GlassAvatar(name: data.name),
                ),
              )
            else
              _GlassAvatar(name: data.name),
          ],
        ),
        Divider(height: 24, color: Colors.white.withOpacity(0.3)),
        if (data.email != null) _ContactRow(Icons.email_outlined, data.email!),
        if (data.phone != null) _ContactRow(Icons.phone_outlined, data.phone!),
        if (data.website != null) _ContactRow(Icons.language_outlined, data.website!),
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
  const _MiniContent({required this.data, required this.scale});
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

class _ContactRow extends StatelessWidget {
  const _ContactRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassAvatar extends StatelessWidget {
  const _GlassAvatar({required this.name});
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
