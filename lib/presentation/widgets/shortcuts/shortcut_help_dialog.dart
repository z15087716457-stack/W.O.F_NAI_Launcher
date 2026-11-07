import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../../core/shortcuts/shortcut_config.dart';
import '../../../core/shortcuts/shortcut_manager.dart';
import '../../../presentation/router/app_router.dart';
import '../../../presentation/screens/settings/widgets/shortcut_settings_panel.dart';
import '../../providers/shortcuts_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../utils/shortcut_guide.dart';

/// 快捷键帮助对话框
/// 显示所有可用的快捷键
class ShortcutHelpDialog extends ConsumerStatefulWidget {
  const ShortcutHelpDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const ShortcutHelpDialog(),
    );
  }

  @override
  ConsumerState<ShortcutHelpDialog> createState() => _ShortcutHelpDialogState();
}

class _ShortcutHelpDialogState extends ConsumerState<ShortcutHelpDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedContext;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = shortcutGuide(
      context.l10n,
      ref.watch(shortcutConfigNotifierProvider).valueOrNull ??
          const ShortcutConfig(),
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 720,
        height: 600,
        child: Column(
          children: [
            _buildHeader(),
            _buildContextFilters(data.contexts),
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: _buildShortcutsList(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inlineSearch = constraints.maxWidth >= 560;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.keyboard_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.shortcut_help_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (inlineSearch) ...[
                    const SizedBox(width: 16),
                    SizedBox(width: 200, child: _buildSearchField()),
                    const SizedBox(width: 10),
                  ],
                  IconButton(
                    key: const Key('shortcut-help-customize'),
                    tooltip: context.l10n.shortcuts_customize,
                    onPressed: _openCustomization,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: const EdgeInsets.all(6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(StudioIcons.settings, size: 18),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: const Key('shortcut-help-close'),
                    tooltip: context.l10n.common_close,
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      padding: const EdgeInsets.all(6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              if (!inlineSearch) ...[
                const SizedBox(height: 14),
                _buildSearchField(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() => TextField(
    key: const Key('shortcut-help-search'),
    controller: _searchController,
    style: Theme.of(context).textTheme.bodySmall,
    decoration: InputDecoration(
      hintText: context.l10n.shortcut_help_search,
      prefixIcon: const Icon(Icons.search, size: 18),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      suffixIcon: _searchQuery.isEmpty
          ? null
          : IconButton(
              key: const Key('shortcut-help-clear-search'),
              tooltip: context.l10n.common_clear,
              icon: const Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: const EdgeInsets.all(6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
            ),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    onChanged: (value) =>
        setState(() => _searchQuery = value.trim().toLowerCase()),
  );

  Widget _buildContextFilters(List<SettingsShortcutContext> contexts) {
    final theme = Theme.of(context);
    Widget filter(String? value, String label) {
      final selected = _selectedContext == value;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ChoiceChip(
          key: Key('shortcut-context-${value ?? 'all'}'),
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          backgroundColor: Colors.transparent,
          selectedColor: theme.colorScheme.primary.withValues(alpha: .08),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          labelPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          onSelected: (_) => setState(() => _selectedContext = value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              filter(null, context.l10n.shortcut_help_all),
              for (final value in contexts) filter(value.id, value.label),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomization() {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    router.go(AppRoutes.settings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) ShortcutSettingsPanel.show(navigator.context);
    });
  }

  Widget _buildShortcutsList(SettingsShortcutsData data) {
    final groups = {
      for (final value in data.contexts)
        if (_selectedContext == null || value.id == _selectedContext)
          value:
              data.shortcuts
                  .where(
                    (row) => row.context == value.id && row.keys.isNotEmpty,
                  )
                  .toList()
                ..sort((a, b) => a.id.compareTo(b.id)),
    };
    if (_searchQuery.isNotEmpty) {
      final results = [
        for (final group in groups.entries)
          for (final row in group.value)
            if ('${row.label} ${group.key.label} ${row.id} ${row.keys.join('+')} ${_keyLabel(row)}'
                .toLowerCase()
                .contains(_searchQuery))
              row,
      ];
      return _buildSearchResults(results);
    }
    final visible = groups.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    return ListView.builder(
      key: const Key('shortcut-help-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: visible.length,
      itemBuilder: (context, index) =>
          _buildContextSection(visible[index].key.label, visible[index].value),
    );
  }

  Widget _buildContextSection(
    String contextLabel,
    List<SettingsShortcut> bindings,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              Text(
                contextLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${bindings.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final binding in bindings) _buildShortcutItem(binding),
        const SizedBox(height: 14),
      ],
    );
  }

  String _keyLabel(SettingsShortcut row) =>
      AppShortcutManager.getDisplayLabel(row.keys.join('+'));

  Widget _buildShortcutItem(SettingsShortcut row) {
    final theme = Theme.of(context);
    final label = _keyLabel(row);
    return Padding(
      key: Key('shortcut-help-item-${row.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  if (row.fixed)
                    Text(
                      context.l10n.set_scFixed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * .46),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: .6,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: StudioTypography.mono,
                    fontFamilyFallback: StudioTypography.fallback,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<SettingsShortcut> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.shortcut_settings_no_matches,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      key: const Key('shortcut-help-list'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildShortcutItem(results[index]),
    );
  }
}

/// 快捷键帮助悬浮按钮
/// 可以放置在页面角落快速打开帮助
class ShortcutHelpFab extends ConsumerWidget {
  const ShortcutHelpFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'shortcut_help',
      onPressed: () => ShortcutHelpDialog.show(context),
      tooltip: context.l10n.shortcut_help_fabTooltip,
      child: const Icon(Icons.keyboard),
    );
  }
}
