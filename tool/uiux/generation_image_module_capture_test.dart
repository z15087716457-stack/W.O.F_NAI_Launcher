import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../test/helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('capture image module with real fonts and synthetic settings', (
    tester,
  ) async {
    final output = Directory('.dart_tool/uiux-task02/captures')
      ..createSync(recursive: true);
    final rows = <Map<String, Object?>>[];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final language in ['zh', 'en', 'ja', 'ko']) {
      for (final dark in [false, true]) {
        for (final width in [352.0, 420.0, 560.0, 320.0]) {
          final explore = width == 320;
          final theme = dark ? GeistTheme.dark : GeistTheme.light;
          tester.view.physicalSize = Size(width, 240);
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                localStorageServiceProvider.overrideWith(
                  (ref) => _MemoryStorage(),
                ),
              ],
              child: MaterialApp(
                theme: theme,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: RepaintBoundary(
                  key: const Key('capture'),
                  child: Builder(
                    builder: (context) => ColoredBox(
                      color: theme.colorScheme.surface,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: GenerationModuleCard(
                            key: const Key('module'),
                            title: AppLocalizations.of(
                              context,
                            )!.generation_moduleImage,
                            children: [
                              const SizeSection(
                                layout: SizeSectionLayout.moduleRow,
                              ),
                              ImageCountSection(
                                layout: ImageCountSectionLayout.moduleRow,
                                showPerRequestSegments: !explore,
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          final rect = tester.getRect(find.byKey(const Key('module')));
          final name =
              '${explore ? 'explore' : 'image'}-$language-${dark ? 'dark' : 'light'}-${width.toInt()}';
          rows.add({
            'name': name,
            'width': width,
            'locale': language,
            'dark': dark,
            'explore': explore,
            'module': {
              'x': rect.left,
              'y': rect.top,
              'width': rect.width,
              'height': rect.height,
            },
          });
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            try {
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '${output.path}/$name.png',
              ).writeAsBytesSync(data!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      }
    }
    File(
      '.dart_tool/uiux-task02/capture-measurements.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
  });
}

class _MemoryStorage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values.containsKey(key) ? values[key] as T? : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}
