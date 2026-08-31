import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/style_explore/style_explore_recipe.dart';
import '../../providers/generation/generation_params_notifier.dart';
import '../../providers/generation/generation_settings_notifiers.dart';
import '../../providers/prompt_block_workspace_provider.dart';
import '../../providers/style_explore_provider.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/themed_confirm_dialog.dart';
import '../../widgets/common/themed_input_dialog.dart';
import '../../widgets/autocomplete/autocomplete_config.dart';
import '../../widgets/prompt/blocks/prompt_block_editor.dart';
import '../../widgets/prompt/unified/unified_prompt_config.dart';
import 'widgets/style_explore_prompt_preview_dialog.dart';
import 'widgets/style_explore_recipe_list_panel.dart';

/// 画风探索页。
///
/// 工作区直接复用公共块文档与块编辑器组件（挂到探索专用工作区实例），
/// Recipe 保存/载入的是完整文档快照；本页不接生成参数链与请求链。
class StyleExploreScreen extends ConsumerStatefulWidget {
  const StyleExploreScreen({super.key});

  @override
  ConsumerState<StyleExploreScreen> createState() => _StyleExploreScreenState();
}

class _StyleExploreScreenState extends ConsumerState<StyleExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(styleExploreRecipeListNotifierProvider);
    final session = ref.watch(styleExploreSessionNotifierProvider);
    final isDirty = ref.watch(styleExploreDirtyProvider);
    final activeRecipe = ref.watch(styleExploreActiveRecipeProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 760;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSidebar)
                SizedBox(
                  width: 260,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Material 承载背景色：ListTile 选中态与水波纹画在最近的
                    // Material 上，直接用 DecoratedBox 背景会将其遮挡。
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: listAsync.maybeWhen(
                        data: (list) => StyleExploreRecipeListPanel(
                          recipes: list.recipes,
                          activeRecipeId: session.activeRecipeId,
                          isDirty: isDirty,
                          onLoadRecipe: _loadRecipe,
                          onStartNew: _startNew,
                          onRenameRecipe: _renameRecipe,
                          onDuplicateRecipe: _duplicateRecipe,
                          onDeleteRecipe: _deleteRecipe,
                        ),
                        orElse: () =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context, theme, activeRecipe, isDirty),
                    if (!showSidebar) _buildCompactRecipeSelector(theme),
                    Expanded(child: _buildEditorArea(context, theme)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    StyleExploreRecipe? activeRecipe,
    bool isDirty,
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
        ],
      ),
    );
  }

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

  Widget _buildEditorArea(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    final enableAutocomplete = ref.watch(autocompleteSettingsProvider);
    final enableAutoFormat = ref.watch(autoFormatPromptSettingsProvider);
    final enableHighlight = ref.watch(highlightEmphasisSettingsProvider);
    final enableSdSyntaxAutoConvert = ref.watch(
      sdSyntaxAutoConvertSettingsProvider,
    );
    final numericEmphasisEnabled = ImageModels.isV4Model(
      ref.watch(generationParamsNotifierProvider.select((p) => p.model)),
    );
    final config = UnifiedPromptConfig(
      enableSyntaxHighlight: enableHighlight,
      numericEmphasisEnabled: numericEmphasisEnabled,
      enableAutocomplete: enableAutocomplete,
      enableAutoFormat: enableAutoFormat,
      enableSdSyntaxAutoConvert: enableSdSyntaxAutoConvert,
      enableComfyuiImport: false,
      autocompleteConfig: const AutocompleteConfig(
        showTranslation: true,
        autoInsertComma: true,
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildLaneLabel(theme, l10n.styleExplore_positive),
        const SizedBox(height: 6),
        PromptBlockEditor(
          key: const Key('style-explore-positive-editor'),
          lane: PromptBlockLane.positive,
          workspaceProvider: styleExploreWorkspaceNotifierProvider,
          config: config.copyWith(hintText: l10n.styleExplore_positiveHint),
          minLines: 3,
          autoGrow: true,
          sessionId: 'style_explore_positive',
        ),
        const SizedBox(height: 16),
        _buildLaneLabel(theme, l10n.styleExplore_negative),
        const SizedBox(height: 6),
        PromptBlockEditor(
          key: const Key('style-explore-negative-editor'),
          lane: PromptBlockLane.negative,
          workspaceProvider: styleExploreWorkspaceNotifierProvider,
          config: config.copyWith(hintText: l10n.prompt_unwantedContent),
          minLines: 2,
          autoGrow: true,
          sessionId: 'style_explore_negative',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLaneLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!ref.read(styleExploreDirtyProvider)) return true;
    final l10n = context.l10n;
    return ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_discardChangesTitle,
      content: l10n.styleExplore_discardChangesMessage,
      confirmText: l10n.styleExplore_discardChangesConfirm,
      cancelText: MaterialLocalizations.of(context).cancelButtonLabel,
    );
  }

  Future<void> _loadRecipe(StyleExploreRecipe recipe) async {
    if (!await _confirmDiscardChanges()) return;
    final ok = await ref
        .read(styleExploreSessionNotifierProvider.notifier)
        .loadRecipe(recipe.id);
    if (!mounted) return;
    if (ok) {
      AppToast.success(
        context,
        context.l10n.styleExplore_recipeLoaded(recipe.displayName),
      );
    }
  }

  Future<void> _startNew() async {
    if (!await _confirmDiscardChanges()) return;
    ref.read(styleExploreSessionNotifierProvider.notifier).startNew();
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
    final composer = ref.read(promptBlockComposerProvider);
    final workspace = ref.read(styleExploreWorkspaceNotifierProvider);
    StyleExplorePromptPreviewDialog.show(
      context,
      positiveText: composer.composePlainText(workspace.positiveDocument),
      negativeText: composer.composePlainText(workspace.negativeDocument),
    );
  }
}
