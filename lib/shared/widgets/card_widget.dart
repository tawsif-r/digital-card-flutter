import 'package:flutter/material.dart';
import '../../features/cards/domain/card_data.dart';
import 'minimal_card.dart';
import 'bold_card.dart';
import 'glass_card.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.data, this.scale = 1.0});

  final CardData data;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return switch (data.template) {
      CardTemplate.minimal => MinimalCard(data: data, scale: scale),
      CardTemplate.bold => BoldCard(data: data, scale: scale),
      CardTemplate.glass => GlassCard(data: data, scale: scale),
    };
  }
}
