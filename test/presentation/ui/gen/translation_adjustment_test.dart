import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/nai_agent/translation_context.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';
import 'package:nai_launcher/presentation/providers/translation_adjustment_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/translation_adjustment_overlay.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _Client implements TranslationAdjustmentClient {
  final stream = StreamController<Map<String, dynamic>>.broadcast();
  final sent = <String>[];
  bool closed = false;
  int stops = 0;
  Completer<void>? pending;
  @override
  String get modelLabel => 'Fixture · translation-model';
  @override
  Stream<Map<String, dynamic>> get events => stream.stream;
  @override
  Future<void> prompt(String text) async {
    sent.add(text);
    await pending?.future;
  }

  @override
  Future<void> abort() async {
    stops++;
    pending?.complete();
    pending = null;
  }

  @override
  Future<void> close() async {
    closed = true;
    await stream.close();
  }

  void message(Map<String, dynamic> value) => stream.add({
    'type': 'event',
    'event': {'type': 'message_end', 'message': value},
  });
}

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final overlay = TranslationAdjustmentOverlay();
  int clicks = 0;
  @override
  void dispose() {
    overlay.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton(
        key: const Key('open-adjustment'),
        onPressed: () => overlay.toggle(
          context,
          const Rect.fromLTWH(20, 30, 360, 30),
          false,
        ),
        child: const Text('Open fixture'),
      ),
      TextButton(
        key: const Key('left-action'),
        onPressed: () => setState(() => clicks++),
        child: Text('Left $clicks'),
      ),
      const SizedBox(
        width: 360,
        child: PromptPillEditor(config: UnifiedPromptConfig(), minLines: 3),
      ),
    ],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('closing while session starts releases the late client', (
    tester,
  ) async {
    final ready = Completer<TranslationAdjustmentClient>();
    final container = ProviderContainer(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        characterPromptNotifierProvider.overrideWith(_Characters.new),
        translationAdjustmentFactoryProvider.overrideWithValue(
          (context, execute) => ready.future,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(promptTranslationContextsProvider.notifier).state = {
      false: TranslationContext([
        const TranslationExchange(
          system: 's',
          request: 'u',
          raw: 'a',
          providerId: 'p',
          modelId: 'm',
        ),
      ], const []),
    };
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: genApp(const _Host()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-adjustment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('translation-adjustment-close')));
    await tester.pumpAndSettle();
    final client = _Client();
    ready.complete(client);
    await tester.pumpAndSettle();
    expect(client.closed, isTrue);
    expect(container.exists(naiAgentControllerProvider), isFalse);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'nonmodal translation adjustment selection tools undo release dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = _Client();
        var currentClient = client;
        final container = ProviderContainer(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
            characterPromptNotifierProvider.overrideWith(_Characters.new),
            translationAdjustmentFactoryProvider.overrideWithValue(
              (context, execute) async => currentClient,
            ),
          ],
        );
        addTearDown(container.dispose);
        final workspace = container.read(
          pillWorkspaceProvider(PillScopes.main).notifier,
        );
        workspace.insertTranslationAt(
          offset: 0,
          source: 'silver hair',
          zh: '银色长发',
        );
        container.read(promptTranslationContextsProvider.notifier).state = {
          false: TranslationContext([
            const TranslationExchange(
              system: 'fixture system',
              request: 'fixture request',
              raw: 'fixture reply',
              providerId: 'fixture',
              modelId: 'translation-model',
            ),
          ], const []),
        };
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: genApp(const _Host(), dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        expect(container.exists(naiAgentControllerProvider), isFalse);
        await tester.tap(find.byKey(const Key('open-adjustment')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('translation-adjustment-window')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('left-action')));
        await tester.pumpAndSettle();
        expect(find.text('Left 1'), findsOneWidget);
        expect(
          find.byKey(const Key('translation-adjustment-window')),
          findsOneWidget,
        );
        final reference = find.byKey(
          const ValueKey('translation-reference-main/\ue000'),
        );
        expect(reference, findsOneWidget);
        await tester.tap(reference);
        await tester.pumpAndSettle();
        expect(container.read(translationReferencesProvider).selected, {
          'main/\ue000',
        });
        await tester.tap(find.text('合并选中'));
        await tester.pumpAndSettle();
        final input = find.byKey(const Key('translation-adjustment-input'));
        expect(
          tester.widget<TextField>(input).controller!.text,
          contains('main/\ue000'),
        );
        await tester.enterText(input, 'first line');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(client.sent, isEmpty);
        expect(
          tester.widget<TextField>(input).controller!.text,
          contains('\n'),
        );
        await tester.enterText(input, '请把银色长发拆开');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(client.sent.single, contains('References: main/'));
        await tester.tap(reference);
        await tester.pumpAndSettle();
        expect(container.read(translationReferencesProvider).selected, isEmpty);
        await tester.tap(reference);
        await tester.pumpAndSettle();
        client.pending = Completer<void>();
        await tester.enterText(input, 'stop fixture');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(find.byIcon(Icons.stop), findsOneWidget);
        await tester.tap(find.byKey(const Key('translation-adjustment-send')));
        await tester.pumpAndSettle();
        expect(client.stops, 1);
        client.message({
          'role': 'user',
          'timestamp': 1,
          'content': '把银色长发拆开，颜色和长度分开。',
        });
        client.message({
          'role': 'assistant',
          'timestamp': 2,
          'content': [
            {'type': 'thinking', 'thinking': '先读取当前块与版本，再保持原文不变进行细分。'},
            {
              'type': 'toolCall',
              'id': 'read',
              'name': 'translation_blocks_read',
              'arguments': {},
            },
          ],
        });
        client.message({
          'role': 'toolResult',
          'timestamp': 3,
          'toolCallId': 'read',
          'toolName': 'translation_blocks_read',
          'isError': false,
          'content': [],
        });
        client.message({
          'role': 'assistant',
          'timestamp': 4,
          'content': [
            {
              'type': 'toolCall',
              'id': 'edit',
              'name': 'translation_blocks_edit',
              'arguments': {},
            },
          ],
        });
        final controller = container.read(translationAdjustmentProvider(false));
        final coordinator = container.read(
          promptTranslationCoordinatorProvider,
        );
        // Use the exact executor invoked by the MCP bridge, not a widget shortcut.
        await controller.execute('translation_blocks_edit', {
          'expected_version': coordinator.adjustmentVersion(false),
          'operations': [
            {
              'scope': 'main',
              'op': 'split',
              'marker': '\ue000',
              'parts': [
                {'source': 'silver ', 'translation': '银发'},
                {'source': 'hair', 'translation': '长发'},
              ],
            },
          ],
        }, NaiAgentCancellation());
        client.message({
          'role': 'toolResult',
          'timestamp': 5,
          'toolCallId': 'edit',
          'toolName': 'translation_blocks_edit',
          'isError': false,
          'content': [],
        });
        client.message({
          'role': 'assistant',
          'timestamp': 6,
          'content': [
            {'type': 'text', 'text': '已拆成 **银发** 和 **长发**，原文保持不变。可以撤销这一步。'},
          ],
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(container.read(translationReferencesProvider).changed.length, 2);
        final freshBorder = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byKey(const ValueKey('translation-reference-main/')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (freshBorder.decoration as BoxDecoration).border!.top.color,
          Colors.green,
        );
        expect(freshBorder.position, DecorationPosition.foreground);
        expect(
          container.read(pillWorkspaceProvider(PillScopes.main)).projection,
          'silver hair',
        );
        final captureDirectory = Platform.environment['TRANSLATE_CAPTURES'];
        if (captureDirectory != null) {
          final shadows = debugDisableShadows;
          debugDisableShadows = false;
          await tester.pump();
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('gen-capture')),
            );
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            await Directory(captureDirectory).create(recursive: true);
            await File(
              '$captureDirectory/translate-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          });
          debugDisableShadows = shadows;
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 1600));
        expect(container.read(translationReferencesProvider).changed, isEmpty);
        await tester.tap(find.text('撤销'));
        await tester.pumpAndSettle();
        expect(
          container
              .read(pillWorkspaceProvider(PillScopes.main))
              .document
              .instances
              .length,
          1,
        );
        await tester.tap(
          find.byKey(const Key('translation-adjustment-collapse')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('translation-adjustment-input')),
          findsNothing,
        );
        await tester.drag(
          find.byKey(const Key('translation-adjustment-drag')),
          const Offset(30, 20),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('translation-adjustment-close')));
        await tester.pumpAndSettle();
        expect(client.closed, isTrue);
        expect(container.read(translationReferencesProvider).negative, isNull);
        expect(container.exists(naiAgentControllerProvider), isFalse);
        expect(tester.takeException(), isNull);
        // A second open followed by page disposal must also close the session.
        final other = _Client();
        currentClient = other;
        await tester.tap(find.byKey(const Key('open-adjustment')));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(other.closed, isTrue);
      },
    );
  }
}
