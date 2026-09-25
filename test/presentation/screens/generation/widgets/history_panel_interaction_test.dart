import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/history_panel.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/history_batch.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_viewer.dart';
import 'package:nai_launcher/presentation/widgets/common/selectable_image_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'groups only explicit runs, sorts by slot and deduplicates current/history',
    () {
      final images = [
        for (var i = 0; i < 4; i++)
          _image('batch-$i').copyWith(generationRunId: 7, batchIndex: i),
      ];
      final legacy1 = _image('legacy-1');
      final legacy2 = _image('legacy-2');
      final batches = buildHistoryBatches(
        ImageGenerationState(
          currentImages: [images[0]],
          history: [...images.reversed, legacy1, legacy2],
        ),
      );
      expect(batches, hasLength(3));
      expect(
        batches.first.images.map((image) => image.id),
        images.map((image) => image.id),
      );
      expect(batches.first.cover?.id, images.first.id);
      expect(batches.first.count, 4);
      expect(batches.skip(1).map((batch) => batch.count), [1, 1]);
    },
  );

  testWidgets('a long history lists every image and takes new ones on top', (
    tester,
  ) async {
    final images = [for (var i = 0; i < 120; i++) _image('long-$i')];
    final container = _createContainer(images);
    addTearDown(container.dispose);
    await tester.pumpWidget(_historyApp(container));
    await tester.pumpAndSettle();

    final list = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('long-119')),
      2000,
      scrollable: list,
    );
    expect(find.byKey(const ValueKey('long-119')), findsOneWidget);

    // A progress-only update keeps the list; a new image joins at the top.
    final notifier = container.read(imageGenerationNotifierProvider.notifier);
    notifier.state = notifier.state.copyWith(progress: 0.5);
    await tester.pump();
    expect(find.byKey(const ValueKey('long-119')), findsOneWidget);
    notifier.state = notifier.state.copyWith(
      history: [_image('long-new'), ...images],
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('long-new')),
      -2000,
      scrollable: list,
    );
    expect(find.byKey(const ValueKey('long-new')), findsOneWidget);
  });

  testWidgets('batch uses first cover and selects/deletes all four images', (
    tester,
  ) async {
    final images = [
      for (var i = 0; i < 4; i++)
        _image('batch-$i').copyWith(generationRunId: 7, batchIndex: i),
    ];
    final container = _createContainer(
      images.reversed.toList(),
      behavior: HistoryClickBehavior.selectPreview,
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_historyApp(container));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableImageCard), findsOneWidget);
    expect(find.byKey(const ValueKey('batch-0')), findsOneWidget);
    expect(find.text('×4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('batch-0')));
    await tester.pumpAndSettle();
    expect(container.read(canvasHistoryFocusRequestProvider)?.group, 'run:7');
    expect(container.read(generationPreviewSelectionProvider), 'batch-0');
    await tester.tap(find.byIcon(Icons.library_add_check_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('batch-0')));
    await tester.pumpAndSettle();
    expect(find.text('保存 (4)'), findsOneWidget);
    expect(find.text('打包 (4)'), findsOneWidget);
    await tester.tap(find.byTooltip('删除选中图像 (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清除').last);
    await tester.pumpAndSettle();
    expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
    expect(find.byType(SelectableImageCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecting a non-cover child scrolls to and highlights its batch',
    (tester) async {
      final cover = _image(
        'target-cover',
      ).copyWith(generationRunId: 1, batchIndex: 0);
      final child = _image(
        'target-child',
      ).copyWith(generationRunId: 1, batchIndex: 1);
      final container = _createContainer([
        for (var i = 0; i < 8; i++)
          _image('other-$i').copyWith(generationRunId: i + 2, batchIndex: 0),
        child,
        cover,
      ], behavior: HistoryClickBehavior.selectPreview);
      addTearDown(container.dispose);
      await tester.pumpWidget(_historyApp(container));
      await tester.pumpAndSettle();
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select(child.id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 150));
      final card = tester.widget<SelectableImageCard>(
        find.byKey(ValueKey(cover.id)),
      );
      expect(card.isPreviewActive, isTrue);
      expect(find.byKey(ValueKey(child.id)), findsNothing);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'waiting, out-of-order responses and completion keep one row and cover',
    (tester) async {
      final images = [
        for (var i = 0; i < 4; i++)
          _image('stream-$i').copyWith(generationRunId: 9, batchIndex: i),
      ];
      final container = _createContainer(
        [],
        behavior: HistoryClickBehavior.selectPreview,
      );
      addTearDown(container.dispose);
      final notifier = container.read(imageGenerationNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        status: GenerationStatus.generating,
        generationRunId: 9,
        totalImages: 4,
      );
      await tester.pumpWidget(_historyApp(container));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SelectableImageCard), findsOneWidget);
      expect(find.text('×4'), findsOneWidget);
      await tester.tap(find.byType(SelectableImageCard));
      await tester.pump();
      expect(container.read(canvasHistoryFocusRequestProvider)?.group, 'run:9');
      notifier.state = notifier.state.copyWith(
        currentImages: [images[2]],
        history: [images[2]],
        currentImage: 3,
      );
      await tester.pump();
      expect(
        tester
            .widget<SelectableImageCard>(find.byType(SelectableImageCard))
            .isGenerating,
        isTrue,
      );
      notifier.state = notifier.state.copyWith(
        currentImages: [images[2], images[0]],
        history: [images[2], images[0]],
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectableImageCard), findsOneWidget);
      expect(find.byKey(const ValueKey('stream-0')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.library_add_check_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stream-0')));
      await tester.pumpAndSettle();
      expect(find.text('保存 (2)'), findsOneWidget);
      notifier.state = notifier.state.copyWith(
        status: GenerationStatus.idle,
        currentImages: [],
        history: images.reversed.toList(),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SelectableImageCard), findsOneWidget);
      expect(find.byKey(const ValueKey('stream-0')), findsOneWidget);
      expect(find.text('×4'), findsOneWidget);
      expect(find.text('保存 (4)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancelled partial batch counts only remaining images and exits group selection',
    (tester) async {
      final image = _image(
        'partial',
      ).copyWith(generationRunId: 5, batchIndex: 2);
      final container = _createContainer([
        image,
      ], behavior: HistoryClickBehavior.selectPreview);
      addTearDown(container.dispose);
      await tester.pumpWidget(_historyApp(container));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableImageCard), findsOneWidget);
      expect(find.text('×4'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(ValueKey(image.id)));
      await tester.pumpAndSettle();
      expect(find.text('保存 (1)'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey(image.id)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('保存 (1)'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['zh', 'en', 'ja']) {
    for (final width in [200.0, 280.0, 400.0]) {
      testWidgets('bulk actions fit ${width}px history in $locale', (
        tester,
      ) async {
        final container = _createContainer([
          _image('bulk-layout'),
        ], behavior: HistoryClickBehavior.selectPreview);
        addTearDown(container.dispose);
        await tester.pumpWidget(
          _historyApp(
            container,
            width: width,
            locale: Locale(locale),
            theme: ThemeData(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.library_add_check_outlined));
        await tester.pumpAndSettle();

        final pack = find.widgetWithIcon(
          OutlinedButton,
          Icons.archive_outlined,
        );
        final save = find.widgetWithIcon(FilledButton, Icons.image_outlined);
        expect(tester.widget<OutlinedButton>(pack).onPressed, isNull);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(tester.takeException(), isNull);

        final packRect = tester.getRect(pack);
        final saveRect = tester.getRect(save);
        final panelRect = tester.getRect(find.byType(HistoryPanel));
        expect(panelRect.contains(packRect.topLeft), isTrue);
        expect(panelRect.contains(saveRect.bottomRight), isTrue);
        if (width < 296) {
          expect(packRect.bottom, lessThan(saveRect.top));
        } else {
          expect(packRect.top, saveRect.top);
          expect(packRect.right, lessThan(saveRect.left));
        }

        final tile = find.byKey(const ValueKey('bulk-layout'));
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(tester.widget<SelectableImageCard>(tile).isSelected, isTrue);
        expect(tester.widget<OutlinedButton>(pack).onPressed, isNotNull);
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(pack, findsNothing);
        expect(save, findsNothing);
        expect(tester.widget<SelectableImageCard>(tile).isSelected, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('classic single click opens one image detail', (tester) async {
    final container = _createContainer([_image('classic')]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await _pumpRoute(tester);
    await tester.tap(find.byKey(const ValueKey('classic')));
    await _pumpRoute(tester);

    final viewer = tester.widget<ImageDetailViewer>(
      find.byType(ImageDetailViewer),
    );
    expect(viewer.images, hasLength(1));
    expect(viewer.initialIndex, 0);
    expect(viewer.showThumbnails, isFalse);
  });

  testWidgets(
    'linked single click selects and second click opens the merged sequence',
    (tester) async {
      final container = _createContainer([
        _image('first'),
        _image('second'),
      ], behavior: HistoryClickBehavior.selectPreview);
      addTearDown(container.dispose);

      await tester.pumpWidget(_historyApp(container));
      await _pumpRoute(tester);

      await tester.tap(find.byKey(const ValueKey('first')));
      await tester.pump();
      expect(container.read(generationPreviewSelectionProvider), 'first');
      expect(find.byType(ImageDetailViewer), findsNothing);
      expect(
        tester
            .widget<SelectableImageCard>(find.byKey(const ValueKey('first')))
            .isPreviewActive,
        isTrue,
      );
      expect(
        container.read(generationPreviewFocusNodeProvider).hasFocus,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('first')));
      await _pumpRoute(tester);
      _expectLinkedViewer(tester, initialIndex: 0);
    },
  );

  testWidgets('linked long press opens the merged sequence at its image', (
    tester,
  ) async {
    final container = _createContainer([
      _image('first'),
      _image('second'),
    ], behavior: HistoryClickBehavior.selectPreview);
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await _pumpRoute(tester);
    final second = find.byKey(const ValueKey('second'));
    await tester.ensureVisible(second);
    await tester.longPress(second);
    await _pumpRoute(tester);

    _expectLinkedViewer(tester, initialIndex: 1);
  });

  testWidgets('linked context detail opens the merged sequence at its image', (
    tester,
  ) async {
    final container = _createContainer([
      _image('first'),
      _image('second'),
    ], behavior: HistoryClickBehavior.selectPreview);
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await _pumpRoute(tester);
    final second = find.byKey(const ValueKey('second'));
    await tester.ensureVisible(second);
    await _openContextMenu(tester, second);
    await tester.tap(find.text('查看详情'));
    await _pumpRoute(tester);

    _expectLinkedViewer(tester, initialIndex: 1);
  });

  testWidgets('linked Ctrl rapid clicks toggle bulk selection on every click', (
    tester,
  ) async {
    final container = _createContainer([
      _image('toggle'),
    ], behavior: HistoryClickBehavior.selectPreview);
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await tester.pumpAndSettle();
    final finder = find.byKey(const ValueKey('toggle'));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(finder);
    await tester.pump();
    expect(tester.widget<SelectableImageCard>(finder).isSelected, isTrue);

    await tester.tap(finder);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(tester.widget<SelectableImageCard>(finder).isSelected, isFalse);
    expect(container.read(generationPreviewSelectionProvider), isNull);
  });

  testWidgets(
    'classic Ctrl rapid clicks stay bulk-only and context opens one',
    (tester) async {
      final container = _createContainer([_image('classic-toggle')]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_historyApp(container));
      await tester.pumpAndSettle();
      final finder = find.byKey(const ValueKey('classic-toggle'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(finder);
      await tester.pump();
      expect(tester.widget<SelectableImageCard>(finder).isSelected, isTrue);
      await tester.tap(finder);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(tester.widget<SelectableImageCard>(finder).isSelected, isFalse);
      expect(container.read(generationPreviewSelectionProvider), isNull);
      expect(find.byType(ImageDetailViewer), findsNothing);

      await _openContextMenu(tester, finder);
      await tester.tap(find.text('查看详情'));
      await _pumpRoute(tester);
      final viewer = tester.widget<ImageDetailViewer>(
        find.byType(ImageDetailViewer),
      );
      expect(viewer.images, hasLength(1));
      expect(viewer.showThumbnails, isFalse);
    },
  );

  testWidgets('rapid tall-row navigation settles on the latest selection', (
    tester,
  ) async {
    final images = [
      for (var index = 0; index < 8; index++)
        _image(
          'rapid-$index',
          width: 100,
          height: 400,
          kind: GeneratedImageKind.failedStreamSnapshot,
        ),
    ];
    final container = _createContainer(
      images,
      behavior: HistoryClickBehavior.selectPreview,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await tester.pumpAndSettle();
    final selection = container.read(
      generationPreviewSelectionProvider.notifier,
    );
    selection.select('rapid-0');
    for (var index = 0; index < 7; index++) {
      selection.selectNext();
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 220));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    final latestPosition = scrollable.position.pixels;
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(generationPreviewSelectionProvider), 'rapid-7');
    expect(find.byKey(const ValueKey('rapid-7')), findsOneWidget);
    expect(scrollable.position.pixels, greaterThan(0));
    expect(
      scrollable.position.pixels,
      greaterThanOrEqualTo(latestPosition - 10),
    );
  });

  testWidgets('generation placeholder row participates in selected offset', (
    tester,
  ) async {
    final target = _image('after-placeholder');
    final container = _createContainer(
      [target],
      behavior: HistoryClickBehavior.selectPreview,
      currentImages: [_image('completed-current')],
      status: GenerationStatus.generating,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_historyApp(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    container
        .read(generationPreviewSelectionProvider.notifier)
        .select(target.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(find.byKey(ValueKey(target.id)), findsOneWidget);
    expect(scrollable.position.pixels, greaterThan(250));
  });

  testWidgets('remount scrolls to selection changed while panel was hidden', (
    tester,
  ) async {
    final images = [
      for (var index = 0; index < 5; index++)
        _image(
          'portrait-$index',
          width: 100,
          height: 400,
          kind: GeneratedImageKind.failedStreamSnapshot,
        ),
    ];
    final container = _createContainer(
      images,
      behavior: HistoryClickBehavior.selectPreview,
    );
    addTearDown(container.dispose);
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);

    await tester.pumpWidget(_historyApp(container, visible: visible));
    await tester.pumpAndSettle();
    visible.value = false;
    await tester.pumpAndSettle();

    final selection = container.read(
      generationPreviewSelectionProvider.notifier,
    );
    selection.select('portrait-0');
    for (var index = 0; index < 4; index++) {
      selection.selectNext();
    }
    expect(container.read(generationPreviewSelectionProvider), 'portrait-4');

    visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('portrait-4')), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));
  });
}

ProviderContainer _createContainer(
  List<GeneratedImage> images, {
  HistoryClickBehavior behavior = HistoryClickBehavior.openDetail,
  List<GeneratedImage> currentImages = const [],
  GenerationStatus status = GenerationStatus.idle,
}) {
  final container = ProviderContainer(
    overrides: [
      localStorageServiceProvider.overrideWith(
        (_) => _HistoryBehaviorStorage(behavior),
      ),
      shortcutConfigNotifierProvider.overrideWith(
        _HistoryShortcutConfigNotifier.new,
      ),
    ],
  );
  final notifier = container.read(imageGenerationNotifierProvider.notifier);
  notifier.state = notifier.state.copyWith(
    status: status,
    currentImages: currentImages,
    history: images,
    batchWidth: 100,
    batchHeight: 100,
  );
  return container;
}

class _HistoryBehaviorStorage extends LocalStorageService {
  _HistoryBehaviorStorage(this.behavior);

  HistoryClickBehavior behavior;

  @override
  String getHistoryClickBehavior() => behavior.storageValue;

  @override
  Future<void> setHistoryClickBehavior(String value) async {
    behavior = HistoryClickBehavior.fromStorageValue(value);
  }
}

class _HistoryShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

GeneratedImage _image(
  String id, {
  int width = 32,
  int height = 32,
  GeneratedImageKind kind = GeneratedImageKind.completed,
}) {
  return GeneratedImage(
    id: id,
    bytes: Uint8List.fromList(
      img.encodePng(img.Image(width: 4, height: 4, numChannels: 4)),
    ),
    width: width,
    height: height,
    kind: kind,
  );
}

Widget _historyApp(
  ProviderContainer container, {
  ValueNotifier<bool>? visible,
  double width = 320,
  Locale locale = const Locale('zh'),
  ThemeData? theme,
}) {
  final previewFocusNode = container.read(generationPreviewFocusNodeProvider);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      theme: theme,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Focus(
          focusNode: previewFocusNode,
          child: SizedBox(
            width: width,
            height: 640,
            child: visible == null
                ? const HistoryPanel()
                : ValueListenableBuilder(
                    valueListenable: visible,
                    builder: (_, isVisible, __) => isVisible
                        ? const HistoryPanel()
                        : const SizedBox.shrink(),
                  ),
          ),
        ),
      ),
    ),
  );
}

void _expectLinkedViewer(WidgetTester tester, {required int initialIndex}) {
  final viewer = tester.widget<ImageDetailViewer>(
    find.byType(ImageDetailViewer),
  );
  expect(viewer.images, hasLength(2));
  expect(viewer.initialIndex, initialIndex);
  expect(viewer.showThumbnails, isTrue);
}

Future<void> _openContextMenu(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(
    tester.getCenter(target),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await tester.pump();
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}
