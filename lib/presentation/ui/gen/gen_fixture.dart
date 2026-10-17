import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'gen_contract.dart';

/// 生图页假数据：照原型（`.devin/mockups/generation/mock.html#a` / `#a-v45`）的内容。
/// 测试和预览用；[GenFixture.images] 换成原型图时就和原型同图。
abstract final class GenFixture {
  /// 按 key 取图（`canvas`、`h1`、`h2`、`g07`……），默认渐变占位图。
  static ImageProvider Function(String key) images = UiFixtureImage.gradient;

  static ImageProvider _img(String key, ImageProvider? Function(String)? f) =>
      f?.call(key) ?? images(key);

  static final now = DateTime(2026, 10, 12, 16, 45);

  static const models = [
    GenModel(
      id: 'nai-diffusion-5',
      name: 'V5 Full',
      description: '最新模型，Opus 免费额度内不扣 Anlas',
    ),
    GenModel(
      id: 'nai-diffusion-4-5-full',
      name: 'V4.5 Full',
      description: '支持风格迁移和精准参考',
    ),
    GenModel(
      id: 'nai-diffusion-4-5-curated',
      name: 'V4.5 Curated',
      description: '精选数据集，更安全',
    ),
    GenModel(id: 'nai-diffusion-4-full', name: 'V4 Full'),
    GenModel(id: 'nai-diffusion-3', name: 'Anime V3', legacy: true),
    GenModel(id: 'nai-diffusion-furry-3', name: 'Furry V3', legacy: true),
  ];

  static const presets = [
    GenSizePreset(GenSizeGroup.normal, GenOrientation.portrait, 832, 1216),
    GenSizePreset(GenSizeGroup.normal, GenOrientation.landscape, 1216, 832),
    GenSizePreset(GenSizeGroup.normal, GenOrientation.square, 1024, 1024),
    GenSizePreset(GenSizeGroup.large, GenOrientation.portrait, 1024, 1536),
    GenSizePreset(GenSizeGroup.large, GenOrientation.landscape, 1536, 1024),
    GenSizePreset(GenSizeGroup.large, GenOrientation.square, 1472, 1472),
    GenSizePreset(GenSizeGroup.wallpaper, GenOrientation.portrait, 1088, 1920),
    GenSizePreset(GenSizeGroup.wallpaper, GenOrientation.landscape, 1920, 1088),
    GenSizePreset(GenSizeGroup.small, GenOrientation.portrait, 512, 768),
    GenSizePreset(GenSizeGroup.small, GenOrientation.landscape, 768, 512),
    GenSizePreset(GenSizeGroup.small, GenOrientation.square, 640, 640),
  ];

  static const samplers = [
    GenOption(id: 'k_euler_ancestral', label: 'Euler Ancestral', detail: ''),
    GenOption(
      id: 'k_dpmpp_2s_ancestral',
      label: 'DPM++ 2S Ancestral',
      detail: '',
    ),
    GenOption(id: 'k_dpmpp_2m_sde', label: 'DPM++ 2M SDE', detail: ''),
    GenOption(id: 'k_euler', label: 'Euler'),
    GenOption(id: 'k_dpmpp_2m', label: 'DPM++ 2M'),
    GenOption(id: 'k_dpmpp_sde', label: 'DPM++ SDE'),
  ];

  static const noises = [
    GenOption(id: 'native', label: 'Native'),
    GenOption(id: 'karras', label: 'Karras', detail: '默认'),
    GenOption(id: 'exponential', label: 'Exponential'),
    GenOption(id: 'polyexponential', label: 'Polyexponential'),
  ];

  static const qualityPresets = [
    GenOption(id: 'none', label: '无'),
    GenOption(id: 'standard', label: '标准'),
  ];

  static const ucPresets = [
    GenOption(id: 'heavy', label: '重度'),
    GenOption(id: 'light', label: '轻度'),
    GenOption(id: 'human', label: '人物专注'),
    GenOption(id: 'none', label: '无'),
  ];

  static const upscaleOptions = [
    GenOption(id: 'local-anime', label: '本地 · 4x-AnimeSharp', detail: '免费'),
    GenOption(id: 'local-real', label: '本地 · RealESRGAN', detail: '免费'),
    GenOption(id: 'novelai', label: 'NovelAI 云端放大', detail: '按尺寸计费'),
  ];

  static const positivePreview = [
    GenPreviewSection(
      label: '主提示词',
      text:
          'scenery, panorama, from behind, green theme, blue theme, plant, detailed background, …',
    ),
    GenPreviewSection(
      label: '质量词',
      text: 'very aesthetic, masterpiece, no text',
    ),
    GenPreviewSection(
      label: '角色 1',
      text: 'girl, 1.5::loli, child::, 1.4::silver hair::, …',
    ),
  ];

  static const negativePreview = [
    GenPreviewSection(
      label: '负面',
      text:
          'lowres, artistic error, scan artifacts, worst quality, bad quality, …',
    ),
    GenPreviewSection(
      label: '负面预设 · 重度',
      text:
          'blurry, lowres, error, film grain, scan artifacts, worst quality, bad quality, jpeg artifacts, very displeasing, chromatic aberration, …',
    ),
  ];

  /// 方案 A 主界面：V5（[v45] = V4.5 Full：无 Opus / 透明背景、多两行参考图、风格迁移已加 2 张收起）。
  static GenViewData view({
    bool v45 = false,
    bool dark = false,
    ImageProvider? Function(String key)? images,
    GenLayout layout = const GenLayout(),
  }) {
    final f = images;
    return GenViewData(
      model: v45 ? 'nai-diffusion-4-5-full' : 'nai-diffusion-5',
      models: models,
      turboVisible: !v45,
      turbo: v45 ? null : false,
      furry: false,
      quota: GenQuota(
        opusPercent: v45 ? null : 147,
        opusTip: v45 ? null : 'Opus 免费额度剩余 147%',
        anlas: 2218,
      ),
      layout: layout,
      prompt: GenPromptData(
        positiveTokens: const GenTokens(77, 512),
        negativeTokens: const GenTokens(64, 512),
        qualityPresets: qualityPresets,
        qualityPreset: 'none',
        ucPresets: ucPresets,
        ucPreset: 'heavy',
        transparent: v45 ? null : false,
        positivePreview: positivePreview,
        negativePreview: negativePreview,
        tools: const GenPromptTools(palettePinned: true),
        translate: const GenTranslate(route: 'DeepSeek · deepseek-chat'),
      ),
      characters: GenCharactersData(
        list: const [
          GenCharacter(
            id: 'c1',
            positiveTokens: GenTokens(46, 512),
            negativeTokens: GenTokens(0, 512),
          ),
        ],
        max: v45 ? 6 : 32,
        freeform: !v45,
      ),
      refs: GenRefsData(
        vibes: v45
            ? GenVibesData(
                list: [
                  GenVibe(id: 'v1', thumb: _img('g07', f), name: '青绿废墟'),
                  GenVibe(
                    id: 'v2',
                    thumb: _img('g46', f),
                    name: '蓝花夜空',
                    strength: .45,
                  ),
                ],
                recent: [
                  GenRecentVibe(id: 'r1', thumb: _img('g33', f), name: '水彩'),
                  GenRecentVibe(id: 'r2', thumb: _img('g50', f), name: '逆光'),
                ],
              )
            : null,
        precise: v45 ? const GenPreciseData() : null,
      ),
      image: const GenImageData(presets: presets),
      params: GenParamsData(
        seed: 3274348526,
        seedPinned: true,
        samplers: samplers,
        noise: v45 ? 'karras' : null,
        noises: noises,
        varietyPlus: v45 ? false : null,
      ),
      generate: const GenGenerateData(label: '生成 1 张图片', cost: 0),
      canvas: GenCanvasData(
        focus: GenGroup(
          id: 'b1',
          tiles: [
            GenTile(
              id: 'i1',
              width: 1664,
              height: 2432,
              image: _img('canvas', f),
            ),
          ],
        ),
        info: const GenFocusInfo(
          tileId: 'i1',
          width: 1664,
          height: 2432,
          seed: 3274348526,
        ),
        upscale: const GenUpscale(
          options: upscaleOptions,
          selected: 'local-anime',
        ),
        backdrop: v45 ? null : 'checker',
      ),
      history: GenHistoryData(
        selected: 'b1',
        batches: [
          GenBatch(
            id: 'b1',
            time: DateTime(2026, 10, 12, 16, 42),
            images: [
              GenHistoryImage(
                id: 'i1',
                thumb: _img('canvas', f),
                width: 1664,
                height: 2432,
                op: GenOp.upscale,
              ),
            ],
          ),
          GenBatch(
            id: 'b2',
            time: DateTime(2026, 10, 12, 16, 38),
            images: [
              GenHistoryImage(
                id: 'i2',
                thumb: _img('h1', f),
                width: 832,
                height: 1216,
              ),
              GenHistoryImage(
                id: 'i3',
                thumb: _img('h0', f),
                width: 832,
                height: 1216,
              ),
            ],
          ),
          GenBatch(
            id: 'b3',
            time: DateTime(2026, 10, 12, 16, 31),
            images: [
              for (final k in ['h2', 'g03', 'g33', 'g50'])
                GenHistoryImage(
                  id: 'i-$k',
                  thumb: _img(k, f),
                  width: 832,
                  height: 1216,
                ),
            ],
          ),
          GenBatch(
            id: 'b4',
            time: DateTime(2026, 10, 12, 16, 20),
            images: [
              GenHistoryImage(
                id: 'i5',
                thumb: _img('g18', f),
                width: 832,
                height: 1216,
                favorite: true,
              ),
              GenHistoryImage(
                id: 'i6',
                thumb: _img('g46', f),
                width: 832,
                height: 1216,
              ),
            ],
          ),
        ],
      ),
      now: now,
    );
  }

  /// V3：没有角色模块、没有 Mode 胶囊；参数抽屉有 SMEA / Decrisp。
  static GenViewData v3({ImageProvider? Function(String key)? images}) {
    final base = view(v45: true, images: images);
    return GenViewData(
      model: 'nai-diffusion-3',
      models: models,
      quota: base.quota,
      prompt: base.prompt,
      refs: GenRefsData(vibes: GenVibesData(recent: base.refs.vibes!.recent)),
      image: base.image,
      params: const GenParamsData(
        seed: 3274348526,
        samplers: samplers,
        noise: 'native',
        noises: noises,
        decrisp: false,
        varietyPlus: false,
        smea: GenSmea(),
      ),
      generate: const GenGenerateData(label: '生成 1 张图片', cost: 20),
      canvas: base.canvas,
      history: base.history,
      now: now,
    );
  }

  /// 第一次打开：画布和历史都是空的，没有角色。
  static GenViewData empty() {
    final base = view();
    return base.copyWith(
      characters: const GenCharactersData(max: 32, freeform: true),
      canvas: const GenCanvasData(),
      history: const GenHistoryData(),
      params: const GenParamsData(samplers: samplers, noises: noises),
    );
  }

  /// 生成中：一次 4 张，第 2 张在出（有流式预览），后两张排队；历史最上面多一批“还剩 2 张”。
  static GenViewData generating({ImageProvider? Function(String key)? images}) {
    final base = view(images: images);
    final f = images;
    return base.copyWith(
      image: const GenImageData(presets: presets, count: 4),
      generate: const GenGenerateData(
        state: GenRunState.generating,
        label: '生成 4 张图片',
        done: 1,
        total: 4,
        progress: .38,
      ),
      canvas: GenCanvasData(
        locked: true,
        focus: GenGroup(
          id: 'b0',
          tiles: [
            GenTile(id: 'n1', width: 832, height: 1216, image: _img('g33', f)),
            GenTile(
              id: 'n2',
              width: 832,
              height: 1216,
              state: GenTileState.streaming,
              preview: _img('g50', f),
              progress: .55,
            ),
            const GenTile(
              id: 'n3',
              width: 832,
              height: 1216,
              state: GenTileState.pending,
            ),
            const GenTile(
              id: 'n4',
              width: 832,
              height: 1216,
              state: GenTileState.pending,
            ),
          ],
        ),
        info: const GenFocusInfo(
          tileId: 'n1',
          width: 832,
          height: 1216,
          seed: 1938201277,
        ),
        upscale: base.canvas.upscale,
      ),
      history: GenHistoryData(
        selected: 'b0',
        batches: [
          GenBatch(
            id: 'b0',
            time: DateTime(2026, 10, 12, 16, 44),
            pending: 3,
            images: [
              GenHistoryImage(
                id: 'n1',
                thumb: _img('g33', f),
                width: 832,
                height: 1216,
              ),
            ],
          ),
          ...base.history.batches,
        ],
      ),
    );
  }

  /// 生成失败：画布下方出失败卡（429 并发）。
  static GenViewData failed({ImageProvider? Function(String key)? images}) {
    final base = view(images: images);
    return base.copyWith(
      canvas: GenCanvasData(
        focus: base.canvas.focus,
        info: base.canvas.info,
        upscale: base.canvas.upscale,
        error: const GenError(
          title: '请求太频繁',
          hint: '同一账号同时只能跑一个生成。等上一张结束，或者稍等几秒再试。',
          detail: 'HTTP 429 Too Many Requests: Concurrent generation is locked',
        ),
      ),
    );
  }

  /// V4.5 参考图全展开：图生图有图（带蒙版）、两张 Vibe（一张待编码）、一张精准参考 → 冲突提示。
  static GenViewData refsFull({ImageProvider? Function(String key)? images}) {
    final base = view(v45: true, images: images);
    final f = images;
    return base.copyWith(
      refs: GenRefsData(
        img2img: GenImg2Img(
          image: _img('g19', f),
          width: 1216,
          height: 832,
          strength: .55,
          noise: .1,
          mask: GenMask.ready,
          inpaintStrength: .8,
        ),
        vibes: GenVibesData(
          list: [
            GenVibe(id: 'v1', thumb: _img('g07', f), name: '青绿废墟'),
            GenVibe(
              id: 'v2',
              thumb: _img('g46', f),
              name: '蓝花夜空',
              strength: .45,
              state: GenVibeState.pending,
            ),
          ],
          recent: base.refs.vibes!.recent,
        ),
        precise: GenPreciseData(
          list: [
            GenPrecise(
              id: 'p1',
              thumb: _img('g03', f),
              strength: .8,
              fidelity: .6,
            ),
          ],
        ),
      ),
    );
  }

  /// 多个角色、自定义定位（V4.5 网格），一个停用。
  static GenViewData characters({bool v45 = true}) {
    final base = view(v45: v45);
    return base.copyWith(
      characters: GenCharactersData(
        aiPosition: false,
        max: v45 ? 6 : 32,
        freeform: !v45,
        list: const [
          GenCharacter(
            id: 'c1',
            name: '银发少女',
            positiveTokens: GenTokens(46, 512),
            position: Offset(.3, .5),
          ),
          GenCharacter(
            id: 'c2',
            gender: GenGender.male,
            positiveTokens: GenTokens(30, 512),
            position: Offset(.7, .5),
          ),
          GenCharacter(
            id: 'c3',
            gender: GenGender.other,
            enabled: false,
            positiveTokens: GenTokens(12, 512),
          ),
        ],
      ),
    );
  }
}
