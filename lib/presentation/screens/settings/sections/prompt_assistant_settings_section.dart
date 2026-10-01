import 'package:flutter/material.dart';
import 'model_management_section.dart';

/// Compatibility entry for existing in-place configuration consumers.
class PromptAssistantSettingsSection extends StatelessWidget {
  const PromptAssistantSettingsSection({super.key});
  @override
  Widget build(BuildContext context) => const ModelManagementSection();
}

Future<void> showModelManagementDialog(BuildContext context) {
  final editor = GlobalKey<ModelManagementSectionState>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      child: SizedBox(
        width: MediaQuery.sizeOf(dialogContext).width > 1150
            ? 1100
            : MediaQuery.sizeOf(dialogContext).width - 48,
        height: MediaQuery.sizeOf(dialogContext).height * .85,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: '返回编辑',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (await (editor.currentState?.confirmLeave() ??
                          Future.value(true)) &&
                      dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ),
            Expanded(child: ModelManagementSection(key: editor)),
          ],
        ),
      ),
    ),
  );
}
