import 'package:flutter/material.dart';

import 'comfyui_settings_section.dart';
import 'krita_bridge_settings_section.dart';
import 'network_settings_section.dart';
import '../widgets/model_management_widgets.dart';
import '../../../../core/utils/localization_extension.dart';

/// 集成设置板块
///
/// 汇总外部工具集成（ComfyUI / Krita）。
/// 顶部子导航切换，一次只渲染一个面板，避免长滚动页。
class IntegrationsSettingsSection extends StatefulWidget {
  /// 测试注入用面板构造器；非 null 时必须恰好包含两个构造器。
  ///
  /// 生产环境保持 null 使用默认三面板。
  @visibleForTesting
  final List<WidgetBuilder>? panelBuilders;

  final bool initialNetwork;
  final int? initialTab;
  const IntegrationsSettingsSection({
    super.key,
    this.panelBuilders,
    this.initialNetwork = false,
    this.initialTab,
  }) : assert(
         panelBuilders == null || panelBuilders.length == 2,
         'panelBuilders must contain exactly two builders.',
       );

  @override
  State<IntegrationsSettingsSection> createState() =>
      _IntegrationsSettingsSectionState();
}

class _IntegrationsSettingsSectionState
    extends State<IntegrationsSettingsSection> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null && widget.panelBuilders == null) {
      _selectedIndex = widget.initialTab!;
      return;
    }
    if (widget.initialNetwork && widget.panelBuilders == null) {
      _selectedIndex = 2;
    }
  }

  @override
  void didUpdateWidget(covariant IntegrationsSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null &&
        widget.panelBuilders == null) {
      _selectedIndex = widget.initialTab!;
      return;
    }
    if (oldWidget.initialNetwork != widget.initialNetwork &&
        widget.panelBuilders == null) {
      _selectedIndex = widget.initialNetwork ? 2 : 0;
    }
  }

  List<WidgetBuilder> get _builders =>
      widget.panelBuilders ??
      [
        (_) => const ComfyUISettingsSection(),
        (_) => const KritaBridgeSettingsSection(),
        (_) => const NetworkSettingsSection(),
      ];

  @override
  Widget build(BuildContext context) {
    final labels = [
      'ComfyUI',
      'Krita',
      if (widget.panelBuilders == null) context.l10n.settings_network,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ManagementTabs(
            labels: labels,
            selected: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
        ),
        _builders[_selectedIndex](context),
      ],
    );
  }
}
