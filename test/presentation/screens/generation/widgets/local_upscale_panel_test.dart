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
import 'package:nai_launcher/presentation/widgets/common/editable_double_field.dart';
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

class _SeedWorkflow extends ImageWorkflowController {
  @override
  ImageWorkflowState build() => const ImageWorkflowState(
    mode: ImageWorkflowMode.upscale,
    sourceWidth: 832,
    sourceHeight: 1216,
    upscale: UpscaleWorkflowSettings(localModel: 'seedvr2-3b'),
  );
}

class _BusyLocalTask extends LocalUpscaleTask {
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState(running: true);
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
  for (final busy in [false, true]) {
    testWidgets(
      'missing 7B is selectable without download or fallback; busy=$busy',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWith((_) => _Storage()),
            generationParamsNotifierProvider.overrideWith(_Params.new),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            imageWorkflowControllerProvider.overrideWith(_SeedWorkflow.new),
            if (busy) localUpscaleTaskProvider.overrideWith(_BusyLocalTask.new),
            localUpscaleModelsProvider.overrideWith(
              (_) async => [
                for (final model in localUpscaleCatalog)
                  model.withInstalled(model.id == 'general'),
                for (final model in advancedUpscaleCatalog)
                  model.withInstalled(model.id == 'seedvr2-3b'),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: GeistTheme.light,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: LocalUpscalePanel(
                    onCloudStart: _noop,
                    cloudRunning: false,
                    sourceWidth: 832,
                    sourceHeight: 1216,
                  ),
                ),
              ),
            ),
          ),
        );
        if (busy) {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          await tester.pumpAndSettle();
        }
        final dropdown = find.byType(DropdownButtonFormField<String>);
        if (busy) {
          expect(
            tester.widget<DropdownButtonFormField<String>>(dropdown).onChanged,
            isNull,
          );
          expect(
            tester
                .widget<ExpansionTile>(
                  find.byKey(const ValueKey('seedvr2-advanced-toggle')),
                )
                .enabled,
            isFalse,
          );
        } else {
          expect(
            tester
                .widget<FilledButton>(
                  find.byWidgetPredicate((widget) => widget is FilledButton),
                )
                .onPressed,
            isNotNull,
          );
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(tester.element(dropdown))!;
          await tester.tap(
            find.text('SeedVR2 7B FP8 · ${l.localUpscale_notInstalled}').last,
          );
          await tester.pumpAndSettle();
          expect(
            container.read(imageWorkflowControllerProvider).upscale.localModel,
            'seedvr2-7b',
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byWidgetPredicate((widget) => widget is FilledButton),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(find.text('RTX'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('SeedVR2'));
          await tester.pumpAndSettle();
          expect(
            container.read(imageWorkflowControllerProvider).upscale.localModel,
            'seedvr2-7b',
          );
          container
              .read(imageWorkflowControllerProvider.notifier)
              .updateLocalUpscaleModel('anime');
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<DropdownButtonFormField<String>>(dropdown)
                .initialValue,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 560.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          final id =
              '${locale.toString()}-${dark ? 'dark' : 'light'}-${width.toInt()}-$scale';
          testWidgets(
            'SeedVR2 advanced settings remain compact and usable $id',
            (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final boundary = GlobalKey();
              final container = ProviderContainer(
                overrides: [
                  localStorageServiceProvider.overrideWith((_) => _Storage()),
                  generationParamsNotifierProvider.overrideWith(_Params.new),
                  imageGenerationNotifierProvider.overrideWith(_Generation.new),
                  imageWorkflowControllerProvider.overrideWith(
                    _SeedWorkflow.new,
                  ),
                  localUpscaleModelsProvider.overrideWith(
                    (_) async => [
                      ...localUpscaleCatalog,
                      for (final model in advancedUpscaleCatalog)
                        model.withInstalled(model.id == 'seedvr2-3b'),
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
                    home: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Scaffold(
                        body: RepaintBoundary(
                          key: boundary,
                          child: ColoredBox(
                            color: (dark ? GeistTheme.dark : GeistTheme.light)
                                .colorScheme
                                .surface,
                            child: const SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: LocalUpscalePanel(
                                  onCloudStart: _noop,
                                  cloudRunning: false,
                                  framed: false,
                                ),
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
              final toggle = find.byKey(
                const ValueKey('seedvr2-advanced-toggle'),
              );
              final l = AppLocalizations.of(tester.element(toggle))!;
              expect(find.byKey(const ValueKey('seedvr2-seed')), findsNothing);
              await _captureSeedvr2(tester, boundary, '$id-collapsed');
              await tester.tap(toggle);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('seedvr2-seed')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('seedvr2-input-noise')),
                findsNothing,
              );
              tester
                  .widget<EditableDoubleField>(
                    find.byKey(const ValueKey('seedvr2-seed')),
                  )
                  .onChanged(123);
              tester
                  .widget<Slider>(find.byKey(const ValueKey('seedvr2-blocks')))
                  .onChanged!(8);
              await tester.pumpAndSettle();
              final updated = container
                  .read(imageWorkflowControllerProvider)
                  .upscale
                  .selectedSeedvr2Options;
              expect((updated.seed, updated.blocksToSwap), (123, 8));
              final stale = tester
                  .widget<Slider>(find.byKey(const ValueKey('seedvr2-blocks')))
                  .onChanged!;
              final controller = container.read(
                imageWorkflowControllerProvider.notifier,
              );
              controller.updateLocalUpscaleModel('seedvr2-7b');
              stale(16);
              expect(
                container
                    .read(imageWorkflowControllerProvider)
                    .upscale
                    .selectedSeedvr2Options
                    .blocksToSwap,
                0,
              );
              controller.updateLocalUpscaleModel('seedvr2-3b');
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.text(l.localUpscale_memoryLow));
              await tester.tap(find.text(l.localUpscale_memoryLow));
              await tester.pumpAndSettle();
              expect(
                container
                    .read(imageWorkflowControllerProvider)
                    .upscale
                    .selectedSeedvr2Options
                    .blocksToSwap,
                32,
              );
              final experimental = find.byKey(
                const ValueKey('seedvr2-experimental-toggle'),
              );
              await tester.ensureVisible(experimental);
              await tester.tap(experimental);
              await tester.pumpAndSettle();
              expect(
                find.byKey(const ValueKey('seedvr2-input-noise')),
                findsOneWidget,
              );
              await _captureSeedvr2(tester, boundary, '$id-expanded');
              final reset = find.byKey(const ValueKey('seedvr2-reset'));
              await tester.ensureVisible(reset);
              await tester.tap(reset);
              await tester.pumpAndSettle();
              expect(
                container
                    .read(imageWorkflowControllerProvider)
                    .upscale
                    .selectedSeedvr2Options
                    .toJson(),
                const Seedvr2Options().toJson(),
              );
              expect(tester.takeException(), isNull);
            },
            variant: TargetPlatformVariant.only(TargetPlatform.windows),
          );
        }
      }
    }
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

Future<void> _captureSeedvr2(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (Platform.environment['CAPTURE_SEEDVR2_OPTIONS'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(
      Platform.environment['CAPTURE_UI_FEEDBACK'] == '1'
          ? '.dart_tool/ui-feedback-20261006/captures/seedvr2'
          : '.dart_tool/seedvr2-options-20261006/captures',
    );
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void _noop() {}
