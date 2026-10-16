import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_controls.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_overview.dart';
import 'settings_scope.dart';

// ───────────────────────────── 生成与额度 ─────────────────────────────

class SettingsGenerationPage extends StatelessWidget {
  const SettingsGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final v = d.values;
    final warnOn = v.flag(SettingKey.costWarning);
    final threshold = v.number(SettingKey.costThreshold);
    final limit = v.flag(SettingKey.intervalLimit);
    final est = d.generation.estimate;
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.generation),
        title: l.set_pageGeneration,
        description: l.set_gnDesc,
      ),
      aside: [
        SettingsAsideCard(
          title: l.set_gnToday,
          trailing: l.set_readOnly,
          child: _TodayUsage(data: d),
        ),
        SettingsHint.text(context, l.set_gnFreeTip),
      ],
      children: [
        SettingsSection(
          title: l.set_gnCost,
          subtitle: l.set_gnCostSub,
          children: [
            SettingKeyRow(
              SettingKey.costWarning,
              title: l.set_gnWarn,
              subtitle: l.set_gnWarnSub,
              control: const SetSwitch(SettingKey.costWarning),
            ),
            SettingKeyRow(
              SettingKey.costThreshold,
              title: l.set_gnThreshold,
              sub: true,
              disabled: !warnOn,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  for (final p in const [20, 50, 100, 200])
                    SettingsChip(
                      key: Key('threshold-$p'),
                      label: '$p',
                      selected: threshold == p,
                      onTap: () => s.actions.onChanged(
                        SettingKey.costThreshold,
                        p.toDouble(),
                      ),
                    ),
                  const SetStepper(SettingKey.costThreshold, unit: 'Anlas'),
                ],
              ),
            ),
            if (est != null)
              SettingsBlock(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Container(
                  key: const Key('cost-estimate'),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: c.sunk,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      UiGlyph(UiGlyphs.bolt, size: 14, color: c.accent),
                      Expanded(
                        child: Text(
                          l.set_gnEstimate(
                            est.model,
                            '${est.width}',
                            '${est.height}',
                            '${est.steps}',
                            '${est.images}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.ink),
                        ),
                      ),
                      Text(
                        est.cost == 0
                            ? l.set_gnFree
                            : '${SettingsFormat.count(est.cost)} Anlas',
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w500,
                          color: c.ink,
                        ),
                      ),
                      if (warnOn && est.cost >= threshold)
                        UiMini(l.set_gnWillWarn, tone: UiMiniTone.warn)
                      else
                        UiMini(l.set_gnNoWarn, tone: UiMiniTone.ok),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SettingsSection(
          title: l.set_gnPace,
          subtitle: l.set_gnPaceSub,
          children: [
            SettingKeyRow(
              SettingKey.intervalLimit,
              title: l.set_gnLimit,
              control: const SetSwitch(SettingKey.intervalLimit),
            ),
            SettingKeyRow(
              SettingKey.intervalSeconds,
              title: l.set_gnInterval,
              sub: true,
              disabled: !limit,
              control: SetStepper(
                SettingKey.intervalSeconds,
                unit: l.set_unitSeconds,
              ),
            ),
            SettingKeyRow(
              SettingKey.intervalJitter,
              title: l.set_gnJitter,
              subtitle: l.set_gnJitterSub,
              sub: true,
              disabled: !limit,
              control: SetSlider(
                SettingKey.intervalJitter,
                ticks: 5,
                label: (x) => '±${x.round()}%',
              ),
            ),
            SettingsBlock(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              child: Opacity(
                opacity: limit ? 1 : .45,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        l.set_gnTimeline,
                        style: UiText.sans(11, color: c.faint),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: CustomPaint(
                        key: const Key('pace-timeline'),
                        size: Size.infinite,
                        painter: _TimelinePainter(
                          seconds: v.number(SettingKey.intervalSeconds),
                          jitter: v.number(SettingKey.intervalJitter) / 100,
                          line: c.border,
                          accent: c.accent,
                          label: c.faint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_gnInput,
          children: [
            SettingKeyRow(
              SettingKey.wheelWeight,
              title: l.set_gnWheel,
              subtitle: l.set_gnWheelSub,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (v.flag(SettingKey.wheelWeight))
                    const SetSeg(SettingKey.wheelModifier),
                  const SetSwitch(SettingKey.wheelWeight),
                ],
              ),
            ),
            SettingKeyRow(
              SettingKey.relatedTags,
              title: l.set_gnRelated,
              subtitle: l.set_gnRelatedSub,
              control: const SetSwitch(SettingKey.relatedTags),
            ),
            SettingsRow(
              title: l.set_gnRag,
              subtitle: l.set_gnRagSub,
              control: SettingsJump(
                page: SettingsPageId.rag,
                label: l.set_gnGoSettings,
                value: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    SettingsDot(
                      d.generation.ragTagsReady
                          ? SettingsTone.ok
                          : SettingsTone.idle,
                    ),
                    Text(
                      d.generation.ragTagsReady
                          ? l.set_gnReady
                          : l.set_gnNotReady,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
            SettingsRow(
              title: l.set_gnTranslate,
              subtitle: l.set_gnTranslateSub,
              control: SettingsJump(
                page: SettingsPageId.models,
                value: Text(
                  d.generation.translationModel ?? l.set_tileNoModel,
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayUsage extends StatelessWidget {
  const _TodayUsage({required this.data});
  final SettingsViewData data;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final g = data.generation;
    final bars = g.hourlyUsage;
    final peak = bars.fold<int>(1, math.max);
    final start = data.now.subtract(
      Duration(hours: math.max(0, bars.length - 1)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 6,
          children: [
            Text(
              SettingsFormat.count(data.account.todayUsed),
              style: settingsBig(context, size: 26),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(l.set_gnUsed, style: UiText.sans(12, color: c.muted)),
            ),
          ],
        ),
        if (bars.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 4,
              children: [
                for (final b in bars)
                  Expanded(
                    child: Container(
                      height: 4 + 34 * b / peak,
                      decoration: BoxDecoration(
                        color: c.accent.withValues(
                          alpha: b / peak > .7 ? .8 : .35,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${SettingsFormat.two(start.hour)}:00',
                style: UiText.sans(11, color: c.faint),
              ),
              const Spacer(),
              Text(l.set_gnNow, style: UiText.sans(11, color: c.faint)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        SettingsAsideList(
          rows: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.set_gnWarned,
                    style: UiText.sans(12, color: c.ink),
                  ),
                ),
                Text(
                  l.set_gnTimes('${g.warningsToday}'),
                  style: UiText.mono(12, color: c.ink),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.set_gnMaxSingle,
                    style: UiText.sans(12, color: c.ink),
                  ),
                ),
                Text(
                  '${g.maxSingleToday}',
                  style: UiText.mono(12, color: c.ink),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 10 次请求的时间分布：方块是请求，上方小字是间隔秒数。抖动序列固定，便于对照。
class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.seconds,
    required this.jitter,
    required this.line,
    required this.accent,
    required this.label,
  });

  final double seconds;
  final double jitter;
  final Color line;
  final Color accent;
  final Color label;

  static const _r = [0.0, .67, -.67, .17, -.33, .83, -.83, .33, -.17];

  @override
  void paint(Canvas canvas, Size size) {
    final gaps = [for (final r in _r) math.max(.1, seconds * (1 + jitter * r))];
    final total = gaps.fold<double>(0, (s, g) => s + g);
    final pxPerSec = math.min(
      19 * 3 / math.max(seconds, .1),
      (size.width - 24 - 160) / total,
    );
    canvas.drawLine(
      const Offset(0, 30.5),
      Offset(size.width, 30.5),
      Paint()..color = line,
    );
    var x = 12.0;
    for (var i = 0; i < 10; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 20, 16, 20),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        r,
        Paint()..color = accent.withValues(alpha: i == 9 ? .10 : .24),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = accent.withValues(alpha: i == 9 ? .6 : 1)
          ..style = PaintingStyle.stroke,
      );
      if (i < 9) {
        final w = gaps[i] * pxPerSec;
        final tp = TextPainter(
          text: TextSpan(
            text: '${gaps[i].toStringAsFixed(1)}s',
            style: UiText.mono(9.5, color: label, height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 16 + w / 2 - tp.width / 2, 4));
        x += 16 + w;
      }
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter o) =>
      o.seconds != seconds ||
      o.jitter != jitter ||
      o.accent != accent ||
      o.line != line;
}

// ───────────────────────────── 存储与图库 ─────────────────────────────

class SettingsStoragePage extends StatelessWidget {
  const SettingsStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final st = d.storage;
    final total = st.totalBytes;
    String kindName(SettingsStorageKind k) => switch (k) {
      SettingsStorageKind.images => l.set_stImages,
      SettingsStorageKind.upscaleModels => l.set_stUpscaleModels,
      SettingsStorageKind.vibes => l.set_stVibes,
      SettingsStorageKind.thumbnails => l.set_stThumbs,
      SettingsStorageKind.ragIndex => l.set_stRag,
      SettingsStorageKind.dictionaries => l.set_stDict,
      SettingsStorageKind.agent => l.set_stAgent,
    };
    String folderName(SettingsFolder f) => switch (f) {
      SettingsFolder.images => l.set_stImages,
      SettingsFolder.vibes => l.set_stVibes,
      SettingsFolder.thumbnails => l.set_stThumbs,
      SettingsFolder.appData => l.set_stAppDataShort,
      SettingsFolder.logs => l.set_stLogs,
      SettingsFolder.agent => l.set_stAgent,
    };
    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.storage),
        title: l.set_pageStorage,
        description: l.set_stDesc,
      ),
      top: [if (d.restartPending) const SettingsRestartBanner()],
      aside: [
        SettingsAsideCard(
          title: l.set_stOpenFolders,
          child: SettingsAsideList(
            rows: [
              for (final f in [
                SettingsFolder.images,
                SettingsFolder.vibes,
                SettingsFolder.thumbnails,
                SettingsFolder.appData,
                SettingsFolder.logs,
              ])
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        folderName(f),
                        style: UiText.sans(12, color: c.ink),
                      ),
                    ),
                    Text(
                      st.folderNames[f] ?? '',
                      style: UiText.mono(11, color: c.faint),
                    ),
                    SettingsIconBtn(
                      key: Key('open-folder-${f.name}'),
                      glyph: SettingsGlyphs.external,
                      glyphSize: 13,
                      tooltip: l.set_open,
                      onTap: () => s.actions.onOpenFolder(f),
                    ),
                  ],
                ),
            ],
          ),
        ),
        SettingsHint.text(context, l.set_stDeleteTip),
      ],
      children: [
        SettingsSection(
          title: l.set_stUsage,
          children: [
            SettingsBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8,
                    children: [
                      Text(
                        st.slices.isEmpty ? '—' : SettingsFormat.gb(total),
                        style: settingsBig(context, size: 28),
                      ),
                      Text('GB', style: UiText.sans(12, color: c.muted)),
                      const Spacer(),
                      if (st.diskFree != null)
                        Text(
                          l.set_stFree(
                            st.diskLabel,
                            SettingsFormat.bytes(st.diskFree!),
                          ),
                          style: UiText.sans(12, color: c.faint),
                        ),
                      SettingsBtn(
                        label: st.computing
                            ? l.set_stCounting
                            : l.set_stRecount,
                        glyph: UiGlyphs.refresh,
                        small: true,
                        tone: SettingsBtnTone.ghost,
                        onTap: st.computing
                            ? null
                            : s.actions.onRecomputeStorage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final n = st.slices.length;
                        final room =
                            constraints.maxWidth - 2 * math.max(0, n - 1);
                        return Row(
                          spacing: 2,
                          children: [
                            for (final p in st.slices)
                              Container(
                                width:
                                    3 +
                                    math.max(0, room - 3 * n) *
                                        p.bytes /
                                        (total == 0 ? 1 : total),
                                decoration: BoxDecoration(
                                  color: c.storage(p.kind),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 600 ? 4 : 2;
                      final w = (constraints.maxWidth - 16 * (cols - 1)) / cols;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          for (final p in st.slices)
                            SizedBox(
                              width: w,
                              child: Row(
                                spacing: 8,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: c.storage(p.kind),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      kindName(p.kind),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: UiText.sans(12, color: c.muted),
                                    ),
                                  ),
                                  Text(
                                    SettingsFormat.bytes(p.bytes),
                                    style: UiText.mono(12, color: c.ink),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_stSave,
          children: [
            SettingKeyRow(
              SettingKey.imageSavePath,
              title: l.set_stSavePath,
              control: const SetPath(SettingKey.imageSavePath),
            ),
            SettingKeyRow(
              SettingKey.autoSave,
              title: l.set_stAutoSave,
              subtitle: l.set_stAutoSaveSub,
              control: const SetSwitch(SettingKey.autoSave),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_stAssets,
          children: [
            SettingKeyRow(
              SettingKey.vibePath,
              title: l.set_stVibePath,
              control: const SetPath(
                SettingKey.vibePath,
                defaultPath: r'Documents\NAI_Launcher\vibes',
              ),
            ),
            SettingKeyRow(
              SettingKey.galleryQuality,
              title: l.set_stQuality,
              subtitle: l.set_stQualitySub,
              control: const SetSeg(SettingKey.galleryQuality),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_stRoots,
          subtitle: l.set_stRootsSub,
          children: [
            for (final r in st.roots)
              SettingsRow(
                key: Key('root-${r.id}'),
                minHeight: 50,
                leading: UiGlyph(
                  SettingsGlyphs.folder,
                  size: 16,
                  color: c.faint,
                ),
                title: r.path,
                titleStyle: UiText.mono(12.5, color: c.ink),
                badges: [if (r.primary) UiMini(l.set_stPrimary)],
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        st.slices.isEmpty
                            ? '—'
                            : l.set_stCount(SettingsFormat.count(r.images)),
                        style: UiText.mono(12, color: c.muted),
                      ),
                    ),
                    SettingsIconBtn(
                      glyph: SettingsGlyphs.external,
                      tooltip: l.set_open,
                      onTap: () => s.actions.onOpenGalleryRoot(r.id),
                    ),
                    if (r.primary)
                      const SizedBox(width: 26)
                    else
                      SettingsIconBtn(
                        key: Key('root-remove-${r.id}'),
                        glyph: UiGlyphs.close,
                        tooltip: l.set_stRemoveRoot,
                        onTap: () => s.actions.onRemoveGalleryRoot(r.id),
                      ),
                  ],
                ),
              ),
            SettingsBlock(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SettingsBtn(
                    label: l.set_stAddFolder,
                    glyph: UiGlyphs.plus,
                    onTap: s.actions.onAddGalleryRoot,
                  ),
                  SettingsBtn(
                    label: l.set_stImportIndex,
                    glyph: SettingsGlyphs.file,
                    onTap: s.actions.onImportTagIndex,
                  ),
                  if (st.lastScanAt != null)
                    Text(
                      l.set_stLastScan(
                        SettingsFormat.ago(context, st.lastScanAt!, d.now),
                        SettingsFormat.count(st.imageCount),
                      ),
                      style: UiText.sans(11, color: c.faint),
                    ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_stMaintain,
          children: [
            SettingsRow(
              anchor: 'rescan',
              title: l.set_stRescan,
              subtitle: l.set_stRescanSub,
              control: SettingsBtn(
                key: const Key('rescan'),
                label: st.scanning ? l.set_stScanning : l.set_stScan,
                glyph: UiGlyphs.refresh,
                small: true,
                onTap: st.scanning ? null : s.actions.onRescanGallery,
              ),
            ),
            SettingsRow(
              title: l.set_stCleanThumbs,
              subtitle: l.set_stCleanThumbsSub,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(
                    '${st.slices.isEmpty ? '—' : SettingsFormat.gb(st.thumbnailBytes)} / ${SettingsFormat.bytes(st.thumbnailLimit)}',
                    style: UiText.mono(12, color: c.muted),
                  ),
                  SettingsBtn(
                    key: const Key('clean-thumbs'),
                    label: l.set_stClean,
                    small: true,
                    onTap: () => s.confirm(
                      title: l.set_stCleanTitle,
                      body: l.set_stCleanBody,
                      confirm: l.set_stClean,
                      onConfirm: s.actions.onCleanThumbnails,
                    ),
                  ),
                ],
              ),
            ),
            SettingKeyRow(
              SettingKey.appDataPath,
              title: l.set_stAppData,
              subtitle: l.set_stAppDataSub,
              control: const SetPath(
                SettingKey.appDataPath,
                width: 300,
                open: false,
                defaultPath: './user-data/hive',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 词库与缓存 ─────────────────────────────

class SettingsDictionaryPage extends StatelessWidget {
  const SettingsDictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final s = SettingsScope.of(context);
    final d = s.data;
    final dc = d.dictionaries;
    Widget cache(SettingsCacheKind k, String title, String sub) {
      final retained = dc.caches[k];
      final (n, b) = retained ?? (0, 0);
      return SettingsRow(
        anchor: 'cache-${k.name}',
        title: title,
        subtitle: sub,
        control: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              retained == null
                  ? '—'
                  : l.set_dcCacheSize(
                      SettingsFormat.count(n),
                      SettingsFormat.bytes(b),
                    ),
              style: UiText.mono(12, color: c.muted),
            ),
            SettingsBtn(
              key: Key('clear-${k.name}'),
              label: l.set_clear,
              glyph: SettingsGlyphs.trash,
              small: true,
              onTap: n == 0
                  ? null
                  : () => s.confirm(
                      title: l.set_dcClearTitle(title),
                      body: l.set_dcClearBody,
                      confirm: l.set_clear,
                      danger: true,
                      onConfirm: () => s.actions.onClearCache(k),
                    ),
            ),
          ],
        ),
      );
    }

    Widget hit(String title, SettingsCacheStat? x) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: UiText.sans(12, color: c.muted)),
              ),
              Text(
                x?.hitRate == null ? '—' : SettingsFormat.percent(x!.hitRate!),
                style: UiText.mono(12, weight: FontWeight.w500, color: c.ink),
              ),
            ],
          ),
          SettingsBar(value: x?.hitRate ?? 0),
          Text(
            x == null
                ? ''
                : x.images
                ? l.set_dcImagesUnit(SettingsFormat.count(x.entries))
                : l.set_dcEntries(SettingsFormat.count(x.entries)),
            style: UiText.mono(11, color: c.faint),
          ),
        ],
      ),
    );

    return SettingsPageFrame(
      title: SettingsPageTitle(
        eyebrow: SettingsFormat.eyebrow(SettingsPageId.dictionaries),
        title: l.set_pageDictionaries,
        description: l.set_dcDesc,
      ),
      aside: [SettingsHint.text(context, l.set_dcTip)],
      children: [
        SettingsSection(
          title: l.set_dcTags,
          subtitle: l.set_dcTagsSub,
          children: [
            SettingsRow(
              title: l.set_dcBase,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  SettingsDot(
                    dc.tagCount > 0 ? SettingsTone.ok : SettingsTone.idle,
                  ),
                  Text(
                    l.set_dcBaseValue(
                      SettingsFormat.count(dc.tagCount),
                      dc.dataVersion,
                    ),
                    style: UiText.sans(12, color: c.ink),
                  ),
                ],
              ),
            ),
            SettingsRow(
              title: l.set_dcCooc,
              subtitle: l.set_dcCoocSub,
              control: Text(
                l.set_dcEntries(SettingsFormat.count(dc.cooccurrence)),
                style: UiText.mono(12, color: c.ink),
              ),
            ),
            SettingsRow(
              title: l.set_dcTranslate,
              subtitle: l.set_dcTranslateSub,
              control: SettingsJump(
                page: SettingsPageId.models,
                value: Text(
                  dc.translationModel ?? l.set_tileNoModel,
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: l.set_dcCaches,
          subtitle: l.set_dcCachesSub,
          children: [
            cache(
              SettingsCacheKind.danbooru,
              l.set_dcDanbooru,
              l.set_dcDanbooruSub,
            ),
            cache(
              SettingsCacheKind.translation,
              l.set_dcTranslation,
              l.set_dcTranslationSub,
            ),
          ],
        ),
        SettingsSection(
          title: l.set_dcStats,
          children: [
            SettingsBlock(
              child: Row(
                spacing: 16,
                children: [
                  hit(l.set_dcL1, dc.l1),
                  hit(l.set_dcL2, dc.l2),
                  hit(l.set_dcL3, dc.l3),
                ],
              ),
            ),
            SettingKeyRow(
              SettingKey.cacheStatsAutoRefresh,
              title: l.set_dcAutoRefresh,
              subtitle: dc.statsUpdatedAt == null
                  ? null
                  : l.set_dcUpdated(
                      SettingsFormat.ago(
                        context,
                        dc.statsUpdatedAt!,
                        d.now,
                        seconds: true,
                      ),
                    ),
              control: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  const SetSwitch(SettingKey.cacheStatsAutoRefresh),
                  SettingsBtn(
                    label: l.set_dcResetStats,
                    small: true,
                    tone: SettingsBtnTone.ghost,
                    onTap: s.actions.onResetCacheStats,
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
