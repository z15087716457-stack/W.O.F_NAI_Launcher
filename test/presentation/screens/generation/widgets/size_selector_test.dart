import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/image/resolution_preset.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/size_selector.dart';

void main() {
  Future<_HarnessState> pumpSelector(
    WidgetTester tester, {
    int width = 832,
    int height = 1216,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: _Harness(initialWidth: width, initialHeight: height),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<_HarnessState>(find.byType(_Harness));
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
    await tester.tap(find.byType(DropdownButtonFormField<ResolutionGroup>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(groupName).last);
    await tester.pumpAndSettle();
  }

  group('SizeSelector', () {
    testWidgets('高亮当前宽高比图标并显示分辨率徽标', (tester) async {
      await pumpSelector(tester);

      final theme = Theme.of(tester.element(find.byType(SizeSelector)));
      final highlightedBg = theme.colorScheme.primary.withValues(alpha: 0.15);

      // 常规-竖屏：分辨率徽标显示 832×1216，竖屏图标高亮
      expect(find.text('832×1216'), findsOneWidget);
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
      // 预设模式下不显示自定义输入框
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('切换分组沿用当前宽高比类型并更新徽标', (tester) async {
      final harness = await pumpSelector(tester);

      await selectGroup(tester, '大尺寸');
      await tester.pump();

      // 竖屏保持 → 大尺寸-竖屏 1024×1536
      expect(harness.width, 1024);
      expect(harness.height, 1536);
      expect(find.text('1024×1536'), findsOneWidget);
      expect(find.text('大尺寸'), findsOneWidget);
    });

    testWidgets('点击宽高比图标应用对应预设', (tester) async {
      final harness = await pumpSelector(tester);
      final theme = Theme.of(tester.element(find.byType(SizeSelector)));
      final highlightedBg = theme.colorScheme.primary.withValues(alpha: 0.15);

      await tester.tap(find.byIcon(Icons.crop_landscape));
      await tester.pump();

      // 常规-横屏 1216×832
      expect(harness.width, 1216);
      expect(harness.height, 832);
      expect(find.text('1216×832'), findsOneWidget);
      expect(
        aspectButtonBackground(tester, Icons.crop_landscape),
        highlightedBg,
      );

      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pump();

      // 常规-方形 1024×1024
      expect(harness.width, 1024);
      expect(harness.height, 1024);
      expect(find.text('1024×1024'), findsOneWidget);
      expect(aspectButtonBackground(tester, Icons.crop_square), highlightedBg);
    });

    testWidgets('壁纸组禁用方形图标', (tester) async {
      final harness = await pumpSelector(tester);

      await selectGroup(tester, '壁纸');
      await tester.pump();

      // 壁纸-竖屏 1088×1920
      expect(harness.width, 1088);
      expect(harness.height, 1920);
      expect(find.text('1088×1920'), findsOneWidget);

      // 壁纸组没有方形预设 → 方形图标禁用
      expect(aspectButton(tester, Icons.crop_square).onPressed, isNull);
      expect(aspectButton(tester, Icons.crop_portrait).onPressed, isNotNull);
      expect(aspectButton(tester, Icons.crop_landscape).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.crop_square));
      await tester.pump();
      expect(harness.width, 1088);
      expect(harness.height, 1920);
    });

    testWidgets('选择自定义显示输入框、隐藏徽标并禁用图标', (tester) async {
      await pumpSelector(tester);

      await selectGroup(tester, '自定义');
      await tester.pump();

      // 自定义输入框出现且保留当前宽高
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        '832',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        '1216',
      );

      // 徽标隐藏（即使当前尺寸仍命中预设）
      expect(find.text('832×1216'), findsNothing);

      // 三个宽高比图标全部禁用，交换按钮仍可用
      expect(aspectButton(tester, Icons.crop_portrait).onPressed, isNull);
      expect(aspectButton(tester, Icons.crop_landscape).onPressed, isNull);
      expect(aspectButton(tester, Icons.crop_square).onPressed, isNull);
      expect(aspectButton(tester, Icons.swap_horiz).onPressed, isNotNull);
    });

    testWidgets('手动输入匹配预设时自动跳回该预设', (tester) async {
      final harness = await pumpSelector(tester);
      final theme = Theme.of(tester.element(find.byType(SizeSelector)));
      final highlightedBg = theme.colorScheme.primary.withValues(alpha: 0.15);

      await selectGroup(tester, '自定义');
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));

      // 输入不匹配预设的尺寸 → 保持自定义
      await tester.enterText(find.byType(EditableText).at(0), '1000');
      await tester.pump();
      expect(harness.width, 1000);
      expect(harness.height, 1216);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('1000×1216'), findsNothing);

      // 输入 1216×832 → 自动匹配常规-横屏，退出自定义
      await tester.enterText(find.byType(EditableText).at(0), '1216');
      await tester.pump();
      await tester.enterText(find.byType(EditableText).at(1), '832');
      await tester.pump();

      expect(harness.width, 1216);
      expect(harness.height, 832);
      // 输入框收起、徽标恢复、横屏图标高亮
      expect(find.byType(TextField), findsNothing);
      expect(find.text('1216×832'), findsOneWidget);
      expect(find.text('常规'), findsOneWidget);
      expect(
        aspectButtonBackground(tester, Icons.crop_landscape),
        highlightedBg,
      );
      expect(aspectButton(tester, Icons.crop_square).onPressed, isNotNull);
    });
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
