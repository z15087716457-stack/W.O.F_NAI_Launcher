// 画布工具的预览模拟器：接管生图页工具条上的增强 / 放大 / 编辑 / 局部重绘 / 导演工具，
// 按钮都能点（改假数据），不调接口。preview_main 的“生图”页用它。
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';

import 'gen_preview.dart';

/// 预设状态（预览顶栏切换）。
enum ToolsScene {
  bar,
  enhance,
  enhanceCustom,
  enhanceLocal,
  upscale,
  upscaling,
  edit,
  inpaint,
  inpaintFocus,
  inpaintExpand,
  director,
  directorEmotion,
  directorRemoveBg,
  directorRunning,
  directorFailed,
  directorPixel,
  directorEmpty,
}

/// 现在显示哪一页：生图页（带工具条面板）/ 编辑器 / 导演工具。
enum ToolsView { gen, editor, director }

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/tools/assets），没有就用渐变图。
ImageProvider toolsPreviewImage(String key) => _images.putIfAbsent(key, () {
  for (final p in [
    '../../mockups/tools/assets/$key.jpg',
    '../../mockups/tools/assets/$key.png',
  ]) {
    final f = File(p);
    if (f.existsSync()) return FileImage(f);
  }
  return UiFixtureImage.gradient(key);
});

class ToolsPreviewSim extends ChangeNotifier {
  ToolsPreviewSim({required this.log}) {
    _load();
  }

  final ValueChanged<String> log;
  late final gen = GenPreviewSim(
    log: log,
    tools: GenToolsHooks(
      onEnhance: (_) => _sheetToggle(GenToolSheet.enhance),
      onUpscale: (_) => _upscaleToggle(),
      onUpscaleSettings: () => _sheetToggle(GenToolSheet.upscale),
      onEditImage: (_) => _openEditor(ToolsEditorMode.edit),
      onInpaint: (_) => _openEditor(ToolsEditorMode.inpaint),
      onSendToTools: (_) => _openDirector(),
      decorate: _decorate,
    ),
  );

  var _scene = ToolsScene.bar;
  var view = ToolsView.gen;
  GenToolSheet? _sheet;
  double? _progress;
  Timer? _timer;
  var _enhance = ToolsFixture.enhance();
  var _upscale = ToolsFixture.upscale();
  var _editor = ToolsFixture.editor(images: toolsPreviewImage);
  var _director = ToolsFixture.director(images: toolsPreviewImage);
  var _n = 0;

  ToolsScene get scene => _scene;
  set scene(ToolsScene s) {
    _scene = s;
    _load();
    notifyListeners();
  }

  ToolsEditorData get editor => _editor;
  ToolsDirectorData get director => _director;

  @override
  void dispose() {
    _timer?.cancel();
    gen.dispose();
    super.dispose();
  }

  void _load() {
    _timer?.cancel();
    _progress = null;
    _sheet = null;
    view = ToolsView.gen;
    _enhance = ToolsFixture.enhance(
      custom: _scene == ToolsScene.enhanceCustom,
      local: _scene == ToolsScene.enhanceLocal,
    );
    _upscale = ToolsFixture.upscale();
    const f = toolsPreviewImage;
    switch (_scene) {
      case ToolsScene.enhance ||
          ToolsScene.enhanceCustom ||
          ToolsScene.enhanceLocal:
        _sheet = GenToolSheet.enhance;
      case ToolsScene.upscale:
        _sheet = GenToolSheet.upscale;
      case ToolsScene.upscaling:
        _startUpscale();
      case ToolsScene.edit:
        _openEditor(ToolsEditorMode.edit, notify: false);
      case ToolsScene.inpaint ||
          ToolsScene.inpaintFocus ||
          ToolsScene.inpaintExpand:
        view = ToolsView.editor;
        _editor = ToolsFixture.editor(
          mode: ToolsEditorMode.inpaint,
          focus: _scene == ToolsScene.inpaintFocus,
          expand: _scene == ToolsScene.inpaintExpand,
          images: f,
        );
      case ToolsScene.director:
        view = ToolsView.director;
        _director = ToolsFixture.director(images: f);
      case ToolsScene.directorEmotion:
        view = ToolsView.director;
        _director = ToolsFixture.emotion(images: f);
      case ToolsScene.directorRemoveBg:
        view = ToolsView.director;
        _director = ToolsFixture.removeBg(images: f);
      case ToolsScene.directorRunning:
        view = ToolsView.director;
        _director = ToolsFixture.running(images: f);
      case ToolsScene.directorFailed:
        view = ToolsView.director;
        _director = ToolsFixture.failed(images: f);
      case ToolsScene.directorPixel:
        view = ToolsView.director;
        _director = ToolsFixture.pixel(images: f);
      case ToolsScene.directorEmpty:
        view = ToolsView.director;
        _director = ToolsFixture.empty;
      case ToolsScene.bar:
        break;
    }
  }

  void _set(String action) {
    log(action);
    notifyListeners();
  }

  // ───────── 生图页工具条 ─────────

  GenViewData _decorate(GenViewData d) {
    final cv = d.canvas;
    final info = cv.info;
    if (info == null) return d;
    return d.copyWith(
      canvas: GenCanvasData(
        focus: cv.focus,
        info: GenFocusInfo(
          tileId: info.tileId,
          width: info.width,
          height: info.height,
          seed: info.seed,
          pinned: info.pinned,
          variationsCost: 48,
          enhanceCost: _enhance.cost,
          canUseAsInput: info.canUseAsInput,
        ),
        upscale: GenUpscale(
          cost: _upscale.backend == 'novelai' ? _upscale.cost : null,
          running: _progress != null,
          progress: _progress,
          status: _upscale.backend == 'novelai'
              ? 'NovelAI 云端放大 · 排队中'
              : '本机放大 · SeedVR2 推理中',
        ),
        error: cv.error,
        backdrop: cv.backdrop,
        zoomToFill: cv.zoomToFill,
        positioning: cv.positioning,
        generateShortcut: cv.generateShortcut,
        locked: cv.locked,
        sheet: _sheet,
      ),
    );
  }

  void _sheetToggle(GenToolSheet s) {
    _sheet = _sheet == s ? null : s;
    _set('${s.name} 面板${_sheet == null ? '收起' : '打开'}');
  }

  void _upscaleToggle() {
    if (_progress != null) {
      _timer?.cancel();
      _progress = null;
      _set('取消放大');
      return;
    }
    _sheet = null;
    _startUpscale();
    _set('开始放大（假）');
  }

  void _startUpscale() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      _progress = (_progress ?? 0) + .02;
      if (_progress! >= 1) {
        t.cancel();
        _progress = null;
        _set('放大完成（真实应用：新图进历史）');
      } else {
        notifyListeners();
      }
    });
  }

  Widget? sheet() => switch (_sheet) {
    GenToolSheet.enhance => ToolsEnhanceSheet(
      data: _enhance,
      actions: enhanceActions,
    ),
    GenToolSheet.upscale => ToolsUpscaleSheet(
      data: _upscale,
      actions: upscaleActions,
    ),
    null => null,
  };

  static const _magnitudes = {
    1: (.2, 0.0),
    2: (.4, 0.0),
    3: (.5, 0.0),
    4: (.6, 0.0),
    5: (.7, .1),
  };

  late final enhanceActions = ToolsEnhanceActions(
    onScale: (s) {
      final f = double.tryParse(s);
      _enhance = _enhance.copyWith(
        scale: s,
        outWidth: f == null ? null : (832 * f).round(),
        outHeight: f == null ? null : (1216 * f).round(),
        cost: s == ToolsEnhanceScale.max ? 40 : (f == 1.5 ? 30 : 20),
      );
      _set('onScale($s)');
    },
    onMagnitude: (m) {
      final (st, no) = _magnitudes[m]!;
      _enhance = _enhance.copyWith(magnitude: m, strength: st, noise: no);
      _set('onMagnitude($m)');
    },
    onCustom: (v) {
      _enhance = _enhance.copyWith(custom: v);
      _set('onCustom($v)');
    },
    onStrength: (v) {
      _enhance = _enhance.copyWith(strength: v);
      _set('onStrength($v)');
    },
    onNoise: (v) {
      _enhance = _enhance.copyWith(noise: v);
      _set('onNoise($v)');
    },
    onOpenUpscaleSettings: () {
      _sheet = GenToolSheet.upscale;
      _set('打开放大设置');
    },
    onRun: () {
      _sheet = null;
      _set('增强（假，不调接口）');
    },
    onClose: () {
      _sheet = null;
      _set('退出增强');
    },
  );

  late final upscaleActions = ToolsUpscaleActions(
    onBackend: (b) {
      _upscale = ToolsFixture.upscale(cloud: b == 'novelai');
      _set('onBackend($b)');
    },
    onMethod: (m) {
      _upscale = _upscale.copyWith(method: m);
      _set('onMethod($m)');
    },
    onModel: (id) {
      final missing =
          _upscale.models.firstWhere((m) => m.id == id).state ==
          ToolsModelState.missing;
      _upscale = _upscale.copyWith(
        model: id,
        blocked: missing ? '模型还没下载，先到“管理模型”里装好' : null,
        clearBlocked: !missing,
      );
      _set('onModel($id)');
    },
    onManageModels: () => log('打开设置页 · 本机放大'),
    onScale: (v) {
      _upscale = _upscale.copyWith(
        scale: v,
        outWidth: (832 * v).round(),
        outHeight: (1216 * v).round(),
      );
      _set('onScale($v)');
    },
    onAdvanced: (id, v) {
      _upscale = _upscale.copyWith(
        advanced: [
          for (final f in _upscale.advanced)
            f.id == id
                ? ToolsUpscaleField(
                    id: f.id,
                    label: f.label,
                    kind: f.kind,
                    value: v,
                    min: f.min,
                    max: f.max,
                    decimals: f.decimals,
                    options: f.options,
                    hint: f.hint,
                  )
                : f,
        ],
      );
      _set('onAdvanced($id, $v)');
    },
    onRun: () {
      _sheet = null;
      _startUpscale();
      _set('按这套设置放大（假）');
    },
    onClose: () {
      _sheet = null;
      _set('收起放大设置');
    },
  );

  // ───────── 编辑器 ─────────

  void _openEditor(ToolsEditorMode mode, {bool notify = true}) {
    _sheet = null;
    view = ToolsView.editor;
    _editor = ToolsFixture.editor(mode: mode, images: toolsPreviewImage);
    if (notify) _set(mode == ToolsEditorMode.edit ? '打开编辑图像' : '打开局部重绘');
  }

  void _edit(ToolsEditorData d, String action) {
    _editor = d;
    _set(action);
  }

  void _leaveEditor(String action) {
    view = ToolsView.gen;
    _set(action);
  }

  late final editorActions = ToolsEditorActions(
    onBack: () => _leaveEditor('返回生图（不保存）'),
    onApply: () =>
        _leaveEditor(_editor.inpainting ? '应用蒙版，回生图页' : '用作图生图底图，回生图页'),
    onApplyAndGenerate: () => _leaveEditor('应用并开始重绘（假）'),
    onZoomIn: () => _edit(
      _editor.copyWith(zoom: (_editor.zoom * 1.25).clamp(.1, 8)),
      'onZoomIn',
    ),
    onZoomOut: () => _edit(
      _editor.copyWith(zoom: (_editor.zoom / 1.25).clamp(.1, 8)),
      'onZoomOut',
    ),
    onZoomFit: () => _edit(_editor.copyWith(zoom: 560 / 832), 'onZoomFit'),
    onUndo: () =>
        _edit(_editor.copyWith(canUndo: false, canRedo: true), 'onUndo'),
    onRedo: () =>
        _edit(_editor.copyWith(canUndo: true, canRedo: false), 'onRedo'),
    onDownload: () => log('下载 PNG（假）'),
    onTool: (t) => _edit(
      _editor.copyWith(
        tool: t,
        options: ToolsFixture.optionsFor(t, inpaint: _editor.inpainting),
      ),
      'onTool(${t.name})',
    ),
    onOptions: (o) => _edit(_editor.copyWith(options: o), 'onOptions'),
    onColor: (color, {required secondary}) => _edit(
      secondary
          ? _editor.copyWith(secondary: color)
          : _editor.copyWith(primary: color),
      'onColor',
    ),
    onSwapColors: () => _edit(
      _editor.copyWith(primary: _editor.secondary, secondary: _editor.primary),
      'onSwapColors',
    ),
    onMoreColors: (_) => log('打开取色器（接线后是现有取色器）'),
    onMaskLook: (m) => _edit(_editor.copyWith(mask: m), 'onMaskLook'),
    onAddLayer: () {
      _n++;
      final id = 'n$_n';
      _edit(
        _editor.copyWith(
          layers: [
            ToolsLayer(
              id: id,
              name: '图层 ${_editor.layers.length}',
              detail: '空',
              kind: ToolsLayerKind.paint,
            ),
            ..._editor.layers,
          ],
          layer: id,
        ),
        'onAddLayer',
      );
    },
    onAdd3dLayer: () => log('打开 3D 图层编辑器（接线后是现有的）'),
    onSelectLayer: (id) =>
        _edit(_editor.copyWith(layer: id), 'onSelectLayer($id)'),
    onLayerVisible: (id, v) => _edit(
      _editor.copyWith(
        layers: [
          for (final l in _editor.layers)
            l.id == id
                ? ToolsLayer(
                    id: l.id,
                    name: l.name,
                    kind: l.kind,
                    detail: l.detail,
                    visible: v,
                    locked: l.locked,
                    thumb: l.thumb,
                  )
                : l,
        ],
      ),
      'onLayerVisible($id, $v)',
    ),
    onLayerAction: (id, action) {
      final list = [..._editor.layers];
      final i = list.indexWhere((l) => l.id == id);
      switch (action) {
        case ToolsLayerAction.up when i > 0:
          list.insert(i - 1, list.removeAt(i));
        case ToolsLayerAction.down when i < list.length - 1:
          list.insert(i + 1, list.removeAt(i));
        case ToolsLayerAction.delete || ToolsLayerAction.merge:
          list.removeAt(i);
        case ToolsLayerAction.duplicate:
          _n++;
          final l = list[i];
          list.insert(
            i,
            ToolsLayer(
              id: 'n$_n',
              name: '${l.name} 副本',
              kind: l.kind == ToolsLayerKind.base
                  ? ToolsLayerKind.paint
                  : l.kind,
              detail: l.detail,
              thumb: l.thumb,
            ),
          );
        default:
          break;
      }
      _edit(
        _editor.copyWith(
          layers: list,
          layer: list.any((l) => l.id == _editor.layer)
              ? _editor.layer
              : list.first.id,
        ),
        'onLayerAction($id, ${action.name})',
      );
    },
    onAdjust: (v) => _edit(_editor.copyWith(adjust: v), 'onAdjust'),
    onAdjustReset: () =>
        _edit(_editor.copyWith(adjust: const ToolsAdjust()), 'onAdjustReset'),
    onAdjustApply: () => _edit(
      _editor.copyWith(adjust: const ToolsAdjust(), canUndo: true),
      '调色写进图层',
    ),
    onResizeCanvas: () => log('打开画布尺寸弹窗（接线后是现有的）'),
    onClearMask: () => _edit(
      _editor.copyWith(
        inpaint: ToolsInpaintInfo(
          strength: _editor.inpaint.strength,
          focusWidth: _editor.inpaint.focusWidth,
          focusHeight: _editor.inpaint.focusHeight,
          focusContext: _editor.inpaint.focusContext,
        ),
        canUndo: true,
      ),
      '清空蒙版',
    ),
    onExpanding: (v) =>
        _edit(_editor.copyWith(expanding: v), 'onExpanding($v)'),
    onExpand: (e) => _edit(_editor.copyWith(expand: e), 'onExpand'),
    onFocusContext: (v) => _edit(
      _editor.copyWith(inpaint: _inpaint(focusContext: v)),
      'onFocusContext($v)',
    ),
    onClearFocus: () =>
        _edit(_editor.copyWith(inpaint: _inpaint(clearFocus: true)), '清除聚焦'),
    onInpaintStrength: (v) => _edit(
      _editor.copyWith(inpaint: _inpaint(strength: v)),
      'onInpaintStrength($v)',
    ),
  );

  ToolsInpaintInfo _inpaint({
    double? strength,
    int? focusContext,
    bool clearFocus = false,
  }) {
    final i = _editor.inpaint;
    return ToolsInpaintInfo(
      strength: strength ?? i.strength,
      coverage: i.coverage,
      regions: i.regions,
      focusWidth: clearFocus ? null : i.focusWidth,
      focusHeight: clearFocus ? null : i.focusHeight,
      focusContext: focusContext ?? i.focusContext,
      maxFocusContext: i.maxFocusContext,
    );
  }

  // ───────── 导演工具 ─────────

  void _openDirector() {
    _sheet = null;
    view = ToolsView.director;
    _set('打开导演工具（带着当前这张）');
  }

  void _dt(ToolsDirectorData d, String action) {
    _director = d;
    _set(action);
  }

  static const _emotionTags = {
    'happy': 'smile, happy',
    'sad': 'sad, tears',
    'angry': 'angry, frown',
    'shy': 'blush, embarrassed, looking away',
    'surprised': 'surprised, open mouth',
    'smug': 'smug, smirk',
    'laughing': 'laughing, closed eyes',
  };

  void _addInput(String key, String action) {
    _n++;
    final id = 'x$_n';
    _dt(
      _director.copyWith(
        inputs: [
          ToolsDirectorInput(
            id: id,
            thumb: toolsPreviewImage(key),
            width: 832,
            height: 1216,
          ),
          ..._director.inputs,
        ],
        input: id,
        clearRun: true,
      ),
      action,
    );
  }

  late final directorActions = ToolsDirectorActions(
    onBack: () {
      view = ToolsView.gen;
      _set('回生图');
    },
    onTool: (t) => _dt(_director.copyWith(tool: t), 'onTool(${t.name})'),
    onSelectInput: (id) => _dt(
      _director.copyWith(input: id, clearRun: true),
      'onSelectInput($id)',
    ),
    onRemoveInput: (id) {
      final rest = [..._director.inputs]..removeWhere((i) => i.id == id);
      _dt(
        _director.copyWith(
          inputs: rest,
          input: rest.firstOrNull?.id,
          clearInput: rest.isEmpty,
          clearRun: _director.input == id,
        ),
        'onRemoveInput($id)',
      );
    },
    onImportFiles: () => _addInput('q3', '导入文件（假）'),
    onPickHistory: () => _addInput('q2', '从生图历史选（假）'),
    onPaste: () => _addInput('src', '粘贴（假）'),
    onRun: () {
      final input = _director.currentInput;
      if (input == null) return;
      _dt(_director.copyWith(running: true, clearError: true), '运行（假）');
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 1400), () {
        _n++;
        final t = _director.tool;
        final img = toolsPreviewImage(switch (t) {
          ToolsDirectorTool.sketch => 'sketch',
          ToolsDirectorTool.lineArt => 'lineart',
          _ => 'src',
        });
        final run = ToolsDirectorRun(
          id: 'run$_n',
          tool: t,
          inputId: input.id,
          images: t == ToolsDirectorTool.removeBackground
              ? [img, toolsPreviewImage('q3'), img]
              : [img],
          variants: t == ToolsDirectorTool.removeBackground
              ? const ['透明底', '背景', '合成']
              : const [],
          time: DateTime.now(),
          width: input.width,
          height: input.height,
          cost: _director.cost,
        );
        _dt(
          _director.copyWith(
            running: false,
            runs: [run, ..._director.runs],
            run: run.id,
            variant: run.images.length - 1,
          ),
          '运行完成',
        );
      });
    },
    onSelectRun: (id) {
      final r = _director.runs.firstWhere((r) => r.id == id);
      _dt(
        _director.copyWith(
          run: id,
          input: _director.inputs.any((i) => i.id == r.inputId)
              ? r.inputId
              : null,
          variant: r.images.length - 1,
        ),
        'onSelectRun($id)',
      );
    },
    onReuseSettings: (id) {
      final r = _director.runs.firstWhere((r) => r.id == id);
      _dt(_director.copyWith(tool: r.tool), '沿用 ${r.tool.name} 的设置');
    },
    onVariant: (v) => _dt(_director.copyWith(variant: v), 'onVariant($v)'),
    onContinue: () => _addInput('sketch', '结果加入输入队列'),
    onCopy: () => log('复制（假）'),
    onSave: () => log('存到图库（假）'),
    onUpscale: () => log('带着这张回生图页放大（假）'),
    onUseAsInit: () {
      view = ToolsView.gen;
      _set('用作图生图底图，回生图页');
    },
    onDefry: (v) => _dt(_director.copyWith(defry: v), 'onDefry($v)'),
    onPrompt: (v) => _dt(_director.copyWith(prompt: v), 'onPrompt'),
    onEmotion: (e) => _dt(
      _director.copyWith(emotion: e, prompt: _emotionTags[e] ?? e),
      'onEmotion($e)',
    ),
    onPixel: (p) => _dt(_director.copyWith(pixel: p), 'onPixel'),
    onDismissError: () =>
        _dt(_director.copyWith(clearError: true), 'onDismissError'),
  );
}
