import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_autocomplete_controller.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';

const candidates = [
  CompletionCandidate(
    canonicalTag: 'blue_eyes',
    category: TagCategory.general,
    postCount: 1,
    matchKind: CompletionMatchKind.englishPrefix,
    sources: {CompletionSourceKind.base},
  ),
  CompletionCandidate(
    canonicalTag: 'blue_hair',
    category: TagCategory.general,
    postCount: 1,
    matchKind: CompletionMatchKind.englishPrefix,
    sources: {CompletionSourceKind.base},
  ),
];
TextEditingValue editing(String text, [int? caret]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret ?? text.length),
);

class _Source implements CompletionSource {
  final queries = <CompletionQuery>[];
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    queries.add(query);
    return candidates;
  }
}

void main() {
  testWidgets(
    'Chinese composing commit searches and accepts English canonical tag',
    (tester) async {
      final source = _Source();
      final service = LocalTagExpansionService(
        catalog: source,
        relatedTags: source,
        substringSearch: (_, {int limit = 40}) async => [],
        popularSearch: ({int limit = 12}) async => [],
        semanticNames: (input, {int limit = 80}) async =>
            input == '蓝眼' ? [candidates.first] : [],
      );
      final controller = PromptAutocompleteController.local(
        service: service,
        enabled: true,
      );
      addTearDown(controller.dispose);
      controller.update(
        editing('蓝眼').copyWith(composing: const TextRange(start: 0, end: 2)),
        locale: 'zh',
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(controller.value.visible, false);
      controller.update(editing('蓝眼'), locale: 'zh');
      await tester.pump(const Duration(milliseconds: 120));
      expect(controller.value.query!.kind, CompletionQueryKind.tag);
      expect(controller.value.candidates.single.canonicalTag, 'blue_eyes');
      expect(controller.accept()!.text, 'blue eyes, ');
      expect(source.queries, isEmpty);
    },
  );

  for (final (text, caret, comma, expected) in [
    ('bl', 2, true, 'blue eyes, blue hair, '),
    ('bl', 2, false, 'blue eyes, blue hair'),
    ('2.5::bl::, sky', 7, true, '2.5::blue eyes::, blue hair, sky'),
    ('{[bl]}', 4, false, '{[blue eyes]}, blue hair'),
    ('(bl:1.2)', 3, true, '(blue eyes:1.2), blue hair, '),
  ]) {
    testWidgets(
      'related completes source once, appends, deduplicates: $text comma=$comma',
      (tester) async {
        final relatedQueries = <(String, Set<String>)>[];
        final controller = PromptAutocompleteController(
          enabled: true,
          search: (_) async => candidates,
          relatedSearch: (tag, {required locale, required existingTags}) async {
            relatedQueries.add((tag, existingTags));
            return [
              candidates.last.copyWith(translation: '蓝发'),
              candidates.first,
            ];
          },
        );
        addTearDown(controller.dispose);
        controller.update(editing(text, caret), locale: 'zh');
        await tester.pump(const Duration(milliseconds: 120));
        await controller.openRelated(0);
        expect(relatedQueries.single.$1, 'blue_eyes');
        expect(relatedQueries.single.$2, contains('blue_eyes'));
        expect(controller.value.relatedFor, (
          index: 0,
          canonicalTag: 'blue_eyes',
        ));
        expect(controller.value.related.first.translation, '蓝发');
        expect(controller.value.visibleTags, ['blue_eyes', 'blue_hair']);
        final first = controller.acceptRelated(0, comma);
        expect(first!.text, expected);
        expect(first.composing, TextRange.empty);
        expect(controller.value.visible, true);
        expect(controller.value.relatedAdded, {'blue_hair'});
        expect(controller.acceptRelated(0, comma), isNull);
        expect(controller.acceptRelated(1, comma), isNull);
        controller.closeRelated();
        expect(controller.value.relatedFor, isNull);
        expect(controller.value.relatedAdded, isEmpty);
        expect(controller.value.visible, true);
        controller.dismiss();
        expect(controller.value.visibleTags, isEmpty);
      },
    );
  }

  testWidgets('related insertion supports one-character canonical source', (
    tester,
  ) async {
    final controller = PromptAutocompleteController(
      enabled: true,
      search: (_) async => [
        const CompletionCandidate(
          canonicalTag: '?',
          category: TagCategory.general,
          postCount: 1,
          matchKind: CompletionMatchKind.chineseExact,
          sources: {CompletionSourceKind.base},
        ),
      ],
      relatedSearch: (_, {required locale, required existingTags}) async => [
        candidates.first,
      ],
    );
    addTearDown(controller.dispose);
    controller.update(editing('疑问'), locale: 'zh');
    await tester.pump(const Duration(milliseconds: 120));
    await controller.openRelated(0);
    expect(controller.acceptRelated(0)!.text, '?, blue eyes, ');
  });

  testWidgets(
    'related keyboard appends multiple tags; Escape closes only related; Shift is not a shortcut',
    (tester) async {
      const extra = CompletionCandidate(
        canonicalTag: 'long_hair',
        category: TagCategory.general,
        postCount: 1,
        matchKind: CompletionMatchKind.related,
        sources: {CompletionSourceKind.cooccurrence},
      );
      final controller = PromptAutocompleteController(
        enabled: true,
        search: (_) async => candidates,
        relatedSearch: (_, {required locale, required existingTags}) async => [
          candidates.last,
          extra,
        ],
      );
      addTearDown(controller.dispose);
      final accepted = <TextEditingValue>[];
      bool key(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) =>
          controller.handleKeyEvent(
            KeyDownEvent(
              logicalKey: logical,
              physicalKey: physical,
              timeStamp: Duration.zero,
            ),
            onAccept: accepted.add,
          );
      controller.update(editing('bl, sky', 2), locale: 'zh');
      await tester.pump(const Duration(milliseconds: 120));
      await controller.openRelated(0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(key(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab), false);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(key(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter), true);
      expect(accepted.last.text, 'blue eyes, blue hair, sky');
      expect(
        key(LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp),
        true,
      );
      expect(controller.value.relatedSelected, 1);
      expect(controller.value.selectedIndex, 0);
      expect(key(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab), true);
      expect(accepted.last.text, 'blue eyes, blue hair, long hair, sky');
      key(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
      expect(accepted, hasLength(2));
      expect(controller.value.relatedAdded, {'blue_hair', 'long_hair'});
      key(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown);
      expect(controller.value.relatedSelected, 0);
      expect(key(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), true);
      expect(controller.value.relatedFor, isNull);
      expect(controller.value.visible, true);
      expect(key(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), true);
      expect(controller.value.visible, false);
    },
  );

  testWidgets(
    'related existing tags, stale responses, errors, dismiss and dispose',
    (tester) async {
      final requests = <Completer<List<CompletionCandidate>>>[];
      final controller = PromptAutocompleteController(
        enabled: true,
        search: (_) async => candidates,
        relatedSearch: (_, {required locale, required existingTags}) {
          final request = Completer<List<CompletionCandidate>>();
          requests.add(request);
          return request.future;
        },
      );
      controller.update(editing('bl, blue hair', 2), locale: 'zh');
      await tester.pump(const Duration(milliseconds: 120));
      var pending = controller.openRelated(0);
      expect(controller.value.relatedLoading, true);
      expect(controller.acceptRelated(0), isNull);
      controller.closeRelated();
      requests.last.complete(candidates);
      await pending;
      expect(controller.value.relatedFor, isNull);
      pending = controller.openRelated(0);
      requests.last.complete(candidates);
      await pending;
      expect(controller.value.relatedAdded, {'blue_hair'});
      expect(controller.acceptRelated(1), isNull);
      pending = controller.openRelated(1);
      requests.last.completeError(StateError('related fixture'));
      await pending;
      expect(controller.value.relatedLoading, false);
      expect(controller.value.relatedError, isA<StateError>());
      pending = controller.openRelated(0);
      controller.dismiss();
      requests.last.complete(candidates);
      await pending;
      expect(controller.value.visible, false);
      controller.update(editing('bl'), locale: 'en');
      await tester.pump(const Duration(milliseconds: 120));
      pending = controller.openRelated(0);
      controller.dispose();
      requests.last.completeError(StateError('disposed'));
      await pending;
    },
  );
  testWidgets(
    'disabled, short inputs, aliases, selection and IME never search',
    (tester) async {
      var calls = 0;
      final controller = PromptAutocompleteController(
        search: (_) async {
          calls++;
          return candidates;
        },
      );
      addTearDown(controller.dispose);
      controller.update(editing('blue'), locale: 'en');
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 0);
      controller.enabled = true;
      for (final value in [
        editing('b'),
        editing(''),
        editing('<blue'),
        editing('blue').copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        ),
        editing('蓝色').copyWith(composing: const TextRange(start: 0, end: 2)),
        editing('2.5::blue::', 2),
      ]) {
        controller.update(value, locale: 'zh');
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(calls, 0);
      controller.update(editing('蓝'), locale: 'zh');
      await tester.pump(const Duration(milliseconds: 120));
      expect(calls, 1);
      expect(controller.value.visible, true);
    },
  );

  testWidgets('debounce, stale success/error, dismiss, disable and dispose', (
    tester,
  ) async {
    final requests = <String, Completer<List<CompletionCandidate>>>{};
    final controller = PromptAutocompleteController(
      enabled: true,
      search: (query) {
        return (requests[query.token] = Completer<List<CompletionCandidate>>())
            .future;
      },
    );
    controller.update(editing('bl'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 119));
    expect(requests, isEmpty);
    controller.update(editing('blu'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    expect(requests.keys, ['blu']);
    controller.update(editing('blue'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    requests['blue']!.complete(candidates);
    await tester.pump();
    expect(controller.value.query!.token, 'blue');
    requests['blu']!.completeError(StateError('stale'));
    await tester.pump();
    expect(controller.value.query!.token, 'blue');
    controller.update(editing('hair'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    controller.dismiss();
    requests['hair']!.complete(candidates);
    await tester.pump();
    expect(controller.value.visible, false);
    controller.update(editing('eyes'), locale: 'en');
    controller.enabled = false;
    await tester.pump(const Duration(milliseconds: 120));
    expect(requests.containsKey('eyes'), false);
    controller.enabled = true;
    controller.update(editing('dispose'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    controller.dispose();
    requests['dispose']!.complete(candidates);
    await tester.pump();
  });

  testWidgets('current local error is state, not an unhandled future', (
    tester,
  ) async {
    final controller = PromptAutocompleteController(
      enabled: true,
      search: (_) async => throw StateError('fixture'),
    );
    addTearDown(controller.dispose);
    controller.update(editing('bl'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    expect(controller.value.error, isA<StateError>());
    expect(controller.value.visible, false);
  });

  for (final (text, caret, expected) in [
    ('bl', 2, 'blue eyes, '),
    ('red, bl, sky', 7, 'red, blue eyes, sky'),
    ('2.5::bl::', 7, '2.5::blue eyes::, '),
    ('{[bl]}', 4, '{[blue eyes]}, '),
    ('(bl:1.2)', 3, '(blue eyes:1.2), '),
    ('{2::bl::}', 6, '{2::blue eyes::}, '),
    ('bl::', 2, 'blue eyes::, '),
  ]) {
    testWidgets('token replacement preserves syntax: $text', (tester) async {
      final source = _Source();
      final service = LocalTagExpansionService(
        catalog: source,
        relatedTags: source,
        substringSearch: (_, {int limit = 40}) async => [],
        popularSearch: ({int limit = 12}) async => [],
      );
      final controller = PromptAutocompleteController.local(
        service: service,
        enabled: true,
      );
      addTearDown(controller.dispose);
      controller.update(editing(text, caret), locale: 'en');
      await tester.pump(const Duration(milliseconds: 120));
      expect(source.queries.single.token, 'bl');
      expect(controller.value.anchorTextOffset, text.indexOf('bl'));
      final result = controller.accept();
      expect(result!.text, expected);
      expect(
        result.selection.extentOffset,
        expected.startsWith('red') ? 16 : expected.length,
      );
      expect(result.composing, TextRange.empty);
      expect(controller.value.visible, false);
    });
  }

  testWidgets('move wraps, keyboard accepts/dismisses only while visible', (
    tester,
  ) async {
    final controller = PromptAutocompleteController(
      enabled: true,
      search: (_) async => candidates,
    );
    addTearDown(controller.dispose);
    TextEditingValue? accepted;
    bool key(LogicalKeyboardKey logical, PhysicalKeyboardKey physical) =>
        controller.handleKeyEvent(
          KeyDownEvent(
            logicalKey: logical,
            physicalKey: physical,
            timeStamp: Duration.zero,
          ),
          onAccept: (value) => accepted = value,
          autoInsertComma: false,
        );
    expect(key(LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter), false);
    controller.update(editing('bl'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    controller.move(-1);
    expect(controller.value.selectedIndex, 1);
    expect(
      key(LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown),
      true,
    );
    expect(controller.value.selectedIndex, 0);
    expect(key(LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab), true);
    expect(accepted!.text, 'blue eyes');
    expect(key(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), false);
    controller.update(editing('bl'), locale: 'en');
    await tester.pump(const Duration(milliseconds: 120));
    expect(key(LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), true);
    expect(controller.value.visible, false);
  });
}
