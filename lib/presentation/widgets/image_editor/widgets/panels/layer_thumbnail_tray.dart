import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import '../../core/history_manager.dart';
import '../../layers/layer.dart';
import '../toolbar/editor_overlay_toolbar.dart';
import 'inpaint_controls.dart';

/// 右下角紧凑图层缩略图托盘
/// 复用 Layer.thumbnail 缓存缩略图；详细操作通过 onOpenDetails 打开完整图层面板
class EditorLayerTray extends StatefulWidget {
  const EditorLayerTray({
    super.key,
    required this.state,
    this.onOpenDetails,
    this.detailsOpen = false,
    this.inpaint = false,
    this.onAdd3dLayer,
    this.onEdit3dLayer,
  });

  final EditorState state;

  /// 打开/关闭详细图层面板（flyout）的回调
  final VoidCallback? onOpenDetails;

  /// 详细面板当前是否展开（用于计数按钮高亮）
  final bool detailsOpen;
  final bool inpaint;
  final VoidCallback? onAdd3dLayer;
  final ValueChanged<Layer>? onEdit3dLayer;

  @override
  State<EditorLayerTray> createState() => _EditorLayerTrayState();
}

class _EditorLayerTrayState extends State<EditorLayerTray> {
  bool _expanded = false;

  /// 缩略图更新防抖计时器（与 LayerPanel 相同的更新策略）
  Timer? _thumbnailUpdateTimer;

  EditorState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    widget.state.layerManager.addListener(_onLayerContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThumbnails();
    });
  }

  @override
  void dispose() {
    widget.state.layerManager.removeListener(_onLayerContentChanged);
    _thumbnailUpdateTimer?.cancel();
    super.dispose();
  }

  void _onLayerContentChanged() {
    _scheduleThumbnailUpdate();
  }

  void _scheduleThumbnailUpdate() {
    _thumbnailUpdateTimer?.cancel();
    _thumbnailUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _updateThumbnails();
      }
    });
  }

  Future<void> _updateThumbnails() async {
    final canvasSize = _state.canvasSize;
    final layersToUpdate = _state.layerManager.layers
        .where((layer) => layer.needsThumbnailUpdate)
        .toList();

    if (layersToUpdate.isEmpty) return;

    try {
      const batchSize = 2;
      for (int i = 0; i < layersToUpdate.length; i += batchSize) {
        if (!mounted) return;
        final batch = layersToUpdate.skip(i).take(batchSize);
        await Future.wait(
          batch.map((layer) => layer.updateThumbnail(canvasSize)),
          eagerError: false,
        );
        if (!mounted) return;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      AppLogger.w('Thumbnail update failed: $e', 'ImageEditor');
    }
  }

  void _moveInpaintLayer(Layer layer, int direction) {
    final index = _state.layerManager.layers.indexOf(layer);
    _state.historyManager.execute(
      ReorderLayerAction(
        oldIndex: index,
        newIndex: direction > 0 ? index + 2 : index - 1,
      ),
      _state,
    );
  }

  void _showLayerMenu(BuildContext context, Layer layer, Offset position) {
    final l10n = context.l10n;
    final manager = _state.layerManager;
    final layers = manager.layers;
    final index = layers.indexWhere((l) => l.id == layer.id);

    // 右键/长按时先选中该图层，merge 等操作针对活动图层
    manager.setActiveLayer(layer.id);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    unawaited(
      showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromPoints(position, position),
          Offset.zero & overlay.size,
        ),
        items: [
          _layerMenuItem(
            value: 'visibility',
            icon: layer.visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: l10n.layer_visibility,
          ),
          _layerMenuItem(
            value: 'lock',
            icon: layer.locked ? Icons.lock_open : Icons.lock_outline,
            label: l10n.layer_lock,
          ),
          _layerMenuItem(
            value: 'duplicate',
            icon: Icons.copy_outlined,
            label: l10n.layer_duplicate,
          ),
          const PopupMenuDivider(),
          _layerMenuItem(
            value: 'moveUp',
            icon: Icons.keyboard_arrow_up,
            label: l10n.layer_moveUp,
            enabled: index >= 0 && index < layers.length - 1,
          ),
          _layerMenuItem(
            value: 'moveDown',
            icon: Icons.keyboard_arrow_down,
            label: l10n.layer_moveDown,
            enabled: index > 0,
          ),
          _layerMenuItem(
            value: 'merge',
            icon: Icons.merge,
            label: l10n.layer_mergeDown,
            enabled: index > 0,
          ),
          const PopupMenuDivider(),
          _layerMenuItem(
            value: 'delete',
            icon: Icons.delete_outline,
            label: l10n.layer_delete,
            enabled: layers.length > 1,
          ),
        ],
      ).then((value) {
        if (!mounted || value == null) return;
        switch (value) {
          case 'visibility':
            manager.toggleVisibility(layer.id);
          case 'lock':
            manager.toggleLock(layer.id);
          case 'duplicate':
            manager.duplicateLayer(layer.id);
          case 'moveUp':
            manager.moveLayerUp(layer.id);
          case 'moveDown':
            manager.moveLayerDown(layer.id);
          case 'merge':
            manager.mergeDown();
          case 'delete':
            manager.removeLayer(layer.id);
        }
      }),
    );
  }

  PopupMenuItem<String> _layerMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool enabled = true,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // 图层结构变化 + 锁定/可见性等 UI 变化 + 活动图层切换
    return ListenableBuilder(
      listenable: Listenable.merge([
        _state.layerManager,
        _state.layerManager.uiUpdateNotifier,
        _state.layerManager.activeLayerNotifier,
      ]),
      builder: (context, _) {
        final manager = _state.layerManager;
        final layers = manager.layers;
        // UI index 0 = 顶部图层 = layers.last（与 LayerPanel 一致）
        final displayLayers = layers.reversed.toList();
        final activeId = manager.activeLayerId;
        final activeIndex = layers.indexWhere((l) => l.id == activeId);
        final canMoveUp = activeIndex >= 0 && activeIndex < layers.length - 1;
        final canMoveDown = activeIndex > 0;
        final canDelete = layers.length > 1 && activeId != null;

        if (widget.inpaint) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_expanded) ...[
                InpaintPanel(
                  width: 92,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            InpaintButton(
                              size: 38,
                              icon: Icons.add,
                              glyph: 'add',
                              tooltip: l10n.layer_add,
                              onPressed: () {
                                _state.historyManager.execute(
                                  AddInpaintMaskLayerAction(
                                    name: l10n.editor_layerName(
                                      manager.layerCount + 1,
                                    ),
                                  ),
                                  _state,
                                );
                              },
                            ),
                            InpaintButton(
                              size: 38,
                              icon: Icons.view_in_ar_outlined,
                              glyph: 'cube',
                              key: const Key('inpaint_add_3d'),
                              tooltip: l10n.model3d_editorTitle,
                              onPressed: widget.onAdd3dLayer,
                            ),
                          ],
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (final layer in displayLayers) ...[
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onDoubleTap: layer.hasModel3d
                                            ? () => widget.onEdit3dLayer?.call(
                                                layer,
                                              )
                                            : null,
                                        child: _LayerThumbTile(
                                          layer: layer,
                                          onTap: layer.inpaintMask
                                              ? () => manager.setActiveLayer(
                                                  layer.id,
                                                )
                                              : () {},
                                        ),
                                      ),
                                      Positioned(
                                        right: -3,
                                        top: -3,
                                        child: InpaintButton(
                                          size: 24,
                                          icon: Icons.delete_outline,
                                          glyph: 'clear',
                                          tooltip: l10n.layer_delete,
                                          onPressed:
                                              layer.id ==
                                                  _state.inpaintSourceLayerId
                                              ? null
                                              : () => _state.historyManager
                                                    .execute(
                                                      DeleteLayerAction(
                                                        layerId: layer.id,
                                                      ),
                                                      _state,
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        left: -3,
                                        bottom: -3,
                                        child: InpaintButton(
                                          size: 24,
                                          icon: layer.visible
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          tooltip: l10n.layer_visibility,
                                          onPressed: () => manager
                                              .toggleVisibility(layer.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _TrayMiniButton(
                                        icon: Icons.keyboard_arrow_up,
                                        tooltip: l10n.layer_moveUp,
                                        enabled:
                                            layers.indexOf(layer) <
                                            layers.length - 1,
                                        onPressed: () =>
                                            _moveInpaintLayer(layer, 1),
                                      ),
                                      _TrayMiniButton(
                                        icon: Icons.keyboard_arrow_down,
                                        tooltip: l10n.layer_moveDown,
                                        enabled: layers.indexOf(layer) > 0,
                                        onPressed: () =>
                                            _moveInpaintLayer(layer, -1),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              InpaintPanel(
                child: Tooltip(
                  key: const Key('inpaint_layers'),
                  message: l10n.editor_layers,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const InpaintGlyph('layers', size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${layers.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorOverlayCard(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditorOverlayIconButton(
                    icon: Icons.add,
                    tooltip: l10n.layer_add,
                    onPressed: () => manager.addLayer(
                      name: l10n.editor_layerName(manager.layerCount + 1),
                    ),
                  ),
                  if (displayLayers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final layer in displayLayers)
                              Padding(
                                key: ValueKey(layer.id),
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _LayerThumbTile(
                                  layer: layer,
                                  onTap: () => manager.setActiveLayer(layer.id),
                                  onShowMenu: (position) =>
                                      _showLayerMenu(context, layer, position),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 活动图层快捷操作：上移 / 下移 / 删除
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TrayMiniButton(
                          icon: Icons.keyboard_arrow_up,
                          tooltip: l10n.layer_moveUp,
                          enabled: canMoveUp,
                          onPressed: () => manager.moveLayerUp(activeId!),
                        ),
                        _TrayMiniButton(
                          icon: Icons.keyboard_arrow_down,
                          tooltip: l10n.layer_moveDown,
                          enabled: canMoveDown,
                          onPressed: () => manager.moveLayerDown(activeId!),
                        ),
                        _TrayMiniButton(
                          icon: Icons.delete_outline,
                          tooltip: l10n.layer_delete,
                          enabled: canDelete,
                          onPressed: () => manager.removeLayer(activeId!),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 图层计数 + 详细面板开关
            EditorOverlayCard(
              padding: EdgeInsets.zero,
              child: Tooltip(
                message: l10n.editor_layers,
                child: Material(
                  color: widget.detailsOpen
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: widget.onOpenDetails,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers,
                            size: 15,
                            color: widget.detailsOpen
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${layers.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.detailsOpen
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 托盘内单个图层缩略图
class _LayerThumbTile extends StatelessWidget {
  const _LayerThumbTile({
    required this.layer,
    required this.onTap,
    this.onShowMenu,
  });

  final Layer layer;
  final VoidCallback onTap;
  final ValueChanged<Offset>? onShowMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: layer.isActiveNotifier,
      builder: (context, isActive, _) {
        return Tooltip(
          message: layer.name,
          child: GestureDetector(
            onTap: onTap,
            onSecondaryTapUp: (details) =>
                onShowMenu?.call(details.globalPosition),
            onLongPressStart: (details) =>
                onShowMenu?.call(details.globalPosition),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                  width: isActive ? 2 : 1,
                ),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (layer.thumbnail != null)
                    Opacity(
                      opacity: layer.visible ? 1.0 : 0.3,
                      child: RawImage(
                        image: layer.thumbnail,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Icon(
                      Icons.image_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  if (!layer.visible)
                    Center(
                      child: Icon(
                        Icons.visibility_off,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (layer.locked)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Icon(
                        Icons.lock,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (layer.hasModel3d)
                    Positioned(
                      left: 1,
                      top: 1,
                      child: Icon(
                        Icons.view_in_ar,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 托盘底部迷你操作按钮（24px）
class _TrayMiniButton extends StatelessWidget {
  const _TrayMiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return EditorOverlayIconButton(
      icon: icon,
      tooltip: tooltip,
      enabled: enabled,
      onPressed: onPressed,
      size: 24,
      iconSize: 14,
    );
  }
}
