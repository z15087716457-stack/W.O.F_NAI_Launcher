part of 'image_editor_screen.dart';

extension _ImageEditorScreenCompression on _ImageEditorScreenState {
  EditorCompressionTarget get _activeCompressionTarget {
    if (!_isInpaintMode) {
      return EditorCompressionTarget(
        width: _state.canvasSize.width.round(),
        height: _state.canvasSize.height.round(),
        isOriginal: true,
      );
    }
    final target = _compressionTarget;
    if (target != null) return target;
    return EditorCompressionTarget(
      width: _state.canvasSize.width.round(),
      height: _state.canvasSize.height.round(),
      isOriginal: true,
    );
  }

  bool get _compressionApplied {
    final target = _activeCompressionTarget;
    return target.width != _state.canvasSize.width.round() ||
        target.height != _state.canvasSize.height.round();
  }

  double get _compressionLinearScale {
    return _activeCompressionTarget.linearScaleFor(
      _state.canvasSize.width.round(),
      _state.canvasSize.height.round(),
    );
  }

  void _initializeCompressionPlan() {
    _refreshCompressionPlan(desiredScale: 1);
  }

  void _refreshCompressionPlan({double? desiredScale}) {
    final workWidth = _state.canvasSize.width.round();
    final workHeight = _state.canvasSize.height.round();
    final previousTarget = _compressionTarget;
    final previousScale = previousTarget?.linearScaleFor(
      _compressionPlan?.workWidth ?? workWidth,
      _compressionPlan?.workHeight ?? workHeight,
    );
    final plan = EditorCompressionPlan.resolve(
      workWidth: workWidth,
      workHeight: workHeight,
    );

    EditorCompressionTarget target;
    if (desiredScale != null) {
      target = plan.targetAtOrBelowScale(desiredScale);
    } else {
      final exactIndex = plan.indexOf(previousTarget);
      target = exactIndex >= 0
          ? plan.targets[exactIndex]
          : plan.targetAtOrBelowScale(previousScale ?? 1);
    }
    _compressionPlan = plan;
    _compressionTarget = target;
  }

  void _selectCompressionTarget(int index) {
    final plan = _compressionPlan;
    if (plan == null || plan.targets.isEmpty) return;
    final resolvedIndex = index.clamp(0, plan.targets.length - 1);
    _updateLayoutState(() {
      _compressionTarget = plan.targets[resolvedIndex];
    });
  }

  Future<Uint8List> _exportMergedImageAtCompressionTarget() async {
    final raw = await ImageExporterNew.exportMergedRgba(
      _state.layerManager,
      _state.canvasSize,
      transparentBackground: true,
    );
    final target = _activeCompressionTarget;
    return EditorCompressionEncoder.encodeRgbaPngAsync(
      raw,
      targetWidth: target.width,
      targetHeight: target.height,
    );
  }

  Future<Uint8List> _exportInpaintLayerMaskAtCompressionTarget(
    List<Rect> additionalMaskRects,
  ) async {
    final excludedSourceIds = {
      for (final layer in _state.layerManager.layers)
        if (!layer.inpaintMask) layer.id,
    };
    final target = _activeCompressionTarget;
    final raster = await ImageExporterNew.tryExportHardEdgeMaskRasterFromLayers(
      _state.layerManager,
      _state.canvasSize,
      excludedBaseImageLayerIds: excludedSourceIds,
      additionalMaskRects: additionalMaskRects,
    );
    if (raster != null) {
      final focus = _state.inpaintFocusRegion;
      if (focus != null) {
        InpaintFocusRegion.fromRect(
          focus,
          context: _state.inpaintContextSize.round(),
        ).applyToBinaryMask(raster.mask, raster.width, raster.height);
      }
      return InpaintMaskUtils.resizeBinaryMaskToPngAsync(
        raster.mask,
        sourceWidth: raster.width,
        sourceHeight: raster.height,
        targetWidth: target.width,
        targetHeight: target.height,
      );
    }

    final mask = await ImageExporterNew.exportMaskFromLayers(
      _state.layerManager,
      _state.canvasSize,
      excludedBaseImageLayerIds: excludedSourceIds,
      forceHardEdges: true,
      additionalMaskRects: additionalMaskRects,
    );
    final focus = _state.inpaintFocusRegion;
    final binary = InpaintMaskUtils.decodeBinaryMask(mask);
    if (focus != null && binary != null) {
      InpaintFocusRegion.fromRect(
        focus,
        context: _state.inpaintContextSize.round(),
      ).applyToBinaryMask(binary.mask, binary.width, binary.height);
      return InpaintMaskUtils.resizeBinaryMaskToPngAsync(
        binary.mask,
        sourceWidth: binary.width,
        sourceHeight: binary.height,
        targetWidth: target.width,
        targetHeight: target.height,
      );
    }
    return InpaintMaskUtils.resizeMaskBytesAsync(
      mask,
      targetWidth: target.width,
      targetHeight: target.height,
    );
  }

  Future<Uint8List?> _prepareInpaintSourceAtCompressionTarget() async {
    final target = _activeCompressionTarget;
    Uint8List? source;
    if (_hasOutpaintChanges) {
      source = await _materializeVirtualOutpaintSourceIfNeeded(
        targetWidth: target.width,
        targetHeight: target.height,
      );
    } else {
      source = _inpaintWorkingSourceImage;
    }
    if (source == null) return null;
    final imageLayers = _state.layerManager.layers
        .where(
          (layer) =>
              !layer.inpaintMask && layer.id != _sourceLayerId && layer.visible,
        )
        .toList();
    if (imageLayers.isNotEmpty) {
      final codec = await ui.instantiateImageCodec(source);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(image, Offset.zero, Paint());
      for (final layer in imageLayers.reversed) {
        layer.render(canvas, _state.canvasSize);
      }
      final picture = recorder.endRecording();
      final merged = await picture.toImage(
        _state.canvasSize.width.round(),
        _state.canvasSize.height.round(),
      );
      picture.dispose();
      final data = await merged.toByteData(format: ui.ImageByteFormat.png);
      merged.dispose();
      image.dispose();
      if (data != null) source = data.buffer.asUint8List();
    }

    final normalized = await NaiResolutionAdapter.normalizeImageForRequestAsync(
      source,
      targetWidth: target.width,
      targetHeight: target.height,
    );
    if (normalized == null) {
      throw StateError('Failed to encode the compressed inpaint source.');
    }
    return normalized;
  }
}
