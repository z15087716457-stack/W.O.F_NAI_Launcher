import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../ui/settings/settings_contract.dart';

/// Kept for this application session, including when settings is closed.
final settingsRagStartupProvider =
    NotifierProvider<SettingsRagStartup, SettingsRagStartupState>(
      SettingsRagStartup.new,
    );

class SettingsRagStartupState {
  const SettingsRagStartupState({this.notified = false, this.preparing});
  final bool notified;
  final SettingsRagSourceKind? preparing;
}

class SettingsRagStartup extends Notifier<SettingsRagStartupState> {
  bool _disposed = false;

  @override
  SettingsRagStartupState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const SettingsRagStartupState();
  }

  Future<void> run({
    required SettingsRagSourceKind source,
    required Future<bool> Function() notify,
    required Future<void> Function() action,
  }) async {
    if (state.preparing != null) return;
    final needsNotice = !state.notified;
    state = SettingsRagStartupState(notified: true, preparing: source);
    try {
      if (needsNotice && !await notify()) return;
      if (_disposed) return;
      await action();
    } finally {
      if (!_disposed) state = const SettingsRagStartupState(notified: true);
    }
  }
}

Future<void> runSettingsRagStartup(
  WidgetRef ref,
  BuildContext context,
  SettingsRagSourceKind source,
  Future<void> Function() action,
) => ref
    .read(settingsRagStartupProvider.notifier)
    .run(
      source: source,
      notify: () => showSettingsRagStartupNotice(context),
      action: () async {
        if (context.mounted) await action();
      },
    );

Future<bool> showSettingsRagStartupNotice(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        key: const Key('rag-startup-notice'),
        title: Text(dialog.l10n.set_rgStartupTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Text(dialog.l10n.set_rgStartupBody),
          ),
        ),
        actions: [
          FilledButton(
            key: const Key('rag-startup-notice-ok'),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(dialog.l10n.common_gotIt),
          ),
        ],
      ),
    ) ??
    false;
