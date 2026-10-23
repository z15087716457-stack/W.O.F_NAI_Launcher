import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_text.dart';
import '../kit/ui_preview_image.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 参考图模块（原型 `refModule`）：标题行 + 图生图 / 风格迁移 / 精准参考三行（模型不支持的行不显示）。
/// 每行自己画顶部分隔线；点行展开内容。带图收起时用原图模糊垫底。
class GenRefsModule extends StatefulWidget {
  const GenRefsModule({super.key});

  @override
  State<GenRefsModule> createState() => _GenRefsModuleState();
}

class _GenRefsModuleState extends State<GenRefsModule> {
  final _open = <GenDropTarget>{};

  void _toggle(GenDropTarget t) =>
      setState(() => _open.contains(t) ? _open.remove(t) : _open.add(t));

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.refs);
    final refs = scope.data.refs;
    final l = context.l10n;
    Widget wrap(GenDropTarget t, Widget child) {
      final hl = GenDropHighlight(active: refs.dropHover == t, child: child);
      return scope.slots.drop?.call(context, t, hl) ?? hl;
    }

    return GenModule(
      key: const Key('gen-refs'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GenModuleHeader(children: [Text(l.gen_refs)]),
          wrap(
            GenDropTarget.img2img,
            _Img2ImgSection(
              open: _open.contains(GenDropTarget.img2img),
              onToggle: () => _toggle(GenDropTarget.img2img),
            ),
          ),
          if (refs.vibes != null)
            wrap(
              GenDropTarget.vibe,
              _VibeSection(
                open: _open.contains(GenDropTarget.vibe),
                onToggle: () => _toggle(GenDropTarget.vibe),
              ),
            ),
          if (refs.precise != null)
            wrap(
              GenDropTarget.precise,
              _PreciseSection(
                open: _open.contains(GenDropTarget.precise),
                onToggle: () => _toggle(GenDropTarget.precise),
              ),
            ),
        ],
      ),
    );
  }
}

/// 有精准参考（启用的）又有启用的 Vibe：Vibe 这次不会发送。
bool _conflict(GenRefsData r) =>
    (r.precise?.list.any((p) => p.enabled) ?? false) &&
    (r.vibes?.list.any((v) => v.enabled) ?? false);

/// 一行（原型 `.refrow`）：46 高、左 12 右 6、间距 10、顶部 1px 分隔。
/// [images] 非空时用模糊原图垫底（原型 `.refrow.img`），字变白。
class _RefRow extends StatelessWidget {
  const _RefRow({
    super.key,
    required this.icon,
    required this.name,
    required this.desc,
    required this.open,
    required this.onToggle,
    this.trailing = const [],
    this.images = const [],
    this.pill,
    this.warn = false,
  });

  final IconData icon;
  final String name;
  final String desc;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> trailing;
  final List<ImageProvider> images;
  final String? pill;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final img = images.isNotEmpty && !open;
    final ink = img ? Colors.white : c.ink;
    final row = UiPressable(
      onTap: onToggle,
      builder: (context, hover) => Container(
        height: 46,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: !img && hover ? c.control.withValues(alpha: .45) : null,
          border: Border(
            top: BorderSide(color: img ? Colors.transparent : c.line),
          ),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: ink),
          child: Row(
            spacing: 10,
            children: [
              Icon(icon, size: 18, color: ink),
              Text(
                name,
                style: UiText.sans(13, weight: FontWeight.w500, color: ink),
              ),
              if (pill != null)
                Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: img ? Colors.white.withValues(alpha: .2) : c.control,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pill!,
                    style: UiText.sans(
                      11,
                      color: img ? Colors.white : c.muted,
                      height: 1,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(
                    12,
                    color: warn
                        ? (img ? const Color(0xFFFFC56B) : c.warn)
                        : (img ? Colors.white.withValues(alpha: .9) : c.muted),
                  ),
                ),
              ),
              ...trailing,
              AnimatedRotation(
                turns: open ? .5 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: GenIb(
                  glyph: UiGlyphs.chevronDown,
                  color: img ? Colors.white : null,
                  onTap: onToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!img) return row;
    return Stack(
      children: [
        Positioned.fill(child: _BlurredStrip(images: images)),
        row,
      ],
    );
  }
}

/// 原型 `.refbg`：几张图横排、各占一份，高 180 上移 60、放大 1.04、模糊 2.4，压 62% → 68% 黑。
class _BlurredStrip extends StatelessWidget {
  const _BlurredStrip({required this.images});
  final List<ImageProvider> images;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Row(
          children: [
            for (final i in images.take(3))
              Expanded(
                child: OverflowBox(
                  minHeight: 180,
                  maxHeight: 180,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -60),
                    child: Transform.scale(
                      scale: 1.04,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 2.4,
                          sigmaY: 2.4,
                        ),
                        child: UiPreviewImage(
                          image: i,
                          height: 180,
                          width: double.infinity,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x9E000000), Color(0xAD000000)],
            ),
          ),
        ),
      ],
    ),
  );
}

/// 小方钮（原型 `.hdb`）：28、圆角 6、控件底 60%、次要色。
class _Hdb extends StatelessWidget {
  const _Hdb({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
    this.size = 15,
  });
  final String glyph;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: tooltip,
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover ? c.hover : c.control.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: UiGlyph(glyph, size: size, color: hover ? c.ink : c.muted),
        ),
      ),
    );
  }
}

/// 强调色文字按钮（原型 `.ghost`）：28 高、左右 10、圆角 6；13 / w500。
class _Ghost extends StatelessWidget {
  const _Ghost({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
  });
  final String glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hover ? c.control : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          spacing: 5,
          children: [
            UiGlyph(glyph, size: 15, color: c.accent),
            Text(
              label,
              style: UiText.sans(13, weight: FontWeight.w500, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 展开后的内容区：左右 12、下 12。
class _Body extends StatelessWidget {
  const _Body({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: children,
    ),
  );
}

/// 空态投放区：虚线框、圆角 8；图标 + 一句说明 + 几个入口按钮。
class _DropZone extends StatelessWidget {
  const _DropZone({required this.text, required this.actions});
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiDashedBox(
      radius: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          spacing: 10,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                UiGlyph(UiGlyphs.upload, size: 15, color: c.faint),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

/// 风格迁移 / 精准参考冲突提示：琥珀底一行。
class _Warn extends StatelessWidget {
  const _Warn(this.text, {this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: c.warnBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.warn.withValues(alpha: .25)),
      ),
      child: Row(
        spacing: 8,
        children: [
          UiGlyph(UiGlyphs.alert, size: 13, color: c.warn),
          Expanded(
            child: Text(
              text,
              style: UiText.sans(12, color: c.warn, height: 1.4),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

// ───────────────────────── 图生图 ─────────────────────────

class _Img2ImgSection extends StatelessWidget {
  const _Img2ImgSection({required this.open, required this.onToggle});
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.refs);
    final a = scope.actions;
    final m = scope.data.refs.img2img;
    final l = context.l10n;
    return Column(
      key: const Key('gen-ref-img2img'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RefRow(
          key: const Key('gen-ref-img2img-row'),
          icon: StudioIcons.imageToImage,
          name: l.gen_img2img,
          desc: m.hasImage
              ? (m.enabled
                    ? l.gen_img2imgSummary(
                        GenFormat.decimal(m.strength),
                        GenFormat.decimal(m.noise),
                      )
                    : l.gen_refPaused)
              : l.gen_img2imgDesc,
          open: open,
          onToggle: onToggle,
          images: [?m.image],
          pill: m.hasImage ? '${m.width}×${m.height}' : null,
          trailing: [
            if (!m.hasImage)
              _Ghost(
                key: const Key('gen-img2img-upload'),
                glyph: UiGlyphs.upload,
                label: l.gen_upload,
                onTap: a.onImg2ImgUpload,
              )
            else
              Tooltip(
                message: m.enabled ? l.gen_refPause : l.gen_refResume,
                child: UiPressable(
                  key: const Key('gen-img2img-enabled'),
                  onTap: () => a.onImg2ImgChanged(
                    GenImg2Img(
                      image: m.image,
                      width: m.width,
                      height: m.height,
                      strength: m.strength,
                      noise: m.noise,
                      enabled: !m.enabled,
                      mask: m.mask,
                      inpaintStrength: m.inpaintStrength,
                    ),
                  ),
                  builder: (context, _) => UiSwitch(value: m.enabled),
                ),
              ),
          ],
        ),
        if (open)
          _Body(
            key: const Key('gen-img2img-body'),
            children: m.hasImage
                ? [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        UiPressable(
                          onTap: a.onImg2ImgPlace,
                          builder: (context, hover) => Container(
                            width: 96,
                            height:
                                (96 * m.height / (m.width == 0 ? 1 : m.width))
                                    .clamp(64.0, 140.0),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: GenFormat.softBg(c),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hover ? c.accent : c.line,
                              ),
                            ),
                            child: UiPreviewImage(image: m.image!),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text(
                                '${m.width} × ${m.height}',
                                style: UiText.mono(12, color: c.muted),
                              ),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  UiBtn(
                                    size: UiBtnSize.small,
                                    onTap: a.onImg2ImgUpload,
                                    children: [
                                      const UiGlyph(UiGlyphs.retry, size: 12),
                                      Text(l.gen_replace),
                                    ],
                                  ),
                                  UiBtn(
                                    size: UiBtnSize.small,
                                    onTap: a.onImg2ImgEdit,
                                    children: [
                                      const UiGlyph(UiGlyphs.pencil, size: 12),
                                      Text(l.gen_edit),
                                    ],
                                  ),
                                  UiBtn(
                                    key: const Key('gen-img2img-inpaint'),
                                    size: UiBtnSize.small,
                                    onTap: a.onImg2ImgInpaint,
                                    children: [
                                      const UiGlyph(GenGlyphs.brush, size: 12),
                                      Text(l.gen_inpaint),
                                    ],
                                  ),
                                  UiBtn(
                                    size: UiBtnSize.small,
                                    onTap: a.onImg2ImgPlace,
                                    children: [
                                      const UiGlyph(UiGlyphs.expand, size: 12),
                                      Text(l.gen_placeOnCanvas),
                                    ],
                                  ),
                                ],
                              ),
                              UiBtn(
                                key: const Key('gen-img2img-remove'),
                                size: UiBtnSize.small,
                                tone: UiBtnTone.ghost,
                                color: c.error,
                                onTap: a.onImg2ImgRemove,
                                children: [
                                  const UiGlyph(UiGlyphs.trash, size: 12),
                                  Text(l.gen_remove),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GenSliderRow(
                      key: const Key('gen-img2img-strength'),
                      label: l.gen_strength,
                      tooltip: l.gen_strengthTip,
                      value: m.strength,
                      defaultValue: .7,
                      onChanged: (v) =>
                          a.onImg2ImgChanged(_with(m, strength: v)),
                    ),
                    GenSliderRow(
                      key: const Key('gen-img2img-noise'),
                      label: l.gen_noise,
                      tooltip: l.gen_noiseTip,
                      value: m.noise,
                      defaultValue: 0,
                      onChanged: (v) => a.onImg2ImgChanged(_with(m, noise: v)),
                    ),
                    if (m.mask == GenMask.ready) ...[
                      GenSliderRow(
                        key: const Key('gen-img2img-inpaint-strength'),
                        label: l.gen_inpaintStrength,
                        value: m.inpaintStrength,
                        defaultValue: 1,
                        onChanged: (v) =>
                            a.onImg2ImgChanged(_with(m, inpaintStrength: v)),
                      ),
                      Text(
                        l.gen_inpaintReady,
                        style: UiText.sans(11.5, color: c.faint, height: 1.4),
                      ),
                    ],
                  ]
                : [
                    _DropZone(
                      text: l.gen_img2imgDrop,
                      actions: [
                        UiBtn(
                          size: UiBtnSize.small,
                          onTap: a.onImg2ImgUpload,
                          children: [
                            const UiGlyph(UiGlyphs.upload, size: 12),
                            Text(l.gen_upload),
                          ],
                        ),
                        UiBtn(
                          size: UiBtnSize.small,
                          onTap: a.onImg2ImgFromLibrary,
                          children: [
                            const UiGlyph(UiGlyphs.archive, size: 12),
                            Text(l.gen_fromPreciseLibrary),
                          ],
                        ),
                        UiBtn(
                          key: const Key('gen-img2img-sketch'),
                          size: UiBtnSize.small,
                          onTap: a.onImg2ImgSketch,
                          children: [
                            const UiGlyph(GenGlyphs.brush, size: 12),
                            Text(l.gen_sketch),
                          ],
                        ),
                      ],
                    ),
                  ],
          ),
      ],
    );
  }

  static GenImg2Img _with(
    GenImg2Img m, {
    double? strength,
    double? noise,
    double? inpaintStrength,
  }) => GenImg2Img(
    image: m.image,
    width: m.width,
    height: m.height,
    strength: strength ?? m.strength,
    noise: noise ?? m.noise,
    enabled: m.enabled,
    mask: m.mask,
    inpaintStrength: inpaintStrength ?? m.inpaintStrength,
  );
}

// ───────────────────────── 风格迁移 ─────────────────────────

class _VibeSection extends StatelessWidget {
  const _VibeSection({required this.open, required this.onToggle});
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.refs);
    final a = scope.actions;
    final refs = scope.data.refs;
    final v = refs.vibes!;
    final l = context.l10n;
    final conflict = _conflict(refs);
    final extra = (v.list.where((x) => x.enabled).length - v.freeCount).clamp(
      0,
      999,
    );
    void addMenu(BuildContext ctx) => scope.controller.openMenu(
      genBelow(ctx, dy: 4),
      [
        UiMenuItem(
          key: const Key('gen-vibe-add-file'),
          label: l.gen_addFromFile,
          glyph: UiGlyphs.upload,
          onTap: a.onAddVibeFiles,
        ),
        UiMenuItem(
          key: const Key('gen-vibe-add-library'),
          label: l.gen_addFromVibeLibrary,
          glyph: UiGlyphs.archive,
          onTap: a.onAddVibeFromLibrary,
        ),
      ],
      tag: #vibeAdd,
      width: 200,
    );
    return Column(
      key: const Key('gen-ref-vibe'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RefRow(
          key: const Key('gen-ref-vibe-row'),
          icon: StudioIcons.styleTransfer,
          name: l.gen_vibe,
          desc: conflict ? l.gen_vibeSkipped : l.gen_vibeDesc,
          warn: conflict,
          open: open,
          onToggle: onToggle,
          images: [for (final x in v.list.take(3)) x.thumb],
          pill: v.list.isEmpty ? null : '${v.list.length}/${v.max}',
          trailing: [
            if (v.list.isEmpty)
              Builder(
                builder: (ctx) => _Hdb(
                  key: const Key('gen-vibe-add-row'),
                  glyph: UiGlyphs.plus,
                  tooltip: l.gen_addVibe,
                  onTap: () => addMenu(ctx),
                ),
              ),
          ],
        ),
        if (open)
          _Body(
            key: const Key('gen-vibe-body'),
            children: [
              if (conflict) _Warn(l.gen_vibeConflict),
              if (v.list.isEmpty)
                _DropZone(
                  text: l.gen_vibeDrop,
                  actions: [
                    UiBtn(
                      size: UiBtnSize.small,
                      onTap: a.onAddVibeFiles,
                      children: [
                        const UiGlyph(UiGlyphs.upload, size: 12),
                        Text(l.gen_addFromFile),
                      ],
                    ),
                    UiBtn(
                      size: UiBtnSize.small,
                      onTap: a.onAddVibeFromLibrary,
                      children: [
                        const UiGlyph(UiGlyphs.archive, size: 12),
                        Text(l.gen_addFromVibeLibrary),
                      ],
                    ),
                  ],
                )
              else
                for (final x in v.list) _VibeItem(vibe: x),
              if (v.list.isNotEmpty)
                Row(
                  spacing: 6,
                  children: [
                    Builder(
                      builder: (ctx) => UiBtn(
                        key: const Key('gen-vibe-add'),
                        size: UiBtnSize.small,
                        onTap: v.list.length >= v.max
                            ? null
                            : () => addMenu(ctx),
                        tooltip: v.list.length >= v.max
                            ? l.gen_vibeFull(v.max)
                            : null,
                        children: [
                          const UiGlyph(UiGlyphs.plus, size: 12),
                          Text(l.gen_add),
                        ],
                      ),
                    ),
                    UiBtn(
                      key: const Key('gen-vibe-save'),
                      size: UiBtnSize.small,
                      tone: UiBtnTone.ghost,
                      onTap: a.onSaveVibes,
                      children: [
                        const UiGlyph(GenGlyphs.save2, size: 12),
                        Text(l.gen_saveToLibrary),
                      ],
                    ),
                    const Spacer(),
                    Tooltip(
                      message: l.gen_normalizeTip,
                      child: UiPressable(
                        key: const Key('gen-vibe-normalize'),
                        onTap: () => a.onNormalizeChanged(!v.normalize),
                        builder: (context, _) => Row(
                          spacing: 6,
                          children: [
                            Text(
                              l.gen_normalize,
                              style: UiText.sans(12, color: c.muted),
                            ),
                            UiSwitch(value: v.normalize),
                          ],
                        ),
                      ),
                    ),
                    GenIb(
                      key: const Key('gen-vibe-clear'),
                      glyph: UiGlyphs.trash,
                      tooltip: l.gen_clearAll,
                      onTap: a.onClearVibes,
                    ),
                  ],
                ),
              if (extra > 0)
                Row(
                  spacing: 6,
                  children: [
                    UiGlyph(UiGlyphs.coin, size: 13, color: c.amber),
                    Expanded(
                      child: Text(
                        l.gen_vibeExtraCost(
                          v.freeCount,
                          v.extraCost,
                          extra * v.extraCost,
                        ),
                        style: UiText.sans(11.5, color: c.muted),
                      ),
                    ),
                  ],
                ),
              if (v.recent.isNotEmpty && v.list.length < v.max)
                _Recent(recent: v.recent, onAdd: a.onAddRecentVibe),
            ],
          ),
      ],
    );
  }
}

/// 一个 Vibe：44 方缩略图 │ 名字 + 编码状态，强度 / 信息提取两条小滑杆 │ 启用、移除。
class _VibeItem extends StatelessWidget {
  const _VibeItem({required this.vibe});
  final GenVibe vibe;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.refs);
    final a = scope.actions;
    final l = context.l10n;
    final v = vibe;
    GenVibe copy({double? strength, double? info, bool? enabled}) => GenVibe(
      id: v.id,
      thumb: v.thumb,
      name: v.name,
      strength: strength ?? v.strength,
      info: info ?? v.info,
      enabled: enabled ?? v.enabled,
      state: v.state,
      encodeCost: v.encodeCost,
    );
    return Container(
      key: Key('gen-vibe-${v.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: GenFormat.softBg(c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Opacity(
            opacity: v.enabled ? 1 : .4,
            child: Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: UiPreviewImage(image: v.thumb),
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: v.enabled ? 1 : .55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: Text(
                          v.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            12.5,
                            weight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                      ),
                      switch (v.state) {
                        GenVibeState.encoded => UiMini(
                          l.gen_encoded,
                          tone: UiMiniTone.ok,
                        ),
                        GenVibeState.encoding => Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            const UiSpinner(size: 12),
                            Text(
                              l.gen_encoding,
                              style: UiText.sans(11, color: c.muted),
                            ),
                          ],
                        ),
                        GenVibeState.pending => Tooltip(
                          message: l.gen_encodeTip(v.encodeCost),
                          child: UiPressable(
                            key: Key('gen-vibe-encode-${v.id}'),
                            onTap: () => a.onEncodeVibe(v.id),
                            builder: (context, hover) => Container(
                              height: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: c.warn.withValues(
                                  alpha: hover ? .2 : .13,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 3,
                                children: [
                                  Text(
                                    l.gen_encode,
                                    style: UiText.sans(
                                      10.5,
                                      weight: FontWeight.w600,
                                      color: c.warn,
                                      height: 1.2,
                                    ),
                                  ),
                                  GenAnlas(
                                    '${v.encodeCost}',
                                    size: 10.5,
                                    iconSize: 9,
                                    color: c.warn,
                                    weight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      },
                    ],
                  ),
                  GenSliderRow(
                    key: Key('gen-vibe-strength-${v.id}'),
                    label: l.gen_vibeStrength,
                    labelWidth: 52,
                    compact: true,
                    value: v.strength,
                    defaultValue: .6,
                    onChanged: (x) => a.onVibeChanged(copy(strength: x)),
                  ),
                  GenSliderRow(
                    key: Key('gen-vibe-info-${v.id}'),
                    label: l.gen_vibeInfo,
                    labelWidth: 52,
                    compact: true,
                    value: v.info,
                    defaultValue: 1,
                    tooltip: v.state == GenVibeState.encoded
                        ? l.gen_vibeInfoReencode
                        : null,
                    onChanged: (x) => a.onVibeChanged(copy(info: x)),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              GenIb(
                key: Key('gen-vibe-enabled-${v.id}'),
                glyph: UiGlyphs.check,
                glyphSize: 15,
                strokeWidth: 2.4,
                size: 24,
                color: v.enabled ? c.ink : c.faint,
                tooltip: v.enabled ? l.gen_refPause : l.gen_refResume,
                onTap: () => a.onVibeChanged(copy(enabled: !v.enabled)),
              ),
              GenIb(
                key: Key('gen-vibe-remove-${v.id}'),
                glyph: UiGlyphs.close,
                glyphSize: 14,
                size: 24,
                tooltip: l.gen_remove,
                onTap: () => a.onRemoveVibe(v.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 最近用过：一排 28 方缩略图，点一下加回来。
class _Recent extends StatelessWidget {
  const _Recent({required this.recent, required this.onAdd});
  final List<GenRecentVibe> recent;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 6,
      children: [
        Text(context.l10n.gen_recent, style: UiText.sans(11.5, color: c.faint)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 4,
              children: [
                for (final r in recent)
                  Tooltip(
                    message: r.name,
                    child: UiPressable(
                      key: Key('gen-recent-${r.id}'),
                      onTap: () => onAdd(r.id),
                      builder: (context, hover) => Container(
                        width: 28,
                        height: 28,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: hover ? c.accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: UiPreviewImage(image: r.thumb),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 精准参考 ─────────────────────────

class _PreciseSection extends StatelessWidget {
  const _PreciseSection({required this.open, required this.onToggle});
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.refs);
    final a = scope.actions;
    final refs = scope.data.refs;
    final p = refs.precise!;
    final l = context.l10n;
    final conflict = _conflict(refs);
    final enabled = p.list.where((x) => x.enabled).length;
    void addMenu(BuildContext ctx) => scope.controller.openMenu(
      genBelow(ctx, dy: 4, right: true),
      [
        UiMenuItem(
          key: const Key('gen-precise-add-file'),
          label: l.gen_addFromFile,
          glyph: UiGlyphs.upload,
          onTap: a.onAddPreciseFiles,
        ),
        UiMenuItem(
          key: const Key('gen-precise-add-library'),
          label: l.gen_addFromPreciseLibrary,
          glyph: UiGlyphs.archive,
          onTap: a.onAddPreciseFromLibrary,
        ),
      ],
      tag: #preciseAdd,
      width: 210,
    );
    return Column(
      key: const Key('gen-ref-precise'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RefRow(
          key: const Key('gen-ref-precise-row'),
          icon: StudioIcons.referenceFocus,
          name: l.gen_precise,
          desc: l.gen_preciseDesc,
          open: open,
          onToggle: onToggle,
          images: [for (final x in p.list.take(3)) x.thumb],
          pill: p.list.isEmpty ? null : '${p.list.length}',
          trailing: [
            _Hdb(
              key: const Key('gen-precise-save'),
              glyph: GenGlyphs.save2,
              size: 14,
              tooltip: l.gen_savePrecise,
              onTap: p.list.isEmpty ? null : a.onSavePrecise,
            ),
            Builder(
              builder: (ctx) => _Hdb(
                key: const Key('gen-precise-add'),
                glyph: UiGlyphs.plus,
                tooltip: l.gen_addPrecise,
                onTap: () => addMenu(ctx),
              ),
            ),
          ],
        ),
        if (open)
          _Body(
            key: const Key('gen-precise-body'),
            children: [
              if (conflict)
                _Warn(
                  l.gen_preciseConflict,
                  action: UiBtn(
                    size: UiBtnSize.small,
                    tone: UiBtnTone.ghost,
                    color: c.warn,
                    onTap: () {
                      for (final v in refs.vibes!.list.where(
                        (v) => v.enabled,
                      )) {
                        a.onVibeChanged(
                          GenVibe(
                            id: v.id,
                            thumb: v.thumb,
                            name: v.name,
                            strength: v.strength,
                            info: v.info,
                            enabled: false,
                            state: v.state,
                            encodeCost: v.encodeCost,
                          ),
                        );
                      }
                    },
                    children: [Text(l.gen_pauseVibes)],
                  ),
                ),
              if (p.list.isEmpty)
                _DropZone(
                  text: l.gen_preciseDrop,
                  actions: [
                    UiBtn(
                      size: UiBtnSize.small,
                      onTap: a.onAddPreciseFiles,
                      children: [
                        const UiGlyph(UiGlyphs.upload, size: 12),
                        Text(l.gen_addFromFile),
                      ],
                    ),
                    UiBtn(
                      size: UiBtnSize.small,
                      onTap: a.onAddPreciseFromLibrary,
                      children: [
                        const UiGlyph(UiGlyphs.archive, size: 12),
                        Text(l.gen_addFromPreciseLibrary),
                      ],
                    ),
                  ],
                )
              else ...[
                for (final x in p.list) _PreciseItem(item: x),
                Row(
                  spacing: 6,
                  children: [
                    UiGlyph(UiGlyphs.coin, size: 13, color: c.amber),
                    Expanded(
                      child: Text(
                        l.gen_preciseCost(p.costEach, enabled * p.costEach),
                        style: UiText.sans(11.5, color: c.muted),
                      ),
                    ),
                    GenIb(
                      key: const Key('gen-precise-clear'),
                      glyph: UiGlyphs.trash,
                      tooltip: l.gen_clearAll,
                      onTap: a.onClearPrecise,
                    ),
                  ],
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// 一个精准参考：44 方缩略图 │ 类型分段，强度 / 保真度 │ 启用、移除。
class _PreciseItem extends StatelessWidget {
  const _PreciseItem({required this.item});
  final GenPrecise item;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.refs);
    final a = scope.actions;
    final l = context.l10n;
    final p = item;
    GenPrecise copy({
      GenPreciseType? type,
      double? strength,
      double? fidelity,
      bool? enabled,
    }) => GenPrecise(
      id: p.id,
      thumb: p.thumb,
      type: type ?? p.type,
      strength: strength ?? p.strength,
      fidelity: fidelity ?? p.fidelity,
      enabled: enabled ?? p.enabled,
    );
    return Container(
      key: Key('gen-precise-${p.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: GenFormat.softBg(c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Opacity(
            opacity: p.enabled ? 1 : .4,
            child: Container(
              width: 44,
              height: 58,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
              child: UiPreviewImage(image: p.thumb),
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: p.enabled ? 1 : .55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  UiSeg<GenPreciseType>(
                    key: Key('gen-precise-type-${p.id}'),
                    values: GenPreciseType.values,
                    selected: p.type,
                    labelOf: (t) => GenFormat.preciseTypeLabel(context, t),
                    onChanged: (t) => a.onPreciseChanged(copy(type: t)),
                  ),
                  GenSliderRow(
                    key: Key('gen-precise-strength-${p.id}'),
                    label: l.gen_strength,
                    labelWidth: 52,
                    compact: true,
                    value: p.strength,
                    inputMax: 10,
                    defaultValue: 1,
                    onChanged: (x) => a.onPreciseChanged(copy(strength: x)),
                  ),
                  GenSliderRow(
                    key: Key('gen-precise-fidelity-${p.id}'),
                    label: l.gen_fidelity,
                    labelWidth: 52,
                    compact: true,
                    value: p.fidelity,
                    inputMax: 10,
                    defaultValue: 1,
                    onChanged: (x) => a.onPreciseChanged(copy(fidelity: x)),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              GenIb(
                key: Key('gen-precise-enabled-${p.id}'),
                glyph: UiGlyphs.check,
                glyphSize: 15,
                strokeWidth: 2.4,
                size: 24,
                color: p.enabled ? c.ink : c.faint,
                tooltip: p.enabled ? l.gen_refPause : l.gen_refResume,
                onTap: () => a.onPreciseChanged(copy(enabled: !p.enabled)),
              ),
              GenIb(
                key: Key('gen-precise-remove-${p.id}'),
                glyph: UiGlyphs.close,
                glyphSize: 14,
                size: 24,
                tooltip: l.gen_remove,
                onTap: () => a.onRemovePrecise(p.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
