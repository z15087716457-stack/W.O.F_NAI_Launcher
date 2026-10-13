part of '../widgets/image_editor/image_editor_screen.dart';

/// Compatibility entry points retain the existing editor session and exporter.
/// Only the visible shell and its controls come from the locked Tools contract.
class ToolsEditorWiring extends ImageEditorScreen {
  const ToolsEditorWiring({
    super.key,
    super.initialImage,
    super.initialSize,
    super.existingMask,
    super.existingFocusRegion,
    super.showMaskExport,
    super.mode,
    super.title,
  });
}

const _toolsEngineIds = {
  ToolsTool.brush: 'brush',
  ToolsTool.eraser: 'eraser',
  ToolsTool.fill: 'fill',
  ToolsTool.blur: 'blur',
  ToolsTool.stamp: 'clone_stamp',
  ToolsTool.select: 'rect_selection',
  ToolsTool.lasso: 'lasso_selection',
  ToolsTool.picker: 'color_picker',
  ToolsTool.focus: 'inpaint_focus',
};

extension _ToolsEditorSessionWiring on _ImageEditorScreenState {
  ProviderContainer? get _toolsContainer {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return null;
    }
  }

  ToolsExpand get _toolsEdges {
    final frame = _virtualOutpaintFrame;
    return frame == null
        ? const ToolsExpand()
        : ToolsExpand(
            left: -frame.frameLeft,
            top: -frame.frameTop,
            right: frame.frameRight - frame.sourceWidth,
            bottom: frame.frameBottom - frame.sourceHeight,
          );
  }

  Widget _buildToolsEditorLayout() => ListenableBuilder(
    listenable: Listenable.merge([
      _state,
      _state.toolNotifier,
      _state.canvasController,
      _state.layerManager,
      _state.historyManager,
      _state.cursorNotifier,
    ]),
    builder: (context, _) {
      if (_state.layerManager.activeLayer?.hasModel3d == true) {
        return _buildDesktopLayout(MediaQuery.sizeOf(context));
      }
      final tool =
          _toolsEngineIds.entries
              .where((entry) => entry.value == _state.currentTool?.id)
              .firstOrNull
              ?.key ??
          ToolsTool.brush;
      final current = _state.currentTool;
      final canvas = _state.canvasSize;
      final focus = _state.inpaintFocusRegion;
      final container = _toolsContainer;
      _toolsStrength ??=
          container?.exists(generationParamsNotifierProvider) == true
          ? container!.read(generationParamsNotifierProvider).inpaintStrength
          : 1;
      final params =
          _isInpaintMode &&
              container?.exists(generationParamsNotifierProvider) == true
          ? container!.read(generationParamsNotifierProvider)
          : null;
      final subscription =
          params != null &&
              container?.exists(subscriptionNotifierProvider) == true
          ? container!.read(subscriptionNotifierProvider).subscription
          : null;
      final request = params?.copyWith(
        width: _activeCompressionTarget.width,
        height: _activeCompressionTarget.height,
        action: ImageGenerationAction.infill,
        inpaintStrength: _toolsStrength!,
        inpaintFocusRegion: focus == null
            ? null
            : InpaintFocusRegion.fromRect(
                focus,
                context: _state.inpaintContextSize.round(),
              ).clamped(
                _activeCompressionTarget.width,
                _activeCompressionTarget.height,
              ),
      );
      final cost = request == null
          ? null
          : generationRequestCost(
              request,
              const ImageWorkflowState(mode: ImageWorkflowMode.inpaint),
              subscription,
              container!.read(imagesPerRequestProvider),
            );
      return WindowChromePage(
        child: ToolsEditorPage(
          data: ToolsEditorData(
            mode: _isInpaintMode
                ? ToolsEditorMode.inpaint
                : ToolsEditorMode.edit,
            width: _isInpaintMode
                ? _effectiveOutpaintFrame.sourceWidth
                : canvas.width.round(),
            height: _isInpaintMode
                ? _effectiveOutpaintFrame.sourceHeight
                : canvas.height.round(),
            zoom: _state.canvasController.scale,
            canUndo: _state.canUndo,
            canRedo: _state.canRedo,
            dirty:
                _state.historyManager.canUndo || _state.editSelection.changed,
            tool: tool,
            shellShortcuts: false,
            shortcuts: {
              for (final engine in _state.tools)
                if (engine.shortcutKey != null)
                  for (final entry in _toolsEngineIds.entries)
                    if (entry.value == engine.id)
                      entry.key: engine.shortcutKey!.keyLabel,
            },
            options: ToolsToolOptions(
              size: current?.isPaintTool == true && current is! FillTool
                  ? _state.brushSize
                  : null,
              minSize: _isInpaintMode ? 8 : 1,
              opacity: !_isInpaintMode && tool == ToolsTool.brush
                  ? _state.brushOpacity
                  : null,
              tip:
                  !_isInpaintMode &&
                      (tool == ToolsTool.brush || tool == ToolsTool.eraser)
                  ? switch (_state.brushTip) {
                      EditorBrushTip.round => ToolsBrushTip.hard,
                      EditorBrushTip.softRound => ToolsBrushTip.soft,
                      EditorBrushTip.square => ToolsBrushTip.square,
                    }
                  : null,
              pressure: !_isInpaintMode && current?.isPaintTool == true
                  ? _state.pressureSensitivity
                  : null,
              square:
                  _isInpaintMode &&
                      (tool == ToolsTool.brush || tool == ToolsTool.eraser)
                  ? _state.squareBrush
                  : null,
              tolerance: current is FillTool ? current.tolerance : null,
              intensity: current is BlurTool ? current.intensity : null,
            ),
            primary: _state.foregroundColor,
            secondary: _state.backgroundColor,
            mask: ToolsMaskLook(
              color: _state.maskDisplayColor,
              opacity: _state.maskDisplayOpacity,
              pattern: ToolsMaskPattern.values.byName(
                _state.maskDisplayPattern.name,
              ),
              border: _state.maskDisplayBorder,
            ),
            layers: [
              for (final layer in _state.layerManager.layers.reversed)
                ToolsLayer(
                  id: layer.id,
                  name: layer.name,
                  kind: layer.id == _sourceLayerId
                      ? ToolsLayerKind.base
                      : layer.hasModel3d
                      ? ToolsLayerKind.model3d
                      : layer.inpaintMask
                      ? ToolsLayerKind.mask
                      : ToolsLayerKind.paint,
                  locked: layer.locked || layer.id == _sourceLayerId,
                  visible: layer.visible,
                  thumb: layer.baseImageBytes == null
                      ? null
                      : MemoryImage(layer.baseImageBytes!),
                  detail: layer.id == _sourceLayerId
                      ? '${canvas.width.round()} × ${canvas.height.round()}'
                      : null,
                ),
            ],
            layer: _state.layerManager.activeLayerId,
            adjust: _toolsAdjust,
            inpaint: ToolsInpaintInfo(
              strength: _toolsStrength!,
              coverage: _toolsMaskCoverage,
              regions: _toolsMaskRegions,
              focusWidth: focus?.width.round(),
              focusHeight: focus?.height.round(),
              focusContext: _state.inpaintContextSize.round(),
            ),
            expanding: _toolsExpanding,
            expand: _toolsEdges,
            cursor: _state.cursorNotifier.value == null
                ? null
                : _state.canvasController.screenToCanvas(
                    _state.cursorNotifier.value!,
                    canvasSize: _state.canvasSize,
                  ),
            applyCost: cost,
            insufficient:
                cost != null &&
                subscription != null &&
                cost > subscription.anlasBalance,
          ),
          slots: ToolsEditorSlots(canvas: (_) => _buildCanvasArea()),
          actions: ToolsEditorActions(
            onBack: () => Navigator.pop(context),
            onApply: () => unawaited(_toolsApply(false)),
            onApplyAndGenerate: () => unawaited(_toolsApply(true)),
            onZoomIn: _state.canvasController.zoomIn,
            onZoomOut: _state.canvasController.zoomOut,
            onZoomFit: () =>
                _state.canvasController.fitToViewport(_state.canvasSize),
            onUndo: () => unawaited(_applyCanvasModelHistory(redo: false)),
            onRedo: () => unawaited(_applyCanvasModelHistory(redo: true)),
            onDownload: () => unawaited(_downloadCanvasImage()),
            onTool: (value) => _state.setToolById(_toolsEngineIds[value]!),
            onOptions: _toolsOptions,
            onColor: (color, {required secondary}) => secondary
                ? _state.setBackgroundColor(color)
                : _state.setForegroundColor(color),
            onSwapColors: _state.swapColors,
            onMoreColors: _toolsMoreColors,
            onMaskLook: (value) => _state.setMaskAppearance(
              color: value.color,
              opacity: value.opacity,
              pattern: MaskDisplayPattern.values.byName(value.pattern.name),
              border: value.border,
            ),
            onAddLayer: () {
              _state.historyManager.execute(
                AddInpaintMaskLayerAction(
                  name: _isInpaintMode
                      ? context.l10n.editor_maskLayerName
                      : context.l10n.editor_defaultDrawingLayerName,
                  inpaintMask: _isInpaintMode,
                ),
                _state,
              );
              _state.requestUiUpdate();
            },
            onAdd3dLayer: () => unawaited(_addInpaint3dLayer()),
            onSelectLayer: (id) {
              final layer = _state.layerManager.getLayerById(id);
              if (layer != null) {
                _toolsResetAdjust();
                unawaited(_selectEditorLayer(layer));
              }
            },
            onLayerVisible: (id, visible) {
              final layer = _state.layerManager.getLayerById(id);
              if (layer != null && layer.visible != visible) {
                _toolsLayerMutation(
                  id,
                  () => _state.layerManager.toggleVisibility(id),
                );
              }
            },
            onLayerAction: _toolsLayerAction,
            onAdjust: (value) {
              _toolsAdjustPending = _toolsPreviewAdjust(value);
              unawaited(_toolsAdjustPending!);
            },
            onAdjustReset: _toolsResetAdjust,
            onAdjustApply: () => unawaited(_toolsApplyAdjust()),
            onResizeCanvas: () => unawaited(_changeCanvasSize()),
            onClearMask: () {
              _resetInpaintMask();
              unawaited(_toolsMeasureMask());
            },
            onExpanding: (value) =>
                _updateLayoutState(() => _toolsExpanding = value),
            onExpand: (value) => unawaited(_toolsExpandTo(value)),
            onFocusContext: (value) =>
                _state.setInpaintContextSize(value.clamp(0, 256).toDouble()),
            onClearFocus: () => _state.setInpaintFocusRegion(null),
            onInpaintStrength: (value) =>
                _updateLayoutState(() => _toolsStrength = value.clamp(0, 1)),
          ),
        ),
      );
    },
  );

  void _toolsOptions(ToolsToolOptions value) {
    if (value.size != null && value.size!.isFinite) {
      _state.setBrushSize(value.size!.clamp(_isInpaintMode ? 8 : 1, 500));
    }
    if (value.opacity != null && value.opacity!.isFinite) {
      _state.setBrushOpacity(value.opacity!.clamp(0, 1));
    }
    if (value.tip != null) {
      _state.setBrushTip(switch (value.tip!) {
        ToolsBrushTip.hard => EditorBrushTip.round,
        ToolsBrushTip.soft => EditorBrushTip.softRound,
        ToolsBrushTip.square => EditorBrushTip.square,
      });
    }
    if (value.pressure != null) _state.setPressureSensitivity(value.pressure!);
    if (value.square != null) _state.setSquareBrush(value.square!);
    if (_state.currentTool case final FillTool fill) {
      if (value.tolerance != null) {
        fill.setTolerance(value.tolerance!.clamp(0, 100));
      }
    }
    if (_state.currentTool case final BlurTool blur) {
      if (value.intensity != null && value.intensity!.isFinite) {
        blur.setIntensity(value.intensity!.clamp(0, 1));
      }
    }
    _state.requestUiUpdate();
  }

  Future<void> _toolsMoreColors(Rect anchor) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final local = anchor.shift(-overlay.localToGlobal(Offset.zero));
    return showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(local.left, local.bottom + 8, local.width, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          child: SizedBox(
            width: 240,
            child: EditColorPicker(
              color: _state.foregroundColor,
              onChanged: _state.setForegroundColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toolsApply(bool generate) async {
    if (_toolsApplying || !_canExportAndClose) return;
    _toolsApplying = true;
    try {
      final ticket = _toolsAdjustTicket;
      await _toolsAdjustPending;
      if (!mounted || ticket != _toolsAdjustTicket) return;
      _toolsCommitAdjust();
      await _exportAndClose(generate: generate);
    } finally {
      _toolsApplying = false;
    }
  }

  void _toolsLayerMutation(String id, void Function() change) {
    if (_state.layerManager.getLayerById(id) == null) return;
    _toolsResetAdjust();
    _state.editSelection.commit();
    _state.historyManager.execute(
      ToolsEditorLayerAction((_) => change(), description: 'Layer operation'),
      _state,
    );
  }

  void _toolsLayerAction(String id, ToolsLayerAction action) {
    final manager = _state.layerManager;
    final layer = manager.getLayerById(id);
    if (layer == null || layer.locked || id == _sourceLayerId) return;
    _toolsLayerMutation(id, () {
      switch (action) {
        case ToolsLayerAction.up:
          manager.moveLayerUp(id);
        case ToolsLayerAction.down:
          final index = manager.layers.indexOf(layer);
          if (index > 0 && manager.layers[index - 1].id != _sourceLayerId) {
            manager.moveLayerDown(id);
          }
        case ToolsLayerAction.duplicate:
          toolsDuplicateLayer(_state, layer);
        case ToolsLayerAction.merge:
          final index = manager.layers.indexOf(layer);
          if (index > 0 && manager.layers[index - 1].id != _sourceLayerId) {
            toolsMergeLayers(_state, layer, manager.layers[index - 1]);
          }
        case ToolsLayerAction.delete:
          if (manager.layerCount > 1) manager.removeLayer(id);
      }
    });
  }

  Future<void> _toolsExpandTo(ToolsExpand value) async {
    if (!_isInpaintMode || _isOutpaintCommitPending) return;
    final current = _toolsEdges;
    int aligned(int v) => (v.clamp(0, 1024) ~/ 64) * 64;
    await _applyOutpaintFrameDelta(
      OutpaintFrameDelta(
        left: aligned(value.left) - current.left,
        top: aligned(value.top) - current.top,
        right: aligned(value.right) - current.right,
        bottom: aligned(value.bottom) - current.bottom,
      ),
    );
    await _toolsMeasureMask();
  }

  Future<void> _toolsPreviewAdjust(ToolsAdjust value) async {
    final layer = _state.layerManager.activeLayer;
    if (layer == null || layer.locked || layer.id == _sourceLayerId) return;
    if (_toolsAdjustLayer != layer.id ||
        _toolsAdjustSourceRevision != _toolsEditRevision) {
      _toolsResetAdjust();
    }
    _toolsAdjustLayer = layer.id;
    final ticket = ++_toolsAdjustTicket;
    _toolsAdjust = value;
    _toolsOriginal ??= renderEditLayer(layer, _state.canvasSize);
    _toolsAdjustSourceRevision = _toolsEditRevision;
    final editRevision = _toolsEditRevision;
    final original = _toolsOriginal!;
    final originalWidth = original.width, originalHeight = original.height;
    final raw = await original.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (raw == null || !mounted || ticket != _toolsAdjustTicket) return;
    final bytes = await compute(adjustEditHsv, {
      'bytes': raw.buffer.asUint8List(),
      'hue': value.hue.toDouble(),
      'saturation': value.saturation.toDouble(),
      'brightness': value.brightness.toDouble(),
    });
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: originalWidth,
      height: originalHeight,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    ui.Image? image;
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
    if (!mounted ||
        ticket != _toolsAdjustTicket ||
        editRevision != _toolsEditRevision ||
        _state.layerManager.activeLayerId != layer.id ||
        _state.layerManager.getLayerById(layer.id) != layer) {
      image.dispose();
      return;
    }
    _toolsPreview?.dispose();
    _toolsPreview = image;
    _toolsPreviewRevision = editRevision;
    _state.rasterPreviewLayerId = layer.id;
    _state.rasterPreview = image;
    _state.notifyCanvasPreview();
    _updateLayoutState(() {});
  }

  void _toolsResetAdjust() {
    _toolsAdjustTicket++;
    _state.rasterPreview = null;
    _state.rasterPreviewLayerId = null;
    _toolsPreview?.dispose();
    _toolsPreview = null;
    _toolsOriginal?.dispose();
    _toolsOriginal = null;
    _toolsAdjustLayer = null;
    _toolsAdjustSourceRevision = -1;
    _toolsPreviewRevision = -1;
    _toolsAdjust = const ToolsAdjust();
    if (!_state.isDisposed && !_toolsDisposing) {
      _state.notifyCanvasPreview();
      _state.requestUiUpdate();
    }
  }

  void _toolsCommitAdjust() {
    if (_toolsPreview != null &&
        !_toolsAdjust.isZero &&
        _toolsPreviewRevision == _toolsEditRevision &&
        _toolsAdjustLayer == _state.layerManager.activeLayerId) {
      _state.historyManager.execute(
        ReplaceEditRasterAction(
          layerId: _toolsAdjustLayer!,
          image: _toolsPreview!.clone(),
          description: 'HSV Adjustment',
        ),
        _state,
      );
    }
    _toolsResetAdjust();
  }

  Future<void> _toolsApplyAdjust() async {
    final ticket = _toolsAdjustTicket;
    await _toolsAdjustPending;
    if (mounted && ticket == _toolsAdjustTicket) _toolsCommitAdjust();
  }

  Future<void> _toolsMeasureMask() {
    if (!_isInpaintMode || !_isInitialized || _toolsDisposing) {
      return Future.value();
    }
    _toolsMaskTicket++;
    return _toolsMaskPending ??= _toolsMeasureLatestMask().whenComplete(
      () => _toolsMaskPending = null,
    );
  }

  Future<void> _toolsMeasureLatestMask() async {
    while (mounted && !_toolsDisposing) {
      final ticket = _toolsMaskTicket;
      try {
        await _toolsReadMaskMeasurement(ticket);
      } catch (error) {
        if (mounted && !_toolsDisposing) {
          AppLogger.w('Failed to measure canvas mask: $error', 'ImageEditor');
        }
      }
      if (ticket == _toolsMaskTicket) return;
    }
  }

  Future<void> _toolsReadMaskMeasurement(int ticket) async {
    final bytes = await _exportInpaintLayerMaskAtCompressionTarget(
      _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
    );
    if (!mounted || _toolsDisposing || ticket != _toolsMaskTicket) return;
    final result = InpaintMaskUtils.decodeBinaryMask(bytes);
    if (result == null) return;
    final mask = result.mask;
    var covered = 0, regions = 0;
    final visited = Uint8List(mask.length);
    for (var i = 0; i < mask.length; i++) {
      if (mask[i] == 0) continue;
      covered++;
      if (visited[i] != 0) continue;
      regions++;
      final queue = [i];
      visited[i] = 1;
      for (var q = 0; q < queue.length; q++) {
        final p = queue[q], x = p % result.width;
        for (final next in [
          if (x > 0) p - 1,
          if (x < result.width - 1) p + 1,
          if (p >= result.width) p - result.width,
          if (p + result.width < mask.length) p + result.width,
        ]) {
          if (mask[next] != 0 && visited[next] == 0) {
            visited[next] = 1;
            queue.add(next);
          }
        }
      }
    }
    _updateLayoutState(() {
      _toolsMaskCoverage = mask.isEmpty ? 0 : covered / mask.length;
      _toolsMaskRegions = regions;
    });
  }
}
