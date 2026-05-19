import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/cards/domain/card_data.dart';

class SocialChip extends StatelessWidget {
  const SocialChip({super.key, required this.social, this.onDelete});

  final SocialLink social;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (onDelete != null) {
      return FilterChip(
        avatar: FaIcon(_iconFor(social.platform), size: 14),
        label: Text(social.platform),
        onSelected: (_) {},
        onDeleted: onDelete,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: theme.textTheme.labelSmall,
      );
    }
    return ActionChip(
      avatar: FaIcon(_iconFor(social.platform), size: 14),
      label: Text(social.platform),
      onPressed: () => launchUrl(Uri.parse(social.url), mode: LaunchMode.externalApplication),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: theme.textTheme.labelSmall,
    );
  }

  FaIconData _iconFor(String platform) => switch (platform.toLowerCase()) {
        'linkedin' => FontAwesomeIcons.linkedin,
        'github' => FontAwesomeIcons.github,
        'twitter' || 'x' => FontAwesomeIcons.xTwitter,
        'instagram' => FontAwesomeIcons.instagram,
        'facebook' => FontAwesomeIcons.facebook,
        'youtube' => FontAwesomeIcons.youtube,
        'tiktok' => FontAwesomeIcons.tiktok,
        'discord' => FontAwesomeIcons.discord,
        'behance' => FontAwesomeIcons.behance,
        'dribbble' => FontAwesomeIcons.dribbble,
        _ => FontAwesomeIcons.link,
      };
}
