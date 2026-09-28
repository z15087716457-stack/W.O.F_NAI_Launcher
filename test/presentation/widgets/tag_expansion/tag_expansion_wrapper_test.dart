import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
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
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/weight_adjust_toolbar.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';

void main() {
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
    await Hive.openBox(StorageKeys.historyBox, bytes: Uint8List(0));
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('typing stays quiet; Ctrl+click searches and inserts locally', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final catalog = _Source([_tag('blue_hair')]);
    final activeEvents = <bool>[];
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      catalog,
      onActiveChanged: activeEvents.add,
    );

    await tester.enterText(find.byKey(const Key('prompt-editor')), 'solo, ');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    expect(catalog.queries, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.idle();
    expect(activeEvents, contains(true));
    await tester.pump();
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
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
    final mouse = await _hover(tester, find.text('blue hair').first);
    await tester.tap(find.byTooltip('Insert tag').first);
    await mouse.removePointer();
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
    final hint = tester.getRect(
      find.byKey(const Key('tag-expansion-tab-hint')),
    );
    final limit = tester.getRect(
      find.byKey(const Key('tag-expansion-result-limit')),
    );
    final popup = tester.getRect(find.byKey(const Key('tag-expansion-popup')));
    expect(limit.left - hint.right, inInclusiveRange(10, 18));
    expect(popup.right - limit.right, lessThanOrEqualTo(2));
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

  testWidgets(
    'arrow keys navigate both result columns and search stays compact',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpEditor(
        tester,
        controller,
        focusNode,
        _Source([
          _tag('first_tag'),
          _tag('second_tag'),
          _tag('third_tag'),
          _tag('fourth_tag'),
          _tag('fifth_tag'),
        ]),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      final search = find.byKey(const Key('tag-expansion-search'));
      await tester.enterText(search, 'tag');
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();

      final searchField = tester.widget<TextField>(search);
      final title = tester.widget<Text>(find.text('first tag'));
      expect(searchField.style!.fontSize, greaterThan(title.style!.fontSize!));
      expect(
        searchField.style!.fontSize! - title.style!.fontSize!,
        lessThanOrEqualTo(2),
      );
      expect(find.text('Tab to complete: first tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Tab to complete: second tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(find.text('Tab to complete: fourth tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(find.text('Tab to complete: third tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(find.text('Tab to complete: first tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(find.text('Tab to complete: fifth tag'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Tab to complete: fifth tag'), findsOneWidget);
    },
  );

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

  testWidgets(
    'click opens wiki; hovered relation action opens the right panel',
    (tester) async {
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
      expect(find.byKey(const Key('tag-expansion-wiki-panel')), findsOneWidget);
      expect(find.text('A local description for blue hair.'), findsOneWidget);
      expect(related.queries, isEmpty);

      final mouse = await _hover(tester, find.text('blue hair').first);
      await tester.tap(find.byTooltip('Show related tags').first);
      await tester.pump();
      expect(related.queries.single.relatedTag, 'blue_hair');
      expect(
        find.byKey(const Key('tag-expansion-related-panel')),
        findsOneWidget,
      );
      expect(find.text('long hair'), findsOneWidget);
      await mouse.moveTo(tester.getCenter(find.text('long hair')));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(find.byTooltip('Insert tag').last);
      await mouse.removePointer();
      await tester.pump();
      expect(controller.text, 'long hair, ');
    },
  );

  testWidgets(
    'search results use two columns and wrap into one on narrow windows',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpEditor(
        tester,
        controller,
        focusNode,
        _Source([_tag('blue_hair'), _tag('green_hair'), _tag('red_hair')]),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'hair',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();

      final first = tester.getTopLeft(find.text('blue hair'));
      final second = tester.getTopLeft(find.text('green hair'));
      final third = tester.getTopLeft(find.text('red hair'));
      expect(second.dy, first.dy);
      expect(second.dx, greaterThan(first.dx));
      expect(third.dy, greaterThan(first.dy));
      expect(third.dy - first.dy, lessThan(55));
    },
  );

  testWidgets(
    'long titles grow a whole paired row and counts align at the top',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      const longName =
          'extremely_detailed_intricate_background_with_many_small_elements';
      await _pumpEditor(
        tester,
        controller,
        focusNode,
        _Source([
          _tag(longName, postCount: 1234567),
          _tag('short_tag'),
          _tag('next_row'),
        ]),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'tag',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();

      final title = find.text(longName.replaceAll('_', ' '));
      final first = tester.getTopLeft(title);
      final second = tester.getTopLeft(find.text('short tag'));
      final next = tester.getTopLeft(find.text('next row'));
      final count = tester.getTopRight(find.text('1.2m'));
      final popup = tester.getRect(
        find.byKey(const Key('tag-expansion-popup')),
      );
      expect(tester.getSize(title).height, greaterThan(25));
      expect(second.dy, closeTo(first.dy, 2));
      expect(next.dy - first.dy, greaterThanOrEqualTo(60));
      expect(count.dy, closeTo(first.dy, 3));
      expect(count.dx, closeTo(popup.left + popup.width / 2, 14));
    },
  );

  testWidgets('result limit controls main search and persists', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final catalog = _Source([_tag('blue_hair')]);
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(tester, controller, focusNode, catalog);
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
    expect(catalog.queries.last.limit, 40);

    await tester.tap(find.byKey(const Key('tag-expansion-result-limit')));
    await tester.pump();
    await tester.tap(find.text('12').last);
    await tester.pump();
    await tester.pump();
    expect(catalog.queries.last.limit, 12);
    expect(
      Hive.box(
        StorageKeys.settingsBox,
      ).get(StorageKeys.tagExpansionResultLimit),
      12,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final nextController = TextEditingController();
    final nextFocus = FocusNode();
    addTearDown(nextController.dispose);
    addTearDown(nextFocus.dispose);
    await _pumpEditor(
      tester,
      nextController,
      nextFocus,
      _Source([_tag('solo')]),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(find.text('Result count 12'), findsOneWidget);
  });

  testWidgets('category icons sit beside titles and actions clear counts', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([
        _tag('white_background', postCount: 1500000),
        _tag('hakurei_reimu', category: TagCategory.character),
        _tag('touhou', category: TagCategory.copyright),
      ]),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'tag',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();

    final generalIcon = find.byKey(const Key('tag-expansion-category-general'));
    final characterIcon = find.byKey(
      const Key('tag-expansion-category-character'),
    );
    final copyrightIcon = find.byKey(
      const Key('tag-expansion-category-copyright'),
    );
    expect(generalIcon, findsOneWidget);
    expect(characterIcon, findsOneWidget);
    expect(copyrightIcon, findsOneWidget);
    expect(find.byTooltip('Character'), findsOneWidget);
    expect(find.byTooltip('Copyright'), findsOneWidget);
    expect(
      tester.widget<Icon>(generalIcon).color,
      isNot(tester.widget<Icon>(characterIcon).color),
    );
    final title = tester.getRect(find.text('white background'));
    final icon = tester.getRect(generalIcon);
    expect(icon.left - title.right, inInclusiveRange(0, 6));

    final mouse = await _hover(tester, find.text('white background'));
    final count = tester.getRect(find.text('1.5m'));
    final relatedAction = tester.getRect(
      find.byTooltip('Show related tags').first,
    );
    final insertAction = tester.getRect(find.byTooltip('Insert tag').first);
    expect(relatedAction.top, greaterThanOrEqualTo(count.bottom));
    expect(insertAction.top, greaterThanOrEqualTo(count.bottom));
    expect(relatedAction.height, lessThanOrEqualTo(20));
    await mouse.removePointer();
  });

  testWidgets('narrow window uses one result column', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair'), _tag('green_hair')]),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'hair',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('green hair')).dy,
      greaterThan(tester.getTopLeft(find.text('blue hair')).dy),
    );
    expect(find.text('Tab to complete: blue hair'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Tab to complete: blue hair'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('Tab to complete: green hair'), findsOneWidget);
  });

  testWidgets(
    'wiki uses natural height and caps long articles with scrolling',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpEditor(
        tester,
        controller,
        focusNode,
        _Source([_tag('short_tag'), _tag('long_tag')]),
        wiki: _Wiki({
          'short_tag': 'Short description.',
          'long_tag': List.filled(250, 'Long article sentence.').join(' '),
        }),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'tag',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();

      await tester.tap(find.text('short tag'));
      await tester.pump();
      await tester.pump();
      final shortHeight = tester
          .getSize(find.byKey(const Key('tag-expansion-wiki-panel')))
          .height;
      await tester.tap(find.text('long tag'));
      await tester.pump();
      await tester.pump();
      final longHeight = tester
          .getSize(find.byKey(const Key('tag-expansion-wiki-panel')))
          .height;
      expect(longHeight, greaterThan(shortHeight));
      expect(longHeight, lessThanOrEqualTo(230));
      expect(
        find.byKey(const Key('tag-expansion-wiki-scroll')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Ctrl+drag sends selected text to local related search', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, solo');
    final focusNode = FocusNode();
    final related = _Source([_tag('long_hair')]);
    final activeEvents = <bool>[];
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      related: related,
      onActiveChanged: activeEvents.add,
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
    // Settle the selected text before release to mirror a slow mouse drag.
    await tester.pump();
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    expect(controller.selection.isCollapsed, isFalse);
    await gesture.up();
    await tester.idle();
    expect(activeEvents, contains(true));
    await tester.pump();
    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
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

  testWidgets(
    'Ctrl secondary click and cancelled drag do not open the picker',
    (tester) async {
      final controller = TextEditingController(text: 'blue hair, solo');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await _pumpEditor(tester, controller, focusNode, _Source(const []));
      final target = tester.getCenter(find.byKey(const Key('prompt-editor')));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final secondary = await tester.startGesture(
        target,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await secondary.up();
      await tester.pump();
      expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);

      final cancelled = await tester.startGesture(
        target,
        kind: PointerDeviceKind.mouse,
      );
      await cancelled.moveBy(const Offset(24, 0));
      await cancelled.cancel();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
    },
  );

  testWidgets('Ctrl drag opens tag picker without the weight toolbar', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'blue hair, solo');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source(const []),
      related: _Source([_tag('long_hair')]),
      includeWeightToolbar: true,
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
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await gesture.up();
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(find.byKey(const Key('tag-expansion-popup')), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(controller.text, 'blue hair, solo');
    await tester.pump(const Duration(milliseconds: 250));
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
          tagWikiRepositoryProvider.overrideWithValue(_Wiki()),
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
  TagWikiRepository? wiki,
  bool enabled = true,
  bool includeWeightToolbar = false,
  ValueChanged<bool>? onActiveChanged,
}) async {
  final service = _service(catalog, related: related);
  Widget editor = TagExpansionWrapper(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    onActiveChanged: onActiveChanged,
    child: TextField(
      key: const Key('prompt-editor'),
      controller: controller,
      focusNode: focusNode,
    ),
  );
  if (includeWeightToolbar) {
    editor = WeightAdjustToolbarWrapper(
      controller: controller,
      focusNode: focusNode,
      wheelModifier: PromptWeightScrollModifier.alt,
      child: editor,
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localTagExpansionServiceProvider.overrideWithValue(service),
        tagWikiRepositoryProvider.overrideWithValue(wiki ?? _Wiki()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: SizedBox(width: 400, height: 80, child: editor)),
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

CompletionCandidate _tag(
  String name, {
  int postCount = 100,
  TagCategory category = TagCategory.general,
}) => CompletionCandidate(
  canonicalTag: name,
  category: category,
  postCount: postCount,
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

class _Wiki implements TagWikiRepository {
  _Wiki([this.bodies = const {}]);

  final Map<String, String> bodies;

  @override
  Future<TagWikiEntry?> find(String tag) async => TagWikiEntry(
    tag: tag,
    body: bodies[tag] ?? 'A local description for ${tag.replaceAll('_', ' ')}.',
    sourceUrl: '',
  );
}

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 120));
  return mouse;
}
