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
                size: compact ? 15 : 16,
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
                  fontSize: compact ? 13 : 14,
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
  late final TextEditingController _shareCtrl;
  late final TextEditingController _refillShareCtrl;
  late final TextEditingController _allowanceCtrl;

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
    _shareCtrl = TextEditingController(text: _fmt(s.opusShareRatio * 100));
    _refillShareCtrl = TextEditingController(
      text: _fmt(s.opusRefillShare * 100),
    );
    _allowanceCtrl = TextEditingController(text: _fmt(s.opusAllowance));
  }

  @override
  void dispose() {
    _subCtrl.dispose();
    _quotaCtrl.dispose();
    _resetDayCtrl.dispose();
    _purCtrl.dispose();
    _topUpCtrl.dispose();
    _shareCtrl.dispose();
    _refillShareCtrl.dispose();
    _allowanceCtrl.dispose();
    super.dispose();
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(2);
  }

  int? _readInt(TextEditingController ctrl) {
    final v = int.tryParse(ctrl.text.trim());
    return v;
  }

  double? _readDouble(TextEditingController ctrl) {
    return double.tryParse(ctrl.text.trim());
  }

  /// 把额度相关输入框刷成 state 的当前值（份额/平分/补满之后调用）
  void _syncOpusFields() {
    final s = ref.read(personalAnlasCounterProvider);
    _shareCtrl.text = _fmt(s.opusShareRatio * 100);
    _refillShareCtrl.text = _fmt(s.opusRefillShare * 100);
    _allowanceCtrl.text = _fmt(s.opusAllowance);
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

    final sharePercent = _readDouble(_shareCtrl);
    final refillPercent = _readDouble(_refillShareCtrl);
    await notifier.updateOpusSettings(
      shareRatio: sharePercent == null ? null : sharePercent / 100,
      refillShare: refillPercent == null ? null : refillPercent / 100,
      allowance: _readDouble(_allowanceCtrl),
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
              'V5 免费额度份额（Opus，百分比池）',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildField(_allowanceCtrl, '我的剩余 %')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_shareCtrl, '份额上限 %')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_refillShareCtrl, '新增分成 %')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '我的份额剩 ${counter.opusAllowance.toStringAsFixed(1)}%'
                    '／上限 ${counter.opusAllowanceCap.toStringAsFixed(0)}%'
                    '${counter.isOpusAllowanceExhausted ? '（已用尽，转 Anlas 计价）' : ''}\n'
                    '账号当前额度 '
                    '${counter.lastObservedPoolPercent == null ? '未观测' : '${counter.lastObservedPoolPercent!.toStringAsFixed(1)}%'}'
                    '：回充按服务端回充时钟入账，跌了按实测扣',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final people = await _askPeopleCount(context);
                        if (people == null) return;
                        await notifier.splitOpusAllowance(people);
                        if (!mounted) return;
                        setState(_syncOpusFields);
                      },
                      child: const Text('平分'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await notifier.refillOpusAllowanceNow();
                        if (!mounted) return;
                        setState(_syncOpusFields);
                      },
                      child: const Text('补满份额'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              '当前合计：${counter.totalRemaining}'
              '${counter.isOverdrawn ? '（已超支）' : ''}\n'
              '只统计本机生图消耗（含桥接），按界面显示单价扣减：\n先扣订阅、再扣购买。朋友的消耗不影响此账本。\n重置日留空=按订阅到期时间自动推断。\n'
              'V5 免费额度是账号级共享池，这里记的是「我的份额」：\n'
              '回充按服务端回充时钟（timeUntilNextPercent）入账分成；\n'
              '异常涨幅按分成入账并抬高池顶（上限=池顶×份额，池子可超 100%）；\n'
              '跌幅只认本机在途生成的实测值；离线超 10 分钟回退纯实测涨跌结算。',
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

  /// 问「几个人平分」，返回 null＝取消
  Future<int?> _askPeopleCount(BuildContext context) async {
    var people = 2;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('平分免费额度'),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('合租人数（含我自己）：'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: people > 1
                        ? () => setLocal(() => people--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$people 人', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    onPressed: people < 20
                        ? () => setLocal(() => people++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '份额上限与回充分成都设为 ${(100 / people).toStringAsFixed(1)}%',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(people),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
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
