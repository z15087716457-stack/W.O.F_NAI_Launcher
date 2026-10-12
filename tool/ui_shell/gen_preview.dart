// 生图页预览模拟器：按钮都能点，改的是假数据；“生成”用计时器假装出图（不调接口、不花 Anlas）。
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';

import 'blocks_preview.dart';

/// 预设状态（预览顶栏切换）。blocksDemo = 块系统那页留下的药丸 / 实例卡演示。
enum GenScene {
  v5,
  v45,
  v3,
  generating,
  failed,
  empty,
  refsFull,
  characters,
  blocksDemo,
}

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/generation/assets），没有就用渐变图。
ImageProvider genPreviewImage(String key) => _images.putIfAbsent(key, () {
  final f = File('../../mockups/generation/assets/$key.jpg');
  return f.existsSync() ? FileImage(f) : UiFixtureImage.gradient(key);
});

const _pool = ['g03', 'g07', 'g18', 'g33', 'g46', 'g50', 'h0', 'h1', 'h2'];

/// 画布工具的模拟器（tools_preview.dart）接管工具条上的这几个按钮，并往画布数据里加面板 / 放大进度。
class GenToolsHooks {
  const GenToolsHooks({
    required this.onEnhance,
    required this.onUpscale,
    required this.onUpscaleSettings,
    required this.onEditImage,
    required this.onInpaint,
    required this.onSendToTools,
    required this.decorate,
  });
  final ValueChanged<String> onEnhance;
  final ValueChanged<String> onUpscale;
  final VoidCallback onUpscaleSettings;
  final ValueChanged<String> onEditImage;
  final ValueChanged<String> onInpaint;
  final ValueChanged<String> onSendToTools;
  final GenViewData Function(GenViewData data) decorate;
}

class GenPreviewSim extends ChangeNotifier {
  GenPreviewSim({required this.log, this.tools}) {
    _load();
  }

  final ValueChanged<String> log;
  final GenToolsHooks? tools;
  var _scene = GenScene.v5;
  late GenViewData _d;
  final _cleared = <String>{};
  Timer? _timer;
  var _n = 0;
  var _layout = const GenLayout();

  GenScene get scene => _scene;
  set scene(GenScene s) {
    _scene = s;
    _timer?.cancel();
    _cleared.clear();
    _load();
    notifyListeners();
  }

  GenViewData get data {
    final d = _d.copyWith(layout: _layout);
    return tools?.decorate(d) ?? d;
  }

  void _load() {
    const f = genPreviewImage;
    _d = switch (_scene) {
      GenScene.v5 || GenScene.blocksDemo => GenFixture.view(images: f),
      GenScene.v45 => GenFixture.view(v45: true, images: f),
      GenScene.v3 => GenFixture.v3(images: f),
      GenScene.generating => GenFixture.generating(images: f),
      GenScene.failed => GenFixture.failed(images: f),
      GenScene.empty => GenFixture.empty(),
      GenScene.refsFull => GenFixture.refsFull(images: f),
      GenScene.characters => GenFixture.characters(),
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _set(GenViewData d, String what) {
    _d = d;
    log(what);
    notifyListeners();
  }

  static String _key(GenEditorTarget t) => '${t.character}-${t.negative}';

  Widget editor(BuildContext context, GenEditorTarget t) =>
      GenFixtureEditor(target: t, empty: _cleared.contains(_key(t)));

  // ── 复制辅助（契约里的嵌套类只在这里需要改值） ──

  GenPromptData _prompt({
    bool? negative,
    String? qualityPreset,
    String? ucPreset,
    bool? transparent,
    GenPromptTools? tools,
    GenTranslate? translate,
  }) {
    final p = _d.prompt;
    return GenPromptData(
      negative: negative ?? p.negative,
      positiveTokens: p.positiveTokens,
      negativeTokens: p.negativeTokens,
      qualityPresets: p.qualityPresets,
      qualityPreset: qualityPreset ?? p.qualityPreset,
      ucPresets: p.ucPresets,
      ucPreset: ucPreset ?? p.ucPreset,
      transparent: p.transparent == null
          ? null
          : (transparent ?? p.transparent),
      positivePreview: p.positivePreview,
      negativePreview: p.negativePreview,
      tools: tools ?? p.tools,
      translate: translate ?? p.translate,
      bridge: p.bridge,
    );
  }

  GenCharactersData _chars({List<GenCharacter>? list, bool? aiPosition}) {
    final c = _d.characters!;
    return GenCharactersData(
      list: list ?? c.list,
      aiPosition: aiPosition ?? c.aiPosition,
      max: c.max,
      freeform: c.freeform,
    );
  }

  GenCharacter _char(
    GenCharacter c, {
    String? name,
    bool clearName = false,
    GenGender? gender,
    bool? enabled,
    Offset? position,
  }) => GenCharacter(
    id: c.id,
    name: clearName ? null : (name ?? c.name),
    gender: gender ?? c.gender,
    enabled: enabled ?? c.enabled,
    positiveTokens: c.positiveTokens,
    negativeTokens: c.negativeTokens,
    position: position ?? c.position,
  );

  void _editChar(int i, GenCharacter Function(GenCharacter) f, String what) {
    final list = [..._d.characters!.list];
    list[i] = f(list[i]);
    _set(_d.copyWith(characters: _chars(list: list)), what);
  }

  GenRefsData _refs({
    GenImg2Img? img2img,
    GenVibesData? vibes,
    GenPreciseData? precise,
  }) {
    final r = _d.refs;
    return GenRefsData(
      img2img: img2img ?? r.img2img,
      vibes: vibes ?? r.vibes,
      precise: precise ?? r.precise,
    );
  }

  GenVibesData _vibes({List<GenVibe>? list, bool? normalize}) {
    final v = _d.refs.vibes!;
    return GenVibesData(
      list: list ?? v.list,
      max: v.max,
      freeCount: v.freeCount,
      extraCost: v.extraCost,
      normalize: normalize ?? v.normalize,
      recent: v.recent,
    );
  }

  GenParamsData _params({
    int? steps,
    double? scale,
    double? cfgRescale,
    int? seed,
    bool clearSeed = false,
    bool? seedPinned,
    String? sampler,
    String? noise,
    bool? varietyPlus,
    bool? decrisp,
    GenSmea? smea,
  }) {
    final p = _d.params;
    return GenParamsData(
      steps: steps ?? p.steps,
      maxSteps: p.maxSteps,
      scale: scale ?? p.scale,
      maxScale: p.maxScale,
      cfgRescale: cfgRescale ?? p.cfgRescale,
      seed: clearSeed ? null : (seed ?? p.seed),
      seedPinned: seedPinned ?? p.seedPinned,
      sampler: sampler ?? p.sampler,
      samplers: p.samplers,
      noise: p.noise == null ? null : (noise ?? p.noise),
      noises: p.noises,
      varietyPlus: p.varietyPlus == null
          ? null
          : (varietyPlus ?? p.varietyPlus),
      decrisp: p.decrisp == null ? null : (decrisp ?? p.decrisp),
      smea: p.smea == null ? null : (smea ?? p.smea),
    );
  }

  GenImageData _image({int? width, int? height, int? count, int? repeat}) {
    final i = _d.image;
    return GenImageData(
      width: width ?? i.width,
      height: height ?? i.height,
      presets: i.presets,
      count: count ?? i.count,
      maxCount: i.maxCount,
      repeat: repeat ?? i.repeat,
      maxRepeat: i.maxRepeat,
    );
  }

  GenCanvasData _canvas({
    GenGroup? focus,
    GenFocusInfo? info,
    bool clearInfo = false,
    GenError? error,
    bool clearError = false,
    String? backdrop,
    bool? zoomToFill,
    bool? positioning,
    bool? locked,
    GenUpscale? upscale,
  }) {
    final c = _d.canvas;
    return GenCanvasData(
      focus: focus ?? c.focus,
      info: clearInfo ? null : (info ?? c.info),
      upscale: upscale ?? c.upscale,
      error: clearError ? null : (error ?? c.error),
      backdrop: backdrop ?? c.backdrop,
      zoomToFill: zoomToFill ?? c.zoomToFill,
      positioning: positioning ?? c.positioning,
      generateShortcut: c.generateShortcut,
      locked: locked ?? c.locked,
    );
  }

  GenFocusInfo _infoOf(GenTile t, {bool? pinned}) => GenFocusInfo(
    tileId: t.id,
    width: t.width,
    height: t.height,
    seed: 1000000000 + t.id.hashCode.abs() % 3000000000,
    pinned: pinned ?? false,
  );

  GenHistoryData _history({
    List<GenBatch>? batches,
    String? selected,
    bool? autoSave,
    int? pinned,
  }) {
    final h = _d.history;
    return GenHistoryData(
      batches: batches ?? h.batches,
      selected: selected ?? h.selected,
      autoSave: autoSave ?? h.autoSave,
      pinned: pinned ?? h.pinned,
    );
  }

  // ── 生成（假的） ──

  void _generate() {
    final count = _d.image.count;
    final w = _d.image.width, h = _d.image.height;
    final run = 'r${++_n}';
    final picks = [
      for (var i = 0; i < count; i++) _pool[(_n * 3 + i) % _pool.length],
    ];
    var done = 0;
    var progress = 0.0;
    void frame() {
      final tiles = [
        for (var i = 0; i < count; i++)
          i < done
              ? GenTile(
                  id: '$run-$i',
                  width: w,
                  height: h,
                  image: genPreviewImage(picks[i]),
                )
              : i == done
              ? GenTile(
                  id: '$run-$i',
                  width: w,
                  height: h,
                  state: GenTileState.streaming,
                  preview: progress > .3 ? genPreviewImage(picks[i]) : null,
                  progress: progress,
                )
              : GenTile(
                  id: '$run-$i',
                  width: w,
                  height: h,
                  state: GenTileState.pending,
                ),
      ];
      final finished = done >= count;
      final batch = GenBatch(
        id: run,
        time: GenFixture.now.add(Duration(minutes: _n)),
        pending: count - done,
        images: [
          for (var i = 0; i < done; i++)
            GenHistoryImage(
              id: '$run-$i',
              thumb: genPreviewImage(picks[i]),
              width: w,
              height: h,
            ),
        ],
      );
      _d = _d.copyWith(
        generate: GenGenerateData(
          state: finished ? GenRunState.ready : GenRunState.generating,
          label: _d.generate.label,
          cost: _d.generate.cost,
          done: done,
          total: count,
          progress: (done + progress) / count,
        ),
        canvas: _canvas(
          focus: GenGroup(id: run, tiles: tiles),
          info: done > 0 ? _infoOf(tiles.first) : null,
          clearInfo: done == 0,
          locked: !finished,
          clearError: true,
        ),
        history: _history(
          selected: run,
          batches: [batch, ..._d.history.batches.where((b) => b.id != run)],
        ),
        params: _d.params.seedPinned ? null : _params(seed: 1938201277 + _n),
      );
      notifyListeners();
    }

    log('onGenerate（预览：假装出图，不调接口）');
    frame();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      progress += .09;
      if (progress >= 1) {
        progress = 0;
        done++;
      }
      frame();
      if (done >= count) t.cancel();
    });
  }

  void _focusBatch(String id) {
    final b = _d.history.batches.firstWhere((b) => b.id == id);
    final tiles = [
      for (final i in b.images)
        GenTile(id: i.id, width: i.width, height: i.height, image: i.thumb),
    ];
    _set(
      _d.copyWith(
        history: _history(selected: id),
        canvas: _canvas(
          focus: GenGroup(id: id, tiles: tiles),
          info: tiles.isEmpty ? null : _infoOf(tiles.first),
          clearInfo: tiles.isEmpty,
        ),
      ),
      'onFocusBatch($id)',
    );
  }

  late final actions = _build();

  GenActions _build() {
    final base = GenActions.logging(log);
    return GenActions(
      onLayoutChanged: (v) {
        _layout = v;
        log('onLayoutChanged');
        notifyListeners();
      },
      onModelChanged: (id) {
        scene = id == 'nai-diffusion-5'
            ? GenScene.v5
            : id.contains('-3')
            ? GenScene.v3
            : GenScene.v45;
        log('onModelChanged($id)');
      },
      onFurryChanged: (v) => _set(_d.copyWith(furry: v), 'onFurryChanged($v)'),
      onOpenQuota: base.onOpenQuota,
      onNegativeTab: (v) =>
          _set(_d.copyWith(prompt: _prompt(negative: v)), 'onNegativeTab($v)'),
      onClearPrompt: (t) {
        _cleared.add(_key(t));
        log('onClearPrompt($t)（真实应用给撤销提示）');
        notifyListeners();
      },
      onQualityPreset: (id) => _set(
        _d.copyWith(prompt: _prompt(qualityPreset: id)),
        'onQualityPreset($id)',
      ),
      onUcPreset: (id) =>
          _set(_d.copyWith(prompt: _prompt(ucPreset: id)), 'onUcPreset($id)'),
      onTransparentChanged: (v) => _set(
        _d.copyWith(prompt: _prompt(transparent: v)),
        'onTransparentChanged($v)',
      ),
      onPromptTool: (tool, v) {
        final t = _d.prompt.tools;
        _set(
          _d.copyWith(
            prompt: _prompt(
              tools: GenPromptTools(
                palettePinned: tool == GenPromptTool.palettePinned
                    ? v
                    : t.palettePinned,
                dockPinned: tool == GenPromptTool.dockPinned ? v : t.dockPinned,
                translatePinned: tool == GenPromptTool.translatePinned
                    ? v
                    : t.translatePinned,
                autoFormat: tool == GenPromptTool.autoFormat ? v : t.autoFormat,
                highlight: tool == GenPromptTool.highlight ? v : t.highlight,
                sdConvert: tool == GenPromptTool.sdConvert ? v : t.sdConvert,
                related: tool == GenPromptTool.related ? v : t.related,
              ),
            ),
          ),
          'onPromptTool(${tool.name}, $v)',
        );
      },
      onOpenPalette: base.onOpenPalette,
      onTranslate: () {
        _set(
          _d.copyWith(
            prompt: _prompt(
              translate: GenTranslate(
                busy: true,
                route: _d.prompt.translate.route,
              ),
            ),
          ),
          'onTranslate',
        );
        Timer(const Duration(milliseconds: 900), () {
          _d = _d.copyWith(
            prompt: _prompt(
              translate: GenTranslate(
                showing: true,
                route: _d.prompt.translate.route,
              ),
            ),
          );
          notifyListeners();
        });
      },
      onToggleTranslation: () => _set(
        _d.copyWith(
          prompt: _prompt(
            translate: GenTranslate(
              showing: !_d.prompt.translate.showing,
              route: _d.prompt.translate.route,
            ),
          ),
        ),
        'onToggleTranslation',
      ),
      onTranslationSettings: base.onTranslationSettings,
      onOpenBridge: base.onOpenBridge,
      onAddCharacter: (g) => _set(
        _d.copyWith(
          characters: _chars(
            list: [
              ..._d.characters!.list,
              GenCharacter(id: 'c${++_n}', gender: g),
            ],
          ),
        ),
        'onAddCharacter(${g.name})',
      ),
      onClearCharacters: () => _set(
        _d.copyWith(characters: _chars(list: const [])),
        'onClearCharacters',
      ),
      onRemoveCharacter: (i) => _set(
        _d.copyWith(
          characters: _chars(list: [..._d.characters!.list]..removeAt(i)),
        ),
        'onRemoveCharacter($i)',
      ),
      onMoveCharacter: (i, delta) {
        final list = [..._d.characters!.list];
        final c = list.removeAt(i);
        list.insert(i + delta, c);
        _set(
          _d.copyWith(characters: _chars(list: list)),
          'onMoveCharacter($i, $delta)',
        );
      },
      onCharacterEnabled: (i, v) => _editChar(
        i,
        (c) => _char(c, enabled: v),
        'onCharacterEnabled($i, $v)',
      ),
      onRenameCharacter: (i, name) => _editChar(
        i,
        (c) => name.isEmpty ? _char(c, clearName: true) : _char(c, name: name),
        'onRenameCharacter($i, $name)',
      ),
      onCharacterGender: (i, g) => _editChar(
        i,
        (c) => _char(c, gender: g),
        'onCharacterGender($i, ${g.name})',
      ),
      onCharacterToLibrary: base.onCharacterToLibrary,
      onAiPositionChanged: (v) => _set(
        _d.copyWith(characters: _chars(aiPosition: v)),
        'onAiPositionChanged($v)',
      ),
      onCharacterPosition: (i, p) => _editChar(
        i,
        (c) => _char(c, position: p),
        'onCharacterPosition($i, $p)',
      ),
      onPositioningChanged: (v) => _set(
        _d.copyWith(canvas: _canvas(positioning: v)),
        'onPositioningChanged($v)',
      ),
      onImg2ImgUpload: () => _set(
        _d.copyWith(
          refs: _refs(
            img2img: GenImg2Img(
              image: genPreviewImage('g19'),
              width: 1216,
              height: 832,
            ),
          ),
        ),
        'onImg2ImgUpload（预览：放入示例图）',
      ),
      onImg2ImgFromLibrary: base.onImg2ImgFromLibrary,
      onImg2ImgSketch: base.onImg2ImgSketch,
      onImg2ImgChanged: (m) =>
          _set(_d.copyWith(refs: _refs(img2img: m)), 'onImg2ImgChanged'),
      onImg2ImgEdit: base.onImg2ImgEdit,
      onImg2ImgInpaint: base.onImg2ImgInpaint,
      onImg2ImgPlace: base.onImg2ImgPlace,
      onImg2ImgRemove: () => _set(
        _d.copyWith(refs: _refs(img2img: const GenImg2Img())),
        'onImg2ImgRemove',
      ),
      onAddVibeFiles: () {
        final v = _d.refs.vibes;
        if (v == null) return;
        _set(
          _d.copyWith(
            refs: _refs(
              vibes: _vibes(
                list: [
                  ...v.list,
                  GenVibe(
                    id: 'v${++_n}',
                    thumb: genPreviewImage(_pool[_n % _pool.length]),
                    name: '新 Vibe $_n',
                    state: GenVibeState.pending,
                  ),
                ],
              ),
            ),
          ),
          'onAddVibeFiles（预览：加一张待编码）',
        );
      },
      onAddVibeFromLibrary: base.onAddVibeFromLibrary,
      onAddRecentVibe: (id) {
        final v = _d.refs.vibes!;
        final r = v.recent.firstWhere((r) => r.id == id);
        _set(
          _d.copyWith(
            refs: _refs(
              vibes: _vibes(
                list: [
                  ...v.list,
                  GenVibe(id: 'v${++_n}', thumb: r.thumb, name: r.name),
                ],
              ),
            ),
          ),
          'onAddRecentVibe($id)',
        );
      },
      onVibeChanged: (x) => _set(
        _d.copyWith(
          refs: _refs(
            vibes: _vibes(
              list: [for (final v in _d.refs.vibes!.list) v.id == x.id ? x : v],
            ),
          ),
        ),
        'onVibeChanged(${x.id})',
      ),
      onEncodeVibe: (id) => _set(
        _d.copyWith(
          refs: _refs(
            vibes: _vibes(
              list: [
                for (final v in _d.refs.vibes!.list)
                  v.id == id
                      ? GenVibe(
                          id: v.id,
                          thumb: v.thumb,
                          name: v.name,
                          strength: v.strength,
                          info: v.info,
                          enabled: v.enabled,
                        )
                      : v,
              ],
            ),
          ),
        ),
        'onEncodeVibe($id)（预览：直接标为已编码）',
      ),
      onRemoveVibe: (id) => _set(
        _d.copyWith(
          refs: _refs(
            vibes: _vibes(
              list: _d.refs.vibes!.list.where((v) => v.id != id).toList(),
            ),
          ),
        ),
        'onRemoveVibe($id)',
      ),
      onClearVibes: () => _set(
        _d.copyWith(
          refs: _refs(vibes: _vibes(list: const [])),
        ),
        'onClearVibes',
      ),
      onSaveVibes: base.onSaveVibes,
      onNormalizeChanged: (v) => _set(
        _d.copyWith(
          refs: _refs(vibes: _vibes(normalize: v)),
        ),
        'onNormalizeChanged($v)',
      ),
      onAddPreciseFiles: () {
        final p = _d.refs.precise;
        if (p == null) return;
        _set(
          _d.copyWith(
            refs: _refs(
              precise: GenPreciseData(
                costEach: p.costEach,
                list: [
                  ...p.list,
                  GenPrecise(id: 'p${++_n}', thumb: genPreviewImage('g18')),
                ],
              ),
            ),
          ),
          'onAddPreciseFiles（预览：加一张）',
        );
      },
      onAddPreciseFromLibrary: base.onAddPreciseFromLibrary,
      onPreciseChanged: (x) {
        final p = _d.refs.precise!;
        _set(
          _d.copyWith(
            refs: _refs(
              precise: GenPreciseData(
                costEach: p.costEach,
                list: [for (final e in p.list) e.id == x.id ? x : e],
              ),
            ),
          ),
          'onPreciseChanged(${x.id})',
        );
      },
      onRemovePrecise: (id) {
        final p = _d.refs.precise!;
        _set(
          _d.copyWith(
            refs: _refs(
              precise: GenPreciseData(
                costEach: p.costEach,
                list: p.list.where((e) => e.id != id).toList(),
              ),
            ),
          ),
          'onRemovePrecise($id)',
        );
      },
      onClearPrecise: () => _set(
        _d.copyWith(refs: _refs(precise: const GenPreciseData())),
        'onClearPrecise',
      ),
      onSavePrecise: base.onSavePrecise,
      onSizeChanged: (w, h) => _set(
        _d.copyWith(
          image: _image(width: w, height: h),
        ),
        'onSizeChanged($w, $h)',
      ),
      onCountChanged: (n) => _set(
        _d.copyWith(
          image: _image(count: n),
          generate: GenGenerateData(label: '生成 $n 张图片', cost: _d.generate.cost),
        ),
        'onCountChanged($n)',
      ),
      onRepeatChanged: (n) =>
          _set(_d.copyWith(image: _image(repeat: n)), 'onRepeatChanged($n)'),
      onParamChanged: (p, v) => _set(
        _d.copyWith(
          params: switch (p) {
            GenParam.steps => _params(steps: v.round()),
            GenParam.scale => _params(scale: v),
            GenParam.cfgRescale => _params(cfgRescale: v),
          },
        ),
        'onParamChanged(${p.name}, $v)',
      ),
      onSeedChanged: (v) => _set(
        _d.copyWith(params: _params(seed: v, seedPinned: true)),
        'onSeedChanged($v)',
      ),
      onSeedPinned: (v) =>
          _set(_d.copyWith(params: _params(seedPinned: v)), 'onSeedPinned($v)'),
      onSamplerChanged: (id) => _set(
        _d.copyWith(params: _params(sampler: id)),
        'onSamplerChanged($id)',
      ),
      onNoiseChanged: (id) =>
          _set(_d.copyWith(params: _params(noise: id)), 'onNoiseChanged($id)'),
      onVarietyChanged: (v) => _set(
        _d.copyWith(params: _params(varietyPlus: v)),
        'onVarietyChanged($v)',
      ),
      onDecrispChanged: (v) => _set(
        _d.copyWith(params: _params(decrisp: v)),
        'onDecrispChanged($v)',
      ),
      onSmeaChanged: (v) =>
          _set(_d.copyWith(params: _params(smea: v)), 'onSmeaChanged'),
      onGenerate: _generate,
      onStop: () {
        _timer?.cancel();
        _set(
          _d.copyWith(
            generate: GenGenerateData(
              label: _d.generate.label,
              cost: _d.generate.cost,
            ),
            canvas: _canvas(locked: false),
          ),
          'onStop',
        );
      },
      onEnhance: tools?.onEnhance ?? base.onEnhance,
      onVariations: base.onVariations,
      onUpscale: tools?.onUpscale ?? base.onUpscale,
      onUpscaleSettings: tools?.onUpscaleSettings,
      onUpscaleOption: (id) => _set(
        _d.copyWith(
          canvas: _canvas(
            upscale: GenUpscale(
              options: _d.canvas.upscale.options,
              selected: id,
              cost: id == 'novelai' ? 15 : null,
            ),
          ),
        ),
        'onUpscaleOption($id)',
      ),
      onSetInit: base.onSetInit,
      onEditImage: tools?.onEditImage ?? base.onEditImage,
      onInpaint: tools?.onInpaint ?? base.onInpaint,
      onSendToTools: tools?.onSendToTools ?? base.onSendToTools,
      onUseSeed: (id) => _set(
        _d.copyWith(
          params: _params(seed: _d.canvas.info?.seed, seedPinned: true),
        ),
        'onUseSeed($id)',
      ),
      onCopySeed: base.onCopySeed,
      onPin: (id, v) {
        final info = _d.canvas.info!;
        _set(
          _d.copyWith(
            canvas: _canvas(
              info: GenFocusInfo(
                tileId: info.tileId,
                width: info.width,
                height: info.height,
                seed: info.seed,
                pinned: v,
              ),
            ),
            history: _history(
              pinned: (_d.history.pinned + (v ? 1 : -1)).clamp(0, 99),
            ),
          ),
          'onPin($id, $v)',
        );
      },
      onCopyImage: base.onCopyImage,
      onSaveImage: base.onSaveImage,
      onOpenViewer: base.onOpenViewer,
      onFocusTile: (id) {
        final t = _d.canvas.focus!.tiles.firstWhere((t) => t.id == id);
        _set(
          _d.copyWith(canvas: _canvas(info: _infoOf(t))),
          'onFocusTile($id)',
        );
      },
      onBackdropChanged: (b) => _set(
        _d.copyWith(canvas: _canvas(backdrop: b)),
        'onBackdropChanged($b)',
      ),
      onZoomToFillChanged: (v) => _set(
        _d.copyWith(canvas: _canvas(zoomToFill: v)),
        'onZoomToFillChanged($v)',
      ),
      onRetry: _generate,
      onDismissError: () => _set(
        _d.copyWith(canvas: _canvas(clearError: true)),
        'onDismissError',
      ),
      onFocusBatch: _focusBatch,
      onAutoSaveChanged: (v) => _set(
        _d.copyWith(history: _history(autoSave: v)),
        'onAutoSaveChanged($v)',
      ),
      onFocusPins: base.onFocusPins,
      onSaveImages: base.onSaveImages,
      onPackImages: base.onPackImages,
      onDeleteImages: (ids) {
        final batches = [
          for (final b in _d.history.batches)
            GenBatch(
              id: b.id,
              time: b.time,
              pending: b.pending,
              images: b.images.where((i) => !ids.contains(i.id)).toList(),
            ),
        ].where((b) => b.count > 0).toList();
        _set(
          _d.copyWith(history: _history(batches: batches)),
          'onDeleteImages(${ids.length})',
        );
      },
      onClearHistory: () => _set(
        _d.copyWith(
          history: _history(batches: const []),
          canvas: const GenCanvasData(),
        ),
        'onClearHistory',
      ),
      onFavorite: (id, v) => _set(
        _d.copyWith(
          history: _history(
            batches: [
              for (final b in _d.history.batches)
                GenBatch(
                  id: b.id,
                  time: b.time,
                  pending: b.pending,
                  images: [
                    for (final i in b.images)
                      i.id == id
                          ? GenHistoryImage(
                              id: i.id,
                              thumb: i.thumb,
                              width: i.width,
                              height: i.height,
                              op: i.op,
                              favorite: v,
                            )
                          : i,
                  ],
                ),
            ],
          ),
        ),
        'onFavorite($id, $v)',
      ),
      onSendTo: base.onSendTo,
      onReveal: base.onReveal,
    );
  }

  // ── 块库侧栏（块系统已做好的组件，这里给假数据） ──
  var _dockFilter = const BlocksDockFilter.all();
  var _dockQuery = '';

  Widget dock() => BlocksDock(
    data: BlocksFixture.dock(
      image: blocksPreviewImage,
      filter: _dockFilter,
      query: _dockQuery,
    ),
    actions: BlocksDockActions(
      onQueryChanged: (q) {
        _dockQuery = q;
        notifyListeners();
      },
      onFilterChanged: (f) {
        _dockFilter = f;
        notifyListeners();
      },
      onInsert: (id) => log('dock.onInsert($id)'),
      dragDataOf: (id) => id,
      onCreate: () => log('dock.onCreate'),
      onOpenLibrary: () => log('dock.onOpenLibrary'),
      onClose: () {
        _layout = _layout.copyWith(dockOpen: false);
        notifyListeners();
      },
      onToggleGroup: (g, v) => log('dock.onToggleGroup($g, $v)'),
      onEdit: (id) => log('dock.onEdit($id)'),
      onSetFavorite: (id, v) => log('dock.onSetFavorite($id, $v)'),
      onAddToPalette: (id) => log('dock.onAddToPalette($id)'),
      onShowInLibrary: (id) => log('dock.onShowInLibrary($id)'),
    ),
  );
}
