part of 'image_editor_screen.dart';

extension _ImageEditorScreenLayout on _ImageEditorScreenState {
  Widget _buildDesktopLayout(Size mediaSize) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(child: _buildCanvasArea()),
        Positioned(
          top: mediaSize.width < 560 ? 66 : 10,
          left: 10,
          child: _isInpaintMode
              ? InpaintToolSettings(state: _state)
              : EditToolSettings(
                  state: _state,
                  maxWidth: (mediaSize.width - 20).clamp(280, 620),
                ),
        ),
        Positioned(top: 10, right: 10, child: _buildTopRightActions(mediaSize)),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Center(child: _buildFloatingToolbar(mediaSize)),
        ),
        if (_showLayerPanel)
          Positioned(right: 10, bottom: 60, child: _buildLayerTrayOverlay()),
        if (_showHsv && !_isInpaintMode) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _updateLayoutState(() => _showHsv = false),
            ),
          ),
          Positioned(
            left: (mediaSize.width / 2 - 130).clamp(10, mediaSize.width - 270),
            bottom: 70,
            child: EditHsvPanel(
              state: _state,
              onClose: () => _updateLayoutState(() => _showHsv = false),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _buildTopRightActions(Size mediaSize) {
    final l = context.l10n;
    return InpaintPanel(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EditButton(
            glyph: 'download',
            tooltip: l.common_download,
            onPressed: _downloadCanvasImage,
          ),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _canExportAndClose ? _exportAndClose : null,
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                minimumSize: const Size(120, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                l.editor_saveAndExit,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          EditButton(
            glyph: 'close',
            tooltip: l.common_close,
            onPressed: _confirmExit,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbar(Size mediaSize) {
    if (_isInpaintMode) {
      return InpaintToolbar(
        state: _state,
        width: (mediaSize.width * .74).clamp(
          288,
          (mediaSize.width - 20).clamp(288, 1100),
        ),
        onClear: _resetInpaintMask,
        onShiftEdges: _showShiftEdgesDialog,
      );
    }
    return EditImageToolbar(
      state: _state,
      width: (mediaSize.width - 20).clamp(270, 830),
      onHsv: () {
        _state.editSelection.commit();
        _updateLayoutState(() => _showHsv = !_showHsv);
      },
      onClear: _state.clearActiveLayerWithHistory,
      onResize: _changeCanvasSize,
    );
  }

  Widget _buildLayerTrayOverlay() => EditorLayerTray(
    state: _state,
    inpaint: _isInpaintMode,
    virtualMaskRects: _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
    onAdd3dLayer: () => _addInpaint3dLayer(),
    onEdit3dLayer: (layer) => _addInpaint3dLayer(layer: layer),
  );
  Future<void> _addInpaint3dLayer({Layer? layer}) async {
    final result = await Model3dEditorScreen.show(
      context,
      renderWidth: _state.canvasSize.width.round(),
      renderHeight: _state.canvasSize.height.round(),
      existing: layer?.model3d,
    );
    if (result == null || !mounted) return;
    final added =
        layer ??
        await _state.layerManager.addLayerFromImage(
          result.pngBytes,
          name: context.l10n.model3d_editorTitle,
        );
    if (added == null || !mounted) return;
    if (layer != null) await layer.setBaseImage(result.pngBytes);
    added.inpaintMask = false;
    added.model3d = Model3dLayerData(
      modelRef: result.modelRef,
      sceneState: result.sceneState,
    );
    final maskLayer = _state.layerManager.layers
        .where((layer) => layer.inpaintMask)
        .firstOrNull;
    if (maskLayer != null) _state.layerManager.setActiveLayer(maskLayer.id);
    _state.requestUiUpdate();
  }

  Future<void> _downloadCanvasImage() async {
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
