import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../settings/settings_kit.dart';
import 'model_providers_contract.dart';
import 'model_providers_kit.dart';

/// 添加服务商：按分组的预设卡片网格，可搜索 / 筛选。铺满面板，点遮罩或 Esc 关闭。
class ProvidersPicker extends StatefulWidget {
  const ProvidersPicker({
    super.key,
    required this.presets,
    required this.existing,
    required this.onPick,
    required this.onCancelSignIn,
    required this.onClose,
  });

  final List<ProviderPresetItem> presets;

  /// 已添加过的预设 id（卡片标“已添加”，仍可再加）。
  final Set<String> existing;
  final Future<bool> Function(String id, {required bool waitForSignIn}) onPick;
  final VoidCallback onCancelSignIn;
  final VoidCallback onClose;

  @override
  State<ProvidersPicker> createState() => _ProvidersPickerState();
}

class _ProvidersPickerState extends State<ProvidersPicker> {
  var _q = '';
  ProviderGroup? _group;
  String? _sel, _failedPreset;
  bool _signingIn = false;

  Future<void> _pick(ProviderPresetItem preset) async {
    if (_signingIn) return;
    final signIn = preset.browserSignIn && !widget.existing.contains(preset.id);
    if (signIn) {
      setState(() {
        _signingIn = true;
        _failedPreset = null;
      });
    }
    final added = await widget.onPick(preset.id, waitForSignIn: signIn);
    if (signIn && mounted) {
      setState(() {
        _signingIn = false;
        if (!added) _failedPreset = preset.id;
      });
    }
  }

  void _close() {
    if (_signingIn) widget.onCancelSignIn();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final q = _q.toLowerCase();
    final shown = [
      for (final p in widget.presets)
        if ((_group == null || p.group == _group) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.host.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q)))
          p,
    ];
    final sel =
        shown.where((p) => p.id == _sel).firstOrNull ?? shown.firstOrNull;
    final account = sel?.browserSignIn == true;
    final alreadyAdded = widget.existing.contains(sel?.id);
    String groupName(ProviderGroup g) => switch (g) {
      ProviderGroup.domestic => l.mp_groupDomesticFull,
      ProviderGroup.international => l.mp_groupInternationalFull,
      ProviderGroup.aggregator => l.mp_groupAggregatorFull,
      ProviderGroup.local => l.mp_groupLocalFull,
    };
    Widget card(ProviderPresetItem p) => UiPressable(
      key: Key('mp-preset-${p.id}'),
      onTap: () => setState(() => _sel = p.id),
      builder: (context, hover) {
        final on = p.id == sel?.id;
        return GestureDetector(
          onDoubleTap: () => _pick(p),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: hover && !on ? c.sunk : c.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: on ? c.accent : (hover ? c.strong : c.border),
              ),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: .13),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              spacing: 10,
              children: [
                ProviderLogo(
                  logoAsset: p.logoAsset,
                  dashed: p.custom,
                  size: 32,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        p.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: p.custom || p.browserSignIn
                            ? UiText.sans(11, color: c.faint)
                            : UiText.mono(11, color: c.faint),
                      ),
                    ],
                  ),
                ),
                if (widget.existing.contains(p.id)) UiMini(l.mp_added),
              ],
            ),
          ),
        );
      },
    );

    final groups = [
      for (final g in ProviderGroup.values)
        if (shown.any((p) => p.group == g)) g,
    ];
    final body = shown.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              l.modelProvider_pickerEmpty,
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, color: c.muted),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    groupName(g),
                    style: UiText.sans(
                      11,
                      weight: FontWeight.w500,
                      color: c.faint,
                      letterSpacing: .44,
                    ),
                  ),
                ),
                SettingsGrid(
                  columns: 3,
                  gap: 8,
                  minItem: 200,
                  children: [
                    for (final p in shown)
                      if (p.group == g) card(p),
                  ],
                ),
              ],
            ],
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (sel != null) _pick(sel);
        },
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('mp-picker-scrim'),
              onTap: _close,
              child: ColoredBox(
                color: c.dark
                    ? const Color(0x80000000)
                    : const Color(0x380A0A0A),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                key: const Key('mp-picker'),
                width: 820,
                constraints: const BoxConstraints(maxHeight: 640),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 80,
                      offset: Offset(0, 30),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.mp_pickerTitle,
                              style: UiText.sans(
                                15,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          SettingsIconBtn(
                            key: const Key('mp-picker-close'),
                            glyph: UiGlyphs.close,
                            tooltip: l.set_cancel,
                            glyphSize: 16,
                            onTap: _close,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: Focus(
                              autofocus: true,
                              child: UiSearchField(
                                key: const Key('mp-picker-search'),
                                value: _q,
                                hint: l.mp_pickerSearch,
                                height: 32,
                                onChanged: (v) => setState(() {
                                  _q = v;
                                  _sel = null;
                                }),
                              ),
                            ),
                          ),
                          UiSeg<ProviderGroup?>(
                            key: const Key('mp-picker-group'),
                            values: const [null, ...ProviderGroup.values],
                            selected: _group,
                            labelOf: (g) => switch (g) {
                              null => l.mp_groupAll,
                              ProviderGroup.domestic => l.mp_groupDomestic,
                              ProviderGroup.international =>
                                l.mp_groupInternational,
                              ProviderGroup.aggregator => l.mp_groupAggregator,
                              ProviderGroup.local => l.mp_groupLocal,
                            },
                            onChanged: (g) => setState(() {
                              _group = g;
                              _sel = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: body,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.rowLine)),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: Text(
                              _signingIn
                                  ? l.naiAgent_chatGptBrowser
                                  : _failedPreset != null &&
                                        _failedPreset == sel?.id
                                  ? l.naiAgent_chatGptError
                                  : account
                                  ? l.naiAgent_chatGptHint
                                  : l.mp_pickerFoot,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(12, color: c.muted),
                            ),
                          ),
                          SettingsBtn(
                            label: l.set_cancel,
                            small: true,
                            tone: SettingsBtnTone.ghost,
                            onTap: _close,
                          ),
                          SettingsBtn(
                            key: const Key('mp-picker-next'),
                            label: !account
                                ? l.mp_pickerNext
                                : alreadyAdded
                                ? l.mp_manageAccount
                                : l.naiAgent_chatGptSignIn,
                            small: true,
                            tone: SettingsBtnTone.primary,
                            onTap: sel == null || _signingIn
                                ? null
                                : () => _pick(sel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
