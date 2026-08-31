import 'package:flutter/material.dart';

import '../../../../data/models/style_explore/style_explore_recipe.dart';
import '../../../../core/utils/localization_extension.dart';

/// 画风探索左侧 Recipe 列表面板。
///
/// 纯受控组件：只展示与回调，持久化和会话协调由父级处理。
class StyleExploreRecipeListPanel extends StatelessWidget {
  const StyleExploreRecipeListPanel({
    super.key,
    required this.recipes,
    required this.activeRecipeId,
    required this.isDirty,
    required this.onLoadRecipe,
    required this.onStartNew,
    required this.onRenameRecipe,
    required this.onDuplicateRecipe,
    required this.onDeleteRecipe,
  });

  final List<StyleExploreRecipe> recipes;
  final String? activeRecipeId;
  final bool isDirty;
  final ValueChanged<StyleExploreRecipe> onLoadRecipe;
  final VoidCallback onStartNew;
  final ValueChanged<StyleExploreRecipe> onRenameRecipe;
  final ValueChanged<StyleExploreRecipe> onDuplicateRecipe;
  final ValueChanged<StyleExploreRecipe> onDeleteRecipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                key: const Key('style-explore-new-recipe'),
                tooltip: l10n.styleExplore_newRecipe,
                onPressed: onStartNew,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: recipes.isEmpty
              ? Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return _buildRecipeTile(context, theme, recipe);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecipeTile(
    BuildContext context,
    ThemeData theme,
    StyleExploreRecipe recipe,
  ) {
    final isActive = recipe.id == activeRecipeId;
    final l10n = context.l10n;
    return ListTile(
      key: ValueKey('style-explore-recipe-${recipe.id}'),
      selected: isActive,
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              recipe.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive && isDirty)
            Tooltip(
              message: l10n.styleExplore_unsavedChanges,
              child: Icon(
                Icons.circle,
                size: 8,
                color: theme.colorScheme.tertiary,
              ),
            ),
        ],
      ),
      subtitle: Text(
        _formatShortDateTime(recipe.updatedAt),
        style: theme.textTheme.bodySmall,
      ),
      onTap: () => onLoadRecipe(recipe),
      trailing: PopupMenuButton<String>(
        tooltip: recipe.displayName,
        onSelected: (value) {
          switch (value) {
            case 'load':
              onLoadRecipe(recipe);
            case 'rename':
              onRenameRecipe(recipe);
            case 'duplicate':
              onDuplicateRecipe(recipe);
            case 'delete':
              onDeleteRecipe(recipe);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'load', child: Text(l10n.styleExplore_load)),
          PopupMenuItem(value: 'rename', child: Text(l10n.styleExplore_rename)),
          PopupMenuItem(
            value: 'duplicate',
            child: Text(l10n.styleExplore_duplicate),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(l10n.styleExplore_deleteRecipe),
          ),
        ],
      ),
    );
  }
}

String _formatShortDateTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
