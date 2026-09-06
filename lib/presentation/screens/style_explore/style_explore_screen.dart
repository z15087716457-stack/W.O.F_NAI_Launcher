import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/style_explore/style_explore_recipe.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/style_explore/explore_manual_capture.dart';
import '../../providers/style_explore/explore_run_provider.dart';
import '../../providers/style_explore_provider.dart';
import '../../widgets/character/character_position_canvas.dart';
import '../../widgets/character/inline_character_row.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/themed_confirm_dialog.dart';
import '../../widgets/common/themed_input_dialog.dart';
import '../../widgets/prompt/block_library_panel_toggle.dart';
import '../generation/widgets/block_library_panel_slot.dart';
import '../generation/widgets/generation_controls/generation_controls.dart';
import '../generation/widgets/parameter_panel.dart';
import '../generation/widgets/prompt_input.dart';
import '../generation/widgets/resize_handle.dart';
import 'widgets/explore_candidate_gallery.dart';
import 'widgets/explore_run_control_bar.dart';
import 'widgets/explore_run_sidebar.dart';
import 'widgets/style_explore_prompt_preview_dialog.dart';
import 'widgets/style_explore_recipe_list_panel.dart';

/// 画风探索页（主编辑 | 块库插槽 | Run/Recipe | 候选画廊）。
///
/// 主编辑区复用主生成页左栏整套面板（尺寸/种子/正·UC 提示词/角色/
/// 生成按钮全套）且**数据同源**：提示词=main/negative lane、
/// 参数=generationParamsNotifierProvider，探索页与主生成页实时同一份。
/// Recipe=主提示词模板库（载入/保存的都是主双 lane 的 PillDocument 快照）。
/// 探索页点生成：主链 generate() + 按批次事件登记为活跃 run 的手动候选。
class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});

  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  static const double _galleryBreakpoint = 1100;

  String? _manualAutoRunName;

  /// 候选画廊展开态的用户覆盖；null = 跟随断点自动（宽窗开、窄窗收）。
  bool? _galleryExpandedOverride;

  bool _galleryVisible(double maxWidth) =>
      _galleryExpandedOverride ?? (maxWidth >= _galleryBreakpoint);

  void _toggleGallery(double maxWidth) {
    setState(() => _galleryExpandedOverride = !_galleryVisible(maxWidth));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeRecipe = ref.watch(styleExploreActiveRecipeProvider);
    final isDirty = ref.watch(styleExploreDirtyProvider);

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
          const resizeHandleWidth = 8.0;
          final galleryVisible = _galleryVisible(constraints.maxWidth);
          final layoutState = ref.watch(layoutStateNotifierProvider);
          final blockLibraryWidth = layoutState.blockLibraryPanelExpanded
              ? layoutState.blockLibraryPanelWidth
                        .clamp(0.0, double.infinity)
                        .toDouble() +
                    resizeHandleWidth
              : 0.0;
          final sidebarWidth =
              layoutState.styleExploreRunSidebarWidth
                  .clamp(0.0, double.infinity)
                  .toDouble() +
              resizeHandleWidth;
          final galleryWidth = galleryVisible
              ? layoutState.styleExploreGalleryWidth
                        .clamp(0.0, double.infinity)
                        .toDouble() +
                    resizeHandleWidth
              : 0.0;
          final totalPaneWidth =
              blockLibraryWidth + sidebarWidth + galleryWidth;
          final contentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth > totalPaneWidth
                    ? constraints.maxWidth
                    : totalPaneWidth
              : totalPaneWidth;
          final mainWidth = contentWidth - totalPaneWidth;

          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 0,
              maxWidth: contentWidth,
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRect(
                        key: const Key('style-explore-main-editor'),
                        child: Column(
                          children: [
                            _buildTopBar(
                              context,
                              theme,
                              activeRecipe,
                              isDirty,
                              constraints.maxWidth,
                              galleryVisible,
                            ),
                            Expanded(
                              child: _buildCenterPanel(
                                theme,
                                availableWidth: mainWidth,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (layoutState.blockLibraryPanelExpanded)
                      const BlockLibraryPanelSlot(rightDock: true),
                    _buildSidebar(theme),
                    if (galleryVisible) _buildGalleryPanel(theme),
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
    BuildContext context,
    ThemeData theme,
    StyleExploreRecipe? activeRecipe,
    bool isDirty,
    double maxWidth,
    bool galleryVisible,
  ) {
    final l10n = context.l10n;
    final name = activeRecipe?.displayName ?? l10n.styleExplore_noActiveRecipe;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Wrap(
        key: const Key('style-explore-top-bar-content'),
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth.isFinite ? maxWidth : double.infinity,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isDirty) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: l10n.styleExplore_unsavedChanges,
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          FilledButton.tonalIcon(
            key: const Key('style-explore-save'),
            onPressed: activeRecipe != null && isDirty ? _saveActive : null,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(l10n.styleExplore_save),
          ),
          FilledButton.tonalIcon(
            key: const Key('style-explore-save-as'),
            onPressed: _saveAsNew,
            icon: const Icon(Icons.save_as_outlined, size: 18),
            label: Text(l10n.styleExplore_saveAs),
          ),
          OutlinedButton.icon(
            key: const Key('style-explore-preview'),
            onPressed: _showPreview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(l10n.styleExplore_preview),
          ),
          _buildGalleryToggle(theme, maxWidth, galleryVisible),
          const BlockLibraryPanelToggleButton(),
        ],
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
        icon: const Icon(Icons.photo_library_outlined),
      ),
    );
  }

  // ==================== Run 侧栏 ====================

  Widget _buildSidebar(ThemeData theme) {
    final width = ref
        .watch(
          layoutStateNotifierProvider.select(
            (state) => state.styleExploreRunSidebarWidth,
          ),
        )
        .clamp(0.0, double.infinity)
        .toDouble();

    final panel = SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        // Material 承载背景色：ListTile 选中态与水波纹画在最近的
        // Material 上，直接用 DecoratedBox 背景会将其遮挡。
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: ExploreRunSidebarSection(
                  key: Key('style-explore-run-sidebar-section'),
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(child: _buildRecipeSection(theme)),
            ],
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
            // 读取最新布局，避免闭包捕获旧值导致不跟手。
            final layout = ref.read(layoutStateNotifierProvider);
            final currentSidebar = layout.styleExploreRunSidebarWidth;
            // 成对补偿：侧栏 ∓Δ、左邻 ±Δ，被拖分界以外的分界不动。
            // 块库收起时左邻是主编辑（Expanded 天然吸收），单写侧栏即可。
            if (!layout.blockLibraryPanelExpanded) {
              ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setStyleExploreRunSidebarWidth(currentSidebar - dx);
              return;
            }
            final currentBlockLibrary = layout.blockLibraryPanelWidth;
            // 吸收方到 0 后本次拖拽 stall，不做级联吸收。
            var effective = dx;
            if (effective > currentSidebar) effective = currentSidebar;
            if (effective < -currentBlockLibrary) {
              effective = -currentBlockLibrary;
            }
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setStyleExplorePaneWidths(
                  blockLibrary: currentBlockLibrary + effective,
                  sidebar: currentSidebar - effective,
                );
          },
        ),
        ClipRect(child: panel),
      ],
    );
  }

  /// Recipe 区：标题 + 列表缩略（最多 3 条，点击载入）+ 管理弹窗入口。
  Widget _buildRecipeSection(ThemeData theme) {
    final l10n = context.l10n;
    final listAsync = ref.watch(styleExploreRecipeListNotifierProvider);
    final activeRecipeId = ref.watch(
      styleExploreSessionNotifierProvider.select((s) => s.activeRecipeId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.styleExplore_recipeListTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                key: const Key('style-explore-recipe-manager'),
                tooltip: l10n.styleExplore_manageRecipes,
                iconSize: 18,
                onPressed: _showRecipeManagerDialog,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Expanded(
          child: listAsync.maybeWhen(
            data: (list) {
              final recipes = list.recipes;
              if (recipes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.styleExplore_recipesEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              const previewCount = 3;
              return ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final recipe in recipes.take(previewCount))
                    ListTile(
                      key: ValueKey('style-explore-recipe-${recipe.id}'),
                      selected: recipe.id == activeRecipeId,
                      dense: true,
                      title: Text(
                        recipe.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _loadRecipe(recipe),
                    ),
                  if (recipes.length > previewCount)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Text(
                        l10n.styleExplore_recipeMoreCount(
                          recipes.length - previewCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  /// Recipe 管理弹窗：复用现有列表面板的全部交互（载入/新建/重命名/
  /// 复制/删除）；载入或新建成功后关闭弹窗。
  Future<void> _showRecipeManagerDialog() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void closeIfMounted() {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        }

        return Consumer(
          builder: (context, ref, _) {
            final theme = Theme.of(context);
            final listAsync = ref.watch(styleExploreRecipeListNotifierProvider);
            final session = ref.watch(styleExploreSessionNotifierProvider);
            final isDirty = ref.watch(styleExploreDirtyProvider);
            return Dialog(
              key: const Key('style-explore-recipe-dialog'),
              child: SizedBox(
                width: 440,
                height: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.styleExplore_recipeListTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.common_close,
                            iconSize: 18,
                            onPressed: closeIfMounted,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    Expanded(
                      child: listAsync.maybeWhen(
                        data: (list) => StyleExploreRecipeListPanel(
                          recipes: list.recipes,
                          activeRecipeId: session.activeRecipeId,
                          isDirty: isDirty,
                          onLoadRecipe: (recipe) async {
                            if (await _loadRecipe(recipe)) closeIfMounted();
                          },
                          onStartNew: () async {
                            if (await _startNew()) closeIfMounted();
                          },
                          onRenameRecipe: _renameRecipe,
                          onDuplicateRecipe: _duplicateRecipe,
                          onDeleteRecipe: _deleteRecipe,
                        ),
                        orElse: () =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== 主编辑区：主生成页左栏整套面板（数据同源） ====================

  /// 提示词=main/negative lane、参数=generationParamsNotifierProvider，
  /// 与主生成页实时同一份；run 控制条嵌主编辑区顶部；生成按钮走主链
  /// generate()（探索页入口在真实批次 start 前布防手动候选登记）。
  Widget _buildCenterPanel(ThemeData theme, {required double availableWidth}) {
    final activeRun = ref.watch(exploreActiveRunProvider);
    final activeRunId = activeRun?.id;
    final manualCaptureNotifier = ref.read(
      exploreManualCaptureProvider.notifier,
    );
    final autoRunName = _manualAutoRunName ??= context.l10n
        .styleExplore_manualRunName(_autoRunTimestamp());
    return LayoutBuilder(
      builder: (context, constraints) {
        final heightCap = _resolvePromptAreaHeightCap(constraints.maxHeight);
        final promptAreaHeight = ref
            .watch(
              layoutStateNotifierProvider.select(
                (s) => s.styleExplorePromptAreaHeight,
              ),
            )
            .clamp(_minPromptAreaHeight, heightCap)
            .toDouble();
        return Column(
          children: [
            if (activeRun != null) ExploreRunControlBar(run: activeRun),
            SizedBox(
              height: promptAreaHeight,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: const PromptInputWidget(
                  showMaximizeButton: false,
                  allowEvolutionToggle: true,
                ),
              ),
            ),
            const InlineCharacterRow(),
            VerticalResizeHandle(
              key: const Key('style-explore-prompt-area-resize-handle'),
              onDrag: (dy) {
                final cap = _resolvePromptAreaHeightCap(constraints.maxHeight);
                // 拖动以存储值为基准累加（与主生成页同款）；显示高度被
                // cap 钳制时继续拖不产生跳变，窗口恢复后高度直接生效。
                final storedHeight = ref
                    .read(layoutStateNotifierProvider)
                    .styleExplorePromptAreaHeight;
                final newHeight = (storedHeight + dy)
                    .clamp(_minPromptAreaHeight, cap)
                    .toDouble();
                ref
                    .read(layoutStateNotifierProvider.notifier)
                    .setStyleExplorePromptAreaHeight(newHeight);
              },
            ),
            Expanded(child: _buildParameterPanel()),
            Container(
              padding: const EdgeInsets.all(12),
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
                  onBatchEvent: (event) =>
                      manualCaptureNotifier.handleBatchEvent(
                        event,
                        autoRunName: autoRunName,
                        activeRunId: activeRunId,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 提示词区高度下限（与主生成页一致）
  static const double _minPromptAreaHeight = 100.0;

  /// 提示词区默认高度（= 固定高度时代的 280，也是 cap 的下限：
  /// 窄窗顶栏折行吃掉高度时退回默认高度，不硬压到 100 造成
  /// PromptInputWidget 内部溢出）
  static const double _defaultPromptAreaHeight = 280.0;

  /// 手柄占位高度
  static const double _resizeHandleHeight = 8.0;

  /// 底部生成控制条（紧凑态）+ padding 的预留高度
  static const double _generationControlsReservedHeight = 150.0;

  /// 角色行预留高度
  static const double _characterRowReservedHeight = 64.0;

  /// Run 控制条（有活动 Run 时出现）预留高度
  static const double _runBarReservedHeight = 64.0;

  /// 参数面板最小可见高度（拖到上限时至少留出这些）
  static const double _minParameterPanelHeight = 240.0;

  /// 提示词区高度上限：总可用高度减去其余分段的预留，保证参数面板
  /// 与底部控制条不被挤没。
  double _resolvePromptAreaHeightCap(double availableHeight) {
    if (!availableHeight.isFinite || availableHeight <= 0) {
      return double.infinity;
    }
    final maxByPanelBudget =
        availableHeight -
        _resizeHandleHeight -
        _generationControlsReservedHeight -
        _characterRowReservedHeight -
        _runBarReservedHeight -
        _minParameterPanelHeight;
    return maxByPanelBudget
        .clamp(_defaultPromptAreaHeight, double.infinity)
        .toDouble();
  }

  Widget _buildParameterPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth >= 320) {
          return const ParameterPanel();
        }
        return const OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 320,
          maxWidth: 320,
          child: SizedBox(width: 320, child: ParameterPanel()),
        );
      },
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

  // ==================== 右栏：候选画廊（阶段 A 空态占位） ====================

  Widget _buildGalleryPanel(ThemeData theme) {
    final width = ref
        .watch(
          layoutStateNotifierProvider.select((s) => s.styleExploreGalleryWidth),
        )
        .clamp(0.0, double.infinity)
        .toDouble();
    final decoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border(left: BorderSide(color: theme.dividerColor)),
    );
    final panel = Container(
      width: width,
      decoration: decoration,
      child: _buildGalleryContent(theme),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizeHandle(
          key: const Key('style-explore-gallery-resize-handle'),
          onDrag: (dx) {
            // 读取最新的宽度值，避免闭包捕获旧值导致不跟手
            final layout = ref.read(layoutStateNotifierProvider);
            final currentGallery = layout.styleExploreGalleryWidth;
            final currentSidebar = layout.styleExploreRunSidebarWidth;
            // 成对补偿：画廊 ∓Δ、侧栏 ±Δ，只有「侧栏|画廊」分界移动；
            // 吸收方（侧栏）到 0 后本次拖拽 stall，不做级联吸收。
            var effective = dx;
            if (effective > currentGallery) effective = currentGallery;
            if (effective < -currentSidebar) effective = -currentSidebar;
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setStyleExplorePaneWidths(
                  gallery: currentGallery - effective,
                  sidebar: currentSidebar + effective,
                );
          },
        ),
        ClipRect(child: panel),
      ],
    );
  }

  Widget _buildGalleryContent(ThemeData theme) {
    final l10n = context.l10n;
    return Column(
      key: const Key('style-explore-gallery-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
          child: Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.styleExplore_galleryTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const Key('style-explore-gallery-close'),
                tooltip: l10n.common_close,
                iconSize: 18,
                onPressed: () =>
                    setState(() => _galleryExpandedOverride = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        const Expanded(child: ExploreCandidateGallery()),
      ],
    );
  }

  // ==================== Recipe 会话动作 ====================

  Future<bool> _confirmDiscardChanges() async {
    if (!ref.read(styleExploreNeedsOverwriteConfirmProvider)) return true;
    final l10n = context.l10n;
    return ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_discardChangesTitle,
      content: l10n.styleExplore_discardChangesMessage,
      confirmText: l10n.styleExplore_discardChangesConfirm,
      cancelText: MaterialLocalizations.of(context).cancelButtonLabel,
    );
  }

  Future<bool> _loadRecipe(StyleExploreRecipe recipe) async {
    if (!await _confirmDiscardChanges()) return false;
    final ok = await ref
        .read(styleExploreSessionNotifierProvider.notifier)
        .loadRecipe(recipe.id);
    if (!mounted) return false;
    if (ok) {
      AppToast.success(
        context,
        context.l10n.styleExplore_recipeLoaded(recipe.displayName),
      );
    }
    return ok;
  }

  Future<bool> _startNew() async {
    if (!await _confirmDiscardChanges()) return false;
    ref.read(styleExploreSessionNotifierProvider.notifier).startNew();
    return true;
  }

  Future<void> _saveActive() async {
    final l10n = context.l10n;
    try {
      final saved = await ref
          .read(styleExploreSessionNotifierProvider.notifier)
          .saveActive();
      if (!mounted) return;
      if (saved == null) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      } else {
        AppToast.success(
          context,
          l10n.styleExplore_recipeSaved(saved.displayName),
        );
      }
    } catch (error) {
      AppLogger.e(
        'Save style explore recipe failed',
        error,
        null,
        'StyleExplore',
      );
      if (mounted) AppToast.error(context, l10n.styleExplore_operationFailed);
    }
  }

  Future<void> _saveAsNew() async {
    final l10n = context.l10n;
    final activeRecipe = ref.read(styleExploreActiveRecipeProvider);
    final name = await _promptForName(initial: activeRecipe?.name);
    if (name == null || name.trim().isEmpty) return;

    try {
      final created = await ref
          .read(styleExploreSessionNotifierProvider.notifier)
          .saveAsNew(name.trim());
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_recipeCreated(created.displayName),
        );
      }
    } catch (error) {
      AppLogger.e('Save as new recipe failed', error, null, 'StyleExplore');
      if (mounted) AppToast.error(context, l10n.styleExplore_operationFailed);
    }
  }

  Future<String?> _promptForName({String? initial}) {
    final l10n = context.l10n;
    return ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_saveAs,
      labelText: l10n.styleExplore_recipeNameLabel,
      hintText: l10n.styleExplore_recipeNameHint,
      initialValue: initial,
      validator: (value) =>
          value.trim().isEmpty ? l10n.styleExplore_nameRequired : null,
    );
  }

  Future<void> _renameRecipe(StyleExploreRecipe recipe) async {
    final l10n = context.l10n;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_rename,
      labelText: l10n.styleExplore_recipeNameLabel,
      initialValue: recipe.displayName,
      validator: (value) =>
          value.trim().isEmpty ? l10n.styleExplore_nameRequired : null,
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(styleExploreRecipeListNotifierProvider.notifier)
        .rename(recipe.id, name.trim());
  }

  Future<void> _duplicateRecipe(StyleExploreRecipe recipe) async {
    final l10n = context.l10n;
    try {
      final copy = await ref
          .read(styleExploreRecipeListNotifierProvider.notifier)
          .duplicate(recipe.id);
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_recipeDuplicated(copy.displayName),
        );
      }
    } catch (error) {
      AppLogger.e('Duplicate recipe failed', error, null, 'StyleExplore');
      if (mounted) AppToast.error(context, l10n.styleExplore_operationFailed);
    }
  }

  Future<void> _deleteRecipe(StyleExploreRecipe recipe) async {
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.showDelete(
      context: context,
      itemName: recipe.displayName,
    );
    if (!confirmed) return;

    final id = recipe.id;
    try {
      await ref
          .read(styleExploreRecipeListNotifierProvider.notifier)
          .delete(id);
      ref
          .read(styleExploreSessionNotifierProvider.notifier)
          .handleRecipeDeleted(id);
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_recipeDeleted(recipe.displayName),
        );
      }
    } catch (error) {
      AppLogger.e('Delete recipe failed', error, null, 'StyleExplore');
      if (mounted) AppToast.error(context, l10n.styleExplore_operationFailed);
    }
  }

  void _showPreview() {
    final positive = ref
        .read(pillWorkspaceProvider(PillScopes.main))
        .projection;
    final negative = ref
        .read(pillWorkspaceProvider(PillScopes.negative))
        .projection;
    StyleExplorePromptPreviewDialog.show(
      context,
      positiveText: positive,
      negativeText: negative,
    );
  }
}
