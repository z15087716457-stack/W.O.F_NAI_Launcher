import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import 'settings_contract.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_scope.dart';

/// 按 [SettingKey] 读写的控件：值来自 [SettingsViewData.values]，改动走 [SettingsActions.onChanged]。

/// 绑定一个标量设置的行：自动画“已修改”蓝点、悬停恢复默认、“需重启”标签，并能被搜索跳转高亮。
class SettingKeyRow extends StatelessWidget {
  const SettingKeyRow(
    this.setting, {
    super.key,
    required this.title,
    this.subtitle,
    this.control,
    this.sub = false,
    this.disabled = false,
    this.badges = const [],
    this.below,
    this.padding,
  });

  final SettingKey setting;
  final String title;
  final String? subtitle;
  final Widget? control;
  final bool sub;
  final bool disabled;
  final List<Widget> badges;
  final Widget? below;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final modified = s.data.modified.contains(setting);
    return SettingsRow(
      key: Key('setting-${setting.name}'),
      anchor: setting.name,
      title: title,
      subtitle: subtitle,
      sub: sub,
      disabled: disabled,
      modified: modified,
      onReset: () => s.actions.onReset(setting),
      badges: [
        ...badges,
        if (SettingSpec.of(setting).restart && !sub)
          SettingsMini(context.l10n.set_needsRestart, tone: UiMiniTone.warn),
      ],
      control: control,
      below: below,
      padding: padding,
    );
  }
}

class SetSwitch extends StatelessWidget {
  const SetSwitch(this.setting, {super.key});
  final SettingKey setting;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return SettingsSwitch(
      key: Key('switch-${setting.name}'),
      value: s.data.values.flag(setting),
      onChanged: (v) => s.actions.onChanged(setting, v),
    );
  }
}

class SetSeg extends StatelessWidget {
  const SetSeg(this.setting, {super.key, this.values});
  final SettingKey setting;

  /// 默认用 [SettingSpec.choices]。
  final List<String>? values;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final values = this.values ?? SettingSpec.of(setting).choices;
    final current = s.data.values.text(setting) ?? values.first;
    return UiSegmented<String>(
      key: Key('seg-${setting.name}'),
      values: values,
      selected: current,
      labelOf: (v) => SettingsFormat.choice(context, setting, v),
      onChanged: (v) => s.actions.onChanged(setting, v),
    );
  }
}

class SetStepper extends StatelessWidget {
  const SetStepper(this.setting, {super.key, this.unit, this.decimals = 0});
  final SettingKey setting;
  final String? unit;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final spec = SettingSpec.of(setting);
    return SettingsStepper(
      key: Key('stepper-${setting.name}'),
      value: s.data.values.number(setting),
      min: spec.min,
      max: s.data.numberMax(setting),
      step: spec.step,
      unit: unit,
      decimals: decimals,
      onChanged: (v) => s.actions.onChanged(setting, v),
    );
  }
}

class SetSlider extends StatelessWidget {
  const SetSlider(
    this.setting, {
    super.key,
    required this.label,
    this.width = 160,
    this.ticks = 0,
  });

  final SettingKey setting;
  final String Function(double v) label;
  final double width;
  final int ticks;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final spec = SettingSpec.of(setting);
    return SettingsSlider(
      key: Key('slider-${setting.name}'),
      value: s.data.values.number(setting),
      min: spec.min,
      max: s.data.numberMax(setting),
      step: spec.step,
      width: width,
      ticks: ticks,
      label: label,
      onChanged: (v) => s.actions.onChanged(setting, v),
    );
  }
}

class SetSelect extends StatelessWidget {
  const SetSelect(this.setting, {super.key, this.width = 180, this.leading});
  final SettingKey setting;
  final double width;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final spec = SettingSpec.of(setting);
    final options =
        s.data.options[setting] ??
        [
          for (final v in spec.choices)
            SettingsOption(
              value: v,
              label: SettingsFormat.choice(context, setting, v),
            ),
        ];
    final current = s.data.values.text(setting);
    final label = options
        .where((o) => o.value == current)
        .map((o) => o.label)
        .firstOrNull;
    return SettingsSelect(
      key: Key('select-${setting.name}'),
      width: width,
      leading: leading,
      label: label ?? context.l10n.set_notSet,
      options: options,
      selected: current,
      onSelected: (v) => s.actions.onChanged(setting, v),
    );
  }
}

class SetText extends StatelessWidget {
  const SetText(
    this.setting, {
    super.key,
    this.width = 240,
    this.mono = true,
    this.hint,
  });

  final SettingKey setting;
  final double width;
  final bool mono;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return SettingsInput(
      key: Key('input-${setting.name}'),
      width: width,
      mono: mono,
      hint: hint,
      value: s.data.values.text(setting) ?? '',
      onSubmitted: (v) => s.actions.onChanged(setting, v.trim()),
    );
  }
}

/// 路径设置：路径框 + 选择 / 打开 / 恢复默认（已修改时）。null 显示“默认位置”标签。
class SetPath extends StatelessWidget {
  const SetPath(
    this.setting, {
    super.key,
    this.width = 380,
    this.defaultPath,
    this.defaultTag,
    this.open = true,
  });

  final SettingKey setting;
  final double width;

  /// 值为 null 时显示的默认路径（例如 `%APPDATA%\nai_launcher\hive`）。
  final String? defaultPath;

  /// 值为 null 时路径框右侧的标签，默认“默认”；空串 = 不显示。
  final String? defaultTag;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final l = context.l10n;
    final value = s.data.values.text(setting);
    return SizedBox(
      width: width,
      child: SettingsPathBox(
        key: Key('path-${setting.name}'),
        path: value ?? defaultPath ?? l.set_defaultLocation,
        tag: value != null || defaultTag == ''
            ? null
            : defaultTag ?? l.set_defaultTag,
        actions: [
          SettingsIconBtn(
            glyph: SettingsGlyphs.folder,
            tooltip: l.set_change,
            onTap: () => s.actions.onPickPath(setting),
          ),
          if (open)
            SettingsIconBtn(
              glyph: SettingsGlyphs.external,
              tooltip: l.set_open,
              onTap: () => s.actions.onOpenPath(setting),
            ),
        ],
      ),
    );
  }
}

/// 一行里的弱色读数 + 跳转按钮（“DeepSeek-V3  模型与接口 ›”）。
class SettingsJump extends StatelessWidget {
  const SettingsJump({super.key, required this.page, this.label, this.value});

  final SettingsPageId page;
  final String? label;
  final Widget? value;

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ?value,
        SettingsBtn(
          key: Key('jump-${page.name}'),
          label: label ?? SettingsFormat.page(context, page),
          small: true,
          tone: SettingsBtnTone.ghost,
          trailingChevron: true,
          onTap: () => s.actions.onOpenPage(page),
        ),
      ],
    );
  }
}

/// 点“...”弹出的小菜单（复用 kit 菜单）。
class SettingsMoreButton extends StatelessWidget {
  const SettingsMoreButton({
    super.key,
    required this.items,
    this.tooltip,
    this.enabled = true,
  });
  final List<(String, VoidCallback, bool)> items;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SettingsMenuButton(
    tooltip: tooltip ?? context.l10n.set_more,
    glyph: UiGlyphs.more,
    items: items,
    enabled: enabled,
  );
}

class SettingsMenuButton extends StatefulWidget {
  const SettingsMenuButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.items,
    this.enabled = true,
  });

  final String glyph;
  final String tooltip;
  final bool enabled;

  /// (文字, 点击, 是否危险)。危险项前面画分隔线。
  final List<(String, VoidCallback, bool)> items;

  @override
  State<SettingsMenuButton> createState() => _SettingsMenuButtonState();
}

class _SettingsMenuButtonState extends State<SettingsMenuButton> {
  bool _open = false;

  @override
  void didUpdateWidget(SettingsMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _open = false;
  }

  @override
  Widget build(BuildContext context) => SettingsPopupMenu(
    open: _open,
    onClose: () => setState(() => _open = false),
    items: widget.items,
    child: SettingsIconBtn(
      glyph: widget.glyph,
      tooltip: widget.tooltip,
      glyphSize: 15,
      onTap: widget.enabled ? () => setState(() => _open = true) : null,
    ),
  );
}
