import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/style_explore/explore_manual_capture.dart';
import '../../providers/style_explore/explore_run_provider.dart';
import '../../providers/tips_provider.dart';
import '../../widgets/character/character_position_canvas.dart';
import '../../widgets/character/inline_character_section.dart';
import '../../widgets/generation/auto_save_toggle_chip.dart';
import '../generation/widgets/block_library_panel_slot.dart';
import '../generation/widgets/generation_controls/generation_controls.dart';
import '../generation/widgets/generation_param_sections.dart';
import '../generation/widgets/generation_params_menu_host.dart';
import '../generation/widgets/generation_sidebar_style.dart';
import '../generation/widgets/header_capsules.dart';
import '../generation/widgets/img2img_panel.dart';
import '../generation/widgets/precise_reference_panel.dart';
import '../generation/widgets/prompt_input.dart';
import '../generation/widgets/resize_handle.dart';
import '../generation/widgets/section_header.dart';
import '../generation/widgets/unified_reference_panel.dart';
import 'widgets/explore_candidate_gallery.dart';
import 'widgets/explore_run_control_bar.dart';
import 'widgets/explore_run_sidebar.dart';

const double _styleExploreResizeHandleWidth = 8;
const double _styleExploreSidebarLayoutMinWidth = 160;
const double _styleExploreGalleryLayoutMinWidth = 240;

double _nonNegativePaneWidth(double width) {
  if (!width.isFinite) return 0;
  return math.max(0, width);
}

class _StyleExploreConcessionKey {
  const _StyleExploreConcessionKey({
    required this.viewportWidth,
    required this.sidebarVisible,
    required this.galleryVisible,
  });

  final double viewportWidth;
  final bool sidebarVisible;
  final bool galleryVisible;

  @override
  bool operator ==(Object other) {
    return other is _StyleExploreConcessionKey &&
        other.viewportWidth == viewportWidth &&
        other.sidebarVisible == sidebarVisible &&
        other.galleryVisible == galleryVisible;
  }

  @override
  int get hashCode =>
      Object.hash(viewportWidth, sidebarVisible, galleryVisible);
}

class _StyleExplorePaneLayout {
  const _StyleExplorePaneLayout({
    required this.contentWidth,
    required this.mainWidth,
    required this.sidebarWidth,
    required this.galleryWidth,
  });

  final double contentWidth;
  final double mainWidth;
  final double sidebarWidth;
  final double galleryWidth;

  static double calculateRightConcession({
    required double viewportWidth,
    required bool sidebarVisible,
    required bool galleryVisible,
    required double sidebarWidth,
    required double galleryWidth,
    required double blockLibraryWidth,
  }) {
    final normalizedViewport = _nonNegativePaneWidth(viewportWidth);
    final sidebar = sidebarVisible ? _nonNegativePaneWidth(sidebarWidth) : 0.0;
    final gallery = galleryVisible ? _nonNegativePaneWidth(galleryWidth) : 0.0;
    final handleWidth =
        (sidebarVisible ? _styleExploreResizeHandleWidth : 0) +
        (galleryVisible ? _styleExploreResizeHandleWidth : 0);
    final total = math.max(
      math.max(0, normalizedViewport - handleWidth),
      sidebar + gallery,
    );
    if (total == 0) return 0;

    final blockLibrary =
        _nonNegativePaneWidth(blockLibraryWidth) +
        _styleExploreResizeHandleWidth;
    final absorbed = math.min(blockLibrary, total);
    final theoretical = absorbed * (sidebar + gallery) / total;
    final donor = galleryVisible ? gallery : (sidebarVisible ? sidebar : 0.0);
    return math.min(theoretical, donor);
  }

  static double effectiveSidebarWidth({
    required bool blockLibraryExpanded,
    required bool sidebarVisible,
    required bool galleryVisible,
    required double sidebarWidth,
    required double rightConcession,
  }) {
    if (!sidebarVisible) return 0;
    final concession = blockLibraryExpanded && !galleryVisible
        ? rightConcession
        : 0.0;
    return math.max(0, _nonNegativePaneWidth(sidebarWidth) - concession);
  }

  static double effectiveGalleryWidth({
    required bool blockLibraryExpanded,
    required bool galleryVisible,
    required double galleryWidth,
    required double rightConcession,
  }) {
    if (!galleryVisible) return 0;
    final concession = blockLibraryExpanded ? rightConcession : 0.0;
    return math.max(0, _nonNegativePaneWidth(galleryWidth) - concession);
  }

  factory _StyleExplorePaneLayout.calculate({
    required double viewportWidth,
    required bool blockLibraryExpanded,
    required bool sidebarVisible,
    required bool galleryVisible,
    required double blockLibraryWidth,
    required double sidebarWidth,
    required double galleryWidth,
    required double rightConcession,
  }) {
    final blockLibrary = blockLibraryExpanded
        ? _nonNegativePaneWidth(blockLibraryWidth)
        : 0.0;
    final sidebar = effectiveSidebarWidth(
      blockLibraryExpanded: blockLibraryExpanded,
      sidebarVisible: sidebarVisible,
      galleryVisible: galleryVisible,
      sidebarWidth: sidebarWidth,
      rightConcession: rightConcession,
    );
    final gallery = effectiveGalleryWidth(
      blockLibraryExpanded: blockLibraryExpanded,
      galleryVisible: galleryVisible,
      galleryWidth: galleryWidth,
      rightConcession: rightConcession,
    );
    final blockLibraryTotal = blockLibraryExpanded
        ? blockLibrary + _styleExploreResizeHandleWidth
        : 0.0;
    final normalizedViewport = _nonNegativePaneWidth(viewportWidth);
    final closedMainWidth = math.max(
      0.0,
      normalizedViewport -
          (sidebarVisible
              ? _nonNegativePaneWidth(sidebarWidth) +
                    _styleExploreResizeHandleWidth
              : 0.0) -
          (galleryVisible
              ? _nonNegativePaneWidth(galleryWidth) +
                    _styleExploreResizeHandleWidth
              : 0.0),
    );
    final mainConcession = blockLibraryExpanded
        ? blockLibraryTotal - rightConcession
        : 0.0;
    final mainWidth = math.max(0.0, closedMainWidth - mainConcession);
    final contentWidth =
        mainWidth +
        blockLibraryTotal +
        (sidebarVisible ? sidebar + _styleExploreResizeHandleWidth : 0.0) +
        (galleryVisible ? gallery + _styleExploreResizeHandleWidth : 0.0);

    return _StyleExplorePaneLayout(
      contentWidth: contentWidth,
      mainWidth: mainWidth,
      sidebarWidth: sidebar,
      galleryWidth: gallery,
    );
  }
}

/// 画风探索页（主编辑 | 块库插槽 | 探索任务侧栏 | 候选画廊）。
///
/// 主编辑区复用主生成页左栏整套官网式装配（胶囊头/提示词/角色/参考图/
/// 尺寸/参数抽屉/生成按钮）且**数据同源**：提示词=main/negative lane、
/// 参数=generationParamsNotifierProvider，探索页与主生成页实时同一份。
/// 探索页点生成：主链 generate() + 按批次事件登记为活跃 run 的手动候选。
class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});

  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  static const double _galleryBreakpoint = 1100;

  String? _manualAutoRunName;
  _StyleExploreConcessionKey? _rightConcessionKey;
  double _rightConcession = 0;

  /// 候选画廊展开态的用户覆盖；null = 跟随断点自动（宽窗开、窄窗收）。
  bool? _galleryExpandedOverride;

  bool _galleryVisible(double maxWidth) =>
      _galleryExpandedOverride ?? (maxWidth >= _galleryBreakpoint);

  void _toggleGallery(double maxWidth) {
    setState(() => _galleryExpandedOverride = !_galleryVisible(maxWidth));
  }

  /// 探索任务侧栏展开态；null = 从未设置过（首次访问默认展开，露新建任务引导）。
  bool _runSidebarVisible(LayoutState layout) =>
      layout.styleExploreRunSidebarVisible ?? true;

  void _toggleRunSidebar(LayoutState layout) {
    ref
        .read(layoutStateNotifierProvider.notifier)
        .setStyleExploreRunSidebarVisible(!_runSidebarVisible(layout));
  }

  double _syncRightConcession({
    required double viewportWidth,
    required bool blockLibraryExpanded,
    required bool sidebarVisible,
    required bool galleryVisible,
    required LayoutState layout,
  }) {
    if (!blockLibraryExpanded) {
      _rightConcessionKey = null;
      return _rightConcession = 0;
    }
    final key = _StyleExploreConcessionKey(
      viewportWidth: viewportWidth,
      sidebarVisible: sidebarVisible,
      galleryVisible: galleryVisible,
    );
    if (_rightConcessionKey == key) return _rightConcession;
    _rightConcessionKey = key;
    return _rightConcession = _StyleExplorePaneLayout.calculateRightConcession(
      viewportWidth: viewportWidth,
      sidebarVisible: sidebarVisible,
      galleryVisible: galleryVisible,
      sidebarWidth: layout.styleExploreRunSidebarWidth,
      galleryWidth: layout.styleExploreGalleryWidth,
      blockLibraryWidth: layout.blockLibraryPanelWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 探索页没有画布宿主（主页画布占图像预览区）：✥ 入口改走轻量弹窗。
    // 弹窗打开后 provider 再关（画布自带关闭按钮/再次点 ✥）由弹窗内
    // 监听同步收窗，见 _showPositionCanvasDialog。
    ref.listen(characterPositionCanvasProvider, (previous, next) {
      if (next && !(previous ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showPositionCanvasDialog());
        });
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final galleryVisible = _galleryVisible(constraints.maxWidth);
          final layoutState = ref.watch(layoutStateNotifierProvider);
          final runSidebarVisible = _runSidebarVisible(layoutState);
          final blockLibraryExpanded = layoutState.blockLibraryPanelExpanded;
          final rightConcession = _syncRightConcession(
            viewportWidth: constraints.maxWidth,
            blockLibraryExpanded: blockLibraryExpanded,
            sidebarVisible: runSidebarVisible,
            galleryVisible: galleryVisible,
            layout: layoutState,
          );
          final paneLayout = _StyleExplorePaneLayout.calculate(
            viewportWidth: constraints.maxWidth,
            blockLibraryExpanded: blockLibraryExpanded,
            sidebarVisible: runSidebarVisible,
            galleryVisible: galleryVisible,
            blockLibraryWidth: layoutState.blockLibraryPanelWidth,
            sidebarWidth: layoutState.styleExploreRunSidebarWidth,
            galleryWidth: layoutState.styleExploreGalleryWidth,
            rightConcession: rightConcession,
          );

          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              maxWidth: paneLayout.contentWidth,
              child: SizedBox(
                width: paneLayout.contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: paneLayout.mainWidth,
                      child: ClipRect(
                        key: const Key('style-explore-main-editor'),
                        child: Column(
                          children: [
                            WindowHeader(
                              enabled:
                                  !galleryVisible &&
                                  !runSidebarVisible &&
                                  !blockLibraryExpanded,
                              child: _buildTopBar(
                                theme,
                                constraints.maxWidth,
                                galleryVisible,
                                runSidebarVisible,
                                layoutState,
                              ),
                            ),
                            Expanded(
                              child: _buildCenterPanel(
                                theme,
                                availableWidth: paneLayout.mainWidth,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (blockLibraryExpanded)
                      WindowPaneInset(
                        enabled: !galleryVisible && !runSidebarVisible,
                        child: const BlockLibraryPanelSlot(rightDock: true),
                      ),
                    if (runSidebarVisible)
                      WindowPaneInset(
                        enabled: !galleryVisible,
                        child: _buildSidebar(
                          theme,
                          width: paneLayout.sidebarWidth,
                          galleryVisible: galleryVisible,
                          rightConcession: rightConcession,
                        ),
                      ),
                    if (galleryVisible)
                      _buildGalleryPanel(
                        theme,
                        width: paneLayout.galleryWidth,
                        rightConcession: rightConcession,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 顶栏 ====================

  Widget _buildTopBar(
    ThemeData theme,
    double maxWidth,
    bool galleryVisible,
    bool runSidebarVisible,
    LayoutState layoutState,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          key: const Key('style-explore-top-bar-content'),
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildRunSidebarToggle(theme, runSidebarVisible, layoutState),
            _buildGalleryToggle(theme, maxWidth, galleryVisible),
            const AutoSaveToggleIcon(),
          ],
        ),
      ),
    );
  }

  /// 探索任务侧栏开关（首次访问默认展开，用户切换后按存值恢复）。
  /// 图标+文字长方块，激活态填主题主色（静当前主题 = 红）。
  Widget _buildRunSidebarToggle(
    ThemeData theme,
    bool runSidebarVisible,
    LayoutState layoutState,
  ) {
    return Tooltip(
      message: context.l10n.styleExplore_runSectionTitle,
      waitDuration: const Duration(milliseconds: 300),
      child: OutlinedButton.icon(
        key: const Key('style-explore-run-sidebar-toggle'),
        style: runSidebarVisible
            ? OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                side: BorderSide(color: theme.colorScheme.primary),
              )
            : null,
        onPressed: () => _toggleRunSidebar(layoutState),
        icon: const Icon(Icons.explore, size: 18),
        label: Text(context.l10n.styleExplore_runSectionTitle),
      ),
    );
  }

  /// 候选画廊开关（宽窗默认开、窄窗默认关，用户切换覆盖断点默认）。
  Widget _buildGalleryToggle(
    ThemeData theme,
    double maxWidth,
    bool galleryVisible,
  ) {
    return Tooltip(
      message: context.l10n.styleExplore_galleryTitle,
      waitDuration: const Duration(milliseconds: 300),
      child: IconButton(
        key: const Key('style-explore-gallery-toggle'),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: galleryVisible
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          foregroundColor: galleryVisible
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () => _toggleGallery(maxWidth),
        icon: const Icon(StudioIcons.localGallery),
      ),
    );
  }

  /// 头部胶囊行（官网式）：Model/Mode 合一胶囊居左，Opus/Anlas 额度胶囊居右；
  /// 宽度不足时余额胶囊整块落第二行靠左（与主生成页头部同款 Wrap 语义）。
  /// 低于排版下限时按 [editorWidth] 排版、超出部分裁掉（同滚动列保底）。
  Widget _buildCapsuleBar(ThemeData theme, {required double editorWidth}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: UnconstrainedBox(
        constrainedAxis: Axis.vertical,
        alignment: Alignment.centerLeft,
        // 自带裁剪并抑制 debug 溢出警告：窄面板时胶囊按下限排版裁右缘
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          // 16 = 本行 Container 的横向 padding，先扣掉再当排版宽度
          width: editorWidth - 16,
          child: const Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 2,
            spacing: 6,
            children: [ModelModeCapsule(), QuotaChipsCapsule()],
          ),
        ),
      ),
    );
  }

  // ==================== Run 侧栏 ====================

  Widget _buildSidebar(
    ThemeData theme, {
    required double width,
    required bool galleryVisible,
    required double rightConcession,
  }) {
    final panel = SizedBox(
      width: width,
      key: const Key('style-explore-run-sidebar-pane'),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: math.max(width, _styleExploreSidebarLayoutMinWidth),
          child: SizedBox(
            width: math.max(width, _styleExploreSidebarLayoutMinWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
              child: Material(
                color: theme.colorScheme.surfaceContainerLow,
                child: const ExploreRunSidebarSection(
                  key: Key('style-explore-run-sidebar-section'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      key: const Key('style-explore-run-sidebar'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizeHandle(
          key: const Key('style-explore-run-sidebar-resize-handle'),
          onDrag: (dx) {
            final layout = ref.read(layoutStateNotifierProvider);
            final currentSidebar = layout.styleExploreRunSidebarWidth;
            final currentWidth = _StyleExplorePaneLayout.effectiveSidebarWidth(
              blockLibraryExpanded: layout.blockLibraryPanelExpanded,
              sidebarVisible: _runSidebarVisible(layout),
              galleryVisible: galleryVisible,
              sidebarWidth: currentSidebar,
              rightConcession: rightConcession,
            );
            if (!layout.blockLibraryPanelExpanded) {
              final effective = math.min(dx, currentWidth);
              ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setStyleExploreRunSidebarWidth(currentSidebar - effective);
              return;
            }
            final currentBlockLibrary = layout.blockLibraryPanelWidth;
            final effective = dx.clamp(
              -_nonNegativePaneWidth(currentBlockLibrary),
              currentWidth,
            );
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setStyleExplorePaneWidths(
                  blockLibrary: currentBlockLibrary + effective,
                  sidebar: currentSidebar - effective,
                );
          },
        ),
        panel,
      ],
    );
  }

  // ==================== 主编辑区：主生成页左栏整套官网式装配（数据同源） ====================

  /// 编辑区排版宽度下限：窄侧栏挤压到放不下时按下限排版、超出右缘裁掉，
  /// 而不是在卡内溢出（与原 ParameterPanel 的 320 下限一致）。
  static const double _minEditorWidth = 320.0;

  /// 提示词=main/negative lane、参数=generationParamsNotifierProvider，
  /// 与主生成页实时同一份；胶囊行 + Run 控制条嵌主编辑区顶部；生成按钮走
  /// 主链 generate()（探索页入口在真实批次 start 前布防手动候选登记）。
  Widget _buildCenterPanel(ThemeData theme, {required double availableWidth}) {
    final activeRun = ref.watch(exploreActiveRunProvider);
    final activeRunId = activeRun?.id;
    final manualCaptureNotifier = ref.read(
      exploreManualCaptureProvider.notifier,
    );
    final autoRunName = _manualAutoRunName ??= context.l10n
        .styleExplore_manualRunName(_autoRunTimestamp());

    final editorWidth = availableWidth < _minEditorWidth
        ? _minEditorWidth
        : availableWidth;

    return Column(
      children: [
        _buildCapsuleBar(theme, editorWidth: editorWidth),
        if (activeRun != null) ExploreRunControlBar(run: activeRun),
        Expanded(
          child: GenerationParamsMenuHost(
            // 摘要条与滚动列共用一个排版下限（原 ParameterPanel 的 320）
            summaryMinWidth: _minEditorWidth,
            // 一体式滚动列（与主生成页左栏同款；生成数量只留请求次数
            // 步进——探索模式强制逐张出图，1–4 每次张数分段无意义）
            child: SingleChildScrollView(
              child: UnconstrainedBox(
                constrainedAxis: Axis.vertical,
                alignment: Alignment.topLeft,
                // 自带裁剪并抑制 debug 溢出警告（滚动视口也会裁右缘）
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: editorWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 提示词：随内容自由增高（官网式，视觉锚点置顶）
                        const PromptInputWidget(
                          autoGrow: true,
                          showMaximizeButton: false,
                          allowEvolutionToggle: true,
                          tipModule: TipModule.explore,
                        ),
                        const SizedBox(height: GenSidebarStyle.sectionGap),

                        // 角色区：内联在主提示词正下方（官网式，内容常显）
                        const InlineCharacterSection(),
                        const SizedBox(height: GenSidebarStyle.sectionGap),

                        // 功能面板：图生图 / 风格迁移 / 精准参考
                        // （官网 Reference Images 小节）
                        SectionHeader(
                          title: context.l10n.generation_sectionReferenceImages,
                        ),
                        const SizedBox(height: 6),
                        const Img2ImgPanel(),
                        const SizedBox(height: GenSidebarStyle.cardGap),
                        const UnifiedReferencePanel(),
                        const SizedBox(height: GenSidebarStyle.cardGap),
                        const PreciseReferencePanel(),
                        const SizedBox(height: GenSidebarStyle.sectionGap),

                        // 尺寸：低频控件下沉至滚动列末尾（官网 Image Settings 小节）
                        SectionHeader(
                          title: context.l10n.generation_sectionImageSettings,
                        ),
                        const SizedBox(height: 6),
                        const SidebarTitleScope(child: SizeSection()),
                        const SizedBox(height: 12),

                        // 生成数量：只留请求次数步进——探索模式强制逐张
                        // 出图，1–4 每次张数分段无意义
                        const SidebarTitleScope(
                          child: ImageCountSection(
                            showPerRequestSegments: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: SizedBox(
            width: availableWidth,
            child: GenerationControls(
              // 主编辑区宽度有限，用紧凑钉底条（与主生成页左面板同款 2×2
              // 点数块布局），正常布局在此宽度会把点数 chips 压到重叠
              compact: true,
              exploreMode: true,
              // Opus/Anlas 芯片与自动保存都已上移到页面顶部，底栏不再渲染
              showBalanceChips: false,
              showAutoSaveChip: false,
              onBatchEvent: (event) => manualCaptureNotifier.handleBatchEvent(
                event,
                autoRunName: autoRunName,
                activeRunId: activeRunId,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 位置画布轻量弹窗（探索页无画布宿主的替代入口）。
  ///
  /// 画布自带关闭按钮写 `provider.close()`，弹窗内监听其关闭同步收窗；
  /// 点外部/返回键关窗时反向收 provider，避免状态悬空（主页 ✥ 图标会
  /// 残留选中态）。
  Future<void> _showPositionCanvasDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            ref.listen(characterPositionCanvasProvider, (previous, next) {
              if (!next) Navigator.of(dialogContext).pop();
            });
            final screen = MediaQuery.sizeOf(context);
            return Dialog(
              child: SizedBox(
                width: screen.width * 0.6,
                height: screen.height * 0.85,
                child: const CharacterPositionCanvasView(),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (ref.read(characterPositionCanvasProvider)) {
      ref.read(characterPositionCanvasProvider.notifier).close();
    }
  }

  static String _autoRunTimestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
  }

  // ==================== 右栏：候选画廊 ====================

  Widget _buildGalleryPanel(
    ThemeData theme, {
    required double width,
    required double rightConcession,
  }) {
    final panel = SizedBox(
      key: const Key('style-explore-gallery-panel'),
      width: width,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: math.max(width, _styleExploreGalleryLayoutMinWidth),
          child: SizedBox(
            width: math.max(width, _styleExploreGalleryLayoutMinWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(left: BorderSide(color: theme.dividerColor)),
              ),
              child: _buildGalleryContent(theme, width),
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizeHandle(
          key: const Key('style-explore-gallery-resize-handle'),
          onDrag: (dx) {
            final layout = ref.read(layoutStateNotifierProvider);
            final currentGallery = layout.styleExploreGalleryWidth;
            final currentGalleryWidth =
                _StyleExplorePaneLayout.effectiveGalleryWidth(
                  blockLibraryExpanded: layout.blockLibraryPanelExpanded,
                  galleryVisible: true,
                  galleryWidth: currentGallery,
                  rightConcession: rightConcession,
                );
            if (_runSidebarVisible(layout)) {
              final currentSidebar = layout.styleExploreRunSidebarWidth;
              final currentSidebarWidth =
                  _StyleExplorePaneLayout.effectiveSidebarWidth(
                    blockLibraryExpanded: layout.blockLibraryPanelExpanded,
                    sidebarVisible: true,
                    galleryVisible: true,
                    sidebarWidth: currentSidebar,
                    rightConcession: rightConcession,
                  );
              final effective = dx.clamp(
                -currentSidebarWidth,
                currentGalleryWidth,
              );
              ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setStyleExplorePaneWidths(
                    gallery: currentGallery - effective,
                    sidebar: currentSidebar + effective,
                  );
            } else if (layout.blockLibraryPanelExpanded) {
              final currentBlockLibrary = layout.blockLibraryPanelWidth;
              final effective = dx.clamp(
                -_nonNegativePaneWidth(currentBlockLibrary),
                currentGalleryWidth,
              );
              ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setStyleExplorePaneWidths(
                    gallery: currentGallery - effective,
                    blockLibrary: currentBlockLibrary + effective,
                  );
            } else {
              final effective = math.min(dx, currentGalleryWidth);
              ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setStyleExploreGalleryWidth(currentGallery - effective);
            }
          },
        ),
        panel,
      ],
    );
  }

  Widget _buildGalleryContent(ThemeData theme, double visibleWidth) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lay out the header at the visible width, even when the gallery body
        // keeps its minimum layout width while the pane is being resized.
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: visibleWidth,
            child: visibleWidth < 180
                ? SizedBox(height: WindowChromeScope.heightOf(context))
                : WindowPanelHeader(
                    child: SizedBox(
                      key: const Key('style-explore-gallery-header'),
                      height: WindowChromeScope.heightOf(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              StudioIcons.localGallery,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l10n.styleExplore_galleryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              key: const Key('style-explore-gallery-close'),
                              tooltip: l10n.styleExplore_collapseGallery,
                              iconSize: 18,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () => _galleryExpandedOverride = false,
                              ),
                              icon: const Icon(Icons.keyboard_tab_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        const Expanded(child: ExploreCandidateGallery()),
      ],
    );
  }
}
