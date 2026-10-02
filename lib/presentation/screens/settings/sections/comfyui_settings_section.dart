import '../widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/comfyui/comfyui_models.dart';
import '../../../../core/comfyui/workflow_template.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../utils/comfyui_workflow_l10n.dart';
import '../../../providers/comfyui/comfyui_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_hover_line.dart';
import '../widgets/workflow_import_wizard.dart';

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
    final workflows = ref.watch(comfyUIWorkflowsProvider);

    if (_urlController.text.isEmpty ||
        _urlController.text != settings.serverUrl) {
      _urlController.text = settings.serverUrl;
    }

    final customWorkflows = workflows.where((t) => !t.isBuiltin).toList();
    final builtinWorkflows = workflows.where((t) => t.isBuiltin).toList();

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
        if (settings.enabled)
          SettingsCard(
            title: context.l10n.settings_comfyUiWorkflowManagement,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (builtinWorkflows.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(
                      context.l10n.settings_comfyUiBuiltinWorkflows,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...builtinWorkflows.map((t) => _buildWorkflowTile(theme, t)),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.settings_comfyUiCustomWorkflows,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => WorkflowImportWizard.show(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.l10n.common_import),
                      ),
                    ],
                  ),
                ),
                if (customWorkflows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      context.l10n.settings_comfyUiNoCustomWorkflows,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...customWorkflows.map((t) => _buildWorkflowTile(theme, t)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWorkflowTile(ThemeData theme, WorkflowTemplate template) {
    final description = template.localizedDescription(context);
    final count = context.l10n.settings_comfyUiSlotCount(template.slots.length);
    final action = template.isBuiltin
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              context.l10n.settings_comfyUiBuiltin,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : IconButton(
            tooltip: context.l10n.common_delete,
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
            onPressed: () => _confirmDeleteWorkflow(template),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            680 * MediaQuery.textScalerOf(context).scale(1)) {
          return SettingsTile(
            key: ValueKey('settings-workflow-${template.id}'),
            dense: true,
            controlWrapWidth: 0,
            hoverFeedback: !template.isBuiltin,
            title: Text(template.localizedName(context)),
            subtitle: Text(
              '$count${description.isEmpty ? "" : " · $description"}',
            ),
            trailing: action,
          );
        }
        return SettingsHoverLine(
          enabled: !template.isBuiltin,
          child: Container(
            key: ValueKey('settings-workflow-${template.id}'),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    template.localizedName(context),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 86 * MediaQuery.textScalerOf(context).scale(1),
                  child: Text(
                    count,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 4,
                  child: Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                action,
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteWorkflow(WorkflowTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settings_comfyUiDeleteWorkflowTitle),
        content: Text(
          context.l10n.settings_comfyUiDeleteWorkflowContent(
            template.localizedName(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(comfyUIWorkflowsProvider.notifier)
          .removeCustomTemplate(template.id);
      if (mounted) {
        AppToast.success(
          context,
          context.l10n.settings_comfyUiDeleted(template.localizedName(context)),
        );
      }
    }
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
