import 'package:flutter/widgets.dart';

import 'resource_window_contract.dart';

/// E05 独立资源窗口的整页（主控负责视觉，按原型 `.devin/mockups/d04-window/`）。
/// 外层由子窗口入口提供 MaterialApp（主题、本地化、字体）。
class ResourceWindowPage extends StatelessWidget {
  const ResourceWindowPage({
    super.key,
    required this.data,
    required this.actions,
  });

  final ResourceWindowViewData data;
  final ResourceWindowActions actions;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
