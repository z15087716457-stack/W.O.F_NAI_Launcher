import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../settings/settings_contract.dart' show SettingsOption, SettingsTone;
import '../settings/settings_format.dart';
import '../settings/settings_kit.dart';
import '../settings/settings_controls.dart' show SettingsMoreButton;
import 'model_providers_contract.dart';
import 'model_providers_controller.dart';
import 'model_providers_kit.dart';

/// 右栏模型检查器：一个模型的全部参数（原“高级请求参数”里的模型项）。
class ProvidersInspector extends StatelessWidget {
  const ProvidersInspector({
    super.key,
    required this.item,
    required this.model,
    required this.protocol,
    required this.onEdit,
    required this.onTest,
    required this.onRemove,
  });

  final ProviderItem item;
  final ProviderModelSettings model;
  final ProvidersProtocol? protocol;
  final void Function(ProviderModelSettings Function(ProviderModelSettings))
  onEdit;
  final VoidCallback onTest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final m = model;
    final info = item.info(m.id);
    final all = protocol?.reasoningLevels ?? const <String>[];
    final levels = m.reasoningLevels ?? const <String>[];

    Widget section(
      String? glyph,
      String? title,
      List<Widget> children, {
      bool last = false,
      Key? key,
    }) => Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.rowLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (title != null)
            Row(
              spacing: 6,
              children: [
                UiGlyph(glyph!, size: 13, color: c.faint),
                Text(
                  title,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
              ],
            ),
          ...children,
        ],
      ),
    );

    final header = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(bottom: BorderSide(color: c.rowLine)),
      ),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.mp_model, style: UiText.sans(11, color: c.faint)),
                Text(
                  m.id,
                  key: const Key('mp-insp-id'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(13, weight: FontWeight.w500, color: c.ink),
                ),
              ],
            ),
          ),
          SettingsMoreButton(
            key: const Key('mp-insp-more'),
            items: [
              (l.mp_copyId, () => providersCopy(m.id), false),
              (l.mp_removeModel, onRemove, true),
            ],
          ),
        ],
      ),
    );

    final basics = section(null, null, [
      ProviderField(
        label: l.mp_alias,
        child: ProviderInput(
          key: const Key('mp-alias'),
          value: m.alias,
          hint: info.detail.isNotEmpty ? info.detail : l.mp_aliasHint,
          onChanged: (v) => onEdit((x) => x.copyWith(alias: v)),
        ),
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ProviderField(
            label: l.mp_context,
            child: ProviderNumBox(
              key: const Key('mp-ctx'),
              value: m.contextWindow,
              min: 1000,
              max: 10000000,
              format: providerTokens,
              parse: providerParseTokens,
              onChanged: (v) => onEdit(
                (x) =>
                    x.copyWith(contextWindow: v, clearContextWindow: v == null),
              ),
            ),
          ),
          ProviderField(
            label: l.mp_maxOutput,
            error: ProvidersValidate.outputTooLarge(m)
                ? l.mp_outputTooLarge
                : null,
            child: ProviderNumBox(
              key: const Key('mp-out'),
              value: m.maxOutput,
              min: 256,
              max: 10000000,
              format: providerTokens,
              parse: providerParseTokens,
              error: ProvidersValidate.outputTooLarge(m),
              onChanged: (v) => onEdit(
                (x) => x.copyWith(maxOutput: v, clearMaxOutput: v == null),
              ),
            ),
          ),
        ],
      ),
    ]);

    final thinking = section(ProvidersGlyphs.bulb, l.mp_thinking, [
      if (all.isEmpty)
        Text(l.mp_protocolNoReasoning, style: UiText.sans(12, color: c.faint))
      else ...[
        ProviderField(
          label: l.mp_levels,
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              key: const Key('mp-levels'),
              spacing: 4,
              runSpacing: 6,
              children: [
                for (final lv in all)
                  ProviderToggle(
                    key: Key('mp-level-$lv'),
                    label: providerLevelLabel(context, lv),
                    on: levels.contains(lv),
                    accent: true,
                    height: 24,
                    badge: m.effectiveDefault == lv ? l.mp_defaultBadge : null,
                    onTap: () => onEdit((x) {
                      final cur = [...?x.reasoningLevels];
                      cur.contains(lv) ? cur.remove(lv) : cur.add(lv);
                      final ordered = [
                        for (final a in all)
                          if (cur.contains(a)) a,
                      ];
                      return x.copyWith(
                        reasoningLevels: ordered,
                        clearDefaultLevel:
                            x.defaultLevel != null &&
                            !ordered.contains(x.defaultLevel),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ProviderField(
              label: l.mp_defaultLevel,
              child: SettingsSelect(
                key: const Key('mp-default-level'),
                width: 130,
                label: levels.isEmpty
                    ? (m.reasoningLevels == null
                          ? l.mp_unconfirmed
                          : l.mp_unsupported)
                    : providerLevelLabel(context, m.effectiveDefault),
                leading: UiGlyph(
                  ProvidersGlyphs.bulb,
                  size: 13,
                  color: c.faint,
                ),
                selected: m.effectiveDefault ?? '',
                options: [
                  if (levels.isNotEmpty)
                    SettingsOption(value: '', label: l.mp_followService),
                  for (final lv in levels)
                    SettingsOption(
                      value: lv,
                      label: providerLevelLabel(context, lv),
                    ),
                ],
                onSelected: (v) => onEdit(
                  (x) => v.isEmpty
                      ? x.copyWith(clearDefaultLevel: true)
                      : x.copyWith(defaultLevel: v),
                ),
              ),
            ),
            ProviderField(
              label: l.mp_reasoningProtocol,
              child: UiSeg<bool>(
                key: const Key('mp-adaptive'),
                values: const [false, true],
                selected: m.adaptiveReasoning,
                labelOf: (v) => v ? l.mp_adaptive : l.mp_standard,
                onChanged: (v) =>
                    onEdit((x) => x.copyWith(adaptiveReasoning: v)),
              ),
            ),
          ],
        ),
      ],
    ]);

    Widget sampler(
      String key,
      String label,
      double? value,
      double max,
      double fallback,
      ProviderModelSettings Function(ProviderModelSettings, double?) set,
    ) => ProviderField(
      label: label,
      child: SizedBox(
        height: 22,
        child: Row(
          spacing: 10,
          children: [
            UiPressable(
              key: Key('mp-$key-on'),
              onTap: () =>
                  onEdit((x) => set(x, value == null ? fallback : null)),
              builder: (context, _) => UiCheckBox(value: value != null),
            ),
            if (value == null)
              Text(l.mp_followDefault, style: UiText.sans(12, color: c.muted))
            else
              SettingsSlider(
                key: Key('mp-$key'),
                value: value,
                min: 0,
                max: max,
                step: .05,
                width: 132,
                label: (v) => v.toStringAsFixed(2),
                onChanged: (v) => onEdit((x) => set(x, v)),
              ),
          ],
        ),
      ),
    );

    final sampling = section(ProvidersGlyphs.sliders, l.mp_sampling, [
      sampler(
        'temp',
        l.mp_temperature,
        m.temperature,
        2,
        1,
        (x, v) => x.copyWith(temperature: v, clearTemperature: v == null),
      ),
      sampler(
        'topp',
        l.mp_topP,
        m.topP,
        1,
        1,
        (x, v) => x.copyWith(topP: v, clearTopP: v == null),
      ),
    ]);

    final caps = section(ProvidersGlyphs.layers, l.mp_capabilities, [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final k in ProviderCapability.values)
            ProviderToggle(
              key: Key('mp-cap-${k.name}'),
              label: providerCapabilityLabel(context, k),
              glyph: ProvidersGlyphs.capability(k),
              on: m.capabilities.contains(k),
              onTap: () => onEdit((x) {
                final s = {...x.capabilities};
                s.contains(k) ? s.remove(k) : s.add(k);
                return x.copyWith(capabilities: s);
              }),
            ),
        ],
      ),
    ]);

    final errs = ProvidersValidate.errors(
      ProviderSettings(
        name: 'x',
        baseUrl: 'http://x',
        protocolId: '',
        models: [m],
      ),
    );
    final overrides = section(ProvidersGlyphs.braces, l.mp_bodyHeaders, [
      if (m.body.isEmpty && m.headers.isEmpty)
        Text(l.mp_notAdded, style: UiText.sans(12, color: c.faint)),
      if (m.body.isNotEmpty)
        ProviderKeyValues(
          key: const Key('mp-body'),
          keyPrefix: 'mp-body',
          json: true,
          items: m.body,
          errors: {
            for (final (i, _) in m.body.indexed)
              if (errs.contains('${m.id}:body:$i')) i,
          },
          onChanged: (v) => onEdit((x) => x.copyWith(body: v)),
        ),
      if (m.headers.isNotEmpty)
        ProviderKeyValues(
          key: const Key('mp-model-headers'),
          keyPrefix: 'mp-mheader',
          items: m.headers,
          errors: {
            for (final (i, _) in m.headers.indexed)
              if (errs.contains('${m.id}:header:$i')) i,
          },
          onChanged: (v) => onEdit((x) => x.copyWith(headers: v)),
        ),
      Row(
        spacing: 6,
        children: [
          SettingsBtn(
            key: const Key('mp-add-field'),
            label: l.mp_field,
            glyph: UiGlyphs.plus,
            small: true,
            tone: SettingsBtnTone.ghost,
            onTap: () => onEdit(
              (x) =>
                  x.copyWith(body: [...x.body, const ProviderKeyValue('', '')]),
            ),
          ),
          SettingsBtn(
            key: const Key('mp-add-mheader'),
            label: l.mp_header,
            glyph: UiGlyphs.plus,
            small: true,
            tone: SettingsBtnTone.ghost,
            onTap: () => onEdit(
              (x) => x.copyWith(
                headers: [...x.headers, const ProviderKeyValue('', '')],
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: l.modelOverrides_valueTypes,
              child: Align(
                alignment: Alignment.centerRight,
                child: UiGlyph(ProvidersGlyphs.info, size: 12, color: c.faint),
              ),
            ),
          ),
        ],
      ),
    ]);

    final last = info.lastTest;
    final test = section(null, null, [
      UiPressable(
        key: const Key('mp-test-model'),
        onTap: info.testing ? null : onTest,
        builder: (context, hover) => Container(
          height: 26,
          decoration: BoxDecoration(
            color: hover ? c.hover : c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              if (info.testing)
                const UiSpinner(size: 12)
              else
                UiGlyph(UiGlyphs.bolt, size: 14, color: c.ink),
              Text(
                info.testing ? l.mp_testing : l.mp_testModel,
                style: UiText.sans(
                  12,
                  weight: FontWeight.w500,
                  color: c.ink,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      if (last != null && !info.testing)
        Row(
          key: const Key('mp-test-result'),
          spacing: 6,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: SettingsDot(
                last.ok ? SettingsTone.ok : SettingsTone.error,
              ),
            ),
            Expanded(
              child: Text(
                [
                  if (last.latencyMs != null)
                    SettingsFormat.ms(last.latencyMs!),
                  if (last.message.isNotEmpty) last.message,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(
                  12,
                  color: last.ok ? c.muted : c.error,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
    ], last: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, basics, thinking, sampling, caps, overrides, test],
    );
  }
}
