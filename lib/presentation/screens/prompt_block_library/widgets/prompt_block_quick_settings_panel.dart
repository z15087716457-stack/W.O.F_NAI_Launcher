import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../widgets/common/themed_input.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import 'prompt_block_color_picker.dart';
import 'prompt_block_edit_dialog.dart';

const promptBlockLibraryWideHeaderHeight = 64.0;

class PromptBlockQuickSettingsPanel extends StatefulWidget {
  const PromptBlockQuickSettingsPanel({
    super.key,
    required this.block,
    required this.folders,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onExport,
    required this.onSave,
    required this.onDelete,
    required this.onCollapse,
    required this.onClose,
  });

  final PromptBlock block;
  final List<PromptBlockFolder> folders;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onExport;
  final Future<void> Function(PromptBlockEditResult result) onSave;
  final VoidCallback onDelete;
  final VoidCallback onCollapse;
  final VoidCallback onClose;

  @override
  State<PromptBlockQuickSettingsPanel> createState() =>
      _PromptBlockQuickSettingsPanelState();
}

class _PromptBlockQuickSettingsPanelState
    extends State<PromptBlockQuickSettingsPanel> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String? _folderId;
  late Color _selectedColor;
  late String? _selectedIconName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _resetForBlock(widget.block);
  }

  @override
  void didUpdateWidget(covariant PromptBlockQuickSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _resetForBlock(widget.block);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _resetForBlock(PromptBlock block) {
    _titleController.text = block.title;
    _contentController.text = block.content;
    _folderId = block.folderId;
    _selectedColor = promptBlockColorFromString(block.color);
    _selectedIconName = block.iconName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final blockColor = promptBlockColorFromString(widget.block.color);
    final folders = widget.folders.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) return const SizedBox.expand();
        return Material(
          key: const Key('prompt-block-quick-settings-content'),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              SizedBox(
                key: const Key('prompt-block-quick-settings-header'),
                height: promptBlockLibraryWideHeaderHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.common_edit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('prompt-block-quick-settings-collapse'),
                        tooltip: l10n.common_collapse,
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onCollapse,
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                      IconButton(
                        key: const Key('prompt-block-quick-settings-close'),
                        tooltip: l10n.common_close,
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: blockColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              promptBlockIconFromName(widget.block.iconName),
                              color: blockColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.block.title.isEmpty
                                  ? l10n.promptBlockLibrary_unnamedBlock
                                  : widget.block.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ThemedInput(
                        key: const Key('prompt-block-quick-title'),
                        controller: _titleController,
                        hintText: l10n.promptBlockLibrary_titleHint,
                        decoration: InputDecoration(
                          labelText: l10n.promptBlockLibrary_blockTitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: const Key('prompt-block-quick-folder'),
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
                                _folderOptionLabel(folder, folders),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _folderId = value),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ThemedInput.multiline(
                            key: const Key('prompt-block-quick-content'),
                            controller: _contentController,
                            minLines: 14,
                            maxLines: 26,
                            hintText: l10n.promptBlockLibrary_contentHint,
                            contentPadding: const EdgeInsets.fromLTRB(
                              12,
                              12,
                              44,
                              36,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Semantics(
                              button: true,
                              label: l10n.common_expand,
                              child: IconButton(
                                key: const Key(
                                  'prompt-block-quick-content-expand',
                                ),
                                tooltip: l10n.common_expand,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                onPressed: _showContentEditor,
                                icon: const Icon(Icons.open_in_full, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.promptBlockLibrary_color,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 7),
                      PromptBlockColorPicker(
                        selectedColor: _selectedColor,
                        onChanged: (color) =>
                            setState(() => _selectedColor = color),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.promptBlockLibrary_icon,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 7),
                      PromptBlockIconPicker(
                        selected: _selectedIconName,
                        onChanged: (name) =>
                            setState(() => _selectedIconName = name),
                      ),
                      if (widget.block.sourcePath != null) ...[
                        const SizedBox(height: 18),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.promptBlockLibrary_sourceFile,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _sourceFileName(widget.block.sourcePath!),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (widget.block.importedAt != null)
                          Text(
                            '${l10n.promptBlockLibrary_importedAt}: ${_formatDateTime(widget.block.importedAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onToggleFavorite,
                            icon: Icon(
                              widget.block.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                            ),
                            label: Text(
                              widget.block.isFavorite
                                  ? l10n.common_unfavorite
                                  : l10n.common_favorite,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _copyContent,
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            label: Text(l10n.common_copy),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onExport,
                            icon: const Icon(
                              Icons.file_upload_outlined,
                              size: 18,
                            ),
                            label: Text(
                              l10n.promptBlockLibrary_exportBlockAsTxt,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: widget.onDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              l10n.common_delete,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('prompt-block-quick-save'),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.common_save),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        PromptBlockEditResult(
          title: _titleController.text.trim(),
          content: _contentController.text,
          folderId: _folderId,
          color: promptBlockColorToHex(_selectedColor),
          iconName: _selectedIconName,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showContentEditor() async {
    final editedContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _PromptBlockContentEditDialog(
        initialContent: _contentController.text,
      ),
    );
    if (!mounted || editedContent == null) return;

    _contentController.value = TextEditingValue(
      text: editedContent,
      selection: TextSelection.collapsed(offset: editedContent.length),
    );
  }

  String _folderOptionLabel(
    PromptBlockFolder folder,
    List<PromptBlockFolder> folders,
  ) {
    final byId = <String, PromptBlockFolder>{
      for (final item in folders) item.id: item,
    };
    var depth = 0;
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

  String _sourceFileName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? sourcePath : segments.last;
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: widget.block.content));
    widget.onCopy();
  }
}

class _PromptBlockContentEditDialog extends StatefulWidget {
  const _PromptBlockContentEditDialog({required this.initialContent});

  final String initialContent;

  @override
  State<_PromptBlockContentEditDialog> createState() =>
      _PromptBlockContentEditDialogState();
}

class _PromptBlockContentEditDialogState
    extends State<_PromptBlockContentEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Dialog(
      key: const Key('prompt-block-quick-content-dialog'),
      child: SizedBox(
        width: 640,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.common_edit,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('prompt-block-quick-content-dialog-close'),
                    tooltip: l10n.common_cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ThemedInput.multiline(
                  key: const Key('prompt-block-quick-content-dialog-field'),
                  controller: _controller,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  hintText: l10n.promptBlockLibrary_contentHint,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('prompt-block-quick-content-dialog-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.common_cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('prompt-block-quick-content-dialog-save'),
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                    child: Text(l10n.common_save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromptBlockQuickSettingsCollapsed extends StatelessWidget {
  const PromptBlockQuickSettingsCollapsed({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('prompt-block-quick-settings-collapsed'),
        onTap: onExpand,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 19,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                context.l10n.common_edit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
