import 'package:flutter/widgets.dart';

/// 「新」角标的已见记录（E04）：首次出现的那次启动一直显示，下次启动起隐藏。
/// 存储由接线层实现；界面层只认这个接口。
abstract interface class UiNewBadgeStore {
  bool showNewBadge(String id);
  void markNewBadgeSeen(String id);
}

/// 由接线层挂在应用根部。没有挂时（夹具、单测）角标总是显示。
class UiNewBadges extends InheritedWidget {
  const UiNewBadges({super.key, required this.store, required super.child});

  final UiNewBadgeStore store;

  static UiNewBadgeStore? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UiNewBadges>()?.store;

  @override
  bool updateShouldNotify(UiNewBadges oldWidget) => store != oldWidget.store;
}

/// 给已有的 `badge:` 字符串参数用：入口真正呈现时调用（菜单打开时、面板构建时），
/// 已见记录在这一帧画完后才写，不在 build 里写存储。
String? uiNewBadge(BuildContext context, String id, String label) {
  final store = UiNewBadges.maybeOf(context);
  if (store == null) return label;
  if (!store.showNewBadge(id)) return null;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) store.markNewBadgeSeen(id);
  });
  return label;
}
