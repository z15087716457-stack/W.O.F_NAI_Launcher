import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_meaning.dart';
import 'package:nai_launcher/core/autocomplete/cooccurrence_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/datasources/cooccurrence_data_source.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/utils/prompt_input_normalization.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_example_repository.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/weight_adjust_toolbar.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_linked_body.dart';
import 'package:nai_launcher/presentation/widgets/common/wiki_example_gallery.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/tag_meaning_fixtures.dart';
import '../../../helpers/wiki_image_fixtures.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
    await Hive.openBox(StorageKeys.historyBox, bytes: Uint8List(0));
  });

  tearDown(() async {
    await Hive.close();
  });

  for (final drag in [false, true]) {
    testWidgets(
      '${drag ? 'Ctrl+drag' : 'Ctrl+click'} uses shared frequency-weighted cooccurrence',
      (tester) async {
        final controller = TextEditingController(text: 'blue hair, solo');
        final focusNode = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focusNode.dispose);
        await _pumpEditor(
          tester,
          controller,
          focusNode,
          _Source(const []),
          related: CooccurrenceCompletionSource(
            _WeightedEdges(),
            catalog: _WeightedCatalog(),
          ),
        );
        await tester.tap(find.byKey(const Key('prompt-editor')));
        await tester.pump();
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        Offset caret(int offset) {
          final rect = editable.getLocalRectForCaret(
            TextPosition(offset: offset),
          );
          return editable.localToGlobal(Offset(rect.left + 1, rect.center.dy));
        }

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        final gesture = await tester.startGesture(
          caret(drag ? 0 : 4),
          kind: PointerDeviceKind.mouse,
        );
        if (drag) {
          await gesture.moveTo(caret(9));
          await tester.pump();
        }
        await gesture.up();
        await tester.pump();
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

        expect(find.text('hair ribbon'), findsOneWidget);
        expect(find.text('long hair'), findsOneWidget);
        final specific = tester.getTopLeft(find.text('hair ribbon'));
        final generic = tester.getTopLeft(find.text('long hair'));
        expect(
          specific.dy < generic.dy ||
              (specific.dy == generic.dy && specific.dx < generic.dx),
          isTrue,
        );
        expect(controller.text, 'blue hair, solo');
        if (drag) {
          expect(controller.selection.textInside(controller.text), 'blue hair');
        }
      },
    );
  }

  for (final (name, alignment, start, end, screen) in [
    ('caret near top', Alignment.topCenter, 4, 4, const Size(620, 510)),
    ('caret near bottom', Alignment.bottomCenter, 4, 4, const Size(620, 510)),
    (
      'forward multiline selection',
      Alignment.bottomCenter,
      0,
      16,
      const Size(620, 510),
    ),
    (
      'backward multiline selection',
      Alignment.topCenter,
      16,
      0,
      const Size(620, 510),
    ),
    (
      'limited space on both sides',
      Alignment.center,
      0,
      16,
      const Size(620, 510),
    ),
    (
      'tall selection beside a narrow panel',
      Alignment.center,
      0,
      16,
      const Size(620, 225),
    ),
    (
      'selection in a short narrow viewport',
      Alignment.center,
      0,
      16,
      const Size(340, 225),
    ),
  ]) {
    testWidgets('tag expansion keeps $name visible', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screen;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = TextEditingController(
        text: 'grey hair,\nwhite dress, solo',
      );
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await _pumpEditor(
        tester,
        controller,
        focus,
        _Source([for (var i = 0; i < 32; i++) _tag('grey_hair_$i')]),
        alignment: alignment,
        maxLines: 3,
      );
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      final field = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      Offset point(int offset) {
        final caret = field.getLocalRectForCaret(TextPosition(offset: offset));
        return field.localToGlobal(Offset(caret.left + 1, caret.center.dy));
      }

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      final gesture = await tester.startGesture(
        point(start),
        kind: PointerDeviceKind.mouse,
      );
      if (start != end) {
        await gesture.moveTo(point(end));
        await tester.pump();
      }
      await gesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      final selection = controller.selection;
      expect(selection.start, start < end ? start : end);
      expect(selection.end, start > end ? start : end);
      final rects = [
        field.getLocalRectForCaret(selection.extent),
        ...field.getBoxesForSelection(selection).map((b) => b.toRect()),
      ];
      final scrollViewport = find.byKey(
        const Key('tag-expansion-scroll-viewport'),
      );
      final popup = tester.getRect(
        scrollViewport.evaluate().isEmpty
            ? find.byKey(const Key('tag-expansion-popup'))
            : scrollViewport,
      );
      if (screen.width == 340) expect(scrollViewport, findsOneWidget);
      for (final rect in rects) {
        final source = Rect.fromPoints(
          field.localToGlobal(rect.topLeft),
          field.localToGlobal(rect.bottomRight),
        );
        if (alignment == Alignment.bottomCenter) {
          expect(popup.bottom, lessThanOrEqualTo(source.top - 7.9));
        } else if (alignment == Alignment.topCenter) {
          expect(popup.top, greaterThanOrEqualTo(source.bottom + 7.9));
        } else {
          expect(popup.overlaps(source.inflate(7.9)), isFalse);
        }
      }
      expect(popup.top, greaterThanOrEqualTo(8));
      expect(popup.bottom, lessThanOrEqualTo(screen.height - 8));
    });
  }

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

  testWidgets(
    'linked browsing searches once, syncs Wiki and restores the chain',
    (tester) async {
      final controller = TextEditingController(text: 'untouched draft');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final source = _Source([
        _tag('first_tag'),
        _tag('second_tag'),
        _tag('third_tag'),
      ]);
      final entries = {
        for (final item in source.results) item.canonicalTag: item,
      };
      await _pumpEditor(
        tester,
        controller,
        focusNode,
        source,
        links: WikiTagLinks(
          exactLookup: (names) async => {
            for (final name in names)
              if (entries[name] case final item?) name: item,
          },
        ),
        wiki: _Wiki({
          'first_tag': 'See second_tag.',
          'second_tag': 'See third_tag.',
          'third_tag': 'Third article.',
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
      await tester.tap(find.text('first tag'));
      await tester.pump();
      await tester.pump();
      final before = source.queries.length;
      tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap(entries['second_tag']!);
      await tester.pump();
      await tester.pump();
      expect(source.queries.length, before + 1);
      expect(source.queries.last.token, 'second_tag');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
            .controller!
            .text,
        'second tag',
      );
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        'See third_tag.',
      );
      tester
          .widget<WikiLinkedBody>(find.byType(WikiLinkedBody))
          .onTagTap(entries['third_tag']!);
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        'Third article.',
      );
      final searches = source.queries.length;
      await tester.tap(find.byKey(const Key('tag-expansion-back')));
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        'See third_tag.',
      );
      await tester.tap(find.byKey(const Key('tag-expansion-back')));
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
            .controller!
            .text,
        'tag',
      );
      expect(
        tester.widget<WikiLinkedBody>(find.byType(WikiLinkedBody)).body,
        'See second_tag.',
      );
      expect(source.queries.length, searches);
      expect(find.byKey(const Key('tag-expansion-back')), findsNothing);
      expect(controller.text, 'untouched draft');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long Wiki titles wrap and retain aligned action buttons', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    const longTag =
        'artoria_pendragon_(swimsuit_ruler)_(first_ascension)_(fate)';
    await _pumpEditor(tester, controller, focusNode, _Source([_tag(longTag)]));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.byKey(const Key('prompt-editor')));
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'artoria',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.tap(find.text(longTag.replaceAll('_', ' ')));
    await tester.pump();
    await tester.pump();
    final title = find.textContaining('Tag wiki ·');
    expect(tester.widget<Text>(title).maxLines, isNull);
    expect(tester.getSize(title).height, greaterThan(20));
    expect(find.byTooltip('Open in Tag Wiki'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery hosts receive a canonical tag without prompt syntax', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'existing query');
    final focusNode = FocusNode();
    final selected = <String>[];
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await _pumpEditor(
      tester,
      controller,
      focusNode,
      _Source([_tag('blue_hair')]),
      onTagSelected: selected.add,
    );

    await tester.enterText(find.byKey(const Key('prompt-editor')), 'draft');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);

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

    expect(selected, ['blue_hair']);
    expect(controller.text, 'draft');
    expect(find.byKey(const Key('tag-expansion-popup')), findsNothing);
  });

  testWidgets('space-separated gallery queries use the tag at the caret', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1girl blue_hair');
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
      splitOnSpaces: true,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('prompt-editor'))) +
          const Offset(170, 0),
    );
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(related.queries.single.relatedTag, 'blue_hair');
    expect(controller.text, '1girl blue_hair');
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
    expect(generalIcon, findsNothing);
    expect(characterIcon, findsOneWidget);
    expect(copyrightIcon, findsOneWidget);
    expect(find.byTooltip('Character'), findsOneWidget);
    expect(find.byTooltip('Copyright'), findsOneWidget);
    expect(
      tester.widget<Icon>(copyrightIcon).color,
      isNot(tester.widget<Icon>(characterIcon).color),
    );
    final title = tester.getRect(find.text('hakurei reimu'));
    final icon = tester.getRect(characterIcon);
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
      expect(longHeight, lessThanOrEqualTo(280));
      expect(
        find.byKey(const Key('tag-expansion-wiki-scroll')),
        findsOneWidget,
      );
    },
  );

  for (final (brightness, long) in [
    (Brightness.dark, false),
    (Brightness.light, false),
    (Brightness.dark, true),
  ]) {
    testWidgets(
      'compact meaning above Wiki body ${brightness.name} long=$long',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(1100, long ? 600 : 800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final controller = TextEditingController(text: 'underwear');
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        await _pumpEditor(
          tester,
          controller,
          focus,
          _Source([_tag('underwear')]),
          brightness: brightness,
          scale: long ? 1.5 : 1,
          meaning: (tag) async =>
              meaningFixture(tag, summary: long ? '完整显示的长释义。' * 60 : null),
          wiki: _Wiki({'underwear': 'Full article with examples and links.'}),
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(find.byKey(const Key('prompt-editor')));
        await tester.pump();
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.enterText(
          find.byKey(const Key('tag-expansion-search')),
          'under',
        );
        await tester.pump(const Duration(milliseconds: 170));
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('tag-expansion-results')),
            matching: find.text('underwear'),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        final panel = find.byKey(const Key('tag-expansion-wiki-panel'));
        expect(panel, findsOneWidget);
        final compact = find.descendant(
          of: panel,
          matching: find.byType(TagMeaning),
        );
        final body = find.text('Full article with examples and links.');
        expect(compact, findsOneWidget);
        expect(
          find.descendant(of: compact, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(find.text('Synonyms'), findsNothing);
        expect(
          tester.getRect(body).top,
          greaterThan(tester.getRect(compact).bottom),
        );
        expect(tester.getSize(panel).height, lessThanOrEqualTo(280));
        if (long) {
          final scroll = tester
              .widget<SingleChildScrollView>(
                find.byKey(const Key('tag-expansion-wiki-scroll')),
              )
              .controller!;
          expect(scroll.position.maxScrollExtent, greaterThan(0));
          await tester.drag(
            find.byKey(const Key('tag-expansion-wiki-scroll')),
            const Offset(0, -70),
          );
          await tester.pump();
          expect(scroll.offset, greaterThan(0));
          expect(tester.getRect(panel).bottom, lessThanOrEqualTo(600));
        }
        expect(controller.text, 'underwear');
        expect(tester.takeException(), isNull);
        await captureTagMeaning(
          tester,
          'wiki-compact-${brightness.name}${long ? '-long' : ''}',
        );
      },
    );
  }

  testWidgets(
    'Ctrl image preview toggles, switches in place, and closes with its owner',
    (tester) async {
      final interval = VisibilityDetectorController.instance.updateInterval;
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      addTearDown(
        () => VisibilityDetectorController.instance.updateInterval = interval,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 850);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = TextEditingController(text: 'keep this draft'),
          focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await _pumpEditor(
        tester,
        controller,
        focus,
        _Source([_tag('solo'), _tag('other')]),
        wiki: _Wiki({'solo': wikiImageSource, 'other': wikiImageSource}),
        images: WikiExampleRepository(
          fetchWiki: (_, {cancelToken}) async => null,
          fetchPosts: (ids, {cancelToken}) async =>
              ids.map((id) => wikiImageMetadata(id)).toList(),
          fetchAssets: (ids, {cancelToken}) async =>
              ids.map((id) => wikiImageMetadata(id, asset: true)).toList(),
        ),
        imageCache: await WikiImageFixtureCache.load(),
        translation: wikiImageTranslation,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const Key('prompt-editor')));
      await tester.pump();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      final sourcePosition = controller.selection.extent;
      final field = tester
          .state<EditableTextState>(
            find.descendant(
              of: find.byKey(const Key('prompt-editor')),
              matching: find.byType(EditableText),
            ),
          )
          .renderEditable;
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'solo',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('tag-expansion-results')),
          matching: find.text('solo'),
        ),
      );
      await settleWikiImageFixtures(tester);
      final thumbnail = find.byKey(const Key('wiki-example-open-11'));
      final preview = find.byKey(const Key('wiki-image-preview-panel'));
      final pane = find.byKey(const Key('tag-expansion-image-panel'));
      final root = find.byKey(const Key('tag-expansion-popup'));
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      expect(preview, findsOneWidget);
      expect(
        find.byKey(const Key('wiki-viewer'), skipOffstage: false),
        findsNothing,
      );
      expect(tester.getRect(preview).left, tester.getRect(pane).right + 3);
      expect(tester.getRect(preview).top, tester.getRect(root).top);
      expect(tester.getRect(preview).bottom, tester.getRect(pane).bottom);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('tag-expansion-search')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      for (final width in [736.0, 540.0, 1100.0]) {
        tester.view.physicalSize = Size(width, 850);
        await settleWikiImageFixtures(tester);
        expect(preview, findsOneWidget);
        expect(
          find.byKey(const Key('wiki-example-large-post:11:0')),
          findsOneWidget,
        );
        expect(tester.getRect(preview).right, lessThanOrEqualTo(width - 8));
        final caret = field.getLocalRectForCaret(sourcePosition);
        final protected = Rect.fromPoints(
          field.localToGlobal(caret.topLeft),
          field.localToGlobal(caret.bottomRight),
        ).inflate(7.9);
        for (final panel in [
          root,
          preview,
          find.byKey(const Key('tag-expansion-wiki-panel')),
          if (width >= 640) pane,
        ]) {
          expect(tester.getRect(panel).overlaps(protected), isFalse);
        }
        expect(tester.takeException(), isNull);
      }
      for (var i = 0; i < 6; i++) {
        await tester.tap(thumbnail);
        await settleWikiImageFixtures(tester);
        expect(preview, i.isEven ? findsNothing : findsOneWidget);
      }
      // Navigation uses this same pane and highlights the corresponding card.
      await tester.tap(find.byKey(const Key('wiki-viewer-next')));
      await settleWikiImageFixtures(tester);
      expect(
        find.byKey(const Key('wiki-example-large-asset:12:1')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<WikiExampleCard>(
              find.byKey(const Key('wiki-image-card-asset:12:1')),
            )
            .selected,
        isTrue,
      );
      // Clicking another thumbnail replaces the current picture, never stacks.
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      expect(preview, findsOneWidget);
      expect(
        find.byKey(const Key('wiki-example-large-post:11:0')),
        findsOneWidget,
      );
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      expect(preview, findsNothing);
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      await tester.enterText(
        find.byKey(const Key('tag-expansion-search')),
        'other',
      );
      await tester.pump(const Duration(milliseconds: 170));
      await tester.pump();
      expect(preview, findsNothing);
      expect(root, findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('tag-expansion-results')),
          matching: find.text('other'),
        ),
      );
      await settleWikiImageFixtures(tester);
      expect(preview, findsNothing);
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      await tester.tap(find.byKey(const Key('wiki-images-toggle')));
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(pane, findsNothing);
      await tester.tap(find.byKey(const Key('wiki-images-toggle')));
      await settleWikiImageFixtures(tester);
      await tester.tap(thumbnail);
      await settleWikiImageFixtures(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(root, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(root, findsNothing);
      expect(controller.text, 'keep this draft');
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final (width, screenHeight, locale, scale) in [
      (1300.0, 850.0, const Locale('zh'), 1.0),
      (1100.0, 850.0, const Locale('zh'), 1.0),
      (900.0, 600.0, const Locale('en'), 1.5),
      (736.0, 600.0, const Locale('zh'), 1.0),
      (540.0, 850.0, const Locale('en'), 1.5),
      (320.0, 850.0, const Locale('ja'), 1.0),
    ]) {
      testWidgets(
        'native image pane ${brightness.name} $width ${locale.languageCode}',
        (tester) async {
          // Deliver visibility before awaiting image IO; the fake test clock
          // cannot decode a newly visible thumbnail inside pumpAndSettle.
          final interval = VisibilityDetectorController.instance.updateInterval;
          VisibilityDetectorController.instance.updateInterval = Duration.zero;
          addTearDown(
            () =>
                VisibilityDetectorController.instance.updateInterval = interval,
          );
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, screenHeight);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final controller = TextEditingController(text: 'keep this draft'),
              focus = FocusNode();
          addTearDown(controller.dispose);
          addTearDown(focus.dispose);
          final images = WikiExampleRepository(
            fetchWiki: (_, {cancelToken}) async =>
                throw StateError('no online Wiki request'),
            fetchPosts: (ids, {cancelToken}) async =>
                ids.map((id) => wikiImageMetadata(id)).toList(),
            fetchAssets: (ids, {cancelToken}) async =>
                ids.map((id) => wikiImageMetadata(id, asset: true)).toList(),
          );
          await _pumpEditor(
            tester,
            controller,
            focus,
            _Source([_tag('solo')]),
            related: _Source([_tag('landscape')]),
            wiki: _Wiki({'solo': wikiImageSource}),
            images: images,
            imageCache: await WikiImageFixtureCache.load(),
            translation: wikiImageTranslation,
            brightness: brightness,
            locale: locale,
            scale: scale,
          );
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.tap(find.byKey(const Key('prompt-editor')));
          await tester.pump();
          await tester.pump();
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.enterText(
            find.byKey(const Key('tag-expansion-search')),
            'solo',
          );
          await tester.pump(const Duration(milliseconds: 170));
          await tester.pump();
          await tester.tap(
            find.descendant(
              of: find.byKey(const Key('tag-expansion-results')),
              matching: find.text('solo'),
            ),
          );
          await settleWikiImageFixtures(tester);
          final wiki = find.byKey(const Key('tag-expansion-wiki-panel'));
          final pane = find.byKey(const Key('tag-expansion-image-panel'));
          expect(pane, findsOneWidget);
          final body = tester
              .widget<WikiLinkedBody>(
                find
                    .descendant(of: wiki, matching: find.byType(WikiLinkedBody))
                    .first,
              )
              .body;
          expect(body, contains('保留这段判定说明'));
          expect(body, isNot(contains('post #11')));
          if (width >= 640) {
            expect(
              tester.getRect(pane).top,
              closeTo(tester.getRect(wiki).top, 1),
            );
            expect(
              tester.getRect(pane).left,
              greaterThan(tester.getRect(wiki).right),
            );
            expect(tester.getRect(pane).bottom, lessThanOrEqualTo(850));
          } else {
            expect(find.descendant(of: wiki, matching: pane), findsOneWidget);
            await tester.ensureVisible(pane);
            await settleWikiImageFixtures(tester);
            final viewport = find.byKey(const Key('tag-expansion-wiki-scroll'));
            expect(
              tester.getRect(pane).height,
              lessThanOrEqualTo(tester.getRect(viewport).height + 1),
            );
            expect(tester.getRect(pane).left, greaterThanOrEqualTo(0));
            expect(tester.getRect(pane).right, lessThanOrEqualTo(width));
          }
          expect(controller.text, 'keep this draft');
          expect(tester.takeException(), isNull);
          await captureWikiImageLayout(
            tester,
            tagMeaningBoundary,
            '${brightness.name}-${width.toInt()}-${locale.languageCode}',
          );
          if (width >= 640) {
            final mouse = await _hover(
              tester,
              find.descendant(
                of: find.byKey(const Key('tag-expansion-results')),
                matching: find.text('solo'),
              ),
            );
            final l = AppLocalizations.of(tester.element(wiki))!;
            await tester.tap(find.byTooltip(l.tagExpansion_showRelated).first);
            await settleWikiImageFixtures(tester);
            final related = find.byKey(
              const Key('tag-expansion-related-panel'),
            );
            expect(tester.getRect(related).left, tester.getRect(pane).left);
            expect(
              tester.getRect(related).bottom,
              lessThan(tester.getRect(pane).top),
            );
            expect(controller.text, 'keep this draft');
            await captureWikiImageLayout(
              tester,
              tagMeaningBoundary,
              '${brightness.name}-1100-related',
            );
            await mouse.removePointer();
          }
          final firstImage = find.byKey(const Key('wiki-example-open-11'));
          await tester.ensureVisible(firstImage);
          await settleWikiImageFixtures(tester);
          await tester.tap(firstImage);
          await settleWikiImageFixtures(tester);
          final preview = find.byKey(const Key('wiki-image-preview-panel'));
          expect(preview, findsOneWidget);
          expect(find.byKey(const Key('wiki-viewer')), findsNothing);
          final previewRect = tester.getRect(preview);
          expect(previewRect.left, greaterThanOrEqualTo(8));
          expect(previewRect.right, lessThanOrEqualTo(width - 8));
          expect(previewRect.top, greaterThanOrEqualTo(8));
          expect(previewRect.bottom, lessThanOrEqualTo(screenHeight - 8));
          if (width >= 882) {
            expect(previewRect.left, tester.getRect(pane).right + 3);
            expect(previewRect.bottom, tester.getRect(wiki).bottom);
          } else {
            expect(previewRect.top, greaterThan(tester.getRect(wiki).bottom));
          }
          expect(tester.takeException(), isNull);
          await captureWikiImageLayout(
            tester,
            tagMeaningBoundary,
            '${brightness.name}-${width.toInt()}-${locale.languageCode}-preview',
          );
          // Closing pictures restores their text; reopening reuses metadata.
          await tester.tap(find.byKey(const Key('wiki-images-toggle')));
          await tester.pumpAndSettle();
          expect(pane, findsNothing);
          expect(preview, findsNothing);
          final restored = tester
              .widget<WikiLinkedBody>(
                find
                    .descendant(of: wiki, matching: find.byType(WikiLinkedBody))
                    .first,
              )
              .body;
          expect(restored, contains('post #11'));
          expect(controller.text, 'keep this draft');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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
          autoTagTranslationProvider.overrideWith((_) => _LocalReadings()),
          tagMeaningProfileProvider.overrideWith((_, tag) async => null),
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
                config: const UnifiedPromptConfig(enableAutoFormat: true),
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
  WikiTagLinks? links,
  bool enabled = true,
  bool splitOnSpaces = false,
  bool includeWeightToolbar = false,
  Alignment alignment = Alignment.center,
  int maxLines = 1,
  ValueChanged<bool>? onActiveChanged,
  ValueChanged<String>? onTagSelected,
  Future<TagSemanticProfile?> Function(String)? meaning,
  Brightness? brightness,
  double scale = 1,
  WikiExampleRepository? images,
  WikiImageFixtureCache? imageCache,
  String? translation,
  Locale locale = const Locale('en'),
}) async {
  final service = _service(catalog, related: related);
  Widget editor = TagExpansionWrapper(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    splitOnSpaces: splitOnSpaces,
    onActiveChanged: onActiveChanged,
    onTagSelected: onTagSelected,
    child: TextField(
      key: const Key('prompt-editor'),
      maxLines: maxLines,
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
        autoTagTranslationProvider.overrideWith(
          (_) => _LocalReadings(translation),
        ),
        wikiExampleRepositoryProvider.overrideWithValue(
          images ??
              WikiExampleRepository(
                fetchWiki: (_, {cancelToken}) async => null,
                fetchPosts: (ids, {cancelToken}) async => [],
              ),
        ),
        if (imageCache != null)
          wikiExampleImageCacheProvider.overrideWithValue(imageCache),
        tagMeaningProfileProvider.overrideWith(
          (_, tag) async => meaning == null ? null : meaning(tag),
        ),
        localTagExpansionServiceProvider.overrideWithValue(service),
        tagWikiRepositoryProvider.overrideWithValue(wiki ?? _Wiki()),
        wikiTagLinksProvider.overrideWithValue(
          links ?? WikiTagLinks(exactLookup: (_) async => {}),
        ),
      ],
      child: MaterialApp(
        theme: brightness == null
            ? null
            : AppTheme.getTheme(AppStyle.geist, brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: tagMeaningBoundary, child: child!),
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: SizedBox(width: 400, height: 80, child: editor),
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
  relatedTags: related ?? _Source(const []),
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

class _WeightedCatalog extends TagCatalogRepository {
  @override
  Future<int> maximumPostCount() async => 10000;

  @override
  Future<Map<String, TagCatalogRecord>> recordsByCanonicalTag(
    Iterable<String> tags,
  ) async => {
    for (final tag in tags)
      tag: TagCatalogRecord(
        canonicalTag: tag,
        category: TagCategory.general,
        postCount: tag == 'long_hair' ? 10000 : 1000,
      ),
  };
}

class _WeightedEdges extends CooccurrenceDataSource {
  @override
  Future<Map<String, List<RelatedTag>>> getRelatedTagsBatch(
    List<String> tags, {
    int? limit = 10,
  }) async => {
    for (final tag in tags)
      tag: const [
        RelatedTag(tag: 'long_hair', count: 800),
        RelatedTag(tag: 'hair_ribbon', count: 100),
      ],
  };
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

class _LocalReadings extends ChangeNotifier
    implements AutoTagTranslationController {
  _LocalReadings([this.translation]);
  final String? translation;
  @override
  String? wikiFor(String tag) => translation;
  @override
  bool get enabled => false;
  @override
  int get activeRequests => 0;
  @override
  bool isTranslating(String tag) => false;
  @override
  bool isWikiTranslating(String tag) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump(const Duration(milliseconds: 120));
  return mouse;
}
