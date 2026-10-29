import 'package:flutter/widgets.dart';
import 'package:collection/collection.dart';

import 'agent_contract.dart';

/// 侧栏内部共享：数据、操作，以及页面层的几个服务（执行并提示失败、改名弹窗、
/// 放大看图、往输入框插字、轻提示）。由 [AgentPanel] 提供。
class AgentScope extends InheritedModel<String> {
  const AgentScope({
    super.key,
    required super.child,
    required this.data,
    required this.actions,
    required this.slots,
    required this.run,
    required this.rename,
    required this.zoom,
    required this.insert,
    required this.toast,
    required this.confirm,
    required this.undoToast,
  });

  final AgentViewData data;
  final AgentActions actions;
  final AgentSlots slots;

  /// 执行一个返回 bool 的操作；false 或抛错时显示「操作没有完成」。
  final Future<void> Function(Future<bool> Function() action) run;

  /// 改名弹窗。
  final void Function({
    required String title,
    required String value,
    required Future<bool> Function(String value) save,
  })
  rename;

  /// 放大看图；[group] 给同一组的图时可以左右切换。
  final void Function(AgentImage image, {List<AgentImage>? group}) zoom;

  /// 往输入框光标处插入文字（快捷任务、`@` 引用、`/` 技能、欢迎页任务块）。
  /// [replace] 为 true 时替换整个输入框。
  final void Function(String text, {bool replace}) insert;

  /// 轻提示（「已复制」）。
  final void Function(String text) toast;

  /// 确认弹窗；[optOut] 非 null 时多一个「不再提醒」勾选框。
  /// 返回 null = 取消；否则 `(勾选了不再提醒)`。
  final Future<(bool,)?> Function({
    required String title,
    required String message,
    required String confirm,
    bool danger,
    String? optOut,
  })
  confirm;

  /// 带「撤销」的底部提示（约 6 秒），点撤销调 [onUndo]。
  final void Function(String text, Future<bool> Function() onUndo) undoToast;

  static AgentScope of(BuildContext context) =>
      InheritedModel.inheritFrom<AgentScope>(context)!;

  static AgentScope controlsOf(BuildContext context) =>
      InheritedModel.inheritFrom<AgentScope>(context, aspect: 'controls')!;

  static AgentScope composerOf(BuildContext context) =>
      InheritedModel.inheritFrom<AgentScope>(context, aspect: 'composer')!;

  List<Object?> get _composerKey => [
    data.chat.id,
    data.workspace.id,
    data.status,
    data.permission,
    data.composer.text,
    data.composer.canSend,
    data.composer.blocked,
    data.composer.importing,
    data.composer.canAttachCanvas,
    data.composer.enterSends,
    data.composer.suggestion,
    for (final a in data.composer.attachments)
      [
        a.id,
        a.name,
        a.image,
        a.width,
        a.height,
        a.metadata?.prompt,
        a.metadata?.characters,
      ],
    for (final q in data.composer.queue) [q.id, q.text, q.kind],
    data.notices,
    for (final m in data.models)
      [
        m.providerId,
        m.modelId,
        m.label,
        m.provider,
        m.selected,
        m.logoAsset,
        m.mark,
      ],
    data.thinking.options,
    data.thinking.selected,
    data.thinking.followsModel,
    for (final m in data.mentions) [m.id, m.kind, m.label, m.detail, m.image],
    for (final s in data.skills) [s.name, s.description],
    for (final c in data.slashCommands)
      [c.kind, c.name, c.description, c.argumentHint, c.source],
    actions.onSelectSlashCommand != null,
    actions.onAcceptSuggestion != null,
  ];

  @override
  bool updateShouldNotify(AgentScope old) =>
      data != old.data || actions != old.actions || slots != old.slots;

  @override
  bool updateShouldNotifyDependent(AgentScope old, Set<String> dependencies) {
    if (dependencies.contains('controls') &&
        (data.status != old.data.status ||
            data.chat.id != old.data.chat.id ||
            data.workspace.id != old.data.workspace.id)) {
      return true;
    }
    return dependencies.contains('composer') &&
        !const DeepCollectionEquality().equals(_composerKey, old._composerKey);
  }
}
