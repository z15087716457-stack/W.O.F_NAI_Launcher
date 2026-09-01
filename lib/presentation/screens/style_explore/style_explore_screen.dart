import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/style_explore/style_explore_recipe.dart';
import '../../providers/character_position_canvas_provider.dart';
import '../../providers/image_generation_provider.dart';
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

/// 画风探索页（三栏：Run/Recipe | 主生成左栏整套面板 | 候选画廊）。
///
/// 中栏不再是独立编辑区，而是主生成页左栏整套面板（尺寸/种子/正·UC
/// 提示词/角色/生成按钮全套）且**数据同源**：提示词=main/negative lane、
/// 参数=generationParamsNotifierProvider，探索页与主生成页实时同一份。
/// Recipe=主提示词模板库（载入/保存的都是主双 lane 的 PillDocument 快照）。
/// 探索页点生成：主链 generate() + 完成登记为活跃 run 的手动候选。
class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});

  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  static const double _sidebarWidth = 240;
  static const double _sidebarBreakpoint = 760;
  static const double _galleryBreakpoint = 1100;
  static const double _galleryMinWidth = 320;
  static const double _galleryMaxWidth = 560;

  bool _isResizingGallery = false;

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
          final maxWidth = constraints.maxWidth;
          final showSidebar = maxWidth >= _sidebarBreakpoint;
          final galleryVisible = _galleryVisible(maxWidth);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSidebar) _buildSidebar(theme),
              const BlockLibraryPanelSlot(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(
                      context,
                      theme,
                      activeRecipe,
                      isDirty,
                      maxWidth,
                      galleryVisible,
                    ),
                    if (!showSidebar) _buildCompactRecipeSelector(theme),
                    Expanded(child: _buildCenterPanel(theme)),
                  ],
                ),
              ),
              if (galleryVisible) _buildGalleryPanel(theme),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.explore_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
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
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            key: const Key('style-explore-save'),
            onPressed: activeRecipe != null && isDirty ? _saveActive : null,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(l10n.styleExplore_save),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            key: const Key('style-explore-save-as'),
            onPressed: _saveAsNew,
            icon: const Icon(Icons.save_as_outlined, size: 18),
            label: Text(l10n.styleExplore_saveAs),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('style-explore-preview'),
            onPressed: _showPreview,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(l10n.styleExplore_preview),
          ),
          const SizedBox(width: 8),
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

  // ==================== 左栏 ====================

  Widget _buildSidebar(ThemeData theme) {
    return SizedBox(
      width: _sidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
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
              const Expanded(child: ExploreRunSidebarSection()),
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

  // ==================== 中栏 ====================

  /// 窄窗口时用下拉菜单承载 Recipe 选择与新建。
  Widget _buildCompactRecipeSelector(ThemeData theme) {
    final l10n = context.l10n;
    final recipes = ref
        .watch(styleExploreRecipeListNotifierProvider)
        .valueOrNull
        ?.recipes;
    final activeRecipe = ref.watch(styleExploreActiveRecipeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              key: const Key('style-explore-compact-selector'),
              tooltip: l10n.styleExplore_recipeListTitle,
              enabled: recipes != null && recipes.isNotEmpty,
              itemBuilder: (context) => [
                for (final recipe in recipes ?? const <StyleExploreRecipe>[])
                  PopupMenuItem(
                    value: recipe.id,
                    child: Text(recipe.displayName),
                  ),
              ],
              onSelected: (id) {
                final recipe = recipes?.where((r) => r.id == id).firstOrNull;
                if (recipe != null) _loadRecipe(recipe);
              },
              child: Text(
                activeRecipe?.displayName ?? l10n.styleExplore_noActiveRecipe,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.styleExplore_newRecipe,
            onPressed: _startNew,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // ==================== 中栏：主生成页左栏整套面板（数据同源） ====================

  /// 提示词=main/negative lane、参数=generationParamsNotifierProvider，
  /// 与主生成页实时同一份；run 控制条嵌中栏顶部；生成按钮走主链
  /// generate()（探索页入口额外布防手动候选登记）。
  Widget _buildCenterPanel(ThemeData theme) {
    final activeRun = ref.watch(exploreActiveRunProvider);
    return Column(
      children: [
        if (activeRun != null) ExploreRunControlBar(run: activeRun),
        SizedBox(
          height: 280,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: const PromptInputWidget(showMaximizeButton: false),
          ),
        ),
        const InlineCharacterRow(),
        const Expanded(child: ParameterPanel()),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: GenerationControls(
            // 中栏宽度有限，用紧凑钉底条（与主生成页左面板同款 2×2
            // 点数块布局），正常布局在此宽度会把点数 chips 压到重叠
            compact: true,
            onGenerateInvoked: _handleExploreGenerateInvoked,
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

  /// 探索页生成按钮钩子（generate() 同步启动后触发，此刻 roll 尚未发生）：
  /// 布防手动候选登记——点击瞬间抓 roll 快照+图 id 基线，完成后登记为
  /// 活跃 run 的手动候选。冷却拦截未真正启动（isGenerating=false）时跳过，
  /// 避免把下一张主页面生成的图误登记。
  void _handleExploreGenerateInvoked() {
    if (!ref.read(imageGenerationNotifierProvider).isGenerating) return;
    final params = ref.read(generationParamsNotifierProvider);
    final int expectedCount =
        params.nSamples * ref.read(imagesPerRequestProvider);
    unawaited(
      ref
          .read(exploreManualCaptureProvider.notifier)
          .arm(
            autoRunName: context.l10n.styleExplore_manualRunName(
              _autoRunTimestamp(),
            ),
            expectedCount: expectedCount,
          ),
    );
  }

  static String _autoRunTimestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
  }

  // ==================== 右栏：候选画廊（阶段 A 空态占位） ====================

  Widget _buildGalleryPanel(ThemeData theme) {
    final width = ref.watch(
      layoutStateNotifierProvider.select((s) => s.styleExploreGalleryWidth),
    );
    final decoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      border: Border(left: BorderSide(color: theme.dividerColor)),
    );
    final content = _buildGalleryContent(theme);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResizeHandle(
          onDragStart: () => setState(() => _isResizingGallery = true),
          onDragEnd: () => setState(() => _isResizingGallery = false),
          onDrag: (dx) {
            // 读取最新的宽度值，避免闭包捕获旧值导致不跟手
            final currentWidth = ref
                .read(layoutStateNotifierProvider)
                .styleExploreGalleryWidth;
            final newWidth = (currentWidth - dx).clamp(
              _galleryMinWidth,
              _galleryMaxWidth,
            );
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setStyleExploreGalleryWidth(newWidth.toDouble());
          },
        ),
        if (_isResizingGallery)
          Container(width: width, decoration: decoration, child: content)
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            decoration: decoration,
            child: content,
          ),
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
