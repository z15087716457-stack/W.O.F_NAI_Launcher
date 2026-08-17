import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/services/personal_anlas_counter_service.dart';

/// 个人点数计数器芯片（合租账本）
///
/// 显示「订阅剩余+购买剩余」，点击打开管理对话框。
/// 与 [AnlasBalanceChip]（账户总余额）并排使用；负数时红字提示超支。
class PersonalAnlasChip extends ConsumerWidget {
  final bool compact;

  const PersonalAnlasChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(personalAnlasCounterProvider);
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    final overdrawn = counter.isOverdrawn;
    final textColor = overdrawn
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message:
          '我的点数：订阅 ${counter.subscriptionRemaining} + 购买 ${counter.purchasedRemaining}\n'
          '只统计本机生图消耗，点击管理合租账本',
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          showDialog<void>(
            context: context,
            builder: (_) => const PersonalAnlasDialog(),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: overdrawn
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: compact ? 14 : 16,
                color: overdrawn
                    ? theme.colorScheme.error
                    : theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${formatter.format(counter.subscriptionRemaining)}'
                '+${formatter.format(counter.purchasedRemaining)}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 个人点数管理对话框
class PersonalAnlasDialog extends ConsumerStatefulWidget {
  const PersonalAnlasDialog({super.key});

  @override
  ConsumerState<PersonalAnlasDialog> createState() =>
      _PersonalAnlasDialogState();
}

class _PersonalAnlasDialogState extends ConsumerState<PersonalAnlasDialog> {
  late final TextEditingController _subCtrl;
  late final TextEditingController _quotaCtrl;
  late final TextEditingController _resetDayCtrl;
  late final TextEditingController _purCtrl;
  late final TextEditingController _topUpCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(personalAnlasCounterProvider);
    _subCtrl = TextEditingController(text: '${s.subscriptionRemaining}');
    _quotaCtrl = TextEditingController(text: '${s.subscriptionQuota}');
    _resetDayCtrl = TextEditingController(
      text: s.resetDay == 0 ? '' : '${s.resetDay}',
    );
    _purCtrl = TextEditingController(text: '${s.purchasedRemaining}');
    _topUpCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _subCtrl.dispose();
    _quotaCtrl.dispose();
    _resetDayCtrl.dispose();
    _purCtrl.dispose();
    _topUpCtrl.dispose();
    super.dispose();
  }

  int? _readInt(TextEditingController ctrl) {
    final v = int.tryParse(ctrl.text.trim());
    return v;
  }

  Future<void> _save() async {
    final notifier = ref.read(personalAnlasCounterProvider.notifier);
    var resetDay = _readInt(_resetDayCtrl) ?? 0;
    if (resetDay < 0 || resetDay > 31) resetDay = 0;
    await notifier.updateSettings(
      subscriptionRemaining: _readInt(_subCtrl),
      purchasedRemaining: _readInt(_purCtrl),
      subscriptionQuota: _readInt(_quotaCtrl),
      resetDay: resetDay,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counter = ref.watch(personalAnlasCounterProvider);
    final notifier = ref.read(personalAnlasCounterProvider.notifier);
    final nextReset = notifier.nextResetDate();

    return AlertDialog(
      title: const Text('我的点数（合租账本）'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('订阅点数（每月重置，用不完也补回配额）',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildField(_subCtrl, '剩余')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_quotaCtrl, '配额')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_resetDayCtrl, '重置日')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    nextReset != null
                        ? '下次重置：${DateFormat('yyyy-MM-dd').format(nextReset)}'
                        : '重置日未设置（将按订阅到期时间自动推断）',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await notifier.resetSubscriptionNow();
                    if (!mounted) return;
                    setState(() {
                      _subCtrl.text =
                          '${ref.read(personalAnlasCounterProvider).subscriptionRemaining}';
                    });
                  },
                  child: const Text('立即补满'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('购买点数（手动充值，不重置）', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildField(_purCtrl, '剩余')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_topUpCtrl, '充值金额')),
                TextButton(
                  onPressed: () async {
                    final amount = _readInt(_topUpCtrl);
                    if (amount == null || amount == 0) return;
                    await notifier.addPurchased(amount);
                    if (!mounted) return;
                    setState(() {
                      _topUpCtrl.clear();
                      _purCtrl.text =
                          '${ref.read(personalAnlasCounterProvider).purchasedRemaining}';
                    });
                  },
                  child: const Text('加入'),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              '当前合计：${counter.totalRemaining}'
              '${counter.isOverdrawn ? '（已超支）' : ''}\n'
              '只统计本机生图消耗（含桥接），按界面显示单价扣减：\n先扣订阅、再扣购买。朋友的消耗不影响此账本。\n重置日留空=按订阅到期时间自动推断。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
