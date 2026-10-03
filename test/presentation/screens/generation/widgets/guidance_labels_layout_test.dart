import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_params_menu_host.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import '../../../../helpers/studio_capture_fonts.dart';

class _Params extends GenerationParamsNotifier {
  _Params(this.seed);
  final int seed;
  @override
  ImageParams build() => ImageParams(
    model: ImageModels.animeDiffusionV4Full,
    seed: seed,
    scale: 6,
    cfgRescale: .66,
  );
}

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in AppLocalizations.supportedLocales) {
    for (final dark in [false, true]) {
      for (final width in [400.0, 280.0]) {
        for (final pinned in [false, true]) {
          testWidgets(
            'full guidance names ${locale.toLanguageTag()} dark=$dark width=$width pinned=$pinned',
            (tester) async {
              final capture = GlobalKey();
              final base = dark ? GeistTheme.dark : GeistTheme.light;
              await tester.pumpWidget(
                ProviderScope(
                  overrides: [
                    generationParamsNotifierProvider.overrideWith(
                      () => _Params(pinned ? 1234567890 : -1),
                    ),
                  ],
                  child: MaterialApp(
                    locale: locale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    theme: base.copyWith(
                      textTheme: base.textTheme.apply(
                        fontFamily: StudioTypography.sans,
                        fontFamilyFallback: StudioTypography.fallback,
                      ),
                    ),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(width == 280 ? 1.3 : 1),
                      ),
                      child: child!,
                    ),
                    home: Scaffold(
                      body: Center(
                        child: RepaintBoundary(
                          key: capture,
                          child: SizedBox(
                            width: width,
                            child: Material(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        CfgScaleSection(),
                                        AdvancedSamplingOptions(),
                                      ],
                                    ),
                                  ),
                                  GenerationParamsSummaryBar(
                                    onToggleDrawer: () {},
                                    arrow: const Icon(
                                      Icons.arrow_drop_up,
                                      size: 18,
                                    ),
                                  ),
                                ],
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
              final l10n = AppLocalizations.of(
                tester.element(find.byType(CfgScaleSection)),
              )!;
              expect(
                find.text(l10n.generation_cfgScale('6.0')),
                findsOneWidget,
              );
              expect(
                find.text(l10n.generation_cfgRescale('0.66')),
                findsOneWidget,
              );
              expect(find.text(l10n.generation_guidance), findsOneWidget);
              expect(find.text('PG'), findsNothing);
              expect(find.text('PGR'), findsNothing);
              expect(find.text('6.0'), findsOneWidget);
              if (pinned) expect(find.text('1234567890'), findsOneWidget);
              expect(tester.takeException(), isNull);
              if (Platform.environment['CAPTURE_GUIDANCE_LABELS'] == '1' &&
                  !dark &&
                  width == 400 &&
                  pinned &&
                  (locale.languageCode == 'en' ||
                      locale == const Locale('zh'))) {
                await tester.runAsync(() async {
                  final boundary =
                      capture.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary;
                  final image = await boundary.toImage();
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  final dir = Directory('.dart_tool/guidance-labels-captures')
                    ..createSync(recursive: true);
                  File(
                    '${dir.path}/${locale.toLanguageTag()}.png',
                  ).writeAsBytesSync(bytes!.buffer.asUint8List());
                  image.dispose();
                });
              }
            },
          );
        }
      }
    }
  }
}
