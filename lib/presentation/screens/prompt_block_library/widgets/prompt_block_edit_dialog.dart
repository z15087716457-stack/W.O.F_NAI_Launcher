import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../widgets/common/themed_input.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import 'prompt_block_color_picker.dart';

class PromptBlockEditResult {
  const PromptBlockEditResult({
    required this.title,
    required this.content,
    required this.folderId,
    required this.color,
    required this.iconName,
  });

  final String title;
  final String content;
  final String? folderId;
  final String color;
  final String? iconName;
}

class PromptBlockEditDialog extends StatefulWidget {
  const PromptBlockEditDialog({
    super.key,
    required this.block,
    required this.folders,
    this.initialFolderId,
  });

  final PromptBlock? block;
  final List<PromptBlockFolder> folders;
  final String? initialFolderId;

  static Future<PromptBlockEditResult?> show({
    required BuildContext context,
    PromptBlock? block,
    required List<PromptBlockFolder> folders,
    String? initialFolderId,
  }) {
    return showDialog<PromptBlockEditResult>(
      context: context,
      builder: (context) => PromptBlockEditDialog(
        block: block,
        folders: folders,
        initialFolderId: initialFolderId,
      ),
    );
  }

  @override
  State<PromptBlockEditDialog> createState() => _PromptBlockEditDialogState();
}

class _PromptBlockEditDialogState extends State<PromptBlockEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String? _folderId;
  late Color _selectedColor;
  late String? _selectedIconName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block?.title ?? '');
    _contentController = TextEditingController(
      text: widget.block?.content ?? '',
    );
    _folderId = widget.block?.folderId ?? widget.initialFolderId;
    _selectedColor = promptBlockColorFromString(
      widget.block?.color ?? '#FF607D8B',
    );
    _selectedIconName = widget.block?.iconName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final folders = widget.folders.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });

    return AlertDialog(
      title: Text(
        widget.block == null
            ? l10n.promptBlockLibrary_newBlock
            : l10n.promptBlockLibrary_editBlock,
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedInput(
                controller: _titleController,
                autofocus: true,
                hintText: l10n.promptBlockLibrary_titleHint,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_blockTitle,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _folderId,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_folder,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.promptBlockLibrary_rootFolder),
                  ),
                  ...folders.map(
                    (folder) => DropdownMenuItem<String>(
                      value: folder.id,
                      child: Text(
                        _folderLabel(folder, folders),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _folderId = value),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.promptBlockLibrary_blockContent,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              ThemedInput.multiline(
                controller: _contentController,
                minLines: 9,
                maxLines: 14,
                hintText: l10n.promptBlockLibrary_contentHint,
                contentPadding: const EdgeInsets.all(12),
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
              if (widget.block?.sourcePath case final sourcePath?) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${l10n.promptBlockLibrary_sourceFile}: ${_sourceFileName(sourcePath)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.block?.importedAt case final importedAt?)
                  Text(
                    '${l10n.promptBlockLibrary_importedAt}: ${_formatDateTime(importedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              PromptBlockEditResult(
                title: _titleController.text.trim(),
                // Keep the original text exactly as entered, including whitespace.
                content: _contentController.text,
                folderId: _folderId,
                color: promptBlockColorToHex(_selectedColor),
                iconName: _selectedIconName,
              ),
            );
          },
          child: Text(l10n.common_save),
        ),
      ],
    );
  }

  String _sourceFileName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty);
    return segments.isEmpty ? sourcePath : segments.last;
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _folderLabel(
    PromptBlockFolder folder,
    List<PromptBlockFolder> folders,
  ) {
    var depth = 0;
    final byId = <String, PromptBlockFolder>{
      for (final item in folders) item.id: item,
    };
    final visited = <String>{};
    String? parentId = folder.parentId;
    while (parentId != null && visited.add(parentId)) {
      depth++;
      parentId = byId[parentId]?.parentId;
    }
    final name = folder.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedFolder
        : folder.name;
    return '${'  ' * depth}$name';
  }
}
