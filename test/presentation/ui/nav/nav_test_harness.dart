import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';

/// 装一个主导航外框，页面区是一块占位底色。关掉动画。
/// 基准图要画真投影：测试体里先 `debugDisableShadows = false`，结束前改回 true（框架在 tearDown 之前检查）。
Future<void> pumpNav(
  WidgetTester tester, {
  required NavViewData data,
  NavActions? actions,
  Size size = const Size(1600, 1000),
  bool dark = false,
  String locale = 'zh',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(navApp(data, actions, dark: dark, locale: locale));
  await tester.pumpAndSettle();
}

Widget navApp(
  NavViewData data,
  NavActions? actions, {
  bool dark = false,
  String locale = 'zh',
}) => RepaintBoundary(
  key: const Key('nav-capture'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: NavShell(
        data: data,
        actions: actions ?? NavActions.none,
        child: Builder(
          builder: (context) => ColoredBox(
            key: const Key('nav-content'),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
        ),
      ),
    ),
  ),
);

/// 鼠标移到 [f] 上并等提示出现。
Future<void> hoverOver(WidgetTester tester, Finder f) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  await g.moveTo(tester.getCenter(f));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

/// 记录所有回调，断言用。
class RecordingNavActions {
  final pages = <NavPage>[];
  final pinned = <bool>[];
  final hidden = <Set<NavPage>>[];
  final ctrlNumbers = <bool>[];
  final switched = <String>[];
  final cancelled = <String>[];
  final undone = <String>[];
  var hintSeen = 0;
  var added = 0;
  var managed = 0;
  var loggedOut = 0;

  NavActions get actions => NavActions(
    onOpenPage: pages.add,
    onPinnedChanged: pinned.add,
    onHiddenChanged: hidden.add,
    onCtrlNumbersChanged: ctrlNumbers.add,
    onCtrlHintSeen: () => hintSeen++,
    onSwitchAccount: switched.add,
    onAddAccount: () => added++,
    onManageAccounts: () => managed++,
    onLogout: () => loggedOut++,
    onCancelTask: cancelled.add,
    onUndoTask: undone.add,
  );
}
