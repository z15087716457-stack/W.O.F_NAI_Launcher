import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/branding/brand_logo.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_controls.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_overview.dart';
import 'settings_scope.dart';

Widget _state(
  BuildContext context,
  SettingsTone tone,
  String text, {
  Color? color,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: 6,
  children: [
    SettingsDot(tone),
    Text(text, style: UiText.sans(12, color: color ?? context.ui.muted)),
  ],
);

// ───────────────────────────── 桥接与集成 ─────────────────────────────

class SettingsBridgesPage extends StatelessWidget {
  const SettingsBridgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final b = d.bridges;
    final a = s.actions;
    final krita = d.values.flag(SettingKey.kritaBridge);
    final comfy = d.values.flag(SettingKey.comfyEnabled);
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.bridges),
        title: l.set_pageBridges,
        description: l.set_brDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_brStatus,
          child: SettingsAsideList(
            rows: [
              for (final (name, tone, text) in [
                (
                  'Krita',
                  !krita
                      ? SettingsTone.idle
                      : (b.kritaConnected
                            ? SettingsTone.ok
                            : SettingsTone.warn),
                  !krita
                      ? l.set_brOff
                      : (b.kritaConnected
                            ? l.set_brConnected
                            : l.set_brWaiting),
                ),
                (
                  l.set_brAgents,
                  b.agentClients > 0 ? SettingsTone.ok : SettingsTone.idle,
                  l.set_brAgentsShort('${b.agentClients}'),
                ),
                (
                  'ComfyUI',
                  !comfy ? SettingsTone.idle : b.comfyTone,
                  !comfy
                      ? l.set_brOff
                      : (b.comfyTone == SettingsTone.error
                            ? l.set_brNoResponse
                            : l.set_brConnected),
                ),
              ])
                Row(
                  spacing: 8,
                  children: [
                    SettingsDot(tone),
                    Expanded(
                      child: Text(name, style: UiText.sans(12, color: c.ink)),
                    ),
                    Text(text, style: UiText.sans(12, color: c.muted)),
                  ],
                ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_brTip),
      ],
      children: [
        SettingsSection(
          title: 'Krita',
          subtitle: l.set_brKritaSub,
          children: [
            SettingKeyRow(
              SettingKey.kritaBridge,
              title: l.set_brKrita,
              subtitle: l.set_brLoopback,
              control: const SetSwitch(SettingKey.kritaBridge),
            ),
            if (krita) ...[
              SettingsRow(
                sub: true,
                titleLead: SettingsDot(
                  b.kritaConnected ? SettingsTone.ok : SettingsTone.idle,
                ),
                title: b.kritaConnected ? l.set_brConnected : l.set_brWaiting,
                subtitle: b.kritaConnected ? b.kritaClient : null,
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text(
                      b.kritaEndpoint,
                      style: UiText.mono(12, color: c.muted),
                    ),
                    SettingsIconBtn(
                      glyph: SettingsGlyphs.copy,
                      tooltip: l.set_copy,
                      onTap: a.onCopyKritaEndpoint,
                    ),
                    SettingsBtn(
                      label: l.set_brRegenerate,
                      glyph: UiGlyphs.refresh,
                      small: true,
                      onTap: a.onRegenerateKritaSession,
                    ),
                  ],
                ),
              ),
              SettingsRow(
                sub: true,
                title: l.set_brDiscovery,
                subtitle: b.kritaDiscovery,
                control: SettingsIconBtn(
                  glyph: SettingsGlyphs.external,
                  tooltip: l.set_open,
                  onTap: a.onOpenKritaDiscovery,
                ),
              ),
            ],
          ],
        ),
        SettingsSection(
          title: l.set_brAgents,
          subtitle: l.set_brAgentsSub,
          children: [
            SettingsRow(
              anchor: 'agents',
              title: l.set_brLocal,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  _state(
                    context,
                    b.agentClients > 0 ? SettingsTone.ok : SettingsTone.idle,
                    b.agentClients > 0
                        ? l.set_brClients('${b.agentClients}')
                        : l.set_brNoClients,
                  ),
                  SettingsBtn(
                    label: l.set_brTakeover,
                    glyph: SettingsGlyphs.copy,
                    small: true,
                    onTap: a.onCopyAgentTakeover,
                  ),
                  SettingsBtn(
                    label: l.set_brEnd,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: b.agentClients == 0 ? null : a.onEndAgentConnections,
                  ),
                ],
              ),
            ),
            if (b.activity.isNotEmpty)
              SettingsBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l.set_brActivity,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ),
                    SettingsAsideList(
                      rows: [
                        for (final x in b.activity)
                          Row(
                            spacing: 8,
                            children: [
                              SettingsDot(x.tone),
                              SizedBox(
                                width: 96,
                                child: Text(
                                  x.client,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(
                                    12,
                                    weight: FontWeight.w500,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  x.action,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(12, color: c.muted),
                                ),
                              ),
                              Text(
                                SettingsFormat.ago(context, x.at, d.now),
                                style: UiText.sans(11, color: c.faint),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        SettingsSection(
          title: 'ComfyUI',
          subtitle: l.set_brComfySub,
          children: [
            SettingKeyRow(
              SettingKey.comfyEnabled,
              title: l.set_brComfyEnable,
              control: const SetSwitch(SettingKey.comfyEnabled),
            ),
            SettingKeyRow(
              SettingKey.comfyUrl,
              title: l.set_brComfyUrl,
              sub: true,
              disabled: !comfy,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  const SetText(SettingKey.comfyUrl),
                  SettingsBtn(
                    key: const Key('comfy-test'),
                    label: b.comfyTesting ? l.set_testing : l.set_test,
                    glyph: UiGlyphs.bolt,
                    small: true,
                    onTap: b.comfyTesting ? null : a.onTestComfy,
                  ),
                ],
              ),
            ),
            if (comfy && b.comfyTone == SettingsTone.error)
              SettingsBlock(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Row(
                  key: const Key('comfy-error'),
                  spacing: 8,
                  children: [
                    UiGlyph(SettingsGlyphs.warn, size: 14, color: c.error),
                    Expanded(
                      child: Text(
                        l.set_brComfyFailed(
                          b.comfyMessage,
                          b.comfyCheckedAt == null
                              ? ''
                              : SettingsFormat.ago(
                                  context,
                                  b.comfyCheckedAt!,
                                  d.now,
                                ),
                        ),
                        style: UiText.sans(12, color: c.error),
                      ),
                    ),
                    SettingsBtn(
                      label: l.set_retry,
                      small: true,
                      onTap: b.comfyTesting ? null : a.onTestComfy,
                    ),
                  ],
                ),
              )
            else if (comfy &&
                b.comfyTone == SettingsTone.ok &&
                b.comfyCheckedAt != null)
              SettingsBlock(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _state(
                  context,
                  SettingsTone.ok,
                  l.set_brComfyOk(
                    SettingsFormat.ago(context, b.comfyCheckedAt!, d.now),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 网络与代理 ─────────────────────────────

class SettingsNetworkPage extends StatelessWidget {
  const SettingsNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final n = d.network;
    final on = d.values.flag(SettingKey.proxyEnabled);
    final manual = d.values.text(SettingKey.proxyMode) == 'manual';
    String name(SettingsEndpoint e) => switch (e.kind) {
      SettingsEndpointKind.naiImage => l.set_nwNaiImage,
      SettingsEndpointKind.naiApi => l.set_nwNaiApi,
      SettingsEndpointKind.danbooru => l.set_nwDanbooru,
      SettingsEndpointKind.update => l.set_nwUpdate,
      SettingsEndpointKind.provider => e.name,
    };
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.network),
        title: l.set_pageNetwork,
        description: l.set_nwDesc,
      ),
      top: [if (d.restartPending) const SettingsRestartBanner()],
      aside: [SettingsHint.text(context, l.set_nwTip)],
      children: [
        SettingsSection(
          title: l.set_nwProxy,
          subtitle: l.set_nwProxySub,
          children: [
            SettingKeyRow(
              SettingKey.proxyEnabled,
              title: l.set_nwUse,
              control: const SetSwitch(SettingKey.proxyEnabled),
            ),
            SettingKeyRow(
              SettingKey.proxyMode,
              title: l.set_nwMode,
              sub: true,
              disabled: !on,
              control: const SetSeg(SettingKey.proxyMode),
            ),
            if (manual)
              SettingKeyRow(
                SettingKey.proxyHost,
                title: l.set_nwAddress,
                sub: true,
                disabled: !on,
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const SetText(
                      SettingKey.proxyHost,
                      width: 170,
                      hint: '127.0.0.1',
                    ),
                    Text(':', style: UiText.sans(13, color: c.faint)),
                    const SetText(
                      SettingKey.proxyPort,
                      width: 70,
                      hint: '7890',
                    ),
                  ],
                ),
              ),
            SettingsBlock(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: UiGlyph(
                      UiGlyphs.infoCircle,
                      size: 13,
                      color: c.muted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      n.systemProxy == null
                          ? l.set_nwNoSystem
                          : l.set_nwDetected(n.systemProxy!),
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_nwCheck,
          subtitle: l.set_nwCheckSub,
          badge: SettingsMini.isNew(context),
          children: [
            for (final e in n.endpoints)
              SettingsRow(
                key: Key('endpoint-${e.host}'),
                minHeight: 48,
                leading: SettingsDot(e.tone),
                title: name(e),
                titleStyle: UiText.sans(13, color: c.ink),
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 24,
                  children: [
                    Text(e.host, style: UiText.mono(12, color: c.faint)),
                    SizedBox(
                      width: 64,
                      child: Text(
                        e.tone == SettingsTone.error
                            ? l.set_nwFail
                            : (e.latencyMs == null
                                  ? '—'
                                  : SettingsFormat.ms(e.latencyMs!)),
                        textAlign: TextAlign.right,
                        style: UiText.mono(
                          12,
                          color: e.tone == SettingsTone.error ? c.error : c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SettingsBlock(
              child: Row(
                spacing: 8,
                children: [
                  SettingsBtn(
                    key: const Key('check-endpoints'),
                    label: n.checking ? l.set_testing : l.set_nwCheckAll,
                    glyph: UiGlyphs.bolt,
                    small: true,
                    onTap: n.checking ? null : s.actions.onCheckEndpoints,
                  ),
                  Flexible(
                    child: Text(
                      n.checkedAt == null
                          ? l.set_nwNeverChecked
                          : '${l.set_nwChecked(SettingsFormat.ago(context, n.checkedAt!, d.now))} · ${on ? l.set_nwViaProxy : l.set_nwDirect}',
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 隐私与保护 ─────────────────────────────

class SettingsPrivacyPage extends StatelessWidget {
  const SettingsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final pv = d.privacy;
    final v = d.values;
    Widget toggle(SettingKey k, String glyph, String title, String sub) {
      final on = v.flag(k);
      return SettingsAnchor(
        anchor: k.name,
        child: UiPressable(
          key: Key('guard-${k.name}'),
          onTap: () => s.actions.onChanged(k, !on),
          builder: (context, hover) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(
                color: on ? c.accent : (hover ? c.strong : c.border),
              ),
              borderRadius: BorderRadius.circular(10),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.accent.withValues(alpha: .12) : c.control,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: UiGlyph(
                    glyph,
                    size: 16,
                    color: on ? c.accent : c.muted,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        spacing: 7,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: UiText.sans(
                                13,
                                weight: FontWeight.w500,
                                color: c.ink,
                              ),
                            ),
                          ),
                          if (d.modified.contains(k))
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        sub,
                        style: UiText.sans(12, color: c.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(child: SettingsSwitch(value: on)),
              ],
            ),
          ),
        ),
      );
    }

    final syncSub = pv.danbooruUser == null
        ? l.set_pvSyncSignedOut
        : pv.lastSyncAt == null
        ? l.set_pvSyncNever(pv.danbooruUser!)
        : l.set_pvSyncSub(
            pv.danbooruUser!,
            SettingsFormat.ago(context, pv.lastSyncAt!, d.now),
          );
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.privacy),
        title: l.set_pagePrivacy,
        description: l.set_pvDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_pvExported,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              for (final (t, inc) in [
                (l.set_pvIncPrefs, true),
                (l.set_pvIncRules, true),
                (l.set_pvIncCred, false),
                (l.set_pvIncPaths, false),
                (l.set_pvIncDrafts, false),
              ])
                Row(
                  spacing: 8,
                  children: [
                    UiGlyph(
                      inc ? UiGlyphs.check : UiGlyphs.close,
                      size: 13,
                      color: inc ? c.ok : c.faint,
                    ),
                    Text(
                      t,
                      style: UiText.sans(12, color: inc ? c.ink : c.faint),
                    ),
                  ],
                ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_pvTip),
      ],
      children: [
        SettingsSection(
          title: l.set_pvProtect,
          children: [
            SettingsBlock(
              child: SettingsGrid(
                columns: 2,
                minItem: 240,
                children: [
                  toggle(
                    SettingKey.stripMetadata,
                    SettingsGlyphs.file,
                    l.set_pvStrip,
                    l.set_pvStripSub,
                  ),
                  toggle(
                    SettingKey.confirmExternalSend,
                    SettingsGlyphs.external,
                    l.set_pvExternal,
                    l.set_pvExternalSub,
                  ),
                  toggle(
                    SettingKey.confirmDangerous,
                    SettingsGlyphs.warn,
                    l.set_pvDanger,
                    l.set_pvDangerSub,
                  ),
                  toggle(
                    SettingKey.noOverwrite,
                    SettingsGlyphs.lock,
                    l.set_pvOverwrite,
                    l.set_pvOverwriteSub,
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_pvBlacklist,
          subtitle: l.set_pvBlacklistSub,
          children: [
            SettingsBlock(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final t in pv.blacklist)
                    SettingsChip(
                      key: Key('tag-$t'),
                      label: t,
                      mono: true,
                      onRemove: () => s.actions.onRemoveBlacklistTag(t),
                    ),
                  _TagInput(onAdd: s.actions.onAddBlacklistTag),
                ],
              ),
            ),
            SettingsRow(
              anchor: 'blacklistSync',
              title: l.set_pvSync,
              subtitle: syncSub,
              control: pv.danbooruUser == null
                  ? SettingsBtn(
                      label: l.set_login,
                      small: true,
                      onTap: s.actions.onDanbooruLogin,
                    )
                  : SettingsBtn(
                      key: const Key('sync-blacklist'),
                      label: pv.syncing ? l.set_pvSyncing : l.set_pvSyncNow,
                      glyph: UiGlyphs.refresh,
                      small: true,
                      onTap: pv.syncing ? null : s.actions.onSyncBlacklist,
                    ),
            ),
            SettingKeyRow(
              SettingKey.blacklistAutoSync,
              title: l.set_pvAutoSync,
              sub: true,
              disabled: pv.danbooruUser == null,
              control: const SetSwitch(SettingKey.blacklistAutoSync),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagInput extends StatefulWidget {
  const _TagInput({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = _focus.hasFocus;
    return Container(
      width: 170,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: on ? c.accent : c.border),
      ),
      child: TextField(
        key: const Key('blacklist-input'),
        controller: _ctrl,
        focusNode: _focus,
        style: UiText.mono(11.5, color: c.ink, height: 1.2),
        cursorColor: c.accent,
        cursorHeight: 13,
        decoration: uiBareDecoration(
          hintText: context.l10n.set_pvAddTag,
          hintStyle: UiText.sans(12, color: c.faint, height: 1.2),
        ),
        onSubmitted: (v) {
          final t = v.trim().replaceAll(' ', '_');
          if (t.isNotEmpty) widget.onAdd(t);
          _ctrl.clear();
          _focus.requestFocus();
        },
      ),
    );
  }
}

// ───────────────────────────── 备份与重置 ─────────────────────────────

class SettingsBackupPage extends StatefulWidget {
  const SettingsBackupPage({super.key});

  @override
  State<SettingsBackupPage> createState() => _SettingsBackupPageState();
}

class _SettingsBackupPageState extends State<SettingsBackupPage> {
  final _scopes = <SettingsResetScope>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final bk = d.backup;
    final a = s.actions;
    final total = d.shortcuts.shortcuts.length;
    String scopeName(SettingsResetScope x) => switch (x) {
      SettingsResetScope.appearance => l.set_bkScopeAppearance,
      SettingsResetScope.input => l.set_bkScopeInput,
      SettingsResetScope.protection => l.set_bkScopeProtect,
      SettingsResetScope.shortcuts => l.set_bkScopeShortcuts,
    };
    String scopeSub(SettingsResetScope x) => switch (x) {
      SettingsResetScope.appearance => l.set_bkScopeAppearanceSub,
      SettingsResetScope.input => l.set_bkScopeInputSub,
      SettingsResetScope.protection => l.set_bkScopeProtectSub,
      SettingsResetScope.shortcuts => l.set_bkScopeShortcutsSub('$total'),
    };
    String kind(SettingsBackupKind k) => switch (k) {
      SettingsBackupKind.import => l.set_bkKindImport,
      SettingsBackupKind.reset => l.set_bkKindReset,
      SettingsBackupKind.upgrade => l.set_bkKindUpgrade,
    };
    String stamp(DateTime t) =>
        '${SettingsFormat.monthDay(t)} ${SettingsFormat.time(t)}';
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.backup),
        title: l.set_pageBackup,
        description: l.set_bkDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_bkAuto,
          trailing: l.set_bkAutoSub,
          badge: SettingsMini.isNew(context),
          child: bk.backups.isEmpty
              ? Text(l.set_bkNoBackups, style: UiText.sans(12, color: c.faint))
              : SettingsAsideList(
                  rows: [
                    for (final b in bk.backups)
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: Text(
                              kind(b.kind),
                              style: UiText.sans(12, color: c.ink),
                            ),
                          ),
                          Text(
                            stamp(b.at),
                            style: UiText.mono(11, color: c.faint),
                          ),
                          SettingsIconBtn(
                            key: Key('restore-${b.id}'),
                            glyph: SettingsGlyphs.undo,
                            glyphSize: 13,
                            tooltip: l.set_bkRestore,
                            onTap: () => s.confirm(
                              title: l.set_bkRestoreTitle(kind(b.kind)),
                              body: l.set_bkRestoreBody,
                              confirm: l.set_bkRestore,
                              onConfirm: () => a.onRestoreBackup(b.id),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
      children: [
        SettingsSection(
          title: l.set_bkPrefs,
          subtitle: l.set_bkPrefsSub,
          children: [
            SettingsRow(
              title: l.set_bkExport,
              subtitle: l.set_bkExportSub,
              control: SettingsBtn(
                label: l.set_bkExportBtn,
                glyph: SettingsGlyphs.upload,
                small: true,
                onTap: a.onExportPreferences,
              ),
            ),
            SettingsRow(
              title: l.set_bkImport,
              subtitle: l.set_bkImportSub,
              control: SettingsBtn(
                label: l.set_bkImportBtn,
                glyph: UiGlyphs.download,
                small: true,
                onTap: a.onImportPreferences,
              ),
            ),
            SettingsRow(
              title: l.set_bkUndoImport,
              subtitle: bk.lastImportAt == null
                  ? l.set_bkNoImport
                  : l.set_bkUndoImportSub(stamp(bk.lastImportAt!)),
              control: SettingsBtn(
                key: const Key('undo-import'),
                label: l.set_bkRestore,
                small: true,
                onTap: bk.lastImportAt == null ? null : a.onUndoImport,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_bkOther,
          children: [
            SettingsRow(
              title: l.set_pageShortcuts,
              subtitle: l.set_bkShortcutsSub(
                '$total',
                '${bk.shortcutsCustomized}',
              ),
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  SettingsBtn(
                    label: l.set_importIt,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: a.onShortcutsImport,
                  ),
                  SettingsBtn(
                    label: l.set_exportIt,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: a.onShortcutsExport,
                  ),
                ],
              ),
            ),
            SettingsRow(
              title: l.set_pageModels,
              subtitle: l.set_bkModelsSub,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  SettingsBtn(
                    label: l.set_importIt,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: a.onImportModelConfig,
                  ),
                  SettingsBtn(
                    label: l.set_bkCopyConfig,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: a.onCopyModelConfig,
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_bkReset,
          subtitle: l.set_bkResetSub,
          children: [
            SettingsBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final x in SettingsResetScope.values)
                    UiPressable(
                      key: Key('scope-${x.name}'),
                      onTap: () => setState(
                        () => _scopes.contains(x)
                            ? _scopes.remove(x)
                            : _scopes.add(x),
                      ),
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          spacing: 10,
                          children: [
                            UiCheckBox(value: _scopes.contains(x)),
                            SizedBox(
                              width: 120,
                              child: Text(
                                scopeName(x),
                                style: UiText.sans(
                                  13,
                                  weight: FontWeight.w500,
                                  color: c.ink,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                scopeSub(x),
                                style: UiText.sans(12, color: c.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 11),
                  Row(
                    spacing: 8,
                    children: [
                      SettingsBtn(
                        key: const Key('reset-scopes'),
                        label: l.set_bkResetBtn,
                        small: true,
                        tone: SettingsBtnTone.danger,
                        onTap: _scopes.isEmpty
                            ? null
                            : () {
                                final picked = {..._scopes};
                                s.confirm(
                                  title: l.set_bkResetTitle,
                                  body: l.set_bkResetBody(
                                    picked.map(scopeName).join(l.set_listSep),
                                  ),
                                  confirm: l.set_resetDefault,
                                  danger: true,
                                  onConfirm: () {
                                    a.onResetScopes(picked);
                                    setState(_scopes.clear);
                                  },
                                );
                              },
                      ),
                      Flexible(
                        child: Text(
                          l.set_bkResetHint,
                          style: UiText.sans(11, color: c.faint),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 关于 ─────────────────────────────

class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final ab = d.about;
    final a = s.actions;
    final (statusText, statusTone) = switch (ab.update) {
      SettingsUpdateState.available => (
        l.set_abNew(ab.latest),
        UiMiniTone.error,
      ),
      SettingsUpdateState.checking => (l.set_abChecking, UiMiniTone.plain),
      SettingsUpdateState.downloading => (
        l.set_abDownloading(SettingsFormat.percent(ab.progress)),
        UiMiniTone.accent,
      ),
      SettingsUpdateState.failed => (l.set_abCheckFailed, UiMiniTone.warn),
      SettingsUpdateState.upToDate => (l.set_abLatest, UiMiniTone.ok),
    };
    final hasNew =
        ab.update == SettingsUpdateState.available ||
        ab.update == SettingsUpdateState.downloading;
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.about),
        title: l.set_pageAbout,
        description: l.set_abDesc,
      ),
      aside: [
        if (ab.system.isNotEmpty)
          SettingsAsideCard(
            key: const Key('about-system'),
            title: l.set_abSystem,
            child: SettingsAsideList(
              rows: [
                for (final (k, v) in ab.system)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(k, style: UiText.sans(12, color: c.muted)),
                      Expanded(
                        child: Text(
                          v,
                          textAlign: TextAlign.end,
                          softWrap: true,
                          style: UiText.mono(12, color: c.ink),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Container(
            key: const Key('about-card'),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  key: const Key('about-brand-header'),
                  spacing: 16,
                  children: [
                    const SizedBox(
                      key: Key('about-brand-slot'),
                      width: 112,
                      height: 56,
                      child: Center(
                        child: ExcludeSemantics(
                          child: BrandLogo(
                            key: Key('about-brand-logo'),
                            width: 112,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        key: const Key('about-brand-name'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'W.O.F NAI Studio',
                            style: UiText.sans(
                              18,
                              weight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            [
                              d.version,
                              if (ab.build.isNotEmpty) 'build ${ab.build}',
                              if (ab.platform.isNotEmpty) ab.platform,
                            ].join(' · '),
                            style: UiText.mono(12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 6,
                      children: [
                        UiMini(statusText, tone: statusTone),
                        if (ab.checkedAt != null)
                          Text(
                            l.set_abChecked(
                              SettingsFormat.ago(context, ab.checkedAt!, d.now),
                            ),
                            style: UiText.sans(11, color: c.faint),
                          ),
                      ],
                    ),
                  ],
                ),
                if (hasNew && ab.notes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: c.sunk,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Text(
                              l.set_abNotes(ab.latest),
                              style: UiText.sans(
                                12,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              [
                                if (ab.releasedAt != null)
                                  SettingsFormat.date(ab.releasedAt!),
                                if (ab.updateBytes > 0)
                                  SettingsFormat.bytes(ab.updateBytes),
                              ].join(' · '),
                              style: UiText.sans(12, color: c.faint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final n in ab.notes)
                          Text(
                            '· $n',
                            style: UiText.sans(
                              12,
                              color: c.muted,
                              height: 1.75,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (ab.update == SettingsUpdateState.downloading) ...[
                  const SizedBox(height: 14),
                  SettingsBar(value: ab.progress),
                ],
                const SizedBox(height: 14),
                Row(
                  spacing: 8,
                  children: [
                    if (ab.update == SettingsUpdateState.available)
                      SettingsBtn(
                        key: const Key('install-update'),
                        label: l.set_abInstall,
                        glyph: UiGlyphs.download,
                        tone: SettingsBtnTone.primary,
                        onTap: a.onInstallUpdate,
                      ),
                    SettingsBtn(
                      label: l.set_abChangelog,
                      glyph: SettingsGlyphs.external,
                      tone: SettingsBtnTone.ghost,
                      onTap: a.onOpenChangelog,
                    ),
                    const Spacer(),
                    Text(
                      l.set_abPrerelease,
                      style: UiText.sans(12, color: c.muted),
                    ),
                    const SetSwitch(SettingKey.includePrerelease),
                  ],
                ),
              ],
            ),
          ),
        ),
        SettingsSection(
          title: l.set_abDiag,
          children: [
            SettingKeyRow(
              SettingKey.logToFile,
              title: l.set_abLog,
              subtitle: l.set_abLogSub,
              control: const SetSwitch(SettingKey.logToFile),
            ),
            SettingsRow(
              title: l.set_abLogDir,
              control: SettingsBtn(
                label: l.set_open,
                glyph: SettingsGlyphs.external,
                small: true,
                onTap: () => a.onOpenFolder(SettingsFolder.logs),
              ),
            ),
            SettingsRow(
              anchor: 'diagnostics',
              title: l.set_abCopyDiag,
              subtitle: l.set_abCopyDiagSub,
              badges: [SettingsMini.isNew(context)],
              control: SettingsBtn(
                key: const Key('copy-diagnostics'),
                label: l.set_copy,
                glyph: SettingsGlyphs.copy,
                small: true,
                onTap: a.onCopyDiagnostics,
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_abProject,
          children: [
            SettingsRow(
              title: l.set_abRepo,
              subtitle: 'github.com/z15087716457-stack/W.O.F_NAI_Launcher',
              control: SettingsBtn(
                label: l.set_open,
                glyph: SettingsGlyphs.external,
                small: true,
                onTap: a.onOpenRepository,
              ),
            ),
            SettingsRow(
              title: l.set_abUpstream,
              subtitle: l.set_abUpstreamSub,
              control: SettingsBtn(
                label: l.set_abView,
                glyph: SettingsGlyphs.external,
                small: true,
                tone: SettingsBtnTone.ghost,
                onTap: a.onOpenUpstream,
              ),
            ),
            SettingsRow(
              title: l.set_abFonts,
              subtitle:
                  'Geist Sans / Mono / Pixel · HarmonyOS Sans SC · Pretendard',
              control: SettingsBtn(
                label: l.set_abLicenses,
                small: true,
                tone: SettingsBtnTone.ghost,
                onTap: a.onOpenLicenses,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
