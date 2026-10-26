import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';

/// 已回答的提问（原型 `.devin/mockups/fix-batch-1024` 场景 agent，`.qa`）：
/// 面板底标题条「向你提问 · 已回答 · 时间」，下面逐题列出：序号 · 问题（次要色）·
/// 选项答案用蓝色已选标签（`.ach`），自由回答用左侧竖线引用（`.aq`）。不随工具步骤折叠。
class AgentAnsweredQuestionsView extends StatelessWidget {
  const AgentAnsweredQuestionsView({super.key, required this.block});
  final AgentAnsweredQuestionsBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final at = block.at;
    return Container(
      key: const Key('agent-answered-questions'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.qah`
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              spacing: 8,
              children: [
                AgentIcon(AgentGlyphs.help, size: 14, color: c.muted),
                Expanded(
                  child: Text(
                    l.ag_answeredTitle,
                    style: UiText.sans(12.5, color: c.muted, height: 1.3),
                  ),
                ),
                if (at != null)
                  Text(
                    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
                    style: UiText.mono(11, color: c.faint),
                  ),
              ],
            ),
          ),
          for (final (i, q) in block.questions.indexed)
            _Item(index: i + 1, question: q),
        ],
      ),
    );
  }
}

/// `.qai`：20 宽序号列 + 问题 / 答案。
class _Item extends StatelessWidget {
  const _Item({required this.index, required this.question});
  final int index;
  final AgentAnsweredQuestion question;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final q = question;
    final Widget answer = q.kind == AgentAnswerKind.option
        // `.ach`
        ? Container(
            padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AgentIcon(
                    AgentGlyphs.check,
                    size: 13,
                    color: c.accent,
                  ),
                ),
                Flexible(
                  child: Text(
                    q.optionLabel ?? q.answer,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w600,
                      color: c.accent,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        // `.aq`
        : Container(
            padding: const EdgeInsets.fromLTRB(9, 1, 0, 1),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.strong, width: 2)),
            ),
            child: Text(
              q.answer,
              style: UiText.sans(13, color: c.ink, height: 1.6),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index',
              textAlign: TextAlign.center,
              style: UiText.mono(
                11,
                weight: FontWeight.w600,
                color: c.faint,
                height: 20 / 11,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  q.question,
                  style: UiText.sans(13, color: c.muted, height: 1.55),
                ),
                answer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
