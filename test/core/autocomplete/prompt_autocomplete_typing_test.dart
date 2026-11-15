import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_autocomplete_controller.dart';

import 'prompt_autocomplete_controller_test.dart' show candidates, editing;

void main() {
  late PromptAutocompleteController controller;
  late List<CompletionQuery> queries;
  setUp(() {
    queries = [];
    controller = PromptAutocompleteController(
      enabled: true,
      search: (query) async {
        queries.add(query);
        return candidates;
      },
    );
  });
  tearDown(() => controller.dispose());

  testWidgets(
    'external text and caret synchronization never requests completion',
    (t) async {
      controller.synchronize(editing('masterpiece, blue hair'));
      await t.pump(const Duration(milliseconds: 150));
      controller.synchronize(editing('masterpiece, blue hair', 15));
      await t.pump(const Duration(milliseconds: 150));
      expect(queries, isEmpty);
      expect(controller.value.visible, false);
    },
  );

  for (final prefix in [
    'masterpiece',
    'masterpiece ',
    'masterpiece, ',
    '<style>masterpiece</style>\n',
  ]) {
    testWidgets(
      'query and replacement begin at first new character after $prefix',
      (t) async {
        controller.synchronize(editing(prefix));
        controller.update(editing('${prefix}b'), locale: 'en');
        await t.pump(const Duration(milliseconds: 150));
        expect(queries, isEmpty);
        controller.update(editing('${prefix}bl'), locale: 'en');
        await t.pump(const Duration(milliseconds: 150));
        expect(queries.single.token, 'bl');
        expect(queries.single.replacementRange.start, prefix.length);
        expect(controller.value.anchorTextOffset, prefix.length);
        expect(controller.accept()!.text, '${prefix}blue eyes, ');
      },
    );
  }

  testWidgets(
    'IME preedit stays quiet and committed Chinese uses this input start',
    (t) async {
      const prefix = 'masterpiece, very aesthetic ';
      controller.synchronize(editing(prefix));
      for (final text in ['l', 'lan', '蓝眼']) {
        controller.update(
          editing('$prefix$text').copyWith(
            composing: TextRange(
              start: prefix.length,
              end: prefix.length + text.length,
            ),
          ),
          locale: 'zh',
        );
        await t.pump(const Duration(milliseconds: 150));
        expect(queries, isEmpty);
      }
      controller.update(
        editing(
          '$prefix蓝眼',
        ).copyWith(composing: const TextRange.collapsed(prefix.length + 2)),
        locale: 'zh',
      );
      await t.pump(const Duration(milliseconds: 150));
      expect(queries.single.token, '蓝眼');
      expect(queries.single.replacementRange.start, prefix.length);
      expect(controller.accept()!.text, '${prefix}blue eyes, ');
    },
  );

  testWidgets(
    'delete all new text dismisses; deleting old text does not search it',
    (t) async {
      const prefix = 'masterpiece';
      controller.synchronize(editing(prefix));
      controller.update(editing('${prefix}bl'), locale: 'en');
      await t.pump(const Duration(milliseconds: 150));
      expect(queries.single.token, 'bl');
      controller.update(editing(prefix), locale: 'en');
      await t.pump(const Duration(milliseconds: 150));
      expect(controller.value.visible, false);
      controller.update(editing('masterpiec'), locale: 'en');
      await t.pump(const Duration(milliseconds: 150));
      expect(queries.length, 1);
      controller.update(editing('masterpiec蓝'), locale: 'zh');
      await t.pump(const Duration(milliseconds: 150));
      expect(queries.last.token, '蓝');
      expect(queries.last.replacementRange.start, 10);
    },
  );

  testWidgets(
    'moving the caret cancels the old span; middle insertion preserves old suffix',
    (t) async {
      controller.synchronize(editing('masterpiece, solo'));
      controller.update(editing('masterpiece, solobl'), locale: 'en');
      await t.pump(const Duration(milliseconds: 150));
      controller.synchronize(editing('masterpiece, solobl', 5));
      await t.pump(const Duration(milliseconds: 150));
      expect(controller.value.visible, false);
      controller.update(editing('masteblrpiece, solobl', 7), locale: 'en');
      await t.pump(const Duration(milliseconds: 150));
      expect(queries.last.token, 'bl');
      expect(queries.last.replacementRange.start, 5);
      expect(queries.last.replacementRange.end, 7);
      expect(controller.accept()!.text, 'masteblue eyes, rpiece, solobl');
    },
  );

  testWidgets(
    'spaces within new phrases continue; commas start the next token',
    (t) async {
      controller.synchronize(editing('old text '));
      for (final suffix in ['hair', 'hair ', 'hair ea', 'hair ears, bl']) {
        controller.update(editing('old text $suffix'), locale: 'en');
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(queries.map((q) => q.token), ['hair', 'hair_ea', 'bl']);
      expect(
        queries.last.replacementRange.start,
        'old text hair ears, '.length,
      );
    },
  );

  testWidgets('existing weights and closing syntax survive partial insertion', (
    t,
  ) async {
    const prefix = 'masterpiece, 1.2::';
    controller.synchronize(editing('$prefix::', prefix.length));
    controller.update(
      editing('${prefix}bl::', prefix.length + 2),
      locale: 'en',
    );
    await t.pump(const Duration(milliseconds: 150));
    expect(queries.single.token, 'bl');
    expect(controller.accept()!.text, 'masterpiece, 1.2::blue eyes::, ');
  });
}
