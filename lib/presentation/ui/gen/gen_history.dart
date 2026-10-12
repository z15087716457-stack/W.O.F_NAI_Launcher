import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 历史栏（原型 `rightA`）：标题行 40 │ 批次列表（时间 · 张数 + 封面）│ 底栏 40。
/// 单击一批 = 画布切到这批；300ms 内再点 = 开大图；右键菜单；多选（按钮 / Ctrl / Shift）出操作条。
/// 窗口按钮压在这一栏顶上，所以有窗口按钮时整栏下移 36。
class GenHistoryPanel extends StatefulWidget {
  const GenHistoryPanel({super.key, required this.width});
  final double width;

  @override
  State<GenHistoryPanel> createState() => _GenHistoryPanelState();
}

class _GenHistoryPanelState extends State<GenHistoryPanel> {
  final _scroll = ScrollController();
  var _selecting = false;
  final _selected = <String>{};
  String? _anchor;
  var _locked = false;
  String? _first;
  String? _lastTap;
  DateTime? _lastTapAt;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final batches = GenScope.of(context).data.history.batches;
    final first = batches.firstOrNull?.id;
    if (_first != null && first != _first && !_locked && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
      });
    }
    _first = first;
    _selected.removeWhere((id) => !batches.any((b) => b.id == id));
  }

  List<String> _ids(GenHistoryData h, Iterable<String> batchIds) => [
    for (final b in h.batches)
      if (batchIds.contains(b.id)) ...b.images.map((i) => i.id),
  ];

  void _tap(GenScope scope, GenBatch b) {
    final keys = HardwareKeyboard.instance;
    final h = scope.data.history;
    if (keys.isShiftPressed && _anchor != null) {
      final ids = h.batches.map((x) => x.id).toList();
      final a = ids.indexOf(_anchor!);
      final z = ids.indexOf(b.id);
      if (a >= 0 && z >= 0) {
        setState(() {
          _selecting = true;
          _selected.addAll(ids.sublist(a < z ? a : z, (a < z ? z : a) + 1));
        });
        return;
      }
    }
    if (_selecting || keys.isControlPressed || keys.isMetaPressed) {
      setState(() {
        _selecting = true;
        _selected.contains(b.id) ? _selected.remove(b.id) : _selected.add(b.id);
        _anchor = b.id;
      });
      return;
    }
    _anchor = b.id;
    final now = DateTime.now();
    final again =
        _lastTap == b.id &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) < const Duration(milliseconds: 300);
    _lastTap = b.id;
    _lastTapAt = now;
    if (again && b.images.isNotEmpty) {
      _lastTap = null;
      scope.actions.onOpenViewer(b.images.first.id);
    } else {
      scope.actions.onFocusBatch(b.id);
    }
  }

  void _setSelecting(bool v) => setState(() {
    _selecting = v;
    if (!v) _selected.clear();
  });

  void _confirmDelete(GenScope scope, List<String> ids, {bool all = false}) {
    final l = context.l10n;
    scope.controller.openDialog(
      (_) => GenConfirmDialog(
        title: all ? l.gen_clearHistoryTitle : l.gen_deleteImagesTitle,
        body: all ? l.gen_clearHistoryBody : l.gen_deleteImagesBody(ids.length),
        confirm: all ? l.gen_clearConfirm : l.gen_removeConfirm,
        cancel: l.gen_cancel,
        onCancel: scope.controller.closeDialog,
        onConfirm: () {
          scope.controller.closeDialog();
          all
              ? scope.actions.onClearHistory()
              : scope.actions.onDeleteImages(ids);
          _setSelecting(false);
        },
      ),
    );
  }

  void _menu(GenScope scope, GenBatch b, Offset at) {
    final l = context.l10n;
    final a = scope.actions;
    final cover = b.images.firstOrNull;
    if (cover == null) return;
    final n = b.images.length;
    scope.controller.openMenu(
      UiPopoverAnchor(at),
      [
        UiMenuItem(
          key: const Key('gen-history-open'),
          label: l.gen_openViewer,
          glyph: UiGlyphs.expand,
          onTap: () => a.onOpenViewer(cover.id),
        ),
        UiMenuItem(
          label: n > 1 ? l.gen_saveBatch(n) : l.gen_saveImage,
          glyph: GenGlyphs.save2,
          divider: true,
          onTap: () => a.onSaveImages(b.images.map((i) => i.id).toList()),
        ),
        UiMenuItem(
          label: l.gen_copyImage,
          glyph: UiGlyphs.copy,
          onTap: () => a.onCopyImage(cover.id),
        ),
        UiMenuItem(
          label: cover.favorite ? l.gen_unfavorite : l.gen_favorite,
          glyph: UiGlyphs.heart,
          onTap: () => a.onFavorite(cover.id, !cover.favorite),
        ),
        UiMenuItem(
          key: const Key('gen-history-send-img2img'),
          label: l.gen_sendImg2Img,
          glyph: UiGlyphs.image,
          divider: true,
          onTap: () => a.onSendTo(cover.id, GenSendTarget.img2img),
        ),
        UiMenuItem(
          label: l.gen_sendVibe,
          glyph: UiGlyphs.palette,
          enabled: scope.data.refs.vibes != null,
          onTap: () => a.onSendTo(cover.id, GenSendTarget.vibe),
        ),
        UiMenuItem(
          label: l.gen_sendPrecise,
          glyph: UiGlyphs.personStar,
          enabled: scope.data.refs.precise != null,
          onTap: () => a.onSendTo(cover.id, GenSendTarget.precise),
        ),
        UiMenuItem(
          label: l.gen_reveal,
          glyph: GenGlyphs.reveal,
          divider: true,
          onTap: () => a.onReveal(cover.id),
        ),
        UiMenuItem(
          key: const Key('gen-history-delete'),
          label: n > 1 ? l.gen_removeBatch(n) : l.gen_removeImage,
          glyph: UiGlyphs.trash,
          danger: true,
          onTap: () =>
              _confirmDelete(scope, b.images.map((i) => i.id).toList()),
        ),
      ],
      tag: ('history', b.id),
      width: 220,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final h = scope.data.history;
    final l = context.l10n;
    final chrome = WindowChromeScope.activeOf(context);
    final selectedIds = _ids(h, _selected);
    return Container(
      key: const Key('gen-history'),
      width: widget.width,
      padding: EdgeInsets.only(
        top: chrome ? WindowChromeScope.heightOf(context) : 0,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(left: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('gen-history-header'),
            height: 40,
            padding: const EdgeInsets.only(left: 8, right: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              spacing: 8,
              children: [
                Tooltip(
                  message: l.gen_collapse,
                  child: UiPressable(
                    key: const Key('gen-collapse-history'),
                    onTap: () => scope.actions.onLayoutChanged(
                      scope.data.layout.copyWith(historyOpen: false),
                    ),
                    builder: (context, hover) => Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hover ? c.hover : c.control,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: UiGlyph(
                        UiGlyphs.chevronRight,
                        size: 13,
                        color: hover ? c.ink : c.muted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          l.gen_history,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            14,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ),
                      if (h.total > 0) GenCount('${h.total}'),
                    ],
                  ),
                ),
                if (h.pinned > 0)
                  Tooltip(
                    message: l.gen_pinnedTip,
                    child: UiPressable(
                      key: const Key('gen-history-pins'),
                      onTap: scope.actions.onFocusPins,
                      builder: (context, hover) => Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: hover ? .16 : .10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            GenNaiIcon('pin-filled', size: 11, color: c.accent),
                            Text(
                              '${h.pinned}',
                              style: UiText.mono(
                                11,
                                weight: FontWeight.w600,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                GenIb(
                  key: const Key('gen-history-select'),
                  glyph: GenGlyphs.multi,
                  glyphSize: 16,
                  active: _selecting,
                  color: _selecting ? c.accent : null,
                  tooltip: _selecting ? l.gen_selectDone : l.gen_select,
                  onTap: h.batches.isEmpty
                      ? null
                      : () => _setSelecting(!_selecting),
                ),
              ],
            ),
          ),
          Expanded(
            child: h.batches.isEmpty
                ? const _Empty()
                : ListView.builder(
                    key: const Key('gen-history-list'),
                    controller: _scroll,
                    padding: const EdgeInsets.all(8),
                    itemCount: h.batches.length,
                    itemBuilder: (context, i) {
                      final b = h.batches[i];
                      return Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                        child: _BatchItem(
                          batch: b,
                          width: widget.width - 16,
                          now: scope.data.now ?? DateTime.now(),
                          focused: h.selected == b.id,
                          selecting: _selecting,
                          checked: _selected.contains(b.id),
                          onTap: () => _tap(scope, b),
                          onMenu: (at) => _menu(scope, b, at),
                        ),
                      );
                    },
                  ),
          ),
          if (_selecting)
            Container(
              key: const Key('gen-history-selection'),
              height: 40,
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .06),
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 2,
                children: [
                  Expanded(
                    child: Text(
                      l.gen_selectedCount(selectedIds.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12,
                        weight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ),
                  GenIb(
                    key: const Key('gen-history-pack'),
                    glyph: GenGlyphs.zip,
                    tooltip: l.gen_pack,
                    onTap: selectedIds.isEmpty
                        ? null
                        : () => scope.actions.onPackImages(selectedIds),
                  ),
                  GenIb(
                    key: const Key('gen-history-save-selected'),
                    glyph: UiGlyphs.download,
                    tooltip: l.gen_saveSelected,
                    onTap: selectedIds.isEmpty
                        ? null
                        : () => scope.actions.onSaveImages(selectedIds),
                  ),
                  GenIb(
                    key: const Key('gen-history-delete-selected'),
                    glyph: UiGlyphs.trash,
                    color: c.error,
                    tooltip: l.gen_removeSelected,
                    onTap: selectedIds.isEmpty
                        ? null
                        : () => _confirmDelete(scope, selectedIds),
                  ),
                ],
              ),
            ),
          Container(
            key: const Key('gen-history-footer'),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.line.withValues(alpha: .6)),
              ),
            ),
            child: Row(
              spacing: 2,
              children: [
                GenIb(
                  key: const Key('gen-autosave'),
                  glyph: GenGlyphs.autosave,
                  glyphSize: 16,
                  color: h.autoSave ? c.accent : null,
                  tooltip: h.autoSave ? l.gen_autoSaveOn : l.gen_autoSaveOff,
                  onTap: () => scope.actions.onAutoSaveChanged(!h.autoSave),
                ),
                const Spacer(),
                GenIb(
                  key: const Key('gen-history-lock'),
                  glyph: _locked ? UiGlyphs.lock : UiGlyphs.unlock,
                  glyphSize: 16,
                  color: _locked ? c.accent : null,
                  tooltip: _locked ? l.gen_scrollUnlock : l.gen_scrollLock,
                  onTap: () => setState(() => _locked = !_locked),
                ),
                GenIb(
                  key: const Key('gen-history-save-all'),
                  glyph: UiGlyphs.download,
                  glyphSize: 16,
                  tooltip: l.gen_saveAll,
                  onTap: h.total == 0
                      ? null
                      : () => scope.actions.onSaveImages(
                          _ids(h, h.batches.map((b) => b.id)),
                        ),
                ),
                GenIb(
                  key: const Key('gen-history-clear'),
                  glyph: UiGlyphs.trash,
                  glyphSize: 16,
                  color: c.error,
                  tooltip: l.gen_clearHistory,
                  onTap: h.batches.isEmpty
                      ? null
                      : () => _confirmDelete(scope, const [], all: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 一批（原型 `.batch` + `.ta`）：时间（Geist Mono 75%）· N 张；封面高 190（随栏宽缩放），
/// 当前批 2px 强调色外圈、外扩 2；左上角操作角标，右下角 ×N。
class _BatchItem extends StatelessWidget {
  const _BatchItem({
    required this.batch,
    required this.width,
    required this.now,
    required this.focused,
    required this.selecting,
    required this.checked,
    required this.onTap,
    required this.onMenu,
  });

  final GenBatch batch;
  final double width;
  final DateTime now;
  final bool focused;
  final bool selecting;
  final bool checked;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final l = context.l10n;
    final b = batch;
    final cover = b.images.firstOrNull;
    final maxH = (width * .98).clamp(150.0, 330.0);
    final ratio = cover == null ? 832 / 1216 : cover.width / cover.height;
    final h = (width / ratio).clamp(0.0, maxH);
    final w = h * ratio;
    final day = GenFormat.day(context, b.time, now);
    Widget image = cover == null
        ? Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: GenFormat.softBg(c),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  const UiSpinner(size: 16),
                  Text(
                    l.gen_generating,
                    style: UiText.sans(11.5, color: c.muted),
                  ),
                ],
              ),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image(
              image: cover.thumb,
              width: w,
              height: h,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
    if (cover != null && scope.slots.historyDrag != null) {
      image = scope.slots.historyDrag!(context, cover.id, image);
    }
    return Column(
      key: Key('gen-batch-${b.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
          child: Row(
            spacing: 6,
            children: [
              Text(
                day == null
                    ? GenFormat.clock(b.time)
                    : '$day ${GenFormat.clock(b.time)}',
                style: UiText.mono(11, color: c.ink.withValues(alpha: .75)),
              ),
              if (b.count > 1)
                Text(
                  '· ${l.gen_batchCount(b.count)}',
                  style: UiText.sans(11, color: c.muted),
                ),
              if (b.pending > 0 && b.images.isNotEmpty)
                Flexible(
                  child: Text(
                    '· ${l.gen_batchPending(b.pending)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(11, color: c.accent),
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onSecondaryTapDown: (d) => onMenu(d.globalPosition),
          child: UiPressable(
            key: Key('gen-batch-tile-${b.id}'),
            onTap: onTap,
            builder: (context, hover) => SizedBox(
              height: h,
              child: Center(
                child: Container(
                  key: focused ? const Key('gen-batch-focused') : null,
                  foregroundDecoration: focused || checked
                      ? BoxDecoration(
                          border: Border.all(
                            color: c.accent,
                            width: 2,
                            strokeAlign: 3,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        )
                      : null,
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: hover && !focused ? .88 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: image,
                      ),
                      if (cover?.op case final op?)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Tooltip(
                            message: GenFormat.opLabel(context, op),
                            child: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.raised.withValues(alpha: .92),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: GenNaiIcon(
                                switch (op) {
                                  GenOp.upscale => 'upscale',
                                  GenOp.enhance => 'enhance',
                                  GenOp.variation => 'variations',
                                  GenOp.inpaint => 'inpaint',
                                  GenOp.img2img => 'img2img',
                                },
                                size: 13,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ),
                      if (cover?.favorite ?? false)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: UiGlyph(
                            UiGlyphs.heart,
                            size: 14,
                            filled: true,
                            color: c.fav,
                          ),
                        ),
                      if (b.count > 1)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '×${b.count}',
                              style: UiText.sans(
                                11,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      if (selecting)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: checked
                                  ? c.accent
                                  : Colors.black.withValues(alpha: .35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: checked
                                ? const Center(
                                    child: UiGlyph(
                                      UiGlyphs.check,
                                      size: 11,
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Center(
      key: const Key('gen-history-empty'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            UiGlyph(GenGlyphs.history, size: 22, color: c.faint),
            Text(
              l.gen_historyEmpty,
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, weight: FontWeight.w600, color: c.muted),
            ),
            Text(
              l.gen_historyEmptySub,
              textAlign: TextAlign.center,
              style: UiText.sans(11.5, color: c.faint, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
