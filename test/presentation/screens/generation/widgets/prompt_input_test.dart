import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_state_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/widgets/prompt_assistant_overlay.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';
import 'package:nai_launcher/presentation/widgets/common/weight_adjust_toolbar.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';

void main() {
  test('Windows 下提示词切换按钮不使用富文本 Tooltip', () {
    expect(usesRichPromptTypeTooltip(TargetPlatform.windows), isFalse);
    expect(usesRichPromptTypeTooltip(TargetPlatform.macOS), isTrue);
  });

  testWidgets('冷启动时切换到负面提示词不会抛出异常', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith((ref) {
            return _TestLocalStorageService();
          }),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 顶栏瘦容后负面切换为纯文字「UC」按钮
    await tester.tap(find.text('UC').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey('generation_prompt_negative_input')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('负向药丸 lane：插入块投影进参数，外部写入同步进编辑器', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _EmptyPromptBlockLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [
                  PromptBlock(
                    id: 'uc-block',
                    title: 'UC包',
                    content: 'lowres, bad anatomy',
                    color: '#FF123456',
                    createdAt: DateTime.utc(2026, 8, 30),
                    updatedAt: DateTime.utc(2026, 8, 30),
                  ),
                ],
                folders: const [],
              ),
            ),
          ),
          localStorageServiceProvider.overrideWith((ref) {
            return _TestLocalStorageService();
          }),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );

    // 切到 UC：负向药丸编辑器挂载
    await tester.tap(find.text('UC').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey('generation_prompt_negative_input')),
      findsOneWidget,
    );

    // 负向 lane 插块 → 投影写回生成参数
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .insertBlockAt(offset: 0, blockId: 'uc-block');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('UC包'), findsOneWidget);
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'lowres, bad anatomy',
    );

    // 外部写入（桥接/画廊发送汇点）→ 负向 lane 同步重建
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePrompt('external uc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      'external uc',
    );
    expect(find.byType(PromptPill), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ctrl+F 搜索选中命中且编辑提示词不重置光标', (tester) async {
    const prompt = 'alpha, beta, Alpha';
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith((ref) {
              return _TestLocalStorageService();
            }),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          ],
          child: const MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 960,
                height: 420,
                child: PromptInputWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final promptField = find
          .descendant(
            of: find.byKey(const ValueKey('generation_prompt_positive_input')),
            matching: find.byType(TextField),
          )
          .first;

      await tester.tap(promptField);
      await tester.enterText(promptField, prompt);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final searchField = find.byKey(
        const ValueKey('prompt_input_search_field'),
      );
      expect(searchField, findsOneWidget);
      final promptTextField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == prompt,
      );
      expect(promptTextField, findsOneWidget);
      expect(
        tester.getBottomLeft(searchField).dy,
        lessThanOrEqualTo(tester.getTopLeft(promptTextField).dy),
      );

      await tester.enterText(searchField, 'alpha');
      await tester.pump();

      expect(find.text('1 / 2'), findsOneWidget);

      final promptEditable = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .singleWhere((editable) => editable.controller.text == prompt);
      expect(
        promptEditable.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      final promptController = promptEditable.controller;
      final activePromptField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            identical(widget.controller, promptController),
      );
      await tester.tap(activePromptField);
      await tester.pump();

      const editedPrompt = '$prompt!';
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: editedPrompt,
          selection: TextSelection.collapsed(offset: editedPrompt.length),
        ),
      );
      await tester.pump();

      expect(promptController.text, editedPrompt);
      expect(
        promptController.selection,
        const TextSelection.collapsed(offset: editedPrompt.length),
      );
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Ctrl+H 展开替换栏并支持替换当前与全部替换', (tester) async {
    const prompt = 'alpha, beta, Alpha';
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith((ref) {
              return _TestLocalStorageService();
            }),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          ],
          child: const MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 960,
                height: 420,
                child: PromptInputWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final promptField = find
          .descendant(
            of: find.byKey(const ValueKey('generation_prompt_positive_input')),
            matching: find.byType(TextField),
          )
          .first;

      await tester.tap(promptField);
      await tester.enterText(promptField, prompt);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final searchField = find.byKey(
        const ValueKey('prompt_input_search_field'),
      );
      final replaceField = find.byKey(
        const ValueKey('prompt_input_replace_field'),
      );
      expect(searchField, findsOneWidget);
      expect(replaceField, findsOneWidget);

      await tester.enterText(searchField, 'alpha');
      await tester.pump();
      await tester.enterText(replaceField, 'omega');
      await tester.pump();

      // 大小写不敏感搜索：alpha 与 Alpha 都应命中。
      expect(find.text('1 / 2'), findsOneWidget);

      final promptController = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .singleWhere((editable) => editable.controller.text == prompt)
          .controller;

      // 替换当前命中后应跳到后一处命中。
      await tester.tap(
        find.byKey(const ValueKey('prompt_input_replace_current')),
      );
      await tester.pump();
      expect(promptController.text, 'omega, beta, Alpha');
      expect(
        promptController.selection,
        const TextSelection(baseOffset: 13, extentOffset: 18),
      );

      // 全部替换应把剩余命中一次改完。
      await tester.tap(find.byKey(const ValueKey('prompt_input_replace_all')));
      await tester.pump();
      expect(promptController.text, 'omega, beta, omega');

      // 替换栏可折叠。
      await tester.tap(
        find.byKey(const ValueKey('prompt_input_replace_toggle')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('prompt_input_replace_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('prompt_input_search_field')),
        findsOneWidget,
      );

      // 全部替换的 toast 有 3 秒延迟 + 退场动画，需要等它彻底移除；
      // 输入框光标闪烁是周期定时器，这里不能用 pumpAndSettle。
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shared prompt input reads the disabled wheel setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(enablePromptWeightScroll: false),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();

    final wrapper = tester.widget<WeightAdjustToolbarWrapper>(
      find.byType(WeightAdjustToolbarWrapper).first,
    );
    final input = tester.widget<ThemedInput>(find.byType(ThemedInput).first);

    expect(wrapper.enableWheelAdjustment, isFalse);
    expect(input.scrollPhysics, isNull);
  });

  testWidgets('expanded prompt assistant does not cover editable prompt text', (
    tester,
  ) async {
    const sessionId = 'assistant_clearance_test';
    final controller = TextEditingController(
      text: List.filled(12, 'long prompt tag').join(', '),
    );
    addTearDown(controller.dispose);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith(
              (ref) => _TestLocalStorageService(),
            ),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 720,
                height: 72,
                child: UnifiedPromptInput(
                  controller: controller,
                  sessionId: sessionId,
                  config: const UnifiedPromptConfig(
                    enableAutocomplete: false,
                    enableSyntaxHighlight: false,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(UnifiedPromptInput)),
      );
      container
          .read(promptAssistantStateProvider.notifier)
          .setExpanded(sessionId, true);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final padding = textField.decoration!.contentPadding!.resolve(
        TextDirection.ltr,
      );
      final toolbar = find.byKey(
        const ValueKey<String>('prompt_assistant_toolbar_$sessionId'),
      );
      final editableRect = tester.getRect(find.byType(EditableText));
      final toolbarRect = tester.getRect(toolbar);

      expect(padding.bottom, PromptAssistantOverlay.contentBottomClearance);
      expect(toolbar, findsOneWidget);
      expect(editableRect.height, greaterThanOrEqualTo(18));
      expect(editableRect.bottom, lessThanOrEqualTo(toolbarRect.top));
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('外部 provider 写入后编辑器同步显示新文本（协调器不依赖组件兜底）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );

    // 模拟 Krita / 元数据导入 / 反推等外部路径：只写生成参数 provider。
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('external import, from bridge');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('external import, from bridge'), findsOneWidget);
    final pillWorkspace = container.read(pillWorkspaceNotifierProvider);
    expect(pillWorkspace.document.text, 'external import, from bridge');
    expect(pillWorkspace.projection, 'external import, from bridge');
    expect(tester.takeException(), isNull);
  });

  testWidgets('带块文档被外部整串写入后压扁为纯文本', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _EmptyPromptBlockLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [
                  PromptBlock(
                    id: 'source-block-ui',
                    title: '画师组合',
                    content: 'artist:xyz',
                    color: '#FF123456',
                    createdAt: DateTime.utc(2026, 8, 30),
                    updatedAt: DateTime.utc(2026, 8, 30),
                  ),
                ],
                folders: const [],
              ),
            ),
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );
    final pillNotifier = container.read(pillWorkspaceNotifierProvider.notifier);
    pillNotifier.replaceWithPlainText('1girl, ');
    pillNotifier.insertBlockAt(offset: 7, blockId: 'source-block-ui');
    await tester.pump();
    // 药丸编辑器：块渲染为内联药丸而非旧整行卡片
    expect(find.byType(PromptPill), findsOneWidget);
    expect(find.text('画师组合'), findsOneWidget);

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('flattened replacement');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PromptPill), findsNothing);
    expect(find.text('flattened replacement'), findsOneWidget);
    final pillState = container.read(pillWorkspaceNotifierProvider);
    expect(pillState.document.text, 'flattened replacement');
    expect(pillState.document.instances, isEmpty);
    expect(pillState.projection, 'flattened replacement');
    expect(tester.takeException(), isNull);
  });
}

class _TestLocalStorageService extends LocalStorageService {
  _TestLocalStorageService({this.enablePromptWeightScroll = true});

  final bool enablePromptWeightScroll;

  @override
  bool getEnablePromptWeightScroll() => enablePromptWeightScroll;

  @override
  bool getEnableAutocomplete() => false;

  @override
  bool getAutoFormatPrompt() => false;

  @override
  bool getHighlightEmphasis() => false;

  @override
  bool getSdSyntaxAutoConvert() => false;

  @override
  bool getEnableCooccurrenceRecommendation() => false;

  @override
  String getLastPrompt() => '';

  @override
  Future<void> setLastPrompt(String prompt) async {}

  @override
  String getLastNegativePrompt() => '';

  @override
  Future<void> setLastNegativePrompt(String prompt) async {}

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';

  @override
  bool getSeedLocked() => false;

  @override
  int? getLockedSeedValue() => null;
}

class _TestCharacterPromptNotifier extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

/// 药丸编辑器（正向主提示词）依赖块库；无 Hive 的测试环境用空库替代。
class _EmptyPromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _EmptyPromptBlockLibraryNotifier([this.initial]);

  final PromptBlockLibraryState? initial;

  @override
  Future<PromptBlockLibraryState> build() async =>
      initial ?? PromptBlockLibraryState(blocks: [], folders: []);
}
