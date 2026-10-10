import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../widgets/prompt/blocks/prompt_block_colors.dart';

class PromptBlockColorPicker extends StatelessWidget {
  const PromptBlockColorPicker({
    super.key,
    required this.selectedColor,
    required this.onChanged,
    this.inline = false,
    this.palette = promptBlockColorPalette,
  });

  final Color selectedColor;
  final ValueChanged<Color> onChanged;
  final bool inline;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (inline) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final color in palette)
            Semantics(
              label: promptBlockColorToHex(color),
              selected: color.toARGB32() == selectedColor.toARGB32(),
              button: true,
              child: InkWell(
                key: ValueKey(
                  'prompt-block-color-option-${promptBlockColorToHex(color)}',
                ),
                onTap: () => onChanged(color),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: color.toARGB32() == selectedColor.toARGB32()
                        ? [
                            BoxShadow(color: color, spreadRadius: 4),
                            BoxShadow(
                              color: theme.colorScheme.surface,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
        ],
      );
    }
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
              for (final color in palette)
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
