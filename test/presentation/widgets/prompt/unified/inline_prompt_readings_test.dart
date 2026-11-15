import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
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
PillDocument readingDocument([String source = readingSource]) {
  final batch = PromptTranslationBatch.prepare({
    'main': PillDocument(text: source, instances: const {}),
  }, mode: PromptTranslationMode.inline);
  const translations = ['1个女孩', '1个男孩', '银发', '柔和光线', '蓝眼'];
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
      .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
      .first;
  return MatrixUtils.transformRect(editable.getTransformTo(null), box.toRect());
}

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
            config: const UnifiedPromptConfig(
              embedded: true,
              enableAutoFormat: false,
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
              expect(rect.top - source.bottom, closeTo(1, .01));
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
              TextSelection(
                baseOffset: position.clamp(0, source.length - 1),
                extentOffset: (position + 1).clamp(0, source.length),
              ),
            )
            .first;
        final caret = e.getLocalRectForCaret(TextPosition(offset: position));
        expect(
          (caret.center.dy - (glyph.top + glyph.bottom) / 2).abs(),
          lessThan(2),
        );
        expect(caret.height, lessThan(23));
      }
      e.selectionHeightStyle = old;
      final blank = source.indexOf('\n') + 1;
      expect(
        e.getLocalRectForCaret(TextPosition(offset: blank + 1)).top -
            e.getLocalRectForCaret(TextPosition(offset: blank)).top,
        inInclusiveRange(17.0, 23.0),
      );
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: source.length,
      );
      await t.pump();
      state.copySelection(SelectionChangedCause.keyboard);
      await t.pump();
      expect(copied, source);
      t.testTextInput.updateEditingValue(
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
      expect(e.text!.toPlainText(), next);
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
      for (final box in e.getBoxesForSelection(controller.selection)) {
        expect(box.bottom - box.top, lessThan(24));
      }
      expect(readingLabels(), findsNWidgets(5));
      expect(e.text!.toPlainText(), readingSource);
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
