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

  group('exploration workbench persistence', () {
    test('candidate size survives recreating the layout provider', () async {
      final storage = _FakeLayoutStorage();
      ProviderContainer create() => ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      final first = create();
      expect(
        first.read(layoutStateNotifierProvider).styleExploreGridLarge,
        isTrue,
      );
      await first
          .read(layoutStateNotifierProvider.notifier)
          .setStyleExploreGridLarge(false);
      first.dispose();
      final restored = create();
      addTearDown(restored.dispose);
      expect(
        restored.read(layoutStateNotifierProvider).styleExploreGridLarge,
        isFalse,
      );
      expect(
        restored.read(layoutStateNotifierProvider).styleExploreEditorWidth,
        384,
      );
    });
    test('new defaults and nullable copyWith preserve unrelated layout', () {
      const state = LayoutState();
      expect(state.styleExploreEditorWidth, 384);
      expect(state.styleExploreInspectorWidth, 312);
      expect(state.styleExploreInspectorVisible, isNull);
      final manual = state.copyWith(styleExploreInspectorVisible: false);
      expect(
        manual.copyWith(rightPanelWidth: 350).styleExploreInspectorVisible,
        false,
      );
      expect(
        manual
            .copyWith(styleExploreInspectorVisible: null)
            .styleExploreInspectorVisible,
        isNull,
      );
      expect(manual.styleExploreEditorWidth, 384);
    });

    test('editor and inspector clamp independently and persist', () async {
      final storage = _FakeLayoutStorage()
        ..styleExploreEditorWidth = 450
        ..styleExploreInspectorWidth = 350;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreEditorWidth,
        450,
      );
      expect(
        container.read(layoutStateNotifierProvider).styleExploreInspectorWidth,
        350,
      );
      await notifier.setStyleExploreEditorWidth(9999);
      await notifier.setStyleExploreInspectorWidth(1);
      expect(storage.styleExploreEditorWidth, 560);
      expect(storage.styleExploreInspectorWidth, 280);
      await notifier.setStyleExploreEditorWidth(1);
      await notifier.setStyleExploreInspectorWidth(9999);
      expect(storage.styleExploreEditorWidth, 352);
      expect(storage.styleExploreInspectorWidth, 420);
      await notifier.setStyleExploreEditorWidth(double.nan);
      await notifier.setStyleExploreInspectorWidth(double.infinity);
      expect(storage.styleExploreEditorWidth, 384);
      expect(storage.styleExploreInspectorWidth, 312);
      expect(storage.blockLibraryPanelWidth, 320);
    });

    test('visibility stores manual intent and can return to auto', () async {
      final storage = _FakeLayoutStorage()
        ..styleExploreInspectorVisible = false;
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreInspectorVisible,
        false,
      );
      await notifier.setStyleExploreInspectorVisible(true);
      expect(storage.styleExploreInspectorVisible, true);
      await notifier.setStyleExploreInspectorVisible(null);
      expect(storage.styleExploreInspectorVisible, isNull);
      expect(
        container
            .read(layoutStateNotifierProvider)
            .styleExploreInspectorVisible,
        isNull,
      );
    });
  });
}

class _FakeLayoutStorage extends LocalStorageService {
  final settings = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      settings[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    settings[key] = value;
  }

  bool rightExpanded = true;
  double rightWidth = 280;
  bool mainNavExpanded = false;
  double webWidth = 400;
  bool webExpanded = true;
  double blockLibraryPanelWidth = 320;
  double styleExploreEditorWidth = 384;
  double styleExploreInspectorWidth = 312;
  bool? styleExploreInspectorVisible;
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
  double getStyleExploreEditorWidth() => styleExploreEditorWidth;
  @override
  Future<void> setStyleExploreEditorWidth(double value) async {
    styleExploreEditorWidth = value;
  }

  @override
  double getStyleExploreInspectorWidth() => styleExploreInspectorWidth;
  @override
  Future<void> setStyleExploreInspectorWidth(double value) async {
    styleExploreInspectorWidth = value;
  }

  @override
  bool? getStyleExploreInspectorVisible() => styleExploreInspectorVisible;
  @override
  Future<void> setStyleExploreInspectorVisible(bool? value) async {
    styleExploreInspectorVisible = value;
  }
}
