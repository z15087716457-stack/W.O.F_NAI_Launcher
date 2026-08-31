import 'package:flutter/material.dart';

import '../../../widgets/prompt/blocks/prompt_block_colors.dart';

class PromptBlockColorPicker extends StatelessWidget {
  const PromptBlockColorPicker({
    super.key,
    required this.selectedColor,
    required this.onChanged,
  });

  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in promptBlockColorPalette)
          Semantics(
            label: promptBlockColorToHex(color),
            selected: color.toARGB32() == selectedColor.toARGB32(),
            button: true,
            child: InkWell(
              onTap: () => onChanged(color),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.toARGB32() == selectedColor.toARGB32()
                          ? theme.colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 26, height: 26),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
