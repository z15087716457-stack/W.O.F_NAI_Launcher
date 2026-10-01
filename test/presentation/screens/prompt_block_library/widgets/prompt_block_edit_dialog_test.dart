import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/compact_parameter_number_field.dart';
import 'package:nai_launcher/presentation/widgets/common/thumbnail_display.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_token_count_bar.dart';

void main() {
  Directory? tempDir;

  tearDown(() {
    if (tempDir?.existsSync() == true) {
      tempDir!.deleteSync(recursive: true);
    }
    tempDir = null;
  });

  File makeImageFile() {
    tempDir ??= Directory.systemTemp.createTempSync(
      'prompt_block_edit_dialog_test_',
    );
    final file = File('${tempDir!.path}/thumb.png')
      ..writeAsBytesSync(img.encodePng(img.Image(width: 40, height: 40)));
    return file;
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  PromptBlock makeBlock({String? thumbnail}) {
    return PromptBlock.create(
      id: 'block-1',
      title: '测试块',
      content: 'content',
      thumbnail: thumbnail,
      thumbnailOffsetX: 0.4,
      thumbnailOffsetY: -0.2,
      thumbnailScale: 1.3,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  testWidgets('reading polish retains source warning and stored language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PromptBlockEditResult? captured;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => captured = await PromptBlockEditDialog.show(
              context: context,
              block: makeBlock().copyWith(
                readingTranslationZh: '元の訳文',
                readingTranslationLanguageCode: 'ja',
                readingTranslationNeedsReview: true,
              ),
              folders: const [],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final field = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '元の訳文',
    );
    await tester.enterText(field, '編集した訳文');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(captured?.readingTranslationLanguageCode, 'ja');
    expect(captured?.readingTranslationEdited, isTrue);
    expect(captured?.readingTranslationNeedsReview, isTrue);
    expect(captured?.content, 'content');
  });

  testWidgets('block without thumbnail shows the add-image placeholder box', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(PromptBlockEditDialog(block: makeBlock(), folders: const [])),
    );
    await tester.pump();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.byType(ThumbnailDisplay), findsNothing);
  });

  testWidgets('tag editor saves a named custom-color tag', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    PromptBlockEditResult? captured;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => captured = await PromptBlockEditDialog.show(
              context: context,
              block: makeBlock(),
              folders: const [],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('block-add-tag')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('block-tag-name-input')), '冷色');
    await tester.enterText(
      find.byKey(const Key('block-tag-color-input')),
      '#268BEA',
    );
    await tester.tap(find.byKey(const Key('block-tag-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-tag-冷色')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(captured?.tags, const [
      PromptBlockTag(name: '冷色', color: '#FF268BEA'),
    ]);
  });

  testWidgets(
    'block with thumbnail shows preview; clearing reverts to placeholder',
    (tester) async {
      final imageFile = makeImageFile();
      await tester.pumpWidget(
        wrap(
          PromptBlockEditDialog(
            block: makeBlock(thumbnail: imageFile.path),
            folders: const [],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ThumbnailDisplay), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);

      // 右上 X 清图 → 回到 + 占位框。
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.byType(ThumbnailDisplay), findsNothing);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    },
  );

  testWidgets('save result carries thumbnail fields through', (tester) async {
    final imageFile = makeImageFile();
    PromptBlockEditResult? captured;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              captured = await PromptBlockEditDialog.show(
                context: context,
                block: makeBlock(thumbnail: imageFile.path),
                folders: const [],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(captured, isNotNull);
    expect(captured!.thumbnail, imageFile.path);
    expect(captured!.thumbnailOffsetX, 0.4);
    expect(captured!.thumbnailOffsetY, -0.2);
    expect(captured!.thumbnailScale, 1.3);
  });

  testWidgets('tabbed editor saves negative text and selected settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    PromptBlockEditResult? captured;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              captured = await PromptBlockEditDialog.show(
                context: context,
                block: makeBlock(),
                folders: const [],
                tokenCounterService: const PromptTokenCounterService(
                  encoder: _FixedTokenEncoder(),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('正文'), findsNothing);
    expect(find.text('基础提示词'), findsOneWidget);
    expect(find.byKey(const Key('block-token-count-bar')), findsOneWidget);
    final bar = tester.widget<PromptTokenCountBar>(
      find.byKey(const Key('block-token-count-bar')),
    );
    expect(bar.usage.usedTokens, greaterThan(0));
    expect(bar.usage.breakdown.first.label, '提示词');
    expect(bar.referenceLimit, isTrue);

    await tester.tap(find.byKey(const Key('block-content-tab-1')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('atom-editor-field')),
      'bad anatomy',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('block-content-tab-2')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('block-setting-steps')));
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('block-setting-steps')),
        matching: find.text('—'),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('block-setting-steps')),
        matching: find.byType(TextField),
      ),
      '30',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('block-setting-scale')),
        matching: find.text('—'),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('block-setting-scale')),
        matching: find.byType(TextField),
      ),
      '5.5',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.content, 'content');
    expect(captured!.negativeContent, 'bad anatomy');
    expect(captured!.generationSettings?.steps, 30);
    expect(captured!.generationSettings?.scale, 5.5);
  });

  testWidgets('settings follow model capabilities and omit dimensions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      wrap(PromptBlockEditDialog(block: makeBlock(), folders: const [])),
    );
    await tester.tap(find.byKey(const Key('block-content-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-setting-width')), findsNothing);
    expect(find.byKey(const Key('block-setting-height')), findsNothing);
    expect(find.byKey(const Key('block-setting-cfg-rescale')), findsNothing);
    expect(find.byKey(const Key('block-setting-noise-schedule')), findsNothing);

    await tester.tap(find.byKey(const Key('block-setting-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NAI Diffusion V4 (Full)').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-setting-cfg-rescale')), findsOneWidget);
    expect(
      find.byKey(const Key('block-setting-noise-schedule')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('block-setting-model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NAI Diffusion V5 (Full)').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-setting-cfg-rescale')), findsOneWidget);
    expect(find.byKey(const Key('block-setting-noise-schedule')), findsNothing);
  });

  testWidgets('compact value supports arrows, drag, and clearing', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 180,
          child: CompactParameterNumberField(
            label: 'PG',
            controller: controller,
            fallback: 5,
            min: 1,
            max: 20,
            step: .1,
            decimals: 1,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(controller.text, '5.1');
    await tester.drag(find.text('5.1'), const Offset(30, 0));
    await tester.pump();
    expect(controller.text, '5.4');
    await tester.tap(find.byKey(const Key('clear-PG')));
    await tester.pump();
    expect(controller.text, isEmpty);
  });
}

class _FixedTokenEncoder implements PromptTokenEncoder {
  const _FixedTokenEncoder();

  @override
  Future<int> countTokens(String text) async => text.isEmpty ? 0 : 7;
}
