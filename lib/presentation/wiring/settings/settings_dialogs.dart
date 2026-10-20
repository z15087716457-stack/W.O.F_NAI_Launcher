import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../screens/settings/widgets/model_draft_save_controller.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_glyph.dart';
import '../../ui/kit/ui_text.dart';
import '../../ui/settings/settings_dialog_kit.dart';
import '../../ui/settings/settings_kit.dart';

/// 单项文字输入（设置页同款弹窗）。[validate] 返回错误文字时就地提示，不关窗。
Future<String?> settingsTextInput(
  BuildContext context, {
  required String title,
  String initial = '',
  int maxLines = 1,
  String? subtitle,
  String? label,
  String? hint,
  String? help,
  bool mono = false,
  String? confirm,
  String? Function(String value)? validate,
}) => showSettingsDialog<String>(
  context,
  (_) => SettingsTextDialog(
    title: title,
    initial: initial,
    maxLines: maxLines,
    subtitle: subtitle,
    label: label,
    hint: hint,
    help: help,
    mono: mono || maxLines > 1,
    confirm: confirm,
    validate: validate,
  ),
);

/// 确认（设置页同款弹窗）。[danger] 用于删除类操作。
Future<bool> settingsConfirm(
  BuildContext context,
  String title,
  String body, {
  String? confirm,
  bool danger = false,
}) async =>
    await showSettingsDialog<bool>(
      context,
      (_) => SettingsConfirmDialog(
        title: title,
        body: body,
        confirm: confirm,
        danger: danger,
      ),
    ) ??
    false;

/// 只有“知道了”的提示（例如名称冲突）。
Future<void> settingsNotice(BuildContext context, String title, String body) =>
    showSettingsDialog<void>(
      context,
      (dialog) => SettingsDialogFrame(
        width: 420,
        title: title,
        glyph: UiGlyphs.infoCircle,
        body: Text(
          body,
          style: UiText.sans(13, color: dialog.ui.muted, height: 1.65),
        ),
        actions: [
          SettingsBtn(
            label: dialog.l10n.common_gotIt,
            tone: SettingsBtnTone.primary,
            onTap: () => Navigator.pop(dialog),
          ),
        ],
      ),
    );

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
