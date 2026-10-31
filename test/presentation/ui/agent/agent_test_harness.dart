import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 记下回调。
class AgentRecorder {
  final calls = <(String, Object?)>[];
  List<String> get names => [for (final c in calls) c.$1];
  Object? last(String name) => calls.lastWhere((c) => c.$1 == name).$2;
}

/// 按侧栏宽度装一个 [AgentPanel]（关动画），返回回调记录。
Future<AgentRecorder> pumpAgent(
  WidgetTester tester, {
  AgentScene scene = AgentScene.chat,
  AgentViewData? data,
  AgentActions? actions,
  AgentSlots slots = const AgentSlots(),
  AgentTab tab = AgentTab.chat,
  double width = 420,
  double height = 900,
  String locale = 'zh',
  bool dark = false,
  bool animate = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final rec = AgentRecorder();
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('agent-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? GeistTheme.dark : GeistTheme.light,
        locale: locale.contains('_')
            ? Locale(locale.split('_')[0], locale.split('_')[1])
            : Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !animate),
          child: TextEditingShortcuts(child: child!),
        ),
        home: Scaffold(
          body: WindowChromeScope(
            child: AgentPanel(
              slots: slots,
              data: data ?? AgentFixture.view(scene),
              actions:
                  actions ??
                  AgentFixture.actions(
                    record: (name, [arg]) => rec.calls.add((name, arg)),
                  ),
              initialTab: tab,
            ),
          ),
        ),
      ),
    ),
  );
  if (!animate) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
  return rec;
}

/// 开着动画装一次（同一棵树上再调就是「数据更新」）；[settle] 时把进场动画走完。
Future<AgentRecorder> pumpAgentAnimated(
  WidgetTester tester,
  AgentViewData data, {
  bool settle = true,
}) async {
  final rec = await pumpAgent(tester, data: data, animate: true);
  await tester.pump();
  if (settle) {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }
  return rec;
}
