import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent_generation_host.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../helpers/agent_data_reader.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../wiring/nai_agent/agent_wiring_harness.dart';

int _mounts = 0, _disposals = 0;

class _Retained extends StatefulWidget {
  const _Retained();
  @override
  State<_Retained> createState() => _RetainedState();
}

class _RetainedState extends State<_Retained> {
  @override
  void initState() {
    super.initState();
    _mounts++;
  }

  @override
  void dispose() {
    _disposals++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init();
  });
  tearDown(() async {
    await h.dispose();
  });
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });
  Widget host(Widget child) =>
      NaiAgentIntegrationScope(child: NaiAgentGenerationHost(child: child));
  Future<void> open() async {
    await h.c.updateSettings({'panelExpanded': true});
    h.container.read(naiAgentUiPreferencesProvider).replace(h.c.settings);
  }

  testWidgets('opening clips fixed-width new panel and retains original page', (
    tester,
  ) async {
    _mounts = _disposals = 0;
    await h.pump(tester, child: host(const _Retained()), width: 1448);
    final prefs = h.container.read(naiAgentUiPreferencesProvider);
    prefs.replace(
      AgentSettings.fromJson({...h.c.settings.toJson(), 'panelExpanded': true}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final width = tester
        .getSize(find.byKey(const Key('nai-agent-reveal')))
        .width;
    expect(width, greaterThan(0));
    expect(width, lessThan(528));
    expect(tester.getSize(find.byType(AgentPanel)).width, 520);
    await tester.pumpAndSettle();
    prefs.replace(h.c.settings);
    await tester.pumpAndSettle();
    expect(_mounts, 1);
    expect(_disposals, 0);
    expect(tester.getSize(find.byKey(const Key('nai-agent-reveal'))).width, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'resize persists split, preserves history, editor and canvas elements',
    (tester) async {
      await open();
      await h.pump(
        tester,
        width: 1600,
        child: host(
          GenerationPage(
            data: GenFixture.view(),
            actions: GenActions.logging((_) {}),
            slots: GenSlots(
              preserveHistory: true,
              historyCaptionInset: false,
              canvas: (_, __) => const _Retained(),
              editor: (_, target) =>
                  target.character == null && !target.negative
                  ? const SizedBox(
                      height: 60,
                      child: TextField(key: Key('kept-editor')),
                    )
                  : const SizedBox(height: 60),
            ),
          ),
        ),
      );
      final editor = find.byKey(const Key('kept-editor'));
      final originalEditor = editor.evaluate().single;
      final canvas = find.byType(_Retained).evaluate().single;
      await tester.enterText(editor, 'retain draft');
      final resize = find.byKey(const Key('nai-agent-resize'));
      await tester.drag(resize, const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(h.c.settings.panelWidth, 600);
      expect(h.container.read(naiAgentWindowControllerProvider).addedWidth, 0);
      for (final width in [752.0, 564.0, 1600.0]) {
        tester.view.physicalSize = Size(width, 860);
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const Key('kept-editor'), skipOffstage: false)
              .evaluate()
              .single,
          same(originalEditor),
        );
        expect(
          find.byType(_Retained, skipOffstage: false).evaluate().single,
          same(canvas),
        );
        expect(find.byKey(const Key('gen-history')), findsOneWidget);
        final pane = tester.getRect(find.byType(AgentPanel));
        expect(
          tester.getRect(find.byKey(const Key('gen-history'))).right,
          lessThanOrEqualTo(pane.left),
        );
        expect(pane.right, lessThanOrEqualTo(width));
      }
      expect(find.text('retain draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('divider paints continuously over new header body and footer', (
    tester,
  ) async {
    await open();
    for (final brightness in Brightness.values) {
      final capture = GlobalKey();
      await h.pump(
        tester,
        width: 1200,
        brightness: brightness,
        child: RepaintBoundary(key: capture, child: host(const _Retained())),
      );
      final pane = tester.getRect(find.byType(AgentPanel));
      final color = Theme.of(
        tester.element(find.byType(AgentPanel)),
      ).colorScheme.outlineVariant;
      await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(find.byKey(capture))
            .toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        for (var y = 0; y < image.height; y++) {
          final o = (y * image.width + pane.left.round()) * 4;
          expect(
            (data.getUint8(o + 3) << 24) |
                (data.getUint8(o) << 16) |
                (data.getUint8(o + 1) << 8) |
                data.getUint8(o + 2),
            color.toARGB32(),
          );
        }
        image.dispose();
      });
    }
  });

  testWidgets(
    'composer persists, IME does not send, Enter sends, model filtering is exact',
    (tester) async {
      await h.pump(tester);
      expect(h.panel(tester).data.models.map((m) => m.modelId), ['model']);
      final input = find.byKey(const Key('agent-input'));
      await tester.enterText(input, 'first\nsecond\nthird');
      await tester.pump();
      expect(h.c.selected!.composer.text, 'first\nsecond\nthird');
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '输入中',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(h.c.calls, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'done',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(h.c.calls, ['send']);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.c.calls, ['send']);
      await h.c.updateSettings({'providerId': '', 'modelId': ''});
      await tester.pump();
      expect(h.panel(tester).data.composer.canSend, false);
      expect(h.c.selected!.composer.text, isNotEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'paste preserves original image and metadata, remove goes through controller',
    (tester) async {
      final png = img.encodePng(
        img.Image(
          width: 2,
          height: 1,
          textData: {
            'Software': 'NovelAI',
            'Description': 'original prompt',
            'Comment': jsonEncode({
              'prompt': 'original prompt',
              'seed': 54321,
              'steps': 28,
            }),
          },
        ),
      );
      h.clipboard = () async => [AgentFixtureDataReader(bytes: png)];
      await h.pump(tester);
      await tester.enterText(find.byKey(const Key('agent-input')), 'keep text');
      await h.paste(tester);
      await h.finishFiles(tester);
      await tester.pumpAndSettle();
      final a = h.c.selected!.composer.attachments.single;
      expect(
        await tester.runAsync(
          () => h.c.store.readAttachment(h.c.selected!.workspace.id, a),
        ),
        png,
      );
      expect(
        h.panel(tester).data.composer.attachments.single.metadata,
        contains('54321'),
      );
      expect(h.c.selected!.composer.text, 'keep text');
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(Key('agent-attachment-${a.id}'))),
      );
      await tester.pump();
      await tester.tap(find.byKey(Key('agent-attachment-remove-${a.id}')));
      await mouse.removePointer();
      await tester.pump();
      expect(h.c.selected!.composer.attachments, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('context menu uses image-first paste path', (tester) async {
    h.clipboard = () async => [
      AgentFixtureDataReader(
        bytes: img.encodePng(img.Image(width: 2, height: 1)),
      ),
    ];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'synthetic'}
          : call.method == 'Clipboard.hasStrings'
          ? {'value': true}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await h.pump(tester);
    await tester.longPress(find.byKey(const Key('agent-input')));
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
      find.byType(AdaptiveTextSelectionToolbar),
    );
    toolbar.buttonItems!
        .singleWhere((i) => i.type == ContextMenuButtonType.paste)
        .onPressed!();
    await h.finishFiles(tester);
    expect(h.c.selected!.composer.attachments, hasLength(1));
    expect(h.c.calls, isEmpty);
  });

  testWidgets(
    'switch during paste keeps original target; new chat can paste independently',
    (tester) async {
      final first = h.c.selected!, read = Completer<List<DataReader>>();
      final png = img.encodePng(img.Image(width: 2, height: 2));
      var reads = 0;
      h.clipboard = () => reads++ == 0
          ? read.future
          : Future.value([AgentFixtureDataReader(bytes: png)]);
      await h.pump(tester);
      await tester.enterText(find.byKey(const Key('agent-input')), 'first');
      await h.paste(tester);
      await tester.runAsync(() => h.c.createWorkspace('second'));
      await tester.pumpAndSettle();
      final second = h.c.selected!;
      await tester.enterText(find.byKey(const Key('agent-input')), 'second');
      await h.paste(tester);
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      read.complete([AgentFixtureDataReader(bytes: png)]);
      await h.finishFiles(tester);
      expect(first.composer.attachments, hasLength(1));
      expect(second.composer.attachments, hasLength(1));
      expect(first.composer.text, 'first');
      expect(second.composer.text, 'second');
    },
  );

  testWidgets('rich clipboard failure falls back to text at latest selection', (
    tester,
  ) async {
    final read = Completer<List<DataReader>>();
    h.clipboard = () => read.future;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': ' pasted'} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await h.pump(tester);
    final input = find.byKey(const Key('agent-input'));
    await tester.enterText(input, 'old');
    await h.paste(tester);
    await tester.enterText(input, 'latest');
    read.completeError(StateError('no rich clipboard'));
    await h.finishFiles(tester);
    expect(h.c.selected!.composer.text, 'latest pasted');
  });

  testWidgets(
    'usage separates current context from cumulative; thinking/permission persist',
    (tester) async {
      h.c.selected!.context = {'tokens': 43200, 'contextWindow': 200000};
      h.c.selected!.stats = {
        'tokens': {'input': 128000, 'total': 210080},
      };
      await h.pump(tester, width: 320);
      await tester.tap(find.byKey(const Key('agent-usage')));
      await tester.pump();
      expect(h.c.calls, contains('usage'));
      expect(h.panel(tester).data.usage.tokens, 43200);
      expect(find.text('210,080'), findsOneWidget);
      await tester.tapAt(const Offset(5, 400));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-model')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-thinking-high')));
      await tester.pump();
      expect(h.c.settings.reasoningEffort, 'high');
      expect(
        h.container
            .read(promptAssistantConfigProvider)
            .models
            .first
            .reasoningEffort,
        'medium',
      );
      await tester.tap(find.byKey(const Key('agent-model')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-thinking-default')));
      await tester.pump();
      expect(h.c.settings.reasoningEffort, isNull);
      await tester.tap(find.byKey(const Key('agent-permission')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-permission-readonly')));
      await tester.pump();
      expect(h.c.settings.permissionMode, 'readonly');
      h.c.selected!.context['windowKnown'] = false;
      await h.c.saveComposer('');
      await tester.pump();
      expect(h.panel(tester).data.usage.window, isNull);
    },
  );

  testWidgets(
    'ask_user explicit answer and extension editor whitespace are preserved',
    (tester) async {
      final r = h.c.selected!, q = h.container.read(naiAgentQuestionsProvider);
      final result = q.ask(r.workspace.id, r.chat.id, {
        'questions': [
          {
            'id': 'direction',
            'question': 'Direction?',
            'options': ['One', 'Two'],
          },
        ],
      }, NaiAgentCancellation());
      await h.pump(tester, width: 320);
      expect(h.panel(tester).data.status, view.AgentRunStatus.waitingUser);
      await tester.tap(find.byKey(const Key('agent-ask-option-direction-1')));
      await tester.pump();
      expect(q.forChat(r.chat.id), hasLength(1));
      await tester.tap(find.byKey(const Key('agent-ask-submit')));
      await tester.pump();
      expect((await result)['details']['answers'][0]['answer'], 'Two');
      final edit = q.askExtensionUi(r.workspace.id, r.chat.id, {
        'method': 'editor',
        'title': 'Edit',
        'prefill': '  initial\n',
      }, NaiAgentCancellation());
      await tester.pump();
      final field = find.byKey(const Key('agent-ask-custom-value'));
      expect(tester.widget<TextField>(field).controller!.text, '  initial\n');
      await tester.enterText(field, '\n  edited\n');
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-ask-submit')));
      await tester.pump();
      expect((await edit)['details']['value'], '\n  edited\n');
      expect(h.c.calls, isEmpty);
    },
  );

  testWidgets(
    'callbacks preserve queue/stop/edit/regenerate and chat lifecycle',
    (tester) async {
      final r = h.c.selected!;
      r.messages = [
        {'role': 'user', 'timestamp': 1, 'content': 'user'},
        {'role': 'assistant', 'content': 'reply'},
      ];
      r.userEntries = [
        {'id': 'e1', 'message': r.messages.first},
      ];
      r.composer = const AgentComposerState(
        text: 'follow-up',
        pending: [
          {'queueId': 'q', 'text': 'next', 'behavior': 'steer'},
        ],
      );
      await h.pump(tester);
      var a = h.panel(tester).actions;
      await a.onSend(steer: true);
      await a.onStop();
      await a.onEditQueued('q', 'new');
      await a.onSteerQueued('q');
      await a.onWithdrawQueued('q');
      expect(h.c.queueEdits, [
        ('q', 'new', false, false),
        ('q', null, false, true),
        ('q', null, true, false),
      ]);
      await a.onRegenerate();
      expect(
        h.c.calls,
        containsAllInOrder(['steer', 'stop', 'edit:e1', 'send']),
      );
      final original = r.chat.id;
      await tester.runAsync(() => a.onNewChat());
      await tester.pump();
      a = h.panel(tester).actions;
      await tester.runAsync(
        () => a.onRenameChat(h.c.selected!.chat.id, 'renamed'),
      );
      await tester.pump();
      expect(h.c.selected!.chat.title, 'renamed');
      await tester.runAsync(() => a.onSelectChat(original));
      await tester.pump();
      expect(h.c.selected!.chat.id, original);
      await tester.runAsync(() => a.onCreateWorkspace('Other'));
      await tester.pump();
      expect(h.c.selectedWorkspace!.name, 'Other');
      await h.finishFiles(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovered queue restore refuses nonempty composer then restores through controller',
    (tester) async {
      h.c.selected!.composer = const AgentComposerState(
        text: 'do not overwrite',
        pending: [
          {'queueId': 'recovered', 'text': 'recover me', 'recovered': true},
        ],
      );
      await h.pump(tester);
      var actions = h.panel(tester).actions;
      await expectLater(
        actions.onRestoreQueued('recovered'),
        throwsA(isA<NaiAgentToolError>()),
      );
      expect(h.c.selected!.composer.text, 'do not overwrite');
      await h.c.saveComposer('');
      await tester.pump();
      actions = h.panel(tester).actions;
      expect(await actions.onRestoreQueued('recovered'), true);
      await tester.pump();
      expect(h.c.selected!.composer.text, 'recover me');
      expect(h.c.selected!.composer.pending, isEmpty);
    },
  );

  testWidgets(
    'welcome fills composer only; errors and notices retain controller strings',
    (tester) async {
      await h.pump(tester);
      await tester.tap(find.byKey(const Key('agent-task-0')));
      await tester.pump();
      expect(h.c.selected!.composer.text, isNotEmpty);
      expect(h.c.calls, isEmpty);
      h.c.selected!.error = 'prelocalized error';
      h.c.selected!.extensionNotices.add('notice');
      await h.c.saveComposer('');
      await tester.pump();
      expect(find.text('prelocalized error'), findsOneWidget);
      h.panel(tester).actions.onDismissNotices();
      await tester.pump();
      expect(h.c.selected!.extensionNotices, isEmpty);
    },
  );

  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'real-font new panel $locale $brightness wide/narrow/short caption and long markdown',
        (tester) async {
          final token = List.filled(150, 'abcdefgh').join();
          h.c.selected!.messages = [
            {
              'role': 'assistant',
              'content':
                  '${List.filled(12, '长段落换行。').join()}\n\nhttps://example.invalid/$token\n\n```text\n$token\n```\n\n| a | b |\n| --- | --- |\n| width | $token |',
            },
          ];
          for (final width in [320.0, 440.0]) {
            await h.pump(
              tester,
              width: width,
              height: 480,
              locale: locale,
              brightness: brightness,
              child: const WindowChromeScope(
                enabled: true,
                extraWidth: 88,
                child: AgentWiring(),
              ),
            );
            expect(
              tester.getRect(find.byKey(const Key('agent-header'))).top,
              0,
            );
            expect(
              tester.getRect(find.byKey(const Key('agent-composer'))).right,
              lessThanOrEqualTo(width),
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('new panel fits actual native caption controls', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      (call) async => call.method == 'isMaximized' ? false : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        null,
      ),
    );
    await h.pump(
      tester,
      width: 320,
      child: const IntegratedTitleBarShell(child: AgentWiring()),
    );
    expect(find.byType(AgentPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
