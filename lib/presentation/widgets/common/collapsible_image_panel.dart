import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../screens/generation/widgets/generation_sidebar_style.dart';

/// A common collapsible panel with optional background image support.
///
/// Used for Precise Reference, Vibe Transfer, and Img2Img panels.
/// 官网式扁平卡片：无阴影、细描边、标题行紧凑单行。
class CollapsibleImagePanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? iconAsset;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? backgroundImage;
  final bool hasData;
  final Widget? badge;
  final Widget? trailing;
  final List<Widget>? headerActions;
  final Widget child;

  const CollapsibleImagePanel({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    required this.isExpanded,
    required this.onToggle,
    this.backgroundImage,
    this.hasData = false,
    this.badge,
    this.trailing,
    this.headerActions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBackground = hasData && !isExpanded;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          // Background Image Layer
          if (showBackground && backgroundImage != null)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CollapsedBackgroundImage(child: backgroundImage!),
                  // Dark Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content Layer
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              InkWell(
                onTap: onToggle,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GenSidebarStyle.cardGutter,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _buildHeaderIcon(theme, showBackground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GenSidebarStyle.sectionTitle(theme)
                                  .copyWith(
                                    color: showBackground
                                        ? Colors.white
                                        : hasData
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: showBackground
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.55,
                                        ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Header actions (e.g. export button)
                      if (headerActions != null &&
                          headerActions!.isNotEmpty) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: headerActions!,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (trailing != null) ...[
                        trailing!,
                        const SizedBox(width: 4),
                      ],
                      if (hasData && badge != null) ...[
                        badge!,
                        const SizedBox(width: 6),
                      ],
                      StudioIcon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: showBackground
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Content
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: child,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(ThemeData theme, bool showBackground) {
    final color = showBackground
        ? Colors.white
        : hasData
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final asset = iconAsset;
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return StudioIcon(icon, size: 22, color: color);
  }
}

/// 官网式行内方形小图标按钮：用于 [CollapsibleImagePanel] 的 headerActions。
/// 支持 Material 图标或 `assets/icons/` 下的官方 SVG（`iconAsset`）。
class PanelHeaderIconButton extends StatelessWidget {
  const PanelHeaderIconButton({
    super.key,
    this.icon,
    this.iconAsset,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.highlighted = false,
    this.color,
  });

  final IconData? icon;
  final String? iconAsset;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 选中态（如当前工作流模式已激活）显示 primary 容器底色。
  final bool selected;

  /// 高亮态（如文件拖入悬停）显示 primary 描边。
  final bool highlighted;

  /// 前景色；未指定时按 selected 取主题槽位。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : (color ?? theme.colorScheme.onSurfaceVariant);
    final background = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    Widget iconWidget;
    final asset = iconAsset;
    if (asset != null) {
      iconWidget = SvgPicture.asset(
        asset,
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
      );
    } else {
      iconWidget = StudioIcon(icon, size: 15, color: foreground);
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: highlighted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  )
                : null,
            alignment: Alignment.center,
            child: iconWidget,
          ),
        ),
      ),
    );
  }
}

class _CollapsedBackgroundImage extends StatelessWidget {
  const _CollapsedBackgroundImage({required this.child});

  static const double _previewHeight = 180;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return child;
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: width,
            maxWidth: width,
            minHeight: _previewHeight,
            maxHeight: _previewHeight,
            child: SizedBox(width: width, height: _previewHeight, child: child),
          ),
        );
      },
    );
  }
}
