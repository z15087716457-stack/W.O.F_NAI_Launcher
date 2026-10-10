import 'dart:convert';
import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/providers/model_request_history_provider.dart';
import '../../../themes/studio_typography.dart';
import 'model_management_widgets.dart';
import 'settings_dialog.dart';
import '../../../../core/utils/localization_extension.dart';

class ModelRequestDetailsDialog extends ConsumerStatefulWidget {
  const ModelRequestDetailsDialog({super.key, required this.recordId});
  final String recordId;
  @override
  ConsumerState<ModelRequestDetailsDialog> createState() =>
      _ModelRequestDetailsDialogState();
}

class _ModelRequestDetailsDialogState
    extends ConsumerState<ModelRequestDetailsDialog> {
  int _tab = 0;
  bool _copied = false;
  String _content(ModelRequestRecord record) {
    final l10n = context.l10n;
    return const JsonEncoder.withIndent('  ').convert(switch (_tab) {
      0 => record.overviewIn(l10n),
      1 => {
        l10n.modelRequest_detailsRequests: [
          for (var i = 0; i < record.exchanges.length; i++)
            {
              l10n.modelRequest_detailsIndex: i + 1,
              ...record.exchanges[i].requestIn(l10n),
            },
        ],
      },
      _ => {
        l10n.modelRequest_detailsResponses: [
          for (var i = 0; i < record.exchanges.length; i++)
            {
              l10n.modelRequest_detailsIndex: i + 1,
              ...record.exchanges[i].responseIn(l10n),
            },
        ],
        if (record.output != null)
          l10n.modelRequest_detailsOutput: record.output,
        if (record.error != null) l10n.modelRequest_fieldError: record.error,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(modelRequestHistoryProvider);
    final record = history.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    final theme = Theme.of(context);
    return SettingsDialogFrame(
      title: record?.task ?? context.l10n.modelRequest_detailsTitle,
      width: 1000,
      actions: [
        TextButton.icon(
          key: const Key('request-details-copy'),
          onPressed: record == null
              ? null
              : () async {
                  await Clipboard.setData(
                    ClipboardData(text: _content(record)),
                  );
                  if (mounted) setState(() => _copied = true);
                },
          icon: Icon(_copied ? Icons.check : Icons.copy_outlined, size: 16),
          label: Text(
            _copied
                ? context.l10n.modelRequest_detailsCopied
                : context.l10n.modelRequest_detailsCopyPage,
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_close),
        ),
      ],
      child: SizedBox(
        width: double.infinity,
        height: math.max(
          120,
          math.min(610, MediaQuery.sizeOf(context).height - 245),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (record != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${record.provider} · ${record.model} · ${record.status.labelIn(context.l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ManagementTabs(
              labels: [
                context.l10n.modelRequest_detailsOverview,
                context.l10n.modelRequest_detailsRequests,
                context.l10n.modelRequest_detailsResponses,
              ],
              selected: _tab,
              onSelected: (value) => setState(() {
                _tab = value;
                _copied = false;
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: record == null
                  ? Center(
                      child: Text(context.l10n.modelRequest_detailsMissing),
                    )
                  : Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          key: ValueKey('request-details-scroll-$_tab'),
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _content(record),
                            key: const Key('request-details-content'),
                            style: StudioTypography.data.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                              height: 1.65,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
