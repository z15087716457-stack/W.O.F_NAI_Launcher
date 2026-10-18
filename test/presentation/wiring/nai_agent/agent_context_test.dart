import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations_en.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_context.dart';

void main() {
  test(
    'current draft mentions and summary count tags, characters and structural blocks',
    () {
      final draft = BridgeDraftSnapshot(
        fields: {
          'prompt': 'a, b, ',
          'negative_prompt': 'bad',
          'model': 'nai-diffusion-5-full',
          'width': 832,
          'height': 1216,
          'characters': [
            {'id': 'one', 'name': '', 'prompt': 'x, y'},
          ],
        },
        documents: {
          'prompt': {
            'instances': {'a': {}, 'b': {}},
          },
          'characters': {
            'lanes': {
              'one': {
                'positive': {
                  'instances': {'c': {}},
                },
              },
            },
          },
        },
      );
      final mentions = agentDraftMentions(draft, AppLocalizationsEn());
      expect(mentions.map((m) => m.kind), [
        AgentMentionKind.prompt,
        AgentMentionKind.negative,
        AgentMentionKind.character,
      ]);
      expect(mentions.first.detail, contains('2'));
      expect(mentions.last.label, contains('1'));
      final summary = agentDraftSummary(draft, const ImageParams(), null);
      expect(summary.blocks, 3);
      expect(summary.characters, 1);
      expect(summary.width, 832);
      expect(summary.prompt, 'a, b, ');
    },
  );
}
