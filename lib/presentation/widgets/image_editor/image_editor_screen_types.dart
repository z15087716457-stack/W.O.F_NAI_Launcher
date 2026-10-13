part of 'image_editor_screen.dart';

enum ImageEditorMode { edit, inpaint }

/// 图像编辑器返回结果
class ImageEditorResult {
  final bool generateAfterApply;
  final double? inpaintStrength;

  /// 修改后的图像（涂鸦合并）
  final Uint8List? modifiedImage;

  /// Inpainting蒙版图像
  final Uint8List? maskImage;
  final InpaintFocusRegion? inpaintFocusRegion;

  /// 是否有图像修改
  final bool hasImageChanges;

  /// 是否有蒙版修改
  final bool hasMaskChanges;

  /// Outpaint 扩展后的源图像
  final Uint8List? outpaintSourceImage;

  /// Outpaint 扩展后的源图像宽度
  final int? outpaintSourceWidth;

  /// Outpaint 扩展后的源图像高度
  final int? outpaintSourceHeight;

  /// 是否有 Outpaint 源图像修改
  final bool hasOutpaintChanges;

  /// 确认 Inpaint 编辑后采用的工作 source。
  final Uint8List? inpaintSourceImage;

  final int? inpaintSourceWidth;
  final int? inpaintSourceHeight;

  /// 工作 source 是否因 2560/64 规则或用户压缩发生规范化。
  final bool sourceWasNormalized;

  /// 用户确认后的实际输出/source 尺寸。
  final int? outputWidth;
  final int? outputHeight;

  /// 用户是否在编辑器中选择了低于工作画布的压缩目标。
  final bool compressionApplied;

  const ImageEditorResult({
    this.generateAfterApply = false,
    this.inpaintStrength,
    this.modifiedImage,
    this.maskImage,
    this.inpaintFocusRegion,
    this.hasImageChanges = false,
    this.hasMaskChanges = false,
    this.outpaintSourceImage,
    this.outpaintSourceWidth,
    this.outpaintSourceHeight,
    this.hasOutpaintChanges = false,
    this.inpaintSourceImage,
    this.inpaintSourceWidth,
    this.inpaintSourceHeight,
    this.sourceWasNormalized = false,
    this.outputWidth,
    this.outputHeight,
    this.compressionApplied = false,
  });
}

/// The virtual frame keeps source pixels intact, so reversible geometry changes
/// can share the mask history without encoding an image on each resize.
class _VirtualOutpaintFrameAction extends EditorAction {
  _VirtualOutpaintFrameAction({
    required this.screen,
    required this.before,
    required this.after,
    required this.shift,
    required this.layerIds,
    required this.compressionScale,
    required this.beforeFocus,
    required this.afterFocus,
    this.preserveViewport = false,
  });
  final _ImageEditorScreenState screen;
  final OutpaintVirtualFrame before, after;
  final Offset shift;
  final List<String> layerIds;
  final double compressionScale;
  final Rect? beforeFocus, afterFocus;
  final bool preserveViewport;
  @override
  void execute(EditorState state) => screen._applyVirtualOutpaintHistoryFrame(
    after,
    shift,
    layerIds,
    compressionScale,
    afterFocus,
    preserveViewport,
  );
  @override
  void undo(EditorState state) => screen._applyVirtualOutpaintHistoryFrame(
    before,
    -shift,
    layerIds,
    compressionScale,
    beforeFocus,
    preserveViewport,
  );
  @override
  String get description => 'Shift Edges';
}
