import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_page.dart';
import 'refs_parts.dart';
import 'refs_wall.dart';

/// 右侧检查器 340：头部 62（名称 · 改名）、可滚动的参数和整理、底部操作。多选时换成批量面板。
class RefsInspector extends StatelessWidget {
  const RefsInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final picking = ctrl.picking;
    final entry = picking
        ? null
        : data.entries.where((e) => e.key == data.selectedKey).firstOrNull;
    final vibe = data.kind == RefsKind.vibe;

    final Widget header = picking
        ? Text(
            l10n.refs_selectedN(ctrl.picked.length),
            style: UiText.sans(14, weight: FontWeight.w700, color: c.ink),
          )
        : entry == null
        ? Text(
            l10n.refs_inspector,
            style: UiText.sans(14, weight: FontWeight.w700, color: c.faint),
          )
        : RefsNameField(
            key: ValueKey('name-${entry.key}'),
            name: entry.name,
            onRename: (v) => scope.actions.onRename(entry.key, v),
          );

    final Widget body;
    final Widget? footer;
    if (picking) {
      body = const _MultiBody();
      footer = null;
    } else if (entry == null) {
      body = _Placeholder(
        text: vibe ? l10n.refs_noSelectionVibe : l10n.refs_noSelectionPrecise,
      );
      footer = null;
    } else {
      body = SingleChildScrollView(
        key: ValueKey('insp-${entry.key}'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: vibe
            ? RefsVibeBody(entry: entry)
            : RefsPreciseBody(entry: entry),
      );
      footer = _Footer(entry: entry);
    }

    return Container(
      key: const Key('refs-inspector'),
      width: 340,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                child: Align(alignment: Alignment.centerLeft, child: header),
              ),
            ),
          ),
          Expanded(child: body),
          ?footer,
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
          key: const Key('refs-insp-empty'),
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

/// 名称：点铅笔或双击就地改，回车确认、Esc 取消。
class RefsNameField extends StatefulWidget {
  const RefsNameField({
    super.key,
    required this.name,
    required this.onRename,
    this.size = 14,
  });
  final String name;
  final ValueChanged<String> onRename;
  final double size;

  @override
  State<RefsNameField> createState() => _RefsNameFieldState();
}

class _RefsNameFieldState extends State<RefsNameField> {
  TextEditingController? _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _done(true);
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    setState(
      () => _ctrl = TextEditingController(text: widget.name)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.name.length,
        ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _done(bool commit) {
    final c = _ctrl;
    if (c == null) return;
    final v = c.text.trim();
    setState(() => _ctrl = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    if (commit && v.isNotEmpty && v != widget.name) widget.onRename(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final style = UiText.sans(
      widget.size,
      weight: FontWeight.w700,
      color: c.ink,
    );
    if (_ctrl != null) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.accent),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.centerLeft,
        child: Focus(
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent &&
                e.logicalKey == LogicalKeyboardKey.escape) {
              _done(false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            key: const Key('refs-rename'),
            controller: _ctrl,
            focusNode: _focus,
            style: style,
            cursorColor: c.accent,
            cursorHeight: widget.size + 2,
            decoration: uiBareDecoration(),
            onSubmitted: (_) => _done(true),
          ),
        ),
      );
    }
    return Row(
      spacing: 6,
      children: [
        Flexible(
          child: GestureDetector(
            onDoubleTap: _start,
            child: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
        UiIconBox(
          key: const Key('refs-rename-start'),
          glyph: UiGlyphs.pencil,
          glyphSize: 14,
          size: 28,
          tooltip: context.l10n.refs_rename,
          onTap: _start,
        ),
      ],
    );
  }
}

/// 预览：圆角 10、1px 描边、棋盘格底。检查器里铺满（[fit] = cover），完整的图点一下开大图看。
class RefsPreview extends StatelessWidget {
  const RefsPreview({
    super.key,
    required this.image,
    required this.height,
    this.overlays = const [],
    this.onTap,
    this.fit = BoxFit.contain,
  });
  final ImageProvider? image;
  final BoxFit fit;
  final double height;
  final List<Widget> overlays;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.line),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: RefsChecker(c.control, c.bg)),
            RefsImage(image, fit: fit),
            ...overlays,
          ],
        ),
      ),
    );
  }
}

/// 透明底棋盘格（8px 一格）。
class RefsChecker extends CustomPainter {
  RefsChecker(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final p = Paint()..color = a;
    for (var y = 0.0; y < size.height; y += 8) {
      for (var x = 0.0; x < size.width; x += 8) {
        if (((x ~/ 8) + (y ~/ 8)).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(RefsChecker old) => old.a != a || old.b != b;
}

/// Vibe 检查器 / 大图详情右栏共用的内容。
class RefsVibeBody extends StatelessWidget {
  const RefsVibeBody({super.key, required this.entry, this.inDialog = false});
  final RefsEntry entry;

  /// 大图详情里：不画预览，操作行换成详情的样式。
  final bool inDialog;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final e = entry;
    final usable = data.model.vibeUsable;
    final k = data.costs;
    final o = ctrl.overrideOf(e.key);
    final s = o?.strength ?? e.strength;
    final info = o?.infoExtracted ?? e.infoExtracted;
    final changed = o != null;
    final raw = e.hasRaw ?? true;
    final detail = data.detail?.key == e.key ? data.detail : null;
    final trayN = data.tray.items.length;

    void set({double? strength, double? infoExtracted}) {
      final next = RefsSendOverride(
        strength: strength ?? s,
        infoExtracted: infoExtracted ?? info,
      );
      ctrl.setOverride(
        e.key,
        next.strength == e.strength && next.infoExtracted == e.infoExtracted
            ? null
            : next,
      );
    }

    final encoding = RefsEncodingBox(
      entry: e,
      model: data.model,
      costs: k,
      onEncodeNow: () => a.onEncodeNow(e.key),
    );
    final encOk = RefsEncodingInfo.of(context, e, data.model, k)?.ok ?? true;
    final children = <Widget>[
      if (!inDialog)
        RefsPreview(
          key: const Key('refs-insp-preview'),
          image: detail?.image ?? e.thumb,
          height: 250,
          fit: BoxFit.cover,
          onTap: () => ctrl.openDetail(e.key),
          overlays: [
            Positioned(
              left: 8,
              bottom: 8,
              child: UiMini(
                e.isBundle
                    ? l10n.refs_bundleOf(e.bundleCount)
                    : RefsFormat.source(context, e.source),
                background: const Color(0xB30F0F0F),
                foreground: Colors.white,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: RefsStarButton(
                on: e.favorite,
                onTap: () => a.onSetFavorite([e.key], !e.favorite),
              ),
            ),
          ],
        ),
      Row(
        key: const Key('refs-insp-actions'),
        spacing: 8,
        children: [
          Expanded(
            child: UiBtn(
              key: const Key('refs-insp-add'),
              size: UiBtnSize.large,
              tone: UiBtnTone.primary,
              expand: true,
              onTap: usable ? () => ctrl.add([e.key]) : null,
              children: [
                const UiGlyph(UiGlyphs.plus, size: 15, strokeWidth: 2.4),
                Text(l10n.refs_addToGeneration),
                Opacity(
                  opacity: .75,
                  child: Text(
                    '$trayN/${k.maxVibes}',
                    style: UiText.mono(12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          UiBtn(
            key: const Key('refs-insp-replace'),
            size: UiBtnSize.large,
            tooltip: l10n.refs_replaceVibesTip,
            onTap: usable ? () => ctrl.add([e.key], replace: true) : null,
            children: [
              const UiGlyph(UiGlyphs.swap, size: 15),
              Text(l10n.refs_replace),
            ],
          ),
        ],
      ),
      // 要编码 / 不能用的提醒放在参数前面，发送前就看得到。
      if (!encOk) encoding,
      if (e.isBundle)
        RefsBox(
          key: const Key('refs-insp-bundle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                l10n.refs_bundleNote(e.bundleCount),
                style: UiText.sans(12, color: c.muted, height: 1.55),
              ),
              UiBtn(
                key: const Key('refs-insp-open-bundle'),
                size: UiBtnSize.small,
                onTap: () => ctrl.openDetail(e.key),
                children: [
                  const UiGlyph(UiGlyphs.stack, size: 13),
                  Text(l10n.refs_openBundle),
                ],
              ),
            ],
          ),
        )
      else
        Column(
          key: const Key('refs-insp-params'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            RefsParam(
              key: const Key('refs-strength'),
              label: l10n.refs_strength,
              value: s,
              defaultValue: e.strength,
              changed: s != e.strength,
              desc: l10n.refs_strengthDesc,
              onChanged: (v) => set(strength: v),
            ),
            RefsParam(
              key: const Key('refs-info'),
              label: l10n.refs_infoExtracted,
              value: info,
              defaultValue: e.infoExtracted,
              changed: info != e.infoExtracted,
              desc: raw ? l10n.refs_infoDesc(k.encode) : l10n.refs_infoLocked,
              onChanged: raw ? (v) => set(infoExtracted: v) : null,
            ),
            if (changed)
              Container(
                key: const Key('refs-changed'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.refs_changedNote,
                        style: UiText.sans(12, color: c.ink),
                      ),
                    ),
                    _Link(
                      key: const Key('refs-save-default'),
                      label: l10n.refs_saveDefault,
                      strong: true,
                      onTap: () {
                        a.onUpdateParams(
                          e.key,
                          RefsParamsPatch(
                            strength: s != e.strength ? s : null,
                            infoExtracted: info != e.infoExtracted
                                ? info
                                : null,
                          ),
                        );
                        ctrl.setOverride(e.key, null);
                      },
                    ),
                    _Link(
                      key: const Key('refs-revert'),
                      label: l10n.refs_revert,
                      onTap: () => ctrl.setOverride(e.key, null),
                    ),
                  ],
                ),
              ),
          ],
        ),
      if (encOk) encoding,
      Column(
        key: const Key('refs-insp-organize'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          RefsSectionLabel(l10n.refs_organize),
          _FieldRow(
            label: l10n.refs_category,
            child: Builder(
              builder: (ctx) => UiDropChip(
                key: const Key('refs-insp-category'),
                glyph: UiGlyphs.folder,
                expand: true,
                label:
                    data.categories
                        .where((x) => x.id == e.categoryId)
                        .firstOrNull
                        ?.name ??
                    l10n.refs_uncategorized,
                onTap: () {
                  final box = ctx.findRenderObject()! as RenderBox;
                  ctrl.openMenu(
                    UiPopoverAnchor(
                      box.localToGlobal(
                        box.size.bottomLeft(const Offset(0, 6)),
                      ),
                    ),
                    refsCategoryMenu(
                      context,
                      (id) => a.onMoveToCategory([e.key], id),
                      current: e.categoryId,
                      markCurrent: true,
                    ),
                  );
                },
              ),
            ),
          ),
          _FieldRow(
            label: l10n.refs_tags,
            top: true,
            child: Wrap(
              key: const Key('refs-insp-tags'),
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final t in e.tags)
                  RefsTag(t, onRemove: () => a.onRemoveTag(e.key, t)),
                RefsAddTag(onAdd: (t) => a.onAddTags([e.key], [t])),
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: RefsKv(
          key: const Key('refs-insp-kv'),
          rows: [
            (
              l10n.refs_used,
              Text(
                e.usedCount == 0
                    ? l10n.refs_neverUsed
                    : l10n.refs_usedTimes(
                        e.usedCount,
                        RefsFormat.relative(context, e.lastUsed, data.now),
                      ),
              ),
            ),
            if (e.createdAt case final d?)
              (l10n.refs_added, Text(RefsFormat.date(d))),
            if (e.fileName case final f?)
              (
                l10n.refs_file,
                Text(
                  f,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11, color: c.ink, height: 18 / 11),
                ),
              ),
          ],
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: inDialog ? 16 : 14,
      children: children,
    );
  }
}

/// 精准参考检查器 / 大图详情右栏共用的内容。改动直接写回默认值。
class RefsPreciseBody extends StatelessWidget {
  const RefsPreciseBody({
    super.key,
    required this.entry,
    this.inDialog = false,
  });
  final RefsEntry entry;
  final bool inDialog;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final e = entry;
    final usable = data.model.preciseUsable;
    final detail = data.detail?.key == e.key ? data.detail : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: inDialog ? 16 : 14,
      children: [
        if (!inDialog)
          RefsPreview(
            key: const Key('refs-insp-preview'),
            image: detail?.image ?? e.thumb,
            height: 270,
            fit: BoxFit.cover,
            onTap: () => ctrl.openDetail(e.key),
            overlays: [
              Positioned(
                right: 8,
                top: 8,
                child: RefsStarButton(
                  on: e.favorite,
                  onTap: () => a.onSetFavorite([e.key], !e.favorite),
                ),
              ),
            ],
          ),
        Column(
          key: const Key('refs-insp-actions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            UiBtn(
              key: const Key('refs-insp-add'),
              size: UiBtnSize.large,
              tone: UiBtnTone.primary,
              expand: true,
              onTap: usable ? () => ctrl.add([e.key]) : null,
              children: [
                const Icon(StudioIcons.preciseReference, size: 15),
                Text(l10n.refs_sendPrecise),
                Opacity(
                  opacity: .75,
                  child: Text(
                    l10n.refs_plusAnlas(data.costs.precise),
                    style: UiText.mono(12, color: Colors.white),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: UiBtn(
                    key: const Key('refs-insp-img2img'),
                    expand: true,
                    onTap: () => a.onSendImg2Img(e.key),
                    children: [
                      const Icon(StudioIcons.imageToImage, size: 14),
                      Text(l10n.refs_sendImg2Img),
                    ],
                  ),
                ),
                Expanded(
                  child: UiBtn(
                    key: const Key('refs-insp-save-vibe'),
                    expand: true,
                    onTap: () => a.onSaveAsVibe(e.key),
                    children: [
                      const Icon(StudioIcons.vibeLibrary, size: 14),
                      Text(l10n.refs_alsoSaveVibe),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          key: const Key('refs-insp-type'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            RefsSectionLabel(l10n.refs_referenceWhat),
            RefsTypeSeg(
              value: e.type,
              onChanged: (t) =>
                  a.onUpdateParams(e.key, RefsParamsPatch(type: t)),
            ),
            Text(
              RefsFormat.typeDesc(context, e.type),
              style: UiText.sans(12, color: c.muted),
            ),
          ],
        ),
        Column(
          key: const Key('refs-insp-params'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            RefsParam(
              key: const Key('refs-strength'),
              label: l10n.refs_preciseStrength,
              value: e.strength,
              max: 10,
              desc: l10n.refs_preciseStrengthDesc,
              onChanged: (v) =>
                  a.onUpdateParams(e.key, RefsParamsPatch(strength: v)),
            ),
            RefsParam(
              key: const Key('refs-fidelity'),
              label: l10n.refs_fidelity,
              value: e.fidelity,
              max: 10,
              desc: l10n.refs_fidelityDesc,
              onChanged: (v) =>
                  a.onUpdateParams(e.key, RefsParamsPatch(fidelity: v)),
            ),
            Text(
              l10n.refs_preciseDefaultsNote,
              style: UiText.sans(11, color: c.faint),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: RefsKv(
            key: const Key('refs-insp-kv'),
            rows: [
              (
                l10n.refs_used,
                Text(
                  e.usedCount == 0
                      ? l10n.refs_neverUsed
                      : l10n.refs_usedTimes(
                          e.usedCount,
                          RefsFormat.relative(context, e.lastUsed, data.now),
                        ),
                ),
              ),
              if (e.createdAt case final d?)
                (l10n.refs_added, Text(RefsFormat.dateTime(d))),
              if (e.imageSize case final s?)
                (
                  l10n.refs_original,
                  Text(
                    '${s.width.round()} × ${s.height.round()}'
                    '${e.imageFormat == null ? '' : ' · ${e.imageFormat}'}',
                    style: UiText.mono(11, color: c.ink, height: 18 / 11),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 参考类型三选一：整宽、每格 46 高（图标在上、字在下）。
class RefsTypeSeg extends StatelessWidget {
  const RefsTypeSeg({
    super.key,
    required this.value,
    required this.onChanged,
    this.tall = true,
  });
  final RefsPreciseType? value;
  final ValueChanged<RefsPreciseType> onChanged;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('refs-type-seg'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        spacing: 2,
        children: [
          for (final t in RefsPreciseType.values)
            Expanded(
              child: UiPressable(
                key: Key('refs-type-seg-${t.name}'),
                onTap: () => onChanged(t),
                builder: (context, hover) {
                  final on = t == value;
                  final fg = on ? c.ink : (hover ? c.ink : c.muted);
                  final label = Text(
                    RefsFormat.type(context, t),
                    maxLines: 1,
                    style: UiText.sans(
                      12,
                      weight: on ? FontWeight.w600 : FontWeight.w400,
                      color: fg,
                    ),
                  );
                  final glyph = UiGlyph(
                    RefsFormat.typeGlyph(t),
                    size: 15,
                    color: on ? RefsPalette.type(t) : fg,
                  );
                  return Container(
                    height: tall ? 46 : 26,
                    decoration: BoxDecoration(
                      color: on ? c.raised : null,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: on
                          ? const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: tall
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 2,
                            children: [glyph, label],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 5,
                            children: [glyph, label],
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child, this.top = false});
  final String label;
  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      crossAxisAlignment: top
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      spacing: 8,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: UiText.sans(
              12,
              color: c.muted,
              height: top ? 22 / 12 : null,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    super.key,
    required this.label,
    required this.onTap,
    this.strong = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (_, hover) => Text(
        label,
        style: UiText.sans(
          12,
          weight: strong ? FontWeight.w600 : FontWeight.w400,
          color: strong
              ? (hover ? c.ink : c.accent)
              : (hover ? c.ink : c.muted),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.entry});
  final RefsEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final a = scope.actions;
    final ctrl = scope.controller;
    final vibe = scope.data.kind == RefsKind.vibe;
    final e = entry;
    return Container(
      key: const Key('refs-insp-footer'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 6,
        children: [
          if (vibe)
            UiBtn(
              key: const Key('refs-insp-export'),
              size: UiBtnSize.small,
              onTap: () => ctrl.openExport([e.key]),
              children: [
                const UiGlyph(UiGlyphs.upload, size: 13),
                Text(l10n.refs_export),
              ],
            )
          else
            UiBtn(
              key: const Key('refs-insp-copy'),
              size: UiBtnSize.small,
              onTap: () => a.onCopyImage(e.key),
              children: [
                const UiGlyph(UiGlyphs.copy, size: 13),
                Text(l10n.refs_copyImage),
              ],
            ),
          UiBtn(
            key: const Key('refs-insp-folder'),
            size: UiBtnSize.small,
            onTap: () => a.onOpenFolder(e.key),
            children: [
              const UiGlyph(UiGlyphs.folder, size: 13),
              Text(l10n.refs_showInFolderShort),
            ],
          ),
          const Spacer(),
          UiBtn(
            key: const Key('refs-insp-delete'),
            size: UiBtnSize.small,
            tone: UiBtnTone.ghost,
            color: c.error,
            onTap: () => ctrl.confirmDelete([e.key]),
            children: [
              const UiGlyph(UiGlyphs.trash, size: 13),
              Text(l10n.refs_delete),
            ],
          ),
        ],
      ),
    );
  }
}

/// 多选面板：叠放的预览 · 加入后的数量和费用 · 统一设置 · 整理。
class _MultiBody extends StatelessWidget {
  const _MultiBody();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final keys = ctrl.picked.toList();
    final vibe = data.kind == RefsKind.vibe;
    final k = data.costs;
    final picked = [
      for (final key in keys)
        ?data.entries.where((e) => e.key == key).firstOrNull,
    ];
    if (picked.isEmpty) {
      return _Placeholder(text: l10n.refs_pickHint);
    }
    final adding = picked.where((e) => !e.inGeneration).toList();
    final before = data.tray.items.length;
    final after = before + adding.length;
    final encodes = adding
        .where(
          (e) =>
              e.encoding == RefsEncoding.encodeOnUse ||
              e.encoding == RefsEncoding.reencode,
        )
        .toList();
    final extra = RefsFormat.extraAfter(k, after);
    final strengths = picked.map((e) => e.strength).toSet();
    final types = picked.map((e) => e.type).toSet();

    final show = picked.take(4).toList();
    final stack = SizedBox(
      key: const Key('refs-multi-stack'),
      height: 170,
      child: Stack(
        children: [
          for (final (j, e) in show.indexed)
            Positioned(
              left: 60.0 + j * 34 + (4 - show.length) * 17,
              top: 10.0 + j * 6,
              child: Transform.rotate(
                angle: (j - (show.length - 1) / 2) * 4 * math.pi / 180,
                child: Container(
                  width: 120,
                  height: 150,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.raised, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: c.dark ? .4 : .14,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: RefsImage(e.thumb),
                ),
              ),
            ),
        ],
      ),
    );

    final summary = RefsBox(
      key: const Key('refs-multi-summary'),
      child: DefaultTextStyle.merge(
        style: UiText.sans(12, color: c.ink, height: 1.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  vibe ? l10n.refs_multiAddTitle : l10n.refs_multiSendTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  vibe ? '$before → $after/${k.maxVibes}' : '$before → $after',
                  style: UiText.mono(
                    12,
                    color: after > k.maxVibes ? c.error : c.muted,
                  ),
                ),
              ],
            ),
            Text(
              vibe
                  ? [
                      if (after > k.maxVibes)
                        l10n.refs_multiOverMax(k.maxVibes)
                      else if (extra > 0)
                        l10n.refs_multiExtra(k.freeVibes, k.extraPerVibe, extra)
                      else
                        l10n.refs_multiFree(k.freeVibes),
                      if (encodes.isNotEmpty)
                        l10n.refs_multiEncodes(
                          encodes.length,
                          encodes.map((e) => e.name).take(2).join('、'),
                          k.encode,
                        ),
                      if (picked.length > adding.length)
                        l10n.refs_multiAlready(picked.length - adding.length),
                    ].join('')
                  : l10n.refs_multiPreciseCost(k.precise, after * k.precise),
              style: TextStyle(color: c.muted),
            ),
          ],
        ),
      ),
    );

    final unify = Column(
      key: const Key('refs-multi-unify'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        RefsSectionLabel(l10n.refs_unify),
        if (vibe) ...[
          _UnifyStrength(
            keys: keys,
            value: strengths.length == 1 ? strengths.first : null,
            onCommit: (v) => a.onSetStrengthMany(keys, v),
          ),
          Text(
            l10n.refs_unifyVibeNote(picked.length),
            style: UiText.sans(11, color: c.faint, height: 1.5),
          ),
        ] else ...[
          RefsTypeSeg(
            tall: false,
            value: types.length == 1 ? types.first : null,
            onChanged: (t) => a.onSetTypeMany(keys, t),
          ),
          Text(
            l10n.refs_unifyPreciseNote(picked.length),
            style: UiText.sans(11, color: c.faint, height: 1.5),
          ),
        ],
      ],
    );

    final allFav = picked.every((e) => e.favorite);
    final organize = Column(
      key: const Key('refs-multi-organize'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        RefsSectionLabel(l10n.refs_organize),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (vibe) ...[
              Builder(
                builder: (ctx) => UiBtn(
                  key: const Key('refs-multi-move'),
                  size: UiBtnSize.small,
                  onTap: () {
                    final box = ctx.findRenderObject()! as RenderBox;
                    ctrl.openMenu(
                      UiPopoverAnchor(
                        box.localToGlobal(
                          box.size.bottomLeft(const Offset(0, 6)),
                        ),
                      ),
                      refsCategoryMenu(
                        context,
                        (id) => a.onMoveToCategory(keys, id),
                      ),
                    );
                  },
                  children: [
                    const UiGlyph(UiGlyphs.folder, size: 13),
                    Text(l10n.refs_moveToCategory),
                  ],
                ),
              ),
              _MultiTag(onAdd: (t) => a.onAddTags(keys, [t])),
            ],
            UiBtn(
              key: const Key('refs-multi-favorite'),
              size: UiBtnSize.small,
              onTap: () => a.onSetFavorite(keys, !allFav),
              children: [
                const UiGlyph(UiGlyphs.star, size: 13),
                Text(allFav ? l10n.refs_unfavorite : l10n.refs_favorite),
              ],
            ),
            if (vibe)
              UiBtn(
                key: const Key('refs-multi-pack'),
                size: UiBtnSize.small,
                onTap: picked.length < 2 || picked.any((e) => e.isBundle)
                    ? null
                    : () => a.onPackBundle(keys),
                children: [
                  const UiGlyph(UiGlyphs.stack, size: 13),
                  Text(l10n.refs_packBundle),
                ],
              ),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [stack, summary, unify, organize],
      ),
    );
  }
}

/// 统一强度：拖动时只动本地值，松手写回。
class _UnifyStrength extends StatefulWidget {
  const _UnifyStrength({
    required this.keys,
    required this.value,
    required this.onCommit,
  });
  final List<String> keys;
  final double? value;
  final ValueChanged<double> onCommit;

  @override
  State<_UnifyStrength> createState() => _UnifyStrengthState();
}

class _UnifyStrengthState extends State<_UnifyStrength> {
  double? _local;

  @override
  void didUpdateWidget(covariant _UnifyStrength old) {
    super.didUpdateWidget(old);
    if (old.keys.join() != widget.keys.join()) _local = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final v = _local ?? widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 5,
      children: [
        Row(
          children: [
            Text(
              l10n.refs_strength,
              style: UiText.sans(
                12.5,
                weight: FontWeight.w600,
                color: context.ui.ink,
              ),
            ),
            const Spacer(),
            UiNumBox(
              value: v ?? 0,
              placeholder: v == null ? l10n.refs_mixed : null,
              onSubmitted: (x) {
                setState(() => _local = x);
                widget.onCommit(x);
              },
            ),
          ],
        ),
        UiSlider(
          key: const Key('refs-multi-strength'),
          value: v ?? 0,
          empty: v == null,
          onChanged: (x) => setState(() => _local = x),
          onChangeEnd: widget.onCommit,
        ),
      ],
    );
  }
}

/// 多选“加标签”：按钮点开变成输入框。
class _MultiTag extends StatefulWidget {
  const _MultiTag({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  State<_MultiTag> createState() => _MultiTagState();
}

class _MultiTagState extends State<_MultiTag> {
  var _editing = false;

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return RefsAddTag(
        startOpen: true,
        onAdd: widget.onAdd,
        onClosed: () => setState(() => _editing = false),
      );
    }
    return UiBtn(
      key: const Key('refs-multi-tag'),
      size: UiBtnSize.small,
      onTap: () => setState(() => _editing = true),
      children: [
        const UiGlyph(UiGlyphs.tag, size: 13),
        Text(context.l10n.refs_addTag),
      ],
    );
  }
}
