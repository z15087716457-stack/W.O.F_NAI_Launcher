import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';

/// 块自定义图标的预设表：键稳定入库存储（`PromptBlock.iconName`），
/// 值为 Material 图标。新增图标只增不改键名，保证旧数据不失效。
const Map<String, IconData> kPromptBlockIconOptions = {
  'palette': Icons.palette_outlined,
  'brush': Icons.brush_outlined,
  'draw': Icons.draw_outlined,
  'color_lens': Icons.color_lens_outlined,
  'image': Icons.image_outlined,
  'photo': Icons.photo_camera_outlined,
  'filter': Icons.filter_vintage_outlined,
  'person': Icons.person_outline,
  'face': Icons.face_outlined,
  'groups': Icons.groups_outlined,
  'heart': Icons.favorite_outline,
  'star': Icons.star_outline,
  'bolt': Icons.bolt_outlined,
  'fire': Icons.local_fire_department_outlined,
  'sparkle': Icons.auto_awesome_outlined,
  'moon': Icons.nightlight_outlined,
  'sun': Icons.wb_sunny_outlined,
  'cloud': Icons.cloud_outlined,
  'snow': Icons.ac_unit_outlined,
  'landscape': Icons.landscape_outlined,
  'city': Icons.location_city_outlined,
  'home': Icons.home_outlined,
  'park': Icons.park_outlined,
  'beach': Icons.beach_access_outlined,
  'forest': Icons.forest_outlined,
  'dress': Icons.checkroom_outlined,
  'diamond': Icons.diamond_outlined,
  'cake': Icons.cake_outlined,
  'food': Icons.restaurant_outlined,
  'game': Icons.sports_esports_outlined,
  'music': Icons.music_note_outlined,
  'pets': Icons.pets_outlined,
  'book': Icons.menu_book_outlined,
  'science': Icons.science_outlined,
  'school': Icons.school_outlined,
  'car': Icons.directions_car_outlined,
  'flight': Icons.flight_outlined,
  'shield': Icons.shield_outlined,
  'build': Icons.build_outlined,
  'tag': Icons.label_outline,
};

/// 块未选图标时的默认图标。
const IconData kPromptBlockDefaultIcon = Icons.view_module_outlined;

/// 按键名解析图标；未知/空键回退默认图标（向前兼容旧数据与被删图标）。
IconData promptBlockIconFromName(String? name) {
  if (name == null) return kPromptBlockDefaultIcon;
  return kPromptBlockIconOptions[name] ?? kPromptBlockDefaultIcon;
}

/// 编辑对话框里的紧凑图标选择器：再点已选中项 = 清除回默认。
class PromptBlockIconPicker extends StatelessWidget {
  const PromptBlockIconPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    MenuController? menuController;
    return MenuAnchor(
      key: const Key('prompt-block-icon-picker'),
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
        maximumSize: WidgetStatePropertyAll(Size(300, 320)),
      ),
      builder: (context, controller, child) {
        menuController = controller;
        return OutlinedButton.icon(
          key: const Key('prompt-block-icon-trigger'),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(
            promptBlockIconFromName(selected),
            size: 19,
            color: theme.colorScheme.primary,
          ),
          label: Text(selected ?? context.l10n.common_default),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            primary: false,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in kPromptBlockIconOptions.entries)
                  _buildCell(
                    theme,
                    entry,
                    onClose: () => menuController?.close(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(
    ThemeData theme,
    MapEntry<String, IconData> entry, {
    required VoidCallback onClose,
  }) {
    final isSelected = selected == entry.key;
    return Tooltip(
      message: entry.key,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        key: ValueKey('prompt-block-icon-option-${entry.key}'),
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          onChanged(isSelected ? null : entry.key);
          onClose();
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Icon(
            entry.value,
            size: 17,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
