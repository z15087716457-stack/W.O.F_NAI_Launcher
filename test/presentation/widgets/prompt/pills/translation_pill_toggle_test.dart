// 翻译块切换原文 / 译文：Windows 用鼠标中键，macOS 用 ⌘+点击（触控板没有中键），
// 所有平台的右键菜单里都有「切换原文 / 译文」（翻译块在输入框里时的菜单见
// prompt_pill_editor_test）。
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';

const _source = 'blue eyes';
const _reading = '蓝眼睛';
const _toggleLabel = '切换原文 / 译文';

final _popup = find.byKey(const Key('tag-expansion-popup'));
final _sourceField = find.byKey(const Key('translation-pill-source-input'));

void main() {
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
    await Hive.openBox(StorageKeys.historyBox, bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
  });

  late TranslationPill pill;
  late List<Offset> edits;

  /// 和输入框里一样：翻译块在「相关 tag」包装层里面。
  Future<void> pumpPill(
    WidgetTester tester, {
    bool editableSource = false,
    bool original = false,
  }) async {
    pill = TranslationPill(
      source: _source,
      zh: _reading,
      showOriginal: original,
    );
    edits = [];
    final controller = TextEditingController(text: 'solo, ');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTagExpansionServiceProvider.overrideWithValue(
            LocalTagExpansionService(
              catalog: const _EmptySource(),
              relatedTags: const _EmptySource(),
              substringSearch: (input, {limit = 20}) async => const [],
              popularSearch: ({limit = 12}) async => const [],
            ),
          ),
          tagWikiRepositoryProvider.overrideWithValue(const _NoWiki()),
          wikiTagLinksProvider.overrideWithValue(
            WikiTagLinks(exactLookup: (_) async => {}),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: TagExpansionWrapper(
                  controller: controller,
                  focusNode: focusNode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        key: const Key('prompt-editor'),
                        controller: controller,
                        focusNode: focusNode,
                      ),
                      const SizedBox(height: 40),
                      StatefulBuilder(
                        builder: (context, setState) => TranslationPillView(
                          pill: pill,
                          onToggle: () => setState(
                            () => pill = pill.copyWith(
                              showOriginal: !pill.showOriginal,
                            ),
                          ),
                          onEdit: edits.add,
                          onSourceChanged: editableSource ? (_) {} : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> clickWith(
    WidgetTester tester,
    Finder target,
    LogicalKeyboardKey modifier,
  ) async {
    await tester.sendKeyDownEvent(modifier);
    final mouse = await tester.startGesture(
      tester.getCenter(target),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.up();
    await tester.sendKeyUpEvent(modifier);
    await tester.idle();
    await tester.pump();
  }

  Finder pillFinder() => find.byType(TranslationPillView);

  testWidgets('macOS：⌘+点击翻译块切换原文 / 译文，不弹相关 tag、不开编辑窗', (tester) async {
    await pumpPill(tester);

    await clickWith(tester, pillFinder(), LogicalKeyboardKey.metaLeft);
    expect(pill.showOriginal, isTrue);
    expect(find.text(_source), findsOneWidget);
    expect(_popup, findsNothing);
    expect(edits, isEmpty);

    await tester.pump(const Duration(milliseconds: 400));
    await clickWith(tester, pillFinder(), LogicalKeyboardKey.metaLeft);
    expect(pill.showOriginal, isFalse);
    expect(_popup, findsNothing);
    expect(edits, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('macOS：原文可编辑时 ⌘+点击原文也切回译文', (tester) async {
    await pumpPill(tester, editableSource: true);
    await clickWith(tester, pillFinder(), LogicalKeyboardKey.metaLeft);
    expect(pill.showOriginal, isTrue);
    expect(_sourceField, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await clickWith(tester, _sourceField, LogicalKeyboardKey.metaLeft);
    expect(pill.showOriginal, isFalse);
    expect(_sourceField, findsNothing);
    expect(_popup, findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('macOS：⌘+点击普通文字照旧打开相关 tag', (tester) async {
    await pumpPill(tester);
    await clickWith(
      tester,
      find.byKey(const Key('prompt-editor')),
      LogicalKeyboardKey.metaLeft,
    );
    expect(_popup, findsOneWidget);
    expect(pill.showOriginal, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('Windows：中键切换照旧；Ctrl+点击不切换（照旧开编辑窗）', (tester) async {
    await pumpPill(tester);
    final middle = await tester.startGesture(
      tester.getCenter(pillFinder()),
      kind: PointerDeviceKind.mouse,
      buttons: kMiddleMouseButton,
    );
    await middle.up();
    await tester.pump();
    expect(pill.showOriginal, isTrue);

    await clickWith(tester, pillFinder(), LogicalKeyboardKey.controlLeft);
    expect(pill.showOriginal, isTrue);
    expect(edits, hasLength(1));
    await tester.pump(const Duration(milliseconds: 400));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    '可编辑的原文：右键是原文输入框自己的菜单，多一项切换',
    (tester) async {
      await pumpPill(tester, editableSource: true, original: true);
      expect(_sourceField, findsOneWidget);

      await tester.tap(_sourceField, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.text(_toggleLabel), findsOneWidget);
      await tester.tap(find.text(_toggleLabel));
      await tester.pumpAndSettle();
      expect(pill.showOriginal, isFalse);
      expect(_sourceField, findsNothing);
      expect(edits, isEmpty);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}

class _EmptySource implements CompletionSource {
  const _EmptySource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}

class _NoWiki implements TagWikiRepository {
  const _NoWiki();

  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}
