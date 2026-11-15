import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/widgets/prompt/nai_syntax_controller.dart';
import 'package:nai_launcher/presentation/utils/text_editing_projection.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/inline_prompt_readings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import '../../../../helpers/studio_capture_fonts.dart';

class _MemorySettings extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

const readingSource =
    '4::1girl, 1boy::, silver hair,\n\n1.4::soft lighting::, blue eyes';
PillDocument readingDocument([
  String source = readingSource,
  List<String>? labels,
]) {
  final batch = PromptTranslationBatch.prepare({
    'main': PillDocument(text: source, instances: const {}),
  }, mode: PromptTranslationMode.inline);
  final translations = labels ?? const ['1个女孩', '1个男孩', '银发', '柔和光线', '蓝眼'];
  return batch.buildFromGroups({
    'main': [
      for (final (i, item) in batch.segments['main']!.indexed)
        (
          start: item.start,
          end: item.end,
          zh: translations[i],
          marks: const <TranslationTagMark>[],
        ),
    ],
  }, mode: PromptTranslationMode.inline)['main']!;
}

Finder readingLabels() => find.byWidgetPredicate(
  (widget) =>
      widget is Row &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('prompt-reading-'),
);
Rect sourceRect(WidgetTester t, int start, int end) {
  final editable = t
      .state<EditableTextState>(find.byType(EditableText))
      .renderEditable;
  final box = editable
      .getBoxesForSelection(displaySelection(editable, start, end))
      .first;
  return MatrixUtils.transformRect(editable.getTransformTo(null), box.toRect());
}

TextSelection displaySelection(RenderEditable e, int start, int end) {
  final p = (e.text as SourceMappedTextSpan).projection;
  return TextSelection(
    baseOffset: p.toDisplay(start),
    extentOffset: p.toDisplay(end, affinity: TextAffinity.upstream),
  );
}

void expectSource(RenderEditable e, String source) {
  expect((e.text as SourceMappedTextSpan).projection.source, source);
  expect(
    e.text!.toPlainText(),
    (e.text as SourceMappedTextSpan).projection.text,
  );
}

// Exercise the actual platform buffer while expressing fixture edits in source
// coordinates. Generated annotations are retained outside the edited range.
void updateSourceInput(WidgetTester t, TextEditingValue after) {
  final view =
      t.widget<EditableText>(find.byType(EditableText)).controller
          as ReadingEditingController;
  final before = view.source.value, p = view.projection;
  var prefix = 0, suffix = 0;
  while (prefix < before.text.length &&
      prefix < after.text.length &&
      before.text[prefix] == after.text[prefix]) {
    prefix++;
  }
  while (suffix < before.text.length - prefix &&
      suffix < after.text.length - prefix &&
      before.text[before.text.length - 1 - suffix] ==
          after.text[after.text.length - 1 - suffix]) {
    suffix++;
  }
  final end = before.text.length - suffix;
  final insertedEnd = after.text.length - suffix;
  final from = prefix == 0 ? 0 : p.toDisplay(prefix);
  final to = end == before.text.length
      ? p.text.length
      : p.toDisplay(end, affinity: TextAffinity.upstream);
  final inserted = after.text.substring(prefix, insertedEnd);
  int position(int raw) {
    if (raw < 0) return raw;
    if (raw < prefix) return p.toDisplay(raw);
    if (raw <= insertedEnd) return from + raw - prefix;
    return p.toDisplay(raw - (insertedEnd - end)) +
        inserted.length -
        (to - from);
  }

  t.testTextInput.updateEditingValue(
    TextEditingValue(
      text: p.text.replaceRange(from, to, inserted),
      selection: after.selection.copyWith(
        baseOffset: position(after.selection.baseOffset),
        extentOffset: position(after.selection.extentOffset),
      ),
      composing: after.composing.isValid
          ? TextRange(
              start: position(after.composing.start),
              end: position(after.composing.end),
            )
          : TextRange.empty,
    ),
  );
}

const semanticSource =
    '<artist>\n1.3::artist:alpha::, artist:beta\n</artist>, <style>\n'
    'soft lighting; warm colors\n</style>\n'
    'Subject: a girl; Camera: from above\n'
    'She opens a book, then looks left.';
List<PromptReading> semanticReadings() => [
  for (final (anchor, label) in const [
    ('artist:alpha', '画师：alpha'),
    ('artist:beta', '画师：beta'),
    ('soft lighting', '柔和光线'),
    ('warm colors', '暖色调'),
    ('Subject: a girl', '主体：一个女孩'),
    ('Camera: from above', '镜头：俯视'),
    ('She opens a book, then looks left.', '她翻开书，然后看向左侧'),
  ])
    PromptReading(
      start: semanticSource.indexOf(anchor),
      end: semanticSource.indexOf(anchor) + anchor.length,
      source: anchor,
      translation: label,
      perSegment: true,
    ),
];

Future<void> pumpReadingEditor(
  WidgetTester t,
  TextEditingController controller,
  List<PromptReading> readings, {
  double width = 440,
  double scale = 1,
  int? maxLines,
  FocusNode? focusNode,
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('zh'),
  double fontSize = 14,
  bool readOnly = false,
}) async {
  await t.binding.setSurfaceSize(Size(width, 900));
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_MemorySettings()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeAnimationDuration: Duration.zero,
        theme: AppTheme.getTheme(AppStyle.geist, brightness),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => UiScale(scale: scale, child: child!),
        home: Scaffold(
          body: UnifiedPromptInput(
            controller: controller,
            focusNode: focusNode,
            readings: readings,
            fitContent: true,
            maxLines: maxLines,
            textStyle: TextStyle(fontSize: fontSize, height: 1.5),
            config: UnifiedPromptConfig(
              embedded: true,
              enableAutoFormat: false,
              readOnly: readOnly,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final dark in [true, false]) {
    for (final width in [320.0, 736.0]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'semantic captions align independently of commas dark=$dark width=$width scale=$scale',
          (t) async {
            final controller = TextEditingController(text: semanticSource);
            final readings = semanticReadings();
            await pumpReadingEditor(
              t,
              controller,
              readings,
              width: width,
              scale: scale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );
            expect(readingLabels(), findsNWidgets(readings.length));
            final editable = t
                .state<EditableTextState>(find.byType(EditableText))
                .renderEditable;
            for (final (i, label) in readingLabels().evaluate().indexed) {
              final rect = t.getRect(find.byWidget(label.widget));
              final reading = readings[i];
              final boxes = editable.getBoxesForSelection(
                TextSelection(
                  baseOffset: displayPositionForEditable(
                    editable,
                    TextPosition(offset: reading.start),
                  ).offset,
                  extentOffset: displayPositionForEditable(
                    editable,
                    TextPosition(
                      offset: reading.end,
                      affinity: TextAffinity.upstream,
                    ),
                  ).offset,
                ),
              );
              final lastTop = boxes.last.top;
              final lastRow = boxes.where((b) => (b.top - lastTop).abs() < 1);
              final source = MatrixUtils.transformRect(
                editable.getTransformTo(null),
                Rect.fromLTRB(
                  lastRow.map((b) => b.left).reduce(math.min),
                  lastTop,
                  lastRow.map((b) => b.right).reduce(math.max),
                  lastRow.map((b) => b.bottom).reduce(math.max),
                ),
              );
              expect(rect.left, closeTo(source.left, .02));
              expect(rect.top - source.bottom, closeTo(3 * scale, .02));
              expect(rect.right, lessThanOrEqualTo(width + .02));
            }
            expectSource(editable, semanticSource);
            expect(controller.text, semanticSource);
            expect(t.takeException(), isNull);
            final capture = Platform.environment['SEMANTIC_READING_CAPTURE'];
            if (capture != null) {
              await t.runAsync(() async {
                await Directory(capture).create(recursive: true);
                final boundary = t.renderObject<RenderRepaintBoundary>(
                  find.byType(RepaintBoundary).first,
                );
                final image = await boundary.toImage();
                final png = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '$capture/dark-$dark-width-$width-scale-$scale.png',
                ).writeAsBytes(png!.buffer.asUint8List());
                image.dispose();
              });
            }
            await t.pumpWidget(const SizedBox());
            controller.dispose();
            await t.binding.setSurfaceSize(null);
          },
        );
      }
    }
  }
  testWidgets(
    'semantic source edits keep the editor, pending state and neighboring captions',
    (t) async {
      final controller = TextEditingController(text: semanticSource),
          focus = FocusNode();
      var readings = semanticReadings();
      await pumpReadingEditor(t, controller, readings, focusNode: focus);
      final state = t.state<EditableTextState>(find.byType(EditableText));
      final start = semanticSource.indexOf('warm colors');
      await t.tapAt(sourceRect(t, start, start + 4).center);
      await t.pump();
      expect(focus.hasFocus, isTrue);
      await t.showKeyboard(find.byType(TextField));
      final edited = semanticSource.replaceFirst('warm colors', 'cool colors');
      updateSourceInput(
        t,
        TextEditingValue(
          text: edited,
          selection: TextSelection.collapsed(offset: start + 4),
        ),
      );
      readings = PromptReading.rebase(readings, semanticSource, edited);
      await pumpReadingEditor(t, controller, readings, focusNode: focus);
      expect(
        t.state<EditableTextState>(find.byType(EditableText)),
        same(state),
      );
      expect(find.text('待更新'), findsOneWidget);
      expect(find.text('暖色调'), findsNothing);
      expect(find.text('柔和光线'), findsOneWidget);
      final deleted = edited.replaceFirst('cool colors', '');
      updateSourceInput(
        t,
        TextEditingValue(
          text: deleted,
          selection: TextSelection.collapsed(offset: start),
        ),
      );
      readings = PromptReading.rebase(readings, edited, deleted);
      await pumpReadingEditor(t, controller, readings, focusNode: focus);
      expect(find.text('待更新'), findsNothing);
      expect(readingLabels(), findsNWidgets(6));
      expect(find.text('镜头：俯视'), findsOneWidget);
      expect(controller.text, deleted);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'a semantic anchor before closing weights keeps the blank-line caret below its caption',
    (t) async {
      const source = '1.4::soft lighting::,\n\n';
      final controller = TextEditingController(text: source);
      await pumpReadingEditor(t, controller, const [
        PromptReading(
          start: 5,
          end: 18,
          source: 'soft lighting',
          translation: '柔和光线',
          perSegment: true,
        ),
      ]);
      final e = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final caret = e.getLocalRectForCaret(
        displayPositionForEditable(
          e,
          TextPosition(offset: source.indexOf('\n') + 1),
        ),
      );
      final rect = MatrixUtils.transformRect(e.getTransformTo(null), caret);
      expect(
        rect.top,
        greaterThanOrEqualTo(t.getRect(readingLabels().first).bottom + 1),
      );
      expect(caret.height, lessThanOrEqualTo(23));
      expectSource(e, source);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  for (final weighted in ['2::soft lighting::', '2::soft lighting']) {
    for (final scale in [1.0, 1.5]) {
      for (final suffix in ['\n', '\n\n', '\nnew text']) {
        testWidgets(
          'manual newline caret clears the preceding reading scale=$scale suffix=${suffix.length} weighted=$weighted',
          (t) async {
            final source = weighted + suffix;
            final controller = TextEditingController(text: weighted),
                focus = FocusNode();
            await pumpReadingEditor(
              t,
              controller,
              [
                PromptReading(
                  start: 0,
                  end: weighted.length,
                  source: weighted,
                  translation: '柔和光线',
                  perSegment: true,
                ),
              ],
              focusNode: focus,
              scale: scale,
              width: 320,
            );
            focus.requestFocus();
            await t.pump();
            await t.pump();
            final before = t.state<EditableTextState>(
              find.byType(EditableText),
            );
            await t.showKeyboard(find.byType(TextField));
            updateSourceInput(
              t,
              TextEditingValue(
                text: source,
                selection: TextSelection.collapsed(offset: weighted.length + 1),
              ),
            );
            await t.pump();
            await t.pump();
            expect(
              t.state<EditableTextState>(find.byType(EditableText)),
              same(before),
            );
            final e = t
                .state<EditableTextState>(find.byType(EditableText))
                .renderEditable;
            final caret = e.getLocalRectForCaret(
              displayPositionForEditable(
                e,
                TextPosition(offset: weighted.length + 1),
              ),
            );
            final visible = MatrixUtils.transformRect(
              e.getTransformTo(null),
              caret,
            );
            final caption = t.getRect(readingLabels().first);
            expect(
              visible.top,
              greaterThanOrEqualTo(caption.bottom + scale),
              reason:
                  'The new source row must begin below the complete caption',
            );
            // macOS uses the ordinary 21px strut plus its native 2px caret margin.
            expect(caret.height, lessThanOrEqualTo(23));
            if (suffix == '\n\n') {
              final next = e.getLocalRectForCaret(
                displayPositionForEditable(
                  e,
                  TextPosition(offset: weighted.length + 2),
                ),
              );
              expect(
                next.top - caret.top,
                inInclusiveRange(20.0, 23.0),
                reason: 'An empty source line keeps its ordinary height',
              );
            }
            expectSource(e, source);
            expect(controller.text, source);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            controller.dispose();
            focus.dispose();
            await t.binding.setSurfaceSize(null);
          },
          variant: const TargetPlatformVariant({
            TargetPlatform.windows,
            TargetPlatform.macOS,
          }),
        );
      }
    }
  }
  for (final scale in [1.0, 1.5]) {
    testWidgets('long readings leave closing symbols compact scale=$scale', (
      t,
    ) async {
      const source = '1.4::pov::\n\n1.4::pov, blue eyes::';
      final controller = TextEditingController(text: source);
      final document = readingDocument(source, const [
        '第一人称视角',
        '第一人称视角',
        '蓝眼',
      ]);
      await pumpReadingEditor(
        t,
        controller,
        document.readings,
        width: 320,
        scale: scale,
      );
      final e = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final firstClosing = source.indexOf('pov') + 3;
      final offsets = [
        for (var i = firstClosing; i <= firstClosing + 2; i++)
          e
              .getLocalRectForCaret(
                displayPositionForEditable(e, TextPosition(offset: i)),
              )
              .left,
      ];
      final caption = t.renderObject<RenderParagraph>(
        find.text('第一人称视角').first,
      );
      expect(caption.didExceedMaxLines, isFalse);
      await pumpReadingEditor(
        t,
        controller,
        const [],
        width: 320,
        scale: scale,
      );
      final plain = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      for (final (i, x) in offsets.indexed) {
        expect(
          plain
              .getLocalRectForCaret(
                displayPositionForEditable(
                  plain,
                  TextPosition(offset: firstClosing + i),
                ),
              )
              .left,
          closeTo(x, .01),
          reason: 'The closing colons must keep their original advance',
        );
      }
      expect(controller.text, source);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    });
  }
  for (final openWeight in [false, true]) {
    for (final dark in [true, false]) {
      for (final scale in [1.0, 1.5]) {
        for (final width in [320.0, 736.0]) {
          testWidgets(
            'weight fills stay inside source rows dark=$dark scale=$scale width=$width open=$openWeight',
            (t) async {
              const closedSource =
                  '0.4::artist:alpha, artist:beta::,\n[[artist:gamma]], {artist:delta},\n\n4::1girl, 1boy::,\n\n1.4::pov::,\n2::soft lighting, blue eyes, silver hair, detailed background::';
              final source =
                  closedSource +
                  (openWeight
                      ? '\n\n1.8::soft colors,\n\nloose sleeves::'
                      : '');
              final batch = PromptTranslationBatch.prepare({
                'main': PillDocument(text: source, instances: const {}),
              }, mode: PromptTranslationMode.inline);
              final document = batch.buildFromGroups({
                'main': [
                  for (final (i, unit) in batch.segments['main']!.indexed)
                    (
                      start: unit.start,
                      end: unit.end,
                      zh: '译文$i',
                      marks: const <TranslationTagMark>[],
                    ),
                ],
              }, mode: PromptTranslationMode.inline)['main']!;
              final controller = TextEditingController(text: source);
              await pumpReadingEditor(
                t,
                controller,
                document.readings,
                width: width,
                scale: scale,
                brightness: dark ? Brightness.dark : Brightness.light,
              );
              final state = t.state<EditableTextState>(
                find.byType(EditableText),
              );
              expect(
                state.renderEditable.selection?.isCollapsed ?? true,
                isTrue,
              );
              final boundary = t.renderObject<RenderRepaintBoundary>(
                find.byType(RepaintBoundary).first,
              );
              final transform = state.renderEditable.getTransformTo(boundary);
              final rows = <Rect>[];
              for (var offset = 0; offset < source.length; offset++) {
                if (source[offset] == '\n') continue;
                for (final box in state.renderEditable.getBoxesForSelection(
                  displaySelection(state.renderEditable, offset, offset + 1),
                )) {
                  rows.add(
                    MatrixUtils.transformRect(
                      transform,
                      box.toRect(),
                    ).inflate(1),
                  );
                }
              }
              final theme = Theme.of(t.element(find.byType(TextField)));
              final syntax = NaiSyntaxController(text: source);
              final colors = <Color>{};
              void collect(InlineSpan span) {
                if (span is! TextSpan) return;
                final color = span.style?.backgroundColor;
                if (color != null && color.a > 0) {
                  colors.add(
                    Color.alphaBlend(color, theme.scaffoldBackgroundColor),
                  );
                }
                for (final child in span.children ?? const <InlineSpan>[]) {
                  collect(child);
                }
              }

              collect(
                syntax.buildTextSpan(
                  context: t.element(find.byType(TextField)),
                  style: state.widget.style,
                  withComposing: false,
                ),
              );
              syntax.dispose();
              expect(colors, isNotEmpty);
              await t.runAsync(() async {
                final image = await boundary.toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                );
                final bytes = data!.buffer.asUint8List();
                final firstUnit = state.renderEditable
                    .getBoxesForSelection(
                      displaySelection(
                        state.renderEditable,
                        0,
                        source.indexOf(',') + 1,
                      ),
                    )
                    .map((box) => box.toRect())
                    .reduce((a, b) => a.expandToInclude(b));
                final band = MatrixUtils.transformRect(transform, firstUnit);
                final expected = Color.alphaBlend(
                  NaiSyntaxColors.fromTheme(theme).weightBottom,
                  theme.scaffoldBackgroundColor,
                );
                final sampleY = (band.top + scale).ceil();
                for (
                  var x = (band.left + scale).ceil();
                  x < (band.right - scale).floor();
                  x++
                ) {
                  final at = (sampleY * image.width + x) * 4;
                  expect(
                    bytes[at],
                    closeTo((expected.r * 255).round(), 1),
                    reason:
                        'No fractional seam inside a continuous weight range',
                  );
                  expect(bytes[at + 1], closeTo((expected.g * 255).round(), 1));
                  expect(bytes[at + 2], closeTo((expected.b * 255).round(), 1));
                }
                var inside = 0, outside = 0;
                for (var y = 0; y < image.height; y++) {
                  for (var x = 0; x < image.width; x++) {
                    final index = (y * image.width + x) * 4;
                    if (!colors.any(
                      (c) =>
                          (bytes[index] - (c.r * 255).round()).abs() <= 1 &&
                          (bytes[index + 1] - (c.g * 255).round()).abs() <= 1 &&
                          (bytes[index + 2] - (c.b * 255).round()).abs() <= 1,
                    )) {
                      continue;
                    }
                    if (rows.any((r) => r.contains(Offset(x + .5, y + .5)))) {
                      inside++;
                    } else {
                      outside++;
                    }
                  }
                }
                final capture =
                    Platform.environment['WEIGHT_BACKGROUND_CAPTURE'];
                if (capture != null) {
                  final png = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await File(
                    '$capture/dark-$dark-scale-$scale-width-$width-open-$openWeight.png',
                  ).writeAsBytes(png!.buffer.asUint8List());
                }
                image.dispose();
                expect(
                  inside,
                  greaterThan(80),
                  reason: 'Weight colors must remain visible on the source',
                );
                expect(
                  outside,
                  0,
                  reason: 'Weight fills must not enter captions or empty lines',
                );
              });
              expect(controller.text, source);
              expect(t.takeException(), isNull);
              await t.pumpWidget(const SizedBox());
              controller.dispose();
              await t.binding.setSurfaceSize(null);
            },
          );
        }
      }
    }
  }
  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 736.0]) {
        testWidgets(
          '$locale dark=$dark width=$width fits independent readings',
          (t) async {
            final controller = TextEditingController(text: readingSource);
            await pumpReadingEditor(
              t,
              controller,
              readingDocument().readings,
              width: width,
              locale: locale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );
            expect(readingLabels(), findsNWidgets(5));
            final originals = [
              '1girl',
              '1boy',
              'silver hair',
              'soft lighting',
              'blue eyes',
            ];
            for (final (i, label) in readingLabels().evaluate().indexed) {
              final rect = t.getRect(find.byWidget(label.widget));
              final start = readingSource.indexOf(originals[i]);
              final source = sourceRect(t, start, start + originals[i].length);
              expect(rect.left, closeTo(source.left, .01));
              expect(rect.top - source.bottom, closeTo(3, .01));
              expect(rect.right, lessThanOrEqualTo(width + .01));
              expect(source.height, lessThan(24));
            }
            expect(sourceRect(t, 0, 1).top, lessThan(4));
            expect(controller.text, readingSource);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            controller.dispose();
            await t.binding.setSurfaceSize(null);
          },
        );
      }
    }
  }
  testWidgets('source edits in place while read-only captions remain visible', (
    t,
  ) async {
    final controller = TextEditingController(text: readingSource),
        focus = FocusNode();
    await pumpReadingEditor(
      t,
      controller,
      readingDocument().readings,
      focusNode: focus,
    );
    final state = t.state<EditableTextState>(
      find.byType(EditableText, skipOffstage: false),
    );
    final start = readingSource.indexOf('soft lighting');
    await t.tapAt(sourceRect(t, start, start + 4).center);
    await t.pump();
    expect(focus.hasFocus, isTrue);
    expect(readingLabels(), findsNWidgets(5));
    expect(t.state<EditableTextState>(find.byType(EditableText)), same(state));
    expect(
      controller.selection.extentOffset,
      inInclusiveRange(
        readingSource.indexOf('soft lighting'),
        readingSource.indexOf('soft lighting') + 17,
      ),
    );
    focus.unfocus();
    await t.pump();
    expect(readingLabels(), findsNWidgets(5));
    expect(
      t.state<EditableTextState>(
        find.byType(EditableText, skipOffstage: false),
      ),
      same(state),
    );
    await t.pumpWidget(const SizedBox());
    controller.dispose();
    focus.dispose();
    await t.binding.setSurfaceSize(null);
  });
  testWidgets(
    'native caret, empty lines, copy and IME use only unchanged original text',
    (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final source = readingSource.replaceFirst('\n\n', '\n\n\n');
      final controller = TextEditingController(text: source),
          focus = FocusNode();
      await pumpReadingEditor(
        t,
        controller,
        readingDocument(source).readings,
        focusNode: focus,
        scale: 1.5,
        width: 320,
        fontSize: 13,
      );
      focus.requestFocus();
      await t.pump();
      await t.pump();
      await t.showKeyboard(find.byType(TextField));
      final state = t.state<EditableTextState>(find.byType(EditableText)),
          e = state.renderEditable;
      final old = e.selectionHeightStyle;
      e.selectionHeightStyle = ui.BoxHeightStyle.strut;
      for (final position in [
        0,
        source.indexOf('silver hair'),
        source.length - 1,
        source.length,
      ]) {
        final glyph = e
            .getBoxesForSelection(
              displaySelection(
                e,
                position.clamp(0, source.length - 1),
                (position + 1).clamp(0, source.length),
              ),
            )
            .first;
        final caret = e.getLocalRectForCaret(
          displayPositionForEditable(e, TextPosition(offset: position)),
        );
        expect(
          (caret.center.dy - (glyph.top + glyph.bottom) / 2).abs(),
          lessThan(2),
        );
        expect(caret.height, lessThan(23));
      }
      e.selectionHeightStyle = old;
      final blank = source.indexOf('\n') + 1;
      expect(
        e
                .getLocalRectForCaret(
                  displayPositionForEditable(
                    e,
                    TextPosition(offset: blank + 1),
                  ),
                )
                .top -
            e
                .getLocalRectForCaret(
                  displayPositionForEditable(e, TextPosition(offset: blank)),
                )
                .top,
        inInclusiveRange(17.0, 23.0),
      );
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: source.length,
      );
      await t.pump();
      Actions.invoke(
        t.element(find.byType(EditableText)),
        CopySelectionTextIntent.copy,
      );
      await t.pump();
      expect(copied, source);
      updateSourceInput(
        t,
        const TextEditingValue(
          text: 'silver hai',
          selection: TextSelection.collapsed(offset: 10),
          composing: TextRange(start: 7, end: 10),
        ),
      );
      await t.pump();
      expect(controller.text, 'silver hai');
      expect(controller.value.composing, const TextRange(start: 7, end: 10));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }),
  );
  testWidgets(
    'deleting a whole source unit removes its caption and retains its neighbors',
    (t) async {
      final document = readingDocument(),
          controller = TextEditingController(text: readingSource);
      await pumpReadingEditor(t, controller, document.readings);
      final next = readingSource.replaceFirst('silver hair,', '');
      controller.text = next;
      await pumpReadingEditor(
        t,
        controller,
        PromptReading.rebase(document.readings, readingSource, next),
      );
      expect(find.text('银发'), findsNothing);
      expect(find.text('1个女孩'), findsOneWidget);
      expect(find.text('蓝眼'), findsOneWidget);
      expect(controller.text, next);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'legacy paragraphs show pending units rather than guessed translations',
    (t) async {
      final controller = TextEditingController(text: 'silver hair, blue eyes');
      await pumpReadingEditor(t, controller, const [
        PromptReading(
          start: 0,
          end: 22,
          source: 'silver hair, blue eyes',
          translation: '旧的整段译文',
        ),
      ]);
      expect(find.text('旧的整段译文'), findsNothing);
      expect(readingLabels(), findsNWidgets(2));
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'long units wrap inside their own caption and scroll in a bounded field',
    (t) async {
      const prose =
          'A girl stands beside the open window and reads a book, soft afternoon light falls on her hair';
      const first = '女孩站在敞开的窗边读书', second = '柔和的午后光线洒在发间';
      final split = prose.indexOf(',') + 1,
          controller = TextEditingController(text: prose);
      final readings = [
        PromptReading(
          start: 0,
          end: split,
          source: prose.substring(0, split),
          translation: first,
          perSegment: true,
        ),
        PromptReading(
          start: split,
          end: prose.length,
          source: prose.substring(split),
          translation: second,
          perSegment: true,
        ),
      ];
      await pumpReadingEditor(
        t,
        controller,
        readings,
        width: 320,
        scale: 1.5,
        maxLines: 2,
      );
      expect(readingLabels(), findsNWidgets(2));
      final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await t.pump();
      expect(t.takeException(), isNull);
      expect(controller.text, prose);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'partial edits show a small wrench status and Unicode remains intact',
    (t) async {
      const source = '1girl, smile 🐺';
      final controller = TextEditingController(text: source);
      final original = [
        const PromptReading(
          start: 0,
          end: 6,
          source: '1girl,',
          translation: '1个女孩',
          perSegment: true,
        ),
        const PromptReading(
          start: 7,
          end: 15,
          source: 'smile 🐺',
          translation: '微笑的狼',
          perSegment: true,
        ),
      ];
      final next = source.replaceFirst('1girl', '2girls');
      controller.text = next;
      await pumpReadingEditor(
        t,
        controller,
        PromptReading.rebase(original, source, next),
      );
      expect(find.text('待更新'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is UiGlyph && w.path == UiGlyphs.wrench && w.size == 12,
        ),
        findsOneWidget,
      );
      final e = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      expectSource(e, next);
      expect(find.text('微笑的狼'), findsOneWidget);
      final status = t.renderObject<RenderParagraph>(find.text('待更新'));
      expect(status.didExceedMaxLines, isFalse);
      expect(t.takeException(), isNull);
      final capture = Platform.environment['INLINE_EDIT_CAPTURE'];
      if (capture != null) {
        await t.runAsync(() async {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(capture).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
  testWidgets(
    'weighted source selection stays one source line high while captions remain',
    (t) async {
      final controller = TextEditingController(text: readingSource),
          focus = FocusNode();
      await pumpReadingEditor(
        t,
        controller,
        readingDocument().readings,
        focusNode: focus,
        width: 320,
      );
      focus.requestFocus();
      await t.pump();
      await t.pump();
      controller.selection = TextSelection(
        baseOffset: readingSource.indexOf('soft lighting'),
        extentOffset: readingSource.indexOf('blue eyes') + 4,
      );
      await t.pump();
      final e = t
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      for (final box in e.getBoxesForSelection(
        displaySelection(
          e,
          controller.selection.start,
          controller.selection.end,
        ),
      )) {
        expect(box.bottom - box.top, lessThan(24));
      }
      expect(readingLabels(), findsNWidgets(5));
      expectSource(e, readingSource);
      final capture = Platform.environment['INLINE_EDIT_CAPTURE'];
      if (capture != null) {
        await t.runAsync(() async {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$capture.weighted.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
      await t.binding.setSurfaceSize(null);
    },
  );
}
