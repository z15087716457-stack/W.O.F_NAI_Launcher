import 'dart:io';

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_waterfall_card.dart';

void main() {
  Directory? tempDir;

  setUp(() {
    // 尺寸缓存跨卡片共享，用例间必须清干净。
    PromptBlockWaterfallCard.clearSizeCache();
  });

  tearDown(() {
    PromptBlockWaterfallCard.clearSizeCache();
    PaintingBinding.instance.imageCache.clear();
    try {
      if (tempDir?.existsSync() == true) {
        tempDir!.deleteSync(recursive: true);
      }
    } catch (_) {}
    tempDir = null;
  });

  File makeImageFile(String name, {required int width, required int height}) {
    tempDir ??= Directory.systemTemp.createTempSync(
      'prompt_block_waterfall_test_',
    );
    final file = File(
      '${tempDir!.path}/$name.png',
    )..writeAsBytesSync(img.encodePng(img.Image(width: width, height: height)));
    return file;
  }

  PromptBlock makeBlock({
    String id = 'b1',
    String title = '测试块',
    String? thumbnail,
    String color = '#FF00ACC1',
    bool isFavorite = false,
  }) {
    return PromptBlock.create(
      id: id,
      title: title,
      content: 'content',
      thumbnail: thumbnail,
      color: color,
      isFavorite: isFavorite,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('no-image block renders old-style colored bar at full width', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: PromptBlockWaterfallCard(
            block: makeBlock(title: '无图块'),
            displayTitle: '无图块',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('prompt-block-waterfall-plain-b1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prompt-block-waterfall-image-b1')),
      findsNothing,
    );
    expect(find.text('无图块'), findsOneWidget);
    // 长条撑满列宽
    final bar = tester.widget<Container>(
      find.byKey(const Key('prompt-block-waterfall-plain-b1')),
    );
    expect(tester.getSize(find.byWidget(bar)).width, 300);
  });

  testWidgets('image block: real aspect ratio + plain title bar + color dot', (
    tester,
  ) async {
    // 80×50=1.6，落在 [4:5, 16:9] 未钳制区间内
    final image = makeImageFile('wide', width: 80, height: 50);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 300,
            child: PromptBlockWaterfallCard(
              block: makeBlock(thumbnail: image.path),
              displayTitle: '横图块',
              onTap: () {},
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pump();

    final ratio = tester.widget<AspectRatio>(
      find.byKey(const Key('prompt-block-waterfall-image-b1')),
    );
    expect(ratio.aspectRatio, closeTo(1.6, 0.001));
    // 素色标题条 + 颜色小圆点
    expect(
      find.byKey(const Key('prompt-block-waterfall-title-b1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prompt-block-waterfall-dot-b1')),
      findsOneWidget,
    );
    expect(find.text('横图块'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('portrait image is capped at 4:5 (cover + offset alignment)', (
    tester,
  ) async {
    final image = makeImageFile('tall', width: 60, height: 120);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 300,
            child: PromptBlockWaterfallCard(
              block: makeBlock(thumbnail: image.path),
              displayTitle: '竖图块',
              onTap: () {},
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pump();

    // 真实比例 0.5 → 钳制到 4:5（0.8），标题条仍占底部
    final ratio = tester.widget<AspectRatio>(
      find.byKey(const Key('prompt-block-waterfall-image-b1')),
    );
    expect(ratio.aspectRatio, closeTo(0.8, 0.001));
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.fit, BoxFit.cover);
    expect(
      find.byKey(const Key('prompt-block-waterfall-title-b1')),
      findsOneWidget,
    );
  });

  testWidgets('ultra-wide panorama is clamped to 16:9', (tester) async {
    final image = makeImageFile('pano', width: 240, height: 50);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 300,
            child: PromptBlockWaterfallCard(
              block: makeBlock(thumbnail: image.path),
              displayTitle: '全景块',
              onTap: () {},
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pump();

    // 真实比例 4.8 → 钳制到 16:9（≈1.78）
    final ratio = tester.widget<AspectRatio>(
      find.byKey(const Key('prompt-block-waterfall-image-b1')),
    );
    expect(ratio.aspectRatio, closeTo(16 / 9, 0.001));
  });

  testWidgets('unreadable thumbnail falls back to plain bar', (tester) async {
    tempDir ??= Directory.systemTemp.createTempSync(
      'prompt_block_waterfall_test_',
    );
    final missing = '${tempDir!.path}/does_not_exist.png';
    await tester.runAsync(() async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 300,
            child: PromptBlockWaterfallCard(
              block: makeBlock(thumbnail: missing),
              displayTitle: '坏图块',
              onTap: () {},
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await tester.pump();

    expect(
      find.byKey(const Key('prompt-block-waterfall-plain-b1')),
      findsOneWidget,
    );
  });

  testWidgets('tap and secondary tap callbacks fire', (tester) async {
    var tapped = false;
    Offset? secondaryAt;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 300,
          child: PromptBlockWaterfallCard(
            block: makeBlock(),
            displayTitle: '交互块',
            onTap: () => tapped = true,
            onSecondaryTap: (details) => secondaryAt = details.globalPosition,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('prompt-block-waterfall-body-b1')));
    expect(tapped, isTrue);

    await tester.tap(
      find.byKey(const Key('prompt-block-waterfall-body-b1')),
      buttons: kSecondaryButton,
    );
    expect(secondaryAt, isNotNull);
  });
}
