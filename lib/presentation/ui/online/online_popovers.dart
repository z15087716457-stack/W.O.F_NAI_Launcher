import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_page.dart';
import 'online_parts.dart';

/// 菜单项（右键菜单、⋯ 菜单、下拉选项）。
@immutable
class OnlineMenuItem {
  const OnlineMenuItem({
    required this.label,
    required this.onTap,
    this.glyph,
    this.danger = false,
    this.divider = false,
    this.checked = false,
    this.trailing,
    this.enabled = true,
  });
  final String label;
  final String? glyph;
  final VoidCallback onTap;
  final bool danger;

  /// 这一项上方画分隔线。
  final bool divider;

  /// 当前选中项（右侧打勾）。
  final bool checked;
  final String? trailing;
  final bool enabled;
}

/// 菜单：抬起底浮层，行高 34、13 号字。点一项先关菜单再执行。
class OnlineMenu extends StatelessWidget {
  const OnlineMenu({
    super.key,
    required this.items,
    required this.onClose,
    this.width = 210,
  });
  final List<OnlineMenuItem> items;
  final VoidCallback onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      key: const Key('online-menu'),
      width: width,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final it in items) ...[
            if (it.divider)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: c.line,
              ),
            UiPressable(
              onTap: it.enabled
                  ? () {
                      onClose();
                      it.onTap();
                    }
                  : null,
              builder: (context, hover) {
                final fg = !it.enabled
                    ? c.faint
                    : it.danger
                    ? c.error
                    : c.ink;
                return Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: hover ? c.control : null,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      if (it.glyph != null)
                        UiGlyph(
                          it.glyph!,
                          size: 15,
                          color: it.danger ? c.error : c.muted,
                        ),
                      Expanded(
                        child: Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            13,
                            color: fg,
                            weight: it.checked
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (it.trailing != null)
                        Text(
                          it.trailing!,
                          style: UiText.mono(11, color: c.faint),
                        ),
                      if (it.checked)
                        UiGlyph(
                          UiGlyphs.check,
                          size: 14,
                          strokeWidth: 2.4,
                          color: c.accent,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// “发送到生图”浮层：380 宽，三种方式 + 记住选择 + 写清会覆盖什么。
class OnlineSendPopover extends StatefulWidget {
  const OnlineSendPopover({
    super.key,
    required this.workKey,
    required this.onClose,
  });
  final String workKey;
  final VoidCallback onClose;

  @override
  State<OnlineSendPopover> createState() => _OnlineSendPopoverState();
}

class _OnlineSendPopoverState extends State<OnlineSendPopover> {
  OnlineSendMode? _mode;
  var _remember = true;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final send = data.send;
    final detail = data.detail?.key == widget.workKey ? data.detail : null;
    final params = detail?.canSendParams ?? false;
    final mode =
        _mode ??
        (send.remembered == OnlineSendMode.withParams && !params
            ? OnlineSendMode.replace
            : send.remembered ?? OnlineSendMode.replace);

    Widget option(OnlineSendMode m, String title, String desc) {
      final enabled = m != OnlineSendMode.withParams || params;
      final on = mode == m && enabled;
      return Opacity(
        opacity: enabled ? 1 : .5,
        child: UiPressable(
          key: Key('online-send-${m.name}'),
          onTap: enabled ? () => setState(() => _mode = m) : null,
          builder: (context, hover) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on
                  ? Color.alphaBlend(c.accent.withValues(alpha: .03), c.raised)
                  : (hover ? c.hover : null),
              border: Border.all(color: on ? c.accent : c.line),
              borderRadius: BorderRadius.circular(9),
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
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: UiRadio(value: on),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled ? desc : l10n.online_sendParamsUnavailable,
                        style: UiText.sans(11.5, color: c.muted, height: 1.5),
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

    void go() {
      widget.onClose();
      scope.actions.onSend(widget.workKey, mode, remember: _remember);
    }

    return UiPopoverSurface(
      key: const Key('online-send-popover'),
      width: 380,
      child: Focus(
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.enter) {
            go();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnlinePopHeader(
              children: [
                Text(l10n.online_send),
                const Spacer(),
                UiPressable(
                  key: const Key('online-send-remember'),
                  onTap: () => setState(() => _remember = !_remember),
                  builder: (context, _) => Row(
                    spacing: 8,
                    children: [
                      Text(
                        l10n.online_sendRemember,
                        style: UiText.sans(12, color: c.muted),
                      ),
                      UiCheckBox(value: _remember),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  option(
                    OnlineSendMode.replace,
                    l10n.online_sendReplace,
                    send.characterCount > 0
                        ? l10n.online_sendReplaceDesc(send.characterCount)
                        : l10n.online_sendReplaceDescNone,
                  ),
                  option(
                    OnlineSendMode.promptOnly,
                    l10n.online_sendPromptOnly,
                    l10n.online_sendPromptOnlyDesc,
                  ),
                  option(
                    OnlineSendMode.withParams,
                    l10n.online_sendParams,
                    l10n.online_sendParamsDesc,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 2, right: 2),
                    child: OnlineNote(
                      send.promptLength > 0
                          ? l10n.online_sendNote(send.promptLength)
                          : l10n.online_sendNoteEmpty,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              decoration: BoxDecoration(
                color: c.panel,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 8,
                children: [
                  const Spacer(),
                  UiBtn(
                    onTap: widget.onClose,
                    children: [Text(l10n.online_cancel)],
                  ),
                  UiBtn(
                    key: const Key('online-send-go'),
                    tone: UiBtnTone.primary,
                    onTap: go,
                    children: [
                      const UiGlyph(UiGlyphs.send, size: 14),
                      Text(l10n.online_sendGo),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 多选“收藏到”：250 宽，选子集或新建子集并收藏。
class OnlineFavoriteToPopover extends StatefulWidget {
  const OnlineFavoriteToPopover({
    super.key,
    required this.keys,
    required this.onClose,
  });
  final List<String> keys;
  final VoidCallback onClose;

  @override
  State<OnlineFavoriteToPopover> createState() =>
      _OnlineFavoriteToPopoverState();
}

class _OnlineFavoriteToPopoverState extends State<OnlineFavoriteToPopover> {
  var _creating = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final fav = scope.data.favorites ?? const OnlineFavorites();

    void pick(String? id, {String? name}) {
      widget.onClose();
      scope.controller.setPicking(false);
      scope.actions.onFavoriteMany(widget.keys, id, newCollection: name);
    }

    Widget row(String? id, String name, int count, {bool on = false}) =>
        UiPressable(
          key: Key('online-favto-${id ?? 'none'}'),
          onTap: () => pick(id),
          builder: (context, hover) => Container(
            height: 40,
            color: on || hover ? c.control : null,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 10,
              children: [
                UiGlyph(UiGlyphs.folder, size: 15, color: c.ink),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(13, color: c.ink),
                  ),
                ),
                Text('$count', style: UiText.mono(11, color: c.faint)),
              ],
            ),
          ),
        );

    return UiPopoverSurface(
      key: const Key('online-favto-popover'),
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnlinePopHeader(children: [Text(l10n.online_favoriteToTitle)]),
          row(
            OnlineFavorites.ungroupedId,
            l10n.online_ungrouped,
            fav.ungrouped,
            on: true,
          ),
          for (final col in fav.collections) row(col.id, col.name, col.count),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: _creating
                ? Row(
                    spacing: 10,
                    children: [
                      UiGlyph(UiGlyphs.folder, size: 15, color: c.accent),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: UiText.sans(13, color: c.ink),
                          cursorColor: c.accent,
                          cursorHeight: 15,
                          decoration: uiBareDecoration(
                            hintText: l10n.online_collectionNameHint,
                            hintStyle: UiText.sans(13, color: c.faint),
                          ),
                          onSubmitted: (v) {
                            if (v.trim().isNotEmpty) pick(null, name: v.trim());
                          },
                        ),
                      ),
                    ],
                  )
                : UiPressable(
                    key: const Key('online-favto-new'),
                    onTap: () => setState(() => _creating = true),
                    builder: (context, _) => Row(
                      spacing: 10,
                      children: [
                        UiGlyph(UiGlyphs.plus, size: 15, color: c.accent),
                        Text(
                          l10n.online_newCollectionAndFav,
                          style: UiText.sans(13, color: c.accent),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 跳到页：一个数字框 + 跳转。失焦关闭由宿主浮层负责（点外面即关）。
class OnlineJumpPopover extends StatefulWidget {
  const OnlineJumpPopover({
    super.key,
    required this.initial,
    required this.onJump,
  });
  final int initial;
  final ValueChanged<int> onJump;

  @override
  State<OnlineJumpPopover> createState() => _OnlineJumpPopoverState();
}

class _OnlineJumpPopoverState extends State<OnlineJumpPopover> {
  late final _ctrl = TextEditingController(text: '${widget.initial}')
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: '${widget.initial}'.length,
    );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final p = int.tryParse(_ctrl.text.trim());
    if (p != null && p > 0) widget.onJump(p);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      key: const Key('online-jump-popover'),
      width: 200,
      padding: const EdgeInsets.all(10),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(7),
              ),
              child: TextField(
                key: const Key('online-jump-input'),
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: UiText.mono(13, color: c.ink),
                cursorColor: c.accent,
                cursorHeight: 15,
                decoration: uiBareDecoration(),
                onSubmitted: (_) => _go(),
              ),
            ),
          ),
          UiBtn(
            key: const Key('online-jump-go'),
            tone: UiBtnTone.primary,
            onTap: _go,
            children: [Text(context.l10n.online_jumpGo)],
          ),
        ],
      ),
    );
  }
}

/// 多选底部操作条：已选 N 张 · 全选 / 反选 · 收藏到… · 下载 · 复制 Prompt · ×。
class OnlineSelectionBar extends StatelessWidget {
  const OnlineSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final a = scope.actions;
    final keys = ctrl.picked.toList();
    final s = data.status;
    final images = data.list.items
        .where((w) => ctrl.picked.contains(w.key))
        .fold<int>(0, (n, w) => n + w.mediaCount);
    final fg = c.bg;

    Widget item(
      Widget content, {
      VoidCallback? onTap,
      bool primary = false,
      Key? key,
    }) => UiPressable(
      key: key,
      onTap: keys.isEmpty && !primary ? null : onTap,
      builder: (context, hover) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: primary
              ? (hover ? Color.lerp(c.brand, Colors.black, .08) : c.brand)
              : (hover ? fg.withValues(alpha: .12) : null),
          borderRadius: BorderRadius.circular(7),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: primary ? Colors.white : fg),
          child: DefaultTextStyle.merge(
            style: UiText.sans(
              12.5,
              weight: FontWeight.w500,
              color: primary ? Colors.white : fg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [content],
            ),
          ),
        ),
      ),
    );

    Widget sep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: UiVSep(height: 20, color: fg.withValues(alpha: .25)),
    );

    return Container(
      key: const Key('online-selection-bar'),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            l10n.online_selCount(keys.length),
            style: UiText.sans(13, weight: FontWeight.w600, color: fg),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DefaultTextStyle.merge(
              style: UiText.sans(12, color: fg.withValues(alpha: .6)),
              child: Row(
                children: [
                  UiPressable(
                    key: const Key('online-sel-all'),
                    onTap: () =>
                        ctrl.setPicked(data.list.items.map((w) => w.key)),
                    builder: (context, _) => Text(l10n.online_selAll),
                  ),
                  const Text(' · '),
                  UiPressable(
                    key: const Key('online-sel-invert'),
                    onTap: () => ctrl.setPicked([
                      for (final w in data.list.items)
                        if (!ctrl.picked.contains(w.key)) w.key,
                    ]),
                    builder: (context, _) => Text(l10n.online_selInvert),
                  ),
                ],
              ),
            ),
          ),
          sep(),
          if (s.favorites && s.favoritesWritable)
            Builder(
              builder: (ctx) => item(
                key: const Key('online-sel-favorite'),
                primary: true,
                onTap: keys.isEmpty
                    ? null
                    : s.favoritesLocal
                    ? () {
                        final box = ctx.findRenderObject()! as RenderBox;
                        ctrl.openFavoriteTo(
                          UiPopoverAnchor(
                            box.localToGlobal(const Offset(0, -16)),
                            alignBottom: true,
                          ),
                          keys,
                        );
                      }
                    : () {
                        ctrl.setPicking(false);
                        a.onFavoriteMany(keys, null);
                      },
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    const UiGlyph(
                      UiGlyphs.heartLib,
                      size: 14,
                      color: Colors.white,
                    ),
                    Text(
                      s.favoritesLocal
                          ? l10n.online_favoriteTo
                          : l10n.online_favoriteToSite,
                    ),
                    if (s.favoritesLocal)
                      const UiGlyph(
                        UiGlyphs.chevronUp,
                        size: 13,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ),
          item(
            key: const Key('online-sel-download'),
            onTap: () => a.onDownload(keys, all: true),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                UiGlyph(UiGlyphs.download, size: 14, color: fg),
                Text(l10n.online_downloadN(images)),
              ],
            ),
          ),
          item(
            key: const Key('online-sel-copy'),
            onTap: () => a.onCopyPrompt(keys),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                UiGlyph(UiGlyphs.copy, size: 14, color: fg),
                Text(
                  s.promptQuery ? l10n.online_copyPrompt : l10n.online_copyTags,
                ),
              ],
            ),
          ),
          sep(),
          Tooltip(
            message: l10n.online_exitMulti,
            child: UiPressable(
              key: const Key('online-sel-exit'),
              onTap: () => ctrl.setPicking(false),
              builder: (context, hover) => Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hover ? fg.withValues(alpha: .12) : null,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: UiGlyph(UiGlyphs.close, size: 14, color: fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
