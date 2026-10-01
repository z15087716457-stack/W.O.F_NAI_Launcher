import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/core/utils/prompt_translation_edit.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_editor.dart';

import '../../../../helpers/studio_capture_fonts.dart';

const sourceKey = Key('translation-pill-source-field');
const zhKey = Key('translation-pill-zh-field');
const upKey = Key('translation-pill-to-source');
const downKey = Key('translation-pill-to-chinese');
const saveKey = Key('translation-pill-save');
const badgeKey = Key('translation-pill-modified');
final _boundary = GlobalKey();

String fieldText(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;
Future<void> settleConversion(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<TranslationPillEditHandle> openEditor(
  WidgetTester tester, {
  TranslationPill initial = const TranslationPill(
    source: 'blue eyes, smile',
    zh: '蓝眼睛，微笑',
  ),
  PromptDraftConverter? converter,
  ValueChanged<String>? cancel,
  bool Function()? configured,
  Future<void> Function()? onConfigure,
  bool enableTags = false,
}) async {
  late TranslationPillEditHandle handle;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localTagExpansionServiceProvider.overrideWithValue(_tagService()),
        tagWikiRepositoryProvider.overrideWithValue(_Wiki()),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.getTheme(
          AppStyle.geist,
          Platform.environment['STUDIO_APPEARANCE'] == 'dark'
              ? Brightness.dark
              : Brightness.light,
        ),
        builder: (_, child) => RepaintBoundary(key: _boundary, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => handle = showTranslationPillEditor(
                context: context,
                initial: initial,
                globalPosition: const Offset(180, 120),
                converter: converter,
                cancelConversion: cancel,
                isModelConfigured: configured,
                onConfigure: onConfigure,
                enableTagExpansion: enableTags,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return handle;
}

void main() {
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
    await Hive.openBox(StorageKeys.historyBox, bytes: Uint8List(0));
  });
  tearDown(() async => Hive.close());
  setUpAll(() async {
    if (Platform.environment['CAPTURE_TRANSLATION_EDITOR'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('up changes draft only; save commits the confirmed pair', (
    tester,
  ) async {
    final requests = <PromptTranslationEditRequest>[];
    final handle = await openEditor(
      tester,
      converter: (request, _) async {
        requests.add(request);
        return const PromptTranslationEditResult('green eyes, smile');
      },
    );
    var completed = false;
    handle.result.then((_) => completed = true);
    await tester.enterText(find.byKey(zhKey), '绿眼睛，微笑');
    await tester.tap(find.byKey(upKey));
    await settleConversion(tester);
    expect(fieldText(tester, sourceKey), 'green eyes, smile');
    expect(fieldText(tester, zhKey), '绿眼睛，微笑');
    expect(completed, isFalse);
    expect(requests.single.baselineSource, 'blue eyes, smile');
    expect(requests.single.zh, '绿眼睛，微笑');
    expect(find.byKey(badgeKey), findsNothing);
    await tester.tap(find.byKey(saveKey));
    await tester.pump();
    final saved = await handle.result as TranslationPill;
    expect(saved.source, 'green eyes, smile');
    expect(saved.needsReview, isFalse);
    expect(saved.showOriginal, isTrue);
  });

  testWidgets(
    'manual source badge clears after conversion; Chinese polish does not trigger it',
    (tester) async {
      final handle = await openEditor(
        tester,
        converter: (_, __) async => const PromptTranslationEditResult('绿眼睛，微笑'),
      );
      await tester.enterText(find.byKey(zhKey), '蓝眼睛，露出微笑');
      expect(find.byKey(badgeKey), findsNothing);
      await tester.enterText(find.byKey(sourceKey), 'green eyes, smile');
      await tester.pump();
      expect(find.byKey(badgeKey), findsOneWidget);
      await tester.tap(find.byKey(downKey));
      await settleConversion(tester);
      expect(fieldText(tester, zhKey), '绿眼睛，微笑');
      expect(find.byKey(badgeKey), findsNothing);
      await tester.enterText(find.byKey(sourceKey), 'green eyes, long hair');
      await tester.pump();
      expect(find.byKey(badgeKey), findsOneWidget);
      await tester.enterText(find.byKey(zhKey), '手工润色');
      await tester.pump();
      expect(find.byKey(badgeKey), findsOneWidget);
      await tester.tap(find.byKey(saveKey));
      await tester.pump();
      expect((await handle.result as TranslationPill).needsReview, isTrue);
    },
  );

  testWidgets('initial modified capsule renders and survives Chinese-only save', (
    tester,
  ) async {
    final handle = await openEditor(
      tester,
      initial: const TranslationPill(
        source: '1.4::blue eyes::, {long hair}, artist:asteroid_ill',
        zh: '1.4::蓝眼睛::，{长发}，画师：asteroid ill',
        needsReview: true,
      ),
      converter: (_, __) async => const PromptTranslationEditResult('unused'),
    );
    expect(find.byKey(badgeKey), findsOneWidget);
    if (Platform.environment['CAPTURE_TRANSLATION_EDITOR'] == '1') {
      debugDisableShadows = false;
      for (final render
          in tester.allRenderObjects.whereType<RenderPhysicalShape>()) {
        render.markNeedsPaint();
      }
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            _boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('.dart_tool/bidirectional-captures')
          ..createSync(recursive: true);
        File(
          '${folder.path}/editor-${Platform.environment['STUDIO_APPEARANCE'] ?? 'light'}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      debugDisableShadows = true;
    }
    await tester.enterText(find.byKey(zhKey), '润色后的中文');
    await tester.tap(find.byKey(saveKey));
    await tester.pump();
    expect((await handle.result as TranslationPill).needsReview, isTrue);
  });

  for (final key in [sourceKey, zhKey]) {
    testWidgets('editing $key during a request preserves the newer draft', (
      tester,
    ) async {
      final response = Completer<PromptTranslationEditResult>();
      final handle = await openEditor(
        tester,
        converter: (_, __) => response.future,
      );
      await tester.tap(find.byKey(upKey));
      await tester.pump();
      expect(tester.widget<IconButton>(find.byKey(upKey)).onPressed, isNull);
      expect(tester.widget<IconButton>(find.byKey(downKey)).onPressed, isNull);
      expect(
        tester.widget<FilledButton>(find.byKey(saveKey)).onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(key), 'new draft');
      response.complete(const PromptTranslationEditResult('obsolete'));
      await settleConversion(tester);
      expect(fieldText(tester, key), 'new draft');
      expect(find.textContaining('内容已修改'), findsOneWidget);
      handle.dismiss();
      await tester.pump();
      expect(await handle.result, isNull);
    });
  }

  testWidgets(
    'selection changes keep response valid; repeated conversions use the latest pair',
    (tester) async {
      final response = Completer<PromptTranslationEditResult>();
      final requests = <PromptTranslationEditRequest>[];
      final handle = await openEditor(
        tester,
        converter: (request, _) {
          requests.add(request);
          return requests.length == 1
              ? response.future
              : Future.value(
                  const PromptTranslationEditResult('green eyes, long hair'),
                );
        },
      );
      await tester.enterText(find.byKey(zhKey), '绿眼睛，微笑');
      await tester.tap(find.byKey(upKey));
      final controller = tester
          .widget<TextField>(find.byKey(sourceKey))
          .controller!;
      controller.selection = const TextSelection.collapsed(offset: 0);
      response.complete(const PromptTranslationEditResult('green eyes, smile'));
      await settleConversion(tester);
      await tester.enterText(find.byKey(zhKey), '绿眼睛，长发');
      await tester.tap(find.byKey(upKey));
      await settleConversion(tester);
      expect(requests.last.baselineSource, 'green eyes, smile');
      expect(requests.last.baselineZh, '绿眼睛，微笑');
      expect(fieldText(tester, sourceKey), 'green eyes, long hair');
      handle.dismiss();
      await tester.pump();
    },
  );

  testWidgets('close cancels request and ignores its late completion', (
    tester,
  ) async {
    final response = Completer<PromptTranslationEditResult>();
    final canceled = <String>[];
    final handle = await openEditor(
      tester,
      converter: (_, __) => response.future,
      cancel: canceled.add,
    );
    await tester.tap(find.byKey(upKey));
    await tester.pump();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    expect(await handle.result, isNull);
    expect(canceled, hasLength(1));
    response.complete(const PromptTranslationEditResult('late'));
    await settleConversion(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure keeps drafts and permits retry', (tester) async {
    final handle = await openEditor(
      tester,
      converter: (_, __) async => throw StateError('offline'),
    );
    await tester.enterText(find.byKey(zhKey), '新中文');
    await tester.tap(find.byKey(upKey));
    await settleConversion(tester);
    expect(fieldText(tester, sourceKey), 'blue eyes, smile');
    expect(fieldText(tester, zhKey), '新中文');
    expect(find.textContaining('转换失败'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(upKey)).onPressed, isNotNull);
    handle.dismiss();
    await tester.pump();
  });

  testWidgets('configuration hides editor temporarily and retains drafts', (
    tester,
  ) async {
    var configured = false;
    final dialog = Completer<void>();
    final handle = await openEditor(
      tester,
      converter: (_, __) async => const PromptTranslationEditResult('new'),
      configured: () => configured,
      onConfigure: () => dialog.future,
    );
    await tester.enterText(find.byKey(zhKey), '未保存的中文');
    expect(tester.widget<IconButton>(find.byKey(upKey)).onPressed, isNull);
    await tester.tap(find.text('配置翻译模型'));
    await tester.pump();
    expect(find.byKey(zhKey), findsNothing);
    configured = true;
    dialog.complete();
    await tester.pumpAndSettle();
    expect(fieldText(tester, zhKey), '未保存的中文');
    expect(tester.widget<IconButton>(find.byKey(upKey)).onPressed, isNotNull);
    handle.dismiss();
    await tester.pump();
  });

  testWidgets('native undo and redo restore only the converted field', (
    tester,
  ) async {
    final handle = await openEditor(
      tester,
      converter: (_, __) async =>
          const PromptTranslationEditResult('green eyes, smile'),
    );
    await tester.enterText(
      find.byKey(sourceKey),
      'blue eyes, smile, long hair',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byKey(zhKey), '绿眼睛，微笑');
    await tester.tap(find.byKey(upKey));
    await settleConversion(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(fieldText(tester, sourceKey), 'blue eyes, smile, long hair');
    expect(fieldText(tester, zhKey), '绿眼睛，微笑');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(fieldText(tester, sourceKey), 'green eyes, smile');
    handle.dismiss();
    await tester.pump();
  });

  testWidgets(
    'Chinese tag insertion retains editor and sends canonical mapping',
    (tester) async {
      PromptTranslationEditRequest? sent;
      final handle = await openEditor(
        tester,
        enableTags: true,
        converter: (request, _) async {
          sent = request;
          return const PromptTranslationEditResult('green eyes, smile');
        },
      );
      await tester.tap(find.byKey(zhKey));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(zhKey));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
      expect(
        find.byKey(const Key('translation-pill-editor-popover')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        '绿眼睛',
      );
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('green eyes').first));
      await tester.pump();
      await tester.tap(find.byTooltip('插入标签').first);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
      expect(find.byKey(zhKey), findsOneWidget);
      expect(fieldText(tester, zhKey), contains('绿眼睛'));
      expect(
        tester.widget<TextField>(find.byKey(zhKey)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.tap(find.byKey(upKey));
      await settleConversion(tester);
      expect(sent!.selectedTerms.single.tag, 'green_eyes');
      expect(sent!.selectedTerms.single.text, '绿眼睛');
      await tester.enterText(find.byKey(zhKey), '只保留微笑');
      await tester.tap(find.byKey(upKey));
      await settleConversion(tester);
      expect(sent!.selectedTerms, isEmpty);
      await tester.tap(find.byKey(zhKey));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.tap(find.byKey(upKey));
      await settleConversion(tester);
      expect(sent!.selectedTerms.single.tag, 'green_eyes');
      handle.dismiss();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'source picker inserts English and close outside discards changes',
    (tester) async {
      final handle = await openEditor(tester, enableTags: true);
      await tester.tap(find.byKey(sourceKey));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(sourceKey));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'green',
      );
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('green eyes').first));
      await tester.pump();
      await tester.tap(find.byTooltip('插入标签').first);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(fieldText(tester, sourceKey), contains('green eyes'));
      expect(fieldText(tester, sourceKey), isNot(contains('绿眼睛')));
      expect(find.byKey(badgeKey), findsOneWidget);
      await tester.tapAt(const Offset(780, 580));
      await tester.pump();
      expect(await handle.result, isNull);
    },
  );

  testWidgets('long drafts fit a narrow viewport and remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(300, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final handle = await openEditor(
      tester,
      initial: TranslationPill(
        source: List.filled(100, 'blue eyes, ').join(),
        zh: List.filled(100, '蓝眼睛，').join(),
        needsReview: true,
      ),
    );
    expect(tester.takeException(), isNull);
    final rect = tester.getRect(
      find.byKey(const Key('translation-pill-editor-popover')),
    );
    expect(rect.width, lessThanOrEqualTo(284));
    expect(rect.height, lessThanOrEqualTo(344));
    expect(rect.left, greaterThanOrEqualTo(8));
    expect(rect.top, greaterThanOrEqualTo(8));
    handle.dismiss();
    await tester.pump();
  });

  testWidgets('empty input disables only its conversion direction', (
    tester,
  ) async {
    final handle = await openEditor(
      tester,
      converter: (_, __) async =>
          const PromptTranslationEditResult('translated'),
    );
    await tester.enterText(find.byKey(zhKey), '');
    await tester.pump();
    expect(tester.widget<IconButton>(find.byKey(upKey)).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(downKey)).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(find.byKey(saveKey)).onPressed, isNull);
    handle.dismiss();
    await tester.pump();
  });

  testWidgets(
    'native select, copy, cut, paste and immediate history stay inside one field',
    (tester) async {
      var clipboard = '';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        if (call.method == 'Clipboard.getData') return {'text': clipboard};
        if (call.method == 'Clipboard.hasStrings') {
          return {'value': clipboard.isNotEmpty};
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final handle = await openEditor(tester);
      await tester.tap(find.byKey(sourceKey));
      await _control(tester, LogicalKeyboardKey.keyA);
      expect(
        tester.widget<TextField>(find.byKey(sourceKey)).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 16),
      );
      await _control(tester, LogicalKeyboardKey.keyC);
      expect(clipboard, 'blue eyes, smile');
      await _control(tester, LogicalKeyboardKey.keyX);
      expect(fieldText(tester, sourceKey), isEmpty);
      clipboard = 'red eyes';
      await _control(tester, LogicalKeyboardKey.keyV);
      expect(fieldText(tester, sourceKey), 'red eyes');
      expect(fieldText(tester, zhKey), '蓝眼睛，微笑');
      await _control(tester, LogicalKeyboardKey.keyZ);
      expect(fieldText(tester, sourceKey), 'blue eyes, smile');
      await _control(tester, LogicalKeyboardKey.keyY);
      expect(fieldText(tester, sourceKey), 'red eyes');
      handle.dismiss();
      await tester.pump();
    },
  );

  testWidgets('IME composition commits one Chinese history step', (
    tester,
  ) async {
    final handle = await openEditor(tester);
    await tester.showKeyboard(find.byKey(zhKey));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中文',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中文',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    await _control(tester, LogicalKeyboardKey.keyZ);
    expect(fieldText(tester, zhKey), '蓝眼睛，微笑');
    expect(fieldText(tester, sourceKey), 'blue eyes, smile');
    expect(find.byKey(badgeKey), findsNothing);
    handle.dismiss();
    await tester.pump();
  });
}

Future<void> _control(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

const _candidate = CompletionCandidate(
  canonicalTag: 'green_eyes',
  translation: '绿眼睛',
  category: TagCategory.general,
  postCount: 10,
  matchKind: CompletionMatchKind.englishExact,
  sources: {CompletionSourceKind.base},
);
LocalTagExpansionService _tagService() => LocalTagExpansionService(
  catalog: _Source(),
  chineseDictionary: _Source(),
  relatedTags: _Source(),
  translations: _Readings(),
  substringSearch: (input, {limit = 20}) async => const [],
  popularSearch: ({limit = 12}) async => [_candidate],
);

class _Source implements CompletionSource {
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [
    _candidate,
  ];
}

class _Readings implements TranslationResolver {
  @override
  Future<Map<String, String>> resolve(
    List<String> tags, {
    required String locale,
  }) async => const {'green_eyes': '绿眼睛'};
}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}
