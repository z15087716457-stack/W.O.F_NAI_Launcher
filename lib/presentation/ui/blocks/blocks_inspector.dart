import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_edit.dart';
import 'blocks_format.dart';
import 'blocks_page.dart';
import 'blocks_parts.dart';

UiPopoverAnchor _below(BuildContext ctx, {bool right = false}) {
  final box = ctx.findRenderObject()! as RenderBox;
  return UiPopoverAnchor(
    box.localToGlobal(
      right
          ? box.size.bottomRight(const Offset(0, 6))
          : box.size.bottomLeft(const Offset(0, 6)),
    ),
    alignRight: right,
  );
}

/// 详情栏 340：标题 61（详情 / 已选 N 个块）+ 可滚动正文。
/// 单选：预览图 · 药丸 + 改名 · 插入 / 收藏 / 复制 / 编辑 · 内容 · 附带参数 · 外观 · 归类 · 使用与来源。
/// 多选：选中的药丸 · 合计 · 批量操作 · 拖放提示。
class BlocksInspector extends StatelessWidget {
  const BlocksInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final ctrl = scope.controller;
    final picking = ctrl.picking && ctrl.picked.isNotEmpty;
    final b = picking ? null : d.selected;

    return Container(
      key: const Key('blocks-inspector'),
      width: BlocksLibraryPage.inspectorWidth,
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
                  right: WindowChromeScope.activeOf(context) ? 0 : 10,
                ),
                child: Row(
                  spacing: 6,
                  children: [
                    Text(
                      picking
                          ? l10n.blocks_selectedBlocksN(ctrl.picked.length)
                          : l10n.blocks_details,
                      style: UiText.sans(
                        14,
                        weight: FontWeight.w700,
                        color: b == null && !picking ? c.faint : c.ink,
                      ),
                    ),
                    const Spacer(),
                    if (b != null)
                      Builder(
                        builder: (ctx) => UiIconBox(
                          key: const Key('blocks-insp-more'),
                          glyph: UiGlyphs.more,
                          glyphSize: 16,
                          size: 28,
                          tooltip: l10n.blocks_more,
                          onTap: () => ctrl.openMenu(
                            _below(ctx, right: true),
                            blocksCardMenu(context, b),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: picking
                ? const _Multi()
                : b == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        l10n.blocks_noSelection,
                        textAlign: TextAlign.center,
                        style: UiText.sans(12.5, color: c.faint, height: 1.6),
                      ),
                    ),
                  )
                : _Single(key: ValueKey('insp-${b.id}'), block: b),
          ),
        ],
      ),
    );
  }
}

class _Single extends StatefulWidget {
  const _Single({super.key, required this.block});
  final BlockData block;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  var _negative = false;
  var _renaming = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final b = widget.block;
    final showNeg = _negative || b.atoms.isEmpty;
    final atoms = showNeg ? b.negativeAtoms : b.atoms;
    final p = b.params;

    Widget section(
      String title,
      List<Widget> children, {
      String? count,
      Widget? trailing,
      Key? key,
    }) => Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 7,
      children: [
        BlockLabel(title, count: count, trailing: trailing),
        ...children,
      ],
    );

    Widget link(String text, VoidCallback? onTap, {Key? key}) => UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, hover) => Text(
        text,
        style:
            UiText.sans(
              11,
              weight: FontWeight.w500,
              color: onTap == null ? c.faint : c.accent,
            ).copyWith(
              decoration: hover ? TextDecoration.underline : null,
              decorationColor: c.accent,
            ),
      ),
    );

    final kv = <(String, String)>[
      if (p?.model case final m?) (l10n.blocks_paramModel, d.catalog.model(m)),
      if (p?.steps case final s?) (l10n.blocks_paramSteps, '$s'),
      if (p?.scale case final g?)
        (
          l10n.blocks_paramGuidance,
          p!.cfgRescale == null
              ? BlocksFormat.num1(g)
              : '${BlocksFormat.num1(g)} · ${l10n.blocks_rescale(BlocksFormat.num1(p.cfgRescale!).replaceAll('.0', ''))}',
        ),
      if (p?.sampler case final s?)
        (l10n.blocks_paramSampler, d.catalog.sampler(s)),
      if (p?.noiseSchedule case final n?)
        (l10n.blocks_paramNoise, d.catalog.noise(n)),
    ];

    final folderName = b.folderId == null
        ? l10n.blocks_uncategorized
        : d.folders.where((f) => f.id == b.folderId).firstOrNull?.name ??
              b.folderName ??
              '';

    final sourceState = switch (b.sourceState) {
      BlockSourceState.synced => l10n.blocks_sourceSynced,
      BlockSourceState.changed => l10n.blocks_sourceChanged,
      BlockSourceState.missing => l10n.blocks_sourceMissing,
      BlockSourceState.none => null,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          if (b.thumb != null)
            Container(
              height: 176,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BlockCover(b),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: UiPressable(
                      key: const Key('blocks-insp-thumb'),
                      onTap: () => ctrl.openEdit(b.id),
                      builder: (context, hover) => Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: hover ? .7 : .55,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 6,
                          children: [
                            const UiGlyph(
                              UiGlyphs.picture,
                              size: 13,
                              color: Colors.white,
                            ),
                            Text(
                              l10n.blocks_changeThumb,
                              style: UiText.sans(
                                12,
                                weight: FontWeight.w500,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: [
              Row(
                spacing: 8,
                children: [
                  if (_renaming)
                    Expanded(
                      child: UiTextInput(
                        key: const Key('blocks-insp-name'),
                        value: b.title,
                        autofocus: true,
                        selectAll: true,
                        height: 30,
                        onSubmitted: (v) {
                          if (!_renaming) return;
                          setState(() => _renaming = false);
                          final t = v.trim();
                          if (t.isNotEmpty && t != b.title) {
                            a.onUpdate(b.id, BlockPatch(title: t));
                          }
                        },
                      ),
                    )
                  else ...[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BlockPill(b, large: true),
                      ),
                    ),
                    UiIconBox(
                      key: const Key('blocks-insp-rename'),
                      glyph: UiGlyphs.pencil,
                      size: 26,
                      glyphSize: 13,
                      tooltip: l10n.blocks_rename,
                      onTap: () => setState(() => _renaming = true),
                    ),
                  ],
                ],
              ),
              Row(
                spacing: 6,
                children: [
                  UiBtn(
                    key: const Key('blocks-insp-insert'),
                    tone: UiBtnTone.primary,
                    onTap: () => a.onInsert([b.id]),
                    children: [
                      const UiGlyph(UiGlyphs.plus, size: 14, strokeWidth: 2.2),
                      Text(l10n.blocks_insertToPrompt),
                    ],
                  ),
                  UiBtn(
                    key: const Key('blocks-insp-favorite'),
                    tooltip: b.favorite
                        ? l10n.blocks_unfavorite
                        : l10n.blocks_favorite,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: b.favorite ? c.star : null,
                    onTap: () => a.onSetFavorite([b.id], !b.favorite),
                    children: [
                      UiGlyph(UiGlyphs.star, size: 15, filled: b.favorite),
                    ],
                  ),
                  UiBtn(
                    key: const Key('blocks-insp-copy'),
                    tooltip: l10n.blocks_copyContent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: () => a.onCopyText(b.id),
                    children: const [UiGlyph(UiGlyphs.copy, size: 15)],
                  ),
                  UiBtn(
                    key: const Key('blocks-insp-edit'),
                    onTap: () => ctrl.openEdit(b.id),
                    children: [
                      const UiGlyph(UiGlyphs.pencil, size: 14),
                      Text(l10n.blocks_edit),
                    ],
                  ),
                ],
              ),
            ],
          ),
          section(
            l10n.blocks_content,
            count: l10n.blocks_items(atoms.length),
            trailing: b.hasNegative && b.atoms.isNotEmpty
                ? BlockSeg<bool>(
                    mini: true,
                    values: const [false, true],
                    selected: _negative,
                    keyOf: (v) => Key('blocks-insp-${v ? 'neg' : 'pos'}'),
                    labelOf: (v) => v
                        ? l10n.blocks_negativeN(b.negativeAtoms.length)
                        : l10n.blocks_positive,
                    onTap: (v) => setState(() => _negative = v),
                  )
                : null,
            [
              BlockBox(
                key: const Key('blocks-insp-atoms'),
                child: BlockAtoms(atoms, mono: true, fontSize: 11, max: 60),
              ),
            ],
          ),
          if (b.reading != null)
            section(
              l10n.blocks_reading,
              trailing: b.readingNeedsReview
                  ? BlockBadge(l10n.blocks_needsReview, color: c.warn)
                  : null,
              [
                Text(
                  b.reading!,
                  style: UiText.sans(12, color: c.ink, height: 1.6),
                ),
              ],
            ),
          section(
            key: const Key('blocks-insp-params'),
            l10n.blocks_params,
            trailing: b.hasParams
                ? link(
                    l10n.blocks_applyToCurrent,
                    p!.incompatible == null
                        ? () => a.onApplyParams(b.id)
                        : null,
                    key: const Key('blocks-insp-apply'),
                  )
                : null,
            [
              if (b.hasParams) ...[
                BlockBox(child: BlockKv(kv)),
                if (p!.incompatible != null)
                  Text(p.incompatible!, style: UiText.sans(11, color: c.warn)),
              ] else
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.blocks_noParams),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: link(
                            l10n.blocks_add,
                            () => ctrl.openEdit(b.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                  style: UiText.sans(12, color: c.faint),
                ),
            ],
          ),
          section(l10n.blocks_appearance, [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: BlockColorDots(
                key: const Key('blocks-insp-colors'),
                selected: b.color,
                ringGap: c.panel,
                onChanged: (col) => a.onUpdate(b.id, BlockPatch(color: col)),
              ),
            ),
            Row(
              spacing: 6,
              children: [
                Builder(
                  builder: (ctx) => UiBtn(
                    key: const Key('blocks-insp-icon'),
                    size: UiBtnSize.small,
                    onTap: () => ctrl.openPanel(
                      _below(ctx),
                      (_) => UiPopoverSurface(
                        padding: const EdgeInsets.all(10),
                        child: BlockIconGrid(
                          selected: b.icon,
                          color: b.color,
                          onChanged: (icon) {
                            ctrl.closeMenu();
                            a.onUpdate(
                              b.id,
                              icon == null
                                  ? const BlockPatch(clearIcon: true)
                                  : BlockPatch(icon: icon),
                            );
                          },
                        ),
                      ),
                    ),
                    children: [
                      UiBlockIcon(b.icon, size: 13, color: b.color),
                      Text(l10n.blocks_icon),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) => UiBtn(
                    key: const Key('blocks-insp-look'),
                    size: UiBtnSize.small,
                    onTap: () => ctrl.openMenu(_below(ctx), [
                      for (final look in BlockAppearance.values)
                        UiMenuItem(
                          key: Key('blocks-look-${look.name}'),
                          label: BlocksFormat.look(context, look),
                          checked: b.look == look,
                          onTap: () => a.onUpdate(b.id, BlockPatch(look: look)),
                        ),
                    ]),
                    children: [
                      Text(BlocksFormat.look(context, b.look)),
                      const UiGlyph(UiGlyphs.chevronDown, size: 12),
                    ],
                  ),
                ),
                if (b.thumb == null)
                  UiBtn(
                    size: UiBtnSize.small,
                    onTap: () => ctrl.openEdit(b.id),
                    children: [
                      const UiGlyph(UiGlyphs.picture, size: 13),
                      Text(l10n.blocks_thumb),
                    ],
                  ),
              ],
            ),
          ]),
          section(l10n.blocks_classify, [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Builder(
                  builder: (ctx) => UiBtn(
                    key: const Key('blocks-insp-folder'),
                    size: UiBtnSize.small,
                    onTap: () => ctrl.openMenu(
                      _below(ctx),
                      blocksMoveMenu(context, [b.id]),
                      width: 230,
                    ),
                    children: [
                      const UiGlyph(UiGlyphs.folder, size: 13),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          folderName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const UiGlyph(UiGlyphs.chevronDown, size: 12),
                    ],
                  ),
                ),
                for (final t in b.tags)
                  BlockTagChip(
                    t,
                    onRemove: () => a.onRemoveTag([b.id], t.name),
                  ),
                Builder(
                  builder: (ctx) => UiBtn(
                    key: const Key('blocks-insp-tag'),
                    size: UiBtnSize.small,
                    tone: UiBtnTone.ghost,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onTap: () => ctrl.openMenu(_below(ctx), [
                      for (final t in d.tags)
                        if (!b.tags.any((x) => x.name == t.tag.name))
                          UiMenuItem(
                            label: t.tag.name,
                            glyph: UiGlyphs.tag,
                            onTap: () => a.onAddTag([b.id], t.tag),
                          ),
                      UiMenuItem(
                        label: l10n.blocks_newTagInEdit,
                        glyph: UiGlyphs.plus,
                        divider: d.tags.isNotEmpty,
                        onTap: () => ctrl.openEdit(b.id),
                      ),
                    ]),
                    children: [
                      const UiGlyph(UiGlyphs.plus, size: 13),
                      Text(l10n.blocks_tag),
                    ],
                  ),
                ),
              ],
            ),
          ]),
          Text(
            [
              '${l10n.blocks_usedTimes(b.useCount)} · ${l10n.blocks_modifiedAt(BlocksFormat.dateTime(b.updatedAt))} · ${l10n.blocks_createdAt(BlocksFormat.date(b.createdAt))}',
              if (b.sourcePath != null)
                [
                  l10n.blocks_sourceFile(b.sourcePath!),
                  ?sourceState,
                ].join(' · '),
            ].join('\n'),
            key: const Key('blocks-insp-meta'),
            style: UiText.sans(11, color: c.faint, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _Multi extends StatelessWidget {
  const _Multi();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final ids = ctrl.picked.toList();
    final blocks = [
      for (final id in ids) ?d.blocks.where((b) => b.id == id).firstOrNull,
    ];
    final total = blocks.fold<int>(0, (s, b) => s + b.itemCount);
    final from = {
      for (final b in blocks) b.folderName ?? l10n.blocks_uncategorized,
    }.join(' · ');

    Widget action(
      String key,
      Widget lead,
      String label,
      void Function(BuildContext) onTap,
    ) => Builder(
      builder: (ctx) => UiBtn(
        key: Key('blocks-multi-$key'),
        expand: true,
        onTap: () => onTap(ctx),
        children: [
          lead,
          Expanded(child: Text(label)),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          BlockBox(
            child: Wrap(
              spacing: 4,
              runSpacing: 6,
              children: [for (final b in blocks) BlockPill(b)],
            ),
          ),
          BlockKv([
            (l10n.blocks_total, l10n.blocks_totalItems(total)),
            (l10n.blocks_from, from),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 7,
            children: [
              BlockLabel(l10n.blocks_batch),
              action(
                'insert',
                const UiGlyph(UiGlyphs.plus, size: 14),
                l10n.blocks_insertInOrder,
                (_) => a.onInsert(ids),
              ),
              action(
                'merge',
                const UiGlyph(UiGlyphs.merge, size: 14),
                l10n.blocks_mergeNew,
                (_) => ctrl.openMerge(ids),
              ),
              action(
                'style',
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: blocks.first.color,
                    shape: BoxShape.circle,
                  ),
                ),
                l10n.blocks_batchStyle,
                (ctx) => ctrl.openPanel(
                  _below(ctx),
                  (_) => _BatchStyle(
                    onColor: (col) {
                      ctrl.closeMenu();
                      a.onBatchStyle(ids, color: col);
                    },
                    onLook: (look) {
                      ctrl.closeMenu();
                      a.onBatchStyle(ids, look: look);
                    },
                  ),
                ),
              ),
            ],
          ),
          BlockBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: UiGlyph(UiGlyphs.info, size: 14, color: c.muted),
                ),
                Expanded(
                  child: Text(
                    l10n.blocks_dragHint(ids.length),
                    style: UiText.sans(12, color: c.muted, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 统一改颜色 / 外观：10 色 + 6 种外观（每种画一颗示例药丸）。
class _BatchStyle extends StatelessWidget {
  const _BatchStyle({required this.onColor, required this.onLook});
  final ValueChanged<Color> onColor;
  final ValueChanged<BlockAppearance> onLook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return UiPopoverSurface(
      key: const Key('blocks-batch-style'),
      width: 300,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          BlockLabel(l10n.blocks_color),
          Padding(
            padding: const EdgeInsets.all(4),
            child: BlockColorDots(selected: null, size: 20, onChanged: onColor),
          ),
          BlockLabel(l10n.blocks_look),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final look in BlockAppearance.values)
                UiPressable(
                  key: Key('blocks-batch-look-${look.name}'),
                  onTap: () => onLook(look),
                  builder: (_, _) => UiBlockPill(
                    label: BlocksFormat.look(context, look),
                    color: blockPalette[6],
                    look: look,
                    icon: 'sparkle',
                    translationMark: l10n.blocks_translationMark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
