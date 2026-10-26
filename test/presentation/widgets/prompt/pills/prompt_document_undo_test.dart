// Prompt document undo/redo regressions, promoted from R14 probes P1–P18.
import 'package:flutter/gestures.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';
import 'package:nai_launcher/presentation/utils/prompt_block_instance_bundle.dart';

class _MemorySettings extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _MemoryCharacters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _TestBlocksPlatform extends BlocksPlatform {
  @override
  Future<void> backupDraft(String snapshot) async {}
}

class _FakeGenerationParamsNotifier extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();

  @override
  void updatePromptFromPill(String prompt) {
    state = state.copyWith(prompt: prompt);
  }

  @override
  void updateNegativePromptFromPill(String prompt) {
    state = state.copyWith(negativePrompt: prompt);
  }
}

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

PromptBlock _block(String id, String title, String content) => PromptBlock(
  id: id,
  title: title,
  content: content,
  createdAt: DateTime(2026, 8, 30),
  updatedAt: DateTime(2026, 8, 30),
);

/// Ctrl/Cmd + 按键。
Future<void> _ctrlKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

/// 一次真实击键（替换式更新，光标在末尾）。
Future<void> _type(WidgetTester tester, String text) async {
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump();
}

/// 等过原生撤销栈 500ms 节流，让最近一次输入落栈。
Future<void> _flushHistory(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
}

/// 失焦（点在输入框外）：触发 UnifiedPromptInput._formatOnBlur。
Future<void> _blur(WidgetTester tester) async {
  await tester.tapAt(const Offset(1150, 760));
  await tester.pumpAndSettle();
}

TextEditingController _fieldController(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!;

/// 真实滚轮路径：Alt + 滚轮 → WeightAdjustScrollPhysics / 工具条入口。
Future<void> _wheelAdjustWeight(WidgetTester tester, Finder field) async {
  final center = tester.getCenter(field);
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: center);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendEventToBinding(
    PointerScrollEvent(position: center, scrollDelta: const Offset(0, -20)),
  );
  await tester.pump();
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pump();
}

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester, {
  bool autoFormat = false,
  bool sdAutoConvert = false,
  String? initialPlainText,
  String scope = PillScopes.main,
  List<PromptBlock> blocks = const [],
  ValueChanged<WidgetRef>? onRef,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = ProviderScope(
    overrides: [
      blocksPlatformProvider.overrideWithValue(_TestBlocksPlatform()),
      localStorageServiceProvider.overrideWithValue(_MemorySettings()),
      characterPromptNotifierProvider.overrideWith(_MemoryCharacters.new),
      promptBlockLibraryNotifierProvider.overrideWith(
        () => _FakePromptBlockLibraryNotifier(
          PromptBlockLibraryState(blocks: blocks, folders: const []),
        ),
      ),
      generationParamsNotifierProvider.overrideWith(
        _FakeGenerationParamsNotifier.new,
      ),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (_, child) => TextEditingShortcuts(child: child!),
      home: Consumer(
        builder: (context, ref, _) {
          onRef?.call(ref);
          return Scaffold(
            body: SizedBox(
              width: 720,
              height: 320,
              child: PromptPillEditor(
                pillScope: scope,
                enableBlurredUndo: true,
                initialPlainText: initialPlainText,
                config: UnifiedPromptConfig(
                  enableSyntaxHighlight: false,
                  enableAutoFormat: autoFormat,
                  enableSdSyntaxAutoConvert: sdAutoConvert,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpWidget(app);
  await tester.pump();
  final element = tester.element(find.byType(PromptPillEditor));
  return ProviderScope.containerOf(element);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scope in [
    PillScopes.main,
    PillScopes.negative,
    PillScopes.charPos('c1'),
    PillScopes.charNeg('c1'),
  ]) {
    testWidgets('blurred undo/redo routes to most recent prompt lane $scope', (
      tester,
    ) async {
      final container = await _pumpEditor(tester, scope: scope);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await _type(tester, 'first');
      await _flushHistory(tester);
      await _type(tester, 'second');
      await _blur(tester);
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      expect(
        container.read(pillWorkspaceProvider(scope)).document.text,
        'first',
      );
      await _ctrlKey(tester, LogicalKeyboardKey.keyY);
      expect(_fieldController(tester).text, 'second');
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(_fieldController(tester).text, 'second');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  for (final expands in [false, true]) {
    testWidgets(
      'standalone search/replace retains native history expands=$expands',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWithValue(_MemorySettings()),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (_, child) => TextEditingShortcuts(child: child!),
              home: Scaffold(
                body: SizedBox(
                  width: 700,
                  height: 320,
                  child: UnifiedPromptInput(
                    controller: controller,
                    expands: expands,
                    fitContent: !expands,
                    config: const UnifiedPromptConfig(
                      enableSyntaxHighlight: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField).first);
        await tester.pump();
        await _flushHistory(tester);
        await _type(tester, 'first');
        await _flushHistory(tester);
        await _type(tester, 'second');
        await _flushHistory(tester);
        final before = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        for (final key in [LogicalKeyboardKey.keyF, LogicalKeyboardKey.keyH]) {
          await _ctrlKey(tester, key);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(find.byType(EditableText)),
            same(before),
          );
        }
        await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
        expect(controller.text, 'first');
        await _ctrlKey(tester, LogicalKeyboardKey.keyY);
        expect(controller.text, 'second');
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }

  testWidgets(
    'program edits restore complete instances, each step immediately, without tombstone limits',
    (tester) async {
      final container = await _pumpEditor(tester);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      final snapshots = <PillDocument>[
        container.read(pillWorkspaceNotifierProvider).document,
      ];
      void save() =>
          snapshots.add(container.read(pillWorkspaceNotifierProvider).document);
      notifier.replaceWithPlainText('initial');
      save();
      notifier.insertTranslationAt(
        offset: 0,
        source: 'blue eyes',
        zh: 'reading',
      );
      save();
      final marker = snapshots.last.instances.keys.single;
      notifier.updateTranslation(
        marker,
        snapshots.last.instances[marker]!.translation!.copyWith(zh: 'edited'),
      );
      save();
      notifier.unwrapTranslation(marker, source: 'blue eyes');
      save();
      notifier.restoreDocument(
        const PillDocument(text: 'agent import', instances: {}),
      );
      save();
      final many = {
        for (var i = 0; i < 70; i++)
          String.fromCharCode(0xe000 + i): const PillInstance(
            blockId: 'missing',
            locked: true,
          ),
      };
      notifier.restoreDocument(
        PillDocument(text: many.keys.join(), instances: many),
      );
      save();
      notifier.replaceWithPlainText('cleared');
      save();
      for (var i = snapshots.length - 2; i >= 0; i--) {
        notifier.undo();
        expect(
          container.read(pillWorkspaceNotifierProvider).document,
          snapshots[i],
        );
      }
      for (var i = 1; i < snapshots.length; i++) {
        notifier.redo();
        expect(
          container.read(pillWorkspaceNotifierProvider).document,
          snapshots[i],
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('paired deletion is independently undoable in both lanes', (
    tester,
  ) async {
    late WidgetRef widgetRef;
    final container = await _pumpEditor(
      tester,
      onRef: (value) => widgetRef = value,
    );
    final positive = container.read(
      pillWorkspaceProvider(PillScopes.main).notifier,
    );
    final negative = container.read(
      pillWorkspaceProvider(PillScopes.negative).notifier,
    );
    const positiveDocument = PillDocument(
      text: '\uE000',
      instances: {
        '\uE000': PillInstance(blockId: 'paired', bundleId: 'bundle'),
      },
    );
    const negativeDocument = PillDocument(
      text: '\uE000',
      instances: {
        '\uE000': PillInstance(
          blockId: 'paired',
          bundleId: 'bundle',
          useNegativeContent: true,
        ),
      },
    );
    positive.restoreDocument(positiveDocument);
    negative.restoreDocument(negativeDocument);
    removePromptBlockBundle(widgetRef, PillScopes.main, '\uE000');
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      isEmpty,
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      isEmpty,
    );
    positive.undo();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document,
      positiveDocument,
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      isEmpty,
    );
    negative.undo();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document,
      negativeDocument,
    );
    positive.redo();
    negative.redo();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      isEmpty,
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'continuous typing merges, program rewrite and structural deletion split groups',
    (tester) async {
      final container = await _pumpEditor(tester);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await _type(tester, 'a');
      await _type(tester, 'ab');
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      expect(_fieldController(tester).text, '');
      await _ctrlKey(tester, LogicalKeyboardKey.keyY);
      expect(_fieldController(tester).text, 'ab');
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.replaceWithPlainText('import');
      await tester.pump();
      await _type(tester, 'import typed');
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      expect(_fieldController(tester).text, 'import');
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      expect(_fieldController(tester).text, 'ab');
      notifier.insertBlockAt(offset: 0, blockId: 'block', countUse: false);
      await tester.pump();
      final inserted = container.read(pillWorkspaceNotifierProvider).document;
      await _type(tester, 'ab');
      notifier.undo();
      expect(container.read(pillWorkspaceNotifierProvider).document, inserted);
      expect(notifier.canRedo, isTrue);
      notifier.replaceWithPlainText('branch');
      expect(notifier.canRedo, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('IME preedit is not a programmatic undo step', (tester) async {
    final container = await _pumpEditor(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await _type(tester, 'before');
    await _flushHistory(tester);
    for (final text in ['before n', 'before ni']) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
          composing: TextRange(start: 7, end: text.length),
        ),
      );
      await tester.pump();
    }
    await _type(tester, 'before 你');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    expect(_fieldController(tester).text, 'before');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(_fieldController(tester).text, 'before 你');
    expect(
      container.read(pillWorkspaceNotifierProvider).projection,
      'before 你',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('IME commit with unchanged text is recorded once', (
    tester,
  ) async {
    await _pumpEditor(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '你好',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    await _type(tester, '你好');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    expect(_fieldController(tester).text, '');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    expect(_fieldController(tester).text, '你好');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P1 基线：连续输入后 Ctrl+Z / Ctrl+Y 可回退重做', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, blue eyes');
    await _flushHistory(tester);

    final controller = _fieldController(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P1 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
    await _ctrlKey(tester, LogicalKeyboardKey.keyY);
    debugPrint('P1 after Ctrl+Y: ${controller.text}');
    expect(controller.text, '1girl, blue eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P2 失焦自动格式化（autoFormat）改写后 Ctrl+Z 应回到改写前', (tester) async {
    await _pumpEditor(tester, autoFormat: true);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl ,,  blue_eyes');
    await _flushHistory(tester);

    // 失焦 → _formatOnBlur 程序化改写文本
    await _blur(tester);
    final controller = _fieldController(tester);
    debugPrint('P2 after blur format: ${controller.text}');
    expect(controller.text, '1girl, blue_eyes');

    // 重新聚焦后撤销：期望回到格式化前的文本（至少能回到 '1girl'）
    await tester.tap(field);
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P2 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl ,,  blue_eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P3 失焦 SD 语法转换后 Ctrl+Z 应回到改写前', (tester) async {
    await _pumpEditor(tester, sdAutoConvert: true);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, (blue eyes:1.2)');
    await _flushHistory(tester);

    await _blur(tester);
    final controller = _fieldController(tester);
    debugPrint('P3 after blur SD convert: ${controller.text}');
    expect(controller.text, '1girl, 1.2::blue eyes::');

    await tester.tap(field);
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P3 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, (blue eyes:1.2)');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P4 程序化插入块（药丸）后 Ctrl+Z 应回到插入前文本', (tester) async {
    final container = await _pumpEditor(
      tester,
      blocks: [_block('style', '画风', 'artist:foo')],
    );
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl');
    await _flushHistory(tester);

    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();
    final controller = _fieldController(tester);
    debugPrint('P4 after insert: ${controller.text} (marker=U+E000)');
    expect(controller.text.length, '1girl'.length + 1);

    await tester.tap(field);
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P4 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      '1girl',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P5 权重工具栏改写（滚轮/applyWeight）后 Ctrl+Z 应回到改写前', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl, blue eyes');
    await _flushHistory(tester);

    final controller = _fieldController(tester);
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 16);
    await tester.pump();
    await _wheelAdjustWeight(tester, field);
    debugPrint('P5 after weight: ${controller.text}');
    expect(controller.text, '1girl, 1.05::blue eyes::');

    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P5 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, blue eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P6 初始化播种（initialPlainText）后输入再撤销', (tester) async {
    await _pumpEditor(tester, initialPlainText: 'seed text');
    final field = find.byType(TextField).first;
    await tester.pumpAndSettle();
    final controller = _fieldController(tester);
    debugPrint('P6 seeded: ${controller.text}');
    expect(controller.text, 'seed text');
    await _flushHistory(tester);

    await tester.tap(field);
    await tester.pump();
    await _flushHistory(tester);
    await _type(tester, 'seed text, extra');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P6 after Ctrl+Z: ${controller.text}');
    expect(controller.text, 'seed text');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P7 同一 lane 两个编辑器（卡片 + 全屏）共享文档时的撤销', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blocksPlatformProvider.overrideWithValue(_TestBlocksPlatform()),
          localStorageServiceProvider.overrideWithValue(_MemorySettings()),
          characterPromptNotifierProvider.overrideWith(_MemoryCharacters.new),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _FakePromptBlockLibraryNotifier(
              PromptBlockLibraryState(blocks: const [], folders: const []),
            ),
          ),
          generationParamsNotifierProvider.overrideWith(
            _FakeGenerationParamsNotifier.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 720,
                  height: 160,
                  child: PromptPillEditor(
                    key: ValueKey('probe-card-editor'),
                    pillScope: PillScopes.main,
                    config: UnifiedPromptConfig(enableSyntaxHighlight: false),
                  ),
                ),
                SizedBox(
                  width: 720,
                  height: 160,
                  child: PromptPillEditor(
                    key: ValueKey('probe-fullscreen-editor'),
                    pillScope: PillScopes.main,
                    config: UnifiedPromptConfig(enableSyntaxHighlight: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    // 在第二个（全屏）里输入
    await tester.tap(fields.at(1));
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);

    final full = tester.widget<TextField>(fields.at(1)).controller!;
    final card = tester.widget<TextField>(fields.at(0)).controller!;
    debugPrint('P7 card=${card.text} full=${full.text}');
    expect(card.text, '1girl, solo', reason: '隐藏的卡片编辑器应同步到同一文档');

    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P7 after Ctrl+Z full=${full.text} card=${card.text}');
    expect(full.text, '1girl');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P8 快捷清空（clear）后 Ctrl+Z 应能恢复文本', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl, blue eyes');
    await _flushHistory(tester);

    final controller = _fieldController(tester);
    // 与 UnifiedPromptInput._handleClear 相同：整体替换为空串
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P8 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, blue eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'P10 immediate block insertion then keyboard deletion are separate undo steps',
    (tester) async {
      final container = await _pumpEditor(
        tester,
        blocks: [_block('style', '画风', 'artist:foo')],
      );
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: 'style');
      await tester.pump();
      final field = find.byType(TextField).first;
      await tester.tap(field);
      await tester.pump();
      final controller = _fieldController(tester);
      expect(controller.text.length, 1);

      // 选中标记字符并删除（键盘删块 → 实例对账移除）
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      // No 500 ms wait: both structural edits must be immediately undoable.
      debugPrint(
        'P10 after delete: text="${controller.text}" instances='
        '${container.read(pillWorkspaceNotifierProvider).document.instances.length}',
      );
      expect(controller.text, isEmpty);

      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      final state = container.read(pillWorkspaceNotifierProvider);
      debugPrint(
        'P10 after Ctrl+Z: text="${controller.text}" instances='
        '${state.document.instances.length} projection=${state.projection}',
      );
      expect(controller.text.length, 1);
      expect(state.document.instances.length, 1);
      await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
      expect(_fieldController(tester).text, isEmpty);
      await _ctrlKey(tester, LogicalKeyboardKey.keyY);
      expect(
        container.read(pillWorkspaceNotifierProvider).document,
        state.document,
      );
      await _ctrlKey(tester, LogicalKeyboardKey.keyY);
      expect(_fieldController(tester).text, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('P11 同 lane 新挂全屏编辑器后，在它里面 Ctrl+Z 不应清空文档', (tester) async {
    final container = await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);

    // 模拟打开全屏编辑器：同 lane 再挂一个 PromptPillEditor（卡片保留）
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blocksPlatformProvider.overrideWithValue(_TestBlocksPlatform()),
          localStorageServiceProvider.overrideWithValue(_MemorySettings()),
          characterPromptNotifierProvider.overrideWith(_MemoryCharacters.new),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _FakePromptBlockLibraryNotifier(
              PromptBlockLibraryState(blocks: const [], folders: const []),
            ),
          ),
          generationParamsNotifierProvider.overrideWith(
            _FakeGenerationParamsNotifier.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 720,
                  height: 160,
                  child: PromptPillEditor(
                    key: ValueKey('probe-card-editor'),
                    pillScope: PillScopes.main,
                    config: UnifiedPromptConfig(enableSyntaxHighlight: false),
                  ),
                ),
                SizedBox(
                  width: 720,
                  height: 160,
                  child: PromptPillEditor(
                    key: ValueKey('probe-fullscreen-editor'),
                    pillScope: PillScopes.main,
                    initialPlainText: '1girl, solo',
                    config: UnifiedPromptConfig(enableSyntaxHighlight: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    final card = tester.widget<TextField>(fields.at(0)).controller!;
    final full = tester.widget<TextField>(fields.at(1)).controller!;
    debugPrint('P11 card=${card.text} full=${full.text}');
    expect(card.text, '1girl, solo');
    expect(full.text, '1girl, solo');

    // 新挂的全屏编辑器使用同 lane 已有历史，不另建空栈。
    await tester.tap(fields.at(1));
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P11 fullscreen Ctrl+Z: full=${full.text} card=${card.text}');
    expect(full.text, '1girl', reason: '同 lane 全屏应共享卡片已有的文档历史，不重置为空');
    expect(card.text, '1girl');
    debugPrint(
      'P11 lane text: '
      '${container.read(pillWorkspaceNotifierProvider).document.text}',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P12 清空按钮（showClearButton）后 Ctrl+Z 应恢复文本', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl, blue eyes');
    await _flushHistory(tester);
    final controller = _fieldController(tester);
    // UnifiedPromptInput._handleClear 的等价写法
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    await tester.pump();
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P12 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, blue eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P13 Agent 式文档快照覆盖（restoreDocument）后 Ctrl+Z 应回到覆盖前', (
    tester,
  ) async {
    final container = await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);

    // Agent prompt_update / 桥接写入走 restoreDocument（整体快照）
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .restoreDocument(
          const PillDocument(text: 'agent wrote this', instances: {}),
        );
    await tester.pump();
    final controller = _fieldController(tester);
    debugPrint('P13 after restoreDocument: ${controller.text}');
    expect(controller.text, 'agent wrote this');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P13 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, solo');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P14 失焦后（光标不在输入框）Ctrl+Z 是否还能撤销', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);

    // 点输入框外：常见操作（点块库/生成按钮/画布）之后的失焦状态
    await _blur(tester);
    final controller = _fieldController(tester);
    expect(
      tester.widget<TextField>(field).focusNode!.hasFocus,
      isFalse,
      reason: '已失焦',
    );
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P14 after Ctrl+Z while blurred: ${controller.text}');
    expect(controller.text, '1girl', reason: '失焦后按 Ctrl+Z 仍应能撤销');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P15 打开/关闭框内搜索（Ctrl+F）后 Ctrl+Z 是否还能撤销', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    await _type(tester, '1girl, solo');
    await _flushHistory(tester);

    await _ctrlKey(tester, LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    debugPrint(
      'P15 search visible: '
      '${find.byKey(const ValueKey('prompt_input_search_field')).evaluate().length}',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pump();

    final controller = _fieldController(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P15 after Ctrl+Z (old history): ${controller.text}');
    expect(controller.text, '1girl', reason: '搜索开关必须保留已有历史');
    // 再输入一段，检查搜索关闭后新输入也可撤销。
    await _type(tester, '1girl, solo, smile');
    await _flushHistory(tester);
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P15 after new burst + Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P16 块插入与键盘删除各自隔开 500ms 后的撤销', (tester) async {
    final container = await _pumpEditor(
      tester,
      blocks: [_block('style', '画风', 'artist:foo')],
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();
    await _flushHistory(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    final controller = _fieldController(tester);
    debugPrint('P16 after insert: "${controller.text}"');
    expect(controller.text.length, 1);

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    await _flushHistory(tester);
    debugPrint(
      'P16 after delete: "${controller.text}" instances='
      '${container.read(pillWorkspaceNotifierProvider).document.instances.length}',
    );
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    final state = container.read(pillWorkspaceNotifierProvider);
    debugPrint(
      'P16 after Ctrl+Z: "${controller.text}" instances='
      '${state.document.instances.length} projection=${state.projection}',
    );
    expect(controller.text.length, 1);
    expect(state.document.instances.length, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('P17 诊断：Ctrl+F 开关后编辑器的 state / controller 是否被重建', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();
    await _type(tester, '1girl');
    await _flushHistory(tester);
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    final controllerBefore = _fieldController(tester);

    await _ctrlKey(tester, LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    final after = tester.state<EditableTextState>(find.byType(EditableText));
    final controllerAfter = _fieldController(tester);
    debugPrint(
      'P17 editable identical=${identical(before, after)} '
      'controller identical=${identical(controllerBefore, controllerAfter)} '
      'focus=${tester.widget<TextField>(field).focusNode!.hasPrimaryFocus}',
    );
    expect(identical(before, after), isTrue, reason: '开关搜索不应重建输入框（否则撤销历史丢失）');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'P18 direct UndoTextIntent uses document history across search toggles',
    (tester) async {
      await _pumpEditor(tester);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await _type(tester, 'first');
      await _flushHistory(tester);
      await _type(tester, 'second');
      await _ctrlKey(tester, LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final ctx = FocusManager.instance.primaryFocus!.context!;
      Actions.invoke(ctx, const UndoTextIntent(SelectionChangedCause.keyboard));
      await tester.pump();
      expect(_fieldController(tester).text, 'first');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('P9 鼠标滚轮改权重（WeightAdjustScrollPhysics）后 Ctrl+Z', (tester) async {
    await _pumpEditor(tester);
    final field = find.byType(TextField).first;
    await tester.tap(field);
    await tester.pump();

    await _type(tester, '1girl, blue eyes');
    await _flushHistory(tester);

    final controller = _fieldController(tester);
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 16);
    await tester.pump();
    await _wheelAdjustWeight(tester, field);
    debugPrint('P9 after wheel: ${controller.text}');
    await _ctrlKey(tester, LogicalKeyboardKey.keyZ);
    debugPrint('P9 after Ctrl+Z: ${controller.text}');
    expect(controller.text, '1girl, blue eyes');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
