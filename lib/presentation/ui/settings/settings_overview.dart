import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../channel/channel_contract.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_scope.dart';

/// 概览：账号与 Anlas、需要处理、六张状态卡；侧注是最近修改、常用开关。
class SettingsOverviewPage extends StatelessWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final c = context.ui;
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.overview),
        title: l.set_pageOverview,
        description: l.set_ovDesc,
      ),
      top: [if (s.data.restartPending) const SettingsRestartBanner()],
      aside: [
        const _RecentCard(),
        const _QuickCard(),
        SettingsHint(
          child: SettingsKeyText(
            text: SettingsFormat.keyed(l.set_searchTip),
            keys: const ['Ctrl', 'F'],
            style: UiText.sans(12, color: c.muted, height: 1.6),
          ),
        ),
      ],
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            const account = _AccountHero();
            const attention = _AttentionCard();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: wide
                  ? const IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 125, child: account),
                          SizedBox(width: 14),
                          Expanded(flex: 100, child: attention),
                        ],
                      ),
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [account, attention],
                    ),
            );
          },
        ),
        // 同一行的卡片等高（原型 grid 拉伸）。
        SettingsGrid(
          columns: 3,
          gap: 14,
          minItem: 200,
          children: _tiles(context),
        ),
      ],
    );
  }

  List<Widget> _tiles(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final d = SettingsScope.of(context).data;
    final v = d.values;
    final ink = c.ink;

    // 存储
    final st = d.storage;
    final total = st.totalBytes;
    final storage = _Tile(
      page: SettingsPageId.storage,
      icon: StudioIcons.settingsStorage,
      title: l.set_tileStorage,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 6,
        children: [
          Text(
            SettingsFormat.gb(total),
            style: UiText.mono(15, weight: FontWeight.w600, color: ink),
          ),
          Text(
            'GB',
            style: UiText.sans(12, weight: FontWeight.w500, color: c.muted),
          ),
          Flexible(
            child: Text(
              '· ${l.set_tileImages(SettingsFormat.count(st.imageCount))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
      lines: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _StackBar(
            parts: [
              for (final p in st.slices)
                (p.bytes / (total == 0 ? 1 : total), c.storage(p.kind)),
            ],
          ),
        ),
        _line(
          context,
          null,
          l.set_tileSaveTo(v.text(SettingKey.imageSavePath) ?? ''),
        ),
      ],
    );

    // 连接
    final br = d.bridges;
    final comfyOn = v.flag(SettingKey.comfyEnabled);
    final online =
        (br.kritaConnected ? 1 : 0) +
        (br.agentClients > 0 ? 1 : 0) +
        (comfyOn && br.comfyTone == SettingsTone.ok ? 1 : 0);
    final connect = _Tile(
      page: SettingsPageId.bridges,
      icon: StudioIcons.settingsIntegrations,
      title: l.set_tileConnect,
      value: _value(context, l.set_tileOnline('$online')),
      lines: [
        _line(
          context,
          br.kritaConnected ? SettingsTone.ok : SettingsTone.idle,
          br.kritaConnected ? l.set_tileKrita : l.set_tileKritaOff,
        ),
        _line(
          context,
          br.agentClients > 0 ? SettingsTone.ok : SettingsTone.idle,
          l.set_tileAgents('${br.agentClients}'),
        ),
        _line(
          context,
          !comfyOn
              ? SettingsTone.idle
              : br.comfyTone == SettingsTone.error
              ? SettingsTone.warn
              : SettingsTone.ok,
          !comfyOn
              ? l.set_tileComfyOff
              : br.comfyTone == SettingsTone.error
              ? l.set_tileComfyDown
              : l.set_tileComfyOk,
        ),
      ],
    );

    // 模型
    final md = d.models;
    final translate = md.assignments
        .where((a) => a.task == SettingsModelTask.promptTranslate)
        .firstOrNull;
    final tp = md.providers
        .where((p) => p.id == translate?.providerId)
        .firstOrNull;
    final agentModel = d.options[SettingKey.agentModel]
        ?.where((o) => o.value == v.text(SettingKey.agentModel))
        .firstOrNull;
    final modelCount = md.providers.fold<int>(0, (n, p) => n + p.models.length);
    final models = _Tile(
      page: SettingsPageId.models,
      icon: StudioIcons.settingsModels,
      title: l.set_tileModels,
      value: _value(
        context,
        d.generation.translationModel ?? l.set_tileNoModel,
      ),
      lines: [
        if (tp != null)
          _line(
            context,
            tp.status == SettingsTone.idle ? SettingsTone.ok : tp.status,
            l.set_tileTranslateVia(
              tp.latencyMs == null ? '—' : SettingsFormat.ms(tp.latencyMs!),
            ),
          ),
        if (agentModel != null)
          _line(
            context,
            SettingsTone.ok,
            l.set_tileAgentModel(agentModel.label),
          ),
        _line(
          context,
          null,
          l.set_tileProviders('${md.providers.length}', '$modelCount'),
        ),
      ],
    );

    // 语义检索
    final rg = d.rag;
    final ragOn = v.flag(SettingKey.ragEnabled);
    final done = rg.sources
        .where((x) => x.enabled && x.state == SettingsRagState.ready)
        .toList();
    final pending = rg.sources
        .where((x) => x.enabled && x.state != SettingsRagState.ready)
        .toList();
    final rag = _Tile(
      page: SettingsPageId.rag,
      glyph: SettingsGlyphs.hub,
      title: l.set_tileRag,
      value: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 6,
        children: [
          Text(
            ragOn ? SettingsFormat.percent(rg.overall) : '—',
            style: UiText.mono(15, weight: FontWeight.w600, color: ink),
          ),
          Text(
            ragOn ? l.set_tileReady : l.set_rgOff,
            style: UiText.sans(12, weight: FontWeight.w500, color: c.muted),
          ),
        ],
      ),
      lines: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SettingsBar(value: ragOn ? rg.overall : 0),
        ),
        if (ragOn && done.isNotEmpty)
          _line(
            context,
            SettingsTone.ok,
            l.set_tileRagDone(
              done
                  .map((x) => SettingsFormat.ragShort(context, x.kind))
                  .join(l.set_listSep),
            ),
          ),
        for (final x in ragOn ? pending.take(1) : const <SettingsRagSource>[])
          _line(
            context,
            switch (x.state) {
              SettingsRagState.paused => SettingsTone.warn,
              SettingsRagState.error => SettingsTone.error,
              SettingsRagState.empty => SettingsTone.idle,
              _ => SettingsTone.ok,
            },
            switch (x.state) {
              SettingsRagState.paused => l.set_tileRagPaused(
                SettingsFormat.ragShort(context, x.kind),
                SettingsFormat.percent(x.fraction),
              ),
              SettingsRagState.empty => l.set_tileRagEmpty(
                SettingsFormat.ragShort(context, x.kind),
              ),
              SettingsRagState.error => l.set_tileRagError(
                SettingsFormat.ragShort(context, x.kind),
              ),
              _ => l.set_tileRagBuilding(
                SettingsFormat.ragShort(context, x.kind),
                SettingsFormat.percent(x.fraction),
              ),
            },
          ),
      ],
    );

    // 本地放大
    final up = d.upscale;
    bool ready(SettingsUpscaleModel m) =>
        m.state == SettingsInstallState.builtin ||
        m.state == SettingsInstallState.installed;
    final avail = [...up.esrgan, ...up.seed, ?up.rtx].where(ready).length;
    final def = d.options[SettingKey.upscaleDefault]
        ?.where((o) => o.value == v.text(SettingKey.upscaleDefault))
        .firstOrNull;
    final seedReady = up.seed.any(ready);
    final upscale = _Tile(
      page: SettingsPageId.upscale,
      icon: StudioIcons.galleryUpscale,
      title: l.set_tileUpscale,
      value: _value(context, l.set_tileUpscaleModels('$avail')),
      lines: [
        _line(
          context,
          up.gpuName == null ? SettingsTone.idle : SettingsTone.ok,
          up.gpuName == null
              ? l.set_upNoGpu
              : [
                  l.set_upGpu(
                    up.gpuName!.replaceFirst('NVIDIA GeForce ', ''),
                    '${up.vramGb}',
                  ),
                  if (up.caps.contains(SettingsGpuCap.cuda)) 'CUDA',
                ].join(' · '),
        ),
        if (def != null) _line(context, null, l.set_tileDefaultIs(def.label)),
        _line(
          context,
          null,
          seedReady ? l.set_tileSeedReady : l.set_tileSeedMissing,
        ),
      ],
    );

    // 保护
    const guards = [
      SettingKey.stripMetadata,
      SettingKey.confirmExternalSend,
      SettingKey.confirmDangerous,
      SettingKey.noOverwrite,
    ];
    final on = guards.where(v.flag).length;
    final protect = _Tile(
      page: SettingsPageId.privacy,
      icon: StudioIcons.settingsPrivacy,
      title: l.set_tileProtect,
      value: _value(context, l.set_tileProtectOn('$on', '${guards.length}')),
      lines: [
        _line(
          context,
          v.flag(SettingKey.stripMetadata)
              ? SettingsTone.ok
              : SettingsTone.idle,
          l.set_pvStrip,
        ),
        _line(
          context,
          v.flag(SettingKey.confirmDangerous)
              ? SettingsTone.ok
              : SettingsTone.idle,
          l.set_pvDanger,
        ),
        _line(
          context,
          null,
          v.flag(SettingKey.intervalLimit)
              ? l.set_tileInterval(
                  v.number(SettingKey.intervalSeconds).round().toString(),
                  v.number(SettingKey.intervalJitter).round().toString(),
                )
              : l.set_tileIntervalOff,
        ),
      ],
    );
    return [storage, connect, models, rag, upscale, protect];
  }

  static Widget _value(BuildContext context, String text) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: UiText.sans(15, weight: FontWeight.w600, color: context.ui.ink),
  );

  static Widget _line(BuildContext context, SettingsTone? tone, String text) =>
      Row(
        spacing: 7,
        children: [
          if (tone != null) SettingsDot(tone),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: context.ui.muted),
            ),
          ),
        ],
      );
}

class _StackBar extends StatelessWidget {
  const _StackBar({required this.parts});
  final List<(double, Color)> parts;
  static const height = 6.0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: Container(
      height: height,
      color: context.ui.control,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (f, color) in parts)
            if (f > 0)
              Expanded(
                flex: (f * 1000).round().clamp(1, 1000),
                child: ColoredBox(color: color),
              ),
          if (parts.fold<double>(0, (s, p) => s + p.$1) < .999)
            Expanded(
              flex: ((1 - parts.fold<double>(0, (s, p) => s + p.$1)) * 1000)
                  .round()
                  .clamp(1, 1000),
              child: const SizedBox(),
            ),
        ],
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.page,
    this.icon,
    this.glyph,
    required this.title,
    required this.value,
    required this.lines,
  });

  final SettingsPageId page;
  final IconData? icon;
  final String? glyph;
  final String title;
  final Widget value;
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final s = SettingsScope.of(context);
    return UiPressable(
      key: Key('settings-tile-${page.name}'),
      onTap: () => s.jump(page),
      builder: (context, hover) => Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: hover ? c.strong : c.border),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                if (icon != null)
                  Icon(icon, size: 15, color: c.faint)
                else
                  UiGlyph(glyph!, size: 15, color: c.faint),
                Expanded(
                  child: Text(title, style: UiText.sans(12, color: c.muted)),
                ),
                UiGlyph(UiGlyphs.chevronRight, size: 13, color: c.faint),
              ],
            ),
            const SizedBox(height: 8),
            value,
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: lines,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final d = s.data;
    final a = d.account.current;
    final threshold = d.values.number(SettingKey.costThreshold).round();
    final warnOn = d.values.flag(SettingKey.costWarning);
    return Container(
      key: const Key('settings-account-hero'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: a == null
          ? Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Text(
                    l.set_ovSignedOut,
                    style: UiText.sans(
                      15,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                ),
                SettingsBtn(
                  label: l.set_accAdd,
                  glyph: UiGlyphs.plus,
                  small: true,
                  onTap: s.actions.onAddAccount,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    SettingsAvatar(
                      name: a.name,
                      color: a.color,
                      size: 44,
                      radius: 11,
                      fontSize: 19,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 8,
                            children: [
                              Flexible(
                                child: Text(
                                  a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(
                                    15,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              if (a.tier != SettingsTier.none)
                                UiMini(
                                  SettingsFormat.tier(a.tier),
                                  tone: UiMiniTone.accent,
                                ),
                              if (a.isDefault) UiMini(l.set_defaultTag),
                            ],
                          ),
                          Text(
                            [
                              a.maskedId,
                              if (a.renewsAt != null)
                                l.set_ovRenews(
                                  SettingsFormat.date(a.renewsAt!),
                                ),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    SettingsBtn(
                      key: const Key('overview-switch-account'),
                      label: l.set_ovSwitchAccount,
                      small: true,
                      onTap: () => s.jump(SettingsPageId.account),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 10,
                  children: [
                    Text(
                      SettingsFormat.count(a.anlas),
                      style: settingsBig(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Anlas',
                        style: UiText.sans(12, color: c.muted),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 2,
                      children: [
                        Text(
                          l.set_ovTodayUsed,
                          style: UiText.sans(11, color: c.faint),
                        ),
                        Text(
                          d.account.todayUsed == 0
                              ? '0'
                              : SettingsFormat.count(-d.account.todayUsed),
                          style: UiText.mono(13, color: c.ink),
                        ),
                      ],
                    ),
                  ],
                ),
                SettingsBar(
                  value: d.account.monthlyAnlas == 0
                      ? 0
                      : a.anlas / d.account.monthlyAnlas,
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.account.monthlyAnlas == 0
                            ? ''
                            : l.set_ovMonthly(
                                SettingsFormat.count(d.account.monthlyAnlas),
                              ),
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ),
                    Text(
                      warnOn ? l.set_ovWarnAt('$threshold') : l.set_ovWarnOff,
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final items = s.data.attention;
    return Container(
      key: const Key('settings-attention'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              spacing: 8,
              children: [
                Text(
                  l.set_ovAttention,
                  style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
                ),
                if (items.isNotEmpty)
                  UiMini('${items.length}', tone: UiMiniTone.error),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                spacing: 8,
                children: [
                  const SettingsDot(SettingsTone.ok),
                  Text(
                    l.set_ovAllClear,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ],
              ),
            )
          else
            SettingsAsideList(
              rows: [for (final a in items) _AttentionRow(item: a)],
              padding: 9,
            ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});
  final SettingsAttention item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final d = s.data;
    final a = item;
    String ragName() => SettingsFormat.ragShort(
      context,
      SettingsRagSourceKind.values.firstWhere(
        (k) => k.name == a.subject,
        orElse: () => SettingsRagSourceKind.gallery,
      ),
    );
    final (title, sub, button, onTap) = switch (a.kind) {
      SettingsAttentionKind.update => (
        l.set_attUpdate(a.subject),
        [
          if (a.detail.isNotEmpty) a.detail,
          if (a.bytes > 0) SettingsFormat.bytes(a.bytes),
        ].join(' · '),
        l.set_attView,
        () => s.jump(SettingsPageId.about),
      ),
      SettingsAttentionKind.ragPaused => (
        l.set_attRagPaused(ragName()),
        l.set_attRagPausedSub(
          SettingsFormat.count(a.done),
          SettingsFormat.count(a.total),
        ),
        l.set_resume,
        () => s.actions.onRagResume(
          SettingsRagSourceKind.values.firstWhere(
            (k) => k.name == a.subject,
            orElse: () => SettingsRagSourceKind.gallery,
          ),
        ),
      ),
      SettingsAttentionKind.bridgeDown => (
        l.set_attBridgeDown(a.subject == 'krita' ? 'Krita' : 'ComfyUI'),
        a.at == null
            ? a.detail
            : l.set_attCheckedAt(
                a.detail,
                SettingsFormat.ago(context, a.at!, d.now),
              ),
        l.set_attGo,
        () => s.jump(
          SettingsPageId.bridges,
          anchor: a.subject == 'krita'
              ? SettingKey.kritaBridge.name
              : SettingKey.comfyUrl.name,
        ),
      ),
      SettingsAttentionKind.credentialExpired => (
        l.set_attCredential(a.subject),
        l.set_attCredentialSub,
        l.set_attUpdateCred,
        () => s.jump(SettingsPageId.account),
      ),
      SettingsAttentionKind.diskLow => (
        l.set_attDiskLow(a.subject),
        l.set_attDiskLowSub(SettingsFormat.bytes(a.bytes)),
        l.set_attGo,
        () => s.jump(SettingsPageId.storage),
      ),
      SettingsAttentionKind.providerDown => (
        l.set_attProvider(a.subject),
        l.set_attProviderSub,
        l.set_attGo,
        () => s.jump(SettingsPageId.models),
      ),
    };
    return Row(
      spacing: 8,
      children: [
        SettingsDot(a.tone),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, weight: FontWeight.w500, color: c.ink),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.faint),
                ),
            ],
          ),
        ),
        SettingsBtn(
          key: Key('attention-${a.kind.name}'),
          label: button,
          small: true,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final d = s.data;
    final recent = d.recent.take(5).toList();
    return SettingsAsideCard(
      key: const Key('settings-recent'),
      title: l.set_recent,
      trailing: l.set_recentSub,
      child: recent.isEmpty
          ? Text(l.set_recentEmpty, style: UiText.sans(12, color: c.faint))
          : SettingsAsideList(
              rows: [
                for (final r in recent)
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                12,
                                weight: FontWeight.w500,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              '${r.from.isEmpty ? r.to : '${r.from} → ${r.to}'} · ${SettingsFormat.ago(context, r.at, d.now)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(11, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      if (r.undoable)
                        SettingsIconBtn(
                          key: Key('recent-undo-${r.id}'),
                          glyph: SettingsGlyphs.undo,
                          tooltip: l.set_undo,
                          onTap: () => s.actions.onUndo(r.id),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final v = s.data.values;
    final ch = s.data.canvas.channel;
    Widget row(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      String key,
    ) => Row(
      children: [
        Expanded(
          child: Text(title, style: UiText.sans(12, color: c.ink)),
        ),
        SettingsSwitch(
          key: Key('quick-$key'),
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
    return SettingsAsideCard(
      title: l.set_quick,
      trailing: l.set_quickSub,
      child: SettingsAsideList(
        rows: [
          row(
            l.set_quickDark,
            v.text(SettingKey.themeMode) == 'dark',
            (on) => s.actions.onChanged(
              SettingKey.themeMode,
              on ? 'dark' : 'light',
            ),
            'dark',
          ),
          row(
            l.set_apSound,
            v.flag(SettingKey.completionSound),
            (on) => s.actions.onChanged(SettingKey.completionSound, on),
            'sound',
          ),
          row(
            l.set_cvLock,
            v.flag(SettingKey.canvasLockCamera),
            (on) => s.actions.onChanged(SettingKey.canvasLockCamera, on),
            'lock',
          ),
          row(
            l.set_quickChannel,
            ch.mode != ChannelMode.off,
            (on) => s.actions.onChannelChanged(
              ch.copyWith(mode: on ? ChannelMode.random : ChannelMode.off),
            ),
            'channel',
          ),
          row(
            l.set_pvStrip,
            v.flag(SettingKey.stripMetadata),
            (on) => s.actions.onChanged(SettingKey.stripMetadata, on),
            'strip',
          ),
        ],
      ),
    );
  }
}

/// 需重启提示条（原型 `.banner`）。
class SettingsRestartBanner extends StatefulWidget {
  const SettingsRestartBanner({super.key});

  @override
  State<SettingsRestartBanner> createState() => _SettingsRestartBannerState();
}

class _SettingsRestartBannerState extends State<SettingsRestartBanner> {
  var _later = false;

  @override
  Widget build(BuildContext context) {
    if (_later) return const SizedBox.shrink();
    final c = context.ui;
    final l = context.l10n;
    final s = SettingsScope.of(context);
    return Container(
      key: const Key('settings-restart-banner'),
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.warn.withValues(alpha: .07), c.card),
        border: Border.all(color: Color.lerp(c.border, c.warn, .35)!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 10,
        children: [
          UiGlyph(SettingsGlyphs.warn, size: 16, color: c.warn),
          Expanded(
            child: Text(
              l.set_restartBanner,
              style: UiText.sans(12.5, color: c.ink),
            ),
          ),
          SettingsBtn(
            key: const Key('restart-later'),
            label: l.set_later,
            small: true,
            tone: SettingsBtnTone.ghost,
            onTap: () => setState(() => _later = true),
          ),
          SettingsBtn(
            label: l.set_restartNow,
            small: true,
            tone: SettingsBtnTone.primary,
            onTap: s.actions.onRestart,
          ),
        ],
      ),
    );
  }
}
