part of 'image_editor_screen.dart';

extension _ImageEditorScreenCompression on _ImageEditorScreenState {
  EditorCompressionTarget get _activeCompressionTarget {
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
      transparentBackground: _hasTransparentCutout,
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

  Widget _buildDesktopCompressionControl({required bool expanded}) {
    final plan = _compressionPlan;
    if (plan == null) return const SizedBox.shrink();
    if (!expanded) {
      return IconButton(
        icon: const Icon(Icons.compress, size: 20),
        onPressed: _showCompressionSheet,
        tooltip: context.l10n.editor_compressionTooltip,
      );
    }

    final target = _activeCompressionTarget;
    final index = plan.indexOf(target).clamp(0, plan.targets.length - 1);
    return Tooltip(
      message: context.l10n.editor_compressionTooltip,
      child: SizedBox(
        width: 300,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.compress, size: 18),
            const SizedBox(width: 6),
            SizedBox(
              width: 92,
              child: Text(
                '${target.width} x ${target.height}',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: Slider(
                value: index.toDouble(),
                min: 0,
                max: plan.targets.length > 1
                    ? (plan.targets.length - 1).toDouble()
                    : 1,
                divisions: plan.targets.length > 1
                    ? plan.targets.length - 1
                    : null,
                onChanged: plan.canCompress
                    ? (value) => _selectCompressionTarget(value.round())
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompressionAction() {
    return IconButton(
      icon: const Icon(Icons.compress),
      onPressed: _showCompressionSheet,
      tooltip: context.l10n.editor_compressionTooltip,
    );
  }

  Future<void> _showCompressionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final plan = _compressionPlan;
            if (plan == null) return const SizedBox.shrink();
            final target = _activeCompressionTarget;
            final index = plan
                .indexOf(target)
                .clamp(0, plan.targets.length - 1);
            final theme = Theme.of(sheetContext);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.editor_compressionTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.editor_compressionSizeSummary(
                        plan.workWidth,
                        plan.workHeight,
                        target.width,
                        target.height,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.isOriginal
                          ? context.l10n.editor_compressionUncompressed
                          : context.l10n.editor_compressionApplyOnDone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Slider(
                      value: index.toDouble(),
                      min: 0,
                      max: plan.targets.length > 1
                          ? (plan.targets.length - 1).toDouble()
                          : 1,
                      divisions: plan.targets.length > 1
                          ? plan.targets.length - 1
                          : null,
                      label: '${target.width} x ${target.height}',
                      onChanged: plan.canCompress
                          ? (value) {
                              _selectCompressionTarget(value.round());
                              setSheetState(() {});
                            }
                          : null,
                    ),
                    Text(
                      context.l10n.editor_compressionNormalSummary(
                        plan.normalTarget.width,
                        plan.normalTarget.height,
                        plan.minimumTarget.width,
                        plan.minimumTarget.height,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (!plan.canCompress) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.editor_compressionUnavailable,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
