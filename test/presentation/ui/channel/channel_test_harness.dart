import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';

import '../gen/gen_test_harness.dart';

export '../gen/gen_test_harness.dart' show tapKey, hoverOver, genRail;

/// 固定种子：主题顺序与元素位置都固定，基准截图才稳定。
const channelSeed = 7;

ChannelSettings channelSettings({
  ChannelMode mode = ChannelMode.random,
  ChannelTheme fixed = ChannelTheme.stars,
  Set<ChannelTheme> pool = ChannelSettings.allThemes,
  ChannelLevel level = ChannelLevel.standard,
  bool ruler = true,
  bool motion = true,
}) => ChannelSettings(
  mode: mode,
  fixed: fixed,
  pool: pool,
  level: level,
  ruler: ruler,
  motion: motion,
  seed: channelSeed,
);

/// 生图页 + 假画布（[ChannelFixtureCanvas]）：设置弹层里改通道会真的生效。
class ChannelHost extends StatefulWidget {
  const ChannelHost({
    super.key,
    required this.initial,
    required this.calls,
    this.generating = false,
    this.overview = false,
    this.focusY,
    this.focusScale,
    this.images,
  });

  final ChannelSettings initial;
  final List<String> calls;
  final bool generating;
  final bool overview;
  final double? focusY;
  final double? focusScale;
  final ImageProvider? Function(String key)? images;

  @override
  State<ChannelHost> createState() => ChannelHostState();
}

class ChannelHostState extends State<ChannelHost> {
  late ChannelSettings settings = widget.initial;

  void _set(ChannelSettings v) {
    widget.calls.add('onChannelChanged($v)');
    setState(() => settings = v);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.generating
        ? GenFixture.generating()
        : GenFixture.view();
    return GenerationPage(
      data: base.copyWith(canvas: base.canvas.withChannel(settings)),
      actions: GenActions.logging(widget.calls.add).withChannel(_set),
      slots: GenSlots(
        editor: GenFixtureEditor.builder,
        canvas: (context, tile) => ChannelFixtureCanvas(
          settings: settings,
          onSettingsChanged: _set,
          generating: widget.generating,
          overview: widget.overview,
          focusY: widget.focusY,
          focusScale: widget.focusScale,
          images: widget.images,
          onJump: (y) => widget.calls.add('onJumpTo(${y.round()})'),
        ),
      ),
    );
  }
}

Future<List<String>> pumpChannel(
  WidgetTester tester, {
  ChannelSettings? settings,
  bool dark = false,
  bool generating = false,
  bool overview = false,
  double? focusY,
  double? focusScale,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  ImageProvider? Function(String key)? images,
}) async {
  final calls = <String>[];
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - genRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    genApp(
      ChannelHost(
        initial: settings ?? channelSettings(),
        calls: calls,
        generating: generating,
        overview: overview,
        focusY: focusY,
        focusScale: focusScale,
        images: images,
      ),
      dark: dark,
      locale: locale,
    ),
  );
  final f = images ?? ChannelFixture.images;
  final base = generating ? GenFixture.generating() : GenFixture.view();
  await precacheGen(tester, [
    for (final g in ChannelFixture.groups())
      for (final t in g.tiles)
        if (t.key != null) ?f(t.key!),
    for (final b in base.history.batches) ...b.images.map((i) => i.thumb),
  ]);
  // 进入提示 4.2 秒后收起；截图前让它走完
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  return calls;
}
