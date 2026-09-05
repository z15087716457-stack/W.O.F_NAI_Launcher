import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';

part 'layout_state_provider.g.dart';

/// UI布局状态数据类
class LayoutState {
  final bool leftPanelExpanded;
  final bool rightPanelExpanded;
  final double leftPanelWidth;
  final double rightPanelWidth;
  final double promptAreaHeight;
  final bool promptMaximized;
  final bool mainNavRailExpanded;
  final bool fixedTagsSidebarExpanded;
  final double fixedTagsSidebarWidth;
  final String fixedTagsSidebarViewMode;
  final double fixedTagsNegativeHeight;
  final double webLeftPanelWidth;
  final bool webLeftPanelExpanded;
  final bool blockLibraryPanelExpanded;
  final double blockLibraryPanelWidth;
  final double styleExploreRunSidebarWidth;
  final double styleExploreGalleryWidth;

  const LayoutState({
    this.leftPanelExpanded = true,
    this.rightPanelExpanded = true,
    this.leftPanelWidth = 300.0,
    this.rightPanelWidth = 280.0,
    this.promptAreaHeight = 200.0,
    this.promptMaximized = false,
    this.mainNavRailExpanded = false,
    this.fixedTagsSidebarExpanded = false,
    this.fixedTagsSidebarWidth = 280.0,
    this.fixedTagsSidebarViewMode = 'list',
    this.fixedTagsNegativeHeight = 180.0,
    this.webLeftPanelWidth = 400.0,
    this.webLeftPanelExpanded = true,
    this.blockLibraryPanelExpanded = false,
    this.blockLibraryPanelWidth = 320.0,
    this.styleExploreRunSidebarWidth = 240.0,
    this.styleExploreGalleryWidth = 360.0,
  });

  /// 复制并更新部分字段
  LayoutState copyWith({
    bool? leftPanelExpanded,
    bool? rightPanelExpanded,
    double? leftPanelWidth,
    double? rightPanelWidth,
    double? promptAreaHeight,
    bool? promptMaximized,
    bool? mainNavRailExpanded,
    bool? fixedTagsSidebarExpanded,
    double? fixedTagsSidebarWidth,
    String? fixedTagsSidebarViewMode,
    double? fixedTagsNegativeHeight,
    double? webLeftPanelWidth,
    bool? webLeftPanelExpanded,
    bool? blockLibraryPanelExpanded,
    double? blockLibraryPanelWidth,
    double? styleExploreRunSidebarWidth,
    double? styleExploreGalleryWidth,
  }) {
    return LayoutState(
      leftPanelExpanded: leftPanelExpanded ?? this.leftPanelExpanded,
      rightPanelExpanded: rightPanelExpanded ?? this.rightPanelExpanded,
      leftPanelWidth: leftPanelWidth ?? this.leftPanelWidth,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
      promptAreaHeight: promptAreaHeight ?? this.promptAreaHeight,
      promptMaximized: promptMaximized ?? this.promptMaximized,
      mainNavRailExpanded: mainNavRailExpanded ?? this.mainNavRailExpanded,
      fixedTagsSidebarExpanded:
          fixedTagsSidebarExpanded ?? this.fixedTagsSidebarExpanded,
      fixedTagsSidebarWidth:
          fixedTagsSidebarWidth ?? this.fixedTagsSidebarWidth,
      fixedTagsSidebarViewMode:
          fixedTagsSidebarViewMode ?? this.fixedTagsSidebarViewMode,
      fixedTagsNegativeHeight:
          fixedTagsNegativeHeight ?? this.fixedTagsNegativeHeight,
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
      leftPanelExpanded: storage.getLeftPanelExpanded(),
      rightPanelExpanded: storage.getRightPanelExpanded(),
      leftPanelWidth: storage.getLeftPanelWidth(),
      rightPanelWidth: storage.getRightPanelWidth(),
      promptAreaHeight: storage.getPromptAreaHeight(),
      promptMaximized: storage.getPromptMaximized(),
      mainNavRailExpanded: storage.getMainNavRailExpanded(),
      fixedTagsSidebarExpanded: storage.getFixedTagsSidebarExpanded(),
      fixedTagsSidebarWidth: storage.getFixedTagsSidebarWidth(),
      fixedTagsSidebarViewMode: storage.getFixedTagsSidebarViewMode(),
      fixedTagsNegativeHeight: storage.getFixedTagsNegativeHeight(),
      webLeftPanelWidth: storage.getWebLeftPanelWidth(),
      webLeftPanelExpanded: storage.getWebLeftPanelExpanded(),
      blockLibraryPanelExpanded: storage.getBlockLibraryPanelExpanded(),
      blockLibraryPanelWidth: storage.getBlockLibraryPanelWidth(),
      styleExploreRunSidebarWidth: storage.getStyleExploreRunSidebarWidth(),
      styleExploreGalleryWidth: storage.getStyleExploreGalleryWidth(),
    );
  }

  /// 设置左侧面板展开状态
  Future<void> setLeftPanelExpanded(bool expanded) async {
    state = state.copyWith(leftPanelExpanded: expanded);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setLeftPanelExpanded(expanded);
  }

  /// 切换左侧面板展开状态
  Future<void> toggleLeftPanel() async {
    await setLeftPanelExpanded(!state.leftPanelExpanded);
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

  /// 设置左侧面板宽度
  Future<void> setLeftPanelWidth(double width) async {
    state = state.copyWith(leftPanelWidth: width);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setLeftPanelWidth(width);
  }

  /// 设置右侧面板宽度
  Future<void> setRightPanelWidth(double width) async {
    state = state.copyWith(rightPanelWidth: width);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setRightPanelWidth(width);
  }

  /// 设置提示区域高度
  Future<void> setPromptAreaHeight(double height) async {
    state = state.copyWith(promptAreaHeight: height);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPromptAreaHeight(height);
  }

  /// 设置提示区域最大化状态
  Future<void> setPromptMaximized(bool maximized) async {
    state = state.copyWith(promptMaximized: maximized);

    // 保存到本地存储
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPromptMaximized(maximized);
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

  /// 设置固定词侧边栏展开状态
  Future<void> setFixedTagsSidebarExpanded(bool expanded) async {
    state = state.copyWith(fixedTagsSidebarExpanded: expanded);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setFixedTagsSidebarExpanded(expanded);
  }

  /// 切换固定词侧边栏展开状态
  Future<void> toggleFixedTagsSidebar() async {
    await setFixedTagsSidebarExpanded(!state.fixedTagsSidebarExpanded);
  }

  /// 设置固定词侧边栏宽度
  Future<void> setFixedTagsSidebarWidth(double width) async {
    final clamped = width.clamp(240.0, 400.0).toDouble();
    state = state.copyWith(fixedTagsSidebarWidth: clamped);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setFixedTagsSidebarWidth(clamped);
  }

  /// 设置固定词侧边栏视图模式
  Future<void> setFixedTagsSidebarViewMode(String mode) async {
    final normalized = mode == 'grid' ? 'grid' : 'list';
    state = state.copyWith(fixedTagsSidebarViewMode: normalized);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setFixedTagsSidebarViewMode(normalized);
  }

  /// 设置负向固定词区域高度
  Future<void> setFixedTagsNegativeHeight(double height) async {
    final clamped = height.clamp(60.0, 500.0).toDouble();
    state = state.copyWith(fixedTagsNegativeHeight: clamped);

    final storage = ref.read(localStorageServiceProvider);
    await storage.setFixedTagsNegativeHeight(clamped);
  }

  /// 设置官网式布局左栏宽度
  Future<void> setWebLeftPanelWidth(double width) async {
    final clamped = width.clamp(320.0, 560.0).toDouble();
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
}
