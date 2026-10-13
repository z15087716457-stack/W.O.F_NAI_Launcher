part of 'image_editor_screen.dart';

extension _ImageEditorSessionModels on _ImageEditorScreenState {
  Model3dEditorState? get _activeModelEditor =>
      _modelEditorKeys[_state.layerManager.activeLayerId]?.currentState;

  Widget _buildDesktopLayout(Size mediaSize) => ListenableBuilder(
    listenable: Listenable.merge([
      _state.layerManager,
      _state.layerManager.activeLayerNotifier,
      _state.historyManager,
    ]),
    builder: (context, _) {
      final layer = _state.layerManager.activeLayer;
      if (layer?.hasModel3d != true) {
        return _buildToolsEditorLayout();
      }
      final active = layer!;
      return Model3dEditorScreen(
        key: _modelEditorKeys.putIfAbsent(
          active.id,
          () => GlobalKey<Model3dEditorState>(),
        ),
        existing: active.model3d,
        renderWidth: _state.canvasSize.width.round(),
        renderHeight: _state.canvasSize.height.round(),
        layerTray: _buildLayerTrayOverlay(),
        onSaveAndClose: _exportAndClose,
        onDownloadCanvas: _downloadCanvasImage,
        onClose: _confirmExit,
        onResizeCanvas: _changeCanvasSize,
        onCanvasUndo: () => _applyCanvasModelHistory(redo: false),
        onCanvasRedo: () => _applyCanvasModelHistory(redo: true),
        canUndoCanvas: _state.canUndo,
        canRedoCanvas: _state.canRedo,
        contextChanges: _state.layerManager,
        contextImages: () => _modelContextImages(active),
        bridgeFactoryForTest: widget.debugModel3dBridgeFactory,
        viewportBuilder: widget.debugModel3dViewport,
        libraryService: widget.debugModel3dLibrary,
        markReadyForTest: widget.debugModel3dBridgeFactory != null,
      );
    },
  );

  Widget _buildLayerTrayOverlay() => EditorLayerTray(
    state: _state,
    inpaint: _isInpaintMode,
    virtualMaskRects: _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
    onAdd3dLayer: () => _addInpaint3dLayer(),
    onEdit3dLayer: (layer) => _addInpaint3dLayer(layer: layer),
    onSelectLayer: _selectEditorLayer,
    beforeLayerMutation: _flushActiveModelLayer,
    initiallyExpanded: _state.layerManager.activeLayer?.hasModel3d == true
        ? true
        : null,
  );
  Future<void> _addInpaint3dLayer({Layer? layer}) async {
    if (!await _flushActiveModelLayer() || !mounted) return;
    _state.editSelection.commit();
    if (layer != null) {
      if (_state.layerManager.getLayerById(layer.id) != layer) return;
      _state.layerManager.setActiveLayer(layer.id);
    } else {
      _state.historyManager.execute(
        AddInpaintMaskLayerAction(
          name: context.l10n.model3d_editorTitle,
          inpaintMask: false,
          model3d: const Model3dLayerData(modelRef: 'empty', sceneState: {}),
        ),
        _state,
      );
    }
    _state.requestUiUpdate();
  }

  Future<void> _selectEditorLayer(Layer layer) async {
    if (_state.layerManager.activeLayerId == layer.id) return;
    if (!await _flushActiveModelLayer() || !mounted) return;
    if (_state.layerManager.getLayerById(layer.id) != layer) return;
    _state.editSelection.commit();
    _state.layerManager.setActiveLayer(layer.id);
  }

  Future<void> _applyCanvasModelHistory({required bool redo}) async {
    if (!await _flushActiveModelLayer() || !mounted) return;
    // Restore the scene from the same snapshot as its raster after canvas undo.
    // A fresh viewport also drops the old per-scene undo stack.
    _modelEditorKeys.clear();
    if (redo) {
      _state.redo();
    } else {
      _state.undo();
    }
  }

  Future<bool> _flushActiveModelLayer() {
    return _flushingModel ??= _captureActiveModel().whenComplete(
      () => _flushingModel = null,
    );
  }

  Future<bool> _captureActiveModel() async {
    final layer = _state.layerManager.activeLayer;
    final editor = _activeModelEditor;
    if (layer?.hasModel3d != true) return true;
    if (editor == null) return false;
    if (!editor.hasChanges && layer!.hasBaseImage) return true;
    final active = layer!;
    final previous = active.model3d;
    ui.Codec? codec;
    try {
      final result = await editor.captureLayer(
        onCaptured: (result) async {
          codec = await ui.instantiateImageCodec(result.pngBytes);
          final image = (await codec!.getNextFrame()).image;
          if (!mounted ||
              _state.layerManager.activeLayerId != active.id ||
              _state.layerManager.getLayerById(active.id) != active ||
              active.model3d != previous) {
            image.dispose();
            throw StateError('The 3D layer changed before commit');
          }
          _state.historyManager.execute(
            ReplaceModel3dLayerAction(
              layerId: active.id,
              image: image,
              bytes: result.pngBytes,
              model3d: Model3dLayerData(
                modelRef: result.modelRef,
                sceneState: result.sceneState,
              ),
            ),
            _state,
          );
        },
      );
      return result != null && mounted;
    } catch (e) {
      if (mounted) AppToast.error(context, context.l10n.editor_exportFailed(e));
      return false;
    } finally {
      codec?.dispose();
    }
  }

  Future<(Uint8List, Uint8List)?> _modelContextImages(Layer active) async {
    final layers = List<Layer>.of(_state.layerManager.layers);
    final index = layers.indexOf(active);
    if (index < 0 || _state.layerManager.activeLayerId != active.id) {
      return null;
    }
    final size = _state.canvasSize;
    Future<Uint8List> render(Iterable<Layer> group) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final bounds = Offset.zero & size;
      canvas.clipRect(bounds);
      for (final layer in group) {
        if (!layer.visible) continue;
        if (layer.inpaintMask) {
          canvas.saveLayer(
            bounds,
            Paint()
              ..colorFilter = ColorFilter.mode(
                _state.maskDisplayColor,
                BlendMode.srcIn,
              ),
          );
        }
        layer.renderWithCache(canvas, size);
        if (layer.inpaintMask) canvas.restore();
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.round(),
        size.height.round(),
      );
      picture.dispose();
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Failed to render canvas context');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    }

    final images = await Future.wait([
      render(layers.take(index)),
      render(layers.skip(index + 1)),
    ]);
    if (!mounted ||
        _state.layerManager.activeLayerId != active.id ||
        _state.layerManager.getLayerById(active.id) != active) {
      return null;
    }
    return (images[0], images[1]);
  }

  Future<void> _downloadCanvasImage() async {
    if (!await _flushActiveModelLayer() || !mounted) return;
    if (!_isInpaintMode) _state.editSelection.commit();
    final l10n = context.l10n;
    try {
      var bytes = _isInpaintMode
          ? await _exportInpaintLayerMaskAtCompressionTarget(
              _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
            )
          : await ImageExporterNew.exportMergedImage(
              _state.layerManager,
              _state.canvasSize,
            );
      if (_isInpaintMode) {
        final binary = InpaintMaskUtils.decodeBinaryMask(bytes);
        if (binary == null) throw StateError('Invalid exported mask');
        final width = (binary.width / 8).round(),
            height = (binary.height / 8).round();
        final latent = InpaintMaskUtils.resizeBinaryMask(
          binary.mask,
          sourceWidth: binary.width,
          sourceHeight: binary.height,
          targetWidth: width,
          targetHeight: height,
        );
        bytes = await InpaintMaskUtils.encodeEditorOverlayFromBinaryMaskAsync(
          latent,
          width: width,
          height: height,
          overlayAlpha: 255,
        );
      }
      if (!mounted) return;
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.common_download,
        fileName: 'canvas_${DateTime.now().millisecondsSinceEpoch}.png',
        type: FileType.custom,
        allowedExtensions: const ['png'],
      );
      if (path == null || !mounted) return;
      final filePath = path.toLowerCase().endsWith('.png') ? path : '$path.png';
      await File(filePath).writeAsBytes(bytes);
      if (mounted) {
        AppToast.success(context, l10n.image_imageSaved(filePath));
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l10n.editor_exportFailed(e));
      }
    }
  }
}
