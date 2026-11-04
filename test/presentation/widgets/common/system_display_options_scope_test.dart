// macOS 系统「减少动态效果」并进 MediaQuery.disableAnimations（应用里已有的判断都读它），
// 「降低透明度」让磨砂改成实底。Windows 不接（系统动画设置由引擎自己报）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_display_options.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/widgets/auth/entry_controls.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_glass_surface.dart';
import 'package:nai_launcher/presentation/widgets/common/system_display_options_scope.dart';

/// 不接通道的一份，测试里直接改 value 模拟系统设置。
MacDisplayOptions _options([
  SystemDisplayOptions value = const SystemDisplayOptions(),
]) => MacDisplayOptions(platform: TargetPlatform.windows)..value = value;

Widget _host(MacDisplayOptions options, Widget child) =>
    SystemDisplayOptionsScope(
      source: options,
      child: MaterialApp(
        theme: GeistTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('减少动态效果：子树里的 MediaQuery.disableAnimations 变成 true，关掉又回来', (
    tester,
  ) async {
    final options = _options();
    bool? disabled;
    await tester.pumpWidget(
      _host(
        options,
        Builder(
          builder: (context) {
            disabled = MediaQuery.disableAnimationsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(disabled, isFalse);

    options.value = const SystemDisplayOptions(reduceMotion: true);
    await tester.pump();
    expect(disabled, isTrue);

    options.value = const SystemDisplayOptions();
    await tester.pump();
    expect(disabled, isFalse);
  });

  testWidgets('减少动态效果：已有的“系统减少动态效果时停”的小动画真的停了', (tester) async {
    final options = _options();
    await tester.pumpWidget(_host(options, const UiSpinner()));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    options.value = const SystemDisplayOptions(reduceMotion: true);
    await tester.pump();
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('降低透明度：工具条磨砂改成实底（不做背景模糊）', (tester) async {
    final options = _options();
    const glass = StudioGlassSurface(
      backdropBlur: true,
      useGradient: false,
      child: SizedBox(width: 120, height: 32),
    );
    await tester.pumpWidget(_host(options, glass));
    expect(find.byType(BackdropFilter), findsOneWidget);

    options.value = const SystemDisplayOptions(reduceTransparency: true);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(StudioGlassSurface), findsOneWidget);
  });

  testWidgets('降低透明度：登录卡片不透出背后的字符场，底色不透明', (tester) async {
    final options = _options();
    late EntryPalette palette;
    final card = EntryCard(
      child: Builder(
        builder: (context) {
          palette = EntryPalette.of(context);
          return const SizedBox(width: 200, height: 80);
        },
      ),
    );
    await tester.pumpWidget(_host(options, card));
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(palette.frosted, isTrue);
    expect(palette.card.a, lessThan(1));

    options.value = const SystemDisplayOptions(reduceTransparency: true);
    await tester.pump();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(palette.frosted, isFalse);
    expect(palette.card.a, 1);
  });

  testWidgets('没有这一层时（Windows 的默认）什么都不变', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        home: const Scaffold(
          body: StudioGlassSurface(
            backdropBlur: true,
            child: SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(StudioGlassSurface));
    expect(SystemDisplayOptionsScope.reduceTransparencyOf(context), isFalse);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
