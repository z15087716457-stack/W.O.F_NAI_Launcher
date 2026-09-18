import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';

void main() {
  group('LayoutState main navigation rail persistence', () {
    test('defaults to collapsed and copyWith preserves other fields', () {
      const state = LayoutState();

      expect(state.mainNavRailExpanded, isFalse);

      final updated = state.copyWith(
        mainNavRailExpanded: true,
        rightPanelWidth: 360.0,
      );
      expect(updated.mainNavRailExpanded, isTrue);
      expect(updated.rightPanelWidth, 360.0);
    });

    test('build reads and setter writes expansion state', () async {
      final storage = _FakeLayoutStorage()..mainNavExpanded = true;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(layoutStateNotifierProvider).mainNavRailExpanded,
        isTrue,
      );

      await container
          .read(layoutStateNotifierProvider.notifier)
          .setMainNavRailExpanded(false);

      expect(storage.mainNavExpanded, isFalse);
    });
  });

  group('LayoutState web style layout fields', () {
    test('defaults', () {
      const state = LayoutState();

      expect(state.webLeftPanelWidth, 400.0);
      expect(state.webLeftPanelExpanded, isTrue);
    });

    test('copyWith 更新 web 字段且不影响其他字段', () {
      final state = const LayoutState().copyWith(rightPanelWidth: 350.0);
      final updated = state.copyWith(
        webLeftPanelWidth: 480.0,
        webLeftPanelExpanded: false,
      );

      expect(updated.rightPanelWidth, 350.0);
      expect(updated.webLeftPanelWidth, 480.0);
      expect(updated.webLeftPanelExpanded, isFalse);
    });
  });

  group('LayoutStateNotifier web style layout persistence', () {
    test('build 从 storage 读取 web 字段', () {
      final storage = _FakeLayoutStorage()
        ..webWidth = 500.0
        ..webExpanded = false;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      final state = container.read(layoutStateNotifierProvider);

      expect(state.webLeftPanelWidth, 500.0);
      expect(state.webLeftPanelExpanded, isFalse);
    });

    test('setter 写回 storage 并 clamp', () async {
      final storage = _FakeLayoutStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setWebLeftPanelWidth(9999.0);
      await notifier.setWebLeftPanelExpanded(false);

      expect(storage.webWidth, 560.0);
      expect(storage.webExpanded, isFalse);

      await notifier.setWebLeftPanelWidth(100.0);

      expect(storage.webWidth, 352.0);
    });
  });

  group('LayoutState style explore widths', () {
    test('defaults and copyWith preserve the Run sidebar width', () {
      const state = LayoutState();

      expect(state.styleExploreRunSidebarWidth, 240.0);
      expect(state.styleExploreGalleryWidth, 360.0);

      final updated = state.copyWith(styleExploreRunSidebarWidth: 300.0);
      expect(updated.styleExploreRunSidebarWidth, 300.0);
      expect(updated.styleExploreGalleryWidth, 360.0);
    });

    test('setters preserve widths outside the former bounds', () async {
      final storage = _FakeLayoutStorage()
        ..blockLibraryPanelWidth = 280.0
        ..styleExploreRunSidebarWidth = 280.0
        ..styleExploreGalleryWidth = 360.0;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(layoutStateNotifierProvider.notifier);
      final state = container.read(layoutStateNotifierProvider);
      expect(state.blockLibraryPanelWidth, 280.0);
      expect(state.styleExploreRunSidebarWidth, 280.0);
      expect(state.styleExploreGalleryWidth, 360.0);

      await notifier.setStyleExploreRunSidebarWidth(100.0);
      expect(storage.styleExploreRunSidebarWidth, 100.0);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreRunSidebarWidth,
        100.0,
      );
      await notifier.setStyleExploreRunSidebarWidth(999.0);
      expect(storage.styleExploreRunSidebarWidth, 999.0);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreRunSidebarWidth,
        999.0,
      );

      await notifier.setStyleExploreGalleryWidth(100.0);
      expect(storage.styleExploreGalleryWidth, 100.0);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreGalleryWidth,
        100.0,
      );
      await notifier.setStyleExploreGalleryWidth(999.0);
      expect(storage.styleExploreGalleryWidth, 999.0);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreGalleryWidth,
        999.0,
      );

      await notifier.setBlockLibraryPanelWidth(100.0);
      expect(storage.blockLibraryPanelWidth, 100.0);
      expect(
        container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
        100.0,
      );
      await notifier.setBlockLibraryPanelWidth(999.0);
      expect(storage.blockLibraryPanelWidth, 999.0);
      expect(
        container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
        999.0,
      );

      await notifier.setStyleExploreRunSidebarWidth(-1.0);
      expect(storage.styleExploreRunSidebarWidth, 0.0);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreRunSidebarWidth,
        0.0,
      );
    });
  });

  group('LayoutStateNotifier paired style explore pane widths', () {
    test(
      'paired setter updates both panes in one state and storage write',
      () async {
        final storage = _FakeLayoutStorage()
          ..blockLibraryPanelWidth = 280.0
          ..styleExploreRunSidebarWidth = 240.0
          ..styleExploreGalleryWidth = 360.0;
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => storage),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(layoutStateNotifierProvider.notifier)
            .setStyleExplorePaneWidths(sidebar: 180.0, gallery: 420.0);

        final state = container.read(layoutStateNotifierProvider);
        expect(state.styleExploreRunSidebarWidth, 180.0);
        expect(state.styleExploreGalleryWidth, 420.0);
        // 未传入的键必须原样保留。
        expect(state.blockLibraryPanelWidth, 280.0);
        expect(storage.styleExploreRunSidebarWidth, 180.0);
        expect(storage.styleExploreGalleryWidth, 420.0);
        expect(storage.blockLibraryPanelWidth, 280.0);
      },
    );

    test(
      'paired setter accepts block library without touching panes',
      () async {
        final storage = _FakeLayoutStorage();
        final container = ProviderContainer(
          overrides: [
            localStorageServiceProvider.overrideWith((ref) => storage),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(layoutStateNotifierProvider.notifier)
            .setStyleExplorePaneWidths(blockLibrary: 260.0, sidebar: 300.0);

        final state = container.read(layoutStateNotifierProvider);
        expect(state.blockLibraryPanelWidth, 260.0);
        expect(state.styleExploreRunSidebarWidth, 300.0);
        expect(state.styleExploreGalleryWidth, 360.0);
        expect(storage.blockLibraryPanelWidth, 260.0);
        expect(storage.styleExploreGalleryWidth, 360.0);
      },
    );

    test('paired setter clamps negative widths to zero', () async {
      final storage = _FakeLayoutStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      await container
          .read(layoutStateNotifierProvider.notifier)
          .setStyleExplorePaneWidths(sidebar: -40.0, gallery: -10.0);

      final state = container.read(layoutStateNotifierProvider);
      expect(state.styleExploreRunSidebarWidth, 0.0);
      expect(state.styleExploreGalleryWidth, 0.0);
      expect(storage.styleExploreRunSidebarWidth, 0.0);
      expect(storage.styleExploreGalleryWidth, 0.0);
    });
  });

  group('LayoutState style explore run sidebar visibility', () {
    test(
      'defaults to null so the screen can treat the first visit as open',
      () {
        const state = LayoutState();

        expect(state.styleExploreRunSidebarVisible, isNull);

        final updated = state.copyWith(styleExploreRunSidebarVisible: false);
        expect(updated.styleExploreRunSidebarVisible, isFalse);
        // 不影响同页其他布局字段。
        expect(updated.styleExploreRunSidebarWidth, 240.0);
        expect(updated.styleExploreGalleryWidth, 360.0);
      },
    );

    test('build reads the stored flag and the setter writes it back', () async {
      final storage = _FakeLayoutStorage()
        ..styleExploreRunSidebarVisible = false;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreRunSidebarVisible,
        isFalse,
      );

      await container
          .read(layoutStateNotifierProvider.notifier)
          .setStyleExploreRunSidebarVisible(true);

      expect(storage.styleExploreRunSidebarVisible, isTrue);
      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreRunSidebarVisible,
        isTrue,
      );
    });

    test('a never touched key stays null (no write on first visit)', () {
      final storage = _FakeLayoutStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreRunSidebarVisible,
        isNull,
      );
      expect(storage.styleExploreRunSidebarVisible, isNull);
    });
  });

  group('LayoutState style explore prompt area height', () {
    test('defaults to 280 and copyWith preserves other fields', () {
      const state = LayoutState();

      expect(state.styleExplorePromptAreaHeight, 280.0);

      final updated = state.copyWith(
        styleExplorePromptAreaHeight: 420.0,
        rightPanelWidth: 360.0,
      );
      expect(updated.styleExplorePromptAreaHeight, 420.0);
      expect(updated.rightPanelWidth, 360.0);
    });

    test('build reads and setter writes back with defensive clamp', () async {
      final storage = _FakeLayoutStorage()
        ..styleExplorePromptAreaHeight = 400.0;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExplorePromptAreaHeight,
        400.0,
      );

      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setStyleExplorePromptAreaHeight(460.0);
      expect(storage.styleExplorePromptAreaHeight, 460.0);
      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExplorePromptAreaHeight,
        460.0,
      );

      // 业务范围钳制（最小 100 / 按可用高度的 cap）在探索页调用方做，
      // setter 只做 ≥0 防御。
      await notifier.setStyleExplorePromptAreaHeight(-1.0);
      expect(storage.styleExplorePromptAreaHeight, 0.0);
    });
  });
}

class _FakeLayoutStorage extends LocalStorageService {
  bool rightExpanded = true;
  double rightWidth = 280.0;
  bool mainNavExpanded = false;
  double webWidth = 400.0;
  bool webExpanded = true;
  double blockLibraryPanelWidth = 320.0;
  double styleExploreRunSidebarWidth = 240.0;
  double styleExploreGalleryWidth = 360.0;
  double styleExplorePromptAreaHeight = 280.0;
  bool? styleExploreRunSidebarVisible;

  @override
  bool getRightPanelExpanded() => rightExpanded;

  @override
  double getRightPanelWidth() => rightWidth;

  @override
  bool getMainNavRailExpanded() => mainNavExpanded;

  @override
  Future<void> setMainNavRailExpanded(bool value) async {
    mainNavExpanded = value;
  }

  @override
  double getWebLeftPanelWidth() => webWidth;

  @override
  Future<void> setWebLeftPanelWidth(double value) async {
    webWidth = value;
  }

  @override
  bool getWebLeftPanelExpanded() => webExpanded;

  @override
  Future<void> setWebLeftPanelExpanded(bool value) async {
    webExpanded = value;
  }

  @override
  double getBlockLibraryPanelWidth() => blockLibraryPanelWidth;

  @override
  Future<void> setBlockLibraryPanelWidth(double value) async {
    blockLibraryPanelWidth = value;
  }

  @override
  double getStyleExploreRunSidebarWidth() => styleExploreRunSidebarWidth;

  @override
  Future<void> setStyleExploreRunSidebarWidth(double value) async {
    styleExploreRunSidebarWidth = value;
  }

  @override
  bool? getStyleExploreRunSidebarVisible() => styleExploreRunSidebarVisible;

  @override
  Future<void> setStyleExploreRunSidebarVisible(bool value) async {
    styleExploreRunSidebarVisible = value;
  }

  @override
  double getStyleExploreGalleryWidth() => styleExploreGalleryWidth;

  @override
  Future<void> setStyleExploreGalleryWidth(double value) async {
    styleExploreGalleryWidth = value;
  }

  @override
  double getStyleExplorePromptAreaHeight() => styleExplorePromptAreaHeight;

  @override
  Future<void> setStyleExplorePromptAreaHeight(double value) async {
    styleExplorePromptAreaHeight = value;
  }
}
