import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import '../settings/settings_format.dart';
import '../settings/settings_kit.dart';
import 'model_providers_contract.dart';
import 'model_providers_controller.dart';
import 'model_providers_kit.dart';

/// 服务商目录（中栏“服务商目录”视图）：可筛选、多选，最多显示 [limit] 行。
class ProvidersCatalogList extends StatelessWidget {
  const ProvidersCatalogList({
    super.key,
    required this.item,
    required this.settings,
    required this.catalog,
    required this.ctrl,
    required this.now,
    required this.onFetch,
  });

  final ProviderItem item;
  final ProviderSettings settings;
  final ProviderCatalog catalog;
  final ProvidersController ctrl;
  final DateTime now;
  final VoidCallback onFetch;

  static const limit = 60;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final box = BoxDecoration(
      color: c.card,
      border: Border.all(color: c.border),
      borderRadius: BorderRadius.circular(9),
    );
    Widget message(String title, {String? sub, Widget? action, Key? key}) =>
        Container(
          key: key,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: box,
          child: Column(
            spacing: 4,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
              if (sub != null)
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: UiText.sans(12, color: c.muted),
                ),
              if (action != null) ...[const SizedBox(height: 8), action],
            ],
          ),
        );
    switch (catalog.state) {
      case ProviderCatalogState.idle:
        return message(
          l.mp_catalogIdle,
          key: const Key('mp-catalog-idle'),
          sub: l.mp_catalogIdleSub,
          action: SettingsBtn(
            label: l.mp_fetch,
            glyph: UiGlyphs.refresh,
            small: true,
            onTap: onFetch,
          ),
        );
      case ProviderCatalogState.loading:
        return Container(
          key: const Key('mp-catalog-loading'),
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: box,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              const UiSpinner(size: 14),
              Text(l.mp_catalogLoading, style: UiText.sans(12, color: c.muted)),
            ],
          ),
        );
      case ProviderCatalogState.failed:
        return message(
          l.mp_catalogFailed(catalog.error),
          key: const Key('mp-catalog-failed'),
          sub: l.mp_noModelsSub,
          action: SettingsBtn(
            label: l.set_retry,
            glyph: UiGlyphs.refresh,
            small: true,
            onTap: onFetch,
          ),
        );
      case ProviderCatalogState.ready:
        break;
    }
    final q = ctrl.filter(item.id).toLowerCase();
    final added = {for (final m in settings.models) m.id};
    final picks = ctrl.picks(item.id);
    final hits = q.isEmpty
        ? catalog.entries
        : catalog.entries.where((e) => e.id.toLowerCase().contains(q)).toList();
    if (hits.isEmpty) return message(l.mp_noMatch);
    final shown = hits.take(limit).toList();
    final head = UiText.sans(11, weight: FontWeight.w500, color: c.faint);

    Widget id(String s) {
      final i = q.isEmpty ? -1 : s.toLowerCase().indexOf(q);
      final st = UiText.mono(12, color: c.ink);
      if (i < 0) {
        return Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: st);
      }
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: s.substring(0, i)),
            TextSpan(
              text: s.substring(i, i + q.length),
              style: TextStyle(backgroundColor: c.mark),
            ),
            TextSpan(text: s.substring(i + q.length)),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: st,
      );
    }

    return Container(
      key: const Key('mp-catalog'),
      clipBehavior: Clip.antiAlias,
      decoration: box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: c.sunk,
            child: Row(
              spacing: 10,
              children: [
                const SizedBox(width: 16),
                Expanded(child: Text(l.mp_catalogId, style: head)),
                SizedBox(
                  width: 60,
                  child: Text(
                    l.mp_catalogCtx,
                    textAlign: TextAlign.right,
                    style: head,
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    l.mp_catalogPrice,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: head,
                  ),
                ),
              ],
            ),
          ),
          for (final e in shown)
            UiPressable(
              key: Key('mp-cat-${e.id}'),
              onTap: added.contains(e.id)
                  ? null
                  : () => ctrl.togglePick(item.id, e.id),
              builder: (context, hover) {
                final had = added.contains(e.id);
                final on = had || picks.contains(e.id);
                return Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: picks.contains(e.id)
                        ? c.accent.withValues(alpha: .05)
                        : hover
                        ? c.hover
                        : null,
                    border: Border(top: BorderSide(color: c.rowLine)),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Opacity(
                        opacity: had ? .45 : 1,
                        child: UiCheckBox(value: on),
                      ),
                      Expanded(child: id(e.id)),
                      if (had) UiMini(l.mp_added),
                      if (e.retired)
                        UiMini(l.set_mdRetired, tone: UiMiniTone.warn),
                      SizedBox(
                        width: 60,
                        child: Text(
                          providerTokens(e.contextWindow),
                          textAlign: TextAlign.right,
                          style: UiText.mono(11, color: c.muted),
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          e.price ?? '—',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          style: UiText.mono(11, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.rowLine)),
            ),
            child: Text(
              [
                l.mp_catalogFooter(
                  '${hits.length}',
                  '${catalog.entries.length}',
                  catalog.fetchedAt == null
                      ? '—'
                      : SettingsFormat.ago(context, catalog.fetchedAt!, now),
                ),
                if (hits.length > shown.length)
                  l.mp_catalogMore('${hits.length - shown.length}'),
              ].join(' · '),
              key: const Key('mp-catalog-footer'),
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}

/// 目录视图时的右栏：已勾选的模型 + 一次添加。
class ProvidersPickTray extends StatelessWidget {
  const ProvidersPickTray({
    super.key,
    required this.item,
    required this.settings,
    required this.ctrl,
    required this.onAdd,
  });
  final ProviderItem item;
  final ProviderSettings settings;
  final ProvidersController ctrl;
  final ValueChanged<List<String>> onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final picks = ctrl.picks(item.id).toList();
    return Column(
      key: const Key('mp-tray'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: c.card,
            border: Border(bottom: BorderSide(color: c.rowLine)),
          ),
          child: Text(
            l.mp_picked('${picks.length}'),
            style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (picks.isEmpty)
                Text(l.mp_pickEmpty, style: UiText.sans(12, color: c.faint)),
              for (final id in picks)
                Row(
                  spacing: 8,
                  children: [
                    UiPressable(
                      onTap: () => ctrl.togglePick(item.id, id),
                      builder: (context, _) => const UiCheckBox(value: true),
                    ),
                    Expanded(
                      child: Text(
                        id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.mono(12, color: c.ink),
                      ),
                    ),
                    UiMini(l.mp_new, tone: UiMiniTone.accent),
                  ],
                ),
              const SizedBox(height: 4),
              SettingsHint.text(context, l.mp_pickHint),
              const SizedBox(height: 4),
              Row(
                spacing: 8,
                children: [
                  SettingsBtn(
                    key: const Key('mp-add-picked'),
                    label: l.mp_addPicked('${picks.length}'),
                    glyph: UiGlyphs.plus,
                    small: true,
                    tone: SettingsBtnTone.primary,
                    onTap: picks.isEmpty ? null : () => onAdd(picks),
                  ),
                  SettingsBtn(
                    label: l.set_cancel,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: () {
                      ctrl
                        ..clearPicks(item.id)
                        ..setMode(item.id, ProvidersListMode.added);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
