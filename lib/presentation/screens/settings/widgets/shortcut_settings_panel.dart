import 'settings_ui_theme.dart';
import 'settings_tile.dart';
import 'settings_hover_line.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shortcuts/default_shortcuts.dart';
import '../../../../core/shortcuts/shortcut_config.dart';
import '../../../../core/shortcuts/shortcut_manager.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/shortcuts_provider.dart';
import '../../../widgets/shortcuts/shortcut_binding_editor.dart';
import '../../../widgets/shortcuts/shortcut_help_dialog.dart';

/// 快捷键设置面板
/// 用于自定义和管理快捷键
class ShortcutSettingsPanel extends ConsumerStatefulWidget {
  const ShortcutSettingsPanel({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Theme(
        data: _shortcutPanelTheme(Theme.of(context)),
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 900,
            height: (MediaQuery.sizeOf(context).height - 96).clamp(200, 720),
            child: const ShortcutSettingsPanel(),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<ShortcutSettingsPanel> createState() =>
      _ShortcutSettingsPanelState();
}

class _ShortcutSettingsPanelState extends ConsumerState<ShortcutSettingsPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ShortcutContext _selectedContext = ShortcutContext.global;
  final _listScroll = ScrollController();
  String? _editingId;

  @override
  void dispose() {
    _searchController.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(shortcutConfigNotifierProvider);
    final bindingsByContext = ref.watch(shortcutsByContextProvider);

    return configAsync.when(
      data: (config) =>
          _buildContent(context, theme, config, bindingsByContext),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(context.l10n.settings_loadFailed(error.toString())),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ShortcutConfig config,
    Map<ShortcutContext, List<ShortcutBinding>> bindingsByContext,
  ) {
    final header = Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.keyboard_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.shortcut_settings_title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              // 帮助按钮
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: context.l10n.shortcut_settings_help,
                onPressed: () => ShortcutHelpDialog.show(context),
              ),
              // 关闭按钮
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 搜索框和全局设置
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n.shortcut_settings_search,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                    _editingId = null;
                  });
                  if (_listScroll.hasClients) _listScroll.jumpTo(0);
                },
              );
              final toggle = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.shortcut_settings_enable,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  SettingsToggle(
                    value: config.enableShortcuts,
                    onChanged: (value) {
                      ref
                          .read(shortcutConfigNotifierProvider.notifier)
                          .updateSettings(enableShortcuts: value);
                    },
                  ),
                ],
              );
              return constraints.maxWidth <
                      480 * MediaQuery.textScalerOf(context).scale(1)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerRight, child: toggle),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: 16),
                        toggle,
                      ],
                    );
            },
          ),
          const SizedBox(height: 8),
          // 其他设置
          LayoutBuilder(
            builder: (context, constraints) {
              final options = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 显示在Tooltip中
                  _displayPreference(
                    'tooltips',
                    context.l10n.shortcut_settings_show_in_tooltips,
                    config.showShortcutInTooltip,
                    config.enableShortcuts
                        ? (value) {
                            ref
                                .read(shortcutConfigNotifierProvider.notifier)
                                .updateSettings(showShortcutInTooltip: value);
                          }
                        : null,
                  ),
                  // 显示徽章
                  _displayPreference(
                    'badges',
                    context.l10n.shortcut_settings_show_badges,
                    config.showShortcutBadges,
                    config.enableShortcuts
                        ? (value) {
                            ref
                                .read(shortcutConfigNotifierProvider.notifier)
                                .updateSettings(showShortcutBadges: value);
                          }
                        : null,
                  ),
                  // 在菜单中显示
                  _displayPreference(
                    'menus',
                    context.l10n.shortcut_settings_show_in_menus,
                    config.showInMenus,
                    config.enableShortcuts
                        ? (value) {
                            ref
                                .read(shortcutConfigNotifierProvider.notifier)
                                .updateSettings(showInMenus: value);
                          }
                        : null,
                  ),
                ],
              );
              final reset = TextButton.icon(
                onPressed: _showResetConfirmDialog,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(context.l10n.shortcut_settings_reset_all),
              );
              if (constraints.maxWidth <
                  650 * MediaQuery.textScalerOf(context).scale(1)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    options,
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerRight, child: reset),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: options),
                  const SizedBox(width: 12),
                  reset,
                ],
              );
            },
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * .6),
            child: SingleChildScrollView(child: header),
          ),
          Expanded(child: _buildWorkspace(config, bindingsByContext)),
        ],
      ),
    );
  }

  Widget _displayPreference(
    String id,
    String label,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return InkWell(
      key: ValueKey('shortcut-display-$id'),
      borderRadius: BorderRadius.circular(4),
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (next) => onChanged(next ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _selectContext(ShortcutContext value) {
    setState(() {
      _selectedContext = value;
      _editingId = null;
      _searchQuery = '';
      _searchController.clear();
    });
    if (_listScroll.hasClients) _listScroll.jumpTo(0);
  }

  List<ShortcutBinding> _searchBindings(ShortcutConfig config) => config
      .bindings
      .values
      .where(
        (binding) =>
            '${_getActionDisplayName(binding)} ${binding.id} ${AppShortcutManager.getDisplayLabel(binding.effectiveShortcut)}'
                .toLowerCase()
                .contains(_searchQuery),
      )
      .toList();

  Widget _buildWorkspace(
    ShortcutConfig config,
    Map<ShortcutContext, List<ShortcutBinding>> groups,
  ) {
    final colors = Theme.of(context).colorScheme;
    final categories = ShortcutContext.values
        .where((value) => (groups[value] ?? []).isNotEmpty)
        .toList();
    final selected = categories.contains(_selectedContext)
        ? _selectedContext
        : categories.firstOrNull;
    final searching = _searchQuery.isNotEmpty;
    final bindings = searching
        ? _searchBindings(config)
        : groups[selected] ?? <ShortcutBinding>[];
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  searching
                      ? context.l10n.settings_searchResults
                      : selected == null
                      ? context.l10n.shortcut_settings_no_matches
                      : _getContextDisplayName(selected),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${bindings.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: bindings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(context.l10n.shortcut_settings_no_matches),
                  ),
                )
              : Scrollbar(
                  controller: _listScroll,
                  thumbVisibility: true,
                  child: ListView.builder(
                    key: const Key('shortcut-binding-list'),
                    controller: _listScroll,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    itemCount: bindings.length,
                    itemBuilder: (context, index) => _buildShortcutTile(
                      bindings[index],
                      showContext: searching,
                    ),
                  ),
                ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 620 * scale) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                child: DropdownButton<ShortcutContext>(
                  key: const Key('shortcut-category-compact'),
                  value: selected,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category,
                        child: Text(_getContextDisplayName(category)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _selectContext(value);
                  },
                ),
              ),
              Expanded(child: list),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const Key('shortcut-category-sidebar'),
              width: 166 * scale,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SettingsHoverLine(
                        child: Material(
                          color: !searching && category == selected
                              ? colors.primary.withValues(alpha: .07)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          child: InkWell(
                            key: ValueKey('shortcut-category-${category.name}'),
                            borderRadius: BorderRadius.circular(3),
                            onTap: () => _selectContext(category),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Text(
                                _getContextDisplayName(category),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: !searching && category == selected
                                          ? colors.primary
                                          : colors.onSurface,
                                      fontWeight:
                                          !searching && category == selected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              color: colors.outlineVariant.withValues(alpha: .5),
            ),
            Expanded(child: list),
          ],
        );
      },
    );
  }

  Widget _buildShortcutTile(
    ShortcutBinding binding, {
    bool showContext = false,
  }) {
    final theme = Theme.of(context);
    final isEditing = _editingId == binding.id;
    final shortcut = binding.effectiveShortcut;

    if (isEditing) {
      return Container(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        child: ShortcutBindingEditor(
          binding: binding,
          inline: false,
          onSave: (newBinding) async {
            await ref
                .read(shortcutConfigNotifierProvider.notifier)
                .updateBinding(newBinding);
            if (mounted) setState(() => _editingId = null);
          },
          onCancel: () {
            setState(() {
              _editingId = null;
            });
          },
        ),
      );
    }

    return SettingsTile(
      key: ValueKey('shortcut-binding-${binding.id}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      controlWrapWidth: 370 * MediaQuery.textScalerOf(context).scale(1),
      title: Text(
        _getActionDisplayName(binding),
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: binding.hasCustomShortcut
          ? Text(
              context.l10n.shortcut_settings_defaultShortcut(
                AppShortcutManager.getDisplayLabel(binding.defaultShortcut),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : showContext
          ? Text(_getContextDisplayName(binding.context))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 快捷键标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: binding.hasCustomShortcut
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: binding.hasCustomShortcut
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              shortcut != null
                  ? AppShortcutManager.getDisplayLabel(shortcut)
                  : context.l10n.shortcut_settings_unassigned,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: StudioTypography.mono,
                fontFamilyFallback: StudioTypography.fallback,
                fontWeight: FontWeight.w600,
                color: binding.hasCustomShortcut
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            tooltip: context.l10n.common_edit,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _editingId = binding.id;
              });
            },
          ),
          // 重置按钮（仅当有自定义快捷键时显示）
          if (binding.hasCustomShortcut)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: context.l10n.shortcut_settings_reset_to_default,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await ref
                    .read(shortcutConfigNotifierProvider.notifier)
                    .resetToDefault(binding.id);
              },
            ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.shortcut_settings_reset_all_title),
        content: Text(context.l10n.shortcut_settings_reset_all_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(shortcutConfigNotifierProvider.notifier)
                  .resetAllToDefault();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.common_reset),
          ),
        ],
      ),
    );
  }

  String _getActionDisplayName(ShortcutBinding binding) {
    final l10n = context.l10n;
    final key = binding.actionKey;

    switch (key) {
      case 'shortcut_action_navigate_to_generation':
        return l10n.shortcut_action_navigate_to_generation;
      case 'shortcut_action_navigate_to_local_gallery':
        return l10n.shortcut_action_navigate_to_local_gallery;
      case 'shortcut_action_navigate_to_online_gallery':
        return l10n.shortcut_action_navigate_to_online_gallery;
      case 'shortcut_action_navigate_to_tag_library':
        return l10n.shortcut_action_navigate_to_tag_library;
      case 'shortcut_action_navigate_to_statistics':
        return l10n.shortcut_action_navigate_to_statistics;
      case 'shortcut_action_navigate_to_settings':
        return l10n.shortcut_action_navigate_to_settings;
      case 'shortcut_action_navigate_to_vibe_library':
        return l10n.vibeLibrary_title;
      case 'shortcut_action_navigate_to_style_explore':
        return l10n.nav_styleExplore;
      case 'shortcut_action_navigate_to_precise_ref_library':
        return l10n.nav_preciseRefLibrary;
      case 'shortcut_action_navigate_to_tag_wiki':
        return l10n.nav_tagWiki;
      case 'shortcut_action_vibe_import':
        return l10n.common_import;
      case 'shortcut_action_vibe_export':
      case 'shortcut_action_vibe_detail_export':
        return l10n.common_export;
      case 'shortcut_action_vibe_detail_rename':
        return l10n.shortcut_action_vibe_detail_rename;
      case 'shortcut_action_vibe_detail_delete':
        return l10n.common_delete;
      case 'shortcut_action_vibe_detail_toggle_favorite':
        return l10n.shortcut_action_toggle_favorite;
      case 'shortcut_action_vibe_detail_send_to_generation':
        return l10n.vibeLibrary_sendToGeneration;
      case 'shortcut_action_vibe_detail_prev_sub_vibe':
        return l10n.shortcut_action_vibe_detail_prev_sub_vibe;
      case 'shortcut_action_vibe_detail_next_sub_vibe':
        return l10n.shortcut_action_vibe_detail_next_sub_vibe;
      case 'shortcut_action_generate_image':
        return l10n.shortcut_action_generate_image;
      case 'shortcut_action_generation_prev_image':
        return l10n.shortcut_action_generation_prev_image;
      case 'shortcut_action_generation_next_image':
        return l10n.shortcut_action_generation_next_image;
      case 'shortcut_action_cancel_generation':
        return l10n.shortcut_action_cancel_generation;
      case 'shortcut_action_clear_prompt':
        return l10n.shortcut_action_clear_prompt;
      case 'shortcut_action_toggle_prompt_mode':
        return l10n.shortcut_action_toggle_prompt_mode;
      case 'shortcut_action_open_tag_library':
        return l10n.shortcut_action_open_tag_library;
      case 'shortcut_action_save_image':
        return l10n.shortcut_action_save_image;
      case 'shortcut_action_upscale_image':
        return l10n.shortcut_action_upscale_image;
      case 'shortcut_action_copy_image':
        return l10n.shortcut_action_copy_image;
      case 'shortcut_action_fullscreen_preview':
        return l10n.shortcut_action_fullscreen_preview;
      case 'shortcut_action_open_params_panel':
        return l10n.shortcut_action_open_params_panel;
      case 'shortcut_action_open_history_panel':
        return l10n.shortcut_action_open_history_panel;
      case 'shortcut_action_reuse_params':
        return l10n.shortcut_action_reuse_params;
      case 'shortcut_action_previous_image':
        return l10n.shortcut_action_previous_image;
      case 'shortcut_action_next_image':
        return l10n.shortcut_action_next_image;
      case 'shortcut_action_zoom_in':
        return l10n.shortcut_action_zoom_in;
      case 'shortcut_action_zoom_out':
        return l10n.shortcut_action_zoom_out;
      case 'shortcut_action_reset_zoom':
        return l10n.shortcut_action_reset_zoom;
      case 'shortcut_action_toggle_fullscreen':
        return l10n.shortcut_action_toggle_fullscreen;
      case 'shortcut_action_close_viewer':
        return l10n.shortcut_action_close_viewer;
      case 'shortcut_action_toggle_favorite':
        return l10n.shortcut_action_toggle_favorite;
      case 'shortcut_action_copy_prompt':
        return l10n.shortcut_action_copy_prompt;
      case 'shortcut_action_reuse_gallery_params':
        return l10n.shortcut_action_reuse_gallery_params;
      case 'shortcut_action_delete_image':
        return l10n.shortcut_action_delete_image;
      case 'shortcut_action_previous_page':
        return l10n.shortcut_action_previous_page;
      case 'shortcut_action_next_page':
        return l10n.shortcut_action_next_page;
      case 'shortcut_action_refresh_gallery':
        return l10n.shortcut_action_refresh_gallery;
      case 'shortcut_action_focus_search':
        return l10n.shortcut_action_focus_search;
      case 'shortcut_action_enter_selection_mode':
        return l10n.shortcut_action_enter_selection_mode;
      case 'shortcut_action_clear_filter':
        return l10n.shortcut_action_clear_filter;
      case 'shortcut_action_toggle_category_panel':
        return l10n.shortcut_action_toggle_category_panel;
      case 'shortcut_action_jump_to_date':
        return l10n.shortcut_action_jump_to_date;
      case 'shortcut_action_open_folder':
        return l10n.shortcut_action_open_folder;
      case 'shortcut_action_show_shortcut_help':
        return l10n.shortcut_action_show_shortcut_help;
      case 'shortcut_action_minimize_to_tray':
        return l10n.shortcut_action_minimize_to_tray;
      case 'shortcut_action_quit_app':
        return l10n.shortcut_action_quit_app;
      case 'shortcut_action_toggle_theme':
        return l10n.shortcut_action_toggle_theme;
      default:
        return key.replaceAll('shortcut_action_', '');
    }
  }

  String _getContextDisplayName(ShortcutContext shortcutContext) {
    final l10n = context.l10n;

    switch (shortcutContext) {
      case ShortcutContext.global:
        return l10n.shortcut_context_global;
      case ShortcutContext.generation:
        return l10n.shortcut_context_generation;
      case ShortcutContext.gallery:
        return l10n.shortcut_context_gallery;
      case ShortcutContext.viewer:
        return l10n.shortcut_context_viewer;
      case ShortcutContext.settings:
        return l10n.shortcut_context_settings;
      case ShortcutContext.input:
        return l10n.shortcut_context_input;
      case ShortcutContext.vibeDetail:
        return l10n.shortcut_context_vibe_detail;
    }
  }
}

ThemeData _shortcutPanelTheme(ThemeData base) {
  final theme = settingsUiTheme(base);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
  );
  return theme.copyWith(
    dialogTheme: theme.dialogTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: theme.textButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(shape),
      ),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
      ),
    ),
  );
}
