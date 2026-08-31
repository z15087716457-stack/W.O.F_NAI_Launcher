import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../data/repositories/prompt_block_repository.dart';

class PromptBlockFolderDeleteDecision {
  const PromptBlockFolderDeleteDecision({
    required this.mode,
    this.destinationFolderId,
  });

  final PromptBlockFolderDeleteMode mode;
  final String? destinationFolderId;
}

class PromptBlockFolderDeleteDialog extends StatefulWidget {
  const PromptBlockFolderDeleteDialog({
    super.key,
    required this.folder,
    required this.destinationFolders,
  });

  final PromptBlockFolder folder;
  final List<PromptBlockFolder> destinationFolders;

  static Future<PromptBlockFolderDeleteDecision?> show({
    required BuildContext context,
    required PromptBlockFolder folder,
    required List<PromptBlockFolder> destinationFolders,
  }) {
    return showDialog<PromptBlockFolderDeleteDecision>(
      context: context,
      builder: (context) => PromptBlockFolderDeleteDialog(
        folder: folder,
        destinationFolders: destinationFolders,
      ),
    );
  }

  @override
  State<PromptBlockFolderDeleteDialog> createState() =>
      _PromptBlockFolderDeleteDialogState();
}

class _PromptBlockFolderDeleteDialogState
    extends State<PromptBlockFolderDeleteDialog> {
  late PromptBlockFolderDeleteMode _mode;
  String? _destinationFolderId;

  @override
  void initState() {
    super.initState();
    _mode = PromptBlockFolderDeleteMode.moveContentsToRoot;
    _destinationFolderId = widget.destinationFolders.isEmpty
        ? null
        : widget.destinationFolders.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canMoveToFolder = widget.destinationFolders.isNotEmpty;
    final confirmEnabled =
        _mode != PromptBlockFolderDeleteMode.moveContentsToFolder ||
        _destinationFolderId != null;

    return AlertDialog(
      title: Text(l10n.promptBlockLibrary_deleteFolderTitle(_displayName)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: RadioGroup<PromptBlockFolderDeleteMode>(
            groupValue: _mode,
            onChanged: (value) {
              if (value != null &&
                  (value != PromptBlockFolderDeleteMode.moveContentsToFolder ||
                      canMoveToFolder)) {
                setState(() => _mode = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.promptBlockLibrary_deleteFolderDescription),
                ),
                const SizedBox(height: 8),
                RadioListTile<PromptBlockFolderDeleteMode>(
                  value: PromptBlockFolderDeleteMode.moveContentsToRoot,
                  title: Text(l10n.promptBlockLibrary_moveContentsToRoot),
                ),
                RadioListTile<PromptBlockFolderDeleteMode>(
                  value: PromptBlockFolderDeleteMode.moveContentsToFolder,
                  enabled: canMoveToFolder,
                  title: Text(l10n.promptBlockLibrary_moveContentsToFolder),
                ),
                if (_mode == PromptBlockFolderDeleteMode.moveContentsToFolder)
                  Padding(
                    padding: const EdgeInsets.only(left: 52, right: 16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _destinationFolderId,
                      decoration: InputDecoration(
                        labelText: l10n.promptBlockLibrary_destinationFolder,
                      ),
                      items: widget.destinationFolders
                          .map(
                            (folder) => DropdownMenuItem<String>(
                              value: folder.id,
                              child: Text(
                                folder.name.isEmpty
                                    ? l10n.promptBlockLibrary_unnamedFolder
                                    : folder.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _destinationFolderId = value),
                    ),
                  ),
                RadioListTile<PromptBlockFolderDeleteMode>(
                  value: PromptBlockFolderDeleteMode.deleteContents,
                  title: Text(l10n.promptBlockLibrary_deleteContents),
                  subtitle: Text(l10n.promptBlockLibrary_deleteContentsWarning),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: confirmEnabled
              ? () => Navigator.of(context).pop(
                  PromptBlockFolderDeleteDecision(
                    mode: _mode,
                    destinationFolderId: _destinationFolderId,
                  ),
                )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: _mode == PromptBlockFolderDeleteMode.deleteContents
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          child: Text(l10n.common_delete),
        ),
      ],
    );
  }

  String get _displayName => widget.folder.name.isEmpty
      ? context.l10n.promptBlockLibrary_unnamedFolder
      : widget.folder.name;
}
