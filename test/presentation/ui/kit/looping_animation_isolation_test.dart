// 一直在转的小动画（加载圈、不定进度条、Agent 工作中图标、流光字、像素点……）各自一个
// 重绘边界：转起来只重画它自己，旁边的东西（这里是一块数着重画次数的“整页”）不跟着重画。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_activity.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_parts.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_progress.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_rail.dart';
import 'package:nai_launcher/presentation/widgets/auth/entry_controls.dart';
import 'package:nai_launcher/presentation/widgets/bridge/bridge_link_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';

/// 和动画放在同一个重绘边界里的“页面其余部分”，记它被重画了几次。
class _Page extends CustomPainter {
  static var paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black12);
  }

  @override
  bool shouldRepaint(_Page old) => false;
}

/// 没有重绘边界的对照组：转动会连累旁边。
class _Bare extends StatefulWidget {
  const _Bare();

  @override
  State<_Bare> createState() => _BareState();
}

class _BareState extends State<_Bare> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: const SizedBox.square(dimension: 14, child: Placeholder()),
  );
}

/// 让 [animated] 转 10 帧，返回旁边的“页面”这期间被重画了几次。
Future<int> _pageRepaints(WidgetTester t, Widget animated) async {
  await t.pumpWidget(
    MaterialApp(
      theme: GeistTheme.light,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(size: const Size(200, 40), painter: _Page()),
            SizedBox(width: 160, height: 40, child: Center(child: animated)),
          ],
        ),
      ),
    ),
  );
  await t.pump();
  expect(t.binding.transientCallbackCount, greaterThan(0), reason: '在转');
  final before = _Page.paints;
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
  return _Page.paints - before;
}

void main() {
  testWidgets('对照：没有重绘边界的转圈会连累旁边每帧重画', (t) async {
    expect(await _pageRepaints(t, const _Bare()), greaterThanOrEqualTo(10));
  });

  final cases = <String, Widget>{
    '加载圈 UiSpinner': const UiSpinner(),
    '不定进度条 UiProgressBar': const SizedBox(width: 120, child: UiProgressBar()),
    '转着的图标按钮': const UiIconButton(
      glyph: UiGlyphs.refresh,
      tooltip: 'refresh',
      spinning: true,
    ),
    '导航栏后台任务圈': NavTasksGlyph(
      data: NavFixture.view(
        tasks: const [NavTask(id: 'a', kind: NavTaskKind.localUpscale)],
      ),
    ),
    'Agent 流光字': const AgentShimmer(child: Text('正在想')),
    'Agent 工作中图标': const AgentActivityIcon(
      kind: AgentActivityKind.think,
      state: AgentActivityState.running,
    ),
    'Agent 等你处理图标': const AgentActivityIcon(
      kind: AgentActivityKind.run,
      state: AgentActivityState.waiting,
    ),
    'Agent 步骤圈': const AgentStepDot(kind: AgentDotKind.running),
    'Agent 工作中那一行': const AgentWorkingLine(kind: AgentActivityKind.think),
    '登录中的像素点': const EntryBusyDots(color: Colors.blue),
    '连接中的桥图标': const BridgeLinkIcon(color: Colors.blue, working: true),
    '翻译中图标': const TranslationIcon(size: 16, busy: true),
  };
  for (final MapEntry(key: name, value: widget) in cases.entries) {
    testWidgets('$name：转起来不连累旁边', (t) async {
      expect(await _pageRepaints(t, widget), 0);
      await t.pumpWidget(const SizedBox());
    });
  }
}
