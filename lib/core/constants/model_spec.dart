import 'api_constants.dart';

/// 模型家族。
///
/// 与网页端 bundle 的家族枚举对齐（`stableDiffusion` / `stableDiffusionGroup2`
/// / `stableDiffusionXL` / `stableDiffusionXLFurry` / `v4` / `v5`）。
enum ModelFamily {
  stableDiffusion,
  stableDiffusionGroup2,
  stableDiffusionXL,
  stableDiffusionXLFurry,
  v4,
  v5,
}

/// 单个模型的能力描述。
///
/// 取代散落各处的 `model.contains('diffusion-4')` 字符串判定：新模型只需在
/// [ModelSpecs._specs] 增加一条记录，调用方无需改动。字段名与网页端 bundle
/// 的 flag 表同名，便于上游更新时逐项核对。
class ModelSpec {
  const ModelSpec({
    required this.id,
    required this.family,
    required this.v4Prompts,
    required this.characterPrompts,
    required this.maxCharacters,
    required this.vibetransfer,
    required this.encodedVibes,
    required this.characterReferences,
    required this.noiseSchedule,
    required this.varietyPlus,
    required this.smea,
    required this.smeaDyn,
    required this.autoSmea,
    required this.opusUsageLimit,
    required this.freeformCharacterPosition,
    required this.img2imgInpainting,
    required this.transparency,
    required this.maxEnhance,
    this.billingVersion = 4,
  });

  /// 官方模型 id，例如 `nai-diffusion-5-full`。
  final String id;

  final ModelFamily family;

  /// 使用 `v4_prompt` / `v4_negative_prompt` 结构发送提示词。
  ///
  /// V5 沿用 V4 的结构，官网 bundle 中不存在 `v5_prompt`。
  final bool v4Prompts;

  /// 支持角色框（`char_captions`）。
  final bool characterPrompts;

  /// 角色框数量上限。V4/V4.5 为 6，V5 为 32。
  final int maxCharacters;

  /// 支持 Vibe Transfer。V5 已移除该功能。
  final bool vibetransfer;

  /// Vibe 需要先编码再使用（编码本身计费）。
  final bool encodedVibes;

  /// 支持 Character Reference。
  final bool characterReferences;

  /// 支持自定义噪声调度。V5 固定由服务端决定。
  final bool noiseSchedule;

  /// 支持 Variety+（`skip_cfg_above_sigma`）。V5 官网面板已无此开关。
  final bool varietyPlus;

  final bool smea;
  final bool smeaDyn;
  final bool autoSmea;

  /// Opus 免费额度受每月生成次数上限约束（V5 起启用）。
  final bool opusUsageLimit;

  /// 角色框支持任意坐标而非固定网格。
  final bool freeformCharacterPosition;

  /// Inpainting 时可复用原图潜空间。
  final bool img2imgInpainting;

  /// 支持原生透明背景（`tag_hint_transparent_background` / `straight_alpha`）。
  ///
  /// V5 起启用：服务端可按提示注入 transparent background 标签并输出
  /// 带 alpha 通道的图像。
  final bool transparency;

  /// 支持增强 Max✨ 档（`upscaled_enhance`，服务端端到端放大至 3MP 上限）。
  final bool maxEnhance;

  /// 计费公式版本，供 `AnlasCalculator` 选择面积/步数系数分支。
  ///
  /// V4/V4.5 = 4（现代系数）；V5 = 5（同一套系数，结果整体 ×1.5）。
  final int billingVersion;

  /// 是否为 V4 及更高版本（提示词结构维度）。
  bool get isV4OrLater => family == ModelFamily.v4 || family == ModelFamily.v5;

  bool get isV5 => family == ModelFamily.v5;

  bool get isInpainting => id.contains('inpainting');
}

/// 模型能力注册表。
class ModelSpecs {
  ModelSpecs._();

  /// V4.0 家族能力集合。
  static const ModelSpec _v4Family = ModelSpec(
    id: '',
    family: ModelFamily.v4,
    v4Prompts: true,
    characterPrompts: true,
    maxCharacters: 6,
    vibetransfer: true,
    encodedVibes: true,
    characterReferences: false,
    noiseSchedule: true,
    varietyPlus: true,
    smea: false,
    smeaDyn: false,
    autoSmea: false,
    opusUsageLimit: false,
    freeformCharacterPosition: false,
    img2imgInpainting: true,
    transparency: false,
    maxEnhance: false,
  );

  /// V4.5 家族能力集合：相比 V4.0 仅增加 Character Reference。
  static const ModelSpec _v45Family = ModelSpec(
    id: '',
    family: ModelFamily.v4,
    v4Prompts: true,
    characterPrompts: true,
    maxCharacters: 6,
    vibetransfer: true,
    encodedVibes: true,
    characterReferences: true,
    noiseSchedule: true,
    varietyPlus: true,
    smea: false,
    smeaDyn: false,
    autoSmea: false,
    opusUsageLimit: false,
    freeformCharacterPosition: false,
    img2imgInpainting: true,
    transparency: false,
    maxEnhance: false,
  );

  /// V5 家族能力集合。
  ///
  /// 与 V4.5 的关键差异（2026-08 取自官网 bundle flag 表）：
  /// Vibe Transfer 移除、角色框上限 6 → 32、噪声调度关闭、角色框支持自由坐标、
  /// Opus 免费额度受每月次数上限约束。
  static const ModelSpec _v5Family = ModelSpec(
    id: '',
    family: ModelFamily.v5,
    v4Prompts: true,
    characterPrompts: true,
    maxCharacters: 32,
    vibetransfer: false,
    encodedVibes: false,
    characterReferences: false,
    noiseSchedule: false,
    varietyPlus: false,
    smea: false,
    smeaDyn: false,
    autoSmea: false,
    opusUsageLimit: true,
    freeformCharacterPosition: true,
    img2imgInpainting: true,
    transparency: true,
    maxEnhance: true,
    billingVersion: 5,
  );

  /// V3 及更早模型的能力集合。
  static const ModelSpec _legacyFamily = ModelSpec(
    id: '',
    family: ModelFamily.stableDiffusionXL,
    v4Prompts: false,
    characterPrompts: false,
    maxCharacters: 0,
    vibetransfer: true,
    encodedVibes: false,
    characterReferences: false,
    noiseSchedule: true,
    varietyPlus: true,
    smea: true,
    smeaDyn: true,
    autoSmea: true,
    opusUsageLimit: false,
    freeformCharacterPosition: false,
    img2imgInpainting: true,
    transparency: false,
    maxEnhance: false,
    billingVersion: 3,
  );

  static ModelSpec _withId(ModelSpec base, String id) => ModelSpec(
    id: id,
    family: base.family,
    v4Prompts: base.v4Prompts,
    characterPrompts: base.characterPrompts,
    maxCharacters: base.maxCharacters,
    vibetransfer: base.vibetransfer,
    encodedVibes: base.encodedVibes,
    characterReferences: base.characterReferences,
    noiseSchedule: base.noiseSchedule,
    varietyPlus: base.varietyPlus,
    smea: base.smea,
    smeaDyn: base.smeaDyn,
    autoSmea: base.autoSmea,
    opusUsageLimit: base.opusUsageLimit,
    freeformCharacterPosition: base.freeformCharacterPosition,
    img2imgInpainting: base.img2imgInpainting,
    transparency: base.transparency,
    maxEnhance: base.maxEnhance,
    billingVersion: base.billingVersion,
  );

  static final Map<String, ModelSpec> _specs = {
    for (final id in const [
      ImageModels.animeDiffusionV5Full,
      ImageModels.animeDiffusionV5FullInpainting,
      ImageModels.animeDiffusionV5Curated,
      ImageModels.animeDiffusionV5CuratedInpainting,
    ])
      id: _withId(_v5Family, id),
    for (final id in const [
      ImageModels.animeDiffusionV45Full,
      ImageModels.animeDiffusionV45FullInpainting,
      ImageModels.animeDiffusionV45Curated,
      ImageModels.animeDiffusionV45CuratedInpainting,
    ])
      id: _withId(_v45Family, id),
    for (final id in const [
      ImageModels.animeDiffusionV4Full,
      ImageModels.animeDiffusionV4FullInpainting,
      ImageModels.animeDiffusionV4Curated,
      ImageModels.animeDiffusionV4CuratedInpainting,
    ])
      id: _withId(_v4Family, id),
  };

  /// 查表获取模型能力；未知模型回退到旧模型能力集合。
  ///
  /// 回退保证新增官方模型 id 时不会崩溃，只是不会自动获得新能力。
  static ModelSpec of(String model) {
    final spec = _specs[model];
    if (spec != null) return spec;
    return _withId(_legacyFamily, model);
  }

  /// 已注册的全部模型 id（含 inpainting 变体）。
  static Iterable<String> get registeredIds => _specs.keys;
}
