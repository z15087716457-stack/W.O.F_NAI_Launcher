import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../providers/uc_preset_provider.dart';
import '../common/prompt_block_picker_dialog.dart';
import 'components/library_entry_menu_item.dart';

/// UC 预设选择器组件
///
/// 支持 NAI 预设类型和从词库添加自定义条目
class UcPresetSelector extends ConsumerStatefulWidget {
  /// 当前选择的模型
  final String model;

  const UcPresetSelector({super.key, required this.model});

  @override
  ConsumerState<UcPresetSelector> createState() => _UcPresetSelectorState();
}

class _UcPresetSelectorState extends ConsumerState<UcPresetSelector> {
  bool _isHovering = false;
  final _buttonKey = GlobalKey();

  String _getPresetDisplayName(BuildContext context, UcPresetType type) {
    switch (type) {
      case UcPresetType.heavy:
        return context.l10n.ucPreset_heavy;
      case UcPresetType.light:
        return context.l10n.ucPreset_light;
      case UcPresetType.furryFocus:
        return context.l10n.ucPreset_furryFocus;
      case UcPresetType.humanFocus:
        return context.l10n.ucPreset_humanFocus;
      case UcPresetType.none:
        return context.l10n.ucPreset_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presetState = ref.watch(ucPresetNotifierProvider);
    final customEntries = ref.watch(ucCustomEntriesProvider);
    final currentEntry = ref.watch(currentUcEntryProvider);

    // 获取实际内容用于 Tooltip 显示
    final effectiveContent = ref
        .read(ucPresetNotifierProvider.notifier)
        .getEffectiveContent(widget.model);
    final isEnabled = !presetState.isDisabled;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        richMessage: WidgetSpan(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildTooltipWidget(
              theme,
              effectiveContent,
              isEnabled,
              presetState.isCustom,
              currentEntry,
            ),
          ),
        ),
        preferBelow: true,
        verticalOffset: 20,
        waitDuration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => _showMenu(context, presetState, customEntries),
          child: AnimatedContainer(
            key: _buttonKey,
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovering
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.25,
                    ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 官网式中性片：「Undesired Content Preset: <名> ▾」，
                // 无预设时 0.55 淡显
                Flexible(
                  child: Text(
                    '${context.l10n.ucPreset_presetChip}: '
                    '${_getDisplayLabel(context, presetState, currentEntry)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isEnabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                StudioIcon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: isEnabled ? 0.7 : 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    UcPresetState presetState,
    List<PromptBlock> customEntries,
  ) async {
    final RenderBox button =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;

    // 菜单位置：按钮正下方，左边缘对齐
    final position = RelativeRect.fromLTRB(
      buttonPosition.dx,
      buttonPosition.dy + buttonSize.height,
      overlay.size.width - buttonPosition.dx - buttonSize.width,
      0,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _buildMenuItems(context, presetState, customEntries),
    );

    if (result != null) {
      _onMenuItemSelected(result);
    }
  }

  String _getDisplayLabel(
    BuildContext context,
    UcPresetState state,
    PromptBlock? customEntry,
  ) {
    if (state.isCustom && customEntry != null) {
      final name = customEntry.displayTitle;
      return name.length > 8 ? '${name.substring(0, 8)}...' : name;
    }
    return _getPresetDisplayName(context, state.presetType);
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    UcPresetState state,
    List<PromptBlock> customEntries,
  ) {
    final theme = Theme.of(context);
    final items = <PopupMenuEntry<String>>[];

    // NAI 预设选项
    for (final type in UcPresetType.values) {
      final isSelected = !state.isCustom && state.presetType == type;
      items.add(
        PopupMenuItem<String>(
          value: 'preset_${type.index}',
          child: Row(
            children: [
              if (isSelected)
                StudioIcon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(
                _getPresetDisplayName(context, type),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 分隔线
    items.add(const PopupMenuDivider());

    // 从词库添加
    items.add(
      PopupMenuItem<String>(
        value: 'add_from_library',
        child: Row(
          children: [
            StudioIcon(Icons.add, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              context.l10n.ucPreset_addFromLibrary,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );

    // 所有已添加的自定义条目
    if (customEntries.isNotEmpty) {
      items.add(const PopupMenuDivider());
      for (final entry in customEntries) {
        final isSelected = state.isCustom && state.customEntryId == entry.id;
        items.add(
          LibraryEntryMenuItem(
            entry: entry,
            isSelected: isSelected,
            onDelete: () {
              ref
                  .read(ucPresetNotifierProvider.notifier)
                  .removeCustomEntry(entry.id);
              Navigator.of(context).pop();
            },
          ),
        );
      }
    }

    return items;
  }

  void _onMenuItemSelected(String value) {
    if (value.startsWith('preset_')) {
      final index = int.tryParse(value.substring(7));
      if (index != null && index < UcPresetType.values.length) {
        ref
            .read(ucPresetNotifierProvider.notifier)
            .setPresetType(UcPresetType.values[index]);
      }
    } else if (value == 'add_from_library') {
      _showPromptBlockPicker();
    } else if (value.startsWith('custom_')) {
      final entryId = value.substring(7);
      ref.read(ucPresetNotifierProvider.notifier).setCustomEntry(entryId);
    }
  }

  Future<void> _showPromptBlockPicker() async {
    final entry = await showDialog<PromptBlock>(
      context: context,
      builder: (context) => PromptBlockPickerDialog(
        title: context.l10n.ucPreset_selectFromLibrary,
      ),
    );
    if (entry != null) {
      ref.read(ucPresetNotifierProvider.notifier).setCustomEntry(entry.id);
    }
  }

  Widget _buildTooltipWidget(
    ThemeData theme,
    String? presetContent,
    bool isEnabled,
    bool isCustom,
    PromptBlock? customEntry,
  ) {
    if (!isEnabled && !isCustom) {
      return Text(
        context.l10n.ucPreset_disabled,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
      );
    }

    final content = presetContent ?? '';

    // 检查预设内容是否包含 nsfw
    final hasNsfw = content.toLowerCase().contains('nsfw');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.ucPreset_addToNegative,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(color: theme.colorScheme.secondary, fontSize: 11),
        ),
        // 如果包含 nsfw，显示提示信息
        if (hasNsfw && !isCustom) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              context.l10n.ucPreset_nsfwHint,
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}
