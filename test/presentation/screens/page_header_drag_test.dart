import 'package:nai_launcher/presentation/wiring/refs_library_wiring.dart';
import 'dart:io';
import 'dart:ui' as ui;

// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/data/services/gelbooru_auth_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_category_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/wiring/refs_platform.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/wiring/online_wiring.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart'
    as character;
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';

import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';
import 'package:nai_launcher/presentation/wiring/blocks_library_wiring.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/tag_wiki_screen.dart';
import 'package:nai_launcher/presentation/screens/tag_wiki/wiki_sidebar.dart';

import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/light_theme_contrast.dart';

class _Palette extends PromptBlockPaletteNotifier {
  @override
  Future<PromptBlockPaletteState> build() async =>
      PromptBlockPaletteState(blocks: const []);
}

class _Shortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _OnlineParams extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _OnlineCharacters extends CharacterPromptNotifier {
  @override
  character.CharacterPromptConfig build() =>
      const character.CharacterPromptConfig();
}

class _Gallery extends OnlineGalleryNotifier {
  @override
  OnlineGalleryState build() => const OnlineGalleryState();
  @override
  Future<void> loadPosts({bool refresh = false}) async {}
}

class _Danbooru extends DanbooruAuth {
  @override
  DanbooruAuthState build() => const DanbooruAuthState();
}

class _Favorites extends OnlineFavoritesNotifier {
  _Favorites() : super(OnlineFavoritesRepository.instance);
  @override
  Future<void> bindSource(GallerySourceId source) async {}
}

class _Gelbooru extends GelbooruAuth {
  @override
  GelbooruAuthState build() => const GelbooruAuthState();
}

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock.create(
        id: 'example',
        title: 'Example',
        content: 'blue_eyes',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
    folders: [],
  );
}

class _Vibes extends VibeLibraryNotifier {
  @override
  VibeLibraryState build() => const VibeLibraryState(isLoading: false);
  @override
  Future<void> initialize() async {}
}

class _Categories extends VibeLibraryCategoryNotifier {
  @override
  VibeLibraryCategoryState build() => const VibeLibraryCategoryState();
}

class _RefsPlatform extends RefsPlatform {
  @override
  Future<String> libraryFolder() async => 'test-library';
}

class _References extends PreciseRefLibraryNotifier {
  @override
  PreciseRefLibraryState build() => const PreciseRefLibraryState();
  @override
  Future<void> initialize() async {}
}

class _Tags extends UnifiedTagRepository {
  _Tags()
    : super(
        catalog: TagCatalogRepository(),
        runtime: () async => throw StateError('not used'),
      );
  @override
  Future<List<CompletionCandidate>> browse({
    TagCategory? category,
    bool? hasWiki,
    bool alphabetical = false,
    int offset = 0,
    int limit = 80,
  }) async => [];
  @override
  Future<int> count({TagCategory? category, bool? hasWiki}) async => 0;
}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}

class _Translation extends ChangeNotifier
    implements AutoTagTranslationController {
  @override
  bool get enabled => false;
  @override
  int get activeRequests => 0;
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

const _pages = <String, Widget>{
  'online': OnlineWiring(),
  'blocks': BlocksLibraryWiring(),
  'vibes': VibeLibraryWiring(),
  'references': PreciseRefLibraryWiring(),
  'wiki': Scaffold(
    body: TagWikiScreen(
      directory: WikiDirectory(roots: [], groups: {}),
    ),
  ),
};

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
  final calls = <String>[];
  const windows = MethodChannel('window_manager');
  const nativeChrome = MethodChannel('com.nailauncher/titlebar');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windows, (call) async {
      calls.add(call.method);
      if (call.method == 'isMaximized' || call.method == 'isFullScreen') {
        return false;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(nativeChrome, (_) async => null);
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(windows, null);
    messenger.setMockMethodCallHandler(nativeChrome, null);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    String page, {
    double width = 1600,
    Locale locale = const Locale('zh'),
    bool dark = false,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
          onlineGalleryNotifierProvider.overrideWith(_Gallery.new),
          localStorageServiceProvider.overrideWithValue(
            InMemoryLocalStorageService(),
          ),
          generationParamsNotifierProvider.overrideWith(_OnlineParams.new),
          characterPromptNotifierProvider.overrideWith(_OnlineCharacters.new),
          onlineFavoritesNotifierProvider.overrideWith((_) => _Favorites()),
          danbooruAuthProvider.overrideWith(_Danbooru.new),
          gelbooruAuthProvider.overrideWith(_Gelbooru.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
          promptBlockPaletteNotifierProvider.overrideWith(_Palette.new),
          vibeLibraryNotifierProvider.overrideWith(_Vibes.new),
          refsPlatformProvider.overrideWith((ref) => _RefsPlatform()),
          vibeLibraryCategoryNotifierProvider.overrideWith(_Categories.new),
          preciseRefLibraryNotifierProvider.overrideWith(_References.new),
          unifiedTagRepositoryProvider.overrideWith((_) => _Tags()),
          tagWikiRepositoryProvider.overrideWith((_) => _Wiki()),
          autoTagTranslationProvider.overrideWith((_) => _Translation()),
        ],
        child: MaterialApp(
          locale: locale,
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: const Key('capture-page'),
            child: IntegratedTitleBarShell(
              captionHeight: page == 'wiki' ? 62 : 61,
              child: _pages[page]!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (page == 'blocks') {
      tester
          .widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage))
          .actions
          .onInspectorChanged(false);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    calls.clear();
  }

  Future<void> mouseDrag(WidgetTester tester, Offset from) async {
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.down(from);
    await mouse.moveBy(const Offset(45, 0));
    await mouse.up();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder pageHeader() {
    final legacy = find.byType(WindowHeader);
    if (legacy.evaluate().isNotEmpty) return legacy.first;
    return find
        .ancestor(
          of: find.byType(TextField).first,
          matching: find.byType(WindowHeaderDragSurface),
        )
        .first;
  }

  Future<void> checkHeader(WidgetTester tester) async {
    final header = pageHeader();
    final rect = tester.getRect(header);
    // This is page padding, far from the pre-existing right caption strip.
    await mouseDrag(tester, rect.topLeft + Offset(3, rect.height - 5));
    expect(calls.where((call) => call == 'startDragging'), hasLength(1));
    calls.clear();
    final fields = find.descendant(
      of: header,
      matching: find.byType(TextField),
    );
    if (fields.evaluate().isNotEmpty) {
      await mouseDrag(tester, tester.getCenter(fields.first));
      expect(calls, isNot(contains('startDragging')));
    }
  }

  for (final page in _pages.keys) {
    for (final locale in const [
      Locale('zh'),
      Locale('zh', 'TW'),
      Locale('en'),
      Locale('ja'),
      Locale('ko'),
    ]) {
      for (final width in [900.0, 1600.0]) {
        testWidgets(
          '$page empty header drags; search stays usable $locale $width',
          (tester) async {
            await pumpPage(
              tester,
              page,
              width: width,
              locale: locale,
              dark: width == 900,
            );
            if (locale == const Locale('zh') &&
                Platform.environment['CAPTURE_HEADER_DRAG'] == '1') {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('capture-page')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final png = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '.dart_tool/page-header-drag-20261005/$page-${width.toInt()}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(png!.buffer.asUint8List());
                image.dispose();
              });
            }
            await checkHeader(tester);
            await tester.tap(find.byIcon(Icons.remove));
            expect(calls, contains('minimize'));
            expect(tester.takeException(), isNull);
          },

          variant: TargetPlatformVariant.only(TargetPlatform.windows),
        );
      }
    }
  }

  for (final page in ['vibes', 'wiki']) {
    testWidgets(
      '$page sidebar gaps drag and create button opens its category editor',
      (tester) async {
        await pumpPage(tester, page);
        final sidebarSurface = find.byType(WindowHeaderDragSurface).first;
        final rect = tester.getRect(sidebarSurface);
        await mouseDrag(tester, rect.topLeft + Offset(rect.width * .55, 30));
        expect(calls, contains('startDragging'));
        calls.clear();
        final create = page == 'vibes'
            ? find.byTooltip(
                lookupAppLocalizations(const Locale('zh')).refs_newCategory,
              )
            : find
                  .descendant(
                    of: sidebarSurface,
                    matching: find.byType(IconButton),
                  )
                  .first;
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(calls, isNot(contains('startDragging')));
        if (page == 'vibes') {
          final field = find.byKey(const Key('refs-category-name'));
          expect(field, findsOneWidget);
          await mouseDrag(tester, tester.getCenter(field));
        } else {
          expect(find.byType(Dialog), findsOneWidget);
          // A modal's blank surface must not reach the header underneath.
          await mouseDrag(tester, rect.topLeft + const Offset(3, 30));
        }
        expect(calls, isNot(contains('startDragging')));
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  }

  testWidgets(
    'blocks toolbar create opens the editor without dragging the window',
    (tester) async {
      await pumpPage(tester, 'blocks');
      await tester.tap(find.byKey(const Key('blocks-create')));
      await tester.pumpAndSettle();
      expect(find.byType(BlockEditDialog), findsOneWidget);
      expect(calls, isNot(contains('startDragging')));
      await mouseDrag(tester, const Offset(600, 56));
      expect(calls, isNot(contains('startDragging')));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets('block header stays draggable with the right detail panel open', (
    tester,
  ) async {
    await pumpPage(tester, 'blocks');
    await tester.tap(find.byKey(const Key('blocks-inspector-toggle')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<WindowHeader>(find.byKey(const Key('blocks-toolbar')))
          .enabled,
      isFalse,
    );
    await checkHeader(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  for (final page in ['online', 'vibes']) {
    testWidgets('$page selection header gaps still drag', (tester) async {
      await pumpPage(tester, page);
      RefsController? refs;
      if (page == 'vibes') {
        refs = tester.state(find.byType(RefsLibraryPage)) as RefsController;
        refs.setPicking(true);
      } else {
        await tester.tap(find.byKey(const Key('online-multi')));
      }
      await tester.pumpAndSettle();
      if (page == 'online') {
        expect(find.byKey(const Key('online-multi-done')), findsOneWidget);
      } else {
        expect(refs!.picking, isTrue);
      }
      await checkHeader(tester);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets('Wiki directory sheet header does not drag the window', (
    tester,
  ) async {
    await pumpPage(tester, 'wiki', width: 900);
    await tester.tap(find.byKey(const Key('wiki-directory-button')));
    await tester.pumpAndSettle();
    final sidebar = find.byType(WikiSidebar);
    expect(tester.widget<WikiSidebar>(sidebar).allowWindowDrag, isFalse);
    final header = tester.getRect(
      find.byKey(const Key('wiki-directory-header')),
    );
    await mouseDrag(tester, header.topLeft + const Offset(3, 30));
    expect(calls, isNot(contains('startDragging')));
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
