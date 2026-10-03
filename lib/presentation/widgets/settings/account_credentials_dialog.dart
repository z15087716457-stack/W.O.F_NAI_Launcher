import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/auth_provider.dart';
import '../../screens/settings/widgets/settings_dialog.dart';

class AccountCredentialsDialog extends ConsumerStatefulWidget {
  const AccountCredentialsDialog({super.key, required this.account});
  final SavedAccount account;
  @override
  ConsumerState<AccountCredentialsDialog> createState() =>
      _AccountCredentialsDialogState();
}

class _AccountCredentialsDialogState
    extends ConsumerState<AccountCredentialsDialog> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || controller.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .replaceSavedAccountCredential(widget.account.id, controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = context.l10n.settings_credentialsWereNotUpdatedCheck,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SettingsDialogFrame(
    title: context.l10n.settings_updateCredentials2,
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.l10n.common_cancel),
      ),
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(
          busy ? context.l10n.settings_checking : context.l10n.common_save,
        ),
      ),
    ],
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.account.displayName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.settings_enterNewSignInToken,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('settings-account-credential'),
            controller: controller,
            enabled: !busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: 'Token', errorText: error),
            onSubmitted: (_) => save(),
          ),
        ],
      ),
    ),
  );
}
