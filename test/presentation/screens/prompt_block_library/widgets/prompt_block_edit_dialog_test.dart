import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_edit_dialog.dart';
import 'package:nai_launcher/presentation/widgets/common/thumbnail_display.dart';

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
}
