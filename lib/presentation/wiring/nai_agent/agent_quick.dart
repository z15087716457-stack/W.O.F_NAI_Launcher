import '../../../l10n/app_localizations.dart';
import '../../providers/nai_agent/nai_agent_quick_messages.dart';
import '../../ui/agent/agent_contract.dart';

/// 内置条目没改过时按界面语言取文字；改过的原样显示。
({String title, String hint, String prompt}) agentQuickText(
  AppLocalizations l,
  NaiAgentQuickMessage m,
) {
  if (!m.localized) return (title: m.title, hint: m.hint, prompt: m.prompt);
  return switch (m.builtin) {
    'review' => (
      title: l.ag_taskReview,
      hint: l.ag_taskReviewHint,
      prompt: l.ag_taskReviewPrompt,
    ),
    'analyze' => (
      title: l.ag_taskAnalyze,
      hint: l.ag_taskAnalyzeHint,
      prompt: l.ag_taskAnalyzePrompt,
    ),
    'variants' => (
      title: l.ag_taskVariants,
      hint: l.ag_taskVariantsHint,
      prompt: l.ag_taskVariantsPrompt,
    ),
    _ => (
      title: l.ag_taskBlocks,
      hint: l.ag_taskBlocksHint,
      prompt: l.ag_taskBlocksPrompt,
    ),
  };
}

List<AgentQuickItem> agentQuickItems(
  AppLocalizations l,
  List<NaiAgentQuickMessage> messages,
) => [
  for (final m in messages)
    if (agentQuickText(l, m) case final t when t.prompt.trim().isNotEmpty)
      AgentQuickItem(
        id: m.id,
        glyph: m.icon,
        title: t.title.trim().isEmpty ? t.prompt.trim() : t.title,
        hint: t.hint,
        prompt: t.prompt,
        send: m.send,
      ),
];
