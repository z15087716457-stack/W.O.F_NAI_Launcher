import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_auto_run_name.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_run_switcher.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('zh'));
  final blocks = [
    'A',
    'B',
    'C',
  ].map((title) => PromptBlock.create(title: title, content: title)).toList();
  final library = PromptBlockLibraryState(blocks: blocks, folders: const []);
  final now = DateTime(2026, 10, 9, 18, 54);
  PillDocument document(int count) => PillDocument(
    text: '',
    instances: {
      for (var i = 0; i < count; i++)
        String.fromCharCode(0xE000 + i): PillInstance(
          blockId: blocks[i].id,
          evolutionEnabled: true,
          settings: const PillInstanceSettings(mode: PillRollMode.random),
        ),
    },
  );
  for (final entry in <int, String>{
    0: l10n.styleExplore_manualRunName('10-09 18:54'),
    1: 'A · 10-09 18:54',
    2: 'A + B · 10-09 18:54',
    3: 'A + B +1 · 10-09 18:54',
  }.entries) {
    test('automatic name uses ${entry.key} eligible random blocks', () {
      expect(
        exploreAutoRunName(
          document: document(entry.key),
          library: library,
          l10n: l10n,
          now: now,
        ),
        entry.value,
      );
    });
  }
  test(
    'disabled, fixed and evolution-off instances do not enter automatic name',
    () {
      final doc = PillDocument(
        text: '',
        instances: {
          '\uE000': PillInstance(
            blockId: blocks[0].id,
            enabled: false,
            evolutionEnabled: true,
            settings: const PillInstanceSettings(mode: PillRollMode.random),
          ),
          '\uE001': PillInstance(blockId: blocks[1].id, evolutionEnabled: true),
          '\uE002': PillInstance(
            blockId: blocks[2].id,
            settings: const PillInstanceSettings(mode: PillRollMode.random),
          ),
        },
      );
      expect(
        exploreAutoRunName(
          document: doc,
          library: library,
          l10n: l10n,
          now: now,
        ),
        l10n.styleExplore_manualRunName('10-09 18:54'),
      );
    },
  );
  test(
    'each event reads fresh block titles and timestamp; sequential rolls count too',
    () {
      final original = document(1);
      final renamed = PromptBlockLibraryState(
        blocks: [blocks[0].copyWith(title: '新池')],
        folders: const [],
      );
      expect(
        exploreAutoRunName(
          document: original,
          library: library,
          l10n: l10n,
          now: now,
        ),
        'A · 10-09 18:54',
      );
      expect(
        exploreAutoRunName(
          document: original,
          library: renamed,
          l10n: l10n,
          now: now.add(const Duration(minutes: 2)),
        ),
        '新池 · 10-09 18:56',
      );
      final sequential = PillDocument(
        text: '',
        instances: {
          '\uE000': PillInstance(
            blockId: blocks[0].id,
            evolutionEnabled: true,
            settings: const PillInstanceSettings(mode: PillRollMode.sequential),
          ),
        },
      );
      expect(
        exploreAutoRunName(
          document: sequential,
          library: library,
          l10n: l10n,
          now: now,
        ),
        'A · 10-09 18:54',
      );
    },
  );
  test('date groups use updatedAt with a Monday week boundary', () {
    expect(exploreRunDateGroup(DateTime(2026, 10, 9), now), 0);
    expect(exploreRunDateGroup(DateTime(2026, 10, 5), now), 1);
    expect(exploreRunDateGroup(DateTime(2026, 10, 4, 23, 59), now), 2);
  });
}
