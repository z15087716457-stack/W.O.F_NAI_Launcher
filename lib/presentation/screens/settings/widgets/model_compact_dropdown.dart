import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  });
  final T value;
  final List<ModelDropdownChoice<T>> choices;
  final ValueChanged<T>? onChanged;

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
        maxHeight: math.max(40, overlay.size.height - rect.bottom - 16),
      ),
      elevation: 5,
      color: colors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      menuPadding: const EdgeInsets.symmetric(vertical: 5),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      requestFocus: true,
      items: [
        for (final choice in choices)
          PopupMenuItem<T>(
            value: choice.value,
            enabled: choice.enabled,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: choice.value == value
                    ? colors.onSurface.withValues(alpha: .08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                choice.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    final label =
        choices.where((c) => c.value == value).firstOrNull?.label ?? '';
    return Builder(
      builder: (context) => TextButton(
        onPressed: onChanged == null ? null : () => _open(context),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: colors.onSurface,
          backgroundColor: colors.surfaceContainerHighest.withValues(
            alpha: .55,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          minimumSize: const Size(0, 33),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: Theme.of(context).textTheme.bodySmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.expand_more, size: 15),
          ],
        ),
      ),
    );
  }
}
