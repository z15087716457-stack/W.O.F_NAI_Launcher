import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_autocomplete_controller.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/core/utils/tag_normalizer.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_meaning.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_autocomplete_binding.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_autocomplete_popup.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/tag_meaning_fixtures.dart';

CompletionCandidate _tag(
  String name, [
  String? translation,
  int count = 8500,
]) => CompletionCandidate(
  canonicalTag: name,
  translation: translation,
  postCount: count,
  category: TagCategory.character,
  matchKind: CompletionMatchKind.englishPrefix,
  sources: const {CompletionSourceKind.base},
);

final _samples = [
  _tag('hair_ears', '耳状发'),
  _tag('keqing_(opulent_splendor)_(genshin_impact)', '刻晴（霓裾翩跹）（原神）'),
  _tag('keqing_(lantern_rite)_(genshin_impact)', '刻晴（海灯节庆典服装）（原神）'),
  _tag('ningguang_(genshin_impact)', '凝光（原神）'),
  _tag('neck_tassel', '颈部流苏'),
  ...List.generate(
    12,
    (i) => _tag(
      'character_${i}_(alternate_costume)_(official_reference)_(genshin_impact)',
      '完整角色译名$i（含替换服装与官方设定说明，保持全部内容）',
      20300,
    ),
  ),
];

class _Readings extends ChangeNotifier implements AutoTagTranslationController {
  final names = <String, String>{};
  @override
  String? nameFor(String tag) => names[tag];
  @override
  void observe({
    required String surface,
    required String tag,
    required bool visible,
    String? existingNameZh,
    AutoTagTranslationContext? tagContext,
  }) {}
  @override
  void clearSurface(String surface) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Editor {
  _Editor({
    List<CompletionCandidate>? candidates,
    Completer<List<CompletionCandidate>>? related,
  }) {
    completion = PromptAutocompleteController(
      enabled: true,
      search: (_) async => candidates ?? _samples,
      relatedSearch: (_, {required locale, required existingTags}) =>
          related?.future ?? Future.value(_samples.reversed.toList()),
    );
  }
  late final PromptAutocompleteController completion;
  final text = TextEditingController();
  final focus = FocusNode();
  final readings = _Readings();
  void dispose() {
    completion.dispose();
    text.dispose();
    focus.dispose();
  }
}

Future<_Editor> _pumpEditor(
  WidgetTester t, {
  Size size = const Size(900, 850),
  double scale = 1,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.dark,
  String input = 'ke',
  Alignment alignment = Alignment.topLeft,
  List<CompletionCandidate>? candidates,
  Completer<List<CompletionCandidate>>? related,
  bool openRelated = false,
  Future<TagSemanticProfile?> Function(String)? meaning,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPhysicalSize);
  final editor = _Editor(candidates: candidates, related: related);
  addTearDown(editor.dispose);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        autoTagTranslationProvider.overrideWith((_) => editor.readings),
        tagMeaningProfileProvider.overrideWith(
          (_, tag) async => meaning == null ? null : meaning(tag),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.getTheme(AppStyle.geist, brightness),
        builder: (_, child) => UiScale(
          scale: scale,
          child: RepaintBoundary(key: tagMeaningBoundary, child: child!),
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: alignment,
              child: SizedBox(
                width: 380,
                child: PromptAutocompleteBinding(
                  autocomplete: editor.completion,
                  controller: editor.text,
                  focusNode: editor.focus,
                  locale: locale.toLanguageTag(),
                  autoInsertComma: true,
                  onAccept: (value) => editor.text.value = value,
                  builder: promptAutocompletePopupBuilder,
                  child: TextField(
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        editor.completion.update(
                          newValue,
                          locale: locale.toLanguageTag(),
                        );
                        return newValue;
                      }),
                    ],
                    controller: editor.text,
                    focusNode: editor.focus,
                    maxLines: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.byType(TextField));
  await t.enterText(find.byType(TextField), input);
  await t.pump(const Duration(milliseconds: 120));
  await t.pump();
  if (openRelated) {
    unawaited(editor.completion.openRelated(1));
    await t.pump();
    await t.pump();
  }
  await t.pump();
  return editor;
}

Finder _row(int index, {bool related = false}) =>
    find.byKey(Key('prompt-autocomplete-${related ? 'related-' : ''}$index'));

void _checkRows(WidgetTester t) {
  for (final element
      in find
          .descendant(
            of: find.byKey(const Key('prompt-autocomplete')),
            matching: find.byType(RichText),
          )
          .evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(paragraph.maxLines, isNull);
    expect(paragraph.didExceedMaxLines, false);
    // Wrapped trailing spaces can hang beyond a line's width; check painted
    // words rather than treating those invisible spaces as clipped content.
    final boxes = RegExp(r'\S+')
        .allMatches(paragraph.text.toPlainText())
        .expand(
          (word) => paragraph.getBoxesForSelection(
            TextSelection(baseOffset: word.start, extentOffset: word.end),
          ),
        );
    for (final box in boxes) {
      expect(box.left, greaterThanOrEqualTo(-1));
      expect(
        box.right,
        lessThanOrEqualTo(paragraph.size.width + 1),
        reason: '${paragraph.text.toPlainText()} / $box / ${paragraph.size}',
      );
      expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 1));
    }
  }
  for (final related in [false, true]) {
    for (var i = 0; i < _samples.length; i++) {
      final candidate = _row(i, related: related);
      if (candidate.evaluate().isEmpty) continue;
      final bounds = t.getRect(candidate);
      final texts = find.descendant(of: candidate, matching: find.byType(Text));
      final count = t.getRect(texts.last);
      for (final text in texts.evaluate().take(texts.evaluate().length - 1)) {
        final rect = t.getRect(find.byWidget(text.widget));
        expect(rect.right, lessThanOrEqualTo(count.left - 5));
        expect(rect.top, greaterThanOrEqualTo(bounds.top));
        expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
      }
    }
  }
  expect(t.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);

  final aliasCorrection = _tag('grey_hair', '灰发').copyWith(
    category: TagCategory.general,
    matchKind: CompletionMatchKind.spelling,
    matchedAlias: 'silver_hair',
  );
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'spelling suggestion displays its alias and accepts a click ${locale.toLanguageTag()}',
      (t) async {
        final editor = await _pumpEditor(
          t,
          size: locale.languageCode == 'ja'
              ? const Size(320, 360)
              : const Size(560, 430),
          scale: locale.languageCode == 'ja' ? 1.5 : 1,
          brightness: locale.languageCode == 'ko'
              ? Brightness.light
              : Brightness.dark,
          input: 'silvre hair',
          candidates: [aliasCorrection],
          locale: locale,
        );
        final l = AppLocalizations.of(t.element(find.byType(TextField)))!;
        expect(find.text(l.prompt_spellingSuggestion), findsOneWidget);
        expect(
          find.text(l.tagExpansion_matchedAlias('silver hair')),
          findsOneWidget,
        );
        expect(find.text(l.prompt_spellingHint), findsOneWidget);
        final list = t.getRect(
          find.byKey(const Key('prompt-autocomplete-list')),
        );
        final alias = t.getRect(
          find.text(l.tagExpansion_matchedAlias('silver hair')),
        );
        expect(alias.bottom, lessThanOrEqualTo(list.bottom + 1));
        _checkRows(t);
        await captureTagMeaning(t, 'spelling-${locale.toLanguageTag()}');
        await t.tap(_row(0));
        await t.pump();
        expect(editor.text.text, 'grey hair, ');
        expect(find.byKey(const Key('prompt-autocomplete')), findsNothing);
      },
    );
  }

  for (final key in [
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.escape,
  ]) {
    testWidgets('spelling keyboard ${key.keyLabel} keeps explicit acceptance', (
      t,
    ) async {
      final editor = await _pumpEditor(
        t,
        input: 'silvre hair',
        candidates: [aliasCorrection],
      );
      await t.sendKeyEvent(key);
      await t.pump();
      expect(find.byKey(const Key('prompt-autocomplete')), findsNothing);
      expect(
        editor.text.text,
        key == LogicalKeyboardKey.tab
            ? 'grey hair, '
            : startsWith('silvre hair'),
      );
    });
  }

  testWidgets('moving to a regular result restores normal Enter completion', (
    t,
  ) async {
    final editor = await _pumpEditor(
      t,
      input: 'silvre hair',
      candidates: [aliasCorrection, _tag('silver_hairband')],
    );
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    expect(editor.completion.value.spellingSelected, false);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(editor.text.text, 'silver hairband, ');
  });

  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'initial popup fits the complete footer ${locale.toLanguageTag()} scale=$scale',
        (t) async {
          final editor = await _pumpEditor(t, locale: locale, scale: scale);
          final footer = find.descendant(
            of: find.byKey(const Key('prompt-autocomplete-footer')),
            matching: find.byType(RichText),
          );
          final paragraph = t.renderObject<RenderParagraph>(footer);
          final text = paragraph.text.toPlainText();
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
            boxHeightStyle: ui.BoxHeightStyle.max,
          );
          expect(
            boxes.map((box) => box.top).toSet(),
            hasLength(1),
            reason: 'The complete shortcut hint should fit on the first line',
          );
          final initialWidth = t
              .getSize(find.byKey(const Key('prompt-autocomplete')))
              .width;
          editor.readings.names[_samples.first.canonicalTag] = '很长的异步译名' * 12;
          editor.readings.notifyListeners();
          editor.completion.move(1);
          await t.pump();
          await t.pump();
          expect(
            t.getSize(find.byKey(const Key('prompt-autocomplete'))).width,
            initialWidth,
            reason:
                'Candidate contents and selection must not resize the popup',
          );
          _checkRows(t);
          await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await t.pump();
          await t.pump();
          final relatedHint = t.renderObject<RenderParagraph>(footer);
          expect(relatedHint.text.toPlainText(), contains('Tab /'));
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pump();
          expect(
            editor.completion.value.relatedAdded,
            contains(_samples.last.canonicalTag),
          );
          expect(editor.focus.hasPrimaryFocus, true);
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('narrow initial popup keeps the full footer scale=$scale', (
      t,
    ) async {
      await _pumpEditor(t, size: const Size(280, 850), scale: scale);
      _checkRows(t);
      final popup = t.getRect(find.byKey(const Key('prompt-autocomplete')));
      final footer = find.descendant(
        of: find.byKey(const Key('prompt-autocomplete-footer')),
        matching: find.byType(RichText),
      );
      final paragraph = t.renderObject<RenderParagraph>(footer);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
      expect(popup.left, greaterThanOrEqualTo(8 * scale - 1));
      expect(popup.right, lessThanOrEqualTo(280 - 8 * scale + 1));
    });
  }

  for (final width in [320.0, 900.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('counts stay on one line width=$width scale=$scale', (
        t,
      ) async {
        final candidates = [
          _tag('food', '食物', 629400),
          _tag('maid', '女仆', 213600),
          _tag('holding_food', '拿着食物', 157100),
          _tag('fruit', '水果', 155100),
        ];
        await _pumpEditor(
          t,
          size: Size(width, 850),
          scale: scale,
          candidates: candidates,
          related: Completer<List<CompletionCandidate>>()..complete(candidates),
          openRelated: true,
        );
        for (final related in [false, true]) {
          double? right;
          for (var i = 0; i < candidates.length; i++) {
            final count = find
                .descendant(
                  of: _row(i, related: related),
                  matching: find.byType(RichText),
                )
                .last;
            final paragraph = t.renderObject<RenderParagraph>(count);
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: paragraph.text.toPlainText().length,
              ),
              boxHeightStyle: ui.BoxHeightStyle.max,
            );
            expect(boxes.map((box) => box.top).toSet(), hasLength(1));
            expect(boxes.last.right, lessThanOrEqualTo(paragraph.size.width));
            final bounds = t.getRect(count);
            right ??= bounds.right;
            expect(bounds.right, closeTo(right, .1));
          }
        }
        _checkRows(t);
      });
    }
  }

  testWidgets('short pairs stay inline; long names and readings wrap in full', (
    t,
  ) async {
    await _pumpEditor(t, openRelated: true);
    _checkRows(t);
    final short = _row(0);
    final english = t.getRect(
      find.descendant(of: short, matching: find.text('hair ears')),
    );
    final reading = t.getRect(
      find.descendant(of: short, matching: find.text('耳状发')),
    );
    expect(english.overlaps(reading), false);
    expect((english.top - reading.top).abs(), lessThan(3));
    final long = _row(1);
    final name = find.descendant(
      of: long,
      matching: find.text(TagNormalizer.toDisplay(_samples[1].canonicalTag)),
    );
    expect(t.getSize(name).height, greaterThan(25));
    final chinese = find.descendant(
      of: long,
      matching: find.text(_samples[1].translation!),
    );
    expect(t.getTopLeft(chinese).dy, greaterThan(t.getBottomLeft(name).dy));
    expect(t.getSize(long).height, greaterThan(t.getSize(short).height));
    expect(
      t.getSize(find.byKey(const Key('prompt-autocomplete-list'))).height,
      lessThanOrEqualTo(PromptAutocompletePopup.maxListHeight),
    );
  });

  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final (width, scale) in [(736.0, 1.0), (320.0, 1.0), (540.0, 1.5)]) {
        testWidgets(
          'full text fits ${locale.toLanguageTag()} $brightness ${width}px scale=$scale',
          (t) async {
            final editor = await _pumpEditor(
              t,
              size: Size(width, 850),
              scale: scale,
              locale: locale,
              brightness: brightness,
              openRelated: true,
            );
            _checkRows(t);
            final popup = t.getRect(
              find.byKey(const Key('prompt-autocomplete')),
            );
            expect(popup.left, greaterThanOrEqualTo(8 * scale - 1));
            expect(popup.right, lessThanOrEqualTo(width - 8 * scale + 1));
            expect(popup.bottom, lessThanOrEqualTo(850 - 8 * scale + 1));
            final main = t.getRect(
              find.byKey(const Key('prompt-autocomplete-main')),
            );
            final related = t.getRect(
              find.byKey(const Key('prompt-autocomplete-related')),
            );
            if (width / scale <= 436) {
              expect(related.top, greaterThanOrEqualTo(main.bottom));
            } else {
              expect(related.left, greaterThanOrEqualTo(main.right));
            }
            expect(editor.focus.hasPrimaryFocus, true);
          },
        );
      }
    }
  }

  for (final related in [false, true]) {
    for (final scale in [1.0, 1.5]) {
      for (final mixed in [false, true]) {
        testWidgets(
          'keyboard selection moves before list scrolls related=$related scale=$scale mixed=$mixed',
          (t) async {
            final candidates = List.generate(
              24,
              (i) => _tag(
                mixed && i.isOdd
                    ? 'long_reference_name_${i}_(alternate_costume)_(game)'
                    : 'option_$i',
                '选项$i',
              ),
            );
            final editor = await _pumpEditor(
              t,
              scale: scale,
              candidates: candidates,
              related: Completer<List<CompletionCandidate>>()
                ..complete(candidates),
            );
            if (related) {
              await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
              await t.pump();
              await t.pump();
            }
            final list = find.byKey(
              Key('prompt-autocomplete-${related ? 'related-' : ''}list'),
            );
            double offset() => t
                .state<ScrollableState>(
                  find.descendant(of: list, matching: find.byType(Scrollable)),
                )
                .position
                .pixels;
            expect(offset(), 0);
            var scrollSteps = 0, stationarySteps = 0;
            double? heldTop;
            for (var i = 1; i < candidates.length - 1; i++) {
              final viewport = t.getRect(list);
              final nextBefore = t.getRect(_row(i + 1, related: related));
              final oldTop = t.getTopLeft(_row(i - 1, related: related)).dy;
              final before = offset();
              await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
              await t.pump();
              await t.pump();
              final selected = t.getRect(_row(i, related: related));
              final following = t.getRect(_row(i + 1, related: related));
              final state = editor.completion.value;
              expect(related ? state.relatedSelected : state.selectedIndex, i);
              if (nextBefore.bottom <= viewport.bottom + .1) {
                expect(
                  offset(),
                  closeTo(before, .01),
                  reason:
                      'Move the selection down inside the visible list first',
                );
                expect(selected.top, greaterThan(oldTop));
                stationarySteps++;
              } else {
                expect(offset(), greaterThan(before));
                expect(
                  following.bottom,
                  closeTo(viewport.bottom, 1),
                  reason:
                      'Leave one complete following candidate below the selection',
                );
                if (!mixed) {
                  heldTop ??= selected.top;
                  expect(selected.top, closeTo(heldTop, 1));
                }
                scrollSteps++;
              }
              expect(selected.top, greaterThanOrEqualTo(viewport.top - 1));
              expect(selected.bottom, lessThanOrEqualTo(viewport.bottom + 1));
              expect(following.bottom, lessThanOrEqualTo(viewport.bottom + 1));
              expect(editor.focus.hasPrimaryFocus, true);
            }
            expect(stationarySteps, greaterThan(0));
            expect(scrollSteps, greaterThan(0));
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('keyboard keeps each variable-height row visible in both lists', (
    t,
  ) async {
    final editor = await _pumpEditor(t);
    for (final related in [false, true]) {
      if (related) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await t.pump();
        await t.pump();
      }
      for (var i = 0; i < _samples.length * 2; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await t.pump();
        await t.pump();
        final state = editor.completion.value;
        final selected = _row(
          related ? state.relatedSelected : state.selectedIndex,
          related: related,
        );
        final list = find.byKey(
          Key('prompt-autocomplete-${related ? 'related-' : ''}list'),
        );
        final bounds = t.getRect(list), item = t.getRect(selected);
        expect(item.top, greaterThanOrEqualTo(bounds.top - 1));
        expect(item.bottom, lessThanOrEqualTo(bounds.bottom + 1));
        expect(editor.focus.hasPrimaryFocus, true);
      }
    }
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'bottom-right caret opens above, clamped under whole UI scaling',
    (t) async {
      await _pumpEditor(
        t,
        size: const Size(736, 500),
        scale: 1.5,
        alignment: Alignment.bottomRight,
        openRelated: true,
      );
      _checkRows(t);
      final popup = t.getRect(find.byKey(const Key('prompt-autocomplete')));
      final editable = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final caret = editable.localToGlobal(
        editable.getLocalRectForCaret(const TextPosition(offset: 0)).topLeft,
      );
      expect(popup.bottom, closeTo(caret.dy - 6, 1));
      expect(popup.left, greaterThanOrEqualTo(11));
      expect(popup.right, lessThanOrEqualTo(725));
      expect(popup.top, greaterThanOrEqualTo(11));
    },
  );

  testWidgets(
    'new asynchronous reading reflows and preserves selected visibility',
    (t) async {
      final editor = await _pumpEditor(t);
      for (var i = 0; i < 7; i++) {
        editor.completion.move(1);
      }
      await t.pump();
      await t.pump();
      editor.readings.names[_samples[0].canonicalTag] =
          '异步返回的非常完整的中文译名与角色服装解释，保持全部内容并自动增加候选高度。' * 3;
      editor.readings.notifyListeners();
      await t.pump();
      await t.pump();
      _checkRows(t);
      final selected = t.getRect(_row(7));
      final list = t.getRect(find.byKey(const Key('prompt-autocomplete-list')));
      expect(selected.top, greaterThanOrEqualTo(list.top - 1));
      expect(selected.bottom, lessThanOrEqualTo(list.bottom + 1));
    },
  );

  testWidgets(
    'click and keyboard accept, append, and close without losing editor focus',
    (t) async {
      final editor = await _pumpEditor(t);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      await t.pump();
      await t.tap(_row(0, related: true));
      await t.pump();
      expect(
        editor.completion.value.relatedAdded,
        contains(_samples.last.canonicalTag),
      );
      expect(
        editor.text.text,
        contains(TagNormalizer.toDisplay(_samples.last.canonicalTag)),
      );
      expect(editor.focus.hasPrimaryFocus, true);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      await t.pump();
      expect(editor.completion.value.relatedFor, isNull);
      await t.tap(_row(1));
      await t.pump();
      expect(
        editor.text.text,
        contains(TagNormalizer.toDisplay(_samples[1].canonicalTag)),
      );
      expect(editor.completion.value.visible, false);
      expect(editor.focus.hasPrimaryFocus, true);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('related loading and empty results stay bounded', (t) async {
    final pending = Completer<List<CompletionCandidate>>();
    await _pumpEditor(t, related: pending, openRelated: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([]);
    await t.pump();
    await t.pump();
    _checkRows(t);
  });

  for (final brightness in Brightness.values) {
    for (final width in [1100.0, 320.0]) {
      testWidgets('meaning layout ${brightness.name} $width', (t) async {
        final editor = await _pumpEditor(
          t,
          size: Size(width, 700),
          brightness: brightness,
          meaning: (tag) async => meaningFixture(tag),
        );
        await t.pump();
        final main = find.byKey(const Key('prompt-autocomplete-main'));
        final meaning = find.byKey(const Key('prompt-autocomplete-meaning'));
        final mainRect = t.getRect(main), meaningRect = t.getRect(meaning);
        expect(find.text('同义词'), findsOneWidget);
        if (width == 1100) {
          expect(meaningRect.left, greaterThan(mainRect.right));
          expect(meaningRect.top, closeTo(mainRect.top, 1));
        } else {
          expect(meaningRect.top, greaterThan(mainRect.bottom));
        }
        await captureTagMeaning(t, 'autocomplete-${brightness.name}-$width');
        await editor.completion.openRelated(1);
        await t.pump();
        await t.pump();
        final related = find.byKey(const Key('prompt-autocomplete-related'));
        if (width == 1100) {
          expect(
            t.getRect(meaning).left,
            greaterThan(t.getRect(related).right),
          );
        } else {
          expect(
            t.getRect(meaning).top,
            greaterThan(t.getRect(related).bottom),
          );
        }
        _checkRows(t);
        expect(editor.text.text, 'ke');
        expect(editor.focus.hasPrimaryFocus, true);
        expect(t.takeException(), isNull);
        await captureTagMeaning(t, 'related-${brightness.name}-$width');
      });
    }
  }

  testWidgets('hover, keyboard, and late meanings keep the correct tag', (
    t,
  ) async {
    final pending = Completer<TagSemanticProfile?>();
    final editor = await _pumpEditor(
      t,
      size: const Size(1100, 850),
      meaning: (tag) => tag == _samples.first.canonicalTag
          ? pending.future
          : Future.value(meaningFixture(tag, summary: '释义：$tag')),
    );
    editor.completion.move(1);
    await t.pump();
    await t.pump();
    final selected = '释义：${_samples[1].canonicalTag}';
    expect(find.text(selected), findsOneWidget);
    pending.complete(
      meaningFixture(_samples.first.canonicalTag, summary: '过时结果'),
    );
    await t.pump();
    expect(find.text('过时结果'), findsNothing);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(_row(2)));
    await t.pump();
    await t.pump();
    final hovered = '释义：${_samples[2].canonicalTag}';
    expect(find.text(hovered), findsOneWidget);
    await mouse.moveTo(t.getCenter(find.byType(TagMeaning)));
    await t.pump();
    expect(find.text(hovered), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    await t.pump();
    expect(find.text('释义：${_samples[3].canonicalTag}'), findsOneWidget);
    expect(editor.text.text, 'ke');
    expect(editor.focus.hasPrimaryFocus, true);
    expect(t.takeException(), isNull);
  });

  testWidgets('meaning fits a short scaled Japanese window', (t) async {
    final editor = await _pumpEditor(
      t,
      size: const Size(540, 420),
      scale: 1.5,
      locale: const Locale('ja'),
      openRelated: true,
      meaning: (tag) async => meaningFixture(tag, summary: '完整显示的长释义。' * 30),
    );
    await t.pump();
    final rect = t.getRect(find.byKey(const Key('prompt-autocomplete')));
    expect(rect.top, greaterThanOrEqualTo(7));
    expect(rect.bottom, lessThanOrEqualTo(413));
    expect(rect.left, greaterThanOrEqualTo(7));
    expect(rect.right, lessThanOrEqualTo(533));
    expect(find.text('同義語'), findsOneWidget);
    expect(editor.focus.hasPrimaryFocus, true);
    expect(t.takeException(), isNull);
    await captureTagMeaning(t, 'related-ja-scaled-short');
  });

  testWidgets('long meaning wraps and wheel stays inside its own scroll', (
    t,
  ) async {
    final editor = await _pumpEditor(
      t,
      size: const Size(1100, 500),
      meaning: (tag) async => meaningFixture(
        tag,
        summary: '完整显示的长释义。' * 90,
        synonyms: List.generate(25, (i) => '完整同义词$i'),
      ),
    );
    await t.pump();
    final meaning = find.byKey(const Key('prompt-autocomplete-meaning'));
    final scroll = t
        .widget<SingleChildScrollView>(
          find.descendant(
            of: meaning,
            matching: find.byType(SingleChildScrollView),
          ),
        )
        .controller!;
    final before = editor.text.value;
    final rowY = t.getTopLeft(_row(0)).dy;
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await t.sendEventToBinding(pointer.hover(t.getCenter(meaning)));
    await t.sendEventToBinding(pointer.scroll(const Offset(0, 110)));
    await t.pump();
    expect(scroll.offset, greaterThan(0));
    expect(t.getTopLeft(_row(0)).dy, rowY);
    expect(editor.text.value, before);
    expect(editor.focus.hasPrimaryFocus, true);
    _checkRows(t);
    expect(t.takeException(), isNull);
    await captureTagMeaning(t, 'long-meaning-scroll');
  });

  testWidgets(
    'visible popup reflows on resize without resetting focus or selection',
    (t) async {
      final editor = await _pumpEditor(t, openRelated: true);
      editor.completion.move(3);
      await t.pump();
      await t.pump();
      final selected = editor.completion.value.relatedSelected;
      for (final width in [320.0, 736.0]) {
        t.view.physicalSize = Size(width, 850);
        await t.pump();
        await t.pump();
        _checkRows(t);
        final popup = t.getRect(find.byKey(const Key('prompt-autocomplete')));
        expect(popup.left, greaterThanOrEqualTo(7));
        expect(popup.right, lessThanOrEqualTo(width - 7));
        expect(editor.completion.value.relatedSelected, selected);
        expect(editor.focus.hasPrimaryFocus, true);
      }
    },
  );

  testWidgets(
    'wheel scrolls candidate list and does not move the text editor',
    (t) async {
      final editor = await _pumpEditor(t);
      final list = find.byKey(const Key('prompt-autocomplete-list'));
      final before = editor.text.value;
      final y = t.getTopLeft(_row(1)).dy;
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await t.sendEventToBinding(pointer.hover(t.getCenter(list)));
      await t.sendEventToBinding(pointer.scroll(const Offset(0, 90)));
      await t.pump();
      expect(t.getTopLeft(_row(1)).dy, lessThan(y));
      expect(editor.text.value, before);
      expect(editor.focus.hasPrimaryFocus, true);
      expect(t.takeException(), isNull);
    },
  );

  for (final toolbar in [false, true]) {
    testWidgets(
      'native paste stays quiet and later typing starts a new span toolbar=$toolbar',
      (t) async {
        final editor = await _pumpEditor(t);
        const prefix = 'masterpiece, ';
        editor.text.value = const TextEditingValue(
          text: prefix,
          selection: TextSelection.collapsed(offset: prefix.length),
        );
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => switch (call.method) {
            'Clipboard.getData' => {'text': 'blue hair'},
            'Clipboard.hasStrings' => {'value': true},
            _ => null,
          },
        );
        addTearDown(
          () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        if (toolbar) {
          await PromptAutocompleteBinding.paste(
            t.state<EditableTextState>(find.byType(EditableText)),
            SelectionChangedCause.toolbar,
          );
        } else {
          final modifier = defaultTargetPlatform == TargetPlatform.macOS
              ? LogicalKeyboardKey.metaLeft
              : LogicalKeyboardKey.controlLeft;
          await t.sendKeyDownEvent(modifier);
          await t.sendKeyEvent(LogicalKeyboardKey.keyV);
          await t.sendKeyUpEvent(modifier);
        }
        await t.pump(const Duration(milliseconds: 150));
        expect(editor.text.text, '${prefix}blue hair');
        expect(editor.completion.value.visible, false);
        final pasted = editor.text.text;
        t.testTextInput.updateEditingValue(
          TextEditingValue(
            text: '${pasted}bl',
            selection: TextSelection.collapsed(offset: pasted.length + 2),
          ),
        );
        await t.pump(const Duration(milliseconds: 150));
        expect(editor.completion.value.query!.token, 'bl');
        expect(
          editor.completion.value.query!.replacementRange.start,
          pasted.length,
        );
        expect(editor.focus.hasPrimaryFocus, true);
        expect(t.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.windows,
        TargetPlatform.macOS,
      }),
    );
  }
}
