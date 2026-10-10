import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import 'generation_sidebar_style.dart';

/// Compact controls shared by the canvas popover and enhancement panel.
abstract final class UpscaleControlStyle {
  static TextStyle label(ThemeData theme) =>
      theme.textTheme.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: theme.colorScheme.onSurface,
      );

  static TextStyle caption(ThemeData theme) => label(
    theme,
  ).copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant);

  static Color track(ThemeData theme) => Color.alphaBlend(
    theme.colorScheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? .025 : .075,
    ),
    GenSidebarStyle.panelSurface(theme),
  );

  static Color selected(ThemeData theme) => theme.brightness == Brightness.dark
      ? Color.alphaBlend(
          theme.colorScheme.onSurface.withValues(alpha: .12),
          theme.colorScheme.surface,
        )
      : theme.colorScheme.surface;
}

class UpscaleChoiceBar<T> extends StatelessWidget {
  const UpscaleChoiceBar({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.equalWidths = true,
  });

  final List<({T value, String label, IconData? icon})> choices;
  final T selected;
  final ValueChanged<T>? onSelected;
  final bool equalWidths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: UpscaleControlStyle.track(theme),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GenSidebarStyle.border(theme)),
      ),
      child: Row(
        mainAxisSize: equalWidths ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final choice in choices)
            Flexible(
              flex: equalWidths ? 1 : 0,
              fit: equalWidths ? FlexFit.tight : FlexFit.loose,
              child: Container(
                key: ValueKey('upscale-choice-${choice.value}'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: selected == choice.value
                        ? GenSidebarStyle.border(theme).withValues(alpha: .7)
                        : Colors.transparent,
                  ),
                ),
                child: SidebarSegmentButton(
                  selected: selected == choice.value,
                  backgroundColor: selected == choice.value
                      ? UpscaleControlStyle.selected(theme)
                      : Colors.transparent,
                  onPressed: onSelected == null
                      ? null
                      : () => onSelected!(choice.value),
                  padding: EdgeInsets.symmetric(
                    horizontal: equalWidths ? 4 : 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (choice.icon != null) ...[
                        Icon(choice.icon, size: 14),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          choice.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: UpscaleControlStyle.label(theme).copyWith(
                            height: 1.1,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: onSelected == null
                                  ? .4
                                  : selected == choice.value
                                  ? 1
                                  : .7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
