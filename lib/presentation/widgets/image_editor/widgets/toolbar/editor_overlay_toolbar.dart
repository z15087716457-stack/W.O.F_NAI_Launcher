import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import '../../tools/tool_base.dart';

/// 编辑器浮层卡片 - 统一悬浮控件外观（半透明、小圆角、细边框）
class EditorOverlayCard extends StatelessWidget {
  const EditorOverlayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// 浮层紧凑图标按钮（34px，圆角 5，支持选中/禁用态）
class EditorOverlayIconButton extends StatelessWidget {
  const EditorOverlayIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.selected = false,
    this.enabled = true,
    this.size = 34,
    this.iconSize = 18,
    this.iconColor,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final bool enabled;
  final double size;
  final double iconSize;

  /// 图标颜色覆盖（默认由 enabled/selected 推导）
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = !enabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : selected
        ? theme.colorScheme.onPrimaryContainer
        : (iconColor ?? theme.colorScheme.onSurface);

    final button = Material(
      color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          width: size,
          height: size,
          child: StudioIcon(icon, size: iconSize, color: color),
        ),
      ),
    );

    final message = tooltip;
    if (message == null || message.isEmpty) {
      return button;
    }
    return Tooltip(message: message, child: button);
  }
}

/// “更多”菜单动作项；列表中的 null 元素渲染为分隔线
class EditorMenuAction {
  const EditorMenuAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.checked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool checked;
}

/// 工具本地化名称（与 DesktopToolbar 保持一致）
String localizedEditorToolName(BuildContext context, EditorTool tool) {
  final l10n = context.l10n;
  return switch (tool.id) {
    'brush' => l10n.editor_toolBrush,
    'eraser' => l10n.editor_toolEraser,
    'fill' => l10n.editor_toolFill,
    'magic_wand' => l10n.editor_toolMagicWand,
    'line' => l10n.editor_toolLine,
    'rect_selection' => l10n.editor_toolRectSelect,
    'ellipse_selection' => l10n.editor_toolEllipseSelect,
    'lasso_selection' => l10n.editor_toolLassoSelect,
    'color_picker' => l10n.editor_toolColorPicker,
    'clone_stamp' => l10n.editor_toolCloneStamp,
    'blur' => l10n.editor_toolBlur,
    _ => tool.name,
  };
}

bool _canClearActiveLayer(EditorState state) {
  final layer = state.layerManager.activeLayer;
  return layer != null && !layer.locked && layer.hasContent;
}

/// 底部居中悬浮水平工具栏
/// 左侧为主工具组，右侧为撤销/重做/清空、缩放与“更多”菜单
class EditorFloatingToolbar extends StatelessWidget {
  const EditorFloatingToolbar({
    super.key,
    required this.state,
    this.allowedToolIds,
    this.onClear,
    this.clearTooltip,
    this.onFillMask,
    this.canFillMask,
    this.fillMaskActive = false,
    this.menuActions = const [],
    this.maxWidth = 720,
  });

  final EditorState state;

  /// 允许展示的工具 id 集合；null 表示全部工具
  final Set<String>? allowedToolIds;

  /// 清空回调；null 时默认执行 [EditorState.clearActiveLayerWithHistory]
  final VoidCallback? onClear;

  /// 清空按钮 tooltip 覆盖（如 inpaint 的重置蒙版语义）
  final String? clearTooltip;

  /// 填充闭合蒙版区域回调（仅 inpaint 提供）
  final VoidCallback? onFillMask;
  final bool Function()? canFillMask;

  /// 填充蒙版模式是否处于激活态（用于高亮）
  final bool fillMaskActive;

  /// “更多”菜单动作项，null 元素渲染为分隔线
  final List<EditorMenuAction?> menuActions;

  /// 工具栏最大宽度；内容超出时内部横向滚动
  final double maxWidth;

  /// 常驻主工具顺序（对齐官方编辑器左组：画笔/橡皮/填充/选区/魔棒）
  static const List<String> _primaryToolOrder = [
    'brush',
    'eraser',
    'fill',
    'rect_selection',
    'ellipse_selection',
    'lasso_selection',
    'magic_wand',
  ];

  List<EditorTool> get _allowedTools {
    if (allowedToolIds == null || allowedToolIds!.isEmpty) {
      return state.tools;
    }
    return state.tools
        .where((tool) => allowedToolIds!.contains(tool.id))
        .toList();
  }

  List<EditorTool> get _primaryTools {
    final byId = {for (final tool in _allowedTools) tool.id: tool};
    return [
      for (final id in _primaryToolOrder)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<EditorTool> get _overflowTools => _allowedTools
      .where((tool) => !_primaryToolOrder.contains(tool.id))
      .toList();

  String _toolTooltip(BuildContext context, EditorTool tool) {
    final keyLabel = tool.shortcutKey?.keyLabel ?? '';
    final suffix = keyLabel.isNotEmpty ? ' (${keyLabel.toUpperCase()})' : '';
    return '${localizedEditorToolName(context, tool)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return EditorOverlayCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主工具组
              ValueListenableBuilder<String?>(
                valueListenable: state.toolNotifier,
                builder: (context, currentToolId, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final tool in _primaryTools)
                        EditorOverlayIconButton(
                          icon: tool.icon,
                          tooltip: _toolTooltip(context, tool),
                          selected: tool.id == currentToolId,
                          onPressed: () => state.setTool(tool),
                        ),
                    ],
                  );
                },
              ),
              const _ToolbarDivider(),
              // 撤销/重做/清空/填充闭合区域
              ListenableBuilder(
                listenable: Listenable.merge([
                  state.historyManager,
                  state.layerManager,
                ]),
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EditorOverlayIconButton(
                        icon: Icons.undo,
                        tooltip: l10n.editor_undo,
                        enabled: state.canUndo,
                        onPressed: state.undo,
                      ),
                      EditorOverlayIconButton(
                        icon: Icons.redo,
                        tooltip: l10n.editor_redo,
                        enabled: state.canRedo,
                        onPressed: state.redo,
                      ),
                      EditorOverlayIconButton(
                        icon: Icons.delete_outline,
                        tooltip: clearTooltip ?? l10n.editor_clearLayer,
                        enabled: _canClearActiveLayer(state),
                        onPressed: onClear ?? state.clearActiveLayerWithHistory,
                      ),
                      if (onFillMask != null)
                        EditorOverlayIconButton(
                          icon: Icons.format_color_fill,
                          tooltip: l10n.editor_fillClosedRegion,
                          enabled: canFillMask?.call() ?? false,
                          selected: fillMaskActive,
                          onPressed: onFillMask!,
                        ),
                    ],
                  );
                },
              ),
              const _ToolbarDivider(),
              // 缩放控制
              ListenableBuilder(
                listenable: state.canvasController,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EditorOverlayIconButton(
                        icon: Icons.zoom_out,
                        tooltip: l10n.editor_zoomOut,
                        onPressed: state.canvasController.zoomOut,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${(state.canvasController.scale * 100).round()}%',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      EditorOverlayIconButton(
                        icon: Icons.zoom_in,
                        tooltip: l10n.editor_zoomIn,
                        onPressed: state.canvasController.zoomIn,
                      ),
                      EditorOverlayIconButton(
                        icon: Icons.fit_screen,
                        tooltip: l10n.editor_fitToWindow,
                        onPressed: () => state.canvasController.fitToViewport(
                          state.canvasSize,
                        ),
                      ),
                      // 旋转/镜像状态指示（保留原状态栏信息）
                      if (state.canvasController.rotation != 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '${(state.canvasController.rotation * 180 / 3.14159265359).round()}°',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      if (state.canvasController.isMirroredHorizontally)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: StudioIcon(
                            Icons.flip,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                    ],
                  );
                },
              ),
              // 更多：溢出工具 + 动作菜单
              if (_overflowTools.isNotEmpty || menuActions.isNotEmpty) ...[
                const _ToolbarDivider(),
                _OverflowMenuButton(toolbar: this),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
    );
  }
}

/// “更多”弹出菜单按钮：先列出溢出工具，再列出动作项
class _OverflowMenuButton extends StatelessWidget {
  const _OverflowMenuButton({required this.toolbar});

  final EditorFloatingToolbar toolbar;

  Future<void> _showMenu(BuildContext context, String? currentToolId) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonBox = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay),
        buttonBox.localToGlobal(
          buttonBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final overflow = toolbar._overflowTools;
    final actions = toolbar.menuActions;
    final items = <PopupMenuEntry<Object>>[
      for (final tool in overflow)
        PopupMenuItem<Object>(
          value: tool,
          height: 40,
          child: _MenuToolRow(tool: tool, selected: tool.id == currentToolId),
        ),
      if (overflow.isNotEmpty && actions.isNotEmpty) const PopupMenuDivider(),
      for (final action in actions)
        if (action == null)
          const PopupMenuDivider()
        else
          PopupMenuItem<Object>(
            value: action,
            enabled: action.enabled,
            height: 40,
            child: _MenuActionRow(action: action),
          ),
    ];

    final result = await showMenu<Object>(
      context: context,
      position: position,
      items: items,
    );
    if (result is EditorTool) {
      toolbar.state.setTool(result);
    } else if (result is EditorMenuAction) {
      result.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: toolbar.state.toolNotifier,
      builder: (context, currentToolId, _) {
        final overflowActive = toolbar._overflowTools.any(
          (tool) => tool.id == currentToolId,
        );
        return Builder(
          builder: (buttonContext) => EditorOverlayIconButton(
            icon: Icons.more_horiz,
            tooltip: MaterialLocalizations.of(buttonContext).moreButtonTooltip,
            iconColor: overflowActive ? theme.colorScheme.primary : null,
            onPressed: () => _showMenu(buttonContext, currentToolId),
          ),
        );
      },
    );
  }
}

class _MenuToolRow extends StatelessWidget {
  const _MenuToolRow({required this.tool, required this.selected});

  final EditorTool tool;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Row(
      children: [
        StudioIcon(tool.icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            localizedEditorToolName(context, tool),
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
        if (selected) StudioIcon(Icons.check, size: 16, color: color),
      ],
    );
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({required this.action});

  final EditorMenuAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = action.enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return Row(
      children: [
        StudioIcon(action.icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            action.label,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
        if (action.checked)
          StudioIcon(Icons.check, size: 16, color: theme.colorScheme.primary),
      ],
    );
  }
}
