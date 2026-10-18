import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_kit.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_models.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;
import '../ui/settings/settings_test_harness.dart';

Future<SettingsModelsData> _project(
  WidgetTester tester,
  List<ProviderConfig> providers,
) async {
  final storage = MemorySettings();
  storage.values[StorageKeys.promptAssistantConfigJson] =
      PromptAssistantConfigState(
        providers: providers,
        models: const [],
        interfaces: const {},
        providerHasApiKey: const {},
        presets: const [],
      ).encode();
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(storage),
      secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
    ],
  );
  addTearDown(container.dispose);
  late SettingsModelsData view;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Consumer(
          builder: (context, ref, _) {
            view = settingsModelsData(context, ref);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return view;
}

Finder _asset(String name) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName ==
          'assets/icons/providers/$name.svg',
);

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['CAPTURE_PROVIDER_LOGOS'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('settings-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() {
    final previous = ModelCatalogRepository.cached;
    ModelCatalogRepository.cached = ModelCatalogRepository.empty;
    addTearDown(() => ModelCatalogRepository.cached = previous);
  });

  testWidgets('saved vendor identity survives renaming and protocol changes', (
    tester,
  ) async {
    final view = await _project(tester, [
      for (final preset in ProviderPreset.values)
        preset.createConfig().copyWith(
          name: 'My endpoint',
          protocol: ProviderProtocol.openaiChatCompletions,
          baseUrl: 'https://example.invalid/explicit/v1',
        ),
      const ProviderConfig(
        id: 'legacy-custom',
        name: 'DeepSeek custom',
        baseUrl: 'https://example.invalid/v1',
      ),
      const ProviderConfig(
        id: 'openai',
        name: 'Legacy renamed',
        baseUrl: 'https://example.invalid/v1',
      ),
    ]);
    for (var i = 0; i < ProviderPreset.values.length; i++) {
      final preset = ProviderPreset.values[i];
      final provider = view.providers[i];
      final custom =
          preset == ProviderPreset.openaiCompatibleChat ||
          preset == ProviderPreset.openaiCompatibleResponses;
      expect(provider.mark, custom ? 'MY' : isNull, reason: preset.name);
      expect(provider.logoAsset, preset.logoAsset, reason: preset.name);
      expect(provider.baseUrl, 'https://example.invalid/explicit/v1');
    }
    // A custom service's display name does not impersonate a vendor. Old saved
    // IDs still receive the existing config decoder's vendor migration.
    expect(view.providers[view.providers.length - 2].mark, 'DE');
    expect(view.providers[view.providers.length - 2].logoAsset, isNull);
    expect(view.providers.last.mark, isNull);
    expect(view.providers.last.logoAsset, 'openai');
  });

  for (final spec in [(false, 1600.0), (true, 1100.0)]) {
    testWidgets('provider list and selected header share logos: $spec', (
      tester,
    ) async {
      final models = await _project(tester, [
        ProviderPreset.deepseek.createConfig().copyWith(name: 'DeepSeek'),
        ProviderPreset.openaiCompatibleChat
            .createConfig(id: 'custom')
            .copyWith(name: 'CPA/Deniv', baseUrl: 'https://example.invalid/v1'),
        ProviderPreset.openaiResponses.createConfig(),
        ProviderPreset.xiaomi.createConfig(),
      ]);
      await pumpSettings(
        tester,
        data: SettingsFixture.view(
          page: SettingsPageId.models,
        ).copyWith(models: models),
        dark: spec.$1,
        window: spec.$2,
      );
      expect(_asset('deepseek-color'), findsNWidgets(2));
      expect(_asset('openai'), findsOneWidget);
      expect(find.text('CP'), findsOneWidget);
      expect(find.text('DE'), findsNothing);
      final row = find.byKey(const Key('mp-provider-deepseek'));
      final rowSize = tester.getSize(row);
      final icon = find.descendant(
        of: row,
        matching: find.byType(ProviderLogo),
      );
      expect(tester.getSize(icon), const Size(28, 28));
      final picture = tester.widget<SvgPicture>(_asset('deepseek-color').first);
      expect(
        picture.colorFilter,
        ColorFilter.mode(
          UiColors.of(tester.element(icon)).ink,
          BlendMode.srcIn,
        ),
      );
      await _capture(tester, 'vendors-${spec.$1 ? 'dark' : 'light'}');

      await tester.tap(find.byKey(const Key('mp-provider-custom')));
      await tester.pumpAndSettle();
      expect(find.text('CP'), findsNWidgets(2));
      expect(_asset('deepseek-color'), findsOneWidget);
      expect(tester.getSize(row), rowSize);
      await _capture(tester, 'custom-${spec.$1 ? 'dark' : 'light'}');

      await tester.tap(find.byKey(const Key('mp-provider-openai_responses')));
      await tester.pumpAndSettle();
      expect(_asset('openai'), findsNWidgets(2));
      expect(find.text('OP'), findsNothing);
      // The existing catalog lacks a MiMo SVG. Use its generic service symbol,
      // as the old UI did, instead of labeling a built-in vendor with letters.
      await tester.tap(find.byKey(const Key('mp-provider-xiaomi')));
      await tester.pumpAndSettle();
      final logos = tester.widgetList<ProviderLogo>(find.byType(ProviderLogo));
      expect(logos.where((l) => l.mark != null).length, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
