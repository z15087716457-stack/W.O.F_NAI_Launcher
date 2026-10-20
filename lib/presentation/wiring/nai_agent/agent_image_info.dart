import '../../../core/constants/model_display.dart';
import '../../ui/agent/agent_contract.dart';

/// 把附件自带的 NovelAI 元数据（[readNaiAttachmentMetadata] 的压缩 JSON）
/// 收成悬停卡片用的生成信息（提示词全文、负面、各角色）；没有可显示的内容时返回 null。
AgentImageInfo? agentImageInfo(Map<String, dynamic>? meta) {
  if (meta == null || meta.isEmpty) return null;
  String? str(String key) {
    final v = meta[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  int? integer(String key) {
    final v = meta[key];
    return v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
  }

  double? number(String key) {
    final v = meta[key];
    return v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  }

  String? flat(String? v) => v?.replaceAll(RegExp(r'\s+'), ' ');
  List<String> strings(String key) => [
    for (final v in meta[key] as List? ?? const []) v is String ? v : '',
  ];

  final model = str('model');
  final chars = strings('characterPrompts');
  final charNegatives = strings('characterNegativePrompts');
  final smea = meta['smea'] == true
      ? (meta['smeaDyn'] == true ? 'SMEA DYN' : 'SMEA')
      : null;
  final info = AgentImageInfo(
    model: model == null ? null : ModelDisplay.shortNameOf(model),
    steps: integer('steps'),
    scale: number('scale'),
    sampler: str('sampler'),
    seed: integer('seed'),
    prompt: flat(str('prompt')),
    negative: flat(str('negativePrompt')),
    cfgRescale: number('cfgRescale'),
    noiseSchedule: str('noiseSchedule'),
    smea: smea,
    characterPrompts: [
      for (final (i, prompt) in chars.indexed)
        AgentImageCharacter(
          prompt: flat(prompt.trim()) ?? '',
          negative:
              i < charNegatives.length && charNegatives[i].trim().isNotEmpty
              ? flat(charNegatives[i].trim())
              : null,
        ),
    ],
  );
  final empty =
      info.model == null &&
      info.steps == null &&
      info.scale == null &&
      info.sampler == null &&
      info.seed == null &&
      info.prompt == null &&
      info.negative == null &&
      info.characters == 0;
  return empty ? null : info;
}
