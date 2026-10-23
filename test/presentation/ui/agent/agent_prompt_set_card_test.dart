import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_prompt_set_card.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_position_board.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final calls = <(int, AgentPromptSetAction)>[];
  final edits = <String>[], images = <String>[];
  Future<void> pump(
    WidgetTester tester, {
    double width = 520,
    bool dark = false,
    AgentPromptSet? data,
    bool missing = false,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('prompt-set-capture'),
            child: SingleChildScrollView(
              child: AgentPromptSetCard(
                data: missing ? null : data ?? AgentFixture.promptSet(),
                onAction: (i, a) async {
                  calls.add((i, a));
                },
                onEdit: edits.add,
                onImage: (image, group) => images.add(image.id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    calls.clear();
    edits.clear();
    images.clear();
  });
  Finder key(String name) => find.byKey(Key('agent-ps-$name'));
  Future<void> tap(WidgetTester t, String name) async {
    await t.ensureVisible(key(name));
    await t.tap(key(name));
    await t.pumpAndSettle();
  }

  testWidgets('arrows, dots, focus keyboard, overview and revision', (t) async {
    await pump(t);
    expect(find.text('大雨'), findsOneWidget);
    expect(find.textContaining('v2'), findsOneWidget);
    await tap(t, 'next');
    expect(find.text('推门'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    expect(find.text('借伞的人'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await t.pumpAndSettle();
    expect(find.text('推门'), findsOneWidget);
    await tap(t, 'dot-4');
    expect(find.text('雨停的早晨'), findsOneWidget);
    await tap(t, 'prev');
    expect(find.text('热可可'), findsOneWidget);
    await tap(t, 'overview');
    expect(find.text('大雨'), findsOneWidget);
    expect(find.text('再来一次'), findsOneWidget);
    await t.tap(find.text('再来一次'));
    await t.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  AgentPromptSet positioned({double? aspect, bool defaults = false}) =>
      AgentPromptSet(
        setId: 'positions',
        revision: 1,
        kind: 'Storyboard',
        kindIcon: 'film',
        title: 'Positions',
        unit: 'scene',
        ordered: true,
        aspect: aspect,
        shared: AgentPromptSetShared(
          characters: const ['silver hair', 'brown hair', 'green hair'],
          positions: defaults ? const [Offset(.25, .5)] : const [],
        ),
        items: const [
          AgentPromptSetItem(
            icon: 'rain',
            title: 'Positioned',
            positions: [null, null, Offset(.8, .6)],
          ),
          AgentPromptSetItem(icon: 'coffee', title: 'Free'),
        ],
      );
  testWidgets(
    'only expanded CURRENT item shows board, original character indices and default aspect',
    (t) async {
      await pump(t, data: positioned());
      expect(find.byType(AgentPositionBoard), findsNothing);
      await tap(t, 'prompt');
      expect(find.byType(AgentPositionBoard), findsOneWidget);
      expect(find.byKey(const Key('agent-position-dot-2')), findsOneWidget);
      expect(find.byKey(const Key('agent-position-dot-0')), findsNothing);
      expect(find.text('角色 3'), findsOneWidget);
      final board = t.getSize(find.byType(AgentPositionBoard));
      expect(board.height, 84);
      expect(board.width / board.height, closeTo(2 / 3, .001));
      await tap(t, 'next');
      expect(find.byType(AgentPositionBoard), findsNothing);
      await tap(t, 'prev');
      expect(find.byType(AgentPositionBoard), findsOneWidget);
      await tap(t, 'prompt');
      expect(find.byType(AgentPositionBoard), findsNothing);
    },
  );
  testWidgets(
    'shared positions inherit through null/missing item entries and draft aspect is used',
    (t) async {
      await pump(t, data: positioned(defaults: true, aspect: 1.5));
      await tap(t, 'prompt');
      var board = t.widget<AgentPositionBoard>(find.byType(AgentPositionBoard));
      expect(board.block.marks.map((m) => m.index), [0, 2]);
      expect(board.block.marks.first.after, const Offset(.25, .5));
      final size = t.getSize(find.byType(AgentPositionBoard));
      expect(size.width / size.height, closeTo(1.5, .001));
      await tap(t, 'next');
      board = t.widget<AgentPositionBoard>(find.byType(AgentPositionBoard));
      expect(board.block.marks.map((m) => m.index), [0]);
    },
  );
  testWidgets(
    'no-position try-on set adds no board even after expansion/navigation',
    (t) async {
      await pump(t, data: AgentFixture.promptSet(ordered: false));
      await tap(t, 'prompt');
      expect(find.byType(AgentPositionBoard), findsNothing);
      expect(find.byKey(const Key('agent-ps-position-preview')), findsNothing);
      await tap(t, 'next');
      expect(find.byType(AgentPositionBoard), findsNothing);
    },
  );
  testWidgets('omitted versus empty/null positions render identical pixels', (
    t,
  ) async {
    AgentPromptSet noPositions(bool explicit) => AgentPromptSet(
      setId: 'same',
      revision: 1,
      kind: 'Try-on',
      kindIcon: 'shirt',
      title: 'Same',
      unit: 'outfit',
      ordered: false,
      shared: AgentPromptSetShared(
        characters: const ['silver hair'],
        positions: explicit ? const [null] : const [],
      ),
      items: [
        AgentPromptSetItem(
          icon: 'dress',
          title: 'Dress',
          positions: explicit ? const [null] : const [],
        ),
        const AgentPromptSetItem(icon: 'hat', title: 'Hat'),
      ],
    );
    Future<List<int>> pixels() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('prompt-set-capture')),
      );
      final image = await boundary.toImage();
      try {
        return (await image.toByteData())!.buffer.asUint8List().toList();
      } finally {
        image.dispose();
      }
    }

    await pump(t, data: noPositions(false));
    await tap(t, 'prompt');
    final before = await t.runAsync(pixels);
    await pump(t, data: noPositions(true));
    final after = await t.runAsync(pixels);
    expect(after, before);
    expect(find.byType(AgentPositionBoard), findsNothing);
  });
  testWidgets('prompt collapsed, same tag window, full expansion/collapse', (
    t,
  ) async {
    await pump(t);
    expect(find.text('主提示词'), findsNothing);
    await tap(t, 'prompt');
    expect(find.text('主提示词'), findsOneWidget);
    String body() => t
        .widgetList<RichText>(find.byType(RichText))
        .map((w) => w.text.toPlainText())
        .join('\n');
    expect(body(), contains('…'));
    expect(body(), isNot(contains('masterpiece,')));
    expect(body(), contains('street'));
    expect(body(), contains('角色 1'));
    expect(body(), contains('负面'));
    await tap(t, 'more-prompt');
    expect(body(), contains('masterpiece,'));
    expect(body(), contains('jpeg artifacts'));
    await tap(t, 'more-prompt');
    expect(body(), isNot(contains('masterpiece,')));
  });
  testWidgets(
    'footer and menu dispatch exact selected index; edit prefills composer',
    (t) async {
      await pump(t);
      await tap(t, 'dot-2');
      await tap(t, 'import');
      await tap(t, 'generate');
      expect(calls, [
        (2, AgentPromptSetAction.import),
        (2, AgentPromptSetAction.generate),
      ]);
      for (final (label, action) in [
        ('存成积木', AgentPromptSetAction.saveBlock),
        ('复制这一幕的提示词', AgentPromptSetAction.copyItem),
        ('复制全部', AgentPromptSetAction.copyAll),
      ]) {
        await tap(t, 'menu');
        await t.tap(find.text(label));
        await t.pumpAndSettle();
        expect(calls.last, (2, action));
      }
      await tap(t, 'menu');
      await t.tap(find.text('让 Agent 修改这一幕'));
      await t.pumpAndSettle();
      expect(edits.single, contains('借伞的人'));
      expect(edits.single, contains('3'));
      final image = find.byType(Image).first;
      await t.tap(image);
      await t.pumpAndSettle();
      expect(images, hasLength(1));
    },
  );
  testWidgets('inline import tray undo callback and busy placeholder', (
    t,
  ) async {
    final base = AgentFixture.promptSet();
    final data = AgentPromptSet(
      setId: base.setId,
      revision: base.revision,
      kind: base.kind,
      kindIcon: base.kindIcon,
      title: base.title,
      unit: base.unit,
      ordered: base.ordered,
      shared: base.shared,
      items: base.items,
      importedIndex: 0,
      canUndoImport: true,
      busyIndex: 0,
    );
    await pump(t, data: data);
    expect(find.text('生成中'), findsOneWidget);
    expect(find.textContaining('已把'), findsOneWidget);
    await tap(t, 'undo');
    expect(calls.single, (0, AgentPromptSetAction.undo));
    await tap(t, 'generate');
    expect(calls, hasLength(1));
  });
  for (final dark in [false, true]) {
    for (final width in [380.0, 520.0]) {
      testWidgets('light/dark narrow $dark $width all controls no overflow', (
        t,
      ) async {
        await pump(t, width: width, dark: dark);
        await tap(t, 'prompt');
        await tap(t, 'more-prompt');
        expect(t.takeException(), isNull);
        await tap(t, 'overview');
        expect(t.takeException(), isNull);
        await tap(t, 'overview');
        await tap(t, 'menu');
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('temporary missing/loading data does not reset selected index', (
    t,
  ) async {
    await pump(t);
    await tap(t, 'dot-4');
    await pump(t, missing: true);
    expect(find.byKey(const Key('agent-ps-next')), findsNothing);
    await pump(t);
    expect(find.text('雨停的早晨'), findsOneWidget);
  });
  testWidgets(
    'unordered omits total from position, revision shrink clamps selected item',
    (t) async {
      await pump(t);
      await tap(t, 'dot-7');
      await pump(t, data: AgentFixture.promptSet(ordered: false));
      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.text('第 6 套'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
