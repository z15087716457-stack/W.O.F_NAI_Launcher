import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/local_upscale_panel.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/local_upscale_settings_section.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import '../../../../helpers/studio_capture_fonts.dart';

class _Storage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Workflow extends ImageWorkflowController {
  @override
  ImageWorkflowState build() => const ImageWorkflowState(
    mode: ImageWorkflowMode.upscale,
    sourceWidth: 832,
    sourceHeight: 1216,
  );
}

class _FailedInstallState extends AdvancedUpscaleInstall {
  @override
  AdvancedUpscaleInstallState build() => const AdvancedUpscaleInstallState(
    phase: 'runtime',
    error: LocalUpscaleError.modelOperationFailed,
    details: 'uv pip: exit 2\nTLS handshake failed',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    testWidgets(
      'installation failure exposes phase and copyable diagnostics in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 650);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWith((ref) => _Storage()),
              generationParamsNotifierProvider.overrideWith(_Params.new),
              localUpscaleModelsProvider.overrideWith((ref) async => []),
              advancedUpscaleInstallProvider.overrideWith(
                _FailedInstallState.new,
              ),
            ],
            child: MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: GeistTheme.light,
              home: const Scaffold(body: LocalUpscaleSettingsSection()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final diagnostics = find.byKey(
          const ValueKey('advanced-upscale-install-diagnostics'),
        );
        await tester.scrollUntilVisible(diagnostics, 200);
        final l10n = AppLocalizations.of(tester.element(diagnostics))!;
        expect(
          find.text(
            l10n.localUpscale_installFailed(
              l10n.localUpscale_installingRuntime,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<SelectableText>(diagnostics).data,
          contains('TLS handshake failed'),
        );
        expect(tester.takeException(), isNull);
      },
    );
    for (final dark in [false, true]) {
      for (final width in [320.0, 560.0]) {
        for (final settings in [false, true]) {
          final id =
              '${locale.toString()}-${dark ? 'dark' : 'light'}-${width.toInt()}-${settings ? 'models' : 'panel'}';
          testWidgets(
            'local upscale layout $id',
            (tester) async {
              tester.view.physicalSize = Size(width, 650);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final key = GlobalKey();
              final container = ProviderContainer(
                overrides: [
                  localStorageServiceProvider.overrideWith((ref) => _Storage()),
                  generationParamsNotifierProvider.overrideWith(_Params.new),
                  imageGenerationNotifierProvider.overrideWith(_Generation.new),
                  imageWorkflowControllerProvider.overrideWith(_Workflow.new),
                  localUpscaleModelsProvider.overrideWith(
                    (ref) async => [
                      localUpscaleCatalog.first.withInstalled(true),
                      ...localUpscaleCatalog.skip(1),
                    ],
                  ),
                ],
              );
              addTearDown(container.dispose);
              await tester.pumpWidget(
                UncontrolledProviderScope(
                  container: container,
                  child: MaterialApp(
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: dark ? GeistTheme.dark : GeistTheme.light,
                    home: Scaffold(
                      body: RepaintBoundary(
                        key: key,
                        child: ColoredBox(
                          color: (dark ? GeistTheme.dark : GeistTheme.light)
                              .colorScheme
                              .surface,
                          child: settings
                              ? const LocalUpscaleSettingsSection()
                              : const Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: LocalUpscalePanel(
                                      onCloudStart: _noop,
                                      cloudRunning: false,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
                await tester.runAsync(() async {
                  final boundary =
                      key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary;
                  final image = await boundary.toImage(pixelRatio: 1);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final directory = Directory(
                    '.dart_tool/advanced-upscale-20261005/captures',
                  );
                  await directory.create(recursive: true);
                  await File(
                    '${directory.path}/$id.png',
                  ).writeAsBytes(bytes!.buffer.asUint8List());
                  image.dispose();
                });
              }
            },
            variant: TargetPlatformVariant.only(TargetPlatform.windows),
          );
        }
      }
    }
  }
}

void _noop() {}
