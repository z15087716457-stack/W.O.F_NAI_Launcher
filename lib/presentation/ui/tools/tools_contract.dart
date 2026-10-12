import 'package:flutter/widgets.dart';

/// 画布工具的契约：工具条落下的两块面板（增强 / 放大设置）、画布编辑器（编辑图像 / 局部重绘）、导演工具。
/// 界面只吃这里的数据和回调；接线方（`wiring/`）读 provider 组装数据，把回调接到 service。
///
/// 价格一律由接线方按现有规则算好（`AnlasCalculator`、Opus 免费规则）：`int` = 要花的 Anlas，
/// `0` = 这次免费（界面写“免费”，不写“0”），`null` = 正在算 / 不显示。

// ───────────────────────── 通用 ─────────────────────────

@immutable
class ToolsOption {
  const ToolsOption({
    required this.id,
    required this.label,
    this.detail,
    this.enabled = true,
  });
  final String id;
  final String label;

  /// 弱色补充（模型大小、“未安装”）。
  final String? detail;
  final bool enabled;
}

// ───────────────────────── 增强面板 ─────────────────────────

/// 增强的放大档：倍数写成 `'1'` / `'1.5'` / `'2'`，另有 [max]（V5 Max✨，服务端端到端放大）
/// 和 [local]（按当前草稿生成，每张完成后在本机放大）。
abstract final class ToolsEnhanceScale {
  static const max = 'max';
  static const local = 'local';

  /// 倍数档的 id（`1.0` → `'1'`，`1.5` → `'1.5'`）。
  static String factor(double f) =>
      f == f.roundToDouble() ? '${f.toInt()}' : '$f';
}

/// 增强设置里的本机放大摘要（`localUpscale` 档）。
@immutable
class ToolsLocalUpscale {
  const ToolsLocalUpscale({
    required this.label,
    required this.factor,
    this.ready = true,
  });

  /// 本机放大模型名，例如“SeedVR2 3B FP8”。
  final String label;
  final double factor;

  /// 模型装好了（绿点）；false = 灰点，按钮仍可点去放大设置。
  final bool ready;
}

@immutable
class ToolsEnhanceData {
  const ToolsEnhanceData({
    required this.sourceWidth,
    required this.sourceHeight,
    this.scales = const ['1', '1.5'],
    this.scale = '1',
    this.outWidth,
    this.outHeight,
    this.magnitude = 3,
    this.strength = .5,
    this.noise = 0,
    this.custom = false,
    this.local,
    this.model = '',
    this.steps = 28,
    this.cost,
    this.insufficient = false,
    this.busy = false,
  });

  final int sourceWidth;
  final int sourceHeight;

  /// 能选的放大档（`availableEnhanceFactors` + `isEnhanceMaxUpscaleEligible` + 本地放大）；
  /// 832 × 1216 只有 1× 和 1.5×，V4.5 没有 Max。顺序即显示顺序。
  final List<String> scales;
  final String scale;

  /// 这一档的输出尺寸（本地放大档给 null，界面写“本机 2×”）。
  final int? outWidth;
  final int? outHeight;

  /// 幅度 1–5（`magnitude * 4 + 1`）；[custom] 时分段变灰。
  final int magnitude;

  /// 实际发出去的强度 / 噪声：幅度档时是档位预设（`_resolveMagnitude`），自定义时是滑杆值。
  final double strength;
  final double noise;

  /// 自定义强度和噪声（原“显示高级设置”，`showIndividualSettings`）。
  final bool custom;

  /// 本地放大档的摘要；[scale] 不是 [ToolsEnhanceScale.local] 时不用。
  final ToolsLocalUpscale? local;

  /// 底部一句“用当前提示词 · 模型 · 步数”。
  final String model;
  final int steps;

  final int? cost;

  /// 余额不够：价格变红，按钮仍可点（接线方弹余额说明）。
  final bool insufficient;

  /// 生成中 / 工具在跑：面板里的控件不可点。
  final bool busy;

  bool get isLocal => scale == ToolsEnhanceScale.local;

  ToolsEnhanceData copyWith({
    String? scale,
    int? outWidth,
    int? outHeight,
    int? magnitude,
    double? strength,
    double? noise,
    bool? custom,
    int? cost,
    bool? busy,
  }) => ToolsEnhanceData(
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    scales: scales,
    scale: scale ?? this.scale,
    outWidth: outWidth ?? this.outWidth,
    outHeight: outHeight ?? this.outHeight,
    magnitude: magnitude ?? this.magnitude,
    strength: strength ?? this.strength,
    noise: noise ?? this.noise,
    custom: custom ?? this.custom,
    local: local,
    model: model,
    steps: steps,
    cost: cost ?? this.cost,
    insufficient: insufficient,
    busy: busy ?? this.busy,
  );
}

@immutable
class ToolsEnhanceActions {
  const ToolsEnhanceActions({
    required this.onScale,
    required this.onMagnitude,
    required this.onCustom,
    required this.onStrength,
    required this.onNoise,
    required this.onOpenUpscaleSettings,
    required this.onRun,
    required this.onClose,
  });

  factory ToolsEnhanceActions.logging(ValueChanged<String> log) =>
      ToolsEnhanceActions(
        onScale: (v) => log('onScale($v)'),
        onMagnitude: (v) => log('onMagnitude($v)'),
        onCustom: (v) => log('onCustom($v)'),
        onStrength: (v) => log('onStrength($v)'),
        onNoise: (v) => log('onNoise($v)'),
        onOpenUpscaleSettings: () => log('onOpenUpscaleSettings'),
        onRun: () => log('onRun'),
        onClose: () => log('onClose'),
      );

  /// 选放大档（`updateEnhanceUpscaleFactor` / `setEnhanceMaxUpscale` / `setEnhanceLocalUpscale`）。
  final ValueChanged<String> onScale;
  final ValueChanged<int> onMagnitude;
  final ValueChanged<bool> onCustom;
  final ValueChanged<double> onStrength;
  final ValueChanged<double> onNoise;

  /// 本地放大档的“放大设置”：关掉增强面板、打开放大设置面板。
  final VoidCallback onOpenUpscaleSettings;

  /// 主按钮 / Ctrl+Enter：按当前设置增强（和左栏“增强”同一个动作）。
  final VoidCallback onRun;

  /// × / 取消 / Esc：退出增强（`closeTemporaryTool`）。
  final VoidCallback onClose;
}

// ───────────────────────── 放大设置面板 ─────────────────────────

/// 放大方式卡片：本机 / NovelAI 云端（以后接 ComfyUI 可以再加一张）。
@immutable
class ToolsUpscaleBackend {
  const ToolsUpscaleBackend({
    required this.id,
    required this.title,
    required this.detail,
    this.cost,
    this.enabled = true,
  });
  final String id;
  final String title;

  /// 一句说明（“用本机显卡 · 只支持 Windows”“官方放大 · 输入上限约 2.8 MP”）。
  final String detail;

  /// null = 免费（卡片角标写“免费”）。
  final int? cost;

  /// 不能用（非 Windows 没有本机放大）：卡片变灰，[detail] 写原因。
  final bool enabled;
}

enum ToolsModelState { ready, missing, downloading }

@immutable
class ToolsUpscaleModel {
  const ToolsUpscaleModel({
    required this.id,
    required this.label,
    this.state = ToolsModelState.ready,
    this.detail,
  });
  final String id;
  final String label;
  final ToolsModelState state;

  /// 菜单里的弱色补充（大小、显存建议）。
  final String? detail;
}

enum ToolsFieldKind { number, toggle, choice }

/// 高级设置的一项（SeedVR2 显存分块、VAE 分块、噪声、种子、色彩校正……），由接线方按方法给。
@immutable
class ToolsUpscaleField {
  const ToolsUpscaleField({
    required this.id,
    required this.label,
    required this.kind,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.decimals = 0,
    this.options = const [],
    this.hint,
  });
  final String id;
  final String label;
  final ToolsFieldKind kind;

  /// number → `double`，toggle → `bool`，choice → 选中的 [ToolsOption.id]。
  final Object value;
  final double min;
  final double max;
  final int decimals;
  final List<ToolsOption> options;

  /// 悬停说明。
  final String? hint;
}

@immutable
class ToolsUpscaleData {
  const ToolsUpscaleData({
    required this.backends,
    required this.backend,
    required this.sourceWidth,
    required this.sourceHeight,
    this.methods = const [],
    this.method,
    this.models = const [],
    this.model,
    this.scale,
    this.minScale = 1,
    this.maxScale = 4,
    this.outWidth,
    this.outHeight,
    this.advanced = const [],
    this.advancedHint,
    this.cost,
    this.running = false,
    this.blocked,
  });

  final List<ToolsUpscaleBackend> backends;
  final String backend;
  final int sourceWidth;
  final int sourceHeight;

  /// 本机放大的方法（普通模型 / SeedVR2 / RTX）；空 = 这一行不显示（云端）。
  final List<ToolsOption> methods;
  final String? method;

  /// 当前方法下的模型（带安装状态）；空 = 这一行不显示（RTX、云端）。
  final List<ToolsUpscaleModel> models;
  final String? model;

  /// 倍数；null = 这一行不显示（云端固定倍数，输出尺寸写在卡片里）。
  final double? scale;
  final double minScale;
  final double maxScale;

  final int? outWidth;
  final int? outHeight;

  /// 高级设置（只有 SeedVR2 有）；空 = 不显示折叠行。
  final List<ToolsUpscaleField> advanced;

  /// 折叠行后面的一句弱色摘要。
  final String? advancedHint;

  /// 云端价格；null = 免费。
  final int? cost;
  final bool running;

  /// 不能放大的原因（模型没装、超过输入上限）：主按钮不可点，原因写在底栏。
  final String? blocked;

  ToolsUpscaleModel? get currentModel =>
      models.where((m) => m.id == model).firstOrNull;

  ToolsUpscaleData copyWith({
    String? method,
    String? model,
    double? scale,
    int? outWidth,
    int? outHeight,
    List<ToolsUpscaleField>? advanced,
    bool? running,
    String? blocked,
    bool clearBlocked = false,
  }) => ToolsUpscaleData(
    backends: backends,
    backend: backend,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    methods: methods,
    method: method ?? this.method,
    models: models,
    model: model ?? this.model,
    scale: scale ?? this.scale,
    minScale: minScale,
    maxScale: maxScale,
    outWidth: outWidth ?? this.outWidth,
    outHeight: outHeight ?? this.outHeight,
    advanced: advanced ?? this.advanced,
    advancedHint: advancedHint,
    cost: cost,
    running: running ?? this.running,
    blocked: clearBlocked ? null : blocked ?? this.blocked,
  );
}

@immutable
class ToolsUpscaleActions {
  const ToolsUpscaleActions({
    required this.onBackend,
    required this.onMethod,
    required this.onModel,
    required this.onManageModels,
    required this.onScale,
    required this.onAdvanced,
    required this.onRun,
    required this.onClose,
  });

  factory ToolsUpscaleActions.logging(ValueChanged<String> log) =>
      ToolsUpscaleActions(
        onBackend: (v) => log('onBackend($v)'),
        onMethod: (v) => log('onMethod($v)'),
        onModel: (v) => log('onModel($v)'),
        onManageModels: () => log('onManageModels'),
        onScale: (v) => log('onScale($v)'),
        onAdvanced: (id, value) => log('onAdvanced($id, $value)'),
        onRun: () => log('onRun'),
        onClose: () => log('onClose'),
      );

  final ValueChanged<String> onBackend;
  final ValueChanged<String> onMethod;
  final ValueChanged<String> onModel;

  /// “管理模型”：打开设置页的本机放大一节（下载 / 删除模型）。
  final VoidCallback onManageModels;
  final ValueChanged<double> onScale;
  final void Function(String id, Object value) onAdvanced;

  /// 主按钮：按这套设置放大当前这张（设置会记住，工具条上的“放大”也用它）。
  final VoidCallback onRun;
  final VoidCallback onClose;
}

// ───────────────────────── 画布编辑器 ─────────────────────────

enum ToolsEditorMode {
  /// 编辑图像：画完替换图生图底图。
  edit,

  /// 局部重绘：画蒙版，只重画蒙版里的地方。
  inpaint,
}

/// 左侧工具栏的工具。编辑模式：画笔、橡皮、填充、模糊、仿制图章 │ 矩形选区、套索、吸管；
/// 局部重绘：画蒙版、擦蒙版、填充、聚焦区域。
enum ToolsTool {
  brush,
  eraser,
  fill,
  blur,
  stamp,
  select,
  lasso,
  picker,
  focus,
}

enum ToolsBrushTip { hard, soft, square }

/// 当前工具的选项（选项条按非 null 的项横排）。
@immutable
class ToolsToolOptions {
  const ToolsToolOptions({
    this.size,
    this.minSize = 1,
    this.maxSize = 500,
    this.opacity,
    this.tip,
    this.pressure,
    this.square,
    this.tolerance,
    this.intensity,
  });

  /// 笔刷大小（像素）。
  final double? size;
  final double minSize;
  final double maxSize;

  /// 不透明度 0–1。
  final double? opacity;

  /// 笔尖（硬 / 软 / 方，`hardness` 1 / 0.3 / 方形笔刷）。
  final ToolsBrushTip? tip;

  /// 压感。
  final bool? pressure;

  /// 局部重绘的方形笔刷（蒙版按 8 像素网格对齐）。
  final bool? square;

  /// 填充容差 0–100。
  final int? tolerance;

  /// 模糊强度 0–1。
  final double? intensity;

  ToolsToolOptions copyWith({
    double? size,
    double? opacity,
    ToolsBrushTip? tip,
    bool? pressure,
    bool? square,
    int? tolerance,
    double? intensity,
  }) => ToolsToolOptions(
    size: size ?? this.size,
    minSize: minSize,
    maxSize: maxSize,
    opacity: opacity ?? this.opacity,
    tip: tip ?? this.tip,
    pressure: pressure ?? this.pressure,
    square: square ?? this.square,
    tolerance: tolerance ?? this.tolerance,
    intensity: intensity ?? this.intensity,
  );
}

/// 蒙版外观的花纹（`MaskDisplayPattern`）。只影响显示，不改蒙版像素。
enum ToolsMaskPattern { solid, lines, crosshatch, grid, dots, checker, hearts }

@immutable
class ToolsMaskLook {
  const ToolsMaskLook({
    required this.color,
    this.pattern = ToolsMaskPattern.solid,
    this.opacity = .55,
    this.border = false,
  });
  final Color color;
  final ToolsMaskPattern pattern;
  final double opacity;

  /// 蒙版描边（`maskDisplayBorder`）。
  final bool border;

  ToolsMaskLook copyWith({
    Color? color,
    ToolsMaskPattern? pattern,
    double? opacity,
    bool? border,
  }) => ToolsMaskLook(
    color: color ?? this.color,
    pattern: pattern ?? this.pattern,
    opacity: opacity ?? this.opacity,
    border: border ?? this.border,
  );
}

enum ToolsLayerKind { paint, base, mask, model3d }

@immutable
class ToolsLayer {
  const ToolsLayer({
    required this.id,
    required this.name,
    required this.kind,
    this.detail,
    this.visible = true,
    this.locked = false,
    this.thumb,
  });
  final String id;
  final String name;
  final ToolsLayerKind kind;

  /// 名字下面一行（“画笔 · 3 笔”“832 × 1216”“原图，不会被修改”）。
  final String? detail;
  final bool visible;

  /// 底图锁定：不能删、不能挪。
  final bool locked;

  /// 图层缩略图；蒙版层 / 无图时界面自己画。
  final ImageProvider? thumb;
}

enum ToolsLayerAction { up, down, duplicate, merge, delete }

/// 调整颜色（原盖在画面上的弹窗，`edit_hsv_panel`）：作用在当前图层，拖动实时预览。
@immutable
class ToolsAdjust {
  const ToolsAdjust({this.hue = 0, this.saturation = 0, this.brightness = 0});

  /// −180–180。
  final int hue;

  /// −100–100。
  final int saturation;
  final int brightness;

  bool get isZero => hue == 0 && saturation == 0 && brightness == 0;

  ToolsAdjust copyWith({int? hue, int? saturation, int? brightness}) =>
      ToolsAdjust(
        hue: hue ?? this.hue,
        saturation: saturation ?? this.saturation,
        brightness: brightness ?? this.brightness,
      );
}

/// 扩展边缘（原“扩展边缘”弹窗）：四边各加多少像素，按 [step] 取整。
@immutable
class ToolsExpand {
  const ToolsExpand({
    this.top = 0,
    this.bottom = 0,
    this.left = 0,
    this.right = 0,
    this.step = 64,
    this.max = 1024,
  });
  final int top;
  final int bottom;
  final int left;
  final int right;
  final int step;
  final int max;

  bool get isZero => top == 0 && bottom == 0 && left == 0 && right == 0;

  ToolsExpand copyWith({int? top, int? bottom, int? left, int? right}) =>
      ToolsExpand(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
        left: left ?? this.left,
        right: right ?? this.right,
        step: step,
        max: max,
      );
}

/// 局部重绘右栏“重绘设置”。
@immutable
class ToolsInpaintInfo {
  const ToolsInpaintInfo({
    this.strength = 1,
    this.coverage = 0,
    this.regions = 0,
    this.focusWidth,
    this.focusHeight,
    this.focusContext = 64,
    this.maxFocusContext = 256,
  });

  /// 重绘强度（就是左栏图生图那个 `inpaintStrength`，两边同步）。
  final double strength;

  /// 蒙版占画面比例 0–1、几块。
  final double coverage;
  final int regions;

  /// 聚焦区域尺寸；null = 未设置（整张图）。
  final int? focusWidth;
  final int? focusHeight;

  /// 聚焦区域的最小上下文（像素）。
  final int focusContext;
  final int maxFocusContext;

  bool get hasFocus => focusWidth != null && focusHeight != null;
}

@immutable
class ToolsEditorData {
  const ToolsEditorData({
    required this.mode,
    required this.width,
    required this.height,
    this.image,
    this.zoom = 1,
    this.canUndo = false,
    this.canRedo = false,
    this.dirty = false,
    this.tool = ToolsTool.brush,
    this.shortcuts = defaultShortcuts,
    this.options = const ToolsToolOptions(),
    this.primary = const Color(0xFFE94B6A),
    this.secondary = const Color(0xFFFFFFFF),
    this.mask = const ToolsMaskLook(color: Color(0xFF4F8CFF)),
    this.layers = const [],
    this.layer,
    this.adjust = const ToolsAdjust(),
    this.inpaint = const ToolsInpaintInfo(),
    this.expanding = false,
    this.expand = const ToolsExpand(),
    this.cursor,
    this.applyCost,
    this.insufficient = false,
    this.shellShortcuts = true,
  });

  final ToolsEditorMode mode;

  /// 画布尺寸（编辑模式可改，局部重绘扩展后是扩展前的尺寸）。
  final int width;
  final int height;

  /// 底图（界面自带的舞台用；接了画布引擎就不用）。
  final ImageProvider? image;

  /// 缩放比例（1 = 100%）。
  final double zoom;
  final bool canUndo;
  final bool canRedo;

  /// 有没保存的修改：返回 / 取消先确认。
  final bool dirty;

  final ToolsTool tool;

  /// 工具快捷键字母（显示在工具角上，界面也按它切工具）；接线方给引擎实际绑定的键。
  final Map<ToolsTool, String> shortcuts;
  final ToolsToolOptions options;

  /// 前景色 / 背景色（X 交换）。
  final Color primary;
  final Color secondary;

  /// 蒙版外观（局部重绘）。
  final ToolsMaskLook mask;

  /// 图层，顶层在前。
  final List<ToolsLayer> layers;
  final String? layer;

  final ToolsAdjust adjust;
  final ToolsInpaintInfo inpaint;

  /// 正在扩展边缘（选项条换成四个数字）。
  final bool expanding;
  final ToolsExpand expand;

  /// 鼠标在图上的像素坐标；null = 不在图上。
  final Offset? cursor;

  /// “应用并生成”的价格（局部重绘）。
  final int? applyCost;
  final bool insufficient;

  /// true：界面按 [shortcuts] 切工具、`[` `]` 调大小、X 交换颜色。接了自带快捷键的画布引擎时给 false，
  /// 界面只处理 Esc 和 Ctrl+Enter。
  final bool shellShortcuts;

  bool get inpainting => mode == ToolsEditorMode.inpaint;

  int get outWidth => width + (inpainting ? expand.left + expand.right : 0);
  int get outHeight => height + (inpainting ? expand.top + expand.bottom : 0);

  /// 原型给的字母（编辑模式也能用 B / E / G…）。
  static const defaultShortcuts = {
    ToolsTool.brush: 'B',
    ToolsTool.eraser: 'E',
    ToolsTool.fill: 'G',
    ToolsTool.blur: 'U',
    ToolsTool.stamp: 'S',
    ToolsTool.select: 'M',
    ToolsTool.lasso: 'L',
    ToolsTool.picker: 'P',
    ToolsTool.focus: 'Q',
  };

  static const editTools = [
    ToolsTool.brush,
    ToolsTool.eraser,
    ToolsTool.fill,
    ToolsTool.blur,
    ToolsTool.stamp,
    ToolsTool.select,
    ToolsTool.lasso,
    ToolsTool.picker,
  ];

  static const inpaintTools = [
    ToolsTool.brush,
    ToolsTool.eraser,
    ToolsTool.fill,
    ToolsTool.focus,
  ];

  ToolsLayer? get activeLayer => layers.where((l) => l.id == layer).firstOrNull;

  ToolsEditorData copyWith({
    ToolsEditorMode? mode,
    int? width,
    int? height,
    double? zoom,
    bool? canUndo,
    bool? canRedo,
    bool? dirty,
    ToolsTool? tool,
    ToolsToolOptions? options,
    Color? primary,
    Color? secondary,
    ToolsMaskLook? mask,
    List<ToolsLayer>? layers,
    String? layer,
    ToolsAdjust? adjust,
    ToolsInpaintInfo? inpaint,
    bool? expanding,
    ToolsExpand? expand,
    int? applyCost,
  }) => ToolsEditorData(
    mode: mode ?? this.mode,
    width: width ?? this.width,
    height: height ?? this.height,
    image: image,
    zoom: zoom ?? this.zoom,
    canUndo: canUndo ?? this.canUndo,
    canRedo: canRedo ?? this.canRedo,
    dirty: dirty ?? this.dirty,
    tool: tool ?? this.tool,
    shortcuts: shortcuts,
    options: options ?? this.options,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    mask: mask ?? this.mask,
    layers: layers ?? this.layers,
    layer: layer ?? this.layer,
    adjust: adjust ?? this.adjust,
    inpaint: inpaint ?? this.inpaint,
    expanding: expanding ?? this.expanding,
    expand: expand ?? this.expand,
    cursor: cursor,
    applyCost: applyCost ?? this.applyCost,
    insufficient: insufficient,
    shellShortcuts: shellShortcuts,
  );
}

/// 颜色、图层菜单从哪弹：组件的全局矩形。
typedef ToolsAnchorCallback = void Function(Rect anchor);

@immutable
class ToolsEditorActions {
  const ToolsEditorActions({
    required this.onBack,
    required this.onApply,
    required this.onApplyAndGenerate,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomFit,
    required this.onUndo,
    required this.onRedo,
    required this.onDownload,
    required this.onTool,
    required this.onOptions,
    required this.onColor,
    required this.onSwapColors,
    required this.onMoreColors,
    required this.onMaskLook,
    required this.onAddLayer,
    required this.onAdd3dLayer,
    required this.onSelectLayer,
    required this.onLayerVisible,
    required this.onLayerAction,
    required this.onAdjust,
    required this.onAdjustReset,
    required this.onAdjustApply,
    required this.onResizeCanvas,
    required this.onClearMask,
    required this.onExpanding,
    required this.onExpand,
    required this.onFocusContext,
    required this.onClearFocus,
    required this.onInpaintStrength,
  });

  factory ToolsEditorActions.logging(
    ValueChanged<String> log,
  ) => ToolsEditorActions(
    onBack: () => log('onBack'),
    onApply: () => log('onApply'),
    onApplyAndGenerate: () => log('onApplyAndGenerate'),
    onZoomIn: () => log('onZoomIn'),
    onZoomOut: () => log('onZoomOut'),
    onZoomFit: () => log('onZoomFit'),
    onUndo: () => log('onUndo'),
    onRedo: () => log('onRedo'),
    onDownload: () => log('onDownload'),
    onTool: (v) => log('onTool(${v.name})'),
    onOptions: (v) => log(
      'onOptions(size: ${v.size}, opacity: ${v.opacity}, tip: ${v.tip?.name}, '
      'pressure: ${v.pressure}, square: ${v.square}, '
      'tolerance: ${v.tolerance}, intensity: ${v.intensity})',
    ),
    onColor: (color, {required secondary}) => log(
      'onColor(${color.toARGB32().toRadixString(16)}, secondary: $secondary)',
    ),
    onSwapColors: () => log('onSwapColors'),
    onMoreColors: (_) => log('onMoreColors'),
    onMaskLook: (v) => log(
      'onMaskLook(${v.color.toARGB32().toRadixString(16)}, ${v.pattern.name}, '
      '${v.opacity.toStringAsFixed(2)}, border: ${v.border})',
    ),
    onAddLayer: () => log('onAddLayer'),
    onAdd3dLayer: () => log('onAdd3dLayer'),
    onSelectLayer: (v) => log('onSelectLayer($v)'),
    onLayerVisible: (id, v) => log('onLayerVisible($id, $v)'),
    onLayerAction: (id, a) => log('onLayerAction($id, ${a.name})'),
    onAdjust: (v) =>
        log('onAdjust(${v.hue}, ${v.saturation}, ${v.brightness})'),
    onAdjustReset: () => log('onAdjustReset'),
    onAdjustApply: () => log('onAdjustApply'),
    onResizeCanvas: () => log('onResizeCanvas'),
    onClearMask: () => log('onClearMask'),
    onExpanding: (v) => log('onExpanding($v)'),
    onExpand: (v) =>
        log('onExpand(${v.top}, ${v.bottom}, ${v.left}, ${v.right})'),
    onFocusContext: (v) => log('onFocusContext($v)'),
    onClearFocus: () => log('onClearFocus'),
    onInpaintStrength: (v) => log('onInpaintStrength($v)'),
  );

  /// 返回 / 取消 / Esc（有修改时界面先确认）：不保存，回生图页。
  final VoidCallback onBack;

  /// 主按钮 / Ctrl+Enter：编辑模式“用作图生图底图”，局部重绘“应用蒙版”（回生图页，侧栏切到局部重绘）。
  final VoidCallback onApply;

  /// 局部重绘下拉“应用并生成”：应用后立刻开始重绘。
  final VoidCallback onApplyAndGenerate;

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomFit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  /// 把当前画面存成 PNG。
  final VoidCallback onDownload;

  final ValueChanged<ToolsTool> onTool;
  final ValueChanged<ToolsToolOptions> onOptions;

  /// 色板里点了一个颜色（[secondary] = 改背景色）。
  final void Function(Color color, {required bool secondary}) onColor;
  final VoidCallback onSwapColors;

  /// 色板“更多颜色”：接线方弹现有取色器（`edit_color_picker`）。
  final ToolsAnchorCallback onMoreColors;
  final ValueChanged<ToolsMaskLook> onMaskLook;

  final VoidCallback onAddLayer;

  /// 加 3D 图层（`Model3dEditorScreen`）。
  final VoidCallback onAdd3dLayer;
  final ValueChanged<String> onSelectLayer;
  final void Function(String id, bool visible) onLayerVisible;
  final void Function(String id, ToolsLayerAction action) onLayerAction;

  /// 拖动调色滑杆（实时预览，不进历史）；“应用”才写进图层，“重置”回 0。
  final ValueChanged<ToolsAdjust> onAdjust;
  final VoidCallback onAdjustReset;
  final VoidCallback onAdjustApply;

  /// “更改尺寸”：接线方弹现有画布尺寸弹窗（`canvas_size_dialog`）。
  final VoidCallback onResizeCanvas;

  /// 清空蒙版（局部重绘）。
  final VoidCallback onClearMask;

  /// 进入 / 退出扩展边缘（“完成”退出）。
  final ValueChanged<bool> onExpanding;
  final ValueChanged<ToolsExpand> onExpand;
  final ValueChanged<int> onFocusContext;
  final VoidCallback onClearFocus;
  final ValueChanged<double> onInpaintStrength;
}

/// 画布引擎（`EditorCanvas` + 拖拽层）：平移缩放、笔画、蒙版、聚焦框、扩展手柄都在里面。
@immutable
class ToolsEditorSlots {
  const ToolsEditorSlots({this.canvas});

  /// null = 界面自带的舞台（只摆底图，预览 / 测试用）。
  final WidgetBuilder? canvas;
}

// ───────────────────────── 导演工具 ─────────────────────────

enum ToolsDirectorTool {
  removeBackground,
  declutter,
  lineArt,
  sketch,
  colorize,
  emotion,
  pixelSnap,
}

/// 舞台对比方式。
enum ToolsCompare { side, wipe, result }

/// 像素对齐的调色板（`PixelSnapPaletteMode`）。
enum ToolsPixelPalette { off, auto, custom }

@immutable
class ToolsPixelOptions {
  const ToolsPixelOptions({
    this.palette = ToolsPixelPalette.auto,
    this.colors = 64,
    this.avoidOverRefining = false,
    this.upscale = false,
  });
  final ToolsPixelPalette palette;

  /// 自定义调色板的颜色数 16–256。
  final int colors;
  final bool avoidOverRefining;
  final bool upscale;

  ToolsPixelOptions copyWith({
    ToolsPixelPalette? palette,
    int? colors,
    bool? avoidOverRefining,
    bool? upscale,
  }) => ToolsPixelOptions(
    palette: palette ?? this.palette,
    colors: colors ?? this.colors,
    avoidOverRefining: avoidOverRefining ?? this.avoidOverRefining,
    upscale: upscale ?? this.upscale,
  );
}

/// 输入队列里的一张。
@immutable
class ToolsDirectorInput {
  const ToolsDirectorInput({
    required this.id,
    required this.thumb,
    required this.width,
    required this.height,
  });
  final String id;
  final ImageProvider thumb;
  final int width;
  final int height;
}

/// 跑过的一次（结果列表的一行）。
@immutable
class ToolsDirectorRun {
  const ToolsDirectorRun({
    required this.id,
    required this.tool,
    required this.inputId,
    required this.images,
    required this.time,
    required this.width,
    required this.height,
    this.variants = const [],
    this.cost,
  });
  final String id;
  final ToolsDirectorTool tool;

  /// 用的是哪张输入（点这一行时舞台左边换成它）。
  final String inputId;

  /// 结果图；背景移除是三张（透明底 / 背景 / 合成）。
  final List<ImageProvider> images;

  /// 多张结果时每张的名字（和 [images] 一一对应）。
  final List<String> variants;
  final DateTime time;
  final int width;
  final int height;
  final int? cost;
}

/// 表情修复的表情（`emotionPresets` 的 mood），前 16 个常用，后 8 个折在“更多”里。
abstract final class ToolsEmotions {
  static const common = [
    'neutral',
    'happy',
    'sad',
    'angry',
    'scared',
    'surprised',
    'tired',
    'excited',
    'nervous',
    'thinking',
    'confused',
    'shy',
    'disgusted',
    'smug',
    'bored',
    'laughing',
  ];
  static const more = [
    'irritated',
    'aroused',
    'embarrassed',
    'worried',
    'love',
    'determined',
    'hurt',
    'playful',
  ];
}

@immutable
class ToolsDirectorData {
  const ToolsDirectorData({
    this.tool = ToolsDirectorTool.removeBackground,
    this.costs = const {},
    this.anlas,
    this.inputs = const [],
    this.input,
    this.runs = const [],
    this.run,
    this.variant = 0,
    this.defry = 0,
    this.prompt = '',
    this.emotion = 'neutral',
    this.pixel = const ToolsPixelOptions(),
    this.running = false,
    this.error,
    this.opusFree = true,
    this.now,
  });

  final ToolsDirectorTool tool;

  /// 每个工具这次要花的 Anlas（按当前输入尺寸算）；像素对齐在本机跑，不看这里。
  final Map<ToolsDirectorTool, int?> costs;

  /// 余额（顶栏胶囊）；null = 未登录 / 不显示。
  final int? anlas;

  /// 输入队列（新的在前）。
  final List<ToolsDirectorInput> inputs;

  /// 当前输入的 id。
  final String? input;

  /// 结果列表（新的在前）。
  final List<ToolsDirectorRun> runs;

  /// 舞台右边显示的那次；null = 还没有结果（运行前）。
  final String? run;

  /// 多张结果时看第几张。
  final int variant;

  /// 强度档 0–5（0 = 正常，5 = 最弱；上色、表情修复）。
  final int defry;

  /// 补充提示词（上色、表情修复）。
  final String prompt;

  /// 表情 mood（[ToolsEmotions]）。
  final String emotion;
  final ToolsPixelOptions pixel;

  final bool running;

  /// 上一次运行失败（舞台右边换成失败说明 + 重试）。
  final String? error;

  /// Opus 1 MP 以内免费：左栏底部写一句规则说明。
  final bool opusFree;

  /// 结果时间的“现在”（测试固定用）；null = `DateTime.now()`。
  final DateTime? now;

  ToolsDirectorInput? get currentInput =>
      inputs.where((i) => i.id == input).firstOrNull;
  ToolsDirectorRun? get currentRun =>
      runs.where((r) => r.id == run).firstOrNull;
  int? get cost => tool == ToolsDirectorTool.pixelSnap ? 0 : costs[tool];
  bool get canRun => !running && currentInput != null;

  ToolsDirectorData copyWith({
    ToolsDirectorTool? tool,
    List<ToolsDirectorInput>? inputs,
    String? input,
    bool clearInput = false,
    List<ToolsDirectorRun>? runs,
    String? run,
    bool clearRun = false,
    int? variant,
    int? defry,
    String? prompt,
    String? emotion,
    ToolsPixelOptions? pixel,
    bool? running,
    String? error,
    bool clearError = false,
  }) => ToolsDirectorData(
    tool: tool ?? this.tool,
    costs: costs,
    anlas: anlas,
    inputs: inputs ?? this.inputs,
    input: clearInput ? null : input ?? this.input,
    runs: runs ?? this.runs,
    run: clearRun ? null : run ?? this.run,
    variant: variant ?? this.variant,
    defry: defry ?? this.defry,
    prompt: prompt ?? this.prompt,
    emotion: emotion ?? this.emotion,
    pixel: pixel ?? this.pixel,
    running: running ?? this.running,
    error: clearError ? null : error ?? this.error,
    opusFree: opusFree,
    now: now,
  );
}

@immutable
class ToolsDirectorActions {
  const ToolsDirectorActions({
    required this.onBack,
    required this.onTool,
    required this.onSelectInput,
    required this.onRemoveInput,
    required this.onImportFiles,
    required this.onPickHistory,
    required this.onPaste,
    required this.onRun,
    required this.onSelectRun,
    required this.onReuseSettings,
    required this.onVariant,
    required this.onContinue,
    required this.onCopy,
    required this.onSave,
    required this.onUpscale,
    required this.onUseAsInit,
    required this.onDefry,
    required this.onPrompt,
    required this.onEmotion,
    required this.onPixel,
    required this.onDismissError,
  });

  factory ToolsDirectorActions.logging(
    ValueChanged<String> log,
  ) => ToolsDirectorActions(
    onBack: () => log('onBack'),
    onTool: (v) => log('onTool(${v.name})'),
    onSelectInput: (v) => log('onSelectInput($v)'),
    onRemoveInput: (v) => log('onRemoveInput($v)'),
    onImportFiles: () => log('onImportFiles'),
    onPickHistory: () => log('onPickHistory'),
    onPaste: () => log('onPaste'),
    onRun: () => log('onRun'),
    onSelectRun: (v) => log('onSelectRun($v)'),
    onReuseSettings: (v) => log('onReuseSettings($v)'),
    onVariant: (v) => log('onVariant($v)'),
    onContinue: () => log('onContinue'),
    onCopy: () => log('onCopy'),
    onSave: () => log('onSave'),
    onUpscale: () => log('onUpscale'),
    onUseAsInit: () => log('onUseAsInit'),
    onDefry: (v) => log('onDefry($v)'),
    onPrompt: (v) => log('onPrompt($v)'),
    onEmotion: (v) => log('onEmotion($v)'),
    onPixel: (v) => log(
      'onPixel(${v.palette.name}, ${v.colors}, ${v.avoidOverRefining}, ${v.upscale})',
    ),
    onDismissError: () => log('onDismissError'),
  );

  /// 返回生图（Esc）。
  final VoidCallback onBack;
  final ValueChanged<ToolsDirectorTool> onTool;
  final ValueChanged<String> onSelectInput;
  final ValueChanged<String> onRemoveInput;

  /// 加号菜单：导入文件 / 从生图历史选；Ctrl+V 粘贴。
  final VoidCallback onImportFiles;
  final VoidCallback onPickHistory;
  final VoidCallback onPaste;

  /// 运行按钮 / Ctrl+Enter / 失败卡“重试”：处理当前输入。
  final VoidCallback onRun;

  /// 点结果列表一行：回看（舞台左边换成它的输入）。
  final ValueChanged<String> onSelectRun;

  /// 结果行“沿用设置”（原 Ctrl+点击）：工具和选项换成那次的。
  final ValueChanged<String> onReuseSettings;
  final ValueChanged<int> onVariant;

  // 结果操作（作用在当前结果的当前那张）
  /// 继续处理：结果加入输入队列并选中。
  final VoidCallback onContinue;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  /// 放大：带着这张回生图页走放大。
  final VoidCallback onUpscale;

  /// 用作图生图底图（原“更多 → 设为源图”）。
  final VoidCallback onUseAsInit;

  final ValueChanged<int> onDefry;
  final ValueChanged<String> onPrompt;

  /// 选表情：mood + 常用标签（`applyEmotionPreset`，会改补充提示词）。
  final ValueChanged<String> onEmotion;
  final ValueChanged<ToolsPixelOptions> onPixel;
  final VoidCallback onDismissError;
}

/// 输入队列外面包一层投放区（拖图片进来，`DropRegion`）。
typedef ToolsDropWrapper = Widget Function(BuildContext context, Widget child);

@immutable
class ToolsDirectorSlots {
  const ToolsDirectorSlots({this.drop});
  final ToolsDropWrapper? drop;
}
