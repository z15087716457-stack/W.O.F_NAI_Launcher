import 'package:flutter/widgets.dart';

import 'agent_contract.dart';

/// 侧栏内部共享：数据、操作，以及页面层的几个服务（执行并提示失败、改名弹窗、
/// 放大看图、往输入框插字、轻提示）。由 [AgentPanel] 提供。
class AgentScope extends InheritedWidget {
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

  /// 放大看图。
  final void Function(AgentImage image) zoom;

  /// 往输入框光标处插入文字（快捷任务、`@` 引用、`/` 技能、欢迎页任务块）。
  /// [replace] 为 true 时替换整个输入框。
  final void Function(String text, {bool replace}) insert;

  /// 轻提示（「已复制」）。
  final void Function(String text) toast;

  static AgentScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AgentScope>()!;

  @override
  bool updateShouldNotify(AgentScope old) =>
      data != old.data || actions != old.actions || slots != old.slots;
}
