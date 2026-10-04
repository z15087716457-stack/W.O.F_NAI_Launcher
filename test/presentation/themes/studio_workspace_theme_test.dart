import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/presentation/screens/online_gallery/online_gallery_screen.dart';
import 'package:nai_launcher/presentation/screens/precise_ref_library/precise_ref_library_screen.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/data/services/gelbooru_auth_service.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/update_capsule.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_category_provider.dart';
import 'package:nai_launcher/presentation/screens/vibe_library/vibe_library_screen.dart';
import 'package:nai_launcher/presentation/screens/statistics/statistics_screen.dart';
import 'package:nai_launcher/presentation/screens/statistics/statistics_state.dart';
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

class _Vibes extends VibeLibraryNotifier {
  @override
  VibeLibraryState build() => const VibeLibraryState();
  @override
  Future<void> initialize() async {}
}

class _VibeCategories extends VibeLibraryCategoryNotifier {
  @override
  VibeLibraryCategoryState build() => const VibeLibraryCategoryState();
}

class _Stats extends StatisticsNotifier {
  @override
  StatisticsData build() => const StatisticsData(isLoading: false);
}

class _Online extends OnlineGalleryNotifier {
  @override
  OnlineGalleryState build() => const OnlineGalleryState();
  @override
  Future<void> loadPosts({bool refresh = false}) async {}
}

class _Danbooru extends DanbooruAuth {
  @override
  DanbooruAuthState build() => const DanbooruAuthState();
}

class _Gelbooru extends GelbooruAuth {
  @override
  GelbooruAuthState build() =>
      const GelbooruAuthState(status: GelbooruAuthStatus.unconfigured);
}

class _Precise extends PreciseRefLibraryNotifier {
  @override
  PreciseRefLibraryState build() => const PreciseRefLibraryState();
  @override
  Future<void> initialize() async {}
}

class _OnlineFavorites extends OnlineFavoritesNotifier {
  _OnlineFavorites() : super(OnlineFavoritesRepository.instance);
  @override
  Future<void> bindSource(GallerySourceId source) async {}
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
      'StudioIcons',
    )..addFont(rootBundle.load('assets/fonts/StudioIcons.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final brightness in Brightness.values) {
    for (final (name, screen) in <(String, Widget)>[
      ('gallery', const LocalGalleryScreen()),
      ('vibe', const VibeLibraryScreen()),
      ('vibe-wide', const VibeLibraryScreen()),
      ('online', const OnlineGalleryScreen()),
      ('precise', const PreciseRefLibraryScreen()),
      ('statistics', const StatisticsScreen()),
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
        final isLibrary = const [
          'gallery',
          'vibe',
          'vibe-wide',
          'online',
          'precise',
          'blocks',
        ].contains(name);
        tester.view.physicalSize = Size(
          name == 'vibe'
              ? 900
              : isLibrary
              ? 2200
              : 1280,
          900,
        );
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final storage = InMemoryLocalStorageService();
        await storage.setStudioThemeMode(brightness.name);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              onlineGalleryNotifierProvider.overrideWith(_Online.new),
              onlineFavoritesNotifierProvider.overrideWith(
                (ref) => _OnlineFavorites(),
              ),
              danbooruAuthProvider.overrideWith(_Danbooru.new),
              gelbooruAuthProvider.overrideWith(_Gelbooru.new),
              preciseRefLibraryNotifierProvider.overrideWith(_Precise.new),
              vibeLibraryNotifierProvider.overrideWith(_Vibes.new),
              vibeLibraryCategoryNotifierProvider.overrideWith(
                _VibeCategories.new,
              ),
              statisticsNotifierProvider.overrideWith(_Stats.new),
              localStorageServiceProvider.overrideWithValue(storage),
              shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
              autocompleteServicesProvider.overrideWithValue(
                AutocompleteServices(
                  localSources: [],
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
                  child: IntegratedTitleBarShell(
                    captionHeight: isLibrary ? 62 : 36,
                    accessoryWidth: isLibrary && brightness == Brightness.dark
                        ? UpdateCapsule.width
                        : 0,
                    accessory: isLibrary && brightness == Brightness.dark
                        ? UpdateCapsule(onPressed: () {})
                        : null,
                    child: screen,
                  ),
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
              ? const Color(0xFF111111)
              : Colors.white,
        );
        if (isLibrary && name != 'vibe') {
          final header = tester.getRect(find.byType(WindowHeader));
          final captions = find.byKey(const Key('window-caption-controls'));
          final minimize = find.descendant(
            of: captions,
            matching: find.byIcon(Icons.remove),
          );
          final search = find
              .descendant(
                of: find.byType(LibraryWindowHeader),
                matching: find.byType(TextField),
              )
              .first;
          if (brightness == Brightness.dark) {
            final capsule = find.byKey(const Key('window-update-capsule'));
            expect(tester.getCenter(capsule).dy, tester.getCenter(minimize).dy);
            expect(tester.getSize(capsule).height, 26);
            expect(
              tester.getRect(capsule).overlaps(tester.getRect(search)),
              isFalse,
            );
          }
          expect(
            tester.getCenter(minimize).dy,
            closeTo(tester.getCenter(search).dy, .1),
          );
          if (name != 'blocks') {
            expect(header.right, tester.getRect(captions).right);
          }
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            int pixel(int x, int y) =>
                data.getUint32((y * image.width + x) * 4);
            final y = header.bottom.floor() - 1;
            final line = pixel(header.left.ceil() + 4, y);
            expect(
              pixel(header.right.floor() - 4, y),
              line,
              reason: 'the bottom rule continues beneath the caption reserve',
            );
            expect(
              pixel(header.right.floor() - 4, y + 2),
              isNot(line),
              reason:
                  'the rule is visible rather than both samples being background',
            );
            if (name == 'blocks') {
              expect(
                pixel(image.width - 4, y),
                line,
                reason: 'the rule joins the detail rail',
              );
            }
            image.dispose();
          });
        }
        // Vibe retains its existing muted zero counts / empty-state caption.
        // Its new coverage here checks window chrome geometry and overflow.
        if (brightness == Brightness.light &&
            !const ['vibe', 'vibe-wide', 'online', 'precise'].contains(name)) {
          expectNoUnreadableLightText(tester, panelName: name);
        }
        if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
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
        if (name == 'blocks') {
          await tester.tap(
            find.byKey(const Key('prompt-block-detail-collapsed')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final header = tester.getRect(find.byType(WindowHeader));
          final captions = tester.getRect(
            find.byKey(const Key('window-caption-controls')),
          );
          expect(header.right, lessThan(captions.left));
          expect(header.bottom, 63);
        }
        if (name == 'gallery') {
          final container = ProviderScope.containerOf(
            tester.element(find.byWidget(screen)),
          );
          container
              .read(localGallerySelectionNotifierProvider.notifier)
              .enter();
          await tester.pumpAndSettle();
          // 多选操作条浮在内容底部，顶栏搜索保持可见
          final bulk = tester.getRect(
            find.byKey(const Key('gallery-floating-bulk-bar')),
          );
          final view = tester.getRect(find.byWidget(screen));
          expect(bulk.height, 48);
          expect(bulk.bottom, lessThan(view.bottom));
          expect(bulk.top, greaterThan(view.center.dy));
          expect(find.byType(TextField), findsWidgets);
          expect(tester.takeException(), isNull);
          container.read(localGallerySelectionNotifierProvider.notifier).exit();
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsWidgets);
        }
      });
    }
  }
}
