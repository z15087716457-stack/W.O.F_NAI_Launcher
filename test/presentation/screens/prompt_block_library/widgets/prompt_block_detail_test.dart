import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_detail.dart';
import 'package:nai_launcher/presentation/widgets/common/thumbnail_display.dart';

void main() {
  Directory? tempDir;

  tearDown(() {
    // Windows 上解码中的文件句柄可能未及时释放，删除走 best-effort。
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
      'prompt_block_detail_test_',
    );
    final file = File(
      '${tempDir!.path}/$name.png',
    )..writeAsBytesSync(img.encodePng(img.Image(width: width, height: height)));
    return file;
  }

  PromptBlock makeBlock({
    String id = 'b1',
    String title = '测试块',
    String content = 'masterpiece, best quality',
    String? thumbnail,
    String? folderId,
    int useCount = 0,
    bool isFavorite = false,
    List<String>? atoms,
    List<PromptBlockTag> tags = const [],
  }) {
    return PromptBlock.create(
      id: id,
      title: title,
      content: content,
      thumbnail: thumbnail,
      folderId: folderId,
      useCount: useCount,
      isFavorite: isFavorite,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      atoms: atoms,
      tags: tags,
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

  PromptBlockFolder makeFolder(String id, String name, {String? parentId}) {
    return PromptBlockFolder.create(
      id: id,
      name: name,
      parentId: parentId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('promptBlockLocationLabel', () {
    test('root block shows 全部块; nested folder shows chain', () {
      final zh = lookupAppLocalizations(const Locale('zh'));
      final folders = [
        makeFolder('a', '风格'),
        makeFolder('b', '人物', parentId: 'a'),
      ];
      expect(promptBlockLocationLabel(makeBlock(), folders, zh), '全部块');
      expect(
        promptBlockLocationLabel(makeBlock(folderId: 'b'), folders, zh),
        '全部块 / 风格 / 人物',
      );
    });
  });

  group('PromptBlockDetailView', () {
    testWidgets(
      'library detail and hover tags wrap without horizontal scroll',
      (tester) async {
        final tags = [
          for (var i = 0; i < 6; i++)
            PromptBlockTag(name: '标签$i-1234567890', color: '#FF268BEA'),
          const PromptBlockTag(
            name: 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',
            color: '#FF268BEA',
          ),
        ];
        for (final compact in [false, true]) {
          await tester.pumpWidget(
            wrap(
              SizedBox(
                width: 320,
                height: compact ? 460 : null,
                child: PromptBlockDetailView(
                  block: makeBlock(tags: tags),
                  displayTitle: '测试块',
                  locationLabel: '全部块',
                  compactImage: compact,
                ),
              ),
            ),
          );
          await tester.pump();
          final tagArea = find.byKey(const Key('prompt-block-detail-tags'));
          expect(tagArea, findsOneWidget);
          expect(
            find.descendant(
              of: tagArea,
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
          final first = tester.getRect(find.text(tags.first.name));
          final last = tester.getRect(find.text(tags.last.name));
          expect(last.top, greaterThan(first.top));
          expect(last.right, lessThanOrEqualTo(tester.getRect(tagArea).right));
          expect(
            tester.getRect(find.text('全部块')).top,
            greaterThan(last.bottom),
          );
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('renders title/content/useCount/path; no-image placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: PromptBlockDetailView(
              block: makeBlock(useCount: 3, isFavorite: true),
              displayTitle: '测试块',
              locationLabel: '全部块 / 风格',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('测试块'), findsOneWidget);
      // FEAT-79：点击态正文原子化成描边 chip，逗号段各成一枚
      expect(find.text('masterpiece'), findsOneWidget);
      expect(find.text('best quality'), findsOneWidget);
      expect(find.text('masterpiece, best quality'), findsNothing);
      expect(find.text('使用 3 次'), findsOneWidget);
      expect(find.text('全部块 / 风格'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      // 无图 = 图标+颜色占位
      expect(
        find.byKey(const Key('prompt-block-detail-image-placeholder')),
        findsOneWidget,
      );
      // 纯预览无按钮
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('explicit atoms render as single chips over comma split', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            child: PromptBlockDetailView(
              block: makeBlock(
                content: 'one scene, with comma, tail',
                atoms: ['one scene, with comma', 'tail'],
              ),
              displayTitle: '原子块',
              locationLabel: '全部块',
            ),
          ),
        ),
      );
      await tester.pump();

      // 显式 atoms 覆盖逗号切：含逗号的一幕整体成一枚 chip
      expect(find.text('one scene, with comma'), findsOneWidget);
      expect(find.text('tail'), findsOneWidget);
      expect(find.text('with comma'), findsNothing);
    });

    testWidgets('landscape thumbnail uses ThumbnailDisplay', (tester) async {
      final image = makeImageFile('wide', width: 80, height: 40);
      // 尺寸读取走真实文件 I/O；pumpWidget 必须在 runAsync 里，
      // 否则 initState 里发起的 Future 绑到 fake zone 永不完成。
      await tester.runAsync(() async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 320,
              child: PromptBlockDetailView(
                block: makeBlock(thumbnail: image.path),
                displayTitle: '横图块',
                locationLabel: '全部块',
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      await tester.pump();

      expect(find.byType(ThumbnailDisplay), findsOneWidget);
      expect(
        find.byKey(const Key('prompt-block-detail-image-landscape')),
        findsOneWidget,
      );
    });

    testWidgets('portrait thumbnail letterboxes vertically', (tester) async {
      final image = makeImageFile('tall', width: 40, height: 80);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 320,
              child: PromptBlockDetailView(
                block: makeBlock(thumbnail: image.path),
                displayTitle: '竖图块',
                locationLabel: '全部块',
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      await tester.pump();

      expect(
        find.byKey(const Key('prompt-block-detail-image-portrait')),
        findsOneWidget,
      );
      expect(find.byType(ThumbnailDisplay), findsNothing);
      final image_ = tester.widget<Image>(find.byType(Image));
      expect(image_.fit, BoxFit.contain);
      // 竖图区比横图区高
      expect(
        tester
            .getSize(
              find.byKey(const Key('prompt-block-detail-image-portrait')),
            )
            .height,
        greaterThan(180),
      );
    });

    testWidgets('compact mode crops portrait thumbnail to 0.8x width', (
      tester,
    ) async {
      final image = makeImageFile('tall-compact', width: 40, height: 80);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 320,
              child: PromptBlockDetailView(
                block: makeBlock(thumbnail: image.path),
                displayTitle: '竖图块',
                locationLabel: '全部块',
                compactImage: true,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      await tester.pump();

      final compact = find.byKey(
        const Key('prompt-block-detail-image-portrait-compact'),
      );
      expect(compact, findsOneWidget);
      // 非紧凑 letterbox 分支不应出现
      expect(
        find.byKey(const Key('prompt-block-detail-image-portrait')),
        findsNothing,
      );
      // 320 宽 → 0.8×宽 = 256 高，cover 裁切而非 letterbox
      expect(tester.getSize(compact).height, moreOrLessEquals(256, epsilon: 1));
      final image_ = tester.widget<Image>(find.byType(Image));
      expect(image_.fit, BoxFit.cover);
    });

    testWidgets('compact long content keeps footer inside bound', (
      tester,
    ) async {
      final image = makeImageFile('tall-long', width: 40, height: 80);
      final longContent = List.generate(
        40,
        (i) => 'artist:long_tag_name_$i',
      ).join(', ');
      await tester.runAsync(() async {
        await tester.pumpWidget(
          wrap(
            // 模拟预览浮层 460 高有界约束
            SizedBox(
              width: 320,
              height: 460,
              child: PromptBlockDetailView(
                block: makeBlock(
                  thumbnail: image.path,
                  content: longContent,
                  useCount: 3,
                ),
                displayTitle: '竖图长文块',
                locationLabel: '全部块',
                compactImage: true,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      await tester.pump();

      final view = find.byType(PromptBlockDetailView);
      final viewBottom = tester.getRect(view).bottom;
      // 页脚「使用次数」仍在视图边界内（未被正文顶出）
      final useCount = find.text('使用 3 次');
      expect(useCount, findsOneWidget);
      expect(tester.getBottomLeft(useCount).dy, lessThanOrEqualTo(viewBottom));
      // 正文被弹性收窄：实际行数 < 上限 8
      final contentText = tester.widget<Text>(find.text(longContent));
      expect(contentText.maxLines, isNotNull);
      expect(contentText.maxLines!, lessThan(8));
    });
  });

  group('PromptBlockHoverPreview', () {
    testWidgets('hover 180ms shows pure preview; exit dismisses', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PromptBlockHoverPreview(
            block: makeBlock(useCount: 2, folderId: 'a'),
            folders: [makeFolder('a', '风格')],
            child: const SizedBox(
              key: Key('hover-target'),
              width: 120,
              height: 60,
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('hover-target'))),
      );
      await tester.pump(const Duration(milliseconds: 179));
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsNothing,
      );

      await tester.pump(const Duration(milliseconds: 2));
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsOneWidget,
      );
      // 预览含四段且无按钮
      expect(find.text('测试块'), findsOneWidget);
      expect(find.text('使用 2 次'), findsOneWidget);
      expect(find.text('全部块 / 风格'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('prompt-block-preview-overlay')),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );

      await gesture.moveTo(const Offset(4, 4));
      await tester.pump();
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsNothing,
      );
      await gesture.removePointer();
    });

    testWidgets('quick pass does not trigger; pointer down suppresses', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PromptBlockHoverPreview(
            block: makeBlock(),
            folders: const [],
            child: const SizedBox(
              key: Key('hover-target'),
              width: 120,
              height: 60,
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      final center = tester.getCenter(find.byKey(const Key('hover-target')));
      // 快速划过：进入后 300ms 内离开 → 不触发
      await gesture.moveTo(center);
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(const Offset(4, 4));
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsNothing,
      );

      // 指针按下（点击/拖拽起手）抑制预览
      await gesture.moveTo(center);
      await gesture.down(center);
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsNothing,
      );
      await gesture.up();
      await gesture.removePointer();
    });

    testWidgets('disabled wrapper never previews', (tester) async {
      await tester.pumpWidget(
        wrap(
          PromptBlockHoverPreview(
            block: makeBlock(),
            folders: const [],
            enabled: false,
            child: const SizedBox(
              key: Key('hover-target'),
              width: 120,
              height: 60,
            ),
          ),
        ),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(
        tester.getCenter(find.byKey(const Key('hover-target'))),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const Key('prompt-block-preview-overlay')),
        findsNothing,
      );
      await gesture.removePointer();
    });
  });

  group('PromptBlockDetailPanel', () {
    testWidgets('full layout with action row; callbacks fire', (tester) async {
      var edited = false;
      var copied = false;
      var deleted = false;
      var exported = false;
      var favorited = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            height: 700,
            child: PromptBlockDetailPanel(
              block: makeBlock(useCount: 5, folderId: 'a'),
              folders: [makeFolder('a', '风格')],
              onEdit: () => edited = true,
              onToggleFavorite: (_) => favorited = true,
              onCopy: () => copied = true,
              onExport: () => exported = true,
              onDelete: () => deleted = true,
              onCollapse: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('prompt-block-detail-panel')),
        findsOneWidget,
      );
      expect(find.text('详情'), findsOneWidget);
      // 完整内容无截断（contentMaxLines: null）：原子 chip 逐枚呈现
      expect(find.text('masterpiece'), findsOneWidget);
      expect(find.text('best quality'), findsOneWidget);
      expect(find.text('使用 5 次'), findsOneWidget);
      expect(find.text('全部块 / 风格'), findsOneWidget);

      await tester.ensureVisible(find.text('编辑'));
      await tester.pump();
      await tester.tap(find.text('编辑'));
      expect(edited, isTrue);

      await tester.ensureVisible(find.text('收藏'));
      await tester.pump();
      await tester.tap(find.text('收藏'));
      expect(favorited, isTrue);

      await tester.ensureVisible(find.text('复制'));
      await tester.pump();
      await tester.tap(find.text('复制'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(copied, isTrue);

      await tester.ensureVisible(find.text('导出为 TXT'));
      await tester.pump();
      await tester.tap(find.text('导出为 TXT'));
      expect(exported, isTrue);

      await tester.ensureVisible(find.text('删除'));
      await tester.pump();
      await tester.tap(find.text('删除'));
      expect(deleted, isTrue);
    });

    testWidgets('narrow width collapses to empty box', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 200,
            child: PromptBlockDetailPanel(
              block: makeBlock(),
              folders: const [],
              onEdit: () {},
              onToggleFavorite: (_) {},
              onCopy: () {},
              onExport: () {},
              onDelete: () {},
              onCollapse: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('prompt-block-detail-panel')), findsNothing);
    });
  });
}
