import 'package:flutter/painting.dart';

import '../../../data/models/director/director_tool_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_questions.dart' as questions;
import '../../ui/agent/agent_contract.dart';
import 'agent_thread_mapper.dart';

AgentPending agentQuestionData(questions.AgentQuestionRequest request) {
  if (request.kind == 'tool_approval' && request.questions.isNotEmpty) {
    final q = request.questions.first;
    final lines = q.text.split('\n');
    return AgentApproval(
      request.id,
      tool: agentToolName(lines.first.replaceFirst(RegExp(r'^.*?[:：]\s*'), '')),
      preview: lines.skip(1).join('\n').trim(),
      options: q.options,
    );
  }
  return AgentAsk(
    request.id,
    questions: [
      for (final q in request.questions)
        AgentQuestion(
          id: q.id,
          text: q.text,
          options: q.options,
          allowCustom: q.allowCustom,
          allowEmpty: q.allowEmpty,
          multiline: q.multiline,
          prefill: q.prefill,
          placeholder: q.placeholder,
        ),
    ],
  );
}

bool _valid(void Function() check) {
  try {
    check();
    return true;
  } catch (_) {
    return false;
  }
}

AgentGate agentGenerationGate(
  AgentGenerationApproval request,
  AppLocalizations l,
) {
  final q = request.quote, input = q.input;
  final ready = _valid(request.check);
  final extra = <String>[
    if (input.sourceOperation != null && input.raw.sourceImage != null)
      '${l.img2img_strength} ${input.raw.strength.toStringAsFixed(2)} · ${l.img2img_noise} ${input.raw.noise.toStringAsFixed(2)}',
    if (input.raw.upscaledEnhance) l.img2img_enhanceMax,
    if (input.sourceOperation == 'explore') l.nav_styleExplore,
    if (input.localEnhance case final enhancement?)
      l.naiAgent_generationLocalEnhance(
        enhancement['model'].toString(),
        enhancement['scale'].toString(),
      ),
  ];
  return AgentGate(
    request.id,
    kind: switch (input.sourceOperation ?? input.raw.action.name) {
      'variations' => AgentGateKind.variations,
      'enhance' => AgentGateKind.enhance,
      'img2img' => AgentGateKind.img2img,
      'infill' => AgentGateKind.inpaint,
      _ => AgentGateKind.text2img,
    },
    expiresAt: q.expiresAt.toLocal(),
    ready: ready,
    changed: !ready,
    model: input.effective.model,
    width: input.outputSize.width,
    height: input.outputSize.height,
    requests: input.raw.nSamples,
    batch: input.batchSize,
    unitAnlas: agentInt(input.billing['per_request_anlas']),
    encodingAnlas: agentInt(input.billing['encoding_anlas']),
    totalAnlas: input.estimate,
    balanceAnlas: input.balance,
    account: input.accountName,
    prompt: input.effective.prompt,
    extra: extra.isEmpty ? null : extra.join(' · '),
    source: input.raw.sourceImage == null
        ? null
        : MemoryImage(input.raw.sourceImage!),
  );
}

AgentGate agentImageGate(AgentImageApproval request, AppLocalizations l) {
  final q = request.quote;
  final ready = _valid(request.check);
  final tool = DirectorToolType.values
      .where((t) => t.name == q['tool'])
      .firstOrNull;
  return AgentGate(
    request.id,
    kind: AgentGateKind.imageTool,
    title: tool?.labelKey(l) ?? l.img2img_novelAiCloudUpscale,
    expiresAt:
        request.expiresAt?.toLocal() ??
        DateTime.tryParse(q['expires_at']?.toString() ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    ready: ready,
    changed: !ready,
    width: agentInt(q['width']),
    height: agentInt(q['height']),
    totalAnlas: agentInt(q['estimated_anlas']),
    balanceAnlas: agentInt(q['balance_anlas']),
    account: q['account_name'] as String?,
    prompt: q['prompt'] as String?,
    extra: q['emotion'] as String?,
    source: request.sourceBytes == null
        ? null
        : MemoryImage(request.sourceBytes!),
  );
}
