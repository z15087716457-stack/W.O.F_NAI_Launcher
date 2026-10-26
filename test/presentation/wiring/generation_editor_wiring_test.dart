import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_prompt.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:nai_launcher/presentation/wiring/generation_editor_wiring.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;
import '../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late StreamController<int> epochs;
  final boundary = GlobalKey();
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-editor-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    epochs = StreamController<int>.broadcast();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        tipDeckProvider.overrideWithValue(TipDeck(seed: 19)),
        tipEpochProvider.overrideWith((ref) async* {
          yield 0;
          yield* epochs.stream;
        }),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('positive original');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePromptImmediately('negative original');
  });
  tearDown(() async {
    container.dispose();
    await epochs.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(
    WidgetTester tester,
    GenEditorTarget target, {
    String? characterId,
    bool page = false,
    bool promptOnly = false,
    bool explore = false,
    double width = 420,
    double scale = 1,
    Locale locale = const Locale('zh'),
    bool dark = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1100);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(scale),
            ),
            child: TextEditingShortcuts(child: child!),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              body: promptOnly
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width - 24,
                        child: GenHost(
                          data: GenFixture.empty(),
                          actions: GenActions.logging((_) {}),
                          slots: GenSlots(
                            editor: (_, value) => GenerationEditorWiring(
                              target: value,
                              explore: explore,
                            ),
                          ),
                          child: const SingleChildScrollView(
                            child: GenPromptModule(),
                          ),
                        ),
                      ),
                    )
                  : page
                  ? GenerationPage(
                      data: GenFixture.empty().copyWith(
                        layout: GenLayout(leftWidth: width),
                      ),
                      actions: GenActions.logging((_) {}),
                      slots: GenSlots(
                        editor: (_, value) => GenerationEditorWiring(
                          target: value,
                          explore: explore,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: width,
                      height: 400,
                      child: GenerationEditorWiring(
                        target: target,
                        characterId: characterId,
                        explore: explore,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder mainEditor() => find.byWidgetPredicate(
    (widget) =>
        widget is PromptPillEditor && widget.pillScope == PillScopes.main,
  );

  for (final target in [
    const GenEditorTarget.base(),
    const GenEditorTarget.base(negative: true),
    const GenEditorTarget.character(0),
    const GenEditorTarget.character(0, negative: true),
    const GenEditorTarget.base(fullscreen: true),
  ]) {
    testWidgets('R14 wired editor $target supports blurred undo/redo', (
      tester,
    ) async {
      await pump(tester, target, characterId: target.isBase ? null : 'kept');
      final field = find.byType(TextField).first;
      final editor = tester.widget<PromptPillEditor>(
        find.byType(PromptPillEditor),
      );
      expect(editor.enableBlurredUndo, isTrue);
      final scope = editor.pillScope;
      await tester.enterText(field, 'first');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.enterText(field, 'second');
      await tester.pump();
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        await tester.pump();
      }

      String projected() {
        final params = container.read(generationParamsNotifierProvider);
        if (target.isBase) {
          return target.negative ? params.negativePrompt : params.prompt;
        }
        final role = container
            .read(characterPromptNotifierProvider)
            .findCharacterById('kept')!;
        return target.negative ? role.negativePrompt : role.prompt;
      }

      await key(LogicalKeyboardKey.keyZ);
      expect(
        container.read(pillWorkspaceProvider(scope)).document.text,
        'first',
      );
      expect(projected(), 'first');
      await key(LogicalKeyboardKey.keyY);
      expect(
        container.read(pillWorkspaceProvider(scope)).document.text,
        'second',
      );
      expect(projected(), 'second');
      await tester.pumpWidget(const SizedBox());
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets('F13 主提示 TIP 随轮次切换，输入内容与文档保持', (tester) async {
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('');
    await pump(tester, const GenEditorTarget.base(), page: true);
    await tester.pumpAndSettle();
    final editor = tester.widget<PromptPillEditor>(mainEditor());
    final first = editor.config.hintText;
    expect(first, isNotEmpty);
    expect(
      tipsFor(TipSurface.prompt).any(
        (tip) => tip.hint(lookupAppLocalizations(const Locale('zh'))) == first,
      ),
      isTrue,
    );
    expect(find.text(first!), findsOneWidget);
    final height = tester.getSize(find.byKey(const Key('gen-prompt'))).height;
    final document = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    epochs.add(1);
    await tester.pumpAndSettle();
    final next = tester.widget<PromptPillEditor>(mainEditor()).config.hintText;
    expect(next, isNot(first));
    expect(tester.getSize(find.byKey(const Key('gen-prompt'))).height, height);
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document,
      same(document),
    );
    expect(container.read(generationParamsNotifierProvider).prompt, isEmpty);
    await tester.enterText(
      find.descendant(of: mainEditor(), matching: find.byType(EditableText)),
      'new prompt',
    );
    await tester.pumpAndSettle();
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new prompt',
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(
                  of: find.text(next!),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity,
      0,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('F13 负面保留主框最低高度，角色与全屏不扩大', (tester) async {
    await pump(tester, const GenEditorTarget.base());
    final positiveLines = tester
        .widget<PromptPillEditor>(find.byType(PromptPillEditor))
        .minLines!;
    expect(positiveLines, greaterThanOrEqualTo(4));
    await pump(tester, const GenEditorTarget.base(negative: true));
    final negative = tester.widget<PromptPillEditor>(
      find.byType(PromptPillEditor),
    );
    expect(negative.minLines, positiveLines);
    expect(negative.config.hintText, isNull);
    await pump(tester, const GenEditorTarget.character(0));
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).minLines,
      1,
    );
    await pump(tester, const GenEditorTarget.base(fullscreen: true));
    // 全屏按可用高度撑满（至少 8 行），点空白处也能落光标。
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).minLines,
      greaterThan(8),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('F13 探索主框保留独立 TIP 池并恢复最低高度', (tester) async {
    await pump(tester, const GenEditorTarget.base(), explore: true);
    final editor = tester.widget<PromptPillEditor>(
      find.byType(PromptPillEditor),
    );
    expect(editor.minLines, greaterThanOrEqualTo(4));
    expect(editor.allowEvolutionToggle, isTrue);
    expect(
      tipsFor(TipSurface.explorePrompt).any(
        (tip) =>
            tip.hint(lookupAppLocalizations(const Locale('zh'))) ==
            editor.config.hintText,
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('F13 改宽与正文增长保留光标和同一份文档', (tester) async {
    await pump(tester, const GenEditorTarget.base(), width: 352);
    final narrow = tester.widget<PromptPillEditor>(mainEditor()).minLines!;
    final field = find.byType(EditableText);
    await tester.enterText(field, 'kept prompt');
    await tester.pumpAndSettle();
    tester.widget<EditableText>(field).controller.selection =
        const TextSelection.collapsed(offset: 4);
    final document = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    await pump(tester, const GenEditorTarget.base(), width: 560);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PromptPillEditor>(mainEditor()).minLines!,
      greaterThan(narrow),
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document,
      same(document),
    );
    expect(
      tester.widget<EditableText>(field).controller.selection.baseOffset,
      4,
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'kept prompt',
    );
    // 在真实卡片中继续按内容增高，清空后回到最低高度。
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('');
    await tester.pumpWidget(const SizedBox());
    await pump(tester, const GenEditorTarget.base(), page: true);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('gen-prompt'));
    final minimum = tester.getSize(card).height;
    await tester.enterText(
      find.descendant(of: mainEditor(), matching: field),
      List.filled(30, 'line').join('\n'),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, greaterThan(minimum));
    await tester.enterText(
      find.descendant(of: mainEditor(), matching: field),
      '',
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, minimum);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final size in [
        (352.0, 1.0),
        (420.0, 1.0),
        (560.0, 1.0),
        (352.0, 1.4),
      ]) {
        final (width, scale) = size;
        testWidgets('F13 最低高度 ${locale.toLanguageTag()} $width $scale $dark', (
          tester,
        ) async {
          container
              .read(generationParamsNotifierProvider.notifier)
              .updatePromptImmediately('');
          await pump(
            tester,
            const GenEditorTarget.base(),
            page: true,
            promptOnly: scale > 1,
            width: width,
            scale: scale,
            locale: locale,
            dark: dark,
          );
          await tester.pumpAndSettle();
          final card = tester.getSize(find.byKey(const Key('gen-prompt')));
          expect(card.height / card.width, inInclusiveRange(.65, .85));
          final field = tester.widget<PromptPillEditor>(mainEditor());
          expect(field.minLines, inInclusiveRange(4, 16));
          expect(field.config.hintText, isNotEmpty);
          expect(find.text(field.config.hintText!), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_PROMPT_HEIGHT_TIP'] == '1' &&
              (width == 420 || scale > 1)) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final path = File(
                '.dart_tool/prompt-height-tip-20261015/captures/${locale.toLanguageTag()}-$width-$scale-${dark ? 'dark' : 'light'}.png',
              );
              await path.parent.create(recursive: true);
              await path.writeAsBytes(png.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets('基础编辑槽只有药丸编辑区，输入同步正面参数且负面保持', (tester) async {
    await pump(tester, const GenEditorTarget.base());
    final editor = tester.widget<PromptPillEditor>(
      find.byType(PromptPillEditor),
    );
    expect(editor.config.showClearButton, isFalse);
    expect(editor.decoration!.contentPadding, EdgeInsets.zero);
    await tester.enterText(find.byType(EditableText), 'positive new');
    await tester.pump();
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'positive new',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'negative original',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('负面槽绑定独立 lane，不覆盖正面', (tester) async {
    await pump(tester, const GenEditorTarget.base(negative: true));
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).pillScope,
      PillScopes.negative,
    );
    await tester.enterText(find.byType(EditableText), 'negative new');
    await tester.pump();
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'negative new',
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'positive original',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('角色槽按 ID 绑定，重排后仍修改原角色的指定一面', (tester) async {
    await pump(
      tester,
      const GenEditorTarget.character(0, negative: true),
      characterId: 'kept',
    );
    final notifier = container.read(characterPromptNotifierProvider.notifier);
    notifier.addCharacter(CharacterGender.male);
    notifier.moveCharacterDown(0);
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'role negative new');
    await tester.pump();
    await tester.pump();
    final role = container
        .read(characterPromptNotifierProvider)
        .findCharacterById('kept')!;
    expect(role.negativePrompt, 'role negative new');
    expect(role.prompt, 'raw character');
    expect(role.name, 'My character');
    expect(tester.takeException(), isNull);
  });
  testWidgets('全屏编辑复用同一份文档，未找到角色不画占位编辑器', (tester) async {
    await pump(tester, const GenEditorTarget.base(fullscreen: true));
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).pillScope,
      PillScopes.main,
    );
    expect(find.byType(SingleChildScrollView), findsWidgets);
    await pump(
      tester,
      const GenEditorTarget.character(0),
      characterId: 'removed',
    );
    expect(find.byType(PromptPillEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
