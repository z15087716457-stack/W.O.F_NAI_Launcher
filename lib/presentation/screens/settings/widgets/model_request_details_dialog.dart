import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../prompt_assistant/providers/model_request_history_provider.dart';
import '../../../themes/studio_typography.dart';
import 'model_management_widgets.dart';
import 'settings_dialog.dart';

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
  String _content(ModelRequestRecord record) =>
      const JsonEncoder.withIndent('  ').convert(switch (_tab) {
        0 => record.overview,
        1 => {
          '请求': [
            for (var i = 0; i < record.exchanges.length; i++)
              {'序号': i + 1, ...record.exchanges[i].request},
          ],
        },
        _ => {
          '响应': [
            for (var i = 0; i < record.exchanges.length; i++)
              {'序号': i + 1, ...record.exchanges[i].response},
          ],
          if (record.output != null) '提取结果': record.output,
          if (record.error != null) '错误': record.error,
        },
      });
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(modelRequestHistoryProvider);
    final record = history.records
        .where((r) => r.id == widget.recordId)
        .firstOrNull;
    final theme = Theme.of(context);
    return SettingsDialogFrame(
      title: record?.task ?? '请求记录',
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
          label: Text(_copied ? '已复制' : '复制当前页'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
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
                  '${record.provider} · ${record.model} · ${record.status}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ManagementTabs(
              labels: const ['概览', '请求', '响应'],
              selected: _tab,
              onSelected: (value) => setState(() {
                _tab = value;
                _copied = false;
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: record == null
                  ? const Center(child: Text('此记录已清空或已超出最近 100 条。'))
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
