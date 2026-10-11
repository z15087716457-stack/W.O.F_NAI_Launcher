import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_inspector.dart';
import 'refs_page.dart';
import 'refs_parts.dart';

/// 弹窗外框：圆角 14 的弹层外观，按给定尺寸（窗口放不下时被宿主夹小）。
class RefsDialogFrame extends StatelessWidget {
  const RefsDialogFrame({
    super.key,
    required this.width,
    required this.height,
    required this.child,
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

Widget _close(BuildContext context, VoidCallback onClose) => UiIconBox(
  key: const Key('refs-dialog-close'),
  glyph: UiGlyphs.close,
  glyphSize: 16,
  tooltip: context.l10n.refs_close,
  onTap: onClose,
);

Widget _star(BuildContext context, RefsEntry e) {
  final c = context.ui;
  final a = RefsScope.of(context).actions;
  return UiIconBox(
    key: const Key('refs-dialog-star'),
    glyph: UiGlyphs.star,
    filled: e.favorite,
    color: e.favorite ? c.star : null,
    tooltip: e.favorite
        ? context.l10n.refs_unfavorite
        : context.l10n.refs_favorite,
    onTap: () => a.onSetFavorite([e.key], !e.favorite),
  );
}

/// 大图详情（Vibe 1260 × 860 / 精准参考 1200 × 840）：左边暗底大图，右边和检查器同一套参数。
/// ← → 切换上一个 / 下一个，Esc 关闭。
class RefsDetailDialog extends StatelessWidget {
  const RefsDetailDialog({
    super.key,
    required this.entryKey,
    required this.onClose,
    required this.onNavigate,
  });
  final String entryKey;
  final VoidCallback onClose;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final list = data.entries;
    final i = list.indexWhere((e) => e.key == entryKey);
    if (i < 0) return const SizedBox.shrink();
    final e = list[i];
    final vibe = data.kind == RefsKind.vibe;
    final prev = i > 0 ? list[i - 1].key : null;
    final next = i < list.length - 1 ? list[i + 1].key : null;
    final detail = data.detail?.key == e.key ? data.detail : null;

    Widget navBtn(
      String key,
      String label,
      String glyph,
      String? to,
      bool lead,
    ) => UiPressable(
      key: Key(key),
      onTap: to == null ? null : () => onNavigate(to),
      builder: (context, hover) {
        final fg = to == null ? Colors.white38 : Colors.white;
        return Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: hover && to != null ? .2 : .12,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (lead) UiGlyph(glyph, size: 13, color: fg),
              Text(
                label,
                style: UiText.sans(12, weight: FontWeight.w500, color: fg),
              ),
              if (!lead) UiGlyph(glyph, size: 13, color: fg),
            ],
          ),
        );
      },
    );

    final stage = Container(
      key: const Key('refs-detail-stage'),
      color: RefsPalette.stage,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Center(
              child: SizedBox(
                width: box.maxWidth * (vibe ? .96 : .94),
                height: box.maxHeight - 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: RefsImage(
                    detail?.image ?? e.thumb,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Row(
                spacing: 6,
                children: [
                  navBtn(
                    'refs-detail-prev',
                    l10n.refs_prev,
                    UiGlyphs.chevronLeft,
                    prev,
                    true,
                  ),
                  navBtn(
                    'refs-detail-next',
                    l10n.refs_next,
                    UiGlyphs.chevronRight,
                    next,
                    false,
                  ),
                  const SizedBox(width: 4),
                  const UiKeycaps(['←', '→'], style: UiKeycapStyle.tip),
                  Text(
                    l10n.refs_switch,
                    style: UiText.sans(11, color: const Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
            if (vibe)
              Positioned(
                left: 14,
                bottom: 12,
                child: Text(
                  l10n.refs_dropReplacePreview,
                  style: UiText.sans(11, color: const Color(0xFF999999)),
                ),
              ),
          ],
        ),
      ),
    );

    final panel = Container(
      width: vibe ? 400 : 380,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDialogHeader(
            children: [
              Expanded(
                child: RefsNameField(
                  key: ValueKey('dname-${e.key}'),
                  name: e.name,
                  size: 15,
                  onRename: (v) => a.onRename(e.key, v),
                ),
              ),
              if (vibe) UiMini(RefsFormat.source(context, e.source)),
              _star(context, e),
              _close(context, onClose),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: vibe
                  ? RefsVibeBody(entry: e, inDialog: true)
                  : RefsPreciseBody(entry: e, inDialog: true),
            ),
          ),
          UiDialogFooter(
            children: [
              if (vibe) ...[
                UiBtn(
                  size: UiBtnSize.small,
                  onTap: () => ctrl.openExport([e.key]),
                  children: [
                    const UiGlyph(UiGlyphs.upload, size: 13),
                    Text(l10n.refs_export),
                  ],
                ),
                UiBtn(
                  size: UiBtnSize.small,
                  onTap: () => a.onOpenFolder(e.key),
                  children: [
                    const UiGlyph(UiGlyphs.folder, size: 13),
                    Text(l10n.refs_showInFolderShort),
                  ],
                ),
              ] else
                UiBtn(
                  size: UiBtnSize.small,
                  onTap: () => a.onCopyImage(e.key),
                  children: [
                    const UiGlyph(UiGlyphs.copy, size: 13),
                    Text(l10n.refs_copyImage),
                  ],
                ),
              const Spacer(),
              UiBtn(
                key: const Key('refs-detail-delete'),
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
        ],
      ),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (_, ev) {
        if (ev is! KeyDownEvent) return KeyEventResult.ignored;
        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx?.widget is EditableText) return KeyEventResult.ignored;
        if (ev.logicalKey == LogicalKeyboardKey.arrowLeft && prev != null) {
          onNavigate(prev);
          return KeyEventResult.handled;
        }
        if (ev.logicalKey == LogicalKeyboardKey.arrowRight && next != null) {
          onNavigate(next);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: RefsDialogFrame(
        key: const Key('refs-detail'),
        width: vibe ? 1260 : 1200,
        height: vibe ? 860 : 840,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: stage),
            panel,
          ],
        ),
      ),
    );
  }
}

/// 组合包详情 1200 × 700：子 Vibe 网格，可以只发勾选的、单独调参数、设封面、拆开。
class RefsBundleDialog extends StatefulWidget {
  const RefsBundleDialog({
    super.key,
    required this.entryKey,
    required this.onClose,
  });
  final String entryKey;
  final VoidCallback onClose;

  @override
  State<RefsBundleDialog> createState() => _RefsBundleDialogState();
}

class _RefsBundleDialogState extends State<RefsBundleDialog> {
  final _checked = <int>{};
  final _values = <int, RefsSendOverride>{};
  var _onlyChecked = false;
  String? _key;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final e = data.entries.where((x) => x.key == widget.entryKey).firstOrNull;
    if (e == null) return const SizedBox.shrink();
    if (_key != e.key) {
      _key = e.key;
      _checked.clear();
      _values.clear();
      _onlyChecked = false;
    }
    final detail = data.detail?.key == e.key ? data.detail : null;
    final kids = detail?.bundle ?? const <RefsBundleChild>[];
    final k = data.costs;
    final n = kids.isEmpty ? e.bundleCount : kids.length;
    final sending = _onlyChecked ? _checked.length : n;
    final before = data.tray.items.length;
    final usable = data.model.vibeUsable;
    RefsSendOverride valueOf(int i) =>
        _values[i] ??
        RefsSendOverride(
          strength: kids[i].strength,
          infoExtracted: kids[i].infoExtracted,
        );
    void set(int i, {double? s, double? x}) {
      final v = valueOf(i);
      final next = RefsSendOverride(
        strength: s ?? v.strength,
        infoExtracted: x ?? v.infoExtracted,
      );
      setState(() {
        if (next.strength == kids[i].strength &&
            next.infoExtracted == kids[i].infoExtracted) {
          _values.remove(i);
        } else {
          _values[i] = next;
        }
      });
    }

    final toolbar = Container(
      key: const Key('refs-bundle-toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 10,
        children: [
          UiSeg<bool>(
            key: const Key('refs-bundle-scope'),
            small: false,
            values: const [false, true],
            selected: _onlyChecked,
            onChanged: (v) => setState(() => _onlyChecked = v),
            labelOf: (v) => v
                ? l10n.refs_bundleOnlyChecked(_checked.length)
                : l10n.refs_bundleAll(n),
          ),
          Expanded(
            child: Text(
              l10n.refs_bundleScopeNote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.muted),
            ),
          ),
          UiBtn(
            onTap: () => ctrl.openExport([e.key]),
            children: [
              const UiGlyph(UiGlyphs.upload, size: 14),
              Text(l10n.refs_export),
            ],
          ),
          UiBtn(
            key: const Key('refs-bundle-split'),
            onTap: () => a.onSplitBundle(e.key),
            children: [
              const UiGlyph(UiGlyphs.stack, size: 14),
              Text(l10n.refs_splitBundle),
            ],
          ),
          UiBtn(
            key: const Key('refs-bundle-add'),
            tone: UiBtnTone.primary,
            onTap: !usable || sending == 0
                ? null
                : () => a.onAddBundle(
                    e.key,
                    indexes: _onlyChecked ? (_checked.toList()..sort()) : null,
                    overrides: Map.of(_values),
                  ),
            children: [
              const UiGlyph(UiGlyphs.plus, size: 14, strokeWidth: 2.4),
              Text(l10n.refs_addToGeneration),
              Opacity(
                opacity: .75,
                child: Text(
                  '$before→${before + sending}/${k.maxVibes}',
                  style: UiText.mono(12, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final grid = LayoutBuilder(
      builder: (context, box) {
        const cols = 5;
        final cw = (box.maxWidth - 36 - 16 * (cols - 1)) / cols;
        return Wrap(
          key: const Key('refs-bundle-grid'),
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < kids.length; i++)
              SizedBox(
                width: cw,
                child: _BundleChild(
                  child: kids[i],
                  index: i,
                  cover: (detail?.coverIndex ?? 0) == i,
                  checked: _checked.contains(i),
                  value: valueOf(i),
                  changed: _values.containsKey(i),
                  onCheck: () => setState(() {
                    if (!_checked.remove(i)) _checked.add(i);
                  }),
                  onCover: () => a.onSetBundleCover(e.key, i),
                  onStrength: (v) => set(i, s: v),
                  onInfo: (v) => set(i, x: v),
                ),
              ),
          ],
        );
      },
    );

    return RefsDialogFrame(
      key: const Key('refs-bundle'),
      width: 1200,
      height: 700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDialogHeader(
            children: [
              UiGlyph(UiGlyphs.stack, size: 17, color: c.muted),
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    UiMini(l10n.refs_bundleOfVibes(n)),
                  ],
                ),
              ),
              _star(context, e),
              _close(context, widget.onClose),
            ],
          ),
          toolbar,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  grid,
                  Container(
                    key: const Key('refs-bundle-note'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        UiGlyph(UiGlyphs.infoCircle, size: 14, color: c.muted),
                        Expanded(
                          child: Text(
                            l10n.refs_bundleNoteLong +
                                (detail?.bundleEncodedFor == null
                                    ? ''
                                    : l10n.refs_bundleAllEncoded(
                                        n,
                                        detail!.bundleEncodedFor!,
                                      )),
                            style: UiText.sans(12, color: c.ink, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          ),
          UiDialogFooter(
            children: [
              Text(l10n.refs_file, style: UiText.sans(12, color: c.muted)),
              Expanded(
                child: Text(
                  e.fileName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.mono(11, color: c.muted),
                ),
              ),
              UiBtn(
                key: const Key('refs-bundle-revert'),
                tone: UiBtnTone.ghost,
                onTap: _values.isEmpty ? null : () => setState(_values.clear),
                children: [Text(l10n.refs_revert)],
              ),
              UiBtn(
                key: const Key('refs-bundle-save'),
                tone: _values.isEmpty ? UiBtnTone.normal : UiBtnTone.primary,
                onTap: _values.isEmpty
                    ? null
                    : () {
                        a.onSaveBundle(e.key, Map.of(_values));
                        setState(_values.clear);
                      },
                children: [Text(l10n.refs_saveToBundle)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BundleChild extends StatefulWidget {
  const _BundleChild({
    required this.child,
    required this.index,
    required this.cover,
    required this.checked,
    required this.value,
    required this.changed,
    required this.onCheck,
    required this.onCover,
    required this.onStrength,
    required this.onInfo,
  });
  final RefsBundleChild child;
  final int index;
  final bool cover;
  final bool checked;
  final RefsSendOverride value;
  final bool changed;
  final VoidCallback onCheck;
  final VoidCallback onCover;
  final ValueChanged<double> onStrength;
  final ValueChanged<double> onInfo;

  @override
  State<_BundleChild> createState() => _BundleChildState();
}

class _BundleChildState extends State<_BundleChild> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final w = widget;
    Widget row(String label, double v, double base, ValueChanged<double> on) =>
        Row(
          spacing: 8,
          children: [
            SizedBox(
              width: 24,
              child: Text(label, style: UiText.sans(11, color: c.muted)),
            ),
            Expanded(
              child: UiSlider(
                compact: true,
                value: v,
                defaultValue: v != base ? base : null,
                onChanged: on,
              ),
            ),
            UiNumBox(
              compact: true,
              value: v,
              changed: v != base,
              onSubmitted: on,
            ),
          ],
        );
    return Column(
      key: Key('refs-bundle-child-${w.index}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: w.onCheck,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: w.checked
                      ? [
                          BoxShadow(
                            color: c.accent.withValues(alpha: .16),
                            spreadRadius: 5,
                          ),
                          BoxShadow(color: c.accent, spreadRadius: 2),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: c.control),
                      RefsImage(w.child.thumb),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c.ink.withValues(alpha: .07),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 7,
                        top: 7,
                        child: RefsPickMark(on: w.checked),
                      ),
                      if (w.cover)
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: RefsDarkBadge(
                            glyph: UiGlyphs.cover,
                            text: l10n.refs_cover,
                            color: c.accent,
                          ),
                        )
                      else if (_hover)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: RefsDarkBar(
                            children: [
                              RefsBarButton(
                                key: const Key('refs-bundle-cover'),
                                glyph: UiGlyphs.cover,
                                label: l10n.refs_setCover,
                                onTap: w.onCover,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
          child: Text(
            w.child.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(
              13,
              weight: FontWeight.w600,
              color: c.ink,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 6),
        row(
          l10n.refs_strengthShort,
          w.value.strength,
          w.child.strength,
          w.onStrength,
        ),
        const SizedBox(height: 6),
        row(
          l10n.refs_infoShort,
          w.value.infoExtracted,
          w.child.infoExtracted,
          w.onInfo,
        ),
      ],
    );
  }
}

/// 导出 940 × 740：左边要导出的条目（可移掉），右边四种格式、选项和保存位置。
class RefsExportDialog extends StatefulWidget {
  const RefsExportDialog({
    super.key,
    required this.keys,
    required this.onClose,
  });
  final List<String> keys;
  final VoidCallback onClose;

  @override
  State<RefsExportDialog> createState() => _RefsExportDialogState();
}

class _RefsExportDialogState extends State<RefsExportDialog> {
  late final _keys = [...widget.keys];
  RefsExportFormat _format = RefsExportFormat.vibeFile;
  var _thumbs = true;
  var _zip = false;
  String? _folder;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final entries = [
      for (final k in _keys) ?data.entries.where((e) => e.key == k).firstOrNull,
    ];
    final n = entries.length;
    final folder = _folder ?? data.exportFolder;
    final format = _format == RefsExportFormat.png && n != 1
        ? RefsExportFormat.vibeFile
        : _format;

    Widget label(String t) => Text(
      t,
      style: UiText.sans(11.5, weight: FontWeight.w600, color: c.muted),
    );

    Widget fmt(RefsExportFormat f, String glyph, String title, String desc) {
      final disabled = f == RefsExportFormat.png && n != 1;
      final on = format == f;
      return Opacity(
        opacity: disabled ? .45 : 1,
        child: UiPressable(
          key: Key('refs-export-${f.name}'),
          onTap: disabled ? null : () => setState(() => _format = f),
          builder: (context, hover) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: on
                  ? Color.alphaBlend(c.accent.withValues(alpha: .03), c.raised)
                  : c.raised,
              border: Border.all(
                color: on ? c.accent : (hover && !disabled ? c.strong : c.line),
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: .13),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.accent.withValues(alpha: .12) : c.control,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: UiGlyph(
                    glyph,
                    size: 16,
                    color: on ? c.accent : c.muted,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        title,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        desc,
                        style: UiText.sans(11.5, color: c.muted, height: 1.45),
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

    Widget option(
      String key,
      String title,
      String desc,
      bool v,
      ValueChanged<bool> on,
    ) => Row(
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: UiText.sans(13, color: c.ink)),
              Text(desc, style: UiText.sans(11, color: c.muted)),
            ],
          ),
        ),
        UiPressable(
          key: Key(key),
          onTap: () => on(!v),
          builder: (_, _) => UiSwitch(value: v, width: 30, height: 18),
        ),
      ],
    );

    final ext = switch (format) {
      RefsExportFormat.vibeFile => '.naiv4vibe',
      RefsExportFormat.bundle => '.naiv4vibebundle',
      RefsExportFormat.png => '.png',
      RefsExportFormat.encoded => '.json',
    };
    final files = format == RefsExportFormat.bundle ? 1 : n;

    return RefsDialogFrame(
      key: const Key('refs-export'),
      width: 940,
      height: 740,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDialogHeader(
            children: [
              Text(l10n.refs_exportTitle(n)),
              const Spacer(),
              _close(context, widget.onClose),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  key: const Key('refs-export-list'),
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border(right: BorderSide(color: c.line)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        for (final e in entries)
                          Container(
                            key: Key('refs-export-row-${e.key}'),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: c.raised,
                              border: Border.all(color: c.line),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              spacing: 10,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: SizedBox(
                                    width: 36,
                                    height: 44,
                                    child: RefsImage(e.thumb),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: UiText.sans(
                                          12,
                                          weight: FontWeight.w600,
                                          color: c.ink,
                                        ),
                                      ),
                                      Text(
                                        e.isBundle
                                            ? l10n.refs_bundleOf(e.bundleCount)
                                            : '${RefsFormat.two(e.strength)} · ${RefsFormat.two(e.infoExtracted)}',
                                        style: UiText.mono(11, color: c.faint),
                                      ),
                                    ],
                                  ),
                                ),
                                UiIconBox(
                                  glyph: UiGlyphs.close,
                                  glyphSize: 13,
                                  size: 28,
                                  tooltip: l10n.refs_remove,
                                  onTap: () =>
                                      setState(() => _keys.remove(e.key)),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            l10n.refs_exportListNote,
                            style: UiText.sans(11, color: c.faint, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label(l10n.refs_exportAs),
                        const SizedBox(height: 10),
                        Column(
                          key: const Key('refs-export-formats'),
                          spacing: 10,
                          children: [
                            for (final row in [
                              [
                                fmt(
                                  RefsExportFormat.vibeFile,
                                  UiGlyphs.file,
                                  l10n.refs_fmtVibeFile,
                                  l10n.refs_fmtVibeFileDesc,
                                ),
                                fmt(
                                  RefsExportFormat.bundle,
                                  UiGlyphs.stack,
                                  l10n.refs_fmtBundle,
                                  l10n.refs_fmtBundleDesc(n),
                                ),
                              ],
                              [
                                fmt(
                                  RefsExportFormat.png,
                                  UiGlyphs.picture,
                                  l10n.refs_fmtPng,
                                  l10n.refs_fmtPngDesc,
                                ),
                                fmt(
                                  RefsExportFormat.encoded,
                                  UiGlyphs.code,
                                  l10n.refs_fmtEncoded,
                                  l10n.refs_fmtEncodedDesc,
                                ),
                              ],
                            ])
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 10,
                                  children: [
                                    for (final w in row) Expanded(child: w),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        label(l10n.refs_options),
                        const SizedBox(height: 10),
                        Container(
                          key: const Key('refs-export-options'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.raised,
                            border: Border.all(color: c.line),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            spacing: 10,
                            children: [
                              option(
                                'refs-export-thumbs',
                                l10n.refs_optThumbs,
                                l10n.refs_optThumbsDesc,
                                _thumbs,
                                (v) => setState(() => _thumbs = v),
                              ),
                              Container(height: 1, color: c.line),
                              option(
                                'refs-export-zip',
                                l10n.refs_optZip,
                                l10n.refs_optZipDesc(files),
                                _zip,
                                (v) => setState(() => _zip = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        label(l10n.refs_saveTo),
                        const SizedBox(height: 10),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: Container(
                                key: const Key('refs-export-folder'),
                                height: 30,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: c.bg,
                                  border: Border.all(color: c.strong),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  folder,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.mono(12, color: c.ink),
                                ),
                              ),
                            ),
                            UiBtn(
                              key: const Key('refs-export-pick'),
                              onTap: () async {
                                final p = await a.onPickExportFolder();
                                if (p != null && mounted) {
                                  setState(() => _folder = p);
                                }
                              },
                              children: [
                                const UiGlyph(UiGlyphs.folder, size: 14),
                                Text(l10n.refs_choose),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          UiDialogFooter(
            children: [
              Expanded(
                child: Text(
                  _zip
                      ? l10n.refs_exportSummaryZip(files, ext)
                      : l10n.refs_exportSummary(files, ext),
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
              UiBtn(onTap: widget.onClose, children: [Text(l10n.refs_cancel)]),
              UiBtn(
                key: const Key('refs-export-confirm'),
                tone: UiBtnTone.primary,
                onTap: n == 0
                    ? null
                    : () {
                        widget.onClose();
                        a.onExport(
                          RefsExportPlan(
                            keys: [for (final e in entries) e.key],
                            format: format,
                            folder: folder,
                            thumbnails: _thumbs,
                            zip: _zip,
                          ),
                        );
                      },
                children: [
                  const UiGlyph(UiGlyphs.upload, size: 14),
                  Text(l10n.refs_export),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 删除确认：说清删几个、会不会删文件。
class RefsDeleteDialog extends StatelessWidget {
  const RefsDeleteDialog({
    super.key,
    required this.keys,
    required this.onClose,
    required this.onConfirm,
  });
  final List<String> keys;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final data = RefsScope.of(context).data;
    final vibe = data.kind == RefsKind.vibe;
    final names = [
      for (final k in keys)
        ?data.entries.where((e) => e.key == k).firstOrNull?.name,
    ];
    return RefsDialogFrame(
      key: const Key('refs-delete'),
      width: 420,
      height: null,
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
                        names.length == 1
                            ? l10n.refs_deleteOne(names.first)
                            : l10n.refs_deleteMany(names.length),
                        style: UiText.sans(
                          15,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        vibe
                            ? l10n.refs_deleteVibeDesc
                            : l10n.refs_deletePreciseDesc,
                        style: UiText.sans(12.5, color: c.muted, height: 1.55),
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
              UiBtn(onTap: onClose, children: [Text(l10n.refs_cancel)]),
              UiBtn(
                key: const Key('refs-delete-confirm'),
                tone: UiBtnTone.primary,
                color: c.error,
                onTap: onConfirm,
                children: [Text(l10n.refs_delete)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
