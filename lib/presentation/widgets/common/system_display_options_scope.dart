import 'package:flutter/widgets.dart';

import '../../../core/services/mac_display_options.dart';

/// 把 macOS 的「减少动态效果」并进 `MediaQuery.disableAnimations`（应用里所有
/// “系统减少动态效果时停动画”的判断都读它，Windows 上它本来就跟系统），「降低透明度」
/// 交给磨砂表面读（[reduceTransparencyOf]）。放在 runApp 根部、MaterialApp 外面。
///
/// 其他平台原样透传，树的结构不分平台。
class SystemDisplayOptionsScope extends StatefulWidget {
  const SystemDisplayOptionsScope({
    super.key,
    required this.child,
    this.source,
  });

  final Widget child;

  /// 默认 [MacDisplayOptions.instance]；测试传自己的。
  final MacDisplayOptions? source;

  /// 系统开了「降低透明度」：磨砂（背景模糊）改成实底。没有这一层时为 false。
  static bool reduceTransparencyOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DisplayOptions>()
          ?.options
          .reduceTransparency ??
      false;

  @override
  State<SystemDisplayOptionsScope> createState() =>
      _SystemDisplayOptionsScopeState();
}

class _SystemDisplayOptionsScopeState extends State<SystemDisplayOptionsScope> {
  MacDisplayOptions get _source => widget.source ?? MacDisplayOptions.instance;

  @override
  void initState() {
    super.initState();
    _source.attach();
  }

  @override
  void didUpdateWidget(SystemDisplayOptionsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _source.attach();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<SystemDisplayOptions>(
        valueListenable: _source,
        builder: (context, options, child) {
          final inherited = _DisplayOptions(options: options, child: child!);
          final media = MediaQuery.maybeOf(context);
          if (media == null) return inherited;
          return MediaQuery(
            data: options.reduceMotion && !media.disableAnimations
                ? media.copyWith(disableAnimations: true)
                : media,
            child: inherited,
          );
        },
        child: widget.child,
      );
}

class _DisplayOptions extends InheritedWidget {
  const _DisplayOptions({required this.options, required super.child});

  final SystemDisplayOptions options;

  @override
  bool updateShouldNotify(_DisplayOptions oldWidget) =>
      options != oldWidget.options;
}
