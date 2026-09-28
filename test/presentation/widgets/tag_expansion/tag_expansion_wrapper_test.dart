import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/utils/prompt_input_normalization.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';

void main() {
  setUp(() async {
    Hive.init(
      '${Directory.systemTemp.path}/tag_expansion_${DateTime.now().microsecondsSinceEpoch}',
    );
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  testWidgets('typing stays quiet; Ctrl+click searches and inserts locally', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final catalog = _Source([_tag('blue_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(tester, controller, focusNode, catalog);

    await tester.enterText(find.byKey(const Key('prompt-editor')), 'solo, ');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    expect(catalog.queries, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Popular local tags'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    expect(catalog.queries.last.token, 'blue');
    await tester.tap(find.byTooltip('Insert tag').first);
    await tester.pump();
    expect(controller.text, 'solo, blue hair, ');
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
  });

  testWidgets('Ctrl+click keeps search empty and shows related context', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, ');
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      related: related,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(related.queries.single.relatedTag, 'blue_hair');
    expect(find.text('long hair'), findsOneWidget);
    expect(find.text('Related tags · blue hair'), findsOneWidget);
    expect(controller.text, 'blue hair, ');
  });

  testWidgets('Tab completes search text; Enter inserts into prompt', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'solo, ');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blu',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();

    expect(find.text('Tab to complete: blue hair'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
          .controller!
          .text,
      'blue hair',
    );
    expect(controller.text, 'solo, ');
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, 'solo, blue hair, ');
  });

  testWidgets('dismisses stale popup when the prompt changes elsewhere', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'solo, ');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);

    controller.text = 'newer user draft';
    await tester.pump();
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    expect(controller.text, 'newer user draft');
  });

  testWidgets('Enter inserts the selected search result', (tester) async {
    final controller = TextEditingController(text: 'solo, ');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.text, 'solo, blue hair, ');
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
  });

  testWidgets('disabled tag expansion does not open a popup', (tester) async {
    final controller = TextEditingController(text: 'solo');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      enabled: false,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
  });

  testWidgets('clicking a search result shows local related tags', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
      related: related,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();

    await tester.tap(find.text('blue hair').first);
    await tester.pump();
    expect(related.queries.single.relatedTag, 'blue_hair');
    expect(find.text('long hair'), findsOneWidget);
    await tester.tap(find.byTooltip('Insert tag').last);
    await tester.pump();
    expect(controller.text, 'long hair, ');
  });

  testWidgets('Ctrl+drag sends selected text to local related search', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, solo');
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      related: related,
    );

    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    Offset caret(int offset) {
      final rect = editable.getLocalRectForCaret(TextPosition(offset: offset));
      return editable.localToGlobal(Offset(rect.left + 1, rect.center.dy));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.startGesture(
      caret(0),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(caret(9));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    await gesture.up();
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    // Keep the selection visible in failures: the editor owns drag selection.
    expect(controller.selection.isValid, isTrue);
    expect(controller.selection.isCollapsed, isFalse);
    expect(
      controller.text.substring(
        controller.selection.start,
        controller.selection.end,
      ),
      'blue hair',
    );
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(related.queries, isNotEmpty);
    expect(related.queries.single.token, isEmpty);
  });

  testWidgets('partial Ctrl+drag prefills search without forcing related', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, solo');
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
      related: related,
    );
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    Offset caret(int offset) {
      final rect = editable.getLocalRectForCaret(TextPosition(offset: offset));
      return editable.localToGlobal(Offset(rect.left + 1, rect.center.dy));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.startGesture(
      caret(0),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(caret(4));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    await gesture.up();
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
          .controller!
          .text,
      'blue',
    );
    expect(related.queries, isEmpty);
    expect(controller.text, 'blue hair, solo');
  });

  testWidgets('multi-tag Ctrl+drag keeps the selection as a search query', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, solo');
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      related: related,
    );
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    final editable = tester
        .state<EditableTextState>(find.byType(EditableText))
        .renderEditable;
    Offset caret(int offset) {
      final rect = editable.getLocalRectForCaret(TextPosition(offset: offset));
      return editable.localToGlobal(Offset(rect.left + 1, rect.center.dy));
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.startGesture(
      caret(0),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(caret(15));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    await gesture.up();
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
          .controller!
          .text,
      'blue hair, solo',
    );
    expect(related.queries, isEmpty);
    expect(controller.text, 'blue hair, solo');
  });

  testWidgets('opening the picker does not format the prompt on focus loss', (
    tester,
  ) async {
    const source = 'blue hair,  white dress';
    expect(
      PromptInputNormalization.normalize(
        source,
        autoFormat: true,
        sdAutoConvert: false,
      ).text,
      isNot(source),
    );
    final controller = TextEditingController(text: source);
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTagExpansionServiceProvider.overrideWithValue(
            _service(_Source([_tag('blue_hair')])),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 160,
              child: UnifiedPromptInput(
                controller: controller,
                focusNode: focusNode,
                config: const UnifiedPromptConfig(
                  enableAutoFormat: true,
                  enableAutocomplete: false,
                ),
                maxLines: 3,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(controller.text, source);
    await tester.pump(const Duration(milliseconds: 250));
  });
}

Future<void> _pumpEditor(
  WidgetTester tester,
  TextEditingController controller,
  FocusNode focusNode,
  CompletionSource catalog, {
  CompletionSource? related,
  bool enabled = true,
}) async {
  final service = _service(catalog, related: related);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [localTagExpansionServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 80,
              child: TagExpansionWrapper(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                child: TextField(
                  key: const Key('prompt-editor'),
                  controller: controller,
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

LocalTagExpansionService _service(
  CompletionSource catalog, {
  CompletionSource? related,
}) => LocalTagExpansionService(
  catalog: catalog,
  chineseDictionary: _Source(const []),
  relatedTags: related ?? _Source(const []),
  translations: const _Translations(),
  substringSearch: (input, {limit = 20}) async => const [],
  popularSearch: ({limit = 12}) async => [_tag('solo')],
);

CompletionCandidate _tag(String name) => CompletionCandidate(
  canonicalTag: name,
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: const {CompletionSourceKind.base},
);

class _Source implements CompletionSource {
  _Source(this.results);

  final List<CompletionCandidate> results;
  final List<CompletionQuery> queries = [];

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    queries.add(query);
    return results;
  }
}

class _Translations implements TranslationResolver {
  const _Translations();

  @override
  Future<Map<String, String>> resolve(
    List<String> canonicalTags, {
    required String locale,
  }) async => const {};
}
