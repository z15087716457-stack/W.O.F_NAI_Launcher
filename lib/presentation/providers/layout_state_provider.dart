import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/constants/storage_keys.dart';

part 'layout_state_provider.g.dart';

const _unchangedInspectorVisibility = Object();

/// UI布局状态数据类
class LayoutState {
  final bool rightPanelExpanded;
  final double rightPanelWidth;
  final bool mainNavRailExpanded;
  final double webLeftPanelWidth;
  final bool webLeftPanelExpanded;
  final bool blockLibraryPanelExpanded;
  final double blockLibraryPanelWidth;
  final bool blockPaletteToolPinned;
  final bool translationToolPinned;
  final bool blockLibraryPanelToolPinned;
  final bool styleExploreGridLarge;
  final double styleExploreEditorWidth;
  final double styleExploreInspectorWidth;

  /// null follows available width; a user override persists across windows.
  final bool? styleExploreInspectorVisible;

  const LayoutState({
    this.rightPanelExpanded = true,
    this.rightPanelWidth = 280.0,
    this.mainNavRailExpanded = false,
    this.webLeftPanelWidth = 400.0,
    this.webLeftPanelExpanded = true,
    this.blockLibraryPanelExpanded = false,
    this.blockLibraryPanelWidth = 320.0,
    this.blockPaletteToolPinned = true,
    this.translationToolPinned = true,
    this.blockLibraryPanelToolPinned = false,
    this.styleExploreGridLarge = true,
    this.styleExploreEditorWidth = 384.0,
    this.styleExploreInspectorWidth = 312.0,
    this.styleExploreInspectorVisible,
  });

  /// 复制并更新部分字段
  LayoutState copyWith({
    bool? rightPanelExpanded,
    double? rightPanelWidth,
    bool? mainNavRailExpanded,
    double? webLeftPanelWidth,
    bool? webLeftPanelExpanded,
    bool? blockLibraryPanelExpanded,
    double? blockLibraryPanelWidth,
    bool? blockPaletteToolPinned,
    bool? translationToolPinned,
    bool? blockLibraryPanelToolPinned,
    bool? styleExploreGridLarge,
    double? styleExploreEditorWidth,
    double? styleExploreInspectorWidth,
    Object? styleExploreInspectorVisible = _unchangedInspectorVisibility,
  }) {
    return LayoutState(
      rightPanelExpanded: rightPanelExpanded ?? this.rightPanelExpanded,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      mainNavRailExpanded: mainNavRailExpanded ?? this.mainNavRailExpanded,
      webLeftPanelWidth: webLeftPanelWidth ?? this.webLeftPanelWidth,
      webLeftPanelExpanded: webLeftPanelExpanded ?? this.webLeftPanelExpanded,
      blockLibraryPanelExpanded:
          blockLibraryPanelExpanded ?? this.blockLibraryPanelExpanded,
      blockLibraryPanelWidth:
          blockLibraryPanelWidth ?? this.blockLibraryPanelWidth,
      blockPaletteToolPinned:
          blockPaletteToolPinned ?? this.blockPaletteToolPinned,
      translationToolPinned:
          translationToolPinned ?? this.translationToolPinned,
      blockLibraryPanelToolPinned:
          blockLibraryPanelToolPinned ?? this.blockLibraryPanelToolPinned,
      styleExploreGridLarge:
          styleExploreGridLarge ?? this.styleExploreGridLarge,
      styleExploreEditorWidth:
          styleExploreEditorWidth ?? this.styleExploreEditorWidth,
      styleExploreInspectorWidth:
          styleExploreInspectorWidth ?? this.styleExploreInspectorWidth,
      styleExploreInspectorVisible:
          identical(styleExploreInspectorVisible, _unchangedInspectorVisibility)
          ? this.styleExploreInspectorVisible
          : styleExploreInspectorVisible as bool?,
    );
  }
}

/// UI布局状态 Notifier
@riverpod
class LayoutStateNotifier extends _$LayoutStateNotifier {
  @override
  LayoutState build() {
    // 从本地存储加载布局状态
    final storage = ref.read(localStorageServiceProvider);

    return LayoutState(
      rightPanelExpanded: storage.getRightPanelExpanded(),
      rightPanelWidth: storage.getRightPanelWidth(),
      mainNavRailExpanded: storage.getMainNavRailExpanded(),
      webLeftPanelWidth: storage.getWebLeftPanelWidth(),
      webLeftPanelExpanded: storage.getWebLeftPanelExpanded(),
      blockLibraryPanelExpanded: storage.getBlockLibraryPanelExpanded(),
      blockLibraryPanelWidth: storage.getBlockLibraryPanelWidth(),
      blockPaletteToolPinned: storage.getBlockPaletteToolPinned(),
      translationToolPinned: storage.getTranslationToolPinned(),
      blockLibraryPanelToolPinned: storage.getBlockLibraryPanelToolPinned(),
      styleExploreGridLarge:
          storage.getSetting<bool>(
            StorageKeys.styleExploreGridLarge,
            defaultValue: true,
          ) ??
          true,
      styleExploreEditorWidth: storage.getStyleExploreEditorWidth(),
      styleExploreInspectorWidth: storage.getStyleExploreInspectorWidth(),
      styleExploreInspectorVisible: storage.getStyleExploreInspectorVisible(),
    );
  }

  /// 设置右侧面板展开状态
  Future<void> setRightPanelExpanded(bool expanded) async {
    state = state.copyWith(rightPanelExpanded: expanded);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setRightPanelExpanded(expanded);
  }

  /// 切换右侧面板展开状态
  Future<void> toggleRightPanel() async {
    await setRightPanelExpanded(!state.rightPanelExpanded);
  }

  /// 设置右侧面板宽度
  Future<void> setRightPanelWidth(double width) async {
    state = state.copyWith(rightPanelWidth: width);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setRightPanelWidth(width);
  }

  /// 设置桌面主导航栏展开状态
  Future<void> setMainNavRailExpanded(bool expanded) async {
    state = state.copyWith(mainNavRailExpanded: expanded);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setMainNavRailExpanded(expanded);
  }

  /// 切换桌面主导航栏展开状态
  Future<void> toggleMainNavRail() async {
    await setMainNavRailExpanded(!state.mainNavRailExpanded);
  }

  /// 设置官网式布局左栏宽度
  Future<void> setWebLeftPanelWidth(double width) async {
    // 下限 = 头部条 Model/Mode 两胶囊 + 折叠按钮能放下的最小宽度
    final clamped = width.clamp(352.0, 560.0).toDouble();
    state = state.copyWith(webLeftPanelWidth: clamped);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setWebLeftPanelWidth(clamped);
  }

  /// 设置官网式布局左栏展开状态
  Future<void> setWebLeftPanelExpanded(bool expanded) async {
    state = state.copyWith(webLeftPanelExpanded: expanded);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setWebLeftPanelExpanded(expanded);
  }

  /// 设置块库面板展开状态
  Future<void> setBlockLibraryPanelExpanded(bool expanded) async {
    state = state.copyWith(blockLibraryPanelExpanded: expanded);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setBlockLibraryPanelExpanded(expanded);
  }

  /// 切换块库面板展开状态
  Future<void> toggleBlockLibraryPanel() async {
    await setBlockLibraryPanelExpanded(!state.blockLibraryPanelExpanded);
  }

  /// 设置块库面板宽度
  Future<void> setBlockLibraryPanelWidth(double width) async {
    final normalized = width.clamp(0.0, double.infinity).toDouble();
    state = state.copyWith(blockLibraryPanelWidth: normalized);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setBlockLibraryPanelWidth(normalized);
  }

  /// 设置积木工具钮钉住状态（提示词头部图标位显隐，模块与开关菜单管理）
  Future<void> setBlockPaletteToolPinned(bool pinned) async {
    state = state.copyWith(blockPaletteToolPinned: pinned);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setBlockPaletteToolPinned(pinned);
  }

  /// 切换积木工具钮钉住状态
  Future<void> toggleBlockPaletteToolPinned() async {
    await setBlockPaletteToolPinned(!state.blockPaletteToolPinned);
  }

  Future<void> toggleTranslationToolPinned() async {
    state = state.copyWith(translationToolPinned: !state.translationToolPinned);
    await ref
        .read(localStorageServiceProvider)
        .setTranslationToolPinned(state.translationToolPinned);
  }

  /// 设置块库面板图标钉住状态（头部"块库"图标位显隐）
  Future<void> setBlockLibraryPanelToolPinned(bool pinned) async {
    state = state.copyWith(blockLibraryPanelToolPinned: pinned);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setBlockLibraryPanelToolPinned(pinned);
  }

  /// 切换块库面板图标钉住状态
  Future<void> toggleBlockLibraryPanelToolPinned() async {
    await setBlockLibraryPanelToolPinned(!state.blockLibraryPanelToolPinned);
  }

  Future<void> setStyleExploreGridLarge(bool large) async {
    state = state.copyWith(styleExploreGridLarge: large);
    await ref
        .read(localStorageServiceProvider)
        .setSetting<bool>(StorageKeys.styleExploreGridLarge, large);
  }

  Future<void> setStyleExploreEditorWidth(double width) async {
    final value = width.isFinite ? width.clamp(352.0, 560.0).toDouble() : 384.0;
    state = state.copyWith(styleExploreEditorWidth: value);
    await ref
        .read(localStorageServiceProvider)
        .setStyleExploreEditorWidth(value);
  }

  Future<void> setStyleExploreInspectorWidth(double width) async {
    final value = width.isFinite ? width.clamp(280.0, 420.0).toDouble() : 312.0;
    state = state.copyWith(styleExploreInspectorWidth: value);
    await ref
        .read(localStorageServiceProvider)
        .setStyleExploreInspectorWidth(value);
  }

  Future<void> setStyleExploreInspectorVisible(bool? visible) async {
    state = state.copyWith(styleExploreInspectorVisible: visible);
    await ref
        .read(localStorageServiceProvider)
        .setStyleExploreInspectorVisible(visible);
  }
}
