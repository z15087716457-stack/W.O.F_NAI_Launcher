import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_params_menu_host.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import '../../test/helpers/light_theme_contrast.dart';
import '../../test/helpers/studio_capture_fonts.dart';

class _Storage extends InMemoryLocalStorageService {
  @override
  int getDefaultSteps() => 28;
  @override
  double getDefaultScale() => 5;
  @override
  String getDefaultSampler() => Samplers.kDpmpp2mSde;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('capture summary with both seed modes and drawer states', (
    tester,
  ) async {
    final root = Directory('.dart_tool/uiux-task05/captures')
      ..createSync(recursive: true);
    final measurements = <Map<String, Object?>>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['zh', 'en', 'ja', 'ko']) {
      for (final dark in [false, true]) {
        for (final width in [352.0, 420.0]) {
          for (final pinned in [false, true]) {
            for (final open in [false, true]) {
              tester.view.physicalSize = Size(width, 700);
              final container = createStorageFreeContainer(
                overrides: [
                  localStorageServiceProvider.overrideWithValue(_Storage()),
                ],
              );
              if (pinned) {
                container
                    .read(generationParamsNotifierProvider.notifier)
                    .updateSeed(3274348526);
              }
              final theme = dark ? GeistTheme.dark : GeistTheme.light;
              await tester.pumpWidget(
                UncontrolledProviderScope(
                  container: container,
                  child: MaterialApp(
                    theme: theme,
                    locale: Locale(language),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    home: Scaffold(
                      body: RepaintBoundary(
                        key: const Key('capture'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border(
                              right: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          child: const GenerationParamsMenuHost(
                            child: SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              if (open) {
                await tester.tap(find.byKey(const Key('params-drawer-toggle')));
                await tester.pumpAndSettle();
              }
              expect(tester.takeException(), isNull);
              final rect = tester.getRect(
                find.byType(GenerationParamsSummaryBar),
              );
              final name =
                  'summary-${pinned ? 'pinned' : 'random'}-${open ? 'open' : 'closed'}-$language-${dark ? 'dark' : 'light'}-${width.toInt()}';
              final rotation = tester
                  .widget<RotationTransition>(
                    find.descendant(
                      of: find.byKey(const Key('params-drawer-toggle')),
                      matching: find.byType(RotationTransition),
                    ),
                  )
                  .turns
                  .value;
              expect(rotation, open ? 0.5 : 0);
              measurements.add({
                'name': name,
                'locale': language,
                'dark': dark,
                'open': open,
                'pinned': pinned,
                'rotation': rotation,
                'summary': {
                  'x': rect.left,
                  'y': rect.top,
                  'width': rect.width,
                  'height': rect.height,
                },
              });
              await tester.runAsync(() async {
                final image = await tester
                    .renderObject<RenderRepaintBoundary>(
                      find.byKey(const Key('capture')),
                    )
                    .toImage(pixelRatio: 1);
                try {
                  final data = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  File(
                    '${root.path}/$name.png',
                  ).writeAsBytesSync(data!.buffer.asUint8List());
                } finally {
                  image.dispose();
                }
              });
              await tester.pumpWidget(const SizedBox());
              await tester.pumpAndSettle();
              container.dispose();
            }
          }
        }
      }
    }
    File('.dart_tool/uiux-task05/capture-measurements.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(measurements),
    );
  });
}
