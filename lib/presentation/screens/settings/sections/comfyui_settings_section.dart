import '../widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/comfyui/comfyui_models.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/comfyui/comfyui_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input.dart';
import '../widgets/settings_card.dart';

/// ComfyUI 设置板块
class ComfyUISettingsSection extends ConsumerStatefulWidget {
  const ComfyUISettingsSection({super.key});

  @override
  ConsumerState<ComfyUISettingsSection> createState() =>
      _ComfyUISettingsSectionState();
}

class _ComfyUISettingsSectionState
    extends ConsumerState<ComfyUISettingsSection> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(comfyUISettingsProvider);
    final connStatus = ref.watch(comfyUIConnectionProvider);

    if (_urlController.text.isEmpty ||
        _urlController.text != settings.serverUrl) {
      _urlController.text = settings.serverUrl;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          bottomSpacing: 22,
          child: Column(
            children: [
              SettingsSwitchTile(
                title: Text(context.l10n.settings_comfyUiEnable),
                subtitle: Text(
                  settings.enabled
                      ? _connectionStatusText(context, connStatus)
                      : context.l10n.settings_comfyUiDisabledSubtitle,
                ),
                value: settings.enabled,
                onChanged: (value) {
                  ref.read(comfyUISettingsProvider.notifier).setEnabled(value);
                  if (!value) {
                    ref.read(comfyUIConnectionProvider.notifier).disconnect();
                  }
                },
              ),
              if (settings.enabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final input = ThemedInput(
                        key: const Key('settings-comfyui-address'),
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'http://127.0.0.1:8188',
                          labelText:
                              constraints.maxWidth <
                                  540 *
                                      MediaQuery.textScalerOf(context).scale(1)
                              ? context.l10n.settings_comfyUiServerUrl
                              : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => ref
                            .read(comfyUISettingsProvider.notifier)
                            .setServerUrl(value),
                      );
                      final test = OutlinedButton(
                        key: const Key('settings-comfyui-test'),
                        onPressed: _isTesting ? null : _testConnection,
                        child: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.settings_testConnection),
                      );
                      if (constraints.maxWidth <
                          540 * MediaQuery.textScalerOf(context).scale(1)) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            input,
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: test,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            context.l10n.settings_comfyUiServerUrl,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(child: input),
                          const SizedBox(width: 12),
                          test,
                        ],
                      );
                    },
                  ),
                ),
                if (_testResult != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testResult == 'ok'
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 16,
                          color: _testResult == 'ok'
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult == 'ok'
                                ? context.l10n.settings_comfyUiConnectionSuccess
                                : context.l10n.settings_comfyUiConnectionFailed(
                                    _testResult!,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _testResult == 'ok'
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (connStatus == ComfyUIConnectionStatus.connected)
                  SettingsTile(
                    title: Text(context.l10n.settings_comfyUiConnected),
                    subtitle: Text(settings.serverUrl),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(comfyUIConnectionProvider.notifier)
                          .disconnect(),
                      child: Text(context.l10n.settings_comfyUiDisconnect),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final ok = await ref
          .read(comfyUIConnectionProvider.notifier)
          .testConnection();
      if (mounted) {
        setState(() {
          _testResult = ok ? 'ok' : context.l10n.settings_comfyUiNoResponse;
          _isTesting = false;
        });
        if (ok) {
          AppToast.success(
            context,
            context.l10n.settings_comfyUiConnectionSuccessFull,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = context.l10n.settings_comfyUiConnectionFailed(
            e.toString(),
          );
          _isTesting = false;
        });
      }
    }
  }

  String _connectionStatusText(
    BuildContext context,
    ComfyUIConnectionStatus status,
  ) {
    switch (status) {
      case ComfyUIConnectionStatus.disconnected:
        return context.l10n.settings_comfyUiStatusDisconnected;
      case ComfyUIConnectionStatus.connecting:
        return context.l10n.settings_comfyUiStatusConnecting;
      case ComfyUIConnectionStatus.connected:
        return context.l10n.settings_comfyUiStatusConnected;
      case ComfyUIConnectionStatus.error:
        return context.l10n.settings_comfyUiStatusError;
    }
  }
}
