import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_controls.dart';
import 'settings_format.dart';
import 'settings_kit.dart';
import 'settings_scope.dart';

/// 一条搜索结果：在哪一页、哪一节，标题和弱色说明，可以直接改的控件，跳转后高亮的锚点。
class SettingsHit {
  const SettingsHit({
    required this.page,
    required this.section,
    required this.title,
    this.detail = '',
    this.keywords = '',
    required this.anchor,
    this.control,
  });

  final SettingsPageId page;
  final String section;
  final String title;
  final String detail;

  /// 不显示、只参与匹配（英文键名、同义词）。
  final String keywords;
  final String anchor;
  final Widget? control;

  bool matches(String q) =>
      '$title\n$detail\n$section\n$keywords'.toLowerCase().contains(q);
}

/// 每个标量设置在界面上的名字（变更记录 [SettingsChange.title] 也建议用它）。
String settingTitle(BuildContext context, SettingKey k) {
  final l = context.l10n;
  return switch (k) {
    SettingKey.themeMode => l.set_apTheme,
    SettingKey.fontFamily => l.set_apFont,
    SettingKey.settingsFontScale => l.set_apScale,
    SettingKey.language => l.set_apLanguage,
    SettingKey.reduceMotion => l.set_apReduceMotion,
    SettingKey.completionSound => l.set_apSound,
    SettingKey.completionSoundFile => l.set_apSoundFile,
    SettingKey.historyClick => l.set_cvHistoryClick,
    SettingKey.outputViewer => l.set_cvViewer,
    SettingKey.canvasLockCamera => l.set_cvLock,
    SettingKey.canvasZoomToFill => l.set_cvFill,
    SettingKey.shortcutsEnabled => l.set_scEnabled,
    SettingKey.shortcutsInTooltips => l.set_scInTooltips,
    SettingKey.shortcutsInMenus => l.set_scInMenus,
    SettingKey.navNumberBadges => l.set_scBadges,
    SettingKey.costWarning => l.set_gnWarn,
    SettingKey.costThreshold => l.set_gnThreshold,
    SettingKey.intervalLimit => l.set_gnLimit,
    SettingKey.intervalSeconds => l.set_gnInterval,
    SettingKey.intervalJitter => l.set_gnJitter,
    SettingKey.wheelWeight => l.set_gnWheel,
    SettingKey.wheelModifier => l.set_gnWheel,
    SettingKey.relatedTags => l.set_gnRelated,
    SettingKey.imageSavePath => l.set_stSavePath,
    SettingKey.autoSave => l.set_stAutoSave,
    SettingKey.vibePath => l.set_stVibePath,
    SettingKey.galleryQuality => l.set_stQuality,
    SettingKey.appDataPath => l.set_stAppData,
    SettingKey.cacheStatsAutoRefresh => l.set_dcAutoRefresh,
    SettingKey.agentModel => l.set_agModel,
    SettingKey.agentEnterToSend => l.set_agEnter,
    SettingKey.agentMaxRequests => l.set_agMax,
    SettingKey.ragEnabled => l.set_pageRag,
    SettingKey.ragContext => l.set_rgRange,
    SettingKey.ragDevice => l.set_rgDevice,
    SettingKey.ragEmbedPath => l.set_rgEmbedPath,
    SettingKey.ragRerankPath => l.set_rgRerankPath,
    SettingKey.ragPythonPath => l.set_rgPython,
    SettingKey.upscaleDefault => l.set_upDefault,
    SettingKey.seedVramMode => l.set_upVramMode,
    SettingKey.seedCpuOffload => l.set_upOffload,
    SettingKey.seedVaeTiling => l.set_upTiling,
    SettingKey.seedVaeTile => l.set_upTiling,
    SettingKey.seedInputNoise => l.set_upInputNoise,
    SettingKey.seedLatentNoise => l.set_upLatentNoise,
    SettingKey.kritaBridge => l.set_brKrita,
    SettingKey.comfyEnabled => l.set_brComfyEnable,
    SettingKey.comfyUrl => l.set_brComfyUrl,
    SettingKey.proxyEnabled => l.set_nwUse,
    SettingKey.proxyMode => l.set_nwMode,
    SettingKey.proxyHost => l.set_nwAddress,
    SettingKey.proxyPort => l.set_nwAddress,
    SettingKey.stripMetadata => l.set_pvStrip,
    SettingKey.confirmExternalSend => l.set_pvExternal,
    SettingKey.confirmDangerous => l.set_pvDanger,
    SettingKey.noOverwrite => l.set_pvOverwrite,
    SettingKey.blacklistAutoSync => l.set_pvAutoSync,
    SettingKey.includePrerelease => l.set_abPrerelease,
    SettingKey.logToFile => l.set_abLog,
    SettingKey.defaultAccount => l.set_accDefault,
    SettingKey.autoLogin => l.set_accAutoLogin,
  };
}

/// 设置所在小节的名字。
String settingSection(BuildContext context, SettingKey k) {
  final l = context.l10n;
  return switch (k) {
    SettingKey.themeMode => l.set_apTheme,
    SettingKey.fontFamily ||
    SettingKey.settingsFontScale ||
    SettingKey.language => l.set_apText,
    SettingKey.reduceMotion ||
    SettingKey.completionSound ||
    SettingKey.completionSoundFile => l.set_apMotion,
    SettingKey.historyClick || SettingKey.outputViewer => l.set_cvBrowse,
    SettingKey.canvasLockCamera ||
    SettingKey.canvasZoomToFill => l.set_cvCanvasSec,
    SettingKey.shortcutsEnabled ||
    SettingKey.shortcutsInTooltips ||
    SettingKey.shortcutsInMenus ||
    SettingKey.navNumberBadges => l.set_scDisplay,
    SettingKey.costWarning || SettingKey.costThreshold => l.set_gnCost,
    SettingKey.intervalLimit ||
    SettingKey.intervalSeconds ||
    SettingKey.intervalJitter => l.set_gnPace,
    SettingKey.wheelWeight ||
    SettingKey.wheelModifier ||
    SettingKey.relatedTags => l.set_gnInput,
    SettingKey.imageSavePath || SettingKey.autoSave => l.set_stSave,
    SettingKey.vibePath || SettingKey.galleryQuality => l.set_stAssets,
    SettingKey.appDataPath => l.set_stMaintain,
    SettingKey.cacheStatsAutoRefresh => l.set_dcStats,
    SettingKey.agentModel ||
    SettingKey.agentEnterToSend ||
    SettingKey.agentMaxRequests => l.set_agModelSec,
    SettingKey.ragEnabled => l.set_pageRag,
    SettingKey.ragContext => l.set_rgContext,
    SettingKey.ragDevice ||
    SettingKey.ragEmbedPath ||
    SettingKey.ragRerankPath ||
    SettingKey.ragPythonPath => l.set_rgRuntime,
    SettingKey.upscaleDefault => l.set_upDefault,
    SettingKey.seedVramMode ||
    SettingKey.seedCpuOffload ||
    SettingKey.seedVaeTiling ||
    SettingKey.seedVaeTile ||
    SettingKey.seedInputNoise ||
    SettingKey.seedLatentNoise => 'SeedVR2',
    SettingKey.kritaBridge => 'Krita',
    SettingKey.comfyEnabled || SettingKey.comfyUrl => 'ComfyUI',
    SettingKey.proxyEnabled ||
    SettingKey.proxyMode ||
    SettingKey.proxyHost ||
    SettingKey.proxyPort => l.set_nwProxy,
    SettingKey.stripMetadata ||
    SettingKey.confirmExternalSend ||
    SettingKey.confirmDangerous ||
    SettingKey.noOverwrite => l.set_pvProtect,
    SettingKey.blacklistAutoSync => l.set_pvBlacklist,
    SettingKey.includePrerelease => l.set_pageAbout,
    SettingKey.logToFile => l.set_abDiag,
    SettingKey.defaultAccount || SettingKey.autoLogin => l.set_accLogin,
  };
}

/// 当前值的一句话（搜索结果里的弱色说明）。
String settingValue(BuildContext context, SettingKey k, SettingsValues v) {
  final l = context.l10n;
  final spec = SettingSpec.of(k);
  final d = SettingsScope.of(context).data;
  switch (spec.kind) {
    case SettingKind.toggle:
      return v.flag(k) ? l.set_on : l.set_off;
    case SettingKind.number:
      final n = v.number(k);
      return switch (k) {
        SettingKey.settingsFontScale => '${(n * 100).round()}%',
        SettingKey.costThreshold => '${n.round()} Anlas',
        SettingKey.intervalSeconds => '${n.round()} ${l.set_unitSeconds}',
        SettingKey.intervalJitter => '±${n.round()}%',
        SettingKey.seedInputNoise ||
        SettingKey.seedLatentNoise => n.toStringAsFixed(2),
        _ => '${n.round()}',
      };
    case SettingKind.choice:
      final t = v.text(k) ?? '';
      final opt = d.options[k]?.where((o) => o.value == t).firstOrNull;
      return opt?.label ?? SettingsFormat.choice(context, k, t);
    case SettingKind.path:
    case SettingKind.text:
      return v.text(k) ?? l.set_defaultTag;
  }
}

/// 整个设置的搜索索引（按目录顺序）。
/// 只参与匹配的同义词（不分语言，主要是英文键和常见说法）。
const _synonyms = <SettingKey, String>{
  SettingKey.costWarning: 'anlas cost',
  SettingKey.costThreshold: 'anlas cost',
  SettingKey.intervalSeconds: 'delay rate limit',
  SettingKey.themeMode: 'dark light theme',
  SettingKey.proxyEnabled: 'proxy http socks',
  SettingKey.proxyHost: 'proxy',
  SettingKey.imageSavePath: 'folder output save',
  SettingKey.stripMetadata: 'metadata exif privacy',
  SettingKey.ragEmbedPath: 'rag gemma embedding model download 下载',
  SettingKey.ragRerankPath: 'rag qwen reranker model download 下载',
  SettingKey.ragPythonPath: 'rag python exe interpreter runtime cuda 运行环境',
};

List<SettingsHit> settingsIndex(BuildContext context) {
  final l = context.l10n;
  final c = context.ui;
  final s = SettingsScope.of(context);
  final d = s.data;
  final hits = <SettingsHit>[];
  for (final k in SettingKey.values) {
    if (k == SettingKey.seedVaeTile ||
        k == SettingKey.proxyPort ||
        k == SettingKey.wheelModifier) {
      continue;
    }
    final spec = SettingSpec.of(k);
    final Widget control = switch (spec.kind) {
      SettingKind.toggle => SetSwitch(k),
      SettingKind.number =>
        k == SettingKey.settingsFontScale ||
                k == SettingKey.intervalJitter ||
                k.name.startsWith('seed')
            ? SetSlider(
                k,
                width: 140,
                label: (x) => switch (k) {
                  SettingKey.settingsFontScale => '${(x * 100).round()}%',
                  SettingKey.intervalJitter => '±${x.round()}%',
                  SettingKey.seedCpuOffload => '${x.round()}',
                  _ => x.toStringAsFixed(2),
                },
              )
            : SetStepper(
                k,
                unit: k == SettingKey.costThreshold
                    ? 'Anlas'
                    : (k == SettingKey.intervalSeconds
                          ? l.set_unitSeconds
                          : null),
              ),
      SettingKind.choice =>
        spec.choices.isNotEmpty && spec.choices.length <= 4
            ? SetSeg(k)
            : SetSelect(k, width: 180),
      SettingKind.path => SettingsIconBtn(
        glyph: SettingsGlyphs.folder,
        tooltip: l.set_change,
        onTap: () => s.actions.onPickPath(k),
      ),
      SettingKind.text => SetText(k, width: 200),
    };
    hits.add(
      SettingsHit(
        page: spec.page,
        section: settingSection(context, k),
        title: settingTitle(context, k),
        detail: settingValue(context, k, d.values),
        keywords:
            '${k.name} ${SettingsFormat.page(context, spec.page)} '
            '${_synonyms[k] ?? ''}',
        anchor: k.name,
        control: control,
      ),
    );
  }
  final a = d.account.current;
  if (a != null) {
    final balance = a.anlas == null
        ? l.set_accUnread
        : SettingsFormat.count(a.anlas!);
    final tier = a.tier;
    hits.add(
      SettingsHit(
        page: SettingsPageId.overview,
        section: l.set_pageOverview,
        title: l.set_srBalance,
        detail: '$balance · ${a.name}',
        keywords: 'anlas balance',
        anchor: 'balance',
        control: Text(
          balance,
          style: a.anlas == null
              ? UiText.sans(12, color: c.faint)
              : UiText.mono(12, color: c.ink),
        ),
      ),
    );
    if (tier != null && tier != SettingsTier.none) {
      hits.add(
        SettingsHit(
          page: SettingsPageId.account,
          section: l.set_accSub,
          title: l.set_srSubscription,
          detail:
              '${SettingsFormat.tier(tier)} · ${l.set_accMonthly(SettingsFormat.count(d.account.monthlyAnlas))}',
          keywords: 'anlas subscription opus',
          anchor: 'subscription',
        ),
      );
    }
  }
  final ctx = {for (final x in d.shortcuts.contexts) x.id: x.label};
  for (final x in d.shortcuts.shortcuts) {
    hits.add(
      SettingsHit(
        page: SettingsPageId.shortcuts,
        section: l.set_pageShortcuts,
        title: x.label,
        detail: ctx[x.context] ?? x.context,
        keywords: '${x.keys.join('+')} shortcut',
        anchor: 'shortcut-${x.id}',
        control: x.keys.isEmpty
            ? Text(l.set_notSet, style: UiText.sans(12, color: c.faint))
            : SettingsKeys(x.keys),
      ),
    );
  }
  for (final x in d.rag.sources) {
    hits.add(
      SettingsHit(
        page: SettingsPageId.rag,
        section: l.set_rgSources,
        title: SettingsFormat.ragSource(context, x.kind),
        detail: switch (x.state) {
          SettingsRagState.paused => l.set_tileRagPaused(
            SettingsFormat.ragShort(context, x.kind),
            SettingsFormat.percent(x.fraction),
          ),
          SettingsRagState.loading => l.set_rgLoading,
          SettingsRagState.empty => l.set_rgEmpty,
          _ => x.known ? SettingsFormat.percent(x.fraction) : '—',
        },
        keywords: 'rag ${x.kind.name}',
        anchor: 'rag-${x.kind.name}',
        control: SettingsSwitch(
          value: x.enabled,
          onChanged: (v) => s.actions.onRagSourceEnabled(x.kind, v),
        ),
      ),
    );
  }
  hits.add(
    SettingsHit(
      page: SettingsPageId.rag,
      section: l.set_rgRuntime,
      title: l.set_rgEnv,
      detail: d.rag.runtimeReady ? l.set_rgEnvReady : l.set_rgEnvMissing,
      keywords: 'rag python cuda cpu install runtime 安装',
      anchor: 'rag-runtime',
    ),
  );
  for (final p in d.models.providers) {
    hits.add(
      SettingsHit(
        page: SettingsPageId.models,
        section: l.set_mdProviders,
        title: p.name,
        detail: p.baseUrl,
        keywords: 'api provider ${p.models.map((m) => m.id).join(' ')}',
        anchor: 'provider-${p.id}',
      ),
    );
  }
  for (final (page, anchor, title, sub, kw) in [
    (
      SettingsPageId.storage,
      'rescan',
      l.set_stRescan,
      l.set_stRescanSub,
      'scan gallery',
    ),
    (
      SettingsPageId.about,
      'diagnostics',
      l.set_abCopyDiag,
      l.set_abCopyDiagSub,
      'diagnostic log',
    ),
    (
      SettingsPageId.network,
      'endpoints',
      l.set_nwCheck,
      l.set_nwCheckSub,
      'ping network',
    ),
    (
      SettingsPageId.privacy,
      'blacklistSync',
      l.set_pvSync,
      l.set_pvBlacklistSub,
      'danbooru blacklist',
    ),
    (
      SettingsPageId.agent,
      'agentInstructions',
      l.set_agInstr,
      l.set_agInstrSub,
      'prompt instructions',
    ),
    (
      SettingsPageId.canvas,
      'channelMode',
      l.set_cvChannel,
      l.set_cvChannelSub,
      'channel theme',
    ),
  ]) {
    hits.add(
      SettingsHit(
        page: page,
        section: SettingsFormat.page(context, page),
        title: title,
        detail: sub,
        keywords: kw,
        anchor: anchor,
      ),
    );
  }
  if (d.agent.systemPrompt != null) {
    hits.add(
      SettingsHit(
        page: SettingsPageId.agent,
        section: l.set_agInstr,
        title: l.set_agBase,
        detail: l.set_agBaseHint,
        keywords: 'system prompt base workspace 系统提示词 内置提示词',
        anchor: 'agentSystemPrompt',
      ),
    );
  }
  return hits;
}

List<SettingsHit> settingsSearch(BuildContext context, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final hits = settingsIndex(context).where((h) => h.matches(q)).toList();
  // 按目录顺序分组，组内保持索引顺序。
  hits.sort((a, b) => a.page.index.compareTo(b.page.index));
  return hits;
}

/// 搜索结果页：按页分组；控件可以直接改，右侧箭头跳过去并高亮。
class SettingsSearchResults extends StatelessWidget {
  const SettingsSearchResults({
    super.key,
    required this.query,
    required this.onJump,
    this.selected = 0,
    this.onHits,
  });

  final String query;
  final void Function(SettingsPageId page, String anchor) onJump;

  /// 每次构建报告当前结果（键盘选择 / Enter 跳转用）。
  final ValueChanged<List<SettingsHit>>? onHits;

  /// 键盘 ↑↓ 选中的序号。
  final int selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    final hits = settingsSearch(context, query);
    onHits?.call(hits);
    final groups = <SettingsPageId, List<(int, SettingsHit)>>{};
    for (final (i, h) in hits.indexed) {
      groups.putIfAbsent(h.page, () => []).add((i, h));
    }
    return SettingsPageFrame(
      wide: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              spacing: 8,
              children: [
                Container(width: 14, height: 1, color: c.strong),
                Text(
                  'SEARCH',
                  style: UiText.mono(
                    11,
                    weight: FontWeight.w500,
                    color: c.faint,
                    letterSpacing: 1.54,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.set_srQuoted(query)),
                TextSpan(
                  text: '  ${l.set_searchCount('${hits.length}')}',
                  style: UiText.sans(16, color: c.muted),
                ),
              ],
            ),
            style: UiText.sans(
              24,
              weight: FontWeight.w600,
              color: c.ink,
              height: 1.25,
              letterSpacing: -.24,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l.set_searchHint,
                  style: UiText.sans(13, color: c.muted, height: 1.6),
                ),
                const SettingsKeys(['↑', '↓']),
                Text(l.set_searchKeys, style: UiText.sans(13, color: c.muted)),
                const SettingsKeys(['Enter']),
                Text(l.set_searchJump, style: UiText.sans(13, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
      children: [
        if (hits.isEmpty)
          SettingsCard(
            children: [
              Padding(
                key: const Key('search-empty'),
                padding: const EdgeInsets.all(48),
                child: Column(
                  spacing: 6,
                  children: [
                    Text(
                      l.set_searchEmpty(query),
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.set_searchEmptyHint,
                      style: UiText.sans(12, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        for (final MapEntry(key: page, value: list) in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
            child: Row(
              spacing: 6,
              children: [
                if (page.group != SettingsGroup.none) ...[
                  Text(
                    SettingsFormat.group(context, page.group),
                    style: UiText.sans(11, color: c.faint),
                  ),
                  UiGlyph(UiGlyphs.chevronRight, size: 11, color: c.faint),
                ],
                Text(
                  SettingsFormat.page(context, page),
                  style: UiText.sans(11, color: c.faint),
                ),
              ],
            ),
          ),
          SettingsCard(
            children: [
              for (final (i, h) in list)
                _HitRow(
                  key: Key('hit-${h.anchor}'),
                  hit: h,
                  query: query,
                  selected: i == selected,
                  onJump: () => onJump(h.page, h.anchor),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({
    super.key,
    required this.hit,
    required this.query,
    required this.selected,
    required this.onJump,
  });
  final SettingsHit hit;
  final String query;
  final bool selected;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.ui;
    return ColoredBox(
      color: selected ? c.accent.withValues(alpha: .05) : Colors.transparent,
      child: SettingsRow(
        titleWidget: Row(
          spacing: 7,
          children: [
            Flexible(
              child: SettingsMarked(
                text: hit.title,
                query: query,
                style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
            ),
            Text(hit.section, style: UiText.sans(11, color: c.faint)),
          ],
        ),
        title: hit.title,
        subtitleWidget: hit.detail.isEmpty
            ? null
            : SettingsMarked(
                text: hit.detail,
                query: query,
                style: UiText.sans(12, color: c.muted, height: 1.55),
              ),
        control: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            ?hit.control,
            SettingsIconBtn(
              key: Key('jump-${hit.anchor}'),
              glyph: UiGlyphs.chevronRight,
              tooltip: l.set_goTo,
              onTap: onJump,
            ),
          ],
        ),
      ),
    );
  }
}

/// 把命中的片段画成黄底。
class SettingsMarked extends StatelessWidget {
  const SettingsMarked({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });
  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final lower = text.toLowerCase();
    if (q.isEmpty || !lower.contains(q)) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final spans = <TextSpan>[];
    var i = 0;
    while (true) {
      final j = lower.indexOf(q, i);
      if (j < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (j > i) spans.add(TextSpan(text: text.substring(i, j)));
      spans.add(
        TextSpan(
          text: text.substring(j, j + q.length),
          style: TextStyle(backgroundColor: context.ui.mark),
        ),
      );
      i = j + q.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
