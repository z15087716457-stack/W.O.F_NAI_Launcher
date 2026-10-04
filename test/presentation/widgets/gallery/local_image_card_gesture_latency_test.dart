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
  }) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: LocalImageCard(
              record: record(r'C:\gallery\missing\a.png'),
              width: 200,
              height: 260,
              imageWidth: 832,
              imageHeight: 1216,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onSelectionToggle: onSelectionToggle,
              onFavoriteToggle: onFavoriteToggle,
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
