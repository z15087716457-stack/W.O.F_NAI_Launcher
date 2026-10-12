import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
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
import 'blocks_parts.dart';

/// 选中文字时浮在选区上方的工具条（原型 `#qtb`）：圆角 9、内边距 3、间距 2；存为块 · 复制 · 查词条。
/// 接线方挂在提示词编辑器的选择工具栏里（替换 `contextMenuBuilder` 的那一条）。
class BlockSelectionToolbar extends StatelessWidget {
  const BlockSelectionToolbar({
    super.key,
    required this.onSaveAsBlock,
    required this.onCopy,
    this.onLookup,
  });

  final VoidCallback onSaveAsBlock;
  final VoidCallback onCopy;

  /// 查词条（标签百科）；null 不显示。
  final VoidCallback? onLookup;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    Widget btn(Key key, Widget icon, String label, VoidCallback onTap) => UiBtn(
      key: key,
      size: UiBtnSize.small,
      tone: UiBtnTone.ghost,
      color: c.ink,
      onTap: onTap,
      children: [icon, Text(label)],
    );
    return UiPopoverSurface(
      key: const Key('block-selection-toolbar'),
      radius: 9,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          btn(
            const Key('block-sel-save'),
            Icon(StudioIcons.promptBlocks, size: 13, color: c.ink),
            l10n.blocks_saveAsBlock,
            onSaveAsBlock,
          ),
          btn(
            const Key('block-sel-copy'),
            const UiGlyph(UiGlyphs.copy, size: 13),
            l10n.blocks_copy,
            onCopy,
          ),
          if (onLookup != null)
            btn(
              const Key('block-sel-lookup'),
              const UiGlyph(UiGlyphs.search, size: 13),
              l10n.blocks_lookup,
              onLookup!,
            ),
        ],
      ),
    );
  }
}

/// 存为块（原型 `quick`，宽 360）：标题行 46（存为块 + 实时药丸）· 名称 · 内容（已按逗号拆好）·
/// 10 色 · 图标 / 文件夹 · “保存后把选中的文字换成这个块” · 底栏（提示 + 取消 + 保存 ⏎）。
class BlockQuickSave extends StatefulWidget {
  const BlockQuickSave({super.key, required this.data, required this.actions});

  final BlockQuickSaveData data;
  final BlockQuickSaveActions actions;

  static const width = 360.0;

  @override
  State<BlockQuickSave> createState() => _BlockQuickSaveState();
}

class _BlockQuickSaveState extends State<BlockQuickSave> {
  late var _title = widget.data.title;
  late var _color = widget.data.color;
  late var _icon = widget.data.icon;
  late var _folder = widget.data.folderId;
  late var _replace = widget.data.replaceSelection;
  UiPopoverAnchor? _pop;
  WidgetBuilder? _popBuilder;

  void _save() => widget.actions.onSave(
    BlockQuickDraft(
      title: _title.trim(),
      atoms: widget.data.atoms,
      color: _color,
      icon: _icon,
      folderId: _folder,
      replaceSelection: _replace,
    ),
  );

  void _open(BuildContext ctx, WidgetBuilder b) {
    final box = ctx.findRenderObject()! as RenderBox;
    setState(() {
      _pop = UiPopoverAnchor(
        box.localToGlobal(box.size.bottomLeft(const Offset(0, 6))),
      );
      _popBuilder = b;
    });
  }

  void _close() => setState(() => _pop = null);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final d = widget.data;
    final folder = d.folders.where((f) => f.id == _folder).firstOrNull;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape):
            widget.actions.onCancel,
        const SingleActivator(LogicalKeyboardKey.enter): _save,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _save,
      },
      child: UiPopover(
        anchor: _pop,
        onDismiss: _close,
        builder: (ctx) => _popBuilder?.call(ctx) ?? const SizedBox.shrink(),
        child: UiPopoverSurface(
          key: const Key('block-quick'),
          width: BlockQuickSave.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 46,
                padding: const EdgeInsets.only(left: 14, right: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Text(
                      l10n.blocks_saveAsBlock,
                      style: UiText.sans(
                        14,
                        weight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: UiBlockPill(
                          label: _title.trim().isEmpty
                              ? d.atoms.first
                              : _title.trim(),
                          color: _color,
                          icon: _icon,
                          translationMark: l10n.blocks_translationMark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        Text(
                          l10n.blocks_name,
                          style: UiText.sans(
                            12,
                            weight: FontWeight.w600,
                            color: c.muted,
                          ),
                        ),
                        UiTextInput(
                          key: const Key('block-quick-title'),
                          value: _title,
                          autofocus: true,
                          selectAll: true,
                          onChanged: (v) => setState(() => _title = v),
                          onSubmitted: (_) {},
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        Row(
                          spacing: 6,
                          children: [
                            Text(
                              l10n.blocks_content,
                              style: UiText.sans(
                                12,
                                weight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                            Text(
                              l10n.blocks_splitDone(d.atoms.length),
                              style: UiText.mono(11, color: c.faint),
                            ),
                          ],
                        ),
                        BlockAtoms(d.atoms, mono: true, max: 12),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: BlockColorDots(
                        key: const Key('block-quick-colors'),
                        selected: _color,
                        size: 15,
                        onChanged: (v) => setState(() => _color = v),
                      ),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        Builder(
                          builder: (ctx) => UiBtn(
                            key: const Key('block-quick-icon'),
                            size: UiBtnSize.small,
                            onTap: () => _open(
                              ctx,
                              (_) => UiPopoverSurface(
                                padding: const EdgeInsets.all(10),
                                child: BlockIconGrid(
                                  selected: _icon,
                                  color: _color,
                                  onChanged: (k) {
                                    _close();
                                    setState(() => _icon = k);
                                  },
                                ),
                              ),
                            ),
                            children: [
                              UiBlockIcon(_icon, size: 13, color: _color),
                              Text(l10n.blocks_icon),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (ctx) => UiBtn(
                            key: const Key('block-quick-folder'),
                            size: UiBtnSize.small,
                            onTap: () => _open(
                              ctx,
                              (_) => UiMenu(
                                width: 220,
                                onClose: _close,
                                items: [
                                  UiMenuItem(
                                    glyph: UiGlyphs.minus,
                                    label: l10n.blocks_uncategorized,
                                    checked: _folder == null,
                                    onTap: () => setState(() => _folder = null),
                                  ),
                                  for (final f in d.folders)
                                    UiMenuItem(
                                      glyph: UiGlyphs.folder,
                                      label: f.name,
                                      indent: f.depth * 16.0,
                                      checked: f.id == _folder,
                                      onTap: () =>
                                          setState(() => _folder = f.id),
                                    ),
                                ],
                              ),
                            ),
                            children: [
                              const UiGlyph(UiGlyphs.folder, size: 13),
                              Text(folder?.name ?? l10n.blocks_uncategorized),
                              const UiGlyph(UiGlyphs.chevronDown, size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    UiPressable(
                      key: const Key('block-quick-replace'),
                      onTap: () => setState(() => _replace = !_replace),
                      builder: (context, hover) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: hover ? c.hover : c.control,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            UiSwitch(value: _replace),
                            Expanded(
                              child: Text(
                                l10n.blocks_replaceSelection,
                                style: UiText.sans(12, color: c.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: c.panel,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.blocks_quickHint,
                        style: UiText.sans(11, color: c.faint, height: 1.4),
                      ),
                    ),
                    UiBtn(
                      key: const Key('block-quick-cancel'),
                      onTap: widget.actions.onCancel,
                      children: [Text(l10n.blocks_cancel)],
                    ),
                    UiBtn(
                      key: const Key('block-quick-save'),
                      tone: UiBtnTone.primary,
                      onTap: _save,
                      children: [Text(l10n.blocks_saveEnter)],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
