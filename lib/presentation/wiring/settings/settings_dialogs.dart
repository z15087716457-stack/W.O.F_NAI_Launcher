import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../screens/settings/widgets/model_draft_save_controller.dart';

Future<String?> settingsTextInput(
  BuildContext context, {
  required String title,
  String initial = '',
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initial);
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: maxLines == 1 ? 420 : 580,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            onSubmitted: maxLines == 1
                ? (value) => Navigator.pop(dialog, value.trim())
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    );
  } finally {
    // Dialog routes can remain mounted during their closing transition.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    controller.dispose();
  }
}

Future<bool> settingsConfirm(
  BuildContext context,
  String title,
  String body,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    ) ??
    false;

typedef SettingsEditorBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<bool> dirty,
      ValueChanged<String> saved,
      ModelDraftSaveController controller,
    );

Future<void> showSettingsEditor(
  BuildContext context,
  SettingsEditorBuilder builder,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _SettingsEditorDialog(builder),
);

class _SettingsEditorDialog extends StatefulWidget {
  const _SettingsEditorDialog(this.builder);
  final SettingsEditorBuilder builder;
  @override
  State<_SettingsEditorDialog> createState() => _SettingsEditorDialogState();
}

class _SettingsEditorDialogState extends State<_SettingsEditorDialog> {
  final saveController = ModelDraftSaveController();
  bool dirty = false, closing = false, closed = false;
  void saved(String _) {
    if (!mounted || closed) return;
    closed = true;
    Navigator.pop(context);
  }

  Future<void> close() async {
    if (closing || closed) return;
    closing = true;
    try {
      if (dirty) {
        final choice = await showDialog<String>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(context.l10n.modelSettings_keepEditsTitle),
            content: Text(context.l10n.modelSettings_keepEditsBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(context.l10n.common_cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialog, 'discard'),
                child: Text(context.l10n.modelSettings_discard),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, 'save'),
                child: Text(context.l10n.common_save),
              ),
            ],
          ),
        );
        if (choice == null || !mounted) return;
        if (choice == 'save' && !await saveController.save()) return;
      }
      if (mounted && !closed) saved('');
    } finally {
      closing = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: closed,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: Dialog(
      child: SizedBox(
        width: 1100,
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: context.l10n.common_close,
                icon: const Icon(Icons.close),
                onPressed: close,
              ),
            ),
            Expanded(
              child: widget.builder(
                context,
                (value) => dirty = value,
                saved,
                saveController,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
