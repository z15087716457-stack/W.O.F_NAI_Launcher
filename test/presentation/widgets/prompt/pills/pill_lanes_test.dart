import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

/// P3：药丸机制多 lane 化（负向框/角色框）的专项测试。
void main() {
  const markerA = '\uE000';

  test('family scopes isolate documents and instances', () async {
    final container = ProviderContainer(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block('style', '画风1', 'CONTENT')],
              folders: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // 等库就绪（投影 resolver 实时读库）
    await container.read(promptBlockLibraryNotifierProvider.future);

    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .setText('main text');
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .setText('neg text');

    final mainState = container.read(pillWorkspaceProvider(PillScopes.main));
    final negState = container.read(pillWorkspaceProvider(PillScopes.negative));
    expect(mainState.document.text, '${markerA}main text');
    expect(mainState.projection, 'CONTENTmain text');
    expect(negState.document.text, 'neg text');
    expect(negState.document.instances, isEmpty);
    expect(negState.projection, 'neg text');

    // main 的启停不影响 negative（同 marker 字符不同 lane）
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .toggleEnabled(markerA);
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances[markerA]
          ?.enabled,
      isFalse,
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      'neg text',
    );
  });

  testWidgets('editor with custom scope renders and projects independently', (
    tester,
  ) async {
    final emissions = <String>[];
    final container = await _pumpEditor(
      tester,
      scope: PillScopes.negative,
      onChanged: emissions.add,
    );

    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();

    expect(find.text('画风1'), findsOneWidget);
    expect(emissions, contains('CONTENT'));
    // main lane 未被波及
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      isEmpty,
    );
  });

  testWidgets('changing pillScope rebinds the document', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final scopeNotifier = ValueNotifier<String>('lane-a');
    addTearDown(scopeNotifier.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _FakeLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [_block('style', '画风1', 'CONTENT')],
                folders: const [],
              ),
            ),
          ),
        ],
        child: ValueListenableBuilder<String>(
          valueListenable: scopeNotifier,
          builder: (_, scope, __) =>
              _editorAppBody(scope: scope, onChanged: null),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    container.read(pillWorkspaceProvider('lane-a').notifier).setText('text of A');
    container.read(pillWorkspaceProvider('lane-b').notifier).setText('text of B');
    await tester.pump();
    expect(find.text('text of A'), findsOneWidget);

    scopeNotifier.value = 'lane-b';
    await tester.pump();
    await tester.pump();

    expect(find.text('text of B'), findsOneWidget);
    expect(find.text('text of A'), findsNothing);
  });

  testWidgets('caret updates the active editor target for panel routing', (
    tester,
  ) async {
    final container = await _pumpEditor(
      tester,
      scope: PillScopes.negative,
      onChanged: null,
    );
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .setText('hello');
    await tester.pump();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.pump();

    final target = container.read(pillActiveEditorTargetProvider);
    expect(target?.scope, PillScopes.negative);
    expect(target?.caret, isNotNull);
  });

  group('character lanes', () {
    testWidgets('seeds existing text, inserts block, writes projection back', (
      tester,
    ) async {
      const character = CharacterPrompt(
        id: 'c1',
        name: 'C1',
        prompt: '1girl, standing',
        negativePrompt: 'bad hands',
      );
      final container = await _pumpCharacterEditor(tester, character);

      // 播种：pill lane 用角色存量文本重建
      await tester.pump();
      final posDoc = container
          .read(pillWorkspaceProvider(PillScopes.charPos('c1')))
          .document;
      expect(posDoc.text, '1girl, standing');

      // 插入块 → 投影写回 updateCharacter
      container
          .read(pillWorkspaceProvider(PillScopes.charPos('c1')).notifier)
          .insertBlockAt(offset: posDoc.text.length, blockId: 'style');
      await tester.pump();
      await tester.pump();

      final updated = container
          .read(characterPromptNotifierProvider)
          .characters
          .single;
      expect(updated.prompt, '1girl, standingCONTENT');
      // 文档层仍是标记字符，未被压扁
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charPos('c1')))
            .document
            .text,
        '1girl, standing$markerA',
      );
      expect(find.text('画风1'), findsOneWidget);
    });

    testWidgets('external updateCharacter rebuilds the pill document', (
      tester,
    ) async {
      const character = CharacterPrompt(id: 'c1', name: 'C1', prompt: 'old');
      final container = await _pumpCharacterEditor(tester, character);
      await tester.pump();

      container
          .read(characterPromptNotifierProvider.notifier)
          .updateCharacter(character.copyWith(prompt: 'external write'));
      await tester.pump();
      await tester.pump();

      final doc = container
          .read(pillWorkspaceProvider(PillScopes.charPos('c1')))
          .document;
      expect(doc.text, 'external write');
      expect(find.text('external write'), findsOneWidget);
    });

    testWidgets('negative tab edits write to negativePrompt', (tester) async {
      const character = CharacterPrompt(id: 'c1', name: 'C1');
      final container = await _pumpCharacterEditor(tester, character);
      await tester.pump();

      // 切到负向 tab 并插入块
      await tester.tap(find.text('负向提示词'));
      await tester.pump();
      await tester.pump();
      container
          .read(pillWorkspaceProvider(PillScopes.charNeg('c1')).notifier)
          .insertBlockAt(offset: 0, blockId: 'style');
      await tester.pump();
      await tester.pump();

      final updated = container
          .read(characterPromptNotifierProvider)
          .characters
          .single;
      expect(updated.negativePrompt, 'CONTENT');
      expect(updated.prompt, isEmpty);
    });

    testWidgets('removing a character deletes its pill lane archives', (
      tester,
    ) async {
      const character = CharacterPrompt(id: 'c1', name: 'C1', prompt: 'x');
      final container = await _pumpCharacterEditor(tester, character);
      await tester.pump();

      // 无 Hive 的测试环境下 deleteScope 安全跳过，这里验证调用链不炸
      container
          .read(characterPromptNotifierProvider.notifier)
          .removeCharacter('c1');
      await tester.pump();
      expect(
        container.read(characterPromptNotifierProvider).characters,
        isEmpty,
      );
    });
  });
}

// ==================== 测试搭建 ====================

Future<ProviderContainer> _pumpEditor(
  WidgetTester tester, {
  required String scope,
  ValueChanged<String>? onChanged,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block('style', '画风1', 'CONTENT')],
              folders: const [],
            ),
          ),
        ),
      ],
      child: _editorAppBody(scope: scope, onChanged: onChanged),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Widget _editorAppBody({required String scope, ValueChanged<String>? onChanged}) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 960,
        height: 360,
        child: PromptPillEditor(
          pillScope: scope,
          config: const UnifiedPromptConfig(
            enableAutocomplete: false,
            enableSyntaxHighlight: false,
            enableAutoFormat: false,
            enableRegexReplace: false,
          ),
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

Future<ProviderContainer> _pumpCharacterEditor(
  WidgetTester tester,
  CharacterPrompt character,
) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block('style', '画风1', 'CONTENT')],
              folders: const [],
            ),
          ),
        ),
        characterPromptNotifierProvider.overrideWith(
          () => _FakeCharacterPromptNotifier(
            CharacterPromptConfig(characters: [character]),
          ),
        ),
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 500,
            // 与真实应用一致：父组件 watch provider，角色变更随 widget 下发
            child: Consumer(
              builder: (context, ref, _) {
                final current = ref
                    .watch(characterPromptNotifierProvider)
                    .characters
                    .where((c) => c.id == character.id)
                    .firstOrNull;
                if (current == null) {
                  return const SizedBox.shrink();
                }
                return SingleChildScrollView(
                  child: CharacterPromptEditor(
                    character: current,
                    compact: true,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

/// 绕开仓库持久化的角色 notifier（Hive 不在测试环境打开）。
class _FakeCharacterPromptNotifier extends CharacterPromptNotifier {
  _FakeCharacterPromptNotifier(this._initial);

  final CharacterPromptConfig _initial;

  @override
  CharacterPromptConfig build() => _initial;

  @override
  void updateCharacter(CharacterPrompt character) {
    state = state.updateCharacter(character);
  }

  @override
  void removeCharacter(String id) {
    state = state.removeCharacter(id);
  }
}

class _TestLocalStorageService extends LocalStorageService {
  @override
  bool getEnablePromptWeightScroll() => true;

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
}

PromptBlock _block(String id, String title, String content) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime(2026, 8, 30),
    updatedAt: DateTime(2026, 8, 30),
  );
}
