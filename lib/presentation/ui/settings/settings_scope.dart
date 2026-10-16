import 'package:flutter/widgets.dart';

import 'settings_contract.dart';

/// 设置页内部共享：数据、回调、当前要高亮的行、确认框入口。
class SettingsScope extends InheritedWidget {
  const SettingsScope({
    super.key,
    required this.data,
    required this.actions,
    required this.highlight,
    required this.confirm,
    required this.jump,
    required this.reportDirty,
    required super.child,
  });

  /// 跳到某页并高亮某一行（概览卡片、侧注链接用）。
  final void Function(SettingsPageId page, {String? anchor}) jump;

  /// 页面有未保存的长文本草稿（Agent 指令）：切页前先确认。
  final ValueChanged<bool> reportDirty;

  final SettingsViewData data;
  final SettingsActions actions;

  /// 搜索跳转后要高亮的行（[SettingsRow.anchor]）。
  final String? highlight;

  /// 弹确认框：标题、正文、确认按钮文字、是否危险操作、确认后执行。
  final void Function({
    required String title,
    required String body,
    required String confirm,
    bool danger,
    required VoidCallback onConfirm,
  })
  confirm;

  static SettingsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!;

  static SettingsScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>();

  @override
  bool updateShouldNotify(SettingsScope old) =>
      data != old.data || actions != old.actions || highlight != old.highlight;
}
