import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import 'package:nai_launcher/presentation/utils/text_editing_projection.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/inline_prompt_readings.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import 'inline_prompt_readings_test.dart' as fixture;

const longSource =
    'game, ruins, A gameplay screenshot from a beautiful Japanese post-apocalyptic fantasy RPG '
    'about a lonely journey through a vast ancient world of colossal ruins reclaimed by nature. '
    'The girl is tiny against the enormous landscape. '
    'The game HUD is clean and minimal: thin white lines, small sans-serif labels, semi-transparent dark-gray panels.';

List<PromptReading> longReadings() => [
  for (final (source, reading) in const [
    ('game', '电子游戏'),
    ('ruins', '废墟'),
    (
      'A gameplay screenshot from a beautiful Japanese post-apocalyptic fantasy RPG',
      '一张精美的日式末日奇幻角色扮演游戏截图，采用细腻的画面表现，突出人物与巨大废墟景观之间的尺度差异。',
    ),
    (
      'about a lonely journey through a vast ancient world of colossal ruins reclaimed by nature.',
      '讲述一段孤独的旅程：穿越辽阔的古老世界，巨大的遗迹已被自然重新覆盖。',
    ),
    ('The girl is tiny against the enormous landscape.', '少女在宏大的景观中显得十分渺小。'),
    (
      'The game HUD is clean and minimal: thin white lines, small sans-serif labels, semi-transparent dark-gray panels.',
      '游戏界面清晰简约，采用细白线、小号无衬线标签，以及半透明的深灰色面板。所有信息完整显示，长译文按照当前栏宽正常换行。',
    ),
  ])
    PromptReading(
      start: longSource.indexOf(source),
      end: longSource.indexOf(source) + source.length,
      source: source,
      translation: reading,
      perSegment: true,
    ),
];

ReadingEditingController editor(WidgetTester t) =>
    t.widget<EditableText>(find.byType(EditableText)).controller
        as ReadingEditingController;

Rect glyphRect(WidgetTester t, int rawStart, int rawEnd) {
  final e = t
      .state<EditableTextState>(find.byType(EditableText))
      .renderEditable;
  final p = (e.text as SourceMappedTextSpan).projection;
  final boxes = e.getBoxesForSelection(
    TextSelection(
      baseOffset: p.toDisplay(rawStart),
      extentOffset: p.toDisplay(rawEnd, affinity: TextAffinity.upstream),
    ),
  );
  return MatrixUtils.transformRect(e.getTransformTo(null), boxes.last.toRect());
}

Finder labels() => find.byWidgetPredicate(
  (w) =>
      w is Row &&
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.startsWith('prompt-reading-'),
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('selection drag, word navigation and resize retain one editor', (
    t,
  ) async {
    final c = TextEditingController(text: longSource), focus = FocusNode();
    await fixture.pumpReadingEditor(t, c, longReadings(), focusNode: focus);
    final state = t.state<EditableTextState>(find.byType(EditableText));
    final from = glyphRect(t, 0, 1).center;
    final end = longSource.indexOf('about a lonely');
    final to = glyphRect(t, end, end + 1).center;
    final gesture = await t.startGesture(
      from,
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.moveTo(to);
    await gesture.up();
    await t.pump();
    expect(c.selection.isCollapsed, isFalse);
    expect(c.selection.start, lessThan(3));
    expect(c.selection.end, inInclusiveRange(end, end + 2));
    final projection = editor(t).projection;
    c.selection = const TextSelection.collapsed(offset: 0);
    await t.pump();
    expect(
      editor(t).projection,
      same(projection),
      reason: 'Moving the caret must reuse measured translation pairs',
    );
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(c.selection.extentOffset, inInclusiveRange(4, 6));
    final selection = c.selection;
    await fixture.pumpReadingEditor(
      t,
      c,
      longReadings(),
      focusNode: focus,
      width: 320,
      scale: 1.5,
    );
    expect(t.state<EditableTextState>(find.byType(EditableText)), same(state));
    expect(c.selection, selection);
    expect(labels(), findsNWidgets(6));
    await fixture.pumpReadingEditor(
      t,
      c,
      const [],
      focusNode: focus,
      width: 320,
      scale: 1.5,
    );
    expect(editor(t).text, longSource);
    expect(c.selection, selection);
    expect(labels(), findsNothing);
    await fixture.pumpReadingEditor(t, c, longReadings(), focusNode: focus);
    expect(labels(), findsNWidgets(6));
    expect(c.text, longSource);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.dispose();
    focus.dispose();
    await t.binding.setSurfaceSize(null);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets('read-only translated source cannot be cut by keyboard', (
    t,
  ) async {
    final c = TextEditingController(text: longSource);
    await fixture.pumpReadingEditor(t, c, longReadings(), readOnly: true);
    await t.tapAt(glyphRect(t, 0, 1).center);
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyX);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump();
    expect(c.text, longSource);
    expect(labels(), findsNWidgets(6));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await t.binding.setSurfaceSize(null);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets(
    'native keys copy, cut, paste and undo across annotation boundaries',
    (t) async {
      String clipboard = '';
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = TextEditingController(text: fixture.readingSource);
      final focus = FocusNode();
      await fixture.pumpReadingEditor(
        t,
        c,
        fixture.readingDocument().readings,
        focusNode: focus,
      );
      await t.showKeyboard(find.byType(TextField));
      await t.pump(const Duration(milliseconds: 600));
      c.selection = const TextSelection.collapsed(offset: 0);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(c.selection.extentOffset, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(c.selection.extentOffset, 0);
      final from = fixture.readingSource.indexOf('1boy');
      final to = fixture.readingSource.indexOf('blue eyes');
      c.selection = TextSelection(baseOffset: from, extentOffset: to);
      await t.pump();
      final modifier = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      Future<void> shortcut(LogicalKeyboardKey key) async {
        await t.sendKeyDownEvent(modifier);
        await t.sendKeyEvent(key);
        await t.sendKeyUpEvent(modifier);
        await t.pump(const Duration(milliseconds: 600));
      }

      await shortcut(LogicalKeyboardKey.keyC);
      expect(clipboard, fixture.readingSource.substring(from, to));
      await shortcut(LogicalKeyboardKey.keyX);
      expect(c.text, fixture.readingSource.replaceRange(from, to, ''));
      expect(c.text, isNot(contains('\uFFFC')));
      await shortcut(LogicalKeyboardKey.keyZ);
      expect(c.text, fixture.readingSource);
      expect(labels(), findsNWidgets(5));
      expect(find.text('银发'), findsOneWidget);
      c.selection = TextSelection(baseOffset: from, extentOffset: to);
      await t.pump();
      clipboard = 'new text 🐺';
      await shortcut(LogicalKeyboardKey.keyV);
      expect(c.text, fixture.readingSource.replaceRange(from, to, clipboard));
      expect(c.text, isNot(contains('\u2060')));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.macOS,
    }),
  );
  testWidgets(
    'native deletion, Enter, selection and emoji keep source offsets',
    (t) async {
      const original = 'silver hair, blue eyes 🐺';
      final c = TextEditingController(text: original), focus = FocusNode();
      final readings = [
        const PromptReading(
          start: 0,
          end: 11,
          source: 'silver hair',
          translation: '一头闪亮柔顺的银色长发',
          perSegment: true,
        ),
        const PromptReading(
          start: 13,
          end: 25,
          source: 'blue eyes 🐺',
          translation: '蓝眼睛的狼',
          perSegment: true,
        ),
      ];
      await fixture.pumpReadingEditor(t, c, readings, focusNode: focus);
      await t.showKeyboard(find.byType(TextField));
      c.selection = const TextSelection.collapsed(offset: 11);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pump();
      expect(c.text, 'silver hai, blue eyes 🐺');
      c.selection = const TextSelection.collapsed(offset: 10);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.delete);
      await t.pump();
      expect(c.text, 'silver hai blue eyes 🐺');
      c.selection = TextSelection.collapsed(offset: c.text.length);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pump();
      expect(c.text, 'silver hai blue eyes ');
      final view = editor(t), before = editor(t).value;
      t.testTextInput.updateEditingValue(
        before.copyWith(
          text: before.text.replaceRange(
            before.selection.start,
            before.selection.end,
            '\n',
          ),
          selection: TextSelection.collapsed(
            offset: before.selection.start + 1,
          ),
        ),
      );
      await t.pump();
      expect(c.text, 'silver hai blue eyes \n');
      expect(view.source.text, c.text);
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(
        c.selection,
        const TextSelection(
          baseOffset: 0,
          extentOffset: 7,
          isDirectional: true,
          affinity: TextAffinity.upstream,
        ),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  for (final width in [320.0, 640.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'long source and full translations occupy native layout width=$width scale=$scale',
        (t) async {
          final c = TextEditingController(text: longSource);
          final readings = longReadings();
          await fixture.pumpReadingEditor(
            t,
            c,
            readings,
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          expect(labels(), findsNWidgets(readings.length));
          final view = editor(t);
          final e = t
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          expect(e.text!.toPlainText(), view.text);
          expect(view.projection.source, longSource);
          expect(c.text, longSource);
          for (final (i, label) in labels().evaluate().indexed) {
            final r = readings[i], box = t.getRect(find.byWidget(label.widget));
            final last = glyphRect(t, r.end - 1, r.end);
            expect(
              box.top,
              greaterThanOrEqualTo(last.bottom - 1),
              reason: 'Translation must follow complete source',
            );
            expect(
              box.right,
              lessThanOrEqualTo(width + .1),
              reason: 'Caption $i: ${r.source}',
            );
            final text = find.descendant(
              of: find.byWidget(label.widget),
              matching: find.text(r.translation),
            );
            expect(text, findsOneWidget);
            final paragraph = t.renderObject<RenderParagraph>(text);
            expect(paragraph.didExceedMaxLines, isFalse);
            if (i >= 2 && i + 1 < readings.length) {
              final next = glyphRect(
                t,
                readings[i + 1].start,
                readings[i + 1].start + 1,
              );
              expect(
                next.top,
                greaterThanOrEqualTo(box.bottom - 1),
                reason: 'Next source must follow full translation',
              );
            }
          }
          final capture = Platform.environment['PAIRED_READING_CAPTURE'];
          if (capture != null) {
            await t.runAsync(() async {
              await Directory(capture).create(recursive: true);
              final b = t.renderObject<RenderRepaintBoundary>(
                find.byType(RepaintBoundary).first,
              );
              final image = await b.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$capture/long-$width-$scale.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await t.pumpWidget(const SizedBox());
          c.dispose();
          await t.binding.setSurfaceSize(null);
        },
      );
    }
  }
  testWidgets(
    'typing and composing update only source, never annotation markers',
    (t) async {
      final c = TextEditingController(text: longSource), focus = FocusNode();
      await fixture.pumpReadingEditor(t, c, longReadings(), focusNode: focus);
      await t.showKeyboard(find.byType(TextField));
      final state = t.state<EditableTextState>(find.byType(EditableText));
      c.selection = const TextSelection.collapsed(offset: 4);
      await t.pump();
      var v = editor(t);
      var before = v.value, at = before.selection.extentOffset;
      t.testTextInput.updateEditingValue(
        before.copyWith(
          text: before.text.replaceRange(at, at, 's'),
          selection: TextSelection.collapsed(offset: at + 1),
        ),
      );
      await t.pump();
      await t.pump();
      expect(c.text, longSource.replaceFirst('game', 'games'));
      expect(c.text, isNot(contains(ReadingEditingController.placeholder)));
      expect(c.text, isNot(contains(ReadingEditingController.joiner)));
      expect(
        t.state<EditableTextState>(find.byType(EditableText)),
        same(state),
      );
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      await t.pump();
      v = editor(t);
      before = v.value;
      at = before.selection.start;
      t.testTextInput.updateEditingValue(
        before.copyWith(
          text: before.text.replaceRange(
            before.selection.start,
            before.selection.end,
            'shijie',
          ),
          selection: TextSelection.collapsed(offset: at + 6),
          composing: TextRange(start: at, end: at + 6),
        ),
      );
      await t.pump();
      expect(c.text, startsWith('shijie,'));
      expect(c.value.composing, const TextRange(start: 0, end: 6));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
}
