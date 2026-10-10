import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../themes/studio_typography.dart';
import '../../../widgets/common/uiux_prototype_icon.dart';
import 'generation_sidebar_style.dart';

/// Shared desktop-sidebar module. Children own their padding and dividers so
/// model-specific panels can disappear without leaving separators behind.
class GenerationModuleCard extends StatelessWidget {
  const GenerationModuleCard({
    super.key,
    required this.title,
    this.titleTooltip,
    this.count,
    this.headerLeading,
    this.showZeroCount = false,
    this.actions = const [],
    this.headerKey,
    this.children = const [],
  });

  final String title;
  final String? titleTooltip;
  final int? count;
  final Widget? headerLeading;
  final bool showZeroCount;
  final List<Widget> actions;
  final Key? headerKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget titleWidget = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GenSidebarStyle.moduleTitle(theme),
    );
    final tooltip = titleTooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      titleWidget = Tooltip(message: tooltip, child: titleWidget);
    }

    return Material(
      color: GenSidebarStyle.promptSurface(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GenSidebarStyle.moduleRadius),
        side: BorderSide(
          color: GenSidebarStyle.border(theme),
          width: GenSidebarStyle.moduleBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(GenSidebarStyle.moduleBorderWidth),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: StudioTypography.cjk),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: headerKey,
                height: GenSidebarStyle.moduleHeaderHeight,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: GenSidebarStyle.cardGutter,
                    end: GenSidebarStyle.moduleHeaderTrailingInset,
                  ),
                  child: Row(
                    children: [
                      if (headerLeading != null) ...[
                        headerLeading!,
                        const SizedBox(width: GenSidebarStyle.moduleActionGap),
                      ],
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: titleWidget),
                            if (count != null && (count! > 0 || showZeroCount))
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: GenSidebarStyle.moduleActionGap,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth:
                                        GenSidebarStyle.moduleCountMinWidth,
                                  ),
                                  height: GenSidebarStyle.moduleCountHeight,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        GenSidebarStyle.moduleCountPadding,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      GenSidebarStyle.moduleCountRadius,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$count',
                                    style: GenSidebarStyle.moduleCountBadge(
                                      theme,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final action in actions)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: GenSidebarStyle.moduleActionGap,
                          ),
                          child: action,
                        ),
                    ],
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A reference entry owns its top divider and decorative image background.
/// The content can grow beyond the minimum height without a fixed-height clip.
class GenerationModuleRow extends StatelessWidget {
  const GenerationModuleRow({super.key, required this.child, this.background});

  final Widget child;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: GenSidebarStyle.border(Theme.of(context)),
            width: GenSidebarStyle.moduleBorderWidth,
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (background != null)
            Positioned.fill(
              child: IgnorePointer(child: ExcludeSemantics(child: background!)),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: GenSidebarStyle.cardGutter,
              end: GenSidebarStyle.moduleHeaderTrailingInset,
              top: GenSidebarStyle.moduleBorderWidth,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight:
                    GenSidebarStyle.moduleRowMinHeight -
                    GenSidebarStyle.moduleBorderWidth,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact header action shared by character, reference and image modules.
class ModuleHeaderIconButton extends StatelessWidget {
  const ModuleHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      icon: UiuxPrototypeIcon(
        icon,
        size: GenSidebarStyle.moduleActionIconSize,
        source: UiuxPrototypeIconSource.generation,
        strokeWidth: icon == Icons.add ? 2.1 : 1.8,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(
          Size.square(GenSidebarStyle.moduleActionSize),
        ),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(
              alpha: GenSidebarStyle.disabledOpacity,
            );
          }
          return primary ? colors.onSurface : colors.onSurfaceVariant;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return colors.surfaceContainerHigh;
          }
          return Colors.transparent;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              GenSidebarStyle.moduleActionRadius,
            ),
          ),
        ),
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }
}

/// An item in a [SidebarSegmentTrack]. Leave child text/icon colors unset to
/// inherit selection and disabled colors; numeric entries also inherit Mono.
@immutable
class SidebarSegment<T> {
  const SidebarSegment({
    required this.value,
    required this.child,
    this.tooltip,
    this.enabled = true,
    this.numeric = false,
  });

  final T value;
  final Widget child;
  final String? tooltip;
  final bool enabled;
  final bool numeric;
}

/// Neutral track used for orientation, image count and character positioning.
class SidebarSegmentTrack<T> extends StatelessWidget {
  const SidebarSegmentTrack({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.dense = false,
    this.expand = false,
  }) : assert(segments.length > 0);

  final List<SidebarSegment<T>> segments;
  final T? selected;
  final ValueChanged<T> onSelected;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = dense
        ? GenSidebarStyle.segmentDenseHeight
        : GenSidebarStyle.segmentHeight;
    final radius = BorderRadius.circular(GenSidebarStyle.segmentRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GenSidebarStyle.segmentTrackRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GenSidebarStyle.segmentTrackInset),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (var index = 0; index < segments.length; index++) ...[
              if (index > 0) const SizedBox(width: GenSidebarStyle.segmentGap),
              if (expand)
                Expanded(
                  child: _buildSegment(theme, segments[index], height, radius),
                )
              else
                _buildSegment(theme, segments[index], height, radius),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    ThemeData theme,
    SidebarSegment<T> segment,
    double height,
    BorderRadius radius,
  ) {
    final isSelected = segment.value == selected;
    final foreground = GenSidebarStyle.segmentForeground(
      theme,
      selected: isSelected,
      enabled: segment.enabled,
    );
    Widget button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: isSelected && theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: GenSidebarStyle.segmentShadowOpacity,
                  ),
                  offset: const Offset(0, GenSidebarStyle.segmentShadowOffset),
                  blurRadius: GenSidebarStyle.segmentShadowBlur,
                ),
              ]
            : null,
      ),
      child: SidebarSegmentButton(
        selected: isSelected,
        onPressed: segment.enabled ? () => onSelected(segment.value) : null,
        height: height,
        borderRadius: radius,
        padding: EdgeInsets.symmetric(
          horizontal: dense
              ? GenSidebarStyle.segmentDenseHorizontalPadding
              : GenSidebarStyle.segmentHorizontalPadding,
        ),
        backgroundColor: isSelected
            ? theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainer
            : Colors.transparent,
        child: DefaultTextStyle.merge(
          style: GenSidebarStyle.segmentLabel(
            theme,
            selected: isSelected,
            enabled: segment.enabled,
            numeric: segment.numeric,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: foreground,
              size: GenSidebarStyle.segmentIconSize,
            ),
            child: segment.child,
          ),
        ),
      ),
    );
    final tooltip = segment.tooltip;
    if (tooltip != null && tooltip.isNotEmpty) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
