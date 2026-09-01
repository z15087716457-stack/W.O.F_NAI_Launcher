import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../widgets/common/themed_input.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../prompt_block_library/widgets/prompt_block_color_picker.dart';

/// 「收编为块」对话框的返回结果。
class ExploreAdoptBlockResult {
  const ExploreAdoptBlockResult({
    required this.title,
    required this.color,
    this.iconName,
  });

  final String title;
  final String color;
  final String? iconName;
}

/// 收编为块对话框：名称 + 颜色 + 图标（内容固定为候选 roll 串，
/// 只读预览不回编）。颜色/图标选择器复用块库编辑弹窗同款组件。
class ExploreAdoptBlockDialog extends StatefulWidget {
  const ExploreAdoptBlockDialog({
    super.key,
    required this.initialTitle,
    required this.contentPreview,
  });

  final String initialTitle;
  final String contentPreview;

  static Future<ExploreAdoptBlockResult?> show(
    BuildContext context, {
    required String initialTitle,
    required String contentPreview,
  }) {
    return showDialog<ExploreAdoptBlockResult>(
      context: context,
      builder: (context) => ExploreAdoptBlockDialog(
        initialTitle: initialTitle,
        contentPreview: contentPreview,
      ),
    );
  }

  @override
  State<ExploreAdoptBlockDialog> createState() =>
      _ExploreAdoptBlockDialogState();
}

class _ExploreAdoptBlockDialogState extends State<ExploreAdoptBlockDialog> {
  late final TextEditingController _titleController;
  late Color _selectedColor;
  String? _selectedIconName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedColor = promptBlockColorFromString('#FF607D8B');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _confirm() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      ExploreAdoptBlockResult(
        title: title,
        color: promptBlockColorToHex(_selectedColor),
        iconName: _selectedIconName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AlertDialog(
      key: const Key('explore-adopt-block-dialog'),
      title: Text(l10n.styleExplore_adoptAsBlock),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedInput(
                key: const Key('explore-adopt-block-name'),
                controller: _titleController,
                autofocus: true,
                hintText: l10n.promptBlockLibrary_titleHint,
                decoration: InputDecoration(
                  labelText: l10n.styleExplore_adoptBlockNameLabel,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: 12),
              Text(
                widget.contentPreview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_color,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockColorPicker(
                selectedColor: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_icon,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockIconPicker(
                selected: _selectedIconName,
                onChanged: (name) => setState(() => _selectedIconName = name),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _titleController,
          builder: (context, value, _) {
            return FilledButton(
              key: const Key('explore-adopt-block-confirm'),
              onPressed: value.text.trim().isEmpty ? null : _confirm,
              child: Text(l10n.common_confirm),
            );
          },
        ),
      ],
    );
  }
}
