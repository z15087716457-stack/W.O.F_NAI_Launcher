import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_cache_database.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/danbooru_completion_source.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/presentation/screens/local_gallery/local_gallery_screen.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/prompt_block_library_screen.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/settings/studio_theme_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/light_theme_contrast.dart';
import '../../helpers/studio_capture_fonts.dart';

class _Shortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _NoTranslations implements TranslationResolver {
  const _NoTranslations();
  @override
  Future<Map<String, String>> resolve(
    List<String> tags, {
    required String locale,
  }) async => {};
}

class _NoRemote extends DanbooruCompletionSource {
  _NoRemote() : super(cache: AutocompleteCacheDatabase());
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [];
}

class _Gallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState(isInitialized: true);
  @override
  Future<void> initialize() async {}
  @override
  Future<void> setNaiOnly(bool value) async {}
  @override
  Future<void> setThumbnailQuality(GalleryThumbnailQuality quality) async {}
}

class _Categories extends GalleryCategoryNotifier {
  @override
  GalleryCategoryState build() => const GalleryCategoryState();
}

class _Collections extends CollectionNotifier {
  @override
  CollectionState build() => const CollectionState();
  @override
  Future<void> initialize() async {}
}

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      for (final (id, title, content) in [
        ('city', '雨夜都市', 'city lights, rainy night, reflections'),
        ('portrait', '角色肖像', 'portrait, soft lighting, detailed eyes'),
        ('pixel', '像素世界', 'pixel art, isometric, intricate details'),
        ('film', '电影光影', 'cinematic lighting, depth of field'),
      ])
        PromptBlock.create(
          id: id,
          title: title,
          content: content,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
    ],
    folders: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final brightness in Brightness.values) {
    for (final (name, screen) in <(String, Widget)>[
      ('gallery', const LocalGalleryScreen()),
      ('blocks', const PromptBlockLibraryScreen()),
      (
        'appearance',
        const Scaffold(
          body: Center(child: SizedBox(width: 420, child: StudioThemePicker())),
        ),
      ),
    ]) {
      testWidgets('$name uses ${brightness.name} surfaces and readable text', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({
          StorageKeys.hasSeenLocalGalleryTip: true,
        });
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final storage = InMemoryLocalStorageService();
        await storage.setStudioThemeMode(brightness.name);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWithValue(storage),
              shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
              zhDictionaryServiceProvider.overrideWith(
                (ref) => ZhDictionaryService(),
              ),
              autocompleteServicesProvider.overrideWithValue(
                AutocompleteServices(
                  localSources: [],
                  dictionaryTranslations: const _NoTranslations(),
                  llmTranslations: const _NoTranslations(),
                  danbooru: _NoRemote(),
                ),
              ),
              localGalleryNotifierProvider.overrideWith(_Gallery.new),
              galleryCategoryNotifierProvider.overrideWith(_Categories.new),
              collectionNotifierProvider.overrideWith(_Collections.new),
              galleryFavoriteCountProvider.overrideWith((ref) async => 0),
              promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ref.watch(studioLightThemeProvider),
                darkTheme: ref.watch(studioDarkThemeProvider),
                themeMode: ref.watch(themeNotifierProvider) == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                locale: const Locale('zh'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: boundary,
                  child: IntegratedTitleBarShell(child: screen),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final theme = Theme.of(tester.element(find.byWidget(screen)));
        expect(theme.brightness, brightness);
        expect(
          theme.scaffoldBackgroundColor,
          brightness == Brightness.dark
              ? const Color(0xFF181818)
              : Colors.white,
        );
        if (brightness == Brightness.light) {
          expectNoUnreadableLightText(tester, panelName: name);
        }
        if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
          await tester.runAsync(() async {
            await precacheImage(
              const AssetImage('assets/images/wof_logo_block.png'),
              tester.element(find.byWidget(screen)),
            );
          });
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 1.5);
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File(
              '.dart_tool/geist-captures/$name-${brightness.name}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
