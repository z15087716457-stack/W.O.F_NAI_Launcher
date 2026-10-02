import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_management_widgets.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_task_editor.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;

final _config = harness.sampleConfig.copyWith(
  models: [
    harness.sampleConfig.models.first.copyWith(
      reasoningEfforts: ['none', 'low', 'high'],
      reasoningEffort: 'high',
    ),
    harness.sampleConfig.models[1],
  ],
  presets: const [
    TaskPresetConfig(
      id: 'menu-test',
      name: '我的阅读预设',
      task: LauncherInterface.translate,
      prompt: 'Offline only',
    ),
  ],
);

Finder get _marker => find.descendant(
  of: find.byType(ModelTaskEditor),
  matching: find.byKey(const Key('management-tab-underline')),
);

Finder get _menu => find.byWidgetPredicate(
  (widget) =>
      widget is Material &&
      widget.type == MaterialType.card &&
      widget.elevation == 3,
);

void _expectMenu(WidgetTester tester, Finder field) {
  final material = tester.widget<Material>(_menu);
  expect(
    (material.shape! as RoundedRectangleBorder).borderRadius,
    BorderRadius.circular(12),
  );
  expect(material.clipBehavior, Clip.antiAlias);
  final fieldRect = tester.getRect(field);
  final menuRect = tester.getRect(_menu);
  expect(menuRect.top, greaterThanOrEqualTo(fieldRect.bottom));
  expect(menuRect.width, closeTo(fieldRect.width, .01));
  final selected = find.descendant(
    of: _menu,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color?.a == .08,
    ),
  );
  expect(selected, findsOneWidget);
  final selectionRect = tester.getRect(selected);
  expect(selectionRect.left, greaterThan(menuRect.left));
  expect(selectionRect.right, lessThan(menuRect.right));
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
    'task menus share rounded inset surfaces and keyboard selection',
    (tester) async {
      await harness.pumpManagement(tester, config: _config);
      await harness.tapVisible(tester, find.text('功能接口').first);
      final route = find.byKey(const Key('task-route-translate-deepseek-chat'));
      final preset = find.byKey(const Key('task-preset-builtin:translate'));
      final language = find.byKey(const Key('task-language'));
      for (final entry in [
        (route, 'model'),
        (preset, 'preset'),
        (language, 'language'),
      ]) {
        await harness.tapVisible(tester, entry.$1);
        _expectMenu(tester, entry.$1);
        await harness.capture(tester, 'menu-polish-${entry.$2}');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
      await harness.tapVisible(tester, find.byKey(const Key('task-reasoning')));
      expect(
        (tester.widget<Material>(_menu).shape! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.circular(12),
      );
      await harness.capture(tester, 'menu-polish-thinking');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await harness.tapVisible(tester, language);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_menu, findsNothing);
      expect(find.text('有未保存的修改'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short enlarged windows keep menu choices reachable', (
    tester,
  ) async {
    await harness.pumpManagement(
      tester,
      config: _config,
      size: const Size(400, 650),
      scale: 1.3,
    );
    await harness.tapVisible(tester, find.text('功能接口').first);
    await harness.tapVisible(tester, find.byKey(const Key('task-language')));
    final rect = tester.getRect(_menu);
    expect(rect.left, greaterThanOrEqualTo(8));
    expect(rect.right, lessThanOrEqualTo(392));
    expect(rect.bottom, lessThanOrEqualTo(642));
    await harness.capture(tester, 'menu-polish-narrow');
    await tester.ensureVisible(find.text('한국어').last);
    await tester.tap(find.text('한국어').last);
    await tester.pumpAndSettle();
    expect(_menu, findsNothing);
    expect(find.text('有未保存的修改'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final success in [true, false]) {
    testWidgets('test marker returns after ${success ? 'success' : 'failure'}', (
      tester,
    ) async {
      RequestInterceptorHandler? pending;
      RequestOptions? request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              pending = handler;
              request = options;
            },
          ),
        );
      addTearDown(dio.close);
      await harness.pumpManagement(
        tester,
        config: _config,
        dio: dio,
        secrets: harness.MemorySecrets()..keys['deepseek'] = 'offline-test',
      );
      await harness.tapVisible(tester, find.text('功能接口').first);
      final before = tester.getRect(_marker);
      final propertiesTop = tester.getTopLeft(
        find.byKey(const Key('task-properties')),
      );
      await tester.tap(find.byKey(const Key('task-test')));
      for (var i = 0; pending == null && i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(pending, isNotNull);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final first = tester.getRect(_marker);
      expect(first.width, lessThan(before.width));
      await tester.pump(const Duration(milliseconds: 420));
      final moving = tester.getRect(_marker);
      expect(moving.left, isNot(closeTo(first.left, .1)));
      expect(moving.bottom, before.bottom);
      expect(
        tester.getTopLeft(find.byKey(const Key('task-properties'))),
        propertiesTop,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('task-save')))
            .onPressed,
        isNull,
      );
      await harness.capture(tester, 'menu-polish-testing');
      if (success) {
        pending!.resolve(
          Response(
            requestOptions: request!,
            statusCode: 200,
            data: {
              'choices': [
                {
                  'message': {
                    'content':
                        '{"fields":[{"id":"sample","groups":[{"ids":["sample-1"],"zh":"蓝眼睛女孩"}]}]}',
                  },
                },
              ],
            },
          ),
        );
      } else {
        pending!.reject(
          DioException(
            requestOptions: request!,
            type: DioExceptionType.connectionError,
            message: 'Offline failure',
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(tester.getRect(_marker), before);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('task-save')))
            .onPressed,
        isNotNull,
      );
      if (success) {
        expect(find.text('蓝眼睛女孩'), findsWidgets);
      } else {
        expect(find.byKey(const Key('task-message')), findsOneWidget);
      }
      await harness.capture(
        tester,
        'menu-polish-${success ? 'success' : 'failure'}',
      );
      await harness.tapVisible(tester, find.byKey(const Key('task-save')));
      expect(tester.getRect(_marker), before);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('marker stops on cancellation, reduced motion and disposal', (
    tester,
  ) async {
    Future<void> pump(
      bool active, {
      bool reduced = false,
      bool visible = true,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: visible,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: ManagementTabs(
                  labels: const ['模型与预设', '提示词与输出'],
                  selected: 0,
                  onSelected: (_) {},
                  inProgress: active,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final marker = find.byKey(const Key('management-tab-underline'));
    await pump(false);
    final before = tester.getRect(marker);
    await pump(true);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(marker).width, lessThan(before.width));
    await pump(false);
    await tester.pumpAndSettle();
    expect(tester.getRect(marker), before);
    for (final reduced in [true, false]) {
      await pump(true, reduced: reduced, visible: reduced);
      await tester.pumpAndSettle();
      expect(tester.getRect(marker), before);
    }
    await pump(true);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
