import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'settings_ui_theme.dart';
import 'settings_hover_line.dart';

const modelMenuRadius = BorderRadius.all(Radius.circular(12));
const modelMenuShape = RoundedRectangleBorder(borderRadius: modelMenuRadius);

class ModelDropdownChoice<T> {
  const ModelDropdownChoice(this.value, this.label, {this.enabled = true});
  final T value;
  final String label;
  final bool enabled;
}

/// A rounded menu anchored below the field, without route animations or
/// selected-item centering (which makes the stock dropdown overlap its field).
class ModelCompactDropdown<T> extends StatelessWidget {
  const ModelCompactDropdown({
    super.key,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.compact = false,
    this.decoration,
    this.textStyle,
    this.hint = '',
  });
  final T? value;
  final List<ModelDropdownChoice<T>> choices;
  final ValueChanged<T>? onChanged;
  final bool compact;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final String hint;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = offset & box.size;
    final colors = Theme.of(context).colorScheme;
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(rect.left, rect.bottom + 4, rect.width, 0),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: rect.width,
        maxWidth: rect.width,
        maxHeight: math.min(360, math.max(40, overlay.size.height - 32)),
      ),
      elevation: 3,
      shadowColor: colors.shadow.withValues(alpha: .14),
      color: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: modelMenuShape,
      clipBehavior: Clip.antiAlias,
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      requestFocus: true,
      items: [
        for (final choice in choices)
          PopupMenuItem<T>(
            value: choice.value,
            enabled: choice.enabled,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: choice.value == value
                    ? colors.primary.withValues(alpha: .08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                choice.label,
                style: (textStyle ?? Theme.of(context).textTheme.bodySmall)
                    ?.copyWith(
                      color: choice.enabled
                          ? colors.onSurface
                          : colors.onSurfaceVariant.withValues(alpha: .4),
                    ),
              ),
            ),
          ),
      ],
    );
    if (selected != null && context.mounted) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canChoose = onChanged != null && choices.isNotEmpty;
    final label =
        choices.where((c) => c.value == value).firstOrNull?.label ?? hint;
    return Builder(
      builder: (context) {
        final button = TextButton(
          onPressed: canChoose ? () => _open(context) : null,
          style:
              TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: colors.onSurface,
                backgroundColor: decoration != null
                    ? Colors.transparent
                    : colors.surfaceContainerHighest.withValues(alpha: .55),
                padding: decoration != null
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 10,
                        vertical: compact ? 6 : 9,
                      ),
                minimumSize: Size(
                  0,
                  decoration != null
                      ? 24
                      : compact
                      ? 28
                      : 33,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle:
                    textStyle ??
                    (compact
                        ? Theme.of(context).textTheme.labelSmall
                        : Theme.of(context).textTheme.bodySmall),
              ).copyWith(
                overlayColor: decoration == null ? null : settingsFieldOverlay,
                iconColor: settingsFieldIconColor(colors),
              ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_more, size: 15),
            ],
          ),
        );
        if (decoration == null) return button;
        final field = InputDecorator(
          decoration: decoration!.copyWith(enabled: canChoose),
          isEmpty: value == null,
          child: button,
        );
        return decoration!.border is UnderlineInputBorder
            ? SettingsHoverLine(enabled: canChoose, child: field)
            : field;
      },
    );
  }
}
