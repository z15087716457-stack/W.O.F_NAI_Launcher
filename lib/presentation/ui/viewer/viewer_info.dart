import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/common/translation_icon.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'viewer_contract.dart';
import 'viewer_format.dart';
import 'viewer_page.dart';
import 'viewer_prompt.dart';

/// 原型里 kit 还没有的图标。
abstract final class ViewerGlyphs {
  static const translate =
      'M4 6h8M8 4v2c0 4-2 7-4 8M6 10c1 2 3 3 5 3M13 20l4-9 4 9M14.5 17h5';
  static const save = 'M5 4h11l3 3v13H5zM8 4v5h7V4M8 20v-6h8v6';
  static const block = 'M4 7l8-4 8 4v10l-8 4-8-4zM4 7l8 4 8-4M12 11v10';
  static const link =
      'M10 14a4 4 0 005.7 0l3-3a4 4 0 00-5.7-5.7l-1 1M14 10a4 4 0 00-5.7 0l-3 3a4 4 0 005.7 5.7l1-1';
  static const moveTo = 'M4 12h12M12 8l4 4-4 4M20 4v16';
  static const layers = 'M12 4l8 4-8 4-8-4zM4 12l8 4 8-4M4 16l8 4 8-4';
  static const trash = 'M5 7h14M10 7V4h4v3M7 7l1 13h8l1-13';
}

/// 信息栏 340：头部 61（标题 · 收藏 / 在文件夹中显示 / 删除 / 更多）、可滚动的文件信息 / 参数 / 提示词、
/// 底部主按钮 + 6 个操作。和本地画廊检查器同一套内容，去掉预览图。
/// [drawer] 时是窄窗口 / 全屏里盖在图上的抽屉（不让窗口按钮）。
class ViewerInfoPanel extends StatelessWidget {
  const ViewerInfoPanel({super.key, this.drawer = false});
  final bool drawer;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = ViewerPageScope.of(context).data;
    return Container(
      key: const Key('viewer-info'),
      width: ImageViewerPage.infoWidth,
      decoration: BoxDecoration(
        color: c.panel,
        border: drawer ? null : Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(drawer: drawer),
          Expanded(
            child: _Body(key: ValueKey('viewer-info-${data.currentKey}')),
          ),
          const _Footer(),
        ],
      ),
    );
  }
}

/// 头部按钮的菜单：顶边在按钮下方 6，右边对齐信息栏右侧留 10（菜单落在信息栏里，不压大图）。
UiPopoverAnchor _below(BuildContext button, BuildContext header) {
  final box = button.findRenderObject()! as RenderBox;
  final panel = header.findRenderObject()! as RenderBox;
  final bottom = box.localToGlobal(box.size.bottomRight(Offset.zero)).dy + 6;
  final right = panel.localToGlobal(Offset(panel.size.width, 0)).dx - 10;
  return UiPopoverAnchor(Offset(right, bottom), alignRight: true);
}

class _Header extends StatelessWidget {
  const _Header({required this.drawer});
  final bool drawer;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final item = data.current;
    final gallery = data.mode == ViewerMode.gallery;
    final chrome = WindowChromeScope.activeOf(context);
    return WindowHeader(
      enabled: !drawer,
      minimumInlineWidth: 0,
      inlineDragWidth: 8,
      dragBackground: !drawer,
      decoration: const BoxDecoration(),
      child: Container(
        key: const Key('viewer-info-header'),
        height: 61,
        padding: EdgeInsets.only(left: 16, right: !drawer && chrome ? 0 : 12),
        child: Row(
          spacing: 2,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                gallery
                    ? l10n.imageViewer_details
                    : l10n.imageViewer_generationResult,
                style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
              ),
            ),
            if (gallery && item != null) ...[
              Builder(
                builder: (bctx) => UiIconBox(
                  key: const Key('viewer-info-favorite'),
                  glyph: UiGlyphs.heartLib,
                  glyphSize: 16,
                  filled: item.favorite,
                  color: item.favorite ? c.fav : null,
                  tooltip: l10n.imageViewer_favorite,
                  onTap: () => ctrl.openCollections(_below(bctx, context)),
                ),
              ),
              if (data.actions.contains(ViewerAction.showInFolder))
                UiIconBox(
                  key: const Key('viewer-info-folder'),
                  glyph: UiGlyphs.folder,
                  glyphSize: 16,
                  tooltip: l10n.imageViewer_showInFolder,
                  onTap: () => scope.actions.onAction(
                    item.key,
                    ViewerAction.showInFolder,
                  ),
                ),
              UiIconBox(
                key: const Key('viewer-info-delete'),
                glyph: ViewerGlyphs.trash,
                glyphSize: 16,
                tooltip: l10n.imageViewer_deleteKey(
                  _keyText(data, ViewerCommand.delete),
                ),
                onTap: ctrl.requestDelete,
              ),
            ],
            if (item != null)
              Builder(
                builder: (bctx) => UiIconBox(
                  key: const Key('viewer-info-more'),
                  glyph: UiGlyphs.more,
                  glyphSize: 17,
                  tone: ctrl.moreOpen ? UiIconBoxTone.on : UiIconBoxTone.plain,
                  tooltip: l10n.imageViewer_more,
                  onTap: () => ctrl.openMore(_below(bctx, context)),
                ),
              ),
            const Spacer(),
            if (drawer)
              UiIconBox(
                key: const Key('viewer-drawer-close'),
                glyph: UiGlyphs.close,
                glyphSize: 15,
                tooltip: l10n.imageViewer_hideInfo,
                onTap: ctrl.closeDrawer,
              ),
          ],
        ),
      ),
    );
  }
}

String _keyText(ViewerViewData data, ViewerCommand c) {
  final a = data.keys[c]?.firstOrNull ?? ViewerKeys.defaults[c]?.firstOrNull;
  return a == null ? '' : viewerKeyLabels(a).join(' ');
}

class _Body extends StatefulWidget {
  const _Body({super.key});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  var _promptFull = false;
  var _negFull = false;
  var _promptOver = false;
  var _negOver = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final item = data.current;
    if (item == null) return const SizedBox.shrink();
    final d = data.detail?.key == item.key ? data.detail : null;
    final status = d?.status ?? ViewerMetaStatus.loading;
    final gen = data.mode == ViewerMode.generation;
    final index = data.items.indexWhere((e) => e.key == item.key);

    final file = gen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                l10n.imageViewer_genIndex(index + 1),
                style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
              ),
              _IconLine(
                glyph: UiGlyphs.picture,
                text: [
                  item.saved
                      ? l10n.imageViewer_savedToGallery
                      : l10n.imageViewer_notSaved,
                  if (item.date != null)
                    viewerAgo(context, item.date!, data.now),
                ].join(' · '),
              ),
            ],
          )
        : Column(
            key: const Key('viewer-info-file'),
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                d?.fileName ?? item.path?.split(RegExp(r'[\\/]')).last ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
              if (d?.folder != null)
                _IconLine(glyph: UiGlyphs.folder, text: d!.folder!),
            ],
          );

    final rows = <(String, String, bool)>[
      (l10n.imageViewer_size, '${item.width} × ${item.height}', true),
      if (!gen && item.sizeBytes != null)
        (l10n.imageViewer_fileSize, viewerBytes(item.sizeBytes!), true),
      if (!gen && item.date != null)
        (l10n.imageViewer_modified, viewerDateTime(item.date!), true),
      if (status == ViewerMetaStatus.ready && d?.model != null)
        (l10n.imageViewer_model, d!.model!, false),
    ];
    final table = Column(
      key: const Key('viewer-info-table'),
      spacing: 5,
      children: [
        for (final (k, v, mono) in rows)
          Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(k, style: UiText.sans(12.5, color: c.muted)),
              ),
              Expanded(
                child: Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono
                      ? UiText.mono(12.5, color: c.ink)
                      : UiText.sans(12.5, color: c.ink),
                ),
              ),
            ],
          ),
      ],
    );

    final children = <Widget>[file, table];
    switch (status) {
      case ViewerMetaStatus.loading:
        children.add(_Skeleton());
      case ViewerMetaStatus.none:
        children.add(const _NoMeta());
      case ViewerMetaStatus.ready:
        children.addAll(_ready(context, d!, item.key));
    }

    return ShaderMask(
      shaderCallback: (b) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 1 - 28 / b.height.clamp(28, double.infinity), 1],
        colors: const [Colors.black, Colors.black, Colors.transparent],
      ).createShader(b),
      blendMode: BlendMode.dstIn,
      child: SelectionArea(
        child: SingleChildScrollView(
          key: const Key('viewer-info-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: children,
          ),
        ),
      ),
    );
  }

  List<Widget> _ready(BuildContext context, ViewerDetail d, String key) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final hl = data.highlight;
    List<InlineSpan> spans(String s) =>
        viewerPromptSpans(s, c: c, highlight: hl);

    Widget translate(ViewerPart part) {
      final t = data.translations[part];
      final on = t?.text != null;
      return _TinyIcon(
        key: Key('viewer-translate-${part.kind.name}${part.index}'),
        glyph: ViewerGlyphs.translate,
        size: 14,
        tooltip: on
            ? l10n.imageViewer_showOriginal
            : l10n.imageViewer_translate,
        color: on ? c.accent : null,
        busy: t?.busy ?? false,
        translation: true,
        onTap: () => a.onToggleTranslation(key, part),
      );
    }

    Widget copy(ViewerPart part) => _TinyIcon(
      key: Key('viewer-copy-${part.kind.name}${part.index}'),
      glyph: UiGlyphs.copy,
      size: 13,
      tooltip: l10n.imageViewer_copy,
      onTap: () => a.onCopy(key, part),
    );

    String shown(ViewerPart part, String original) =>
        data.translations[part]?.text ?? original;

    Widget? error(ViewerPart part) {
      final e = data.translations[part]?.error;
      return e == null
          ? null
          : Text(
              l10n.imageViewer_translateFailed(e),
              style: UiText.sans(11.5, color: c.error),
            );
    }

    final cells = <(String, String, ViewerPart?)>[
      if (d.seed != null) (l10n.imageViewer_seed, '${d.seed}', ViewerPart.seed),
      if (d.sampler != null) (l10n.imageViewer_sampler, d.sampler!, null),
      if (d.steps != null) (l10n.imageViewer_steps, '${d.steps}', null),
      if (d.scale != null)
        (l10n.imageViewer_guidance, viewerDecimal(d.scale!), null),
    ];
    final extras = [
      if (d.noiseSchedule != null) l10n.imageViewer_noise(d.noiseSchedule!),
      if (d.cfgRescale != null)
        l10n.imageViewer_rescale(viewerDecimal(d.cfgRescale!)),
      if (d.smea != null) 'SMEA ${d.smea}',
      if (d.qualityTags == true) l10n.imageViewer_qualityTags,
      if (d.preciseCount > 0) l10n.imageViewer_precise(d.preciseCount),
    ];

    final out = <Widget>[
      Column(
        key: const Key('viewer-info-params'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 7,
        children: [
          _SectionTitle(label: l10n.imageViewer_params),
          if (cells.isNotEmpty)
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 6) / 2;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (i, (k, v, part)) in cells.indexed)
                      SizedBox(
                        key: Key('viewer-param-$i'),
                        width: w,
                        child: _ParamCell(
                          label: k,
                          value: v,
                          onCopy: part == null
                              ? null
                              : () => a.onCopy(key, part),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (extras.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in extras)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(e, style: UiText.mono(11.5, color: c.muted)),
                  ),
              ],
            ),
        ],
      ),
    ];

    if (d.prompt.trim().isNotEmpty) {
      out.add(
        _PromptHover(
          child: Column(
            key: const Key('viewer-info-prompt'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              _SectionTitle(
                label: l10n.imageViewer_prompt,
                actions: [
                  _HoverTranslation(translate(ViewerPart.prompt)),
                  copy(ViewerPart.prompt),
                ],
              ),
              ViewerPromptBox(
                key: const Key('viewer-prompt-box'),
                spans: spans(shown(ViewerPart.prompt, d.prompt)),
                maxLines: _promptFull ? null : 9,
                onOverflow: (v) {
                  if (v != _promptOver && mounted) {
                    setState(() => _promptOver = v);
                  }
                },
              ),
              ?error(ViewerPart.prompt),
              if (_promptFull || _promptOver)
                _More(
                  pressKey: const Key('viewer-prompt-more'),
                  label: _promptFull
                      ? l10n.imageViewer_collapse
                      : l10n.imageViewer_expandAll,
                  onTap: () => setState(() => _promptFull = !_promptFull),
                ),
            ],
          ),
        ),
      );
    }

    for (final (i, ch) in d.characters.indexed) {
      final part = ViewerPart.character(i);
      out.add(
        _PromptHover(
          child: Column(
            key: Key('viewer-info-character-$i'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              _SectionTitle(
                label: l10n.imageViewer_character(i + 1),
                extra: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Tooltip(
                      message: l10n.imageViewer_position(
                        viewerCellName(ch.x, ch.y),
                      ),
                      // 和原型一样：39 高的格子在 22 高的标题行里上下溢出，不撑高标题行。
                      child: SizedBox(
                        width: 39,
                        height: 22,
                        child: OverflowBox(
                          maxHeight: 40,
                          child: ViewerPositionGrid(x: ch.x, y: ch.y),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    viewerCellName(ch.x, ch.y),
                    style: UiText.sans(11, color: c.faint),
                  ),
                ],
                actions: [_HoverTranslation(translate(part)), copy(part)],
              ),
              // The 39px grid overflows its 22px title by 8.5px.
              // 6 + 4.5px leaves a real 2px gap below the grid.
              Padding(
                padding: const EdgeInsets.only(top: 4.5),
                child: ViewerPromptBox(spans: spans(shown(part, ch.prompt))),
              ),
              ?error(part),
              if (ch.negative.trim().isNotEmpty)
                ViewerPromptBox(
                  muted: true,
                  prefix: l10n.imageViewer_characterNegative,
                  spans: [TextSpan(text: ch.negative.trim())],
                ),
            ],
          ),
        ),
      );
    }

    if (d.negative.trim().isNotEmpty) {
      out.add(
        _PromptHover(
          child: Column(
            key: const Key('viewer-info-negative'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              _SectionTitle(
                label: l10n.imageViewer_negative,
                extra: [
                  Text(
                    l10n.imageViewer_tagCount(viewerTagCount(d.negative)),
                    style: UiText.sans(11, color: c.faint),
                  ),
                ],
                actions: [
                  _HoverTranslation(translate(ViewerPart.negative)),
                  copy(ViewerPart.negative),
                ],
              ),
              ViewerPromptBox(
                muted: true,
                spans: [
                  TextSpan(text: shown(ViewerPart.negative, d.negative).trim()),
                ],
                maxLines: _negFull ? null : 3,
                onOverflow: (v) {
                  if (v != _negOver && mounted) setState(() => _negOver = v);
                },
              ),
              ?error(ViewerPart.negative),
              if (_negFull || _negOver)
                _More(
                  pressKey: const Key('viewer-negative-more'),
                  label: _negFull
                      ? l10n.imageViewer_collapse
                      : l10n.imageViewer_expand,
                  onTap: () => setState(() => _negFull = !_negFull),
                ),
            ],
          ),
        ),
      );
    }

    if (d.vibes.isNotEmpty) {
      out.add(
        Column(
          key: const Key('viewer-info-vibes'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            _SectionTitle(
              label: l10n.imageViewer_vibes,
              extra: [
                Text(
                  '${d.vibes.length}',
                  style: UiText.sans(11, color: c.faint),
                ),
              ],
            ),
            for (final (i, v) in d.vibes.indexed)
              _VibeRow(vibe: v, onSave: () => a.onSaveVibe(key, i)),
          ],
        ),
      );
    }
    return out;
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.glyph, required this.text});
  final String glyph;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 5,
      children: [
        UiGlyph(glyph, size: 13, color: c.muted),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12, color: c.muted),
          ),
        ),
      ],
    );
  }
}

/// One hover region per prompt section, including its title and body.
class _PromptHover extends StatefulWidget {
  const _PromptHover({required this.child});
  final Widget child;
  @override
  State<_PromptHover> createState() => _PromptHoverState();
}

class _PromptHoverState extends State<_PromptHover> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: _PromptHoverScope(hovered: hovered, child: widget.child),
  );
}

class _PromptHoverScope extends InheritedWidget {
  const _PromptHoverScope({required this.hovered, required super.child});
  final bool hovered;
  @override
  bool updateShouldNotify(_PromptHoverScope oldWidget) =>
      hovered != oldWidget.hovered;
}

class _HoverTranslation extends StatelessWidget {
  const _HoverTranslation(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => Visibility(
    visible:
        context
            .dependOnInheritedWidgetOfExactType<_PromptHoverScope>()
            ?.hovered ??
        false,
    maintainSize: true,
    maintainState: true,
    maintainAnimation: true,
    child: child,
  );
}

/// 段标题：12 / w700，22 高；后面可跟小字，右侧小图标按钮。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    this.extra = const [],
    this.actions = const [],
  });
  final String label;
  final List<Widget> extra;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SizedBox(
      height: 22,
      child: Row(
        spacing: 6,
        children: [
          Text(
            label,
            style: UiText.sans(12, weight: FontWeight.w700, color: c.ink),
          ),
          ...extra,
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, spacing: 2, children: actions),
        ],
      ),
    );
  }
}

/// 24 × 24 小图标按钮（复制、翻译）；[busy] 时呼吸。
class _TinyIcon extends StatefulWidget {
  const _TinyIcon({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
    this.size = 13,
    this.color,
    this.busy = false,
    this.translation = false,
  });
  final String glyph;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final bool busy;
  final bool translation;

  @override
  State<_TinyIcon> createState() => _TinyIconState();
}

class _TinyIconState extends State<_TinyIcon>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    lowerBound: .35,
  )..value = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _TinyIcon old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.busy && !MediaQuery.disableAnimationsOf(context);
    if (run && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!run && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: widget.tooltip,
      child: UiPressable(
        onTap: widget.onTap,
        builder: (context, hover) => Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: FadeTransition(
            opacity: _pulse,
            child: widget.translation
                ? TranslationIcon(
                    size: 16,
                    busy: widget.busy,
                    color: widget.color ?? (hover ? c.ink : c.faint),
                  )
                : UiGlyph(
                    widget.glyph,
                    size: widget.size,
                    color: widget.color ?? (hover ? c.ink : c.faint),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ParamCell extends StatelessWidget {
  const _ParamCell({required this.label, required this.value, this.onCopy});
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: UiText.sans(10.5, color: c.faint)),
          Row(
            spacing: 5,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(
                    12.5,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
              ),
              if (onCopy != null)
                Tooltip(
                  message: context.l10n.imageViewer_copySeed,
                  child: UiPressable(
                    key: const Key('viewer-copy-seed'),
                    onTap: onCopy,
                    builder: (context, hover) => UiGlyph(
                      UiGlyphs.copy,
                      size: 11,
                      color: hover ? c.ink : c.faint,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _More extends StatelessWidget {
  const _More({
    required this.pressKey,
    required this.label,
    required this.onTap,
  });
  final Key pressKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: UiPressable(
          key: pressKey,
          onTap: onTap,
          builder: (context, hover) => Text(
            label,
            style: UiText.sans(
              12,
              color: c.accent,
            ).copyWith(decoration: hover ? TextDecoration.underline : null),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return Column(
      key: const Key('viewer-info-loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        _SectionTitle(
          label: l10n.imageViewer_params,
          extra: [
            Text(
              l10n.imageViewer_loadingMeta,
              style: UiText.sans(11, color: c.faint),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - 6) / 2;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 4; i++) UiSkeleton(width: w, height: 40),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _SectionTitle(label: l10n.imageViewer_prompt),
        ),
        LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              for (final f in const [.92, .80, .86, .40])
                UiSkeleton(width: box.maxWidth * f, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoMeta extends StatelessWidget {
  const _NoMeta();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return UiDashedBox(
      key: const Key('viewer-info-nometa'),
      radius: 10,
      strokeWidth: 1,
      dash: 4,
      gap: 3,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 6,
          children: [
            UiGlyph(UiGlyphs.infoCircle, size: 22, color: c.faint),
            Text(
              l10n.imageViewer_noMetaTitle,
              style: UiText.sans(13, weight: FontWeight.w700, color: c.ink),
            ),
            Text(
              l10n.imageViewer_noMetaBody,
              textAlign: TextAlign.center,
              style: UiText.sans(12, color: c.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _VibeRow extends StatelessWidget {
  const _VibeRow({required this.vibe, required this.onSave});
  final ViewerVibe vibe;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final params = [
      if (vibe.strength != null)
        l10n.imageViewer_vibeStrength(viewerDecimal(vibe.strength!)),
      if (vibe.infoExtracted != null)
        l10n.imageViewer_vibeInfo(viewerDecimal(vibe.infoExtracted!)),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 9,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              color: c.control,
              child: vibe.thumb == null
                  ? null
                  : Image(image: vibe.thumb!, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vibe.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w500,
                    color: c.ink,
                  ),
                ),
                if (params.isNotEmpty)
                  Text(params, style: UiText.mono(11.5, color: c.muted)),
              ],
            ),
          ),
          UiBtn(
            size: UiBtnSize.small,
            onTap: onSave,
            children: [Text(l10n.imageViewer_saveVibe)],
          ),
        ],
      ),
    );
  }
}

/// 底部：主按钮（复用参数 / 保存到图库）+ 3 × 2 操作格。
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final item = data.current;
    if (item == null) return const SizedBox.shrink();
    final key = item.key;
    final gen = data.mode == ViewerMode.generation;
    final has = data.actions.contains;
    final status = data.detail?.key == key
        ? data.detail!.status
        : ViewerMetaStatus.loading;
    final meta = status == ViewerMetaStatus.ready;
    void run(ViewerAction a) => scope.actions.onAction(key, a);

    final Widget primary;
    if (gen) {
      primary = UiBtn(
        key: const Key('viewer-primary'),
        size: UiBtnSize.large,
        tone: UiBtnTone.primary,
        expand: true,
        onTap: has(ViewerAction.save) && !item.saved
            ? () => run(ViewerAction.save)
            : null,
        children: [
          const UiGlyph(ViewerGlyphs.save, size: 15),
          Text(item.saved ? l10n.imageViewer_saved : l10n.imageViewer_save),
        ],
      );
    } else {
      final reuseKeys =
          data.keys[ViewerCommand.reuse]?.firstOrNull ??
          ViewerKeys.defaults[ViewerCommand.reuse]!.first;
      primary = UiBtn(
        key: const Key('viewer-primary'),
        size: UiBtnSize.large,
        tone: UiBtnTone.primary,
        expand: true,
        onTap: has(ViewerAction.reuse) && meta
            ? () => run(ViewerAction.reuse)
            : null,
        children: [
          const UiGlyph(UiGlyphs.spark, size: 15),
          Text(l10n.imageViewer_reuse),
          if (status == ViewerMetaStatus.none)
            Expanded(
              child: Text(
                '· ${l10n.imageViewer_reuseNoMeta}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(11, color: c.onBrand.withValues(alpha: .85)),
              ),
            )
          else
            const Spacer(),
          if (meta) _BrandKey(viewerKeyLabels(reuseKeys).join(' ')),
        ],
      );
    }

    final tiles = gen
        ? <(ViewerAction, Widget, String)>[
            (
              ViewerAction.copyImage,
              const _G(UiGlyphs.copy),
              l10n.imageViewer_copyImage,
            ),
            (
              ViewerAction.saveAsBlock,
              const _G(ViewerGlyphs.block),
              l10n.imageViewer_saveBlock,
            ),
            (
              ViewerAction.reuse,
              const _G(UiGlyphs.spark),
              l10n.imageViewer_reuse,
            ),
            (
              ViewerAction.img2img,
              const _I(StudioIcons.imageToImage),
              l10n.imageViewer_img2img,
            ),
            (
              ViewerAction.preciseRef,
              const _I(StudioIcons.referenceFocus),
              l10n.imageViewer_preciseRef,
            ),
            (
              ViewerAction.upscale,
              const _I(StudioIcons.galleryUpscale),
              l10n.imageViewer_upscale,
            ),
          ]
        : <(ViewerAction, Widget, String)>[
            (
              ViewerAction.img2img,
              const _I(StudioIcons.imageToImage),
              l10n.imageViewer_img2img,
            ),
            (
              ViewerAction.styleTransfer,
              const _I(StudioIcons.styleTransfer),
              l10n.imageViewer_styleTransfer,
            ),
            (
              ViewerAction.preciseRef,
              const _I(StudioIcons.referenceFocus),
              l10n.imageViewer_preciseRef,
            ),
            (
              ViewerAction.saveToRefLibrary,
              const _I(StudioIcons.galleryBookmarkAdd),
              l10n.imageViewer_saveRef,
            ),
            (
              ViewerAction.krita,
              const _I(StudioIcons.galleryBrush),
              l10n.imageViewer_krita,
            ),
            (
              ViewerAction.upscale,
              const _I(StudioIcons.galleryUpscale),
              l10n.imageViewer_upscale,
            ),
          ];
    final shown = [
      for (final t in tiles)
        if (has(t.$1)) t,
    ];

    return Container(
      key: const Key('viewer-footer'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          primary,
          if (shown.isNotEmpty)
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth - 12) / 3;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (a, icon, label) in shown)
                      SizedBox(
                        width: w,
                        child: _Tile(
                          key: Key('viewer-tile-${a.name}'),
                          icon: icon,
                          label: label,
                          disabledTip:
                              a == ViewerAction.krita && !data.kritaConnected
                              ? l10n.imageViewer_kritaOff
                              : a == ViewerAction.reuse && !meta
                              ? l10n.imageViewer_reuseNoMeta
                              : null,
                          onTap: () => run(a),
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

class _BrandKey extends StatelessWidget {
  const _BrandKey(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 18,
    margin: const EdgeInsets.only(left: 3),
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.white.withValues(alpha: .25)),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        label,
        style: UiText.mono(
          10.5,
          weight: FontWeight.w500,
          height: 1,
          color: Colors.white,
        ),
      ),
    ),
  );
}

/// 操作格图标：线性图标（原型 SVG）。
class _G extends StatelessWidget {
  const _G(this.path);
  final String path;

  @override
  Widget build(BuildContext context) =>
      UiGlyph(path, size: 17, color: IconTheme.of(context).color);
}

/// 操作格图标：StudioIcons（和本地画廊检查器同一组）。
class _I extends StatelessWidget {
  const _I(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) => Icon(icon, size: 17);
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabledTip,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  /// 有值时灰掉，悬停写原因。
  final String? disabledTip;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final off = disabledTip != null;
    final tile = UiPressable(
      onTap: off ? null : onTap,
      builder: (context, hover) {
        final fg = off ? c.faint : c.ink;
        return Container(
          height: 50,
          decoration: BoxDecoration(
            color: hover ? c.hover : c.card,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: fg, size: 17),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                icon,
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: fg, height: 1.2),
                ),
              ],
            ),
          ),
        );
      },
    );
    return off
        ? Tooltip(message: disabledTip, child: tile)
        : Tooltip(message: label, child: tile);
  }
}
