import 'package:flutter/material.dart';
import '../../features/cards/domain/card_data.dart';
import 'card_widget.dart';

class TemplatePicker extends StatelessWidget {
  const TemplatePicker({
    super.key,
    required this.selected,
    required this.baseData,
    required this.onSelect,
  });

  final CardTemplate selected;
  final CardData baseData;
  final void Function(CardTemplate) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: CardTemplate.values.map((t) {
          final isSelected = t == selected;
          final preview = baseData.copyWith(template: t);
          return GestureDetector(
            onTap: () => onSelect(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: CardWidget(data: preview, scale: 0.38),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        t.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
