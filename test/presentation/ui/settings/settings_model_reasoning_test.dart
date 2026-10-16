import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

const _models = SettingsModelsData(
  providers: [
    SettingsProvider(
      id: 'p',
      name: 'Fixture',
      protocol: 'Fixture',
      mark: 'F',
      color: 0xff266eff,
      models: [
        SettingsModel(
          id: 'supported',
          reasoningEfforts: ['none', 'low', 'medium'],
          defaultReasoningEffort: 'medium',
        ),
        SettingsModel(id: 'unsupported', reasoningEfforts: []),
        SettingsModel(id: 'unknown'),
      ],
    ),
  ],
  assignments: [
    SettingsTaskAssignment(
      task: SettingsModelTask.promptTranslate,
      providerId: 'p',
      modelId: 'supported',
      reasoningEffort: 'low',
    ),
    SettingsTaskAssignment(
      task: SettingsModelTask.promptReverse,
      providerId: 'p',
      modelId: 'supported',
    ),
    SettingsTaskAssignment(
      task: SettingsModelTask.tagTranslate,
      providerId: 'p',
      modelId: 'unsupported',
    ),
    SettingsTaskAssignment(
      task: SettingsModelTask.wikiTranslate,
      providerId: 'p',
      modelId: 'unknown',
    ),
  ],
);

Future<SettingsRecorder> _pump(
  WidgetTester t, {
  String locale = 'zh',
  double width = 1600,
  bool dark = false,
  double scale = 1,
}) async {
  t.platformDispatcher.textScaleFactorTestValue = 1;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final d = SettingsFixture.view(page: SettingsPageId.models);
  final rec = await pumpSettings(
    t,
    data: d.copyWith(models: _models),
    locale: locale,
    window: width,
    height: 1400,
    dark: dark,
  );
  await t.tap(find.byKey(const Key('models-tab-tasks')));
  await t.pumpAndSettle();
  t.platformDispatcher.textScaleFactorTestValue = scale;
  await t.pumpAndSettle();
  return rec;
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'thinking overrides and inheritance stay distinct and target only the chosen interface',
    (t) async {
      final rec = await _pump(t);
      const key = Key('assign-reasoning-promptTranslate');
      final select = t.widget<SettingsSelect>(find.byKey(key));
      expect(select.selected, 'low');
      expect(select.options.map((o) => o.value), [
        'inherit',
        'none',
        'low',
        'medium',
      ]);
      for (final value in ['medium', 'none', 'inherit']) {
        await t.tap(find.byKey(key));
        await t.pumpAndSettle();
        await t.tap(find.byKey(Key('settings-option-$value')));
        await t.pumpAndSettle();
      }
      expect(rec.calls, [
        'assign:promptTranslate:p:supported:medium:false',
        'assign:promptTranslate:p:supported:none:false',
        'assign:promptTranslate:p:supported:null:true',
      ]);
    },
  );

  testWidgets('unsupported and unknown models do not invent thinking levels', (
    t,
  ) async {
    await _pump(t);
    final unsupported = t.widget<SettingsSelect>(
      find.byKey(const Key('assign-reasoning-tagTranslate')),
    );
    expect(unsupported.options, isEmpty);
    final unknown = t.widget<SettingsSelect>(
      find.byKey(const Key('assign-reasoning-wikiTranslate')),
    );
    expect(unknown.options.map((o) => o.value), ['inherit']);
    final inherited = t.widget<SettingsSelect>(
      find.byKey(const Key('assign-reasoning-promptReverse')),
    );
    expect(inherited.selected, 'inherit');
    final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
    expect(inherited.label, l.modelReasoning_followModel);
    expect(
      inherited.options.first.detail,
      l.modelReasoning_modelDefault(l.modelReasoning_medium),
    );
  });

  testWidgets(
    'question mark shows the structured output recommendation on hover',
    (t) async {
      await _pump(t);
      final help = find.byKey(const Key('models-reasoning-help'));
      final l = AppLocalizations.of(t.element(help))!;
      expect(t.widget<Tooltip>(help).message, l.modelSettings_reasoningHelp);
      final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(help));
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpAndSettle();
      expect(find.text(l.modelSettings_reasoningHelp), findsOneWidget);
    },
  );

  testWidgets(
    'six columns stay aligned and narrow windows scroll, with five languages and large text',
    (t) async {
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
        for (final (width, scale) in [
          (1600.0, 1.0),
          (900.0, 1.0),
          (1600.0, 1.5),
        ]) {
          await t.pumpWidget(const SizedBox.shrink());
          await _pump(
            t,
            locale: locale,
            width: width,
            dark: width == 900,
            scale: scale,
          );
          final model = t.getRect(
            find.byKey(const Key('assign-model-promptTranslate')),
          );
          final thinking = t.getRect(
            find.byKey(const Key('assign-reasoning-promptTranslate')),
          );
          final preset = t.getRect(
            find.byKey(const Key('assign-preset-promptTranslate')),
          );
          expect(model.right, lessThan(thinking.left));
          expect(thinking.right, lessThan(preset.left));
          expect(model.top, thinking.top);
          expect(thinking.top, preset.top);
          final scroll = find.descendant(
            of: find.byKey(const Key('models-task-scroll')),
            matching: find.byType(Scrollable),
          );
          final position = t.state<ScrollableState>(scroll).position;
          if (width == 900 || scale > 1) {
            expect(position.maxScrollExtent, greaterThan(0));
          }
          expect(
            t
                .widget<Scrollbar>(
                  find.byKey(const Key('models-task-scrollbar')),
                )
                .thumbVisibility,
            isTrue,
          );
          expect(
            t.widget<Text>(find.byKey(const Key('models-task-hint'))).textAlign,
            TextAlign.right,
          );
          expect(t.takeException(), isNull);
          await _capture(t, '$locale-${width.toInt()}-$scale');
          if (width == 900) {
            await t.drag(
              find.byKey(const Key('models-task-scroll')),
              const Offset(-600, 0),
            );
            await t.pumpAndSettle();
            final viewport = t.getRect(
              find.byKey(const Key('models-task-scroll')),
            );
            final visiblePreset = t.getRect(
              find.byKey(const Key('assign-preset-promptTranslate')),
            );
            expect(visiblePreset.left, greaterThanOrEqualTo(viewport.left));
            expect(visiblePreset.right, lessThanOrEqualTo(viewport.right));
            expect(t.takeException(), isNull);
            await _capture(t, '$locale-${width.toInt()}-$scale-scrolled');
          }
        }
      }
    },
  );
}

Future<void> _capture(WidgetTester t, String name) async {
  final dir = Platform.environment['MODEL_REASONING_CAPTURE_DIR'];
  if (dir == null) return;
  final box = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('settings-capture')),
  );
  await t.runAsync(() async {
    Directory(dir).createSync(recursive: true);
    final image = await box.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}
