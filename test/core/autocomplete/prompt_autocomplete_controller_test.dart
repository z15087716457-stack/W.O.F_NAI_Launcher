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
