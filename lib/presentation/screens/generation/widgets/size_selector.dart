import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/resolution_preset.dart';
import '../../../widgets/common/themed_dropdown.dart';
import 'generation_sidebar_style.dart';

/// 尺寸选择器 (官网式布局：紧凑分组下拉 + 等宽宽高比分段组 + 自定义输入)
///
/// 从 ParameterPanel 提取的公开组件，经典布局的参数面板与
/// 官网式布局的置顶尺寸区共用。
///
/// 传入 [title] 时会在控件顶部渲染分节标题行，右端附带当前分辨率
/// 徽标（自定义分组下隐藏）。
class SizeSelector extends StatefulWidget {
  final int width;
  final int height;
  final void Function(int width, int height) onChanged;

  /// 可选的分节标题（渲染在控件顶部；右侧显示当前分辨率徽标）
  final Widget? title;

  const SizeSelector({
    super.key,
    required this.width,
    required this.height,
    required this.onChanged,
    this.title,
  });

  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late FocusNode _widthFocusNode;
  late FocusNode _heightFocusNode;
  final FocusNode _dropdownFocusNode = FocusNode();
  late ResolutionGroup _selectedGroup;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(text: widget.width.toString());
    _heightController = TextEditingController(text: widget.height.toString());
    _widthFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
    _updateSelectedGroup();
  }

  @override
  void didUpdateWidget(covariant SizeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      _syncFieldController(
        controller: _widthController,
        focusNode: _widthFocusNode,
        targetValue: widget.width,
      );
      _syncFieldController(
        controller: _heightController,
        focusNode: _heightFocusNode,
        targetValue: widget.height,
      );
      _updateSelectedGroup();
    }
  }

  void _syncFieldController({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int targetValue,
  }) {
    final nextText = resolveManualSizeFieldSyncText(
      currentText: controller.text,
      targetValue: targetValue,
      hasFocus: focusNode.hasFocus,
    );
    if (nextText == null) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
  }

  void _updateSelectedGroup() {
    final matchedPreset = ResolutionPreset.findBySize(
      widget.width,
      widget.height,
    );
    _selectedGroup = matchedPreset?.group ?? ResolutionGroup.custom;
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    _dropdownFocusNode.dispose();
    super.dispose();
  }

  String _getGroupName(BuildContext context, ResolutionGroup group) {
    final l10n = context.l10n;
    return switch (group) {
      ResolutionGroup.normal => l10n.resolution_groupNormal,
      ResolutionGroup.large => l10n.resolution_groupLarge,
      ResolutionGroup.wallpaper => l10n.resolution_groupWallpaper,
      ResolutionGroup.small => l10n.resolution_groupSmall,
      ResolutionGroup.custom => l10n.resolution_groupCustom,
    };
  }

  String _getTypeName(BuildContext context, ResolutionType type) {
    final l10n = context.l10n;
    return switch (type) {
      ResolutionType.portrait => l10n.resolution_typePortrait,
      ResolutionType.landscape => l10n.resolution_typeLandscape,
      ResolutionType.square => l10n.resolution_typeSquare,
      ResolutionType.custom => l10n.resolution_typeCustom,
    };
  }

  /// 在指定分组内查找指定宽高比类型的预设
  ResolutionPreset? _findPreset(ResolutionGroup group, ResolutionType? type) {
    if (type == null) return null;
    for (final preset in ResolutionPreset.presets) {
      if (preset.group == group && preset.type == type) {
        return preset;
      }
    }
    return null;
  }

  void _onGroupSelected(ResolutionGroup? group) {
    if (group == null) return;

    // 选择后取消焦点
    _dropdownFocusNode.unfocus();

    setState(() {
      _selectedGroup = group;
    });

    if (group == ResolutionGroup.custom) {
      // 保持当前宽高不变
      return;
    }

    // 优先保持当前宽高比类型；组内缺失该类型时回退到组内第一个预设
    final currentType = ResolutionPreset.findBySize(
      widget.width,
      widget.height,
    )?.type;
    final groupPresets = ResolutionPreset.getByGroup(group);
    final preset =
        _findPreset(group, currentType) ??
        (groupPresets.isNotEmpty ? groupPresets.first : null);
    if (preset != null) {
      widget.onChanged(preset.width, preset.height);
    }
  }

  void _onTypeSelected(ResolutionType type) {
    final preset = _findPreset(_selectedGroup, type);
    if (preset == null) return;
    if (preset.width == widget.width && preset.height == widget.height) {
      return;
    }
    widget.onChanged(preset.width, preset.height);
  }

  void _onManualSizeChanged() {
    final newWidth = int.tryParse(_widthController.text) ?? widget.width;
    final newHeight = int.tryParse(_heightController.text) ?? widget.height;

    // 检查是否匹配某个预设，匹配则自动跳回该预设所在分组
    final matchedPreset = ResolutionPreset.findBySize(newWidth, newHeight);
    setState(() {
      _selectedGroup = matchedPreset?.group ?? ResolutionGroup.custom;
    });

    if (newWidth != widget.width || newHeight != widget.height) {
      widget.onChanged(newWidth, newHeight);
    }
  }

  /// 分组下拉的紧凑宽度：随最长组名收缩（约 100px），把行宽让给宽高比组
  double _measureGroupDropdownWidth(BuildContext context) {
    const style = TextStyle(fontSize: 13);
    var maxTextWidth = 0.0;
    for (final group in ResolutionGroup.values) {
      if ((ResolutionPreset.groupedPresets[group] ?? []).isEmpty) {
        continue;
      }
      final painter = TextPainter(
        text: TextSpan(text: _getGroupName(context, group), style: style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      if (painter.width > maxTextWidth) {
        maxTextWidth = painter.width;
      }
    }
    // 文本宽 + 水平内边距(24) + 下拉图标(~24) + 留白
    return (maxTextWidth + 44).clamp(96.0, 112.0).toDouble();
  }

  /// 官网式宽高比分段控件：横屏/竖屏/方形三个等宽按钮共用一个
  /// 描边圆角组，选中段填充主题中性表面色。
  Widget _buildAspectGroup(
    BuildContext context,
    bool isCustomGroup,
    ResolutionPreset? matchedPreset,
  ) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(5);
    return Container(
      key: const Key('size-aspect-group'),
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Row(
          children: [
            _buildAspectSegment(
              context,
              ResolutionType.landscape,
              Icons.crop_landscape,
              isCustomGroup,
              matchedPreset,
            ),
            _buildAspectSegment(
              context,
              ResolutionType.portrait,
              Icons.crop_portrait,
              isCustomGroup,
              matchedPreset,
            ),
            _buildAspectSegment(
              context,
              ResolutionType.square,
              Icons.crop_square,
              isCustomGroup,
              matchedPreset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectSegment(
    BuildContext context,
    ResolutionType type,
    IconData icon,
    bool isCustomGroup,
    ResolutionPreset? matchedPreset,
  ) {
    final theme = Theme.of(context);
    // 自定义分组全部禁用；壁纸组无方形预设时方形图标禁用
    final enabled = !isCustomGroup && _findPreset(_selectedGroup, type) != null;
    final highlighted =
        !isCustomGroup &&
        matchedPreset != null &&
        matchedPreset.group == _selectedGroup &&
        matchedPreset.type == type;

    // 等宽段占满分段组宽度（320px 下每段约 70px），命中面积远大于
    // 原先的 34px 孤立图标钮；选中段出主题表面色淡底，不再用 primary 描边
    return Expanded(
      child: IconButton(
        key: Key('size-aspect-${type.name}'),
        onPressed: enabled ? () => _onTypeSelected(type) : null,
        icon: Icon(icon, size: 18),
        tooltip: _getTypeName(context, type),
        style: IconButton.styleFrom(
          backgroundColor: highlighted
              ? GenSidebarStyle.selectedSurface(theme)
              : Colors.transparent,
          foregroundColor: highlighted
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          disabledForegroundColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.3,
          ),
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isCustomGroup = _selectedGroup == ResolutionGroup.custom;
    final matchedPreset = ResolutionPreset.findBySize(
      widget.width,
      widget.height,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          // 分节标题行：右端显示当前分辨率徽标（自定义分组时隐藏）
          Row(
            children: [
              // 标题提升为模块标题档（官网 Resolution 同款），
              // 外层传入的 ParamSectionTitle 样式经作用域放大
              Expanded(child: SidebarTitleScope(child: widget.title!)),
              if (!isCustomGroup)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${widget.width} × ${widget.height}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // 紧凑分组下拉 + 占满剩余宽度的宽高比分段组（官网式）
        Row(
          children: [
            // 分组下拉菜单（只显示分组名，宽度随组名收缩约 100px）
            Container(
              width: _measureGroupDropdownWidth(context),
              height: 36,
              decoration: BoxDecoration(
                color: GenSidebarStyle.selectedSurface(theme),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButtonFormField<ResolutionGroup>(
                initialValue: _selectedGroup,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.expand_more, size: 18),
                dropdownColor: theme.colorScheme.surfaceContainerHigh,
                decoration: const InputDecoration(
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                focusNode: _dropdownFocusNode,
                items: [
                  for (final group in ResolutionGroup.values)
                    if ((ResolutionPreset.groupedPresets[group] ?? [])
                        .isNotEmpty)
                      DropdownMenuItem<ResolutionGroup>(
                        value: group,
                        child: Text(
                          _getGroupName(context, group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                ],
                onChanged: _onGroupSelected,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAspectGroup(context, isCustomGroup, matchedPreset),
            ),
          ],
        ),

        // 自定义宽高输入（仅自定义分组显示）
        if (isCustomGroup) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              // 宽度输入
              Expanded(
                child: ThemedTextField(
                  controller: _widthController,
                  focusNode: _widthFocusNode,
                  keyboardType: TextInputType.number,
                  labelText: l10n.resolution_width,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => _onManualSizeChanged(),
                ),
              ),
              // × 符号
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              // 高度输入
              Expanded(
                child: ThemedTextField(
                  controller: _heightController,
                  focusNode: _heightFocusNode,
                  keyboardType: TextInputType.number,
                  labelText: l10n.resolution_height,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => _onManualSizeChanged(),
                ),
              ),
              // 交换宽高按钮（与宽高比钮同款紧凑描边样式）
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final temp = _widthController.text;
                  _widthController.text = _heightController.text;
                  _heightController.text = temp;
                  _onManualSizeChanged();
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                tooltip: context.l10n.common_swap,
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.7,
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(34, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

@visibleForTesting
String? resolveManualSizeFieldSyncText({
  required String currentText,
  required int targetValue,
  required bool hasFocus,
}) {
  if (hasFocus) {
    return null;
  }

  final nextText = targetValue.toString();
  if (currentText == nextText) {
    return null;
  }

  return nextText;
}
