import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/model3d_layer_data.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/layer_panel.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 记录路由,确保图层选择不再创建独立编辑页面。
class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // EditorState 构造时 ToolManager 会异步读取 SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  /// 挂载图层面板:一个普通层 + 一个 3D 层(空图层即可,避免真实图像解码)
  Future<(EditorState, _RecordingNavigatorObserver)> pumpPanel(
    WidgetTester tester,
  ) async {
    final state = EditorState();
    addTearDown(state.dispose);

    state.layerManager.addLayer(name: 'Normal Layer');
    final layer3d = state.layerManager.addLayer(name: 'Pose Layer');
    layer3d.model3d = const Model3dLayerData(
      modelRef: 'builtin:mannequin',
      sceneState: {'version': 1},
    );

    final observer = _RecordingNavigatorObserver();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [observer],
        home: Scaffold(body: LayerPanel(state: state)),
      ),
    );
    // 消化 addLayer 触发的快照失效防抖计时器(100ms 一次性、回调为空)
    // 与缩略图批处理的 zero-delay 计时器,避免测试收尾报 pending timer
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    observer.pushed.clear(); // 丢弃初始路由的 push 记录
    return (state, observer);
  }

  Future<void> doubleTapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text(text));
    await tester.pump();
    // 推进时钟,消化第二次点击的 kDoubleTapMinTime(40ms)倒计时计时器
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('header shows the add-3d-layer button', (tester) async {
    await pumpPanel(tester);

    expect(find.byIcon(Icons.view_in_ar), findsOneWidget);
    expect(find.byTooltip('Add 3D Model Layer'), findsOneWidget);
  });

  testWidgets('3D badge shows only on model3d layers', (tester) async {
    await pumpPanel(tester);

    // 两个图层中仅 3D 层显示角标
    expect(find.text('3D'), findsOneWidget);
    expect(find.text('Pose Layer'), findsOneWidget);
    expect(find.text('Normal Layer'), findsOneWidget);
    // 角标与 3D 层名字同处一个 tile 行
    final badgeRow = find.ancestor(
      of: find.text('3D'),
      matching: find.ancestor(
        of: find.text('Pose Layer'),
        matching: find.byType(Row),
      ),
    );
    expect(badgeRow, findsWidgets);
  });

  testWidgets('double-tapping a 3D layer selects it without pushing a route', (
    tester,
  ) async {
    final (state, observer) = await pumpPanel(tester);
    state.layerManager.setActiveLayer(state.layerManager.layers.first.id);

    await doubleTapText(tester, 'Pose Layer');
    await tester.pump();
    await tester.pump();

    // 重命名未激活
    expect(find.byType(ThemedInput), findsNothing);
    expect(state.layerManager.activeLayer!.name, 'Pose Layer');
    expect(observer.pushed, isEmpty);
    expect(find.byType(Model3dEditorScreen), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('double-tapping normal layer name still opens rename', (
    tester,
  ) async {
    final (_, observer) = await pumpPanel(tester);

    await doubleTapText(tester, 'Normal Layer');
    await tester.pump();

    // 重命名激活,且没有推入任何路由
    expect(find.byType(ThemedInput), findsOneWidget);
    expect(observer.pushed, isEmpty);
    expect(find.byType(Model3dEditorScreen), findsNothing);

    // 收尾:卸载树,终止重命名输入框的光标闪烁计时器
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
