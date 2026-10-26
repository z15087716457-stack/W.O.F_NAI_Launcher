import 'package:flutter/material.dart';
import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';

class AgentAnsweredQuestionsView extends StatelessWidget {
  const AgentAnsweredQuestionsView({super.key, required this.block});
  final AgentAnsweredQuestionsBlock block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final at = block.at;
    return Container(
      key: const Key('agent-answered-questions'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 6,
            children: [
              AgentIcon(AgentGlyphs.help, size: 14, color: c.muted),
              Expanded(
                child: Text(
                  context.l10n.ag_answeredTitle,
                  style: UiText.sans(
                    12,
                    weight: FontWeight.w600,
                    color: c.muted,
                  ),
                ),
              ),
              if (at != null)
                Text(
                  '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
                  style: UiText.mono(10.5, color: c.faint),
                ),
            ],
          ),
          for (final (i, q) in block.questions.indexed)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text('${i + 1}', style: UiText.mono(11, color: c.faint)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        q.question,
                        style: UiText.sans(12, color: c.muted, height: 1.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: q.kind == AgentAnswerKind.option
                              ? c.accent.withValues(alpha: .09)
                              : null,
                          borderRadius: q.kind == AgentAnswerKind.option
                              ? BorderRadius.circular(5)
                              : null,
                          border: q.kind == AgentAnswerKind.free
                              ? Border(
                                  left: BorderSide(color: c.border, width: 2),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5,
                          children: [
                            if (q.kind == AgentAnswerKind.option)
                              AgentIcon(
                                AgentGlyphs.check,
                                size: 13,
                                color: c.accent,
                              ),
                            Flexible(
                              child: Text(
                                q.optionLabel ?? q.answer,
                                style: UiText.sans(
                                  12,
                                  color: q.kind == AgentAnswerKind.option
                                      ? c.accent
                                      : c.ink,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
