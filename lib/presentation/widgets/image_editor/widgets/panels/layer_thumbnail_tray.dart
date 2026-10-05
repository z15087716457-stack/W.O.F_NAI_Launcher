import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import '../../core/history_manager.dart';
import '../../layers/layer.dart';
import 'inpaint_controls.dart';

/// 右下角紧凑图层缩略图托盘
/// 官方比例的缩略图、增删和排序；普通编辑器默认展开。
class EditorLayerTray extends StatefulWidget {
  const EditorLayerTray({
    super.key,
    required this.state,
    this.onOpenDetails,
    this.detailsOpen = false,
    this.inpaint = false,
    this.onAdd3dLayer,
    this.onEdit3dLayer,
    this.virtualMaskRects = const [],
    this.onSelectLayer,
    this.beforeLayerMutation,
    this.initiallyExpanded,
  });

  final EditorState state;

  /// 打开/关闭详细图层面板（flyout）的回调
  final VoidCallback? onOpenDetails;

  /// 详细面板当前是否展开（用于计数按钮高亮）
  final bool detailsOpen;
  final bool inpaint;
  final VoidCallback? onAdd3dLayer;
  final ValueChanged<Layer>? onEdit3dLayer;
  final List<Rect> virtualMaskRects;
  final Future<void> Function(Layer)? onSelectLayer;
  final Future<bool> Function()? beforeLayerMutation;
  final bool? initiallyExpanded;

  @override
  State<EditorLayerTray> createState() => _EditorLayerTrayState();
}

class _EditorLayerTrayState extends State<EditorLayerTray> {
  bool _expanded = false;

  /// 缩略图更新防抖计时器（与 LayerPanel 相同的更新策略）
  Timer? _thumbnailUpdateTimer;
  Size? _thumbnailCanvasSize;

  EditorState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ?? !widget.inpaint;
    widget.state.layerManager.addListener(_onLayerContentChanged);
    widget.state.addListener(_onEditorChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThumbnails();
    });
  }

  @override
  void dispose() {
    widget.state.layerManager.removeListener(_onLayerContentChanged);
    widget.state.removeListener(_onEditorChanged);
    _thumbnailUpdateTimer?.cancel();
    super.dispose();
  }

  void _onLayerContentChanged() {
    _scheduleThumbnailUpdate();
  }

  void _onEditorChanged() {
    if (_thumbnailCanvasSize != _state.canvasSize) {
      _scheduleThumbnailUpdate();
    }
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
    if (_thumbnailCanvasSize != canvasSize) {
      for (final layer in _state.layerManager.layers) {
        layer.markNeedsUpdate();
      }
      _thumbnailCanvasSize = canvasSize;
    }
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

  bool _canMoveInpaintLayer(Layer layer, int direction) {
    final layers = _state.layerManager.layers;
    final index = layers.indexOf(layer);
    final target = index + direction;
    return index >= 0 &&
        target >= 0 &&
        target < layers.length &&
        layers[target].inpaintMask == layer.inpaintMask;
  }

  Future<void> _mutateLayers(VoidCallback action) async {
    if (widget.beforeLayerMutation != null &&
        !await widget.beforeLayerMutation!()) {
      return;
    }
    if (mounted) action();
  }

  Future<void> _moveInpaintLayer(Layer layer, int direction) async {
    if (widget.beforeLayerMutation != null &&
        !await widget.beforeLayerMutation!()) {
      return;
    }
    if (!mounted) return;
    if (!_canMoveInpaintLayer(layer, direction)) return;
    final index = _state.layerManager.layers.indexOf(layer);
    _state.historyManager.execute(
      ReorderLayerAction(
        oldIndex: index,
        newIndex: direction > 0 ? index + 2 : index - 1,
      ),
      _state,
    );
  }

  Widget _buildInpaintTray(List<Layer> displayLayers) {
    final l10n = context.l10n;
    final manager = _state.layerManager;
    final scheme = Theme.of(context).colorScheme;
    final autoMaskLayer = manager.layers
        .where((layer) => layer.inpaintMask)
        .firstOrNull;
    final canvas = _state.canvasSize;
    final aspect = canvas.width / canvas.height;
    final thumbSize = aspect >= 1
        ? Size(80, 80 / aspect)
        : Size(80 * aspect, 80);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          InpaintPanel(
            key: const Key('inpaint_layer_panel'),
            width: 94,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InpaintButton(
                          key: const Key('inpaint_add_layer'),
                          size: 24,
                          glyphSize: 16,
                          glyph: 'add',
                          tooltip: l10n.layer_add,
                          onPressed: () => _mutateLayers(
                            () => _state.historyManager.execute(
                              AddInpaintMaskLayerAction(
                                name: l10n.editor_layerName(
                                  manager.layerCount + 1,
                                ),
                                inpaintMask: widget.inpaint,
                              ),
                              _state,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InpaintButton(
                          key: const Key('inpaint_add_3d'),
                          size: 28,
                          glyphSize: 20,
                          glyph: 'cube',
                          tooltip: l10n.model3d_editorTitle,
                          onPressed: widget.onAdd3dLayer,
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.sizeOf(context).height - 220)
                          .clamp(80, 400),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final layer in displayLayers)
                            SizedBox(
                              width: 80,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _InpaintLayerThumb(
                                    layer: layer,
                                    size: thumbSize,
                                    maskColor: _state.maskDisplayColor,
                                    canvasSize: canvas,
                                    maskRects: layer == autoMaskLayer
                                        ? widget.virtualMaskRects
                                        : const [],
                                    onTap:
                                        !widget.inpaint ||
                                            layer.inpaintMask ||
                                            layer.hasModel3d
                                        ? () {
                                            if (widget.onSelectLayer != null) {
                                              unawaited(
                                                widget.onSelectLayer!(layer),
                                              );
                                            } else {
                                              manager.setActiveLayer(layer.id);
                                            }
                                          }
                                        : null,
                                    onDoubleTap: layer.hasModel3d
                                        ? () =>
                                              widget.onEdit3dLayer?.call(layer)
                                        : null,
                                    onDelete:
                                        (widget.inpaint &&
                                                layer.id ==
                                                    _state
                                                        .inpaintSourceLayerId) ||
                                            manager.layerCount < 2
                                        ? null
                                        : () => _mutateLayers(
                                            () => _state.historyManager.execute(
                                              DeleteInpaintLayerAction(
                                                layerId: layer.id,
                                              ),
                                              _state,
                                            ),
                                          ),
                                  ),
                                  SizedBox(
                                    width: thumbSize.width,
                                    height: 20,
                                    child: Material(
                                      color: scheme.surfaceContainerHighest,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InpaintButton(
                                              key: Key(
                                                'inpaint_layer_up_${layer.id}',
                                              ),
                                              size: 20,
                                              glyph: 'up',
                                              tooltip: l10n.layer_moveUp,
                                              onPressed:
                                                  _canMoveInpaintLayer(layer, 1)
                                                  ? () => _moveInpaintLayer(
                                                      layer,
                                                      1,
                                                    )
                                                  : null,
                                            ),
                                            InpaintButton(
                                              key: Key(
                                                'inpaint_layer_down_${layer.id}',
                                              ),
                                              size: 20,
                                              glyph: 'down',
                                              tooltip: l10n.layer_moveDown,
                                              onPressed:
                                                  _canMoveInpaintLayer(
                                                    layer,
                                                    -1,
                                                  )
                                                  ? () => _moveInpaintLayer(
                                                      layer,
                                                      -1,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                    const InpaintGlyph('layers', size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${manager.layerCount}',
                      style: const TextStyle(fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    // 图层结构变化 + 锁定/可见性等 UI 变化 + 活动图层切换
    return ListenableBuilder(
      listenable: Listenable.merge([
        _state.layerManager,
        _state.layerManager.uiUpdateNotifier,
        _state.layerManager.activeLayerNotifier,
        _state,
      ]),
      builder: (context, _) {
        final manager = _state.layerManager;
        final layers = manager.layers;
        // UI index 0 = 顶部图层 = layers.last（与 LayerPanel 一致）
        final displayLayers = layers.reversed.toList();
        return _buildInpaintTray(displayLayers);
      },
    );
  }
}

/// Official tray proportions: 80px long edge, 3px frame, checkerboard and
/// only a delete action plus the noninteractive mask/3D type badge.
class _InpaintLayerThumb extends StatelessWidget {
  const _InpaintLayerThumb({
    required this.layer,
    required this.size,
    required this.canvasSize,
    required this.maskColor,
    required this.maskRects,
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
  });
  final Layer layer;
  final Size size, canvasSize;
  final Color maskColor;
  final List<Rect> maskRects;
  final VoidCallback? onTap, onDoubleTap, onDelete;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: layer.isActiveNotifier,
    builder: (context, active, _) {
      final scheme = Theme.of(context).colorScheme;
      return Tooltip(
        message: layer.name,
        child: GestureDetector(
          key: Key('inpaint_layer_thumb_${layer.id}'),
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? scheme.onSurface : scheme.outlineVariant,
            ),
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  const CustomPaint(painter: _InpaintCheckerboardPainter()),
                  if (layer.thumbnail != null)
                    RawImage(
                      image: layer.thumbnail,
                      fit: BoxFit.fill,
                      color: layer.inpaintMask ? maskColor : null,
                      colorBlendMode: layer.inpaintMask
                          ? BlendMode.srcIn
                          : null,
                    ),
                  if (maskRects.isNotEmpty)
                    CustomPaint(
                      painter: _InpaintThumbnailOutpaintPainter(
                        maskRects,
                        canvasSize,
                        maskColor,
                      ),
                    ),
                  if (layer.inpaintMask || layer.hasModel3d)
                    Positioned(
                      left: 1,
                      bottom: 1,
                      child: IgnorePointer(
                        child: Container(
                          key: Key('inpaint_layer_type_${layer.id}'),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: layer.hasModel3d
                                ? const InpaintGlyph('cube', size: 12)
                                : const InpaintGlyph('mask_badge', size: 12),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Material(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(3),
                      child: InpaintButton(
                        key: Key('inpaint_layer_delete_${layer.id}'),
                        size: 20,
                        glyphSize: 14,
                        glyph: 'clear',
                        tooltip: context.l10n.layer_delete,
                        onPressed: onDelete,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _InpaintCheckerboardPainter extends CustomPainter {
  const _InpaintCheckerboardPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()..color = const Color(0xFFA0A0A0);
    for (var y = 0.0; y < size.height; y += 8) {
      for (var x = 0.0; x < size.width; x += 8) {
        if (((x / 8).floor() + (y / 8).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InpaintCheckerboardPainter old) => false;
}

class _InpaintThumbnailOutpaintPainter extends CustomPainter {
  const _InpaintThumbnailOutpaintPainter(
    this.rects,
    this.canvasSize,
    this.color,
  );
  final List<Rect> rects;
  final Size canvasSize;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(
      size.width / canvasSize.width,
      size.height / canvasSize.height,
    );
    final paint = Paint()..color = color;
    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InpaintThumbnailOutpaintPainter old) =>
      old.rects != rects || old.canvasSize != canvasSize || old.color != color;
}
