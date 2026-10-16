import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../channel/channel_contract.dart';
import '../channel/channel_format.dart';
import '../channel/channel_geometry.dart';
import '../channel/channel_settings.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_controls.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_scope.dart';

// ───────────────────────────── 账号 ─────────────────────────────

class SettingsAccountPage extends StatelessWidget {
  const SettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final cur = d.account.current;
    final tier = cur?.tier;
    final anlas = cur?.anlas;
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.account),
        title: l.set_pageAccount,
        description: l.set_accDesc,
      ),
      aside: [
        if (tier != null && tier != SettingsTier.none)
          SettingsAsideCard(
            title: l.set_accSub,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    UiMini(SettingsFormat.tier(tier), tone: UiMiniTone.accent),
                    Text(
                      l.set_accMonthly(
                        SettingsFormat.count(d.account.monthlyAnlas),
                      ),
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsBar(
                  value: anlas == null || d.account.monthlyAnlas == 0
                      ? 0
                      : anlas / d.account.monthlyAnlas,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      anlas == null
                          ? l.set_accBalanceUnread
                          : l.set_accRemaining(SettingsFormat.count(anlas)),
                      style: UiText.sans(11, color: c.faint),
                    ),
                    const Spacer(),
                    if (cur!.renewsAt != null)
                      Text(
                        l.set_accResets(SettingsFormat.monthDay(cur.renewsAt!)),
                        style: UiText.sans(11, color: c.faint),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SettingsBtn(
                      label: l.set_accPortal,
                      glyph: SettingsGlyphs.external,
                      small: true,
                      onTap: s.actions.onOpenAccountPortal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        SettingsHint.text(context, l.set_accSwitchHint),
      ],
      children: [
        SettingsSection(
          title: l.set_accSaved,
          subtitle: l.set_accSavedSub,
          children: [
            for (final a in d.account.accounts) _AccountRow(account: a),
            SettingsBlock(
              child: Row(
                spacing: 8,
                children: [
                  SettingsBtn(
                    label: l.set_accAdd,
                    glyph: UiGlyphs.plus,
                    onTap: s.actions.onAddAccount,
                  ),
                  Flexible(
                    child: Text(
                      l.set_accAddHint,
                      style: UiText.sans(12, color: c.faint),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_accLogin,
          children: [
            SettingKeyRow(
              SettingKey.defaultAccount,
              title: l.set_accDefault,
              subtitle: l.set_accDefaultSub,
              control: const SetSelect(SettingKey.defaultAccount),
            ),
            SettingKeyRow(
              SettingKey.autoLogin,
              title: l.set_accAutoLogin,
              subtitle: l.set_accAutoLoginSub,
              control: const SetSwitch(SettingKey.autoLogin),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final SettingsAccount account;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final a = account;
    final sub = a.expired
        ? [if (a.tier == SettingsTier.none) l.set_accNoSub, l.set_accExpired]
        : [
            a.loginKind == SettingsLoginKind.email
                ? l.set_accEmail
                : l.set_accToken,
            a.maskedId,
            if (a.current && a.renewsAt != null)
              l.set_accRenews(SettingsFormat.date(a.renewsAt!))
            else if (a.lastUsedAt != null)
              l.set_accLastUsed(SettingsFormat.monthDay(a.lastUsedAt!)),
          ];
    return SettingsRow(
      key: Key('account-${a.id}'),
      minHeight: 68,
      leading: Padding(
        padding: const EdgeInsets.only(right: 0),
        child: SettingsAvatar(
          name: a.name,
          color: a.expired ? 0xFFA8A8A8 : a.color,
        ),
      ),
      title: a.name,
      badges: [
        if (a.tier != null && a.tier != SettingsTier.none)
          UiMini(
            SettingsFormat.tier(a.tier!),
            tone: a.tier == SettingsTier.opus
                ? UiMiniTone.accent
                : UiMiniTone.plain,
          ),
        if (a.current) UiMini(l.set_accCurrent, tone: UiMiniTone.ok),
        if (a.isDefault) UiMini(l.set_defaultTag),
      ],
      subtitle: sub.join(' · '),
      control: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (a.anlas == null)
                  Text(
                    l.set_accUnread,
                    key: Key('account-unread-${a.id}'),
                    style: UiText.sans(12.5, color: c.faint, height: 1.3),
                  )
                else
                  Text(
                    SettingsFormat.count(a.anlas!),
                    style: UiText.mono(
                      13,
                      weight: FontWeight.w500,
                      color: a.anlas == 0 ? c.faint : c.ink,
                    ),
                  ),
                Text('Anlas', style: UiText.sans(11, color: c.faint)),
              ],
            ),
          ),
          if (a.current)
            SizedBox(
              width: 52,
              child: Text(
                l.set_accInUse,
                textAlign: TextAlign.center,
                style: UiText.sans(12, color: c.faint),
              ),
            )
          else if (a.expired)
            SettingsBtn(
              label: l.set_accUpdate,
              small: true,
              onTap: () => s.actions.onUpdateCredentials(a.id),
            )
          else
            SettingsBtn(
              key: Key('account-switch-${a.id}'),
              label: l.set_accSwitch,
              small: true,
              onTap: () => s.actions.onSwitchAccount(a.id),
            ),
          SettingsMoreButton(
            items: [
              (l.set_accEdit, () => s.actions.onEditAccount(a.id), false),
              (
                l.set_accUpdate,
                () => s.actions.onUpdateCredentials(a.id),
                false,
              ),
              if (!a.isDefault)
                (
                  l.set_accMakeDefault,
                  () => s.actions.onSetDefaultAccount(a.id),
                  false,
                ),
              (
                l.set_accDelete,
                () => s.confirm(
                  title: l.set_accDeleteTitle(a.name),
                  body: l.set_accDeleteBody,
                  confirm: l.set_delete,
                  danger: true,
                  onConfirm: () => s.actions.onDeleteAccount(a.id),
                ),
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 外观 ─────────────────────────────

/// 主题缩略图用的固定配色（画的是“那个主题长什么样”，不随当前主题变）。
class _Swatch {
  const _Swatch(this.bg, this.panel, this.line, this.text, this.mute);
  final Color bg, panel, line, text, mute;
  static const light = _Swatch(
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
    Color(0xFFE6E6E6),
    Color(0xFF171717),
    Color(0xFFCFCFCF),
  );
  static const dark = _Swatch(
    Color(0xFF111111),
    Color(0xFF161616),
    Color(0xFF2E2E2E),
    Color(0xFFEDEDED),
    Color(0xFF555555),
  );
  static const brand = Color(0xFF1F6BFF);
  static const tiles = [
    [Color(0xFFF4C3D0), Color(0xFFA7B7F4)],
    [Color(0xFFBFE3D4), Color(0xFFE9D7A8)],
    [Color(0xFFCDB8F0), Color(0xFFF2C4A8)],
    [Color(0xFFA9D3F2), Color(0xFFF3B1C4)],
  ];
}

class _ThemeMini extends StatelessWidget {
  const _ThemeMini(this.x, {this.compact = false});
  final _Swatch x;

  /// 跟随系统时左右各半：中间面板和图块收窄。
  final bool compact;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: x.bg,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 16,
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: x.line)),
          ),
          child: Column(
            spacing: 5,
            children: [_sq(8, _Swatch.brand), _sq(7, x.mute), _sq(7, x.mute)],
          ),
        ),
        Container(
          width: compact ? 30 : 44,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            color: x.panel,
            border: Border(right: BorderSide(color: x.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              FractionallySizedBox(
                widthFactor: .7,
                child: Container(height: 4, color: x.text),
              ),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: x.bg,
                  border: Border.all(color: x.line),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: .85,
                child: Container(height: 3, color: x.mute),
              ),
              FractionallySizedBox(
                widthFactor: .6,
                child: Container(height: 3, color: x.mute),
              ),
              const Spacer(),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF005DFF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(compact ? 6 : 10),
            child: Column(
              spacing: 6,
              children: [
                for (final r in [0, 2])
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        for (final i in [r, r + 1])
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: _Swatch.tiles[i],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static Widget _sq(double s, Color c) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
  );
}

Widget _themePreview(BuildContext context, String kind, {double height = 104}) {
  final c = context.ui;
  final body = switch (kind) {
    'dark' => const _ThemeMini(_Swatch.dark),
    'system' => const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _ThemeMini(_Swatch.light, compact: true)),
        Expanded(child: _ThemeMini(_Swatch.dark, compact: true)),
      ],
    ),
    _ => const _ThemeMini(_Swatch.light),
  };
  return Container(
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.border),
    ),
    child: body,
  );
}

class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final v = s.data.values;
    final theme = v.text(SettingKey.themeMode) ?? 'light';
    final scale = v.number(SettingKey.settingsFontScale);
    final soundOn = v.flag(SettingKey.completionSound);
    final shownTheme = theme == 'system' ? (c.dark ? 'dark' : 'light') : theme;
    final font =
        s.data.options[SettingKey.fontFamily]
            ?.where((o) => o.value == v.text(SettingKey.fontFamily))
            .firstOrNull
            ?.label ??
        v.text(SettingKey.fontFamily) ??
        '';
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.appearance),
        title: l.set_pageAppearance,
        description: l.set_apDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_apPreview,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _themePreview(context, shownTheme, height: 150),
              ),
              const SizedBox(height: 10),
              Row(
                spacing: 8,
                children: [
                  Text(l.set_apCurrent, style: UiText.sans(12, color: c.muted)),
                  Expanded(
                    child: Text(
                      [
                        SettingsFormat.choice(
                          context,
                          SettingKey.themeMode,
                          theme,
                        ),
                        font,
                        '${(scale * 100).round()}%',
                      ].where((x) => x.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingsHint(
          child: SettingsKeyText(
            text: SettingsFormat.keyed(l.set_apThemeTip),
            keys: const ['Ctrl', 'Shift', 'T'],
            style: UiText.sans(12, color: c.muted, height: 1.6),
          ),
        ),
      ],
      children: [
        SettingsSection(
          title: l.set_apTheme,
          subtitle: l.set_apThemeSub,
          children: [
            SettingsAnchor(
              anchor: SettingKey.themeMode.name,
              radius: 11,
              child: SettingsBlock(
                child: SettingsGrid(
                  columns: 3,
                  children: [
                    for (final k in SettingSpec.of(
                      SettingKey.themeMode,
                    ).choices)
                      SettingsOptionCard(
                        key: Key('theme-$k'),
                        selected: theme == k,
                        preview: _themePreview(context, k),
                        label: SettingsFormat.choice(
                          context,
                          SettingKey.themeMode,
                          k,
                        ),
                        description: switch (k) {
                          'light' => 'Geist Light',
                          'dark' => 'Geist Dark',
                          _ => l.set_apSystemSub,
                        },
                        onTap: () =>
                            s.actions.onChanged(SettingKey.themeMode, k),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_apText,
          children: [
            SettingKeyRow(
              SettingKey.fontFamily,
              title: l.set_apFont,
              subtitle: l.set_apFontSub,
              control: const SetSelect(SettingKey.fontFamily, width: 200),
            ),
            SettingKeyRow(
              SettingKey.settingsFontScale,
              title: l.set_apScale,
              subtitle: l.set_apScaleSub,
              control: SetSlider(
                SettingKey.settingsFontScale,
                width: 180,
                ticks: 7,
                label: (x) => '${(x * 100).round()}%',
              ),
            ),
            SettingsBlock(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Container(
                key: const Key('font-sample'),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: c.sunk,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      l.set_apSampleTitle,
                      style: UiText.sans(
                        15 * scale,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.set_apSampleBody,
                      style: UiText.sans(13 * scale, color: c.ink),
                    ),
                    Text(
                      l.set_apSampleNote,
                      style: UiText.sans(11 * scale, color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
            SettingKeyRow(
              SettingKey.language,
              title: l.set_apLanguage,
              subtitle: l.set_apLanguageSub,
              control: const SetSeg(SettingKey.language),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_apMotion,
          children: [
            SettingKeyRow(
              SettingKey.reduceMotion,
              title: l.set_apReduceMotion,
              subtitle: l.set_apReduceMotionSub,
              control: const SetSwitch(SettingKey.reduceMotion),
            ),
            SettingKeyRow(
              SettingKey.completionSound,
              title: l.set_apSound,
              subtitle: l.set_apSoundSub,
              control: const SetSwitch(SettingKey.completionSound),
            ),
            SettingKeyRow(
              SettingKey.completionSoundFile,
              title: l.set_apSoundFile,
              sub: true,
              disabled: !soundOn,
              control: SizedBox(
                width: 330,
                child: Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: SettingsPathBox(
                        path:
                            v.text(SettingKey.completionSoundFile) ??
                            l.set_builtinSound,
                        actions: [
                          if (v.text(SettingKey.completionSoundFile) != null)
                            SettingsIconBtn(
                              glyph: UiGlyphs.close,
                              tooltip: l.set_clear,
                              onTap: () => s.actions.onReset(
                                SettingKey.completionSoundFile,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SettingsBtn(
                      label: l.set_choose,
                      small: true,
                      onTap: () =>
                          s.actions.onPickPath(SettingKey.completionSoundFile),
                    ),
                    SettingsBtn(
                      label: l.set_apPreviewSound,
                      glyph: UiGlyphs.play,
                      small: true,
                      onTap: s.actions.onPreviewSound,
                    ),
                  ],
                ),
              ),
            ),
            SettingsRow(
              title: l.set_apNotify,
              subtitle: l.set_apNotifySub,
              control: SettingsBtn(
                label: l.set_apNotifyPreview,
                glyph: SettingsGlyphs.bell,
                small: true,
                onTap: s.actions.onPreviewNotification,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 画布与浏览 ─────────────────────────────

class _Diagram extends StatelessWidget {
  const _Diagram(this.kind);
  final String kind;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    // 原型是行内 svg，下面多出约 5px 基线空隙。
    return Container(
      height: 75,
      padding: const EdgeInsets.only(bottom: 5),
      child: CustomPaint(
        size: Size.infinite,
        painter: _DiagramPainter(
          kind,
          line: c.strong,
          accent: c.accent,
          control: c.control,
          sunk: c.sunk,
        ),
      ),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  _DiagramPainter(
    this.kind, {
    required this.line,
    required this.accent,
    required this.control,
    required this.sunk,
  });
  final String kind;
  final Color line, accent, control, sunk;

  @override
  void paint(Canvas canvas, Size size) {
    // 原型 viewBox 160 × 70，按高度等比、水平居中（同 preserveAspectRatio meet）。
    final k = math.min(size.width / 160, size.height / 70);
    canvas.translate((size.width - 160 * k) / 2, (size.height - 70 * k) / 2);
    canvas.scale(k);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = line;
    final fill = Paint();
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    void list() {
      canvas.drawRRect(rr(4.5, 6.5, 34, 58, 4), stroke);
      for (var i = 0; i < 4; i++) {
        canvas.drawRRect(
          rr(9, 11 + i * 13.0, 24, 9, 2),
          fill..color = i == 1 ? accent : control,
        );
      }
    }

    final tint = accent.withValues(alpha: .2);
    switch (kind) {
      case 'openDetail':
        list();
        final ap = Paint()
          ..color = accent
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(44, 29), const Offset(64, 29), ap);
        canvas.drawPath(
          Path()
            ..moveTo(63, 26)
            ..lineTo(68, 29)
            ..lineTo(63, 32)
            ..close(),
          Paint()..color = accent,
        );
        canvas.drawRRect(rr(74, 6, 82, 58, 5), fill..color = sunk);
        canvas.drawRRect(
          rr(74, 6, 82, 58, 5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = accent
            ..strokeWidth = 1.4,
        );
        canvas.drawRRect(
          rr(96, 14, 38, 42, 3),
          fill..color = accent.withValues(alpha: .18),
        );
      case 'linkedPreview':
        list();
        canvas.drawRRect(rr(46.5, 6.5, 110, 58, 5), stroke);
        for (var i = 0; i < 3; i++) {
          final r = rr(56 + i * 32.0, 16, 26, 38, 3);
          canvas.drawRRect(
            r,
            fill..color = i == 1 ? accent.withValues(alpha: .22) : control,
          );
          if (i == 1) {
            canvas.drawRRect(
              r,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = accent
                ..strokeWidth = 1.4,
            );
          }
        }
      case 'canvas':
        canvas.drawRRect(rr(4, 6, 152, 58, 5), fill..color = sunk);
        canvas.drawRRect(rr(4.5, 6.5, 151, 57, 5), stroke);
        for (final (i, (x, y)) in [
          (22.0, 14.0),
          (62.0, 10.0),
          (102.0, 18.0),
        ].indexed) {
          final r = rr(x, y, 32, 44, 3);
          canvas.drawRRect(r, fill..color = i == 1 ? tint : control);
          if (i == 1) {
            canvas.drawRRect(
              r,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = accent,
            );
          }
        }
      default:
        canvas.drawRRect(rr(4, 6, 152, 58, 5), fill..color = sunk);
        canvas.drawRRect(rr(4.5, 6.5, 151, 57, 5), stroke);
        final r = rr(60, 11, 40, 48, 3);
        canvas.drawRRect(r, fill..color = tint);
        canvas.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = accent,
        );
    }
  }

  @override
  bool shouldRepaint(_DiagramPainter o) =>
      o.kind != kind || o.accent != accent || o.line != line;
}

class SettingsCanvasPage extends StatelessWidget {
  const SettingsCanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final v = s.data.values;
    Widget choose(SettingKey key, String title) => SettingKeyRow(
      key,
      title: title,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      below: SettingsGrid(
        columns: 2,
        children: [
          for (final k in SettingSpec.of(key).choices)
            SettingsOptionCard(
              key: Key('${key.name}-$k'),
              selected: v.text(key) == k,
              preview: _Diagram(k),
              label: SettingsFormat.choice(context, key, k),
              description: switch (k) {
                'openDetail' => l.set_cvOpenDetailSub,
                'linkedPreview' => l.set_cvLinkedSub,
                'canvas' => l.set_cvCanvasSub,
                _ => l.set_cvSimpleSub,
              },
              onTap: () => s.actions.onChanged(key, k),
            ),
        ],
      ),
    );
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.canvas),
        title: l.set_pageCanvas,
        description: l.set_cvDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_cvOps,
          trailing: l.set_readOnly,
          child: SettingsAsideList(
            rows: [
              for (final (keys, label) in [
                ([l.set_cvWheel], l.set_cvOpScroll),
                (['Shift', l.set_cvWheel], l.set_cvOpPan),
                (['Ctrl', l.set_cvWheel], l.set_cvOpZoom),
                (['W', 'A', 'S', 'D'], l.set_cvOpMove),
                (['Ctrl', '0'], l.set_cvOpAll),
                (['Home'], l.set_cvOpHome),
              ])
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: UiText.sans(12, color: c.ink)),
                    ),
                    SettingsKeys(keys),
                  ],
                ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_cvChannelTip),
      ],
      children: [
        SettingsSection(
          title: l.set_cvBrowse,
          children: [
            choose(SettingKey.historyClick, l.set_cvHistoryClick),
            choose(SettingKey.outputViewer, l.set_cvViewer),
          ],
        ),
        SettingsSection(
          title: l.set_cvCanvasSec,
          children: [
            SettingKeyRow(
              SettingKey.canvasLockCamera,
              title: l.set_cvLock,
              subtitle: l.set_cvLockSub,
              control: const SetSwitch(SettingKey.canvasLockCamera),
            ),
            SettingKeyRow(
              SettingKey.canvasZoomToFill,
              title: l.set_cvFill,
              subtitle: l.set_cvFillSub,
              control: const SetSwitch(SettingKey.canvasZoomToFill),
            ),
          ],
        ),
        const _ChannelSection(),
      ],
    );
  }
}

class _ChannelSection extends StatefulWidget {
  const _ChannelSection();

  @override
  State<_ChannelSection> createState() => _ChannelSectionState();
}

class _ChannelSectionState extends State<_ChannelSection> {
  var _flash = false;

  static const _def = ChannelSettings();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final ch = s.data.canvas.channel;
    final off = ch.mode == ChannelMode.off;
    void set(ChannelSettings v) => s.actions.onChannelChanged(v);
    void tap(ChannelTheme t) {
      switch (ch.mode) {
        case ChannelMode.fixed:
          set(ch.copyWith(fixed: t));
        case ChannelMode.random:
          if (!ch.pool.contains(t)) {
            set(ch.copyWith(pool: {...ch.pool, t}));
          } else if (ch.pool.length <= 2) {
            setState(() => _flash = true);
          } else {
            set(ch.copyWith(pool: {...ch.pool}..remove(t)));
          }
        case ChannelMode.off:
          break;
      }
    }

    final env = ChannelEnv.of(ch);
    final order = env
        .sequenceFrom(0, math.min(env.order.length, 6))
        .map((t) => ChannelFormat.name(context, t))
        .join(' → ');
    Widget dim(Widget w) =>
        off ? IgnorePointer(child: Opacity(opacity: .4, child: w)) : w;
    SettingsRow row(
      String anchor,
      String title,
      String? sub,
      bool mod,
      VoidCallback reset,
      Widget control,
    ) => SettingsRow(
      anchor: anchor,
      title: title,
      subtitle: sub,
      modified: mod,
      onReset: reset,
      disabled: off && anchor != 'channelMode',
      control: control,
    );
    return SettingsSection(
      title: l.set_cvChannel,
      subtitle: l.set_cvChannelSub,
      children: [
        row(
          'channelMode',
          l.set_cvMode,
          null,
          ch.mode != _def.mode,
          () => set(ch.copyWith(mode: _def.mode)),
          UiSegmented<ChannelMode>(
            key: const Key('seg-channelMode'),
            values: ChannelMode.values,
            selected: ch.mode,
            labelOf: (m) => ChannelFormat.mode(context, m),
            onChanged: (m) => set(ch.copyWith(mode: m)),
          ),
        ),
        SettingsBlock(
          child: dim(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in ChannelTheme.values)
                      _ThemeCard(
                        theme: t,
                        seed: ch.seed,
                        on: ch.mode == ChannelMode.fixed
                            ? ch.fixed == t
                            : ch.pool.contains(t),
                        faded:
                            ch.mode == ChannelMode.random &&
                            !ch.pool.contains(t),
                        onTap: () => tap(t),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  spacing: 8,
                  children: [
                    UiGlyph(
                      UiGlyphs.infoCircle,
                      size: 13,
                      color: _flash ? c.warn : c.muted,
                    ),
                    Expanded(
                      child: Text(
                        ch.mode == ChannelMode.fixed
                            ? ChannelFormat.description(context, ch.fixed)
                            : '${l.set_cvMinTwo}${l.set_cvSession(order)}',
                        key: const Key('channel-order'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12,
                          color: _flash ? c.warn : c.muted,
                        ),
                      ),
                    ),
                    if (ch.mode == ChannelMode.random)
                      SettingsBtn(
                        key: const Key('channel-reroll'),
                        label: l.channel_reroll,
                        glyph: UiGlyphs.refresh,
                        small: true,
                        onTap: () => set(
                          ch.copyWith(seed: math.Random().nextInt(1 << 31)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        row(
          'channelLevel',
          l.set_cvLevel,
          null,
          ch.level != _def.level,
          () => set(ch.copyWith(level: _def.level)),
          UiSegmented<ChannelLevel>(
            values: ChannelLevel.values,
            selected: ch.level,
            labelOf: (x) => ChannelFormat.level(context, x),
            onChanged: (x) => set(ch.copyWith(level: x)),
          ),
        ),
        row(
          'channelRuler',
          l.set_cvRuler,
          l.set_cvRulerSub,
          ch.ruler != _def.ruler,
          () => set(ch.copyWith(ruler: _def.ruler)),
          SettingsSwitch(
            value: ch.ruler,
            onChanged: (x) => set(ch.copyWith(ruler: x)),
          ),
        ),
        row(
          'channelMotion',
          l.set_cvMotion,
          l.set_cvMotionSub,
          ch.motion != _def.motion,
          () => set(ch.copyWith(motion: _def.motion)),
          SettingsSwitch(
            value: ch.motion,
            onChanged: (x) => set(ch.copyWith(motion: x)),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.seed,
    required this.on,
    required this.faded,
    required this.onTap,
  });
  final ChannelTheme theme;
  final int seed;
  final bool on;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: Key('channel-theme-${theme.name}'),
      onTap: onTap,
      builder: (context, hover) => Opacity(
        opacity: faded ? .45 : 1,
        child: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Container(
                height: 64,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.sunk,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: on ? c.accent : (hover ? c.strong : c.border),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: ChannelThumbPainter(
                        theme: theme,
                        seed: seed,
                        dark: c.dark,
                        base: c.sunk,
                      ),
                    ),
                    Positioned(right: 6, top: 6, child: UiCheckBox(value: on)),
                  ],
                ),
              ),
              ChannelSwatchName(theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── 快捷键 ─────────────────────────────

class SettingsShortcutsPage extends StatefulWidget {
  const SettingsShortcutsPage({super.key});

  @override
  State<SettingsShortcutsPage> createState() => _SettingsShortcutsPageState();
}

class _SettingsShortcutsPageState extends State<SettingsShortcutsPage> {
  String? _context;
  var _query = '';
  var _layer = 'Ctrl';
  String? _key;
  String? _hover;
  String? _recording;
  var _contextInit = false;

  static const _mods = ['', 'Ctrl', 'Shift', 'Alt'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final data = s.data.shortcuts;
    if (!_contextInit) {
      _contextInit = true;
      _context = data.contexts.length > 1 ? data.contexts[1].id : null;
    }
    final q = _query.trim().toLowerCase();
    bool match(SettingsShortcut x) {
      if (q.isNotEmpty &&
          !x.label.toLowerCase().contains(q) &&
          !x.keys.join('+').toLowerCase().contains(q)) {
        return false;
      }
      if (_key != null) {
        final want = [if (_layer.isNotEmpty) _layer, _key!];
        if (!_same(x.keys, want)) return false;
      }
      return true;
    }

    // 选了某个上下文时，全局快捷键在那里同样生效，跟在后面一起列出（同原型）。
    final shown = _context == null
        ? data.contexts
        : [
            ...data.contexts.where((x) => x.id == _context),
            if (_context != 'global')
              ...data.contexts.where((x) => x.id == 'global'),
          ];
    final visible = [
      for (final ctx in shown)
        (
          ctx,
          data.shortcuts.where((x) => x.context == ctx.id && match(x)).toList(),
        ),
    ].where((e) => e.$2.isNotEmpty).toList();
    final conflicts = <(SettingsShortcut, SettingsShortcut)>[];
    for (final x in data.shortcuts) {
      final o = data.shortcuts.where((y) => y.id == x.conflictWith).firstOrNull;
      if (o != null &&
          x.changed &&
          !conflicts.any((p) => p.$1.id == o.id || p.$2.id == o.id)) {
        conflicts.add((o, x));
      }
    }
    final customized = data.shortcuts.where((x) => x.changed).length;
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.shortcuts),
        title: l.set_pageShortcuts,
        description: l.set_scDesc,
      ),
      top: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SettingsInput(
                  key: const Key('shortcut-search'),
                  width: 280,
                  value: _query,
                  hint: l.set_scSearch,
                  leading: UiGlyph(UiGlyphs.search, size: 14, color: c.faint),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              SettingsChip(
                label: l.set_scAll,
                count: data.shortcuts.length,
                selected: _context == null,
                onTap: () => setState(() => _context = null),
              ),
              for (final ctx in data.contexts)
                SettingsChip(
                  key: Key('shortcut-context-${ctx.id}'),
                  label: ctx.label,
                  count: data.shortcuts
                      .where((x) => x.context == ctx.id)
                      .length,
                  selected: _context == ctx.id,
                  onTap: () => setState(() => _context = ctx.id),
                ),
            ],
          ),
        ),
      ],
      aside: [
        SettingsAsideCard(
          title: l.set_scDisplay,
          child: SettingsAsideList(
            rows: [
              for (final (k, t) in [
                (SettingKey.shortcutsEnabled, l.set_scEnabled),
                (SettingKey.shortcutsInTooltips, l.set_scInTooltips),
                (SettingKey.shortcutsInMenus, l.set_scInMenus),
                (SettingKey.navNumberBadges, l.set_scBadges),
              ])
                SettingsAnchor(
                  anchor: k.name,
                  radius: 6,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t, style: UiText.sans(12, color: c.ink)),
                      ),
                      SetSwitch(k),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SettingsAsideCard(
          key: const Key('shortcut-conflicts'),
          title: l.set_scConflicts,
          trailing: conflicts.isEmpty
              ? null
              : l.set_scConflictCount('${conflicts.length}'),
          child: conflicts.isEmpty
              ? Row(
                  spacing: 8,
                  children: [
                    const SettingsDot(SettingsTone.ok),
                    Text(
                      l.set_scNoConflict,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (a, b) in conflicts) ...[
                      Row(
                        spacing: 8,
                        children: [
                          const SettingsDot(SettingsTone.error),
                          Expanded(
                            child: Text(
                              l.set_scConflictLine(b.keys.join('+')),
                              style: UiText.sans(12, color: c.ink),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 6, 0, 10),
                        child: Text(
                          l.set_scConflictSub(
                            data.contexts
                                    .where((x) => x.id == b.context)
                                    .firstOrNull
                                    ?.label ??
                                b.context,
                            a.label,
                            b.label,
                          ),
                          style: UiText.sans(11, color: c.muted, height: 1.5),
                        ),
                      ),
                      SettingsBtn(
                        key: Key('shortcut-fix-${b.id}'),
                        label: l.set_scFix(b.label, b.defaultKeys.join('+')),
                        small: true,
                        onTap: () => s.actions.onShortcutReset(b.id),
                      ),
                    ],
                  ],
                ),
        ),
        SettingsAsideCard(
          title: l.set_scConfig,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                spacing: 6,
                children: [
                  SettingsBtn(
                    label: l.set_importIt,
                    glyph: UiGlyphs.download,
                    small: true,
                    onTap: s.actions.onShortcutsImport,
                  ),
                  SettingsBtn(
                    label: l.set_exportIt,
                    glyph: SettingsGlyphs.upload,
                    small: true,
                    onTap: s.actions.onShortcutsExport,
                  ),
                ],
              ),
              SettingsBtn(
                key: const Key('shortcut-reset-all'),
                label: l.set_scResetAll,
                small: true,
                tone: SettingsBtnTone.danger,
                onTap: customized == 0
                    ? null
                    : () => s.confirm(
                        title: l.set_scResetAllTitle,
                        body: l.set_scResetAllBody('$customized'),
                        confirm: l.set_resetDefault,
                        danger: true,
                        onConfirm: s.actions.onShortcutsResetAll,
                      ),
              ),
            ],
          ),
        ),
        SettingsHint(
          child: SettingsKeyText(
            text: SettingsFormat.keyed((k) => l.set_scHelpTip(k)),
            keys: const ['F1'],
            style: UiText.sans(12, color: c.muted, height: 1.6),
          ),
        ),
      ],
      children: [
        SettingsSection(
          title: l.set_scKeyboard,
          subtitle: l.set_scKeyboardSub,
          children: [_keyboard(context, data)],
        ),
        for (final (ctx, list) in visible)
          SettingsSection(
            title: ctx.label,
            children: [
              _ShortcutTable(
                shortcuts: list,
                all: data.shortcuts,
                recording: _recording,
                onRecord: (id) => setState(() => _recording = id),
                onStop: () => setState(() => _recording = null),
              ),
            ],
          ),
        if (visible.isEmpty)
          SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(36),
                child: Center(
                  child: Text(
                    l.set_scEmpty,
                    style: UiText.sans(12.5, color: c.muted),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 组合是否相同；`1…9` 这类区间匹配其中任一键。
  static bool _same(List<String> a, List<String> b) =>
      a.length == b.length &&
      a.isNotEmpty &&
      _keyMatch(a.last, b.last) &&
      [
        for (var i = 0; i < a.length - 1; i++)
          a[i].toUpperCase() == b[i].toUpperCase(),
      ].every((x) => x);

  static bool _keyMatch(String a, String b) {
    if (a.toUpperCase() == b.toUpperCase()) return true;
    final r = RegExp(r'^(\d)…(\d)$');
    final m = r.firstMatch(a) ?? r.firstMatch(b);
    if (m == null) return false;
    final k = m.input == a ? b : a;
    final n = int.tryParse(k);
    return n != null && n >= int.parse(m[1]!) && n <= int.parse(m[2]!);
  }

  static const _rows = <List<(String, double)>>[
    [
      ('`', 1),
      ('1', 1),
      ('2', 1),
      ('3', 1),
      ('4', 1),
      ('5', 1),
      ('6', 1),
      ('7', 1),
      ('8', 1),
      ('9', 1),
      ('0', 1),
      ('-', 1),
      ('=', 1),
      ('Backspace', 2),
    ],
    [
      ('Tab', 1.5),
      ('Q', 1),
      ('W', 1),
      ('E', 1),
      ('R', 1),
      ('T', 1),
      ('Y', 1),
      ('U', 1),
      ('I', 1),
      ('O', 1),
      ('P', 1),
      ('[', 1),
      (']', 1),
      ('\\', 1.5),
    ],
    [
      ('Caps', 1.8),
      ('A', 1),
      ('S', 1),
      ('D', 1),
      ('F', 1),
      ('G', 1),
      ('H', 1),
      ('J', 1),
      ('K', 1),
      ('L', 1),
      (';', 1),
      ("'", 1),
      ('Enter', 2.2),
    ],
    [
      ('Shift', 2.3),
      ('Z', 1),
      ('X', 1),
      ('C', 1),
      ('V', 1),
      ('B', 1),
      ('N', 1),
      ('M', 1),
      (',', 1),
      ('.', 1),
      ('/', 1),
      ('Shift', 2.7),
    ],
    [
      ('Ctrl', 1.5),
      ('Win', 1.2),
      ('Alt', 1.2),
      ('Space', 7.2),
      ('Alt', 1.2),
      ('Fn', 1.2),
      ('Ctrl', 1.5),
    ],
  ];

  Widget _keyboard(BuildContext context, SettingsShortcutsData data) {
    final l = context.l10n;
    final c = context.ui;
    final ctxLabel = _context == null
        ? l.set_scAll
        : data.contexts.where((x) => x.id == _context).firstOrNull?.label ?? '';
    final scope = data.shortcuts
        .where((x) => _context == null || x.context == _context)
        .toList();
    List<SettingsShortcut> at(String key) => scope
        .where((x) => _same(x.keys, [if (_layer.isNotEmpty) _layer, key]))
        .toList();
    final focus = _hover ?? _key;
    final focusHits = focus == null ? const <SettingsShortcut>[] : at(focus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Row(
            spacing: 10,
            children: [
              UiSegmented<String>(
                key: const Key('shortcut-layer'),
                values: _mods,
                selected: _layer,
                labelOf: (m) => m.isEmpty ? l.set_scNoMod : m,
                onChanged: (m) => setState(() {
                  _layer = m;
                  _key = null;
                }),
              ),
              Flexible(
                child: Text(
                  _layer.isEmpty
                      ? l.set_scLayerNone(ctxLabel)
                      : l.set_scLayer(ctxLabel, _layer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.faint),
                ),
              ),
              const Spacer(),
              if (focusHits.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    SettingsKey(focus!),
                    Text(
                      focusHits.map((x) => x.label).join(' / '),
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 第一行 15 个单位宽、14 个间隔，外加 Backspace 多出的一个间隔。
              final u = math.min(44.8, (constraints.maxWidth - 75) / 15);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  for (final row in _rows)
                    Row(
                      spacing: 5,
                      children: [
                        for (final (k, w) in row)
                          _keycap(context, k, w * u + (w - 1) * 5, at(k)),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _keycap(
    BuildContext context,
    String k,
    double width,
    List<SettingsShortcut> hits,
  ) {
    final c = context.ui;
    final isMod = k == _layer && _layer.isNotEmpty;
    final conflict = hits.length > 1 || hits.any((x) => x.conflictWith != null);
    final bound = hits.isNotEmpty;
    final selected = _key == k;
    final (bg, border, ink) = isMod
        ? (c.ink, c.ink, c.bg)
        : conflict
        ? (
            Color.alphaBlend(c.error.withValues(alpha: .08), c.card),
            c.error,
            c.ink,
          )
        : bound
        ? (
            Color.alphaBlend(c.accent.withValues(alpha: .08), c.card),
            Color.lerp(c.border, c.accent, .35)!,
            c.ink,
          )
        : (c.sunk, c.border, c.faint);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = k),
      onExit: (_) => setState(() => _hover = null),
      child: UiPressable(
        key: Key('key-$k'),
        onTap: isMod || !bound
            ? null
            : () => setState(() => _key = selected ? null : k),
        builder: (context, _) => Container(
          width: width,
          height: 34,
          padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(color: border),
              top: BorderSide(color: border),
              right: BorderSide(color: border),
              bottom: BorderSide(color: border, width: 2),
            ),
            boxShadow: selected || _hover == k && bound
                ? [BoxShadow(color: c.accent, spreadRadius: 2)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                k,
                maxLines: 1,
                style: UiText.mono(
                  10.5,
                  weight: FontWeight.w500,
                  color: ink,
                  height: 1.1,
                ),
              ),
              if (bound)
                Text(
                  hits.first.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    9,
                    weight: FontWeight.w500,
                    color: conflict ? c.error : c.accent,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTable extends StatelessWidget {
  const _ShortcutTable({
    required this.shortcuts,
    required this.all,
    required this.recording,
    required this.onRecord,
    required this.onStop,
  });

  final List<SettingsShortcut> shortcuts;
  final List<SettingsShortcut> all;
  final String? recording;
  final ValueChanged<String> onRecord;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final TextStyle head = UiText.sans(
      11,
      weight: FontWeight.w500,
      color: c.faint,
    );
    Widget cells(
      List<Widget> children, {
      Color? bg,
      Key? key,
      EdgeInsets? pad,
    }) => Container(
      key: key,
      color: bg,
      padding: pad ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Row(
            children: [
              SizedBox(width: w * .46 - 18, child: children[0]),
              Expanded(child: children[1]),
              SizedBox(width: 120, child: children[2]),
              SizedBox(
                width: 52,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: children[3],
                ),
              ),
            ],
          );
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cells([
          Text(l.set_scAction, style: head),
          Text(l.set_scKeys, style: head),
          Text(l.set_scDefault, style: head),
          const SizedBox(),
        ], pad: const EdgeInsets.fromLTRB(18, 12, 18, 8)),
        for (final x in shortcuts) ...[
          Container(height: 1, color: c.rowLine),
          SettingsAnchor(
            anchor: 'shortcut-${x.id}',
            radius: 0,
            child: cells(
              key: Key('shortcut-${x.id}'),
              bg: recording == x.id
                  ? c.accent.withValues(alpha: .06)
                  : x.conflictWith != null
                  ? c.error.withValues(alpha: .05)
                  : null,
              [
                Row(
                  key: Key('shortcut-label-${x.id}'),
                  spacing: 8,
                  children: [
                    Flexible(
                      child: SettingsModMark(
                        on: x.changed,
                        child: Text(
                          x.label,
                          style: UiText.sans(12.5, color: c.ink),
                        ),
                      ),
                    ),
                    if (x.conflictWith != null)
                      Flexible(
                        child: UiMini(
                          l.set_scConflict(
                            all
                                    .where((y) => y.id == x.conflictWith)
                                    .firstOrNull
                                    ?.label ??
                                '',
                          ),
                          tone: UiMiniTone.error,
                        ),
                      ),
                  ],
                ),
                recording == x.id
                    ? _Recorder(
                        onKeys: (keys) {
                          onStop();
                          s.actions.onShortcutRecorded(x.id, keys);
                        },
                        onClear: () {
                          onStop();
                          s.actions.onShortcutCleared(x.id);
                        },
                        onCancel: onStop,
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: UiPressable(
                          key: Key('shortcut-keys-${x.id}'),
                          onTap: () => onRecord(x.id),
                          builder: (context, hover) => x.keys.isEmpty
                              ? Text(
                                  l.set_notSet,
                                  style: UiText.sans(
                                    12,
                                    color: hover ? c.accent : c.faint,
                                  ),
                                )
                              : SettingsKeys(x.keys),
                        ),
                      ),
                Text(
                  x.changed && x.defaultKeys.isNotEmpty
                      ? l.set_scDefaultIs(x.defaultKeys.join('+'))
                      : '',
                  style: UiText.sans(11, color: c.faint),
                ),
                x.changed
                    ? SettingsIconBtn(
                        key: Key('shortcut-reset-${x.id}'),
                        glyph: SettingsGlyphs.undo,
                        tooltip: l.set_resetDefault,
                        onTap: () => s.actions.onShortcutReset(x.id),
                      )
                    : SettingsMoreButton(
                        items: [
                          (l.set_scRecord, () => onRecord(x.id), false),
                          if (x.keys.isNotEmpty)
                            (
                              l.set_scClear,
                              () => s.actions.onShortcutCleared(x.id),
                              true,
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 录制框：按下组合键即回调；Esc 取消，Backspace 清除。
class _Recorder extends StatefulWidget {
  const _Recorder({
    required this.onKeys,
    required this.onClear,
    required this.onCancel,
  });
  final ValueChanged<List<String>> onKeys;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  @override
  State<_Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<_Recorder> {
  final _focus = FocusNode(debugLabel: 'shortcut-recorder');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static final _modifiers = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  static String _label(LogicalKeyboardKey k) => switch (k) {
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.arrowDown => '↓',
    LogicalKeyboardKey.arrowLeft => '←',
    LogicalKeyboardKey.arrowRight => '→',
    LogicalKeyboardKey.space => 'Space',
    LogicalKeyboardKey.escape => 'Esc',
    _ => k.keyLabel.length == 1 ? k.keyLabel.toUpperCase() : k.keyLabel,
  };

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    final k = e.logicalKey;
    if (_modifiers.contains(k)) return KeyEventResult.handled;
    final hw = HardwareKeyboard.instance;
    final hasMod = hw.isControlPressed || hw.isShiftPressed || hw.isAltPressed;
    if (!hasMod && k == LogicalKeyboardKey.escape) {
      widget.onCancel();
    } else if (!hasMod && k == LogicalKeyboardKey.backspace) {
      widget.onClear();
    } else {
      widget.onKeys([
        if (hw.isControlPressed) 'Ctrl',
        if (hw.isShiftPressed) 'Shift',
        if (hw.isAltPressed) 'Alt',
        _label(k),
      ]);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      onFocusChange: (on) {
        if (!on) widget.onCancel();
      },
      child: Row(
        spacing: 8,
        children: [
          Container(
            key: const Key('shortcut-recorder'),
            width: 190,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: c.accent),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: .16),
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Text(
              l.set_scRecording,
              maxLines: 1,
              style: UiText.sans(12, color: c.accent, height: 1.2),
            ),
          ),
          Flexible(
            child: Text(
              l.set_scRecordHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}
