import 'package:flutter/widgets.dart';

import 'app_visibility_scope.dart';
import 'system_display_options_scope.dart';

/// 每个 runApp 的根部都套这一层（启动页、主界面、首启导入、启动失败页），放和窗口、
/// 系统设置有关、要管到整个应用的东西：
/// - 窗口看不见时停掉全部动画（[AppVisibilityScope]）；
/// - macOS 的「减少动态效果」「降低透明度」（[SystemDisplayOptionsScope]）。
class StudioRootScope extends StatelessWidget {
  const StudioRootScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppVisibilityScope(child: SystemDisplayOptionsScope(child: child));
}
