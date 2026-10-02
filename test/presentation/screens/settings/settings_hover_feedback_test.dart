import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

const _reasoningAdvice = '纯翻译通常无需开启思考；为兼顾打标、语义分类等处理，建议开启该模型支持的最低思考档位。';
final _config = harness.sampleConfig.copyWith(
  models: [
    harness.sampleConfig.models.first.copyWith(
      reasoningEfforts: ['none', 'low', 'high'],
      reasoningEffort: 'low',
    ),
    ...harness.sampleConfig.models.skip(1),
  ],
);

Future<List<int>> _pixel(
  WidgetTester tester,
  Offset point, {
  GlobalKey? key,
}) async {
  final boundary =
      (key ?? harness.captureKey).currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final local = boundary.globalToLocal(point);
    final offset = (local.dy.floor() * image.width + local.dx.floor()) * 4;
    final pixel = bytes.buffer.asUint8List().sublist(offset, offset + 4);
    image.dispose();
    return pixel;
  }))!;
}

void main() {
  setUpAll(() async {
    await ModelCatalogRepository.load();
    if (Platform.environment['CAPTURE_MODEL_MANAGEMENT'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets(
    'shared settings rows stay flat while buttons and keyboard focus still respond',
    (tester) async {
      final key = GlobalKey();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: settingsUiTheme(
            AppTheme.getTheme(
              AppStyle.geist,
              Platform.environment['STUDIO_APPEARANCE'] == 'dark'
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SettingsTile(
                      key: const Key('flat-setting-row'),
                      title: const Text('常规设置'),
                      onTap: () {},
                    ),
                    const ExpansionTile(
                      key: Key('flat-expansion-row'),
                      title: Text('高级设置'),
                      children: [Text('设置内容')],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('bounded-action'),
                        focusNode: focus,
                        onPressed: () {},
                        child: const Text('操作按钮'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      for (final finder in [
        find.byKey(const Key('flat-setting-row')),
        find.byKey(const Key('flat-expansion-row')),
      ]) {
        final rect = tester.getRect(finder);
        final point = Offset(rect.right - 60, rect.center.dy);
        final before = await _pixel(tester, point, key: key);
        await mouse.moveTo(rect.center);
        await tester.pumpAndSettle();
        expect(await _pixel(tester, point, key: key), before);
        await mouse.moveTo(const Offset(1, 1));
        await tester.pumpAndSettle();
      }
      final action = tester.getRect(find.byKey(const Key('bounded-action')));
      final sample = Offset(action.left + 3, action.center.dy);
      final before = await _pixel(tester, sample, key: key);
      await mouse.moveTo(action.center);
      await tester.pumpAndSettle();
      expect(await _pixel(tester, sample, key: key), isNot(before));
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      final previousStrategy = FocusManager.instance.highlightStrategy;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(await _pixel(tester, sample, key: key), isNot(before));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advanced heading and all task selectors avoid full-field hover fill',
    (tester) async {
      await harness.pumpManagement(tester, config: _config);
      final advanced = find.byKey(const Key('service-advanced-toggle'));
      await tester.ensureVisible(advanced);
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      Future<void> check(Finder field, String captureName) async {
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        final rect = tester.getRect(field);
        final point = Offset(rect.right - 36, rect.center.dy);
        final before = await _pixel(tester, point);
        await mouse.moveTo(rect.center);
        await tester.pumpAndSettle();
        expect(await _pixel(tester, point), before);
        await harness.capture(tester, captureName);
        await mouse.moveTo(const Offset(1, 1));
        await tester.pumpAndSettle();
      }

      await check(advanced, 'settings-feedback-advanced-hover');
      await harness.tapVisible(tester, find.text('功能接口').first);
      for (final spec in [
        (find.byKey(const Key('task-reasoning')), 'thinking'),
        (find.byKey(const Key('task-route-translate-deepseek-chat')), 'model'),
        (find.byKey(const Key('task-preset-builtin:translate')), 'preset'),
        (find.byKey(const Key('task-language')), 'language'),
      ]) {
        await check(spec.$1, 'settings-feedback-${spec.$2}-hover');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all four task hints and hover/tap reasoning advice leave configured effort untouched',
    (tester) async {
      final container = await harness.pumpManagement(tester, config: _config);
      final before = container.read(promptAssistantConfigProvider).encode();
      await harness.tapVisible(tester, find.text('功能接口').first);
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      for (final task in LauncherInterface.values) {
        await harness.tapVisible(
          tester,
          find.widgetWithText(ManagementListItem, task.title),
        );
        expect(find.byKey(const Key('task-format-hint')), findsOneWidget);
        final help = find.byKey(const Key('task-reasoning-help'));
        await tester.ensureVisible(help);
        await tester.pumpAndSettle();
        final heading = tester.getRect(find.text('思考'));
        final bounds = tester.getRect(help);
        expect(bounds.left, greaterThan(heading.right));
        expect(bounds.center.dy, closeTo(heading.center.dy, .1));
        await mouse.moveTo(bounds.center);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.text(_reasoningAdvice), findsOneWidget);
        await harness.capture(tester, 'settings-feedback-${task.name}-advice');
        await mouse.moveTo(const Offset(1, 1));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        await tester.tap(help);
        await tester.pumpAndSettle();
        expect(find.text(_reasoningAdvice), findsOneWidget);
        Tooltip.dismissAllToolTips();
        await tester.pumpAndSettle();
        expect(container.read(promptAssistantConfigProvider).encode(), before);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
