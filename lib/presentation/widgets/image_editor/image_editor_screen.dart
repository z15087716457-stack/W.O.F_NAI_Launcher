import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/editor_compression_utils.dart';
import '../../../core/utils/inpaint_mask_utils.dart';
import '../../../core/utils/inpaint_focus_region.dart';
import '../../../core/utils/inpaint_outpaint_utils.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../utils/dropped_file_reader.dart';
import '../../utils/internal_drag_protocol.dart';
import '../../providers/image_generation_provider.dart';
import '../../widgets/common/app_toast.dart';
import 'core/editor_state.dart';
import 'core/edit_image_actions.dart';
import 'widgets/panels/edit_image_controls.dart';
import 'widgets/panels/edit_hsv_panel.dart';
import 'widgets/panels/edit_resize_dialog.dart';
import 'core/history_manager.dart';
import 'layers/layer.dart';
import 'canvas/editor_canvas.dart';
import 'widgets/panels/layer_thumbnail_tray.dart';
import 'widgets/panels/shift_edges_dialog.dart';
import 'widgets/panels/inpaint_controls.dart';
import 'widgets/outpaint_edge_drag_overlay.dart';
import '../model3d_editor/model3d_editor_screen.dart';
import 'layers/model3d_layer_data.dart';
import 'canvas/layer_painter.dart';
import 'export/image_exporter_new.dart';

part 'image_editor_screen_compression.dart';
part 'image_editor_screen_layout.dart';
part 'image_editor_screen_types.dart';

/// 图像编辑器主界面
class ImageEditorScreen extends StatefulWidget {
  /// 初始图像（可选，用于编辑已有图像）
  final Uint8List? initialImage;

  /// 初始画布尺寸（当没有初始图像时使用）
  final Size? initialSize;

  /// 已有的蒙版图像
  final Uint8List? existingMask;
  final InpaintFocusRegion? existingFocusRegion;

  /// 是否显示蒙版导出选项
  final bool showMaskExport;

  /// 编辑器模式
  final ImageEditorMode mode;

  /// 标题
  final String title;

  @visibleForTesting
  final bool initialOutpaintCommitPending;

  @visibleForTesting
  final bool initialShowLayerPanel;

  @visibleForTesting
  final bool debugFailOutpaintSourceReplacement;

  @visibleForTesting
  final bool debugDisableDropRegion;

  @visibleForTesting
  const ImageEditorScreen({
    super.key,
    this.initialImage,
    this.initialSize,
    this.existingMask,
    this.existingFocusRegion,
    this.showMaskExport = true,
    this.mode = ImageEditorMode.edit,
    this.title = '',
    this.initialOutpaintCommitPending = false,
    this.initialShowLayerPanel = true,
    this.debugFailOutpaintSourceReplacement = false,
    this.debugDisableDropRegion = false,
  });

  /// 显示编辑器
  static Future<ImageEditorResult?> show(
    BuildContext context, {
    Uint8List? initialImage,
    Size? initialSize,
    Uint8List? existingMask,
    InpaintFocusRegion? existingFocusRegion,
    bool showMaskExport = true,
    ImageEditorMode mode = ImageEditorMode.edit,
    String? title,
  }) {
    return Navigator.push<ImageEditorResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          initialImage: initialImage,
          initialSize: initialSize,
          existingMask: existingMask,
          existingFocusRegion: existingFocusRegion,
          showMaskExport: showMaskExport,
          mode: mode,
          title: title ?? context.l10n.editor_defaultTitle,
        ),
      ),
    );
  }

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  static const bool _useVirtualOutpaint = true;
  static const int _maxImportedImageBytes = 50 * 1024 * 1024;

  late EditorState _state;
  EditorCompressionPlan? _compressionPlan;
  EditorCompressionTarget? _compressionTarget;
  bool _isInitialized = false;
  bool _didStartInitialization = false;
  bool _showLayerPanel = true;
  bool _showHsv = false;
  bool _isOutpaintCommitPending = false;
  String? _sourceLayerId;
  Uint8List? _outpaintSourceImage;
  int? _outpaintSourceWidth;
  int? _outpaintSourceHeight;
  Uint8List? _inpaintWorkingSourceImage;
  int? _inpaintWorkingSourceWidth;
  int? _inpaintWorkingSourceHeight;
  int? _initialSourceWidth;
  int? _initialSourceHeight;
  bool _sourceWasNormalized = false;
  OutpaintVirtualFrame? _virtualOutpaintFrame;
  // ignore: prefer_final_fields
  bool _hasOutpaintChanges = false;
  bool _isImportingDroppedImage = false;

  bool get _isInpaintMode => widget.mode == ImageEditorMode.inpaint;
  bool get _canExportAndClose => !_isOutpaintCommitPending;

  OutpaintVirtualFrame get _effectiveOutpaintFrame {
    return _virtualOutpaintFrame ??
        OutpaintVirtualFrame.fromSource(
          sourceWidth: _state.canvasSize.width.round(),
          sourceHeight: _state.canvasSize.height.round(),
        );
  }

  @visibleForTesting
  Size get debugCanvasSize => _state.canvasSize;

  @visibleForTesting
  Size get debugCompressionTargetSize => Size(
    _activeCompressionTarget.width.toDouble(),
    _activeCompressionTarget.height.toDouble(),
  );

  @visibleForTesting
  int get debugCompressionTargetCount => _compressionPlan?.targets.length ?? 0;

  @visibleForTesting
  bool get debugCompressionApplied => _compressionApplied;

  @visibleForTesting
  void debugSetCompressionTargetIndex(int index) {
    _selectCompressionTarget(index);
  }

  @visibleForTesting
  bool get debugHasOutpaintChanges => _hasOutpaintChanges;

  @visibleForTesting
  bool get debugOutpaintCommitPending => _isOutpaintCommitPending;

  @visibleForTesting
  List<Rect> get debugVirtualOutpaintMaskRects {
    return _virtualOutpaintFrame?.outpaintMaskRects ?? const [];
  }

  @visibleForTesting
  int? get debugOutpaintSourceWidth => _outpaintSourceWidth;

  @visibleForTesting
  int? get debugOutpaintSourceHeight => _outpaintSourceHeight;

  @visibleForTesting
  String? get debugCurrentToolId => _state.currentTool?.id;

  @visibleForTesting
  String? get debugActiveLayerId => _state.layerManager.activeLayerId;

  @visibleForTesting
  String? get debugActiveLayerName => _state.layerManager.activeLayer?.name;

  @visibleForTesting
  int get debugActiveLayerStrokeCount {
    return _state.layerManager.activeLayer?.strokes.length ?? 0;
  }

  @visibleForTesting
  bool get debugIsDrawing => _state.isDrawing;

  @visibleForTesting
  bool get debugActiveLayerHasBaseImage =>
      _state.layerManager.activeLayer?.hasBaseImage ?? false;

  @visibleForTesting
  int get debugCurrentStrokePointCount => _state.currentStrokePoints.length;

  @visibleForTesting
  bool get debugHasMaskContent => _hasMaskContent();

  @visibleForTesting
  bool debugUndo() => _state.undo();

  @visibleForTesting
  Offset debugCanvasToScreen(Offset point) {
    return _state.canvasController.canvasToScreen(
      point,
      canvasSize: _state.canvasSize,
    );
  }

  @visibleForTesting
  Rect? get debugSelectionBounds => _state.selectionPath?.getBounds();

  @visibleForTesting
  Rect? get debugPreviewBounds => _state.previewPath?.getBounds();

  @visibleForTesting
  List<String> get debugLayerNames =>
      _state.layerManager.layers.map((layer) => layer.name).toList();

  @visibleForTesting
  Future<void> debugApplyOutpaintEdges(
    OutpaintEdges edges, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
  }) {
    return _applyOutpaintEdges(
      edges,
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
  }

  @visibleForTesting
  Future<void> debugApplyOutpaintFrameDelta(
    OutpaintFrameDelta delta, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
  }) {
    return _applyOutpaintFrameDelta(
      delta,
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
  }

  @visibleForTesting
  Future<void> debugApplyOutpaintFrameDeltaMaterialized(
    OutpaintFrameDelta delta, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
  }) {
    return _applyOutpaintFrameDeltaMaterialized(
      delta,
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
  }

  @visibleForTesting
  Future<void> debugExportAndClose() => _exportAndClose();

  @visibleForTesting
  Future<void> debugImportDroppedImageLayer(
    String fileName,
    Uint8List imageBytes,
  ) {
    return _importDroppedImageLayer(fileName, imageBytes);
  }

  @visibleForTesting
  EditorState get debugEditorState => _state;

  @visibleForTesting
  Future<Uint8List> debugExportMask() =>
      _exportInpaintLayerMaskAtCompressionTarget(
        _virtualOutpaintFrame?.outpaintMaskRects ?? const [],
      );

  @visibleForTesting
  void debugSetToolById(String toolId) {
    _state.setToolById(toolId);
  }

  @visibleForTesting
  void debugSetSelectionRect(Rect rect) {
    _state.setSelection(Path()..addRect(rect), saveHistory: false);
  }

  @visibleForTesting
  void debugSetPreviewRect(Rect rect) {
    _state.setPreviewPath(Path()..addRect(rect));
  }

  String _editorTitle() =>
      widget.title.isEmpty ? context.l10n.editor_defaultTitle : widget.title;

  void _localizeDefaultLayerName() {
    for (final layer in _state.layerManager.layers) {
      if (layer.name == '\u56fe\u5c42 1' || layer.name == 'Layer 1') {
        _state.layerManager.renameLayer(
          layer.id,
          context.l10n.editor_defaultDrawingLayerName,
        );
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _state = EditorState(inpaint: _isInpaintMode);
    _isOutpaintCommitPending = widget.initialOutpaintCommitPending;
    _showLayerPanel = widget.initialShowLayerPanel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didStartInitialization) {
      _didStartInitialization = true;
      unawaited(_initializeCanvas());
    }
  }

  Future<void> _initializeCanvas() async {
    if (widget.initialImage != null) {
      // 从已有图像初始化
      await _loadInitialImage();
    } else {
      // 显示尺寸选择对话框或使用默认尺寸
      final size = widget.initialSize ?? const Size(1024, 1024);
      _state.initNewCanvas(
        size,
        initialLayerName: context.l10n.editor_defaultDrawingLayerName,
      );
      _localizeDefaultLayerName();

      // 加载已有蒙版（如果有）
      await _loadExistingMask();
    }

    _initializeCompressionPlan();

    setState(() {
      _isInitialized = true;
    });

    if (_isInpaintMode) {
      _state.setForegroundColor(Colors.white);
      for (final layer in _state.layerManager.layers) {
        if (layer.id != _sourceLayerId) layer.inpaintMask = true;
      }
      _state.setBrushSize(32);
      _state.setToolById('brush');
      _state.setInpaintFocusRegion(widget.existingFocusRegion?.rect);
      _state.setInpaintContextSize(
        widget.existingFocusRegion?.context.toDouble() ?? 96,
      );
    }

    // 适应视口
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _state.canvasController.fitToViewport(
          _state.canvasSize,
          padding: 64,
          insets: _isInpaintMode
              ? null
              : const EdgeInsets.fromLTRB(10, 70, 10, 70),
        );
      }
    });
  }

  Future<void> _loadInitialImage() async {
    final defaultDrawingLayerName = context.l10n.editor_defaultDrawingLayerName;
    final baseLayerName = context.l10n.editor_baseLayerName;
    ui.Codec? codec;
    try {
      final editorImage = await NaiResolutionAdapter.prepareImageForEditorAsync(
        widget.initialImage!,
        alignForInpaint: _isInpaintMode,
      );
      var workingBytes = editorImage?.bytes ?? widget.initialImage!;
      if (editorImage?.resizeMode == NaiEditorResizeMode.medium) {
        workingBytes = await _resizeEditorImageWithMedium(
          workingBytes,
          width: editorImage!.width,
          height: editorImage.height,
        );
      }
      _initialSourceWidth = editorImage?.originalWidth;
      _initialSourceHeight = editorImage?.originalHeight;
      _sourceWasNormalized = editorImage?.wasNormalized ?? false;
      if (_isInpaintMode) {
        _inpaintWorkingSourceImage = workingBytes;
        _inpaintWorkingSourceWidth = editorImage?.width;
        _inpaintWorkingSourceHeight = editorImage?.height;
      }

      codec = await ui.instantiateImageCodec(workingBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      _initialSourceWidth ??= image.width;
      _initialSourceHeight ??= image.height;
      _inpaintWorkingSourceWidth ??= image.width;
      _inpaintWorkingSourceHeight ??= image.height;

      _state.initNewCanvas(
        Size(image.width.toDouble(), image.height.toDouble()),
        initialLayerName: defaultDrawingLayerName,
      );

      // 将图像添加为底图图层
      final sourceLayer = await _state.layerManager.addLayerFromImage(
        workingBytes,
        name: baseLayerName,
        index: _isInpaintMode ? 0 : null,
      );
      _sourceLayerId = sourceLayer?.id;
      _state.inpaintSourceLayerId = _isInpaintMode ? _sourceLayerId : null;
      if (!_isInpaintMode && sourceLayer != null) {
        for (final layer
            in _state.layerManager.layers
                .where((l) => l.id != sourceLayer.id)
                .toList()) {
          _state.layerManager.removeLayer(layer.id);
        }
      }
      if (_isInpaintMode && sourceLayer != null) {
        _virtualOutpaintFrame = OutpaintVirtualFrame.fromSource(
          sourceWidth: image.width,
          sourceHeight: image.height,
        );
      }
      if (_isInpaintMode && sourceLayer != null) {
        sourceLayer.locked = true;
      }

      _localizeDefaultLayerName();

      // Select the default drawing layer rather than the base image layer.
      final layer1 = _state.layerManager.layers.firstWhere(
        (l) => l.name == defaultDrawingLayerName,
        orElse: () => _state.layerManager.layers.last,
      );
      _state.layerManager.setActiveLayer(layer1.id);

      // 加载已有蒙版
      await _loadExistingMask();

      image.dispose();
    } catch (e) {
      AppLogger.w('Failed to load initial image: $e', 'ImageEditor');
      _state.initNewCanvas(
        widget.initialSize ?? const Size(1024, 1024),
        initialLayerName: defaultDrawingLayerName,
      );
      _localizeDefaultLayerName();
    } finally {
      codec?.dispose();
    }
  }

  Future<Uint8List> _resizeEditorImageWithMedium(
    Uint8List sourceBytes, {
    required int width,
    required int height,
  }) async {
    ui.Codec? sourceCodec;
    ui.Image? sourceImage;
    ui.Image? targetImage;
    ui.Picture? picture;
    try {
      sourceCodec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await sourceCodec.getNextFrame();
      sourceImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        sourceImage,
        ui.Rect.fromLTWH(
          0,
          0,
          sourceImage.width.toDouble(),
          sourceImage.height.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
      picture = recorder.endRecording();
      targetImage = await picture.toImage(width, height);
      final byteData = await targetImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw StateError('Failed to encode the editor working image');
      }
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      targetImage?.dispose();
      picture?.dispose();
      sourceImage?.dispose();
      sourceCodec?.dispose();
    }
  }

  Future<void> _loadExistingMask() async {
    if (widget.existingMask == null) return;

    try {
      final resizedMask = InpaintMaskUtils.resizeMaskBytes(
        widget.existingMask!,
        targetWidth: _state.canvasSize.width.round(),
        targetHeight: _state.canvasSize.height.round(),
      );
      final overlayBytes = InpaintMaskUtils.maskToEditorOverlay(
        resizedMask,
        overlayAlpha: 255,
      );

      // 将已有蒙版添加为图层
      final layer = await _addMaskLayerAboveSource(
        overlayBytes,
        name: context.l10n.editor_existingMaskLayerName,
      );

      if (layer != null) {
        AppLogger.i(
          'Existing mask loaded as layer: ${layer.id}',
          'ImageEditor',
        );
      } else {
        AppLogger.w('Failed to load existing mask as layer', 'ImageEditor');
      }
    } catch (e) {
      AppLogger.e('Error loading existing mask: $e', 'ImageEditor');
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(_editorTitle())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _buildDroppedImageLayerRegion(
      LayoutBuilder(
        builder: (context, constraints) {
          return _buildDesktopLayout(constraints.biggest);
        },
      ),
    );
  }

  void _updateLayoutState(VoidCallback update) => setState(update);

  Future<void> _changeCanvasSize() async {
    _state.editSelection.commit();
    final delta = await showDialog<OutpaintFrameDelta>(
      context: context,
      builder: (context) => EditResizeDialog(size: _state.canvasSize),
    );
    if (delta != null && !delta.isEmpty && mounted) {
      _state.historyManager.execute(
        ShiftEditCanvasAction(delta: delta, preserveViewport: false),
        _state,
      );
    }
  }

  Future<void> _showShiftEdgesDialog() async {
    if (!_isInpaintMode) return;
    final source = await _prepareInpaintSourceAtCompressionTarget();
    if (!mounted) return;
    final result = await ShiftEdgesDialog.show(
      context,
      sourceWidth: _state.canvasSize.width.round(),
      sourceHeight: _state.canvasSize.height.round(),
      previewImage: source,
    );
    if (result == null || !mounted) return;
    await _applyOutpaintFrameDelta(
      OutpaintFrameDelta(
        left: result.requestedEdges.left,
        top: result.requestedEdges.top,
        right: result.requestedEdges.right,
        bottom: result.requestedEdges.bottom,
      ),
      horizontalSnapTarget: result.horizontalSnapTarget,
      verticalSnapTarget: result.verticalSnapTarget,
    );
  }

  Future<void> _confirmExit() async {
    // 检查是否有修改：检查历史记录或图层内容
    final hasChanges =
        _state.historyManager.canUndo || _state.editSelection.changed;

    if (hasChanges) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.editor_confirmExitTitle),
          content: Text(context.l10n.editor_confirmExitContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.editor_exit),
            ),
            FilledButton(
              onPressed: _canExportAndClose
                  ? () async {
                      Navigator.pop(context, false);
                      await _exportAndClose();
                    }
                  : null,
              child: Text(context.l10n.editor_saveAndExit),
            ),
          ],
        ),
      );

      if (shouldExit != true) return;
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// 导出并关闭
  Future<void> _exportAndClose() async {
    if (!mounted) return;
    if (!_canExportAndClose) return;
    if (!_isInpaintMode) _state.editSelection.commit();

    bool loadingDialogShown = false;

    try {
      loadingDialogShown = true;
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );

      final target = _activeCompressionTarget;
      final compressionApplied = _compressionApplied;
      final hasCanvasImageChanges =
          _state.historyManager.canUndo ||
          _state.layerManager.layers.any((l) => l.strokes.isNotEmpty) ||
          _state.layerManager.layerCount > 1;
      final hasImageChanges =
          hasCanvasImageChanges || (!_isInpaintMode && compressionApplied);

      final virtualOutpaintMaskRects =
          _virtualOutpaintFrame?.outpaintMaskRects ?? const <Rect>[];
      final hasMaskChanges =
          _hasMaskContent() ||
          virtualOutpaintMaskRects.isNotEmpty ||
          (_state.inpaintFocusInterior != null &&
              !_state.inpaintFocusInterior!.isEmpty);
      AppLogger.d(
        'Export editor result: inpaint=$_isInpaintMode, '
            'hasImageChanges=$hasImageChanges, hasMaskChanges=$hasMaskChanges, '
            'selection=${_state.selectionPath != null}, '
            'work=${_state.canvasSize.width.round()}x${_state.canvasSize.height.round()}, '
            'target=${target.width}x${target.height}, '
            'compressionApplied=$compressionApplied, '
            'layers=${_state.layerManager.layerCount}',
        'ImageEditor',
      );

      Uint8List? modifiedImage;
      if (!_isInpaintMode && hasImageChanges) {
        modifiedImage = await _exportMergedImageAtCompressionTarget();
      }

      Uint8List? maskImage;
      if (_isInpaintMode && widget.showMaskExport && hasMaskChanges) {
        maskImage = await _exportInpaintLayerMaskAtCompressionTarget(
          virtualOutpaintMaskRects,
        );
        AppLogger.d(
          'Exported inpaint mask bytes: ${maskImage.length}',
          'ImageEditor',
        );
      }

      final inpaintSource = _isInpaintMode
          ? await _prepareInpaintSourceAtCompressionTarget()
          : null;

      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }

      if (mounted) {
        Navigator.of(context).pop(
          ImageEditorResult(
            modifiedImage: modifiedImage,
            maskImage: maskImage,
            inpaintFocusRegion: _state.inpaintFocusRegion == null
                ? null
                : InpaintFocusRegion.fromRect(
                    _state.inpaintFocusRegion!,
                    context: _state.inpaintContextSize.round(),
                  ),
            hasImageChanges: !_isInpaintMode && hasImageChanges,
            hasMaskChanges: _isInpaintMode && hasMaskChanges,
            outpaintSourceImage: _isInpaintMode && _hasOutpaintChanges
                ? inpaintSource
                : null,
            outpaintSourceWidth: _isInpaintMode && _hasOutpaintChanges
                ? target.width
                : null,
            outpaintSourceHeight: _isInpaintMode && _hasOutpaintChanges
                ? target.height
                : null,
            hasOutpaintChanges: _isInpaintMode && _hasOutpaintChanges,
            inpaintSourceImage: _isInpaintMode && !_hasOutpaintChanges
                ? inpaintSource
                : null,
            inpaintSourceWidth: _isInpaintMode && !_hasOutpaintChanges
                ? target.width
                : null,
            inpaintSourceHeight: _isInpaintMode && !_hasOutpaintChanges
                ? target.height
                : null,
            sourceWasNormalized:
                _isInpaintMode &&
                !_hasOutpaintChanges &&
                (_sourceWasNormalized || compressionApplied),
            outputWidth: target.width,
            outputHeight: target.height,
            compressionApplied: compressionApplied,
          ),
        );
      }
    } catch (e) {
      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        AppToast.error(context, context.l10n.editor_exportFailed(e));
      }
    }
  }

  Future<Uint8List?> _materializeVirtualOutpaintSourceIfNeeded({
    int? targetWidth,
    int? targetHeight,
  }) async {
    final frame = _virtualOutpaintFrame;
    final sourceLayerId = _sourceLayerId;
    if (!_isInpaintMode || frame == null || !frame.hasOutpaintChanges) {
      return _outpaintSourceImage;
    }
    if (sourceLayerId == null) {
      throw Exception('Unable to read current source image.');
    }
    final sourceLayer = _state.layerManager.getLayerById(sourceLayerId);
    final sourceBytes = sourceLayer?.baseImageBytes;
    if (sourceBytes == null) {
      throw Exception('Unable to read current source image.');
    }
    final result = await InpaintOutpaintUtils.materializeVirtualFrameAsync(
      sourceImage: sourceBytes,
      frame: frame,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    _outpaintSourceImage = result.sourceImage;
    _outpaintSourceWidth = result.width;
    _outpaintSourceHeight = result.height;
    return result.sourceImage;
  }

  bool _hasMaskContent() {
    for (final layer in _state.layerManager.layers) {
      if (!layer.visible || (_isInpaintMode && !layer.inpaintMask)) {
        continue;
      }
      if (layer.hasBaseImage || layer.strokes.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  int? _resolveMaskLayerInsertIndex() {
    if (_sourceLayerId == null) {
      return null;
    }

    final sourceIndex = _state.layerManager.layers.indexWhere(
      (layer) => layer.id == _sourceLayerId,
    );
    if (sourceIndex == -1) {
      return null;
    }

    // 蒙版图层应插入到底图上方，否则会被底图完全覆盖。
    return sourceIndex + 1;
  }

  Future<Layer?> _addMaskLayerAboveSource(
    Uint8List imageBytes, {
    required String name,
  }) async {
    final layer = await _state.layerManager.addLayerFromImage(
      imageBytes,
      name: name,
      index: _resolveMaskLayerInsertIndex(),
    );
    if (layer != null) layer.inpaintMask = true;
    return layer;
  }

  Layer _addEmptyMaskLayerAboveSource({required String name}) {
    final layer = _state.layerManager.addLayer(
      name: name,
      index: _resolveMaskLayerInsertIndex(),
    );
    layer.inpaintMask = true;
    return layer;
  }

  void _removeAllMaskLayers({Set<String> preservedLayerIds = const {}}) {
    final removableLayerIds = _state.layerManager.layers
        .where(
          (layer) => layer.inpaintMask && !preservedLayerIds.contains(layer.id),
        )
        .map((layer) => layer.id)
        .toList(growable: false);

    for (final layerId in removableLayerIds) {
      _state.layerManager.removeLayer(layerId);
    }
  }

  bool _hasVisibleMaskContent(String sourceLayerId) {
    return _state.layerManager.layers.any(
      (layer) => layer.inpaintMask && layer.visible && layer.hasContent,
    );
  }

  // ignore: unused_element
  Future<void> _applyOutpaintEdges(
    OutpaintEdges edges, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
  }) async {
    return _applyOutpaintFrameDelta(
      OutpaintFrameDelta.fromExpansionEdges(edges),
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
  }

  Future<void> _applyOutpaintFrameDelta(
    OutpaintFrameDelta delta, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
    bool preserveViewport = false,
  }) async {
    if (!_useVirtualOutpaint) {
      return _applyOutpaintFrameDeltaMaterialized(
        delta,
        horizontalSnapTarget: horizontalSnapTarget,
        verticalSnapTarget: verticalSnapTarget,
      );
    }

    if (!_isInpaintMode || delta.isEmpty || _isOutpaintCommitPending) {
      return;
    }

    final compressionScale = _compressionLinearScale;
    final sourceLayerId = _sourceLayerId;
    if (sourceLayerId == null) {
      if (mounted) {
        AppToast.error(context, 'Unable to read current source image.');
      }
      return;
    }

    final applied = _effectiveOutpaintFrame.applyDelta(
      delta,
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
    if (!applied.geometry.hasAppliedChange) {
      return;
    }

    final sourceLayer = _state.layerManager.getLayerById(sourceLayerId);
    if (sourceLayer == null) {
      if (mounted) {
        AppToast.error(context, 'Unable to read current source image.');
      }
      return;
    }

    final nonSourceLayerIds = _state.layerManager.layers
        .where((layer) => layer.id != sourceLayerId)
        .map((layer) => layer.id)
        .toList(growable: false);
    final resizedCanvasSize = applied.frame.canvasSize;

    final beforeFocus = _state.inpaintFocusRegion;
    final shiftedFocus = beforeFocus
        ?.shift(applied.contentShift)
        .intersect(Offset.zero & resizedCanvasSize);
    _state.historyManager.execute(
      _VirtualOutpaintFrameAction(
        screen: this,
        before: _effectiveOutpaintFrame,
        after: applied.frame,
        shift: applied.contentShift,
        layerIds: nonSourceLayerIds,
        compressionScale: compressionScale,
        beforeFocus: beforeFocus,
        afterFocus: shiftedFocus?.isEmpty == true ? null : shiftedFocus,
        preserveViewport: preserveViewport,
      ),
      _state,
    );
  }

  void _applyVirtualOutpaintHistoryFrame(
    OutpaintVirtualFrame frame,
    Offset shift,
    List<String> layerIds,
    double compressionScale,
    Rect? focus,
    bool preserveViewport,
  ) {
    final sourceLayer = _state.layerManager.getLayerById(_sourceLayerId!);
    if (sourceLayer == null) return;
    _state.canvasController.beginBatch();
    try {
      _state.runBatch(() {
        sourceLayer.setBaseImageOffset(frame.sourceDrawOffset);
        _state.layerManager.translateLayersContent(layerIds, shift);
        _state.layerManager.invalidateSnapshot();
        _virtualOutpaintFrame = frame;
        _outpaintSourceImage = null;
        _outpaintSourceWidth = frame.width;
        _outpaintSourceHeight = frame.height;
        _hasOutpaintChanges = frame.hasOutpaintChanges;
        _state.setCanvasSize(frame.canvasSize);
        _state.setInpaintFocusRegion(focus);
        _refreshCompressionPlan(desiredScale: compressionScale);
        if (preserveViewport) {
          _state.canvasController.pan(-shift * _state.canvasController.scale);
        } else {
          _state.canvasController.fitToViewport(_state.canvasSize);
        }
        _state.requestUiUpdate();
      });
    } finally {
      _state.canvasController.endBatch();
    }
    if (mounted) setState(() {});
  }

  Future<void> _applyOutpaintFrameDeltaMaterialized(
    OutpaintFrameDelta delta, {
    OutpaintHorizontalSnapTarget horizontalSnapTarget =
        OutpaintHorizontalSnapTarget.right,
    OutpaintVerticalSnapTarget verticalSnapTarget =
        OutpaintVerticalSnapTarget.bottom,
  }) async {
    if (!_isInpaintMode || delta.isEmpty || _isOutpaintCommitPending) {
      return;
    }

    final compressionScale = _compressionLinearScale;
    final sourceLayerId = _sourceLayerId;
    if (sourceLayerId == null) {
      if (mounted) {
        AppToast.error(context, 'Unable to read current source image.');
      }
      return;
    }
    final maskLayerName = context.l10n.editor_maskLayerName;

    final pendingGeometry = InpaintOutpaintUtils.tryResolveFrameGeometry(
      sourceWidth: _state.canvasSize.width.round(),
      sourceHeight: _state.canvasSize.height.round(),
      delta: delta,
      horizontalSnapTarget: horizontalSnapTarget,
      verticalSnapTarget: verticalSnapTarget,
    );
    if (pendingGeometry == null || !pendingGeometry.hasAppliedChange) {
      return;
    }

    if (mounted) {
      setState(() {
        _isOutpaintCommitPending = true;
      });
    } else {
      _isOutpaintCommitPending = true;
    }

    try {
      final sourceLayer = _state.layerManager.getLayerById(sourceLayerId);
      final sourceBytes = sourceLayer?.baseImageBytes;
      if (sourceBytes == null) {
        if (mounted) {
          AppToast.error(context, 'Unable to read current source image.');
        }
        return;
      }

      final existingMask = _hasVisibleMaskContent(sourceLayerId)
          ? await ImageExporterNew.exportMaskFromLayers(
              _state.layerManager,
              _state.canvasSize,
              excludedBaseImageLayerIds: {sourceLayerId},
              forceHardEdges: true,
            )
          : null;
      final result = await InpaintOutpaintUtils.resizeFrameAsync(
        sourceImage: sourceBytes,
        existingMask: existingMask,

        delta: delta,
        horizontalSnapTarget: horizontalSnapTarget,
        verticalSnapTarget: verticalSnapTarget,
        includeEditorOverlay: true,
      );

      final resizedCanvasSize = Size(
        result.width.toDouble(),
        result.height.toDouble(),
      );
      final hasResultMask = InpaintMaskUtils.hasMaskedPixels(result.maskImage);
      final overlayBytes = hasResultMask
          ? result.editorOverlayImage ??
                await InpaintMaskUtils.maskToEditorOverlayAsync(
                  result.maskImage,
                )
          : null;

      final previousOutpaintSourceImage = _outpaintSourceImage;
      final previousOutpaintSourceWidth = _outpaintSourceWidth;
      final previousOutpaintSourceHeight = _outpaintSourceHeight;
      final previousHasOutpaintChanges = _hasOutpaintChanges;
      final previousVirtualOutpaintFrame = _virtualOutpaintFrame;
      final previousCanvasSize = _state.canvasSize;
      final previousControllerScale = _state.canvasController.scale;
      final previousControllerOffset = _state.canvasController.offset;
      final previousSourceBytes = sourceBytes;
      final previousSourceOffset = sourceLayer?.baseImageOffset ?? Offset.zero;
      final previousActiveLayerId = _state.layerManager.activeLayerId;
      final previousToolId = _state.currentTool?.id;
      final previousSelectionPath = _state.selectionPath == null
          ? null
          : Path.from(_state.selectionPath!);
      final previousPreviewPath = _state.previewPath == null
          ? null
          : Path.from(_state.previewPath!);

      void restoreOutpaintTrackingFields() {
        _outpaintSourceImage = previousOutpaintSourceImage;
        _outpaintSourceWidth = previousOutpaintSourceWidth;
        _outpaintSourceHeight = previousOutpaintSourceHeight;
        _hasOutpaintChanges = previousHasOutpaintChanges;
        _virtualOutpaintFrame = previousVirtualOutpaintFrame;
      }

      void restoreScreenState() {
        restoreOutpaintTrackingFields();
        _state.setCanvasSize(previousCanvasSize);
        _refreshCompressionPlan(desiredScale: compressionScale);
        _state.setSelection(previousSelectionPath, saveHistory: false);
        _state.setPreviewPath(previousPreviewPath);
        if (previousToolId != null) {
          _state.setToolById(previousToolId);
        }
        if (previousActiveLayerId != null &&
            _state.layerManager.getLayerById(previousActiveLayerId) != null) {
          _state.layerManager.setActiveLayer(previousActiveLayerId);
        }
        _state.canvasController.runBatch(() {
          _state.canvasController.setScale(previousControllerScale);
          _state.canvasController.setOffset(previousControllerOffset);
        });
      }

      _state.canvasController.beginBatch();
      try {
        await _state.runBatchAsync(() async {
          await _state.layerManager.runBatchAsync(() async {
            Layer? maskLayer;
            var sourceReplaced = false;

            Future<void> rollbackTransaction() async {
              if (maskLayer != null) {
                _state.layerManager.removeLayer(maskLayer.id);
              }
              if (sourceReplaced) {
                await _state.layerManager.replaceLayerImage(
                  sourceLayerId,
                  previousSourceBytes,
                );
                _state.layerManager
                    .getLayerById(sourceLayerId)
                    ?.setBaseImageOffset(previousSourceOffset);
              }
              restoreScreenState();
            }

            try {
              if (overlayBytes != null) {
                maskLayer = await _addMaskLayerAboveSource(
                  overlayBytes,
                  name: maskLayerName,
                );
                if (maskLayer == null) {
                  throw Exception('Unable to add outpaint mask layer.');
                }
              }

              if (widget.debugFailOutpaintSourceReplacement) {
                throw StateError(
                  'Simulated outpaint source replacement failure.',
                );
              }

              final replaced = await _state.layerManager.replaceLayerImage(
                sourceLayerId,
                result.sourceImage,
              );
              if (!replaced) {
                throw Exception('Unable to replace current source image.');
              }
              sourceReplaced = true;

              _outpaintSourceImage = result.sourceImage;
              _outpaintSourceWidth = result.width;
              _outpaintSourceHeight = result.height;
              _hasOutpaintChanges = true;
              _virtualOutpaintFrame = OutpaintVirtualFrame.fromSource(
                sourceWidth: result.width,
                sourceHeight: result.height,
              );

              _state.setCanvasSize(resizedCanvasSize);
              _state.canvasController.fitToViewport(_state.canvasSize);

              if (maskLayer != null) {
                _removeAllMaskLayers(preservedLayerIds: {maskLayer.id});
              } else {
                _removeAllMaskLayers();
                _addEmptyMaskLayerAboveSource(name: maskLayerName);
              }
              _state.requestUiUpdate();
            } catch (_) {
              await rollbackTransaction();
              rethrow;
            }
          });
        });
      } finally {
        _state.canvasController.endBatch();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Apply outpaint failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOutpaintCommitPending = false;
        });
      } else {
        _isOutpaintCommitPending = false;
      }
    }
  }

  void _resetInpaintMask() {
    if (!_isInpaintMode) {
      _state.clearActiveLayerWithHistory();
      return;
    }

    _state.historyManager.execute(ClearInpaintMasksAction(), _state);
    _state.clearPreview();
    _refreshCompressionPlan();
    _state.requestUiUpdate();
    setState(() {});
  }

  Widget _buildDroppedImageLayerRegion(Widget child) {
    if (_isInpaintMode || widget.debugDisableDropRegion) {
      return child;
    }

    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (_isImportingDroppedImage) {
          return DropOperation.none;
        }

        final isInternalDrag = event.session.items.any(
          (item) => isGalleryInternalDragLocalData(item.localData),
        );
        if (isInternalDrag) {
          return DropOperation.none;
        }

        return event.session.allowedOperations.contains(DropOperation.copy)
            ? DropOperation.copy
            : DropOperation.none;
      },
      onPerformDrop: (event) async {
        unawaited(_handleDroppedImageLayerDrop(event));
      },
      child: child,
    );
  }

  Future<void> _handleDroppedImageLayerDrop(PerformDropEvent event) async {
    if (_isInpaintMode || _isImportingDroppedImage) {
      return;
    }

    setState(() => _isImportingDroppedImage = true);
    try {
      var handledAny = false;
      final generationState = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(imageGenerationNotifierProvider);
      for (final item in event.session.items) {
        final internalPayload = resolveInternalHistoryDropPayload(
          item.localData,
          generationState,
        );
        if (internalPayload != null) {
          handledAny = true;
          await _importDroppedImageLayer(
            internalPayload.fileName,
            internalPayload.bytes,
          );
          continue;
        }

        final reader = item.dataReader;
        if (reader == null) {
          continue;
        }

        final fileData = await DroppedFileReader.read(
          reader,
          allowVibeFiles: false,
          logTag: 'ImageEditorDrop',
        );
        if (fileData == null) {
          continue;
        }

        handledAny = true;
        await _importDroppedImageLayer(fileData.fileName, fileData.bytes);
      }

      if (!handledAny && mounted) {
        AppToast.error(
          context,
          context.l10n.toast_unreadableDroppedImageSource,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingDroppedImage = false);
      } else {
        _isImportingDroppedImage = false;
      }
    }
  }

  Future<void> _importDroppedImageLayer(
    String fileName,
    Uint8List imageBytes,
  ) async {
    if (!mounted || _isInpaintMode) {
      return;
    }

    final l10n = context.l10n;
    if (imageBytes.isEmpty) {
      AppLogger.w('Dropped image is empty: $fileName', 'ImageEditorDrop');
      AppToast.error(context, l10n.editor_emptyImageFile);
      return;
    }
    if (imageBytes.length > _maxImportedImageBytes) {
      final sizeMB = (imageBytes.length / (1024 * 1024)).toStringAsFixed(1);
      AppLogger.w(
        'Dropped image too large: ${imageBytes.length} bytes',
        'ImageEditorDrop',
      );
      AppToast.error(context, l10n.editor_fileTooLarge(sizeMB));
      return;
    }

    try {
      final layerBytes = await _coverDroppedImageToCanvas(imageBytes);
      if (!mounted) {
        return;
      }

      final layer = await _state.layerManager.addLayerFromImage(
        layerBytes,
        name: _droppedImageLayerName(fileName),
        index: _isInpaintMode ? 0 : null,
      );
      if (!mounted) {
        return;
      }
      if (layer == null) {
        AppToast.error(context, l10n.editor_parseImageFailed);
        return;
      }

      _state.clearSelection(saveHistory: false);
      _state.clearPreview();
      _state.requestUiUpdate();
      setState(() {});
    } catch (e) {
      AppLogger.w(
        'Failed to import dropped image layer: $fileName, error=$e',
        'ImageEditorDrop',
      );
      if (mounted) {
        AppToast.error(context, l10n.editor_parseImageFailed);
      }
    }
  }

  Future<Uint8List> _coverDroppedImageToCanvas(Uint8List imageBytes) async {
    final canvasWidth = _state.canvasSize.width.round();
    final canvasHeight = _state.canvasSize.height.round();
    final targetWidth = canvasWidth < 1 ? 1 : canvasWidth;
    final targetHeight = canvasHeight < 1 ? 1 : canvasHeight;

    ui.Codec? codec;
    ui.Image? sourceImage;
    ui.Image? targetImage;
    try {
      codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      sourceImage = frame.image;

      if (sourceImage.width == targetWidth &&
          sourceImage.height == targetHeight) {
        return imageBytes;
      }

      final sourceAspect = sourceImage.width / sourceImage.height;
      final targetAspect = targetWidth / targetHeight;
      final Rect sourceRect;
      if (sourceAspect > targetAspect) {
        final cropWidth = sourceImage.height * targetAspect;
        sourceRect = Rect.fromLTWH(
          (sourceImage.width - cropWidth) / 2,
          0,
          cropWidth,
          sourceImage.height.toDouble(),
        );
      } else {
        final cropHeight = sourceImage.width / targetAspect;
        sourceRect = Rect.fromLTWH(
          0,
          (sourceImage.height - cropHeight) / 2,
          sourceImage.width.toDouble(),
          cropHeight,
        );
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        sourceImage,
        sourceRect,
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      targetImage = await recorder.endRecording().toImage(
        targetWidth,
        targetHeight,
      );
      final byteData = await targetImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        throw StateError('Failed to encode dropped image layer');
      }
      return byteData.buffer.asUint8List();
    } finally {
      targetImage?.dispose();
      sourceImage?.dispose();
      codec?.dispose();
    }
  }

  String _droppedImageLayerName(String fileName) {
    final trimmed = fileName.trim();
    return trimmed.isEmpty ? 'dropped_image.png' : trimmed;
  }

  Widget _buildCanvasArea() {
    final virtualOutpaintMaskRects =
        _virtualOutpaintFrame?.outpaintMaskRects ?? const <Rect>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: EditorCanvas(
                  state: _state,
                  showTransparentCanvasBackground: true,
                  shouldSuppressPointerInput: (position) =>
                      OutpaintEdgeDragOverlay.isResizeInteractionPoint(
                        localPosition: position,
                        viewportSize: constraints.biggest,
                        canvasSize: _state.canvasSize,
                        controller: _state.canvasController,
                      ),
                ),
              ),
            ),
            if (_isInpaintMode && virtualOutpaintMaskRects.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: VirtualOutpaintMaskPainter(
                        state: _state,
                        maskRects: virtualOutpaintMaskRects,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: OutpaintEdgeDragOverlay(
                canvasSize: _state.canvasSize,
                controller: _state.canvasController,
                enabled: !_isOutpaintCommitPending,
                onCommitted: _applyOutpaintEdges,
                onFrameResizeCommitted:
                    (
                      delta, {
                      required horizontalSnapTarget,
                      required verticalSnapTarget,
                    }) => _isInpaintMode
                    ? _applyOutpaintFrameDelta(
                        delta,
                        horizontalSnapTarget: horizontalSnapTarget,
                        verticalSnapTarget: verticalSnapTarget,
                        preserveViewport: true,
                      )
                    : Future<void>.sync(() {
                        _state.editSelection.commit();
                        _state.historyManager.execute(
                          ShiftEditCanvasAction(delta: delta),
                          _state,
                        );
                      }),
              ),
            ),
          ],
        );
      },
    );
  }
}
