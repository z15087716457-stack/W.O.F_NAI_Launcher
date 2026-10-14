import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_welcome.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_parts.dart';
import 'package:nai_launcher/presentation/widgets/bridge/bridge_link_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/prompt_translation_guide.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

GenSlots slots({bool captions = true}) => GenSlots(
  editor: GenFixtureEditor.builder,
  emptyCanvas: (_) => const ProviderScope(child: GenerationWelcome()),
  translationGuide: (_, back) => PromptTranslationGuide(onBack: back),
  agentToggle: const IconButton(
    key: Key('fixture-agent-toggle'),
    onPressed: _nothing,
    icon: Icon(Icons.auto_awesome_outlined),
  ),
  historyCaptionInset: captions,
);
void _nothing() {}

Future<void> capture(WidgetTester t, String name) async {
  if (Platform.environment['FEEDBACK_CAPTURES'] != '1') return;
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('gen-capture')),
    );
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    bitmap.dispose();
    final file = File(
      '.dart_tool/feedback-restoration-20261014/captures/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'restored toolbar and tutorial $locale dark=$dark at narrow width',
        (t) async {
          final record = GenRecorder();
          await pumpGen(
            t,
            data: GenFixture.view(layout: const GenLayout(leftWidth: 352)),
            slots: slots(),
            actions: record.actions,
            locale: locale,
            dark: dark,
            height: 680,
          );
          expect(find.byKey(const Key('fixture-agent-toggle')), findsOneWidget);
          expect(find.byIcon(Icons.translate), findsOneWidget);
          expect(t.takeException(), isNull);
          await tapKey(t, 'gen-tool-menu');
          await tapKey(t, 'gen-pin-agent');
          expect(
            record.last('onPromptTool'),
            'onPromptTool(GenPromptTool.agentPinned, false)',
          );
          await t.tapAt(const Offset(650, 100));
          await t.pumpAndSettle();
          await tapKey(t, 'gen-translate-menu');
          await tapKey(t, 'gen-translation-tutorial');
          expect(find.byType(MouseGestureIcon), findsNWidgets(3));
          expect(find.byIcon(Icons.keyboard), findsOneWidget);
          expect(
            find.byKey(const Key('gen-translation-guide')),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
          if (locale == 'zh') {
            await capture(t, 'tutorial-${dark ? 'dark' : 'light'}');
          }
          await tapKey(t, 'translation-guide-back');
          expect(find.byKey(const Key('gen-translate-new')), findsOneWidget);
          expect(find.byKey(const Key('gen-translation-guide')), findsNothing);
          expect(t.takeException(), isNull);
        },
      );
      testWidgets('restored empty logo and stable tip $locale dark=$dark', (
        t,
      ) async {
        await pumpGen(
          t,
          data: GenFixture.empty(),
          slots: slots(),
          locale: locale,
          dark: dark,
          height: 680,
        );
        expect(find.byType(GenerationWelcome), findsOneWidget);
        await t.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/wof_logo_full.png'),
            t.element(find.byType(GenerationWelcome)),
          ),
        );
        await t.pump();
        final logo = find.descendant(
          of: find.byType(GenerationWelcome),
          matching: find.byType(RawImage),
        );
        expect(t.widget<RawImage>(logo).image, isNotNull);
        expect(t.widget<RawImage>(logo).image!.width, 1111);
        expect(t.getRect(logo).height, greaterThan(140));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('tip-welcome-text')), findsOneWidget);
        final text = t
            .widget<Text>(find.byKey(const Key('tip-welcome-text')))
            .data;
        await t.pump(const Duration(minutes: 6));
        expect(
          t.widget<Text>(find.byKey(const Key('tip-welcome-text'))).data,
          text,
        );
        expect(t.takeException(), isNull);
        if (locale == 'zh') {
          await capture(t, 'welcome-${dark ? 'dark' : 'light'}');
        }
      });
    }
  }
  testWidgets(
    'history caption inset disappears only when Agent occupies the right dock',
    (t) async {
      for (final reserved in [true, false, true]) {
        await pumpGen(
          t,
          data: GenFixture.view(),
          slots: slots(captions: reserved),
        );
        final header = t.getRect(find.byKey(const Key('gen-history-header')));
        expect(header.top, reserved ? 36 : 0);
        expect(header.height, 40);
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets('bridge uses the retained double link in all feedback phases', (
    t,
  ) async {
    final base = GenFixture.view();
    for (final phase in GenBridgePhase.values) {
      await pumpGen(
        t,
        data: base.copyWith(
          prompt: GenPromptData(
            bridge: GenBridge(phase: phase, label: phase.name),
          ),
        ),
      );
      final link = t.widget<BridgeLinkIcon>(find.byType(BridgeLinkIcon));
      expect(link.working, phase == GenBridgePhase.working);
      expect(
        t.getSize(find.byKey(const Key('gen-bridge'))),
        const Size(24, 24),
      );
    }
  });
  testWidgets('top tool clicks play the retained glyph motion immediately', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        home: const Scaffold(
          body: GenIb(
            animatedIcon: StudioIcons.promptBlockPalette,
            onTap: _nothing,
          ),
        ),
      ),
    );
    final icon = find.byType(StudioAnimatedIcon);
    expect(t.widget<StudioAnimatedIcon>(icon).trigger, 0);
    await t.tap(find.byType(GenIb));
    await t.pump();
    expect(t.widget<StudioAnimatedIcon>(icon).trigger, 1);
    await t.pump(const Duration(milliseconds: 150));
    expect(t.binding.hasScheduledFrame, isTrue);
    await t.pumpAndSettle();
    expect(t.binding.hasScheduledFrame, isFalse);
  });
}
