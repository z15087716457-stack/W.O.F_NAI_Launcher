import 'package:flutter/widgets.dart';

import '../../../core/services/app_visibility.dart';

/// 放在每个 runApp 的根部：窗口看不见时（藏到托盘 / 菜单栏、最小化、被完全挡住，见
/// [AppVisibility]）用 [TickerMode] 停掉整个应用的动画，看得见时恢复。
///
/// 自己按定时器走的动画（视觉通道每秒一次的微动、登录页字符场）读
/// `TickerMode.valuesOf`，也跟着停。这一层还负责把 [AppVisibilitySources] 接上，
/// 并把指针事件当成“窗口看得见”的信号（[AppVisibilitySources.noteInput]）。
class AppVisibilityScope extends StatefulWidget {
  const AppVisibilityScope({super.key, required this.child, this.sources});

  final Widget child;

  /// 默认 [AppVisibilitySources.instance]；测试传自己的。
  final AppVisibilitySources? sources;

  @override
  State<AppVisibilityScope> createState() => _AppVisibilityScopeState();
}

class _AppVisibilityScopeState extends State<AppVisibilityScope> {
  AppVisibilitySources get _sources =>
      widget.sources ?? AppVisibilitySources.instance;

  @override
  void initState() {
    super.initState();
    _sources.attach();
  }

  @override
  void didUpdateWidget(AppVisibilityScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sources != widget.sources) _sources.attach();
  }

  void _seen(PointerEvent _) => _sources.noteInput();

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _seen,
    onPointerHover: _seen,
    onPointerSignal: _seen,
    child: ListenableBuilder(
      listenable: AppVisibility.instance,
      builder: (context, child) =>
          TickerMode(enabled: AppVisibility.instance.isVisible, child: child!),
      child: widget.child,
    ),
  );
}
