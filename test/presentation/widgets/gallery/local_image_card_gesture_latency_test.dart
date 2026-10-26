import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/services/image_clipboard_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

/// 卡片手势：单击立即生效（不挂双击识别器），双击在单击之后追加；
/// 选择圈与悬停按钮是手势层的兄弟节点，点击即时响应且不触发卡片单击。
void main() {
  tearDown(ThumbnailService.instance.cancelAll);

  LocalImageRecord record(String path) =>
      LocalImageRecord(path: path, size: 100, modifiedAt: DateTime(2026, 1, 1));

  Widget cardApp({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onSelectionToggle,
    void Function(Offset anchor)? onFavoriteToggle,
    bool isSelected = false,
    bool isFocused = false,
    bool selectionMode = false,
    double width = 200,
    double height = 260,
    Future<void> Function()? onUseImage,
    LocalImageRecord? imageRecord,
    ImageClipboardService? clipboard,
  }) {
    return ProviderScope(
      overrides: [
        if (clipboard != null)
          imageClipboardServiceProvider.overrideWithValue(clipboard),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: LocalImageCard(
              record: imageRecord ?? record(r'C:\gallery\missing\a.png'),
              width: width,
              height: height,
              imageWidth: 832,
              imageHeight: 1216,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onSelectionToggle: onSelectionToggle,
              onFavoriteToggle: onFavoriteToggle,
              onUseImage: onUseImage,
              isSelected: isSelected,
              isFocused: isFocused,
              selectionMode: selectionMode,
            ),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(LocalImageCard)));
    await tester.pump(const Duration(milliseconds: 200));
    return mouse;
  }

  testWidgets('card copy uses shared service once with original bytes', (
    tester,
  ) async {
    late Directory temp;
    late File file;
    final original = Uint8List.fromList(
      img.encodePng(img.Image(width: 6, height: 9)),
    );
    await tester.runAsync(() async {
      temp = await Directory.systemTemp.createTemp('card-copy-');
      file = File('${temp.path}/original.png');
      await file.writeAsBytes(original);
    });
    addTearDown(() => temp.delete(recursive: true));
    final writes = <Uint8List>[];
    late Completer<void> copied;
    await tester.runAsync(() async {
      copied = Completer<void>();
    });
    final clipboard = ImageClipboardService(
      stripMetadata: () => false,
      write: (bytes) async {
        writes.add(bytes);
        copied.complete();
      },
    );
    await tester.pumpWidget(
      cardApp(imageRecord: record(file.path), clipboard: clipboard),
    );
    await hover(tester);
    final button = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: find.byIcon(StudioIcons.galleryCopy),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.runAsync(() async {
      button.onTapUp!(TapUpDetails(kind: PointerDeviceKind.mouse));
      await copied.future.timeout(const Duration(seconds: 5));
    });
    await tester.pump();
    expect(writes.length, 1);
    expect(writes.single, original);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('single tap fires immediately without waiting for double tap', (
    tester,
  ) async {
    var taps = 0;
    var doubleTaps = 0;
    await tester.pumpWidget(
      cardApp(onTap: () => taps++, onDoubleTap: () => doubleTaps++),
    );

    await tester.tap(find.byType(LocalImageCard));
    await tester.pump(const Duration(milliseconds: 16));
    expect(taps, 1);
    expect(doubleTaps, 0);

    await tester.tap(find.byType(LocalImageCard));
    await tester.pump(const Duration(milliseconds: 16));
    expect(taps, 2);
    expect(doubleTaps, 1);

    // 超过双击窗口的第三下只算单击
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(LocalImageCard));
    await tester.pump(const Duration(milliseconds: 16));
    expect(taps, 3);
    expect(doubleTaps, 1);
  });

  testWidgets('hover favorite button responds without triggering card tap', (
    tester,
  ) async {
    var taps = 0;
    var favoriteTaps = 0;
    await tester.pumpWidget(
      cardApp(
        onTap: () => taps++,
        onDoubleTap: () {},
        onFavoriteToggle: (_) => favoriteTaps++,
      ),
    );
    await hover(tester);

    await tester.tap(find.byIcon(StudioIcons.galleryHeart));
    await tester.pump(const Duration(milliseconds: 16));
    expect(favoriteTaps, 1);
    expect(taps, 0);
    expect(find.text('V4.5'), findsNothing);
    expect(find.text('832×1216'), findsOneWidget);
  });

  testWidgets('hover buttons sit in the bottom-right corner of wide cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      cardApp(
        width: 940,
        height: 532,
        onFavoriteToggle: (_) {},
        onUseImage: () async {},
      ),
    );
    await hover(tester);

    final card = tester.getRect(find.byType(LocalImageCard));
    final heart = tester.getRect(find.byIcon(StudioIcons.galleryHeart));
    final send = tester.getRect(find.byIcon(StudioIcons.gallerySend));
    final size = tester.getRect(find.text('832×1216'));
    // 按钮（26px 方块）贴右下角，距边 8px；尺寸文字靠左
    expect(send.right, closeTo(card.right - 8, 0.5));
    expect(send.bottom, closeTo(card.bottom - 8, 0.5));
    expect(heart.left, greaterThan(card.right - 100));
    expect(size.left, closeTo(card.left + 10, 0.5));
  });

  testWidgets('selection circle toggles selection instead of focusing', (
    tester,
  ) async {
    var taps = 0;
    var toggles = 0;
    await tester.pumpWidget(
      cardApp(onTap: () => taps++, onSelectionToggle: () => toggles++),
    );
    expect(find.byKey(const Key('gallery-card-select')), findsNothing);

    await hover(tester);
    await tester.tap(find.byKey(const Key('gallery-card-select')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(toggles, 1);
    expect(taps, 0);
  });

  testWidgets(
    'card arrow directly requests image use without a menu or card tap',
    (tester) async {
      var uses = 0;
      var taps = 0;
      await tester.pumpWidget(
        cardApp(onTap: () => taps++, onUseImage: () async => uses++),
      );
      await hover(tester);
      await tester.tap(find.byIcon(StudioIcons.gallerySend));
      await tester.pumpAndSettle();
      expect(uses, 1);
      expect(taps, 0);
      expect(find.byType(MenuItemButton), findsNothing);
      expect(find.byType(PopupMenuItem<Object>), findsNothing);
    },
  );

  testWidgets('focused and selected cards draw the accent ring', (
    tester,
  ) async {
    await tester.pumpWidget(cardApp());
    expect(find.byKey(const Key('gallery-card-highlight')), findsNothing);

    await tester.pumpWidget(cardApp(isFocused: true));
    expect(find.byKey(const Key('gallery-card-highlight')), findsOneWidget);
    expect(find.byIcon(StudioIcons.galleryCheckBold), findsNothing);

    await tester.pumpWidget(
      cardApp(isSelected: true, selectionMode: true, onSelectionToggle: () {}),
    );
    expect(find.byKey(const Key('gallery-card-highlight')), findsOneWidget);
    expect(find.byIcon(StudioIcons.galleryCheckBold), findsOneWidget);
  });
}
