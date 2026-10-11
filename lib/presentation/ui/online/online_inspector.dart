import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_format.dart';
import 'online_page.dart';
import 'online_parts.dart';
import 'online_popovers.dart';

/// 右侧检查器 340：头部 62（来源 · 作品号 · 在网站打开）、可滚动的详情、底部操作。
class OnlineInspector extends StatefulWidget {
  const OnlineInspector({super.key, this.width = 340, this.viewer = false});

  final double width;

  /// 大图查看器右侧的信息栏：不显示预览图，头部不给窗口按钮让位。
  final bool viewer;

  @override
  State<OnlineInspector> createState() => _OnlineInspectorState();
}

class _OnlineInspectorState extends State<OnlineInspector> {
  var _media = 0;
  String? _key;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final detail = data.detail;
    final work = data.list.items
        .where((w) => w.key == data.selectedKey)
        .firstOrNull;
    if (_key != data.selectedKey) {
      _key = data.selectedKey;
      _media = 0;
    }
    final ai = data.status.promptQuery;

    final header = Row(
      spacing: 8,
      children: [
        OnlineSourceMark(data.source, size: 22),
        Text(
          ai ? l10n.online_inspWork : l10n.online_inspPost,
          style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
        ),
        if (work != null)
          Text('#${work.id}', style: UiText.mono(12, color: c.faint)),
        const Spacer(),
        if (work != null)
          UiIconBox(
            key: const Key('online-insp-open'),
            glyph: UiGlyphs.external,
            tooltip: l10n.online_openInBrowser,
            onTap: () => scope.actions.onOpenInBrowser(work.key),
          ),
      ],
    );

    return Container(
      key: Key(widget.viewer ? 'online-viewer-info' : 'online-inspector'),
      width: widget.width,
      decoration: BoxDecoration(
        color: c.panel,
        border: widget.viewer ? null : Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.viewer)
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: header,
            )
          else
            WindowHeader(
              minimumInlineWidth: 0,
              inlineDragWidth: 8,
              dragBackground: true,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: SizedBox(
                height: 61,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: WindowChromeScope.activeOf(context) ? 0 : 16,
                  ),
                  child: header,
                ),
              ),
            ),
          Expanded(
            child: work == null || detail == null
                ? _Placeholder(text: l10n.online_noSelection)
                : detail.error != null
                ? _DetailError(message: detail.error!)
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: OnlineDetailBody(
                      work: work,
                      detail: detail,
                      preview: !widget.viewer,
                      media: _media,
                      onMedia: (i) => setState(() => _media = i),
                    ),
                  ),
          ),
          if (work != null) _Footer(work: work, detail: detail, media: _media),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            UiGlyph(UiGlyphs.panel, size: 26, color: c.faint),
            Text(
              text,
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, color: c.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            UiGlyph(UiGlyphs.alert, size: 24, color: c.error),
            Text(
              l10n.online_detailError(message),
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, color: c.muted, height: 1.6),
            ),
            UiBtn(
              size: UiBtnSize.small,
              onTap: () => scope.actions.onSelect(scope.data.selectedKey!),
              children: [
                const UiGlyph(UiGlyphs.refresh, size: 13),
                Text(l10n.online_retry),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 详情主体：预览（可选）· 标题与数字 · 作者 · 生成参数 · 提示词 · 负面 · 标签。
/// Danbooru 系：预览 · 文件信息 · 分组标签。
class OnlineDetailBody extends StatelessWidget {
  const OnlineDetailBody({
    super.key,
    required this.work,
    required this.detail,
    required this.preview,
    required this.media,
    required this.onMedia,
  });

  final OnlineWork work;
  final OnlineDetail detail;
  final bool preview;
  final int media;
  final ValueChanged<int> onMedia;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final a = scope.actions;
    final w = work;
    final d = detail;
    final ai = w.isAiTag;
    final mediaList = d.media.isEmpty
        ? [
            OnlineMedia(
              thumb: w.thumb,
              image: w.thumb,
              width: w.width,
              height: w.height,
            ),
          ]
        : d.media;
    final total = ai ? w.mediaCount : 1;

    final children = <Widget>[];
    if (preview) {
      children.add(
        Column(
          key: const Key('online-insp-preview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            _Preview(
              height: ai ? 290 : 300,
              media: mediaList[media.clamp(0, mediaList.length - 1)],
              index: media,
              total: total,
              loading: d.loading,
              onPrev: media > 0 ? () => onMedia(media - 1) : null,
              onNext: media < mediaList.length - 1
                  ? () => onMedia(media + 1)
                  : null,
              onOpen: () => scope.controller.openViewer(w.key),
            ),
            if (ai && mediaList.length > 1)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  key: const Key('online-insp-film'),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: mediaList.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => _FilmThumb(
                    image: mediaList[i].thumb,
                    on: i == media,
                    onTap: () => onMedia(i),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (!ai) {
      children.add(
        Row(
          spacing: 12,
          children: [
            if (w.rating != null) OnlineRatingBadge(w.rating!),
            Expanded(
              child: Text(
                [
                  if (mediaList.first.width > 0)
                    '${mediaList.first.width} × ${mediaList.first.height}',
                  ?d.fileType,
                  if (d.fileBytes != null) OnlineFormat.bytes(d.fileBytes!),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.muted),
              ),
            ),
            if (w.score != null)
              _stat(context, UiGlyphs.chevronUp, '${w.score}', stroke: 2.4),
            if (w.favorites != null)
              _stat(context, UiGlyphs.heartLib, '${w.favorites}'),
          ],
        ),
      );
      children.add(
        Column(
          key: const Key('online-insp-tags'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            for (final g in OnlineTagGroup.values)
              if (d.tagGroups[g]?.isNotEmpty ?? false)
                _TagGroup(group: g, tags: d.tagGroups[g]!),
          ],
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: children,
      );
    }

    children.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: [
          Text(
            w.title ?? '',
            style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
          ),
          Row(
            spacing: 10,
            children: [
              if (d.createdAt != null)
                Text(
                  OnlineFormat.date(d.createdAt!),
                  style: UiText.sans(12, color: c.muted),
                ),
              if (w.views != null)
                _stat(
                  context,
                  UiGlyphs.eye,
                  OnlineFormat.count(w.views!),
                  big: true,
                ),
              if (w.favorites != null)
                _stat(
                  context,
                  UiGlyphs.heartLib,
                  OnlineFormat.count(w.favorites!),
                  big: true,
                ),
              if (w.model != null) UiMini(w.model!),
            ],
          ),
        ],
      ),
    );

    if (w.author != null) {
      children.add(
        Container(
          key: const Key('online-insp-author'),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: c.raised,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            spacing: 10,
            children: [
              OnlineAvatar(name: w.author!, image: d.authorAvatar, size: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    if (d.authorSavedCount > 0)
                      Text(
                        l10n.online_youSaved(d.authorSavedCount),
                        style: UiText.sans(11, color: c.muted),
                      ),
                  ],
                ),
              ),
              UiBtn(
                key: const Key('online-insp-only-author'),
                size: UiBtnSize.small,
                onTap: () => a.onOnlyAuthor(w.key),
                children: [
                  const UiGlyph(UiGlyphs.user, size: 13),
                  Text(l10n.online_onlyAuthor),
                ],
              ),
              UiIconBox(
                key: const Key('online-insp-fav-author'),
                glyph: d.authorFavorited ? UiGlyphs.check : UiGlyphs.userPlus,
                size: 26,
                color: c.accent,
                tone: d.authorFavorited
                    ? UiIconBoxTone.on
                    : UiIconBoxTone.plain,
                tooltip: d.authorFavorited
                    ? l10n.online_unfavAuthor
                    : l10n.online_favAuthor,
                onTap: () => a.onToggleAuthorFavorite(w.key),
              ),
            ],
          ),
        ),
      );
    }

    if (d.loading) {
      children.add(
        const Column(
          spacing: 8,
          children: [_LineSkeleton(height: 120), _LineSkeleton(height: 72)],
        ),
      );
    } else {
      final p = d.params;
      if (p != null) {
        children.add(
          _Section(
            key: const Key('online-insp-params'),
            title: l10n.online_params,
            child: _ParamGrid(params: p),
          ),
        );
      }
      if (d.prompt == null || d.prompt!.isEmpty) {
        children.add(
          Text(l10n.online_noPrompt, style: UiText.sans(12, color: c.faint)),
        );
      } else {
        children.add(
          _Section(
            key: const Key('online-insp-prompt'),
            title: l10n.online_prompt,
            copy: d.prompt,
            child: _PromptText(text: d.prompt!),
          ),
        );
      }
      if (d.negative != null && d.negative!.isNotEmpty) {
        children.add(
          _Section(
            title: l10n.online_negative,
            copy: d.negative,
            child: _PromptText(text: d.negative!, clamp: true),
          ),
        );
      }
      if (d.siteTags.isNotEmpty) {
        children.add(
          _Section(
            key: const Key('online-insp-site-tags'),
            title: l10n.online_tags,
            hint: l10n.online_tagsHint,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final t in d.siteTags)
                  UiPressable(
                    key: Key('online-site-tag-$t'),
                    onTap: () => a.onTagTap(t),
                    builder: (context, hover) => Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: hover ? c.hover : c.control,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          t,
                          style: UiText.sans(12, color: c.ink, height: 1.2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: children,
    );
  }

  static Widget _stat(
    BuildContext context,
    String glyph,
    String text, {
    double stroke = 1.8,
    bool big = false,
  }) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        UiGlyph(glyph, size: 12, strokeWidth: stroke, color: c.muted),
        Text(text, style: UiText.sans(12, color: c.muted)),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.height,
    required this.media,
    required this.index,
    required this.total,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    required this.onOpen,
  });

  final double height;
  final OnlineMedia media;
  final int index;
  final int total;
  final bool loading;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    Widget nav(String glyph, VoidCallback onTap, {required bool left}) =>
        Positioned(
          left: left ? 8 : null,
          right: left ? null : 8,
          top: height / 2 - 15,
          child: UiPressable(
            onTap: onTap,
            builder: (context, hover) => Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: hover ? 1 : .9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: UiGlyph(
                glyph,
                size: 16,
                strokeWidth: 2.2,
                color: const Color(0xFF111111),
              ),
            ),
          ),
        );
    final w = height * media.aspect;
    return GestureDetector(
      onDoubleTap: onOpen,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            if (media.image != null)
              Center(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: Image(
                    image: media.image!,
                    width: w,
                    height: height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            if (total > 1)
              Positioned(
                right: 7,
                top: 7,
                child: OnlineBadge(text: '${index + 1} / $total'),
              ),
            if (loading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // 关掉动画时画一段静止的进度条。
                child: LinearProgressIndicator(
                  minHeight: 2,
                  value: MediaQuery.disableAnimationsOf(context) ? .35 : null,
                ),
              ),
            if (onPrev != null) nav(UiGlyphs.chevronLeft, onPrev!, left: true),
            if (onNext != null)
              nav(UiGlyphs.chevronRight, onNext!, left: false),
          ],
        ),
      ),
    );
  }
}

class _FilmThumb extends StatelessWidget {
  const _FilmThumb({
    required this.image,
    required this.on,
    required this.onTap,
  });
  final ImageProvider? image;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Opacity(
        opacity: on || hover ? 1 : .7,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: on ? c.accent : c.line,
                spreadRadius: on ? 2 : 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: image == null
                ? null
                : Image(
                    image: image!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 小节：标题行（11.5 / w600 次要色，可带提示和复制按钮）+ 内容，间距 7。
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.child,
    this.hint,
    this.copy,
  });
  final String title;
  final Widget child;
  final String? hint;

  /// 非 null 时标题行右侧有复制按钮，复制这段文字。
  final String? copy;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 7,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              title,
              style: UiText.sans(11.5, weight: FontWeight.w600, color: c.muted),
            ),
            if (hint != null)
              Text(hint!, style: UiText.sans(11.5, color: c.faint)),
            if (copy != null) ...[const Spacer(), _CopyIcon(text: copy!)],
          ],
        ),
        child,
      ],
    );
  }
}

/// 复制图标：点了换成勾 1.2 秒。
class _CopyIcon extends StatefulWidget {
  const _CopyIcon({required this.text, this.size = 13});
  final String text;
  final double size;

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  var _done = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: context.l10n.online_copy,
      child: UiPressable(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.text));
          setState(() => _done = true);
          _t?.cancel();
          _t = Timer(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _done = false);
          });
        },
        builder: (context, hover) => UiGlyph(
          _done ? UiGlyphs.check : UiGlyphs.copy,
          size: widget.size,
          strokeWidth: _done ? 2.4 : 1.8,
          color: _done ? c.ok : (hover ? c.ink : c.faint),
        ),
      ),
    );
  }
}

class _ParamGrid extends StatelessWidget {
  const _ParamGrid({required this.params});
  final OnlineParams params;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final p = params;
    Widget cell(String k, String v, {Widget? trailing}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: UiText.sans(10.5, color: c.faint)),
          Row(
            spacing: 5,
            children: [
              Flexible(
                child: Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(
                    12,
                    weight: FontWeight.w500,
                    color: c.ink,
                    height: 1.33,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
    final cfg = p.cfg == null ? '—' : p.cfg!.toStringAsFixed(1);
    return Column(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cell(l10n.online_pModel, p.model ?? '—'),
        Row(
          spacing: 6,
          children: [
            Expanded(
              child: cell(
                l10n.online_pSize,
                p.width == null ? '—' : '${p.width} × ${p.height}',
              ),
            ),
            Expanded(
              child: cell(
                l10n.online_pSeed,
                p.seed?.toString() ?? '—',
                trailing: p.seed == null
                    ? null
                    : _CopyIcon(text: '${p.seed}', size: 11),
              ),
            ),
          ],
        ),
        Row(
          spacing: 6,
          children: [
            Expanded(child: cell(l10n.online_pSampler, p.sampler ?? '—')),
            Expanded(
              child: cell(l10n.online_pStepsCfg, '${p.steps ?? '—'} · $cfg'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 提示词框：Geist Mono 12 / 1.6，画师串强调色；[clamp] 时先显示 3 行，点一下展开。
class _PromptText extends StatefulWidget {
  const _PromptText({required this.text, this.clamp = false});
  final String text;
  final bool clamp;

  @override
  State<_PromptText> createState() => _PromptTextState();
}

class _PromptTextState extends State<_PromptText> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final clamp = widget.clamp && !_open;
    final base = UiText.mono(
      12,
      color: widget.clamp ? c.muted : c.ink,
      height: 1.6,
    );
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            for (final (t, artist) in OnlineFormat.promptSegments(widget.text))
              TextSpan(
                text: t,
                style: artist && !widget.clamp
                    ? base.copyWith(color: c.accent)
                    : null,
              ),
          ],
        ),
        style: base,
        maxLines: clamp ? 3 : null,
        overflow: clamp ? TextOverflow.ellipsis : null,
      ),
    );
    if (!widget.clamp) return SelectionArea(child: box);
    return UiPressable(
      onTap: () => setState(() => _open = !_open),
      builder: (context, _) => box,
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({required this.group, required this.tags});
  final OnlineTagGroup group;
  final List<OnlineTag> tags;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final color = OnlinePalette.tagGroup(group, c);
    final title = switch (group) {
      OnlineTagGroup.artist => l10n.online_tagArtist,
      OnlineTagGroup.copyright => l10n.online_tagCopyright,
      OnlineTagGroup.character => l10n.online_tagCharacter,
      OnlineTagGroup.general => l10n.online_tagGeneral,
      OnlineTagGroup.meta => l10n.online_tagMeta,
    };
    final a = OnlineScope.of(context).actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 2,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            title,
            style: UiText.sans(11.5, weight: FontWeight.w600, color: color),
          ),
        ),
        for (final t in tags)
          UiPressable(
            key: Key('online-tag-row-${t.name}'),
            onTap: () => a.onTagTap(t.name),
            builder: (context, hover) => SizedBox(
              height: 24,
              child: Row(
                spacing: 6,
                children: [
                  Expanded(
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(12.5, color: color).copyWith(
                        decoration: hover ? TextDecoration.underline : null,
                        decorationColor: color,
                      ),
                    ),
                  ),
                  if (t.translation != null)
                    Text(
                      t.translation!,
                      style: UiText.sans(10.5, color: c.faint),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LineSkeleton extends StatelessWidget {
  const _LineSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: context.ui.control,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

/// 底部操作：发送到生图（主按钮，箭头选方式）+ 收藏 / 复制 / 下载。
class _Footer extends StatelessWidget {
  const _Footer({
    required this.work,
    required this.detail,
    required this.media,
  });
  final OnlineWork work;
  final OnlineDetail? detail;
  final int media;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final a = scope.actions;
    final s = scope.data.status;
    final ai = s.promptQuery;
    final w = work;

    UiPopoverAnchor above(BuildContext ctx) {
      final box = ctx.findRenderObject()! as RenderBox;
      return UiPopoverAnchor(
        box.localToGlobal(Offset(box.size.width - 380, -16)),
        alignBottom: true,
      );
    }

    return Container(
      key: const Key('online-insp-footer'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Builder(
            builder: (ctx) => UiBtn(
              key: const Key('online-insp-send'),
              size: UiBtnSize.large,
              tone: UiBtnTone.primary,
              expand: true,
              onTap: () => scope.controller.requestSend(w.key, above(ctx)),
              children: [
                const UiGlyph(UiGlyphs.send, size: 15),
                Text(ai ? l10n.online_send : l10n.online_sendTags),
                const Spacer(),
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: Colors.white.withValues(alpha: .35),
                ),
                Tooltip(
                  message: l10n.online_sendModes,
                  child: GestureDetector(
                    key: const Key('online-insp-send-modes'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => scope.controller.chooseSend(w.key, above(ctx)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: UiGlyph(UiGlyphs.chevronDown, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final third = (box.maxWidth - 12) / 3;
              return Row(
                spacing: 6,
                children: [
                  Expanded(
                    child: UiBtn(
                      key: const Key('online-insp-fav'),
                      expand: true,
                      color: w.favorited ? c.fav : null,
                      onTap: s.favoritesWritable
                          ? () => a.onToggleFavorite(w.key)
                          : null,
                      children: [
                        UiGlyph(
                          UiGlyphs.heartLib,
                          size: 14,
                          filled: w.favorited,
                        ),
                        Text(
                          w.favorited
                              ? l10n.online_favorited
                              : l10n.online_favorite,
                        ),
                      ],
                    ),
                  ),
                  // 三等分；中间按钮放不下文字时按内容撑开，两边平分剩下的（和原型的 1fr 网格一致）。
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: third),
                    child: UiBtn(
                      key: const Key('online-insp-copy'),
                      onTap: () => a.onCopyPrompt([w.key]),
                      children: [
                        const UiGlyph(UiGlyphs.copy, size: 14),
                        Text(
                          ai ? l10n.online_copyPrompt : l10n.online_copyTags,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (ctx) => UiBtn(
                        key: const Key('online-insp-download'),
                        expand: true,
                        onTap: w.mediaCount > 1
                            ? () {
                                final box =
                                    ctx.findRenderObject()! as RenderBox;
                                scope.controller.openMenu(
                                  UiPopoverAnchor(
                                    box.localToGlobal(
                                      Offset(box.size.width - 210, -6),
                                    ),
                                    alignBottom: true,
                                  ),
                                  [
                                    OnlineMenuItem(
                                      glyph: UiGlyphs.download,
                                      label: l10n.online_downloadCurrent,
                                      onTap: () => a.onDownload([
                                        w.key,
                                      ], mediaIndex: media),
                                    ),
                                    OnlineMenuItem(
                                      glyph: UiGlyphs.layers,
                                      label: l10n.online_downloadAll(
                                        w.mediaCount,
                                      ),
                                      onTap: () =>
                                          a.onDownload([w.key], all: true),
                                    ),
                                  ],
                                );
                              }
                            : () => a.onDownload([w.key], all: true),
                        children: [
                          const UiGlyph(UiGlyphs.download, size: 14),
                          Text(l10n.online_download),
                          if (w.mediaCount > 1)
                            const UiGlyph(UiGlyphs.chevronDown, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
