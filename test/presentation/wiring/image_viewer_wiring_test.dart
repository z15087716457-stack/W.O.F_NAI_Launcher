import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_focus_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/utils/image_viewer_opener.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_backend.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_gallery.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_platform.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_session.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_wiring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/library/library_test_helpers.dart';

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

class _Highlight extends HighlightEmphasisSettings {
  @override
  bool build() => true;
}

class _Share extends ShareImageSettingsNotifier {
  @override
  ShareImageSettings build() =>
      const ShareImageSettings(confirmDangerousActions: true);
}

class _GalleryNotifier extends LocalGalleryNotifier {
  final records = <String, LocalImageRecord>{};
  @override
  LocalGalleryState build() => const LocalGalleryState();
  @override
  LocalImageRecord? cachedRecord(String path) => records[path];
  void favorite(String path, bool value) {
    records[path] = LocalImageRecord(
      path: path,
      size: 1,
      modifiedAt: DateTime(2026),
      isFavorite: value,
    );
    state = state.copyWith(recordsRevision: state.recordsRevision + 1);
  }
}

class _Gallery extends ImageViewerGallery {
  _Gallery(super.ref);
  final events = <Object>[];
  Completer<List<ViewerCollection>>? slow;
  @override
  Future<List<ViewerCollection>> collections(String path) async =>
      path == '0' && slow != null
      ? await slow!.future
      : [ViewerCollection(id: path, name: path)];
  @override
  Future<void> setFavorite(String path, bool value) async {
    events.add((path, value));
    (ref.read(localGalleryNotifierProvider.notifier) as _GalleryNotifier)
        .favorite(path, value);
  }

  @override
  Future<void> setCollection(String path, String id, bool member) async =>
      events.add((path, id, member));
}

class _Platform extends ImageViewerPlatform {
  final events = <bool>[];
  final backups = <String>[];
  Completer<void>? backupWait;
  Completer<({bool infoOpen, bool zoomHintSeen})>? preferencesWait;
  @override
  Future<void> backupDraft(String snapshot) async {
    backups.add(snapshot);
    await backupWait?.future;
  }

  @override
  Future<({bool infoOpen, bool zoomHintSeen})> preferences() =>
      preferencesWait?.future ?? super.preferences();
  @override
  Future<bool> isFullscreen() async => false;
  @override
  Future<bool> isMaximized() async => false;
  @override
  Future<void> setFullscreen(bool value) async => events.add(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('viewer_wiring_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );
  ImageDetailData source(String key, {bool failed = false}) =>
      GeneratedImageDetailData(
        imageBytes: bytes,
        id: key,
        metadata: NaiImageMetadata(
          prompt: 'prompt-$key',
          negativePrompt: 'negative-$key',
          seed: 42,
        ),
        showSaveButton: !failed,
        showCopyButton: !failed,
      );
  late ProviderContainer container;
  late _Platform platform;
  late _Gallery gallery;
  late GoRouter router;
  late BuildContext openerContext;
  late Future<PillDocument> Function(PillDocument, String) translator;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = _Platform();
    translator = (document, session) async => document;
    container = ProviderContainer(
      overrides: [
        imageViewerPlatformProvider.overrideWithValue(platform),
        detailPromptTranslatorProvider.overrideWithValue(
          (document, session) => translator(document, session),
        ),
        imageViewerGalleryProvider.overrideWith(
          (ref) => gallery = _Gallery(ref),
        ),
        localGalleryNotifierProvider.overrideWith(_GalleryNotifier.new),
        highlightEmphasisSettingsProvider.overrideWith(_Highlight.new),
        promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
        shareImageSettingsProvider.overrideWith(_Share.new),
        shortcutConfigNotifierProvider.overrideWith(TestLibraryShortcuts.new),
        kritaBridgeNotifierProvider.overrideWith(
          (ref) => KritaBridgeNotifier(),
        ),
      ],
    );
    container.read(imageViewerGalleryProvider);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ImageViewerHost(
              child: Builder(
                builder: (context) {
                  openerContext = context;
                  return const Text('underlying page');
                },
              ),
            ),
          ),
        ),
      ],
    );
  });
  tearDown(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      router.dispose();
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      await Hive.box(StorageKeys.settingsBox).clear();
    });
  });

  ImageViewerSession session({
    ViewerMode mode = ViewerMode.gallery,
    int count = 3,
    int initial = 0,
    Future<void> Function(ImageDetailData)? save,
    bool failed = false,
    ImageDetailData Function(String)? input,
  }) {
    final keys = List.generate(count, (i) => '$i');
    return ImageViewerSession(
      mode: mode,
      backend: ImageViewerBackend(
        keys: keys,
        initialKey: '$initial',
        load: (keys) async => keys
            .map((key) => input?.call(key) ?? source(key, failed: failed))
            .toList(),
        readMetadata: (image) async => image.metadata,
        deleteImage: (key) async => true,
        restoreImage: (key) async {},
      ),
      save: save,
      dimensions: {for (final key in keys) key: (width: 1, height: 1)},
      dates: {for (final key in keys) key: DateTime(2026, 10, 12)},
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    ImageViewerSession? viewer,
    Size size = const Size(1600, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container.read(imageViewerSessionProvider.notifier).state = viewer;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh'),
          theme: GeistTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  ImageViewerPage page(WidgetTester tester) =>
      tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'resolution follows encoded pixels rather than request metadata',
    (tester) async {
      final pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 640, height: 960)),
      );
      await pump(
        tester,
        viewer: session(
          mode: ViewerMode.generation,
          count: 1,
          input: (key) => GeneratedImageDetailData(
            imageBytes: pixels,
            id: key,
            metadata: const NaiImageMetadata(
              seed: 123,
              width: 1792,
              height: 896,
            ),
          ),
        ),
      );
      expect(
        (page(tester).data.current!.width, page(tester).data.current!.height),
        (640, 960),
      );
    },
  );

  testWidgets('img2img action backs up then writes live image parameters', (
    tester,
  ) async {
    final pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 512, height: 768)),
    );
    await pump(
      tester,
      viewer: session(
        mode: ViewerMode.generation,
        input: (key) => GeneratedImageDetailData(
          imageBytes: pixels,
          id: key,
          metadata: const NaiImageMetadata(prompt: 'source'),
        ),
      ),
    );
    await tester.runAsync(() async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('before');
      page(tester).actions.onAction('0', ViewerAction.img2img);
      await Future<void>.delayed(Duration.zero);
      await Hive.box(StorageKeys.settingsBox).flush();
    });
    await flush(tester);
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      pixels,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'before');
    expect(
      (jsonDecode(platform.backups.single) as Map)['generation']['prompt'],
      'before',
    );
    expect(container.read(imageViewerSessionProvider), isNull);
  });

  testWidgets('new edit during img2img backup prevents action write', (
    tester,
  ) async {
    await pump(tester, viewer: session(mode: ViewerMode.generation));
    platform.backupWait = Completer<void>();
    page(tester).actions.onAction('0', ViewerAction.img2img);
    await flush(tester);
    expect(platform.backups, hasLength(1));
    await tester.runAsync(() async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new');
      await Hive.box(StorageKeys.settingsBox).flush();
    });
    platform.backupWait!.complete();
    await flush(tester);
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      isNull,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'new');
    expect(container.read(imageViewerSessionProvider), isNotNull);
  });

  testWidgets(
    'zoom hint acknowledgement does not drop delayed info preference',
    (tester) async {
      platform.preferencesWait =
          Completer<({bool infoOpen, bool zoomHintSeen})>();
      await pump(tester, viewer: session());
      page(tester).actions.onZoomHintSeen();
      platform.preferencesWait!.complete((
        infoOpen: false,
        zoomHintSeen: false,
      ));
      await flush(tester);
      expect(page(tester).data.infoOpen, isFalse);
      expect(page(tester).data.zoomHintSeen, isTrue);
    },
  );

  testWidgets(
    'mounts approved page and retains underlying content without root route',
    (tester) async {
      await pump(tester, viewer: session());
      expect(page(tester).data.items.length, 3);
      expect(page(tester).data.detail!.prompt, 'prompt-0');
      expect(page(tester).data.current!.protected, isTrue);
      expect(find.text('underlying page'), findsNothing);
      expect(find.text('underlying page', skipOffstage: false), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
      expect(tester.takeException(), isNull);
      page(tester).actions.onClose(keyboard: false);
      await flush(tester);
      expect(find.byType(ImageViewerPage), findsNothing);
      expect(find.text('underlying page'), findsOneWidget);
      expect(container.read(localGalleryFocusNotifierProvider), '0');
    },
  );

  testWidgets('duplicate open does not replace current session', (
    tester,
  ) async {
    final viewer = session(mode: ViewerMode.generation);
    await pump(tester, viewer: viewer);
    ImageViewerOpener.showSingleImmediate(openerContext, image: source('new'));
    await flush(tester);
    expect(container.read(imageViewerSessionProvider), same(viewer));
    expect(page(tester).data.currentKey, '0');
  });

  testWidgets('fullscreen and stage captions reflect the latest window state', (
    tester,
  ) async {
    await pump(tester, viewer: session());
    page(tester).actions.onCaptionOverStage(true);
    await flush(tester);
    final chrome = tester.widget<WindowChromePage>(
      find.byType(WindowChromePage),
    );
    expect(chrome.captionHeight, 61);
    expect(chrome.captionTheme!.brightness, Brightness.dark);
    final stale = page(tester).actions;
    stale.onFullscreenChanged(true);
    await flush(tester);
    stale.onCaptionOverStage(true);
    await flush(tester);
    expect(page(tester).data.fullscreen, isTrue);
    expect(
      tester
          .widget<WindowChromePage>(find.byType(WindowChromePage))
          .hideCaptions,
      isTrue,
    );
    page(tester).actions.onClose(keyboard: false);
    await flush(tester);
    expect(platform.events, [true, false]);
  });

  testWidgets(
    'favorite and collection callbacks preserve target identity and value',
    (tester) async {
      await pump(tester, viewer: session());
      page(tester).actions.onSetFavorite('0', true);
      page(tester).actions.onToggleCollection('0', 'collection', true);
      await flush(tester);
      expect(gallery.events, [('0', true), ('0', 'collection', true)]);
      expect(page(tester).data.current!.favorite, isTrue);
    },
  );

  testWidgets(
    'late collection requests do not replace new selection memberships',
    (tester) async {
      gallery.slow = Completer<List<ViewerCollection>>();
      await pump(tester, viewer: session());
      page(tester).actions.onSelect('1');
      await flush(tester);
      gallery.slow!.complete([
        const ViewerCollection(id: 'stale', name: 'stale'),
      ]);
      await flush(tester);
      expect(page(tester).data.collections!.single.id, '1');
    },
  );

  testWidgets(
    'delete is already confirmed and undo restores the deleted item',
    (tester) async {
      await pump(tester, viewer: session());
      page(tester).actions.onDelete('0');
      await flush(tester);
      expect(page(tester).data.currentKey, '1');
      expect(page(tester).data.total, 2);
      expect(page(tester).data.undo, isNotNull);
      expect(find.byType(AlertDialog), findsNothing);
      page(tester).actions.onUndoDelete();
      await flush(tester);
      expect(page(tester).data.currentKey, '0');
      expect(page(tester).data.total, 3);
    },
  );

  testWidgets('generation mode exposes save, but no gallery-only actions', (
    tester,
  ) async {
    var saved = 0;
    await pump(
      tester,
      viewer: session(
        mode: ViewerMode.generation,
        save: (_) async {
          saved++;
        },
      ),
    );
    expect(page(tester).data.actions, contains(ViewerAction.save));
    expect(
      page(tester).data.actions,
      isNot(contains(ViewerAction.styleTransfer)),
    );
    expect(page(tester).data.collections, isNull);
    page(tester).actions.onAction('0', ViewerAction.save);
    await flush(tester);
    expect(saved, 1);
  });

  testWidgets('failed generation snapshots remain read-only', (tester) async {
    var saved = 0;
    await pump(
      tester,
      viewer: session(
        mode: ViewerMode.generation,
        failed: true,
        save: (_) async {
          saved++;
        },
      ),
    );
    expect(page(tester).data.actions, isEmpty);
    page(tester).actions.onAction('0', ViewerAction.save);
    await flush(tester);
    expect(saved, 0);
  });

  testWidgets(
    'old save callback cannot dispatch against a newly selected image',
    (tester) async {
      final saved = <String>[];
      await pump(
        tester,
        viewer: session(
          mode: ViewerMode.generation,
          save: (image) async => saved.add(image.identifier),
        ),
      );
      final old = page(tester).actions;
      old.onSelect('1');
      await flush(tester);
      old.onAction('0', ViewerAction.save);
      await flush(tester);
      expect(saved, isEmpty);
    },
  );

  testWidgets('translation pills are rendered as reading text, not markers', (
    tester,
  ) async {
    await pump(tester, viewer: session());
    translator = (document, session) async => const PillDocument(
      text: '\uE000',
      instances: {
        '\uE000': PillInstance(
          blockId: 'reading',
          translation: TranslationPill(source: 'original', zh: '译文'),
        ),
      },
    );
    page(tester).actions.onToggleTranslation('0', ViewerPart.prompt);
    await flush(tester);
    expect(page(tester).data.translations[ViewerPart.prompt]!.text, '译文');
  });
}
