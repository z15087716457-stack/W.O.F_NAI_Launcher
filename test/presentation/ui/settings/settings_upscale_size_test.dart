import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/advanced_upscale_component_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_model_manager.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_format.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_upscale.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  late List<LocalUpscaleModel> models;
  setUpAll(() async {
    await loadStudioCaptureFonts();
    final temporary = await Directory.systemTemp.createTemp('upscale-size-ui-');
    final base = LocalUpscaleModelManager(
      rootDirectory: () async => Directory('${temporary.path}/base'),
      loadAsset: (name) => File('assets/local_upscale/$name').readAsBytes(),
    );
    final advanced = AdvancedUpscaleComponentManager(
      rootDirectory: () async => Directory('${temporary.path}/advanced'),
      loadAsset: (name) => File('assets/local_upscale/$name').readAsBytes(),
    );
    try {
      models = [...await base.models(), ...await advanced.models()];
    } finally {
      base.dispose();
      advanced.dispose();
      await temporary.delete(recursive: true);
    }
  });

  SettingsViewData view({
    bool installed = false,
    SettingsUpscaleOperation operation = const SettingsUpscaleOperation(),
  }) => SettingsFixture.view(page: SettingsPageId.upscale).copyWith(
    upscale: settingsUpscaleData(
      [
        for (final model in models)
          model.withInstalled(model.bundled || installed),
      ],
      operation,
      const AdvancedUpscaleInstallState(),
      const UpscaleWorkflowSettings(),
    ),
  );

  testWidgets(
    'all catalog cards retain readable sizes before and after installation',
    (t) async {
      for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
        for (final width in [900.0, 1600.0]) {
          await t.pumpWidget(const SizedBox.shrink());
          await pumpSettings(
            t,
            data: view(),
            window: width,
            height: 2100,
            locale: locale,
            dark: width == 900,
          );
          for (final installed in [false, true]) {
            t
                .state<SettingsHostState>(find.byType(SettingsHost))
                .updateData(view(installed: installed));
            await t.pumpAndSettle();
            final data = view(installed: installed).upscale;
            for (final model in [...data.esrgan, ...data.seed]) {
              final card = find.byKey(Key('upscale-${model.id}'));
              final label = find.descendant(
                of: card,
                matching: find.text(SettingsFormat.bytes(model.bytes)),
              );
              expect(model.bytes, greaterThan(0));
              expect(label, findsOneWidget);
              expect(t.getRect(card).contains(t.getRect(label).center), isTrue);
            }
            expect(find.text('0 B'), findsNothing);
            expect(t.takeException(), isNull);
            final output =
                Platform.environment['SETTINGS_UPSCALE_SIZE_CAPTURE_DIR'];
            if (output != null && locale == 'zh') {
              final box = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('settings-capture')),
              );
              await t.runAsync(() async {
                Directory(output).createSync(recursive: true);
                final image = await box.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File(
                  '$output/$locale-${width.toInt()}-${installed ? 'installed' : 'before'}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
    },
  );

  testWidgets(
    'transfer progress uses archive total rather than fixed model size',
    (t) async {
      await pumpSettings(
        t,
        data: view(
          operation: const SettingsUpscaleOperation(
            id: 'general',
            received: 40000000,
            total: 80000000,
          ),
        ),
      );
      final card = find.byKey(const Key('upscale-general'));
      expect(
        find.descendant(of: card, matching: find.text('50%')),
        findsOneWidget,
      );
      expect(
        t
            .widget<SettingsBar>(
              find.descendant(of: card, matching: find.byType(SettingsBar)),
            )
            .value,
        .5,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining(SettingsFormat.bytes(80000000)),
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
}
