import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_icon_catalog.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_glyphs.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_extra_icons.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_icons.dart';

void main() {
  test(
    'group metadata exactly covers stable catalogs without duplicate keys',
    () {
      expect(UiBlockIcon.keys.toSet().length, UiBlockIcon.keys.length);
      expect(
        agentPromptSetGlyphNames.toSet().length,
        agentPromptSetGlyphNames.length,
      );
      expect(UiBlockIcon.groups.keys.toSet(), UiBlockIcon.keys.toSet());
      expect(
        agentPromptSetIconGroups.keys.toSet(),
        agentPromptSetGlyphNames.toSet(),
      );
      expect({
        ...kPromptBlockIconOptions.keys,
        ...additionalPromptIconNames,
      }, UiBlockIcon.keys.toSet());
      expect(PromptIconGroup.nsfw.id, 'nsfw');
      expect(PromptIconGroup.values.where((group) => group.hiddenByDefault), [
        PromptIconGroup.nsfw,
      ]);
      expect(
        additionalPromptIcons.keys.toSet(),
        additionalPromptIconNames.toSet(),
      );
      expect(additionalPromptIconNames, hasLength(44));
      expect(
        additionalPromptIcons.values.where((group) => group.hiddenByDefault),
        hasLength(8),
      );
      expect(UiBlockIcon.keys, hasLength(84));
      expect(agentPromptSetGlyphNames, hasLength(79));
    },
  );

  testWidgets('all legacy block glyphs render and unknown/null use default', (
    tester,
  ) async {
    for (final name in kPromptBlockIconOptions.keys) {
      await tester.pumpWidget(MaterialApp(home: UiBlockIcon(name)));
      expect(find.byType(UiGlyph), findsOneWidget, reason: name);
      expect(tester.takeException(), isNull);
    }
    for (final name in [
      null,
      'future-no-path',
      ...additionalPromptIconNames.where(
        (name) => !UiExtraIcons.paths.containsKey(name),
      ),
    ]) {
      await tester.pumpWidget(MaterialApp(home: UiBlockIcon(name)));
      expect(
        tester.widget<Icon>(find.byType(Icon)).icon,
        StudioIcons.promptBlocks,
      );
    }
  });

  testWidgets(
    'picker draft keeps legacy footprint and accepts explicit grouped keys',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlockIconGrid(
            selected: null,
            color: Colors.blue,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byKey(const Key('block-icon-palette')), findsOneWidget);
      expect(find.byKey(const Key('block-icon-eye')), findsNothing);
      expect(find.byKey(const Key('block-icon-r18')), findsNothing);
      await tester.pumpWidget(
        MaterialApp(
          home: BlockIconGrid(
            selected: null,
            color: Colors.blue,
            onChanged: (_) {},
            iconKeys: const ['eye', 'r18'],
          ),
        ),
      );
      expect(find.byKey(const Key('block-icon-eye')), findsOneWidget);
      expect(find.byKey(const Key('block-icon-r18')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('all prompt-set glyphs resolve and unknown/no-path keys fall back', () {
    for (final name in agentPromptSetGlyphNames) {
      expect(agentPromptSetGlyph(name), isNotEmpty, reason: name);
    }
    expect(agentPromptSetGlyph('future-no-path'), AgentGlyphs.book);
  });
}
