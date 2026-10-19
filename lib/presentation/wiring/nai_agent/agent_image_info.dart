import '../../../core/constants/model_display.dart';
import '../../ui/agent/agent_contract.dart';

/// 把附件自带的 NovelAI 元数据（[readNaiAttachmentMetadata] 的压缩 JSON）
/// 收成悬停卡片用的几项摘要；没有可显示的内容时返回 null。
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

  final model = str('model');
  final prompt = str('prompt');
  final chars = meta['characterPrompts'];
  final info = AgentImageInfo(
    model: model == null ? null : ModelDisplay.shortNameOf(model),
    steps: integer('steps'),
    scale: number('scale'),
    sampler: str('sampler'),
    seed: integer('seed'),
    prompt: prompt?.replaceAll(RegExp(r'\s+'), ' '),
    characters: chars is List ? chars.length : 0,
  );
  final empty =
      info.model == null &&
      info.steps == null &&
      info.scale == null &&
      info.sampler == null &&
      info.seed == null &&
      info.prompt == null &&
      info.characters == 0;
  return empty ? null : info;
}
