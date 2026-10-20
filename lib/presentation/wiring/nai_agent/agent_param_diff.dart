import '../../../core/constants/api_constants.dart';
import '../../../core/constants/model_display.dart';
import '../../../core/constants/model_spec.dart';
import '../../ui/agent/agent_contract.dart';

/// 参数卡能撤销的草稿键（与 `validateBridgePatch` 的标量键一致，不含提示词与角色）。
const agentParamKeys = [
  'model',
  'width',
  'height',
  'steps',
  'cfg_scale',
  'cfg_rescale',
  'sampler',
  'noise_schedule',
  'seed',
  'n_samples',
  'variety_plus',
  'smea_auto',
  'smea',
  'smea_dyn',
  'quality_preset',
  'uc_preset',
  'transparent_background',
];

/// 比较改动前后的草稿字段，列出这次 `prompt_update` 真正改变、且改动后模型用得上的参数。
/// [applied] 是工具回报的写入键（含 `seed_lock` 这类派生键）。
List<AgentParamChange> agentParamChanges(
  List<dynamic> applied,
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  final keys = {
    for (final k in applied) k.toString(),
    if (applied.contains('seed_lock')) 'seed',
  };
  if (!keys.any(agentParamKeys.contains)) return const [];
  final model = (after['model'] ?? before['model']) as String? ?? '';
  final spec = ModelSpecs.of(model);
  bool changed(String k) => keys.contains(k) && before[k] != after[k];
  String plain(Object? v) {
    if (v is! num) return '$v';
    final d = v.toDouble();
    return d == d.roundToDouble() ? d.toStringAsFixed(0) : '$d';
  }

  AgentParamValue text(Object? v) => AgentParamValue.text(plain(v));
  AgentParamValue flag(Object? v) =>
      AgentParamValue.word(v == true ? AgentParamWord.on : AgentParamWord.off);
  AgentParamValue seed(Object? v) => v is num && v >= 0
      ? AgentParamValue.text('${v.toInt()}')
      : const AgentParamValue.word(AgentParamWord.random);
  AgentParamValue sampler(Object? v) =>
      AgentParamValue.text(Samplers.samplerDisplayNames[v] ?? '$v');
  AgentParamValue schedule(Object? v) =>
      AgentParamValue.text(NoiseSchedules.displayNames[v] ?? '$v');
  AgentParamValue size(Map<String, dynamic> f) =>
      AgentParamValue.text('${f['width']}×${f['height']}');
  String smea(Map<String, dynamic> f) => f['smea_auto'] == true
      ? 'auto'
      : f['smea'] != true
      ? 'off'
      : f['smea_dyn'] == true
      ? 'dyn'
      : 'on';
  AgentParamValue smeaValue(String v) => switch (v) {
    'auto' => const AgentParamValue.text('Auto'),
    'dyn' => const AgentParamValue.text('SMEA DYN'),
    'on' => const AgentParamValue.text('SMEA'),
    _ => const AgentParamValue.word(AgentParamWord.off),
  };
  AgentParamValue quality(Object? v) => switch (v) {
    'none' => const AgentParamValue.word(AgentParamWord.none),
    'light' => const AgentParamValue.text('Light'),
    _ => const AgentParamValue.text('Standard'),
  };
  AgentParamValue uc(Object? v) =>
      AgentParamValue.text(UCPresets.displayNames[v] ?? '$v');

  final out = <AgentParamChange>[];
  void add(AgentParam p, AgentParamValue a, AgentParamValue b) {
    if (a != b) out.add(AgentParamChange(p, a, b));
  }

  if (changed('model')) {
    add(
      AgentParam.model,
      AgentParamValue.text(ModelDisplay.shortNameOf('${before['model']}')),
      AgentParamValue.text(ModelDisplay.shortNameOf(model)),
    );
  }
  if (changed('width') || changed('height')) {
    add(AgentParam.size, size(before), size(after));
  }
  // Turbo 等固定步数 / 采样器的模型：改了也不生效，不列。
  if (changed('steps') && spec.fixedSteps == null) {
    add(AgentParam.steps, text(before['steps']), text(after['steps']));
  }
  if (changed('cfg_scale')) {
    add(
      AgentParam.guidance,
      text(before['cfg_scale']),
      text(after['cfg_scale']),
    );
  }
  if (changed('cfg_rescale') && spec.cfgRescale) {
    add(
      AgentParam.rescale,
      text(before['cfg_rescale']),
      text(after['cfg_rescale']),
    );
  }
  if (changed('sampler') && spec.fixedSampler == null) {
    add(
      AgentParam.sampler,
      sampler(before['sampler']),
      sampler(after['sampler']),
    );
  }
  if (changed('noise_schedule') && spec.noiseSchedule) {
    add(
      AgentParam.noiseSchedule,
      schedule(before['noise_schedule']),
      schedule(after['noise_schedule']),
    );
  }
  if (changed('seed')) {
    add(AgentParam.seed, seed(before['seed']), seed(after['seed']));
  }
  if (changed('n_samples')) {
    add(AgentParam.count, text(before['n_samples']), text(after['n_samples']));
  }
  if (changed('variety_plus') && spec.varietyPlus) {
    add(
      AgentParam.variety,
      flag(before['variety_plus']),
      flag(after['variety_plus']),
    );
  }
  if ((changed('smea') || changed('smea_dyn') || changed('smea_auto')) &&
      spec.smea) {
    add(AgentParam.smea, smeaValue(smea(before)), smeaValue(smea(after)));
  }
  if (changed('quality_preset')) {
    add(
      AgentParam.qualityPreset,
      quality(before['quality_preset']),
      quality(after['quality_preset']),
    );
  }
  if (changed('uc_preset') && spec.customNegativePrompt) {
    add(AgentParam.ucPreset, uc(before['uc_preset']), uc(after['uc_preset']));
  }
  if (changed('transparent_background') && spec.transparency) {
    add(
      AgentParam.transparent,
      flag(before['transparent_background']),
      flag(after['transparent_background']),
    );
  }
  return out;
}

/// 撤销参数卡时写回的键：卡上每一项对应的原始草稿键。
List<String> agentParamRestoreKeys(List<AgentParamChange> changes) => [
  for (final c in changes)
    ...switch (c.param) {
      AgentParam.model => const ['model', 'sampler'],
      AgentParam.size => const ['width', 'height'],
      AgentParam.steps => const ['steps'],
      AgentParam.guidance => const ['cfg_scale'],
      AgentParam.rescale => const ['cfg_rescale'],
      AgentParam.sampler => const ['sampler'],
      AgentParam.noiseSchedule => const ['noise_schedule'],
      AgentParam.seed => const ['seed'],
      AgentParam.count => const ['n_samples'],
      AgentParam.variety => const ['variety_plus'],
      AgentParam.smea => const ['smea_auto', 'smea', 'smea_dyn'],
      AgentParam.qualityPreset => const ['quality_preset'],
      AgentParam.ucPreset => const ['uc_preset'],
      AgentParam.transparent => const ['transparent_background'],
    },
];
