import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/rag_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import '../../../helpers/studio_capture_fonts.dart';

class _FakeRag extends RagController {
  @override
  RagStatus build() => const RagStatus(
    phase: 'partial',
    indexed: 1200,
    total: 5000,
    partial: true,
    bytes: 5242880,
  );
}

class _EnabledSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(enabled: true);
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    await Hive.openBox(StorageKeys.settingsBox, bytes: Uint8List(0));
  });
  tearDown(Hive.close);
  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final width in [280.0, 760.0]) {
        testWidgets('RAG settings ${locale.toLanguageTag()} $brightness $width', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width + 32, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ragControllerProvider.overrideWith(_FakeRag.new),
                ragSettingsProvider.overrideWith(_EnabledSettings.new),
              ],
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: settingsUiTheme(
                  ThemeData(
                    brightness: brightness,
                    fontFamily: 'HarmonyOS Sans SC',
                  ),
                ),
                home: RepaintBoundary(
                  key: key,
                  child: Scaffold(
                    body: SettingsTypographyScope(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          controller: scroll,
                          child: const RagSettingsSection(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final directory = Directory('.dart_tool/rag-20261015/captures');
          Future<void> capture(String part) async {
            await tester.runAsync(() async {
              await directory.create(recursive: true);
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              await File(
                '${directory.path}/settings-${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}-$part.png',
              ).writeAsBytes(data!.buffer.asUint8List());
            });
          }

          await capture('top');
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pump();
          expect(tester.takeException(), isNull);
          await capture('bottom');
        });
      }
    }
  }
}
