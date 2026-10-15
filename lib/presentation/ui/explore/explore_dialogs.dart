import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../blocks/blocks_contract.dart' show blockPalette;
import '../blocks/blocks_parts.dart' show BlockColorDots;
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'explore_contract.dart';
import 'explore_format.dart';
import 'explore_page.dart';
import 'explore_parts.dart';

/// 弹窗外框：圆角 14 的弹层外观。
class _Frame extends StatelessWidget {
  const _Frame({
    super.key,
    required this.width,
    required this.child,
    this.height,
  });
  final double width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: UiPopoverSurface(radius: 14, child: child),
  );
}

/// 标题行（原型 `.mhd`）：上 18 右 18 下 6 左 22、间距 10；图标 20 · 标题 17 / w700 · …… · 关闭。
class _Header extends StatelessWidget {
  const _Header({
    required this.glyph,
    required this.title,
    required this.onClose,
    this.color,
    this.trailing = const [],
    this.note,
  });
  final String glyph;
  final String title;
  final VoidCallback onClose;
  final Color? color;
  final List<Widget> trailing;

  /// 靠右、紧挨关闭按钮的说明文字。
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 6),
      child: Row(
        spacing: 10,
        children: [
          UiGlyph(glyph, size: 20, color: color ?? c.ink),
          Expanded(
            child: Row(
              spacing: 10,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      17,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
                ...trailing,
              ],
            ),
          ),
          if (note != null) Text(note!, style: UiText.sans(12, color: c.muted)),
          UiIconBox(
            key: const Key('explore-dialog-close'),
            glyph: UiGlyphs.close,
            glyphSize: 16,
            tooltip: context.l10n.explore_close,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

/// 字段标题（原型 `.lab`）：12 / w600 次要色，下面 6。
class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: UiText.sans(12, weight: FontWeight.w600, color: c.muted),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// 两段切换（原型 `.seg2`，弹窗里的大号）：控件底、内边距 2、圆角 7；项 30 高、12.5。
class _Seg<T> extends StatelessWidget {
  const _Seg({
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.enabledOf,
    this.tooltipOf,
  });
  final List<T> values;
  final T value;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool Function(T)? enabledOf;
  final String? Function(T)? tooltipOf;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final v in values)
            Builder(
              builder: (context) {
                final on = v == value;
                final enabled = enabledOf?.call(v) ?? true;
                final tip = tooltipOf?.call(v);
                final w = UiPressable(
                  key: Key('explore-seg-$v'),
                  onTap: on || !enabled ? null : () => onChanged(v),
                  builder: (context, hover) => Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? (c.dark ? c.hover : c.raised) : null,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: on && !c.dark
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labelOf(v),
                      style: UiText.sans(
                        12.5,
                        weight: on ? FontWeight.w600 : FontWeight.w500,
                        color: !enabled
                            ? c.faint
                            : (on || hover ? c.ink : c.muted),
                      ),
                    ),
                  ),
                );
                return tip == null ? w : Tooltip(message: tip, child: w);
              },
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 开始进化 ─────────────────────────────

enum _EvoMode { create, join }

/// 开始进化（原型 `.evodlg`，宽 660）：三步说明 · 新建 / 加入现有线 · 名称 · 第 1 代父本（可去掉、可加自定义串）·
/// 子代替换哪个随机块 —— 第一批子代张数 · 只创建 / 创建并生成。
class ExploreEvolutionDialog extends StatefulWidget {
  const ExploreEvolutionDialog({
    super.key,
    required this.keys,
    required this.onClose,
    required this.onConfirm,
    this.lineId,
  });
  final List<String> keys;

  /// 默认加入的进化线（从进化页签打开时）；null 时新建。
  final String? lineId;
  final VoidCallback onClose;
  final ValueChanged<ExploreEvolutionPlan> onConfirm;

  @override
  State<ExploreEvolutionDialog> createState() => _ExploreEvolutionDialogState();
}

class _ExploreEvolutionDialogState extends State<ExploreEvolutionDialog> {
  late var _keys = [...widget.keys];
  final _custom = <String>[];
  var _adding = false;
  var _count = 8;
  late var _mode = widget.lineId != null ? _EvoMode.join : _EvoMode.create;
  String? _name;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final line =
        run.lines.where((e) => e.id == widget.lineId).firstOrNull ??
        run.lines.lastOrNull;
    final join = _mode == _EvoMode.join && line != null;
    final name = _name ?? l.explore_lineDefault(run.lines.length + 1);
    final vars = scope.data.variables;
    final targets = vars.where((v) => v.evolution).toList();
    final cands = [
      for (final k in _keys)
        if (run.candidate(k) case final x?) x,
    ];
    final parents = cands.length + _custom.length;
    final ok =
        targets.isNotEmpty && parents > 0 && (join || name.trim().isNotEmpty);

    Widget step(int n, String title, String body) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.evoBg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.evo, shape: BoxShape.circle),
              child: Text(
                '$n',
                style: UiText.sans(
                  11,
                  weight: FontWeight.w700,
                  color: c.onEvo,
                  height: 1,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title\n',
                      style: UiText.sans(
                        12,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    TextSpan(text: body),
                  ],
                ),
                style: UiText.sans(12, color: c.muted, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );

    Widget row(Widget thumb, Widget text, VoidCallback? onRemove, Key key) =>
        Container(
          key: key,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            spacing: 10,
            children: [
              thumb,
              Expanded(child: text),
              UiIconBox(
                glyph: UiGlyphs.close,
                size: 26,
                glyphSize: 13,
                tooltip: l.explore_remove,
                onTap: onRemove,
              ),
            ],
          ),
        );

    return _Frame(
      key: const Key('explore-evolution-dialog'),
      width: 660,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            glyph: UiGlyphs.evo,
            color: c.evo,
            title: join
                ? l.explore_evoJoinTitle(
                    parents,
                    line.name,
                    line.current.number,
                  )
                : l.explore_evoTitle(parents),
            onClose: widget.onClose,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        step(1, l.explore_evoStep1, l.explore_evoStep1Body),
                        step(2, l.explore_evoStep2, l.explore_evoStep2Body),
                        step(3, l.explore_evoStep3, l.explore_evoStep3Body),
                      ],
                    ),
                  ),
                  if (line != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _Seg<_EvoMode>(
                        values: _EvoMode.values,
                        value: _mode,
                        labelOf: (m) => m == _EvoMode.create
                            ? l.explore_evoNewLine
                            : l.explore_evoJoin(line.name, line.current.number),
                        onChanged: (m) => setState(() => _mode = m),
                      ),
                    ),
                  if (!join)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Label(l.explore_lineName),
                        UiTextInput(
                          key: const Key('explore-evo-name'),
                          value: name,
                          onChanged: (v) => setState(() => _name = v),
                        ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      _Label(
                        join
                            ? l.explore_evoAddParents(parents)
                            : l.explore_evoParents(parents),
                      ),
                      for (final x in cands)
                        row(
                          SizedBox(
                            width: 40,
                            height: 58,
                            child: ExploreImage(x.thumb ?? x.image, radius: 5),
                          ),
                          Text(
                            ExploreFormat.atomsRaw(x.atoms),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.mono(12, color: c.ink, height: 1.5),
                          ),
                          parents > 1
                              ? () => setState(
                                  () => _keys = [..._keys]..remove(x.key),
                                )
                              : null,
                          Key('explore-evo-parent-${x.key}'),
                        ),
                      for (final (i, s) in _custom.indexed)
                        row(
                          Container(
                            width: 40,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.control,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: UiGlyph(
                              UiGlyphs.pencil,
                              size: 15,
                              color: c.faint,
                            ),
                          ),
                          Text(
                            s,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.mono(12, color: c.ink, height: 1.5),
                          ),
                          parents > 1
                              ? () => setState(() => _custom.removeAt(i))
                              : null,
                          Key('explore-evo-custom-$i'),
                        ),
                      if (_adding)
                        UiTextInput(
                          key: const Key('explore-evo-custom-input'),
                          value: '',
                          autofocus: true,
                          height: 46,
                          hint: l.explore_customHint,
                          style: UiText.mono(12, color: c.ink),
                          onSubmitted: (v) {
                            if (!_adding) return;
                            setState(() {
                              _adding = false;
                              if (v.trim().isNotEmpty) _custom.add(v.trim());
                            });
                          },
                        )
                      else
                        UiPressable(
                          key: const Key('explore-evo-add-custom'),
                          onTap: () => setState(() => _adding = true),
                          builder: (context, hover) => CustomPaint(
                            foregroundPainter: _Dash(c.strong, 9),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hover ? c.hover : null,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 6,
                                children: [
                                  UiGlyph(
                                    UiGlyphs.plus,
                                    size: 14,
                                    color: c.muted,
                                  ),
                                  Text(
                                    l.explore_addCustom,
                                    style: UiText.sans(12.5, color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    key: const Key('explore-genetic-summary'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: targets.isEmpty ? c.warnBg : c.panel,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: targets.isEmpty
                        ? Row(
                            spacing: 8,
                            children: [
                              UiGlyph(UiGlyphs.alert, size: 15, color: c.warn),
                              Expanded(
                                child: Text(
                                  l.explore_noTarget,
                                  style: UiText.sans(12, color: c.warn),
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              UiGlyph(
                                UiGlyphs.evo,
                                size: 15,
                                color: targets.first.color,
                              ),
                              Text(
                                l.explore_targetBefore,
                                style: UiText.sans(12, color: c.muted),
                              ),
                              for (final target in targets)
                                UiBlockPill(
                                  label: target.title,
                                  color: target.color,
                                  icon: target.icon,
                                  badge: UiBlockBadge.evolution,
                                ),
                              Text(
                                l.explore_targetAfter,
                                style: UiText.sans(12, color: c.muted),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          UiDialogFooter(
            children: [
              Text(
                l.explore_firstBatch,
                style: UiText.sans(12, color: c.muted),
              ),
              ExploreStepper(
                value: _count,
                min: 4,
                max: 32,
                bordered: true,
                keyPrefix: 'explore-evo-count',
                onChanged: (v) => setState(() => _count = v),
              ),
              Text(l.explore_atLeast4, style: UiText.sans(12, color: c.faint)),
              const Spacer(),
              UiBtn(
                key: const Key('explore-evo-create'),
                size: UiBtnSize.large,
                onTap: ok
                    ? () => _confirm(join ? line.id : null, name, null)
                    : null,
                children: [
                  Text(join ? l.explore_joinOnly : l.explore_createOnly),
                ],
              ),
              UiBtn(
                key: const Key('explore-evo-create-generate'),
                size: UiBtnSize.large,
                tone: UiBtnTone.evo,
                onTap: ok
                    ? () => _confirm(join ? line.id : null, name, _count)
                    : null,
                children: [
                  UiGlyph(
                    UiGlyphs.play,
                    size: 12,
                    filled: true,
                    color: c.onEvo,
                  ),
                  Text(l.explore_createGenerate(_count)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(String? lineId, String name, int? generate) => widget.onConfirm(
    ExploreEvolutionPlan(
      candidateKeys: _keys,
      customParents: [..._custom],
      newLineName: lineId == null ? name.trim() : null,
      joinLineId: lineId,
      generate: generate,
    ),
  );
}

class _Dash extends CustomPainter {
  _Dash(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          Radius.circular(radius),
        ),
      );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dash old) => old.color != color;
}

// ───────────────────────────── 存为块 ─────────────────────────────

enum _BlockMode { artists, full }

/// 存为提示词块（原型 `.adoptdlg`，宽 560）：来源缩略图 · 只要画师 / 完整正向 · 点 × 去掉画师（再点恢复）·
/// 名称（标题旁实时药丸）· 颜色 · 放到块库哪个文件夹。
class ExploreBlockDialog extends StatefulWidget {
  const ExploreBlockDialog({
    super.key,
    required this.keys,
    required this.onClose,
    required this.onConfirm,
  });
  final List<String> keys;
  final VoidCallback onClose;
  final ValueChanged<ExploreBlockDraft> onConfirm;

  @override
  State<ExploreBlockDialog> createState() => _ExploreBlockDialogState();
}

class _ExploreBlockDialogState extends State<ExploreBlockDialog> {
  var _mode = _BlockMode.artists;
  final _removed = <String>{};
  String? _name;
  var _color = blockPalette[8];
  String? _folder;
  var _folderSet = false;
  UiPopoverAnchor? _pop;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final run = scope.data.run!;
    final cands = [
      for (final k in widget.keys)
        if (run.candidate(k) case final x?) x,
    ];
    final single = cands.length == 1;
    final atoms = {for (final x in cands) ...x.atoms}.toList();
    final kept = [
      for (final a in atoms)
        if (!_removed.contains(a.raw)) a,
    ];
    final name =
        _name ??
        (single
            ? '${run.name} #${cands.first.number}'
            : l.explore_blockNameMany(run.name, cands.length));
    final folders = scope.data.blockFolders;
    if (!_folderSet) _folder = folders.firstOrNull?.id;
    final folder =
        folders.where((f) => f.id == _folder).firstOrNull ??
        folders.firstOrNull;
    final full = _mode == _BlockMode.full && single;
    final ok =
        name.trim().isNotEmpty &&
        (full ? cands.first.prompt.isNotEmpty : kept.isNotEmpty);

    return UiPopover(
      anchor: _pop,
      onDismiss: () => setState(() => _pop = null),
      builder: (_) => UiMenu(
        width: 240,
        onClose: () => setState(() => _pop = null),
        items: [
          for (final f in folders)
            UiMenuItem(
              key: Key('explore-block-folder-${f.id}'),
              label: f.name.isEmpty ? l.explore_blockRoot : f.name,
              glyph: f.id == null ? UiGlyphs.archive : UiGlyphs.folder,
              indent: f.depth * 14.0,
              checked: f.id == folder?.id,
              onTap: () => setState(() {
                _folder = f.id;
                _folderSet = true;
              }),
            ),
        ],
      ),
      child: _Frame(
        key: const Key('explore-block-dialog'),
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              glyph: UiGlyphs.archive,
              title: l.explore_saveBlockTitle,
              onClose: widget.onClose,
              trailing: [
                Flexible(
                  child: UiBlockPill(
                    label: name.trim().isEmpty
                        ? l.explore_untitled
                        : name.trim(),
                    color: _color,
                    icon: 'palette',
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        for (final x in cands.take(6))
                          SizedBox(
                            width: 44,
                            height: 64,
                            child: ExploreImage(x.thumb ?? x.image, radius: 6),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            single
                                ? l.explore_blockFromOne(cands.first.number)
                                : l.explore_blockFromMany(cands.length),
                            style: UiText.sans(12, color: c.muted),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: [
                        Text(
                          l.explore_blockContent,
                          style: UiText.sans(
                            12,
                            weight: FontWeight.w600,
                            color: c.muted,
                          ),
                        ),
                        _Seg<_BlockMode>(
                          values: _BlockMode.values,
                          value: full ? _BlockMode.full : _BlockMode.artists,
                          labelOf: (m) => m == _BlockMode.artists
                              ? l.explore_blockArtists
                              : l.explore_blockFull,
                          enabledOf: (m) => m == _BlockMode.artists || single,
                          tooltipOf: (m) => m == _BlockMode.full && !single
                              ? l.explore_blockFullSingle
                              : null,
                          onChanged: (m) => setState(() => _mode = m),
                        ),
                      ],
                    ),
                    if (full)
                      Container(
                        key: const Key('explore-block-full'),
                        constraints: const BoxConstraints(maxHeight: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.panel,
                          border: Border.all(color: c.line),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: ExplorePromptText(
                            text: cands.first.prompt,
                            hits: cands.first.hits,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Label(
                            l.explore_blockRemoveHint,
                            trailing: Text(
                              l.explore_blockKept(kept.length, atoms.length),
                              style: UiText.sans(11.5, color: c.faint),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.panel,
                              border: Border.all(color: c.line),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final a in atoms)
                                  ExploreAtomChip(
                                    a,
                                    key: Key('explore-block-atom-${a.text}'),
                                    background: c.raised,
                                    border: c.line,
                                    struck: _removed.contains(a.raw),
                                    onTap: () => setState(() {
                                      if (!_removed.remove(a.raw)) {
                                        _removed.add(a.raw);
                                      }
                                    }),
                                    trailing: UiGlyph(
                                      _removed.contains(a.raw)
                                          ? UiGlyphs.retry
                                          : UiGlyphs.close,
                                      size: 11,
                                      color: c.faint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Label(l.explore_blockName),
                        UiTextInput(
                          key: const Key('explore-block-name'),
                          value: name,
                          onChanged: (v) => setState(() => _name = v),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 18,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(l.explore_blockColor),
                            SizedBox(
                              height: 34,
                              child: Center(
                                child: BlockColorDots(
                                  selected: _color,
                                  size: 18,
                                  gap: 7,
                                  onChanged: (v) => setState(() => _color = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Label(l.explore_blockFolder),
                              Builder(
                                builder: (bctx) => UiPressable(
                                  key: const Key('explore-block-folder'),
                                  onTap: () {
                                    final box =
                                        bctx.findRenderObject()! as RenderBox;
                                    setState(
                                      () => _pop = UiPopoverAnchor(
                                        box.localToGlobal(
                                          Offset(0, box.size.height + 4),
                                        ),
                                      ),
                                    );
                                  },
                                  builder: (context, hover) => Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hover ? c.hover : c.bg,
                                      border: Border.all(
                                        color: _pop != null
                                            ? c.accent
                                            : c.strong,
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      spacing: 8,
                                      children: [
                                        UiGlyph(
                                          folder?.id == null
                                              ? UiGlyphs.archive
                                              : UiGlyphs.folder,
                                          size: 14,
                                          color: c.muted,
                                        ),
                                        Expanded(
                                          child: Text(
                                            folder == null ||
                                                    folder.name.isEmpty
                                                ? l.explore_blockRoot
                                                : folder.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: UiText.sans(
                                              13,
                                              color: c.ink,
                                            ),
                                          ),
                                        ),
                                        UiGlyph(
                                          UiGlyphs.chevronDown,
                                          size: 14,
                                          color: c.muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            UiDialogFooter(
              children: [
                UiGlyph(UiGlyphs.infoCircle, size: 13, color: c.faint),
                Expanded(
                  child: Text(
                    l.explore_blockFooter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
                UiBtn(
                  key: const Key('explore-block-cancel'),
                  size: UiBtnSize.large,
                  onTap: widget.onClose,
                  children: [Text(l.explore_cancel)],
                ),
                UiBtn(
                  key: const Key('explore-block-save'),
                  size: UiBtnSize.large,
                  tone: UiBtnTone.primary,
                  onTap: ok
                      ? () => widget.onConfirm(
                          ExploreBlockDraft(
                            title: name.trim(),
                            atoms: full
                                ? const []
                                : [for (final a in kept) a.raw],
                            fullText: full ? cands.first.prompt : null,
                            color: _color,
                            folderId: folder?.id,
                          ),
                        )
                      : null,
                  children: [Text(l.explore_saveBlock)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── 两两比较 ─────────────────────────────

/// 两两比较（原型 `.cmpdlg`，1380 × 888，窗口小时缩）：左右两张父本图，选哪张更接近想要的画风
/// （← → ↓ 空格）；右侧实时排名。每一对马上保存，可以中途关掉。
class ExploreCompareDialog extends StatefulWidget {
  const ExploreCompareDialog({
    super.key,
    required this.lineId,
    required this.onClose,
  });
  final String lineId;
  final VoidCallback onClose;

  @override
  State<ExploreCompareDialog> createState() => _ExploreCompareDialogState();
}

class _ExploreCompareDialogState extends State<ExploreCompareDialog> {
  final _focus = FocusNode(debugLabel: 'explore-compare');
  List<(String, String)>? _pairs;
  var _index = 0;

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

  /// 轮转排程：先比相邻、再隔一个……每个父本尽量均匀出场。
  static List<(String, String)> schedule(List<ExploreParent> parents) {
    final ids = [for (final p in parents) p.id];
    final out = <(String, String)>[];
    for (var gap = 1; gap < ids.length; gap++) {
      for (var i = 0; i + gap < ids.length; i++) {
        out.add(i.isEven ? (ids[i], ids[i + gap]) : (ids[i + gap], ids[i]));
      }
    }
    return out;
  }

  void _answer(ExploreCompareResult r) {
    final pairs = _pairs!;
    if (_index >= pairs.length) return;
    final (a, b) = pairs[_index];
    ExploreScope.of(context).actions.onCompare(widget.lineId, a, b, r);
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = ExploreScope.of(context);
    final line = scope.data.run!.lines
        .where((e) => e.id == widget.lineId)
        .firstOrNull;
    if (line == null) return const SizedBox.shrink();
    final gen = line.current;
    final pairs = _pairs ??= schedule(gen.parents);
    final byId = {for (final p in gen.parents) p.id: p};
    final done = _index >= pairs.length;
    final ranked = [...gen.parents]
      ..sort((a, b) => b.preference.compareTo(a.preference));
    final top = ranked.map((p) => p.preference).fold(0.0, math.max);
    final size = MediaQuery.sizeOf(context);

    Widget side(ExploreParent p, bool left) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Expanded(
            child: UiPressable(
              key: Key('explore-compare-${left ? 'left' : 'right'}-image'),
              onTap: () => _answer(
                left ? ExploreCompareResult.left : ExploreCompareResult.right,
              ),
              builder: (context, hover) => Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hover ? c.evo : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: p.image == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            ExploreFormat.atomsRaw(p.atoms),
                            textAlign: TextAlign.center,
                            style: UiText.mono(14, color: c.muted, height: 1.6),
                          ),
                        ),
                      )
                    : ExploreImage(p.image, fit: BoxFit.contain),
              ),
            ),
          ),
          ExploreArtistsText(
            p.atoms,
            maxLines: 1,
            size: 12.5,
            textAlign: TextAlign.center,
          ),
          UiBtn(
            key: Key('explore-compare-${left ? 'left' : 'right'}'),
            size: UiBtnSize.large,
            expand: true,
            onTap: () => _answer(
              left ? ExploreCompareResult.left : ExploreCompareResult.right,
            ),
            children: [
              if (left) const UiGlyph(UiGlyphs.arrowLeft, size: 15),
              Text(left ? l.explore_leftBetter : l.explore_rightBetter),
              if (!left) const UiGlyph(UiGlyphs.arrowRight, size: 15),
              UiKeycap(left ? '←' : '→'),
            ],
          ),
        ],
      ),
    );

    final Widget main;
    if (done) {
      main = Center(
        key: const Key('explore-compare-done'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.evoBg, shape: BoxShape.circle),
              child: UiGlyph(
                UiGlyphs.check,
                size: 26,
                strokeWidth: 2.6,
                color: c.evo,
              ),
            ),
            Text(
              l.explore_compareDone,
              style: UiText.sans(16, weight: FontWeight.w700, color: c.ink),
            ),
            Text(
              l.explore_compareDoneBody,
              style: UiText.sans(12.5, color: c.muted),
            ),
            const SizedBox(height: 4),
            UiBtn(
              key: const Key('explore-compare-finish'),
              size: UiBtnSize.large,
              tone: UiBtnTone.evo,
              onTap: widget.onClose,
              children: [Text(l.explore_done)],
            ),
          ],
        ),
      );
    } else {
      final (a, b) = pairs[_index];
      main = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            spacing: 12,
            children: [
              Text(
                l.explore_compareQuestion,
                style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
              ),
              const Spacer(),
              Text(
                l.explore_comparePairs(_index + 1, pairs.length),
                style: UiText.mono(12, color: c.muted),
              ),
              SizedBox(
                width: 160,
                child: ExplorePrefBar(_index / pairs.length),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [side(byId[a]!, true), side(byId[b]!, false)],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              UiBtn(
                key: const Key('explore-compare-neither'),
                onTap: () => _answer(ExploreCompareResult.neither),
                children: [
                  const UiGlyph(UiGlyphs.arrowDown, size: 14),
                  Text(l.explore_neither),
                  const UiKeycap('↓'),
                ],
              ),
              UiBtn(
                key: const Key('explore-compare-skip'),
                tone: UiBtnTone.ghost,
                onTap: () => _answer(ExploreCompareResult.skip),
                children: [
                  const UiGlyph(UiGlyphs.skip, size: 13),
                  Text(l.explore_skip),
                  UiKeycap(l.explore_keySpace),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent || done) return KeyEventResult.ignored;
        final r = switch (e.logicalKey) {
          LogicalKeyboardKey.arrowLeft => ExploreCompareResult.left,
          LogicalKeyboardKey.arrowRight => ExploreCompareResult.right,
          LogicalKeyboardKey.arrowDown => ExploreCompareResult.neither,
          LogicalKeyboardKey.space => ExploreCompareResult.skip,
          _ => null,
        };
        if (r == null) return KeyEventResult.ignored;
        _answer(r);
        return KeyEventResult.handled;
      },
      child: _Frame(
        key: const Key('explore-compare-dialog'),
        width: math.min(1380, size.width - 220).clamp(720, 1380).toDouble(),
        height: math.min(888, size.height - 112).clamp(560, 888).toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              glyph: UiGlyphs.sort,
              color: c.evo,
              title: l.explore_compareTitle,
              onClose: widget.onClose,
              note: l.explore_compareNote,
              trailing: [
                ExplorePill(
                  l.explore_lineGen(line.name, gen.number),
                  tone: ExplorePillTone.evo,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 18,
                  children: [
                    Expanded(child: main),
                    Container(
                      width: 280,
                      padding: const EdgeInsets.only(left: 18),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: c.line)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 6,
                        children: [
                          ExploreSect(l.explore_ranking),
                          const SizedBox(height: 4),
                          for (final (i, p) in ranked.indexed)
                            Padding(
                              key: Key('explore-rank-${p.id}'),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                spacing: 9,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    child: Text(
                                      '${i + 1}',
                                      style: UiText.mono(11, color: c.faint),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    height: 44,
                                    child: ExploreImage(p.image, radius: 4),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      spacing: 6,
                                      children: [
                                        ExploreArtistsText(
                                          p.atoms,
                                          maxLines: 1,
                                          size: 12,
                                        ),
                                        ExplorePrefBar(
                                          top <= 0 ? 0 : p.preference / top,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    ExploreFormat.pref(p.preference),
                                    style: UiText.mono(11, color: c.muted),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            l.explore_rankingNote,
                            style: UiText.sans(11, color: c.faint, height: 1.6),
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
      ),
    );
  }
}

// ───────────────────────────── 删除确认 ─────────────────────────────

/// 删除探索 / 进化线确认（同块库删除确认的外观）。
class ExploreConfirmDialog extends StatelessWidget {
  const ExploreConfirmDialog._({
    required this.title,
    required this.body,
    required this.onCancel,
    required this.onConfirm,
    required this.dialogKey,
  });

  factory ExploreConfirmDialog.deleteRun({
    required String runId,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) => ExploreConfirmDialog._(
    title: (l, s) {
      final r = s.data.runs.where((e) => e.id == runId).firstOrNull;
      return l.explore_deleteRunTitle(r?.name ?? s.data.run?.name ?? '');
    },
    body: (l, s) {
      final r = s.data.runs.where((e) => e.id == runId).firstOrNull;
      return l.explore_deleteRunBody(r?.total ?? 0);
    },
    onCancel: onCancel,
    onConfirm: onConfirm,
    dialogKey: 'explore-delete-run',
  );

  factory ExploreConfirmDialog.deleteLine({
    required String lineId,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) => ExploreConfirmDialog._(
    title: (l, s) {
      final line = s.data.run?.lines.where((e) => e.id == lineId).firstOrNull;
      return l.explore_deleteLineTitle(line?.name ?? '');
    },
    body: (l, s) {
      final line = s.data.run?.lines.where((e) => e.id == lineId).firstOrNull;
      final kids =
          line?.generations.fold(0, (n, g) => n + g.childKeys.length) ?? 0;
      return l.explore_deleteLineBody(kids);
    },
    onCancel: onCancel,
    onConfirm: onConfirm,
    dialogKey: 'explore-delete-line',
  );

  final String Function(AppLocalizations l, ExploreScope s) title;
  final String Function(AppLocalizations l, ExploreScope s) body;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String dialogKey;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = ExploreScope.of(context);
    return _Frame(
      key: Key(dialogKey),
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: UiGlyph(UiGlyphs.trash, size: 16, color: c.error),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        title(l, s),
                        style: UiText.sans(
                          15,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        body(l, s),
                        style: UiText.sans(12.5, color: c.muted, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          UiDialogFooter(
            children: [
              const Spacer(),
              UiBtn(
                key: const Key('explore-confirm-cancel'),
                onTap: onCancel,
                children: [Text(l.explore_cancel)],
              ),
              UiBtn(
                key: const Key('explore-confirm-delete'),
                tone: UiBtnTone.primary,
                color: c.error,
                onTap: onConfirm,
                children: [Text(l.explore_delete)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
