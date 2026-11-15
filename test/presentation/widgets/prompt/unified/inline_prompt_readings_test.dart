import 'dart:ui' as ui;
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
      widget is Text &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('prompt-reading-'),
);
Finder readingOriginal(String value) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.textSpan?.toPlainText() == value,
);
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
              readingOriginal('1girl,'),
              readingOriginal('1boy::,'),
              readingOriginal('silver hair,'),
              readingOriginal('soft lighting::,'),
              readingOriginal('blue eyes'),
            ];
            for (final (i, label) in readingLabels().evaluate().indexed) {
              final rect = t.getRect(find.byWidget(label.widget));
              final sourceRect = t.getRect(originals[i]);
              expect(rect.left, closeTo(sourceRect.left, .01));
              expect(rect.top - sourceRect.bottom, closeTo(1, .01));
              expect(rect.right, lessThanOrEqualTo(width + .01));
            }
            expect(
              t.getTopLeft(originals[0]).dy,
              t.getTopLeft(originals[1]).dy,
            );
            expect(t.getTopLeft(originals[0]).dy, closeTo(0, .01));
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
  testWidgets(
    'source click enters the same native editor; captions do not edit',
    (t) async {
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
      await t.tapAt(t.getCenter(find.text('1个女孩')));
      await t.pump();
      expect(focus.hasFocus, isFalse);
      await t.tap(readingOriginal('soft lighting::,'));
      await t.pump();
      expect(focus.hasFocus, isTrue);
      expect(readingLabels(), findsNothing);
      expect(
        t.state<EditableTextState>(find.byType(EditableText)),
        same(state),
      );
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
    },
  );
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
      final controller = TextEditingController(text: readingSource),
          focus = FocusNode();
      await pumpReadingEditor(
        t,
        controller,
        readingDocument().readings,
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
      e.selectionHeightStyle = ui.BoxHeightStyle.tight;
      for (final position in [
        0,
        readingSource.indexOf('silver hair'),
        readingSource.length - 1,
        readingSource.length,
      ]) {
        final glyph = e
            .getBoxesForSelection(
              TextSelection(
                baseOffset: position.clamp(0, readingSource.length - 1),
                extentOffset: (position + 1).clamp(0, readingSource.length),
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
      final blank = readingSource.indexOf('\n') + 1;
      expect(
        e.getLocalRectForCaret(TextPosition(offset: blank + 1)).top -
            e.getLocalRectForCaret(TextPosition(offset: blank)).top,
        inInclusiveRange(17.0, 23.0),
      );
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: readingSource.length,
      );
      await t.pump();
      state.copySelection(SelectionChangedCause.keyboard);
      await t.pump();
      expect(copied, readingSource);
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
      expect(
        t.getTopLeft(find.text(second)).dy,
        greaterThan(t.getBottomLeft(find.text(first)).dy),
      );
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
}
