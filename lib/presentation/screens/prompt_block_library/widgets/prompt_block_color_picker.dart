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
    MenuController? menuController;
    return MenuAnchor(
      key: const Key('prompt-block-color-picker'),
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        maximumSize: WidgetStatePropertyAll(Size(280, 300)),
      ),
      builder: (context, controller, child) {
        menuController = controller;
        return OutlinedButton.icon(
          key: const Key('prompt-block-color-trigger'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: _buildSwatch(theme, selectedColor, size: 20),
          label: Text(promptBlockColorToHex(selectedColor)),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: 248,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final color in promptBlockColorPalette)
                _buildColorOption(
                  theme,
                  color,
                  onClose: () => menuController?.close(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(
    ThemeData theme,
    Color color, {
    required VoidCallback onClose,
  }) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    return Semantics(
      label: promptBlockColorToHex(color),
      selected: isSelected,
      button: true,
      child: InkWell(
        key: ValueKey(
          'prompt-block-color-option-${promptBlockColorToHex(color)}',
        ),
        borderRadius: BorderRadius.circular(7),
        onTap: () {
          onChanged(color);
          onClose();
        },
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(ThemeData theme, Color color, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
    );
  }
}
