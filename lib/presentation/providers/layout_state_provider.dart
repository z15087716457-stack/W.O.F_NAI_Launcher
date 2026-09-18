import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';

part 'layout_state_provider.g.dart';

/// UI布局状态数据类
class LayoutState {
  final bool rightPanelExpanded;
  final double rightPanelWidth;
  final bool mainNavRailExpanded;
  final double webLeftPanelWidth;
  final bool webLeftPanelExpanded;
  final bool blockLibraryPanelExpanded;
  final double blockLibraryPanelWidth;
  final double styleExploreRunSidebarWidth;
  final double styleExploreGalleryWidth;
  final double styleExplorePromptAreaHeight;

  /// 探索页 Run 侧栏展开态；null = 从未设置过（首次访问由页面按默认展开处理）。
  final bool? styleExploreRunSidebarVisible;

  const LayoutState({
    this.rightPanelExpanded = true,
    this.rightPanelWidth = 280.0,
    this.mainNavRailExpanded = false,
    this.webLeftPanelWidth = 400.0,
    this.webLeftPanelExpanded = true,
    this.blockLibraryPanelExpanded = false,
    this.blockLibraryPanelWidth = 320.0,
    this.styleExploreRunSidebarWidth = 240.0,
    this.styleExploreGalleryWidth = 360.0,
    this.styleExplorePromptAreaHeight = 280.0,
    this.styleExploreRunSidebarVisible,
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
    double? styleExploreRunSidebarWidth,
    double? styleExploreGalleryWidth,
    double? styleExplorePromptAreaHeight,
    bool? styleExploreRunSidebarVisible,
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
      styleExploreRunSidebarWidth:
          styleExploreRunSidebarWidth ?? this.styleExploreRunSidebarWidth,
      styleExploreGalleryWidth:
          styleExploreGalleryWidth ?? this.styleExploreGalleryWidth,
      styleExplorePromptAreaHeight:
          styleExplorePromptAreaHeight ?? this.styleExplorePromptAreaHeight,
      styleExploreRunSidebarVisible:
          styleExploreRunSidebarVisible ?? this.styleExploreRunSidebarVisible,
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
      styleExploreRunSidebarWidth: storage.getStyleExploreRunSidebarWidth(),
      styleExploreGalleryWidth: storage.getStyleExploreGalleryWidth(),
      styleExplorePromptAreaHeight: storage.getStyleExplorePromptAreaHeight(),
      styleExploreRunSidebarVisible: storage.getStyleExploreRunSidebarVisible(),
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

  /// 设置画风探索页 Run 侧栏宽度
  Future<void> setStyleExploreRunSidebarWidth(double width) async {
    final normalized = width.clamp(0.0, double.infinity).toDouble();
    state = state.copyWith(styleExploreRunSidebarWidth: normalized);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setStyleExploreRunSidebarWidth(normalized);
  }

  /// 设置画风探索页候选画廊宽度
  Future<void> setStyleExploreGalleryWidth(double width) async {
    final normalized = width.clamp(0.0, double.infinity).toDouble();
    state = state.copyWith(styleExploreGalleryWidth: normalized);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setStyleExploreGalleryWidth(normalized);
  }

  /// 设置画风探索页 Run 侧栏展开状态
  ///
  /// 首次访问由探索页按默认展开处理；用户手动开关过一次即落盘，
  /// 此后按存值恢复（与块库/画廊 toggle 同款持久化语义）。
  Future<void> setStyleExploreRunSidebarVisible(bool visible) async {
    state = state.copyWith(styleExploreRunSidebarVisible: visible);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setStyleExploreRunSidebarVisible(visible);
  }

  /// 设置画风探索页主提示词区高度
  ///
  /// 业务范围钳制（最小 100 / 按可用高度算上限）在探索页调用方做，
  /// 这里只做 ≥0 防御。
  Future<void> setStyleExplorePromptAreaHeight(double height) async {
    final normalized = height.clamp(0.0, double.infinity).toDouble();
    state = state.copyWith(styleExplorePromptAreaHeight: normalized);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setStyleExplorePromptAreaHeight(normalized);
  }

  /// 成对调整画风探索页分区宽度（手柄拖拽补偿专用）
  ///
  /// 拖拽分界时右邻 ∓Δ、左邻 ±Δ 同帧写回，被拖分界以外的分界位置不动；
  /// 一次 copyWith、只持久化传入的键，避免每帧两次 state 更新。
  /// 单键 setter 保留给其他调用方。
  Future<void> setStyleExplorePaneWidths({
    double? blockLibrary,
    double? sidebar,
    double? gallery,
  }) async {
    final blockLibraryWidth = blockLibrary
        ?.clamp(0.0, double.infinity)
        .toDouble();
    final sidebarWidth = sidebar?.clamp(0.0, double.infinity).toDouble();
    final galleryWidth = gallery?.clamp(0.0, double.infinity).toDouble();
    state = state.copyWith(
      blockLibraryPanelWidth: blockLibraryWidth,
      styleExploreRunSidebarWidth: sidebarWidth,
      styleExploreGalleryWidth: galleryWidth,
    );

    final storage = ref.read(localStorageServiceProvider);
    if (blockLibraryWidth != null) {
      await storage.setBlockLibraryPanelWidth(blockLibraryWidth);
    }
    if (sidebarWidth != null) {
      await storage.setStyleExploreRunSidebarWidth(sidebarWidth);
    }
    if (galleryWidth != null) {
      await storage.setStyleExploreGalleryWidth(galleryWidth);
    }
  }
}
