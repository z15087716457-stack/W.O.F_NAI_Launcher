import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/resolution_preset.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/size_selector.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_sidebar_style.dart';

void main() {
  Future<_HarnessState> pumpSelector(
    WidgetTester tester, {
    int width = 832,
    int height = 1216,
    double harnessWidth = 400,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SizedBox(
            width: harnessWidth,
            child: _Harness(initialWidth: width, initialHeight: height),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<_HarnessState>(find.byType(_Harness));
  }

  void expectDimensions(WidgetTester tester, String width, String height) {
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('size-width-input')))
          .controller!
          .text,
      width,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('size-height-input')))
          .controller!
          .text,
      height,
    );
  }

  IconButton aspectButton(WidgetTester tester, IconData icon) {
    return tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
    );
  }

  Color? aspectButtonBackground(WidgetTester tester, IconData icon) {
    return aspectButton(
      tester,
      icon,
    ).style?.backgroundColor?.resolve(const <WidgetState>{});
  }

  Future<void> selectGroup(WidgetTester tester, String groupName) async {
    await tester.tap(find.byType(DropdownButton<ResolutionGroup>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(groupName).last);
    await tester.pumpAndSettle();
  }

  group('SizeSelector', () {
    testWidgets('紧凑下拉 + 等宽分段组按横屏/竖屏/方形顺序排列', (tester) async {
      await pumpSelector(tester, harnessWidth: 320);

      final dropdown = find.byType(DropdownButton<ResolutionGroup>);
      final group = find.byKey(const Key('size-aspect-group'));
      expect(dropdown, findsOneWidget);
      expect(group, findsOneWidget);

      // 下拉紧凑（约 100px），分段组占据剩余大部分宽度
      final dropdownWidth = tester.getSize(dropdown).width;
      final groupWidth = tester.getSize(group).width;
      expect(
        tester.getCenter(find.byIcon(Icons.expand_more)).dy,
        closeTo(tester.getCenter(group).dy, 1),
      );
      expect(
        tester.getCenter(find.text('常规')).dy,
        closeTo(tester.getCenter(group).dy, 2),
      );
      expect(dropdownWidth, lessThanOrEqualTo(140));
      expect(groupWidth, greaterThan(dropdownWidth));

      // 三段等宽且命中宽度充足（320px 下约 70px/段）
      final landscape = find.byKey(const Key('size-aspect-landscape'));
      final portrait = find.byKey(const Key('size-aspect-portrait'));
      final square = find.byKey(const Key('size-aspect-square'));
      for (final segment in [landscape, portrait, square]) {
        expect(segment, findsOneWidget);
      }
      final landscapeWidth = tester.getSize(landscape).width;
      expect(tester.getSize(portrait).width, landscapeWidth);
      expect(tester.getSize(square).width, landscapeWidth);
      expect(landscapeWidth, greaterThanOrEqualTo(44));

      // 顺序：横屏 → 竖屏 → 方形（官网同款）
      expect(
        tester.getCenter(landscape).dx,
        lessThan(tester.getCenter(portrait).dx),
      );
      expect(
        tester.getCenter(portrait).dx,
        lessThan(tester.getCenter(square).dx),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('高亮当前宽高比图标并显示分辨率徽标', (tester) async {
      await pumpSelector(tester);

      final theme = Theme.of(tester.element(find.byType(SizeSelector)));
      final highlightedBg = GenSidebarStyle.selectedSurface(theme);

      // 常规-竖屏：分辨率徽标显示 832 × 1216，竖屏图标高亮
      expectDimensions(tester, '832', '1216');
      expect(
        aspectButtonBackground(tester, Icons.crop_portrait),
        highlightedBg,
      );
      expect(
        aspectButtonBackground(tester, Icons.crop_landscape),
        isNot(highlightedBg),
      );
      expect(
        aspectButtonBackground(tester, Icons.crop_square),
        isNot(highlightedBg),
      );
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('切换分组沿用当前宽高比类型并更新徽标', (tester) async {
      final harness = await pumpSelector(tester);

      await selectGroup(tester, '大尺寸');
      await tester.pump();

      // 竖屏保持 → 大尺寸-竖屏 1024 × 1536
      expect(harness.width, 1024);
      expect(harness.height, 1536);
      expectDimensions(tester, '1024', '1536');
      expect(find.text('大尺寸'), findsOneWidget);
    });

    testWidgets('点击宽高比图标应用对应预设', (tester) async {
      final harness = await pumpSelector(tester);
      final theme = Theme.of(tester.element(find.byType(SizeSelector)));
      final highlightedBg = GenSidebarStyle.selectedSurface(theme);

      await tester.tap(find.byIcon(Icons.crop_landscape));
      await tester.pump();

      // 常规-横屏 1216 × 832
      expect(harness.width, 1216);
      expect(harness.height, 832);
      expectDimensions(tester, '1216', '832');
      expect(
        aspectButtonBackground(tester, Icons.crop_landscape),
        highlightedBg,
      );

      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pump();

      // 常规-方形 1024 × 1024
      expect(harness.width, 1024);
      expect(harness.height, 1024);
      expectDimensions(tester, '1024', '1024');
      expect(aspectButtonBackground(tester, Icons.crop_square), highlightedBg);
    });

    testWidgets('壁纸组禁用方形图标', (tester) async {
      final harness = await pumpSelector(tester);

      await selectGroup(tester, '壁纸');
      await tester.pump();

      // 壁纸-竖屏 1088 × 1920
      expect(harness.width, 1088);
      expect(harness.height, 1920);
      expectDimensions(tester, '1088', '1920');

      // 壁纸组没有方形预设 → 方形图标禁用
      expect(aspectButton(tester, Icons.crop_square).onPressed, isNull);
      expect(aspectButton(tester, Icons.crop_portrait).onPressed, isNotNull);
      expect(aspectButton(tester, Icons.crop_landscape).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pump();
      expect(harness.width, 1088);
      expect(harness.height, 1920);
    });

    testWidgets('the inline separator preserves swap without an extra button', (
      tester,
    ) async {
      final harness = await pumpSelector(tester);
      await tester.tap(find.text('×'));
      await tester.pump();
      expect((harness.width, harness.height), (1216, 832));
      expect(find.text('自定义'), findsOneWidget);
      expectDimensions(tester, '1216', '832');
    });

    testWidgets('custom focuses the inline dimensions without another row', (
      tester,
    ) async {
      await pumpSelector(tester);
      final originalHeight = tester.getSize(find.byType(SizeSelector)).height;
      await selectGroup(tester, '自定义');
      expect(find.byType(TextField), findsNWidgets(2));
      expectDimensions(tester, '832', '1216');
      expect(tester.getSize(find.byType(SizeSelector)).height, originalHeight);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('size-width-input')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(aspectButton(tester, Icons.crop_portrait).onPressed, isNull);
    });

    testWidgets('inline edits commit as custom even when matching a preset', (
      tester,
    ) async {
      final harness = await pumpSelector(tester);
      await tester.enterText(find.byKey(const Key('size-width-input')), '1216');
      await tester.enterText(find.byKey(const Key('size-height-input')), '832');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect((harness.width, harness.height), (1216, 832));
      expect(find.text('自定义'), findsOneWidget);
      expectDimensions(tester, '1216', '832');
      await selectGroup(tester, '大尺寸');
      expect((harness.width, harness.height), (1536, 1024));
      expectDimensions(tester, '1536', '1024');
      expect(find.text('大尺寸'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'blur commits both fields; blank and zero never change the size',
      (tester) async {
        final harness = await pumpSelector(tester);
        await tester.enterText(
          find.byKey(const Key('size-width-input')),
          '896',
        );
        await tester.enterText(
          find.byKey(const Key('size-height-input')),
          '1280',
        );
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pump();
        expect((harness.width, harness.height), (896, 1280));
        expect(find.text('自定义'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('size-width-input')), '');
        await tester.enterText(find.byKey(const Key('size-height-input')), '0');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expectDimensions(tester, '896', '1280');
        expect((harness.width, harness.height), (896, 1280));
      },
    );
  });
}

/// 与 SizeSection 相同的状态回路：onChanged 把宽高写回 SizeSelector
class _Harness extends StatefulWidget {
  const _Harness({this.initialWidth = 832, this.initialHeight = 1216});

  final int initialWidth;
  final int initialHeight;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int _width = widget.initialWidth;
  late int _height = widget.initialHeight;

  int get width => _width;
  int get height => _height;

  @override
  Widget build(BuildContext context) {
    return SizeSelector(
      width: _width,
      height: _height,
      title: const Text('图像尺寸'),
      onChanged: (width, height) {
        setState(() {
          _width = width;
          _height = height;
        });
      },
    );
  }
}
