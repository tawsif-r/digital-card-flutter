import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.radius = 22,
  });

  final String displayName;
  final String? photoUrl;
  final double radius;

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  static const _colors = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFFEC407A),
    Color(0xFF00ACC1),
    Color(0xFF66BB6A),
  ];

  static Color avatarColor(String name) =>
      _colors[name.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final color = avatarColor(displayName);
    final text = initials(displayName);

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _Initials(text: text, radius: radius),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: _Initials(text: text, radius: radius),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text, required this.radius});
  final String text;
  final double radius;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      );
}
