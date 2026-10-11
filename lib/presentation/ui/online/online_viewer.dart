import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'online_contract.dart';
import 'online_inspector.dart';
import 'online_page.dart';
import 'online_parts.dart';

/// 大图查看器的宿主：[viewerKey] 非 null 时在应用浮层里铺满整个窗口（盖住导航栏和窗口按钮）。
class OnlineViewerHost extends StatefulWidget {
  const OnlineViewerHost({
    super.key,
    required this.viewerKey,
    required this.onClose,
    required this.onWorkChanged,
    required this.child,
  });

  final String? viewerKey;
  final VoidCallback onClose;
  final ValueChanged<String> onWorkChanged;
  final Widget child;

  @override
  State<OnlineViewerHost> createState() => _OnlineViewerHostState();
}

class _OnlineViewerHostState extends State<OnlineViewerHost> {
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  void didUpdateWidget(covariant OnlineViewerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewerKey == null && widget.viewerKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _portal.show();
      });
    }
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => widget.viewerKey == null
        ? const SizedBox.shrink()
        : Positioned.fill(
            child: OnlineViewer(
              workKey: widget.viewerKey!,
              onClose: widget.onClose,
              onWorkChanged: widget.onWorkChanged,
            ),
          ),
    child: widget.child,
  );
}

/// 大图查看器：黑底舞台（顶栏 · 大图 + 左右箭头 · 这一组的缩略图 · 快捷键提示）+ 右侧 380 信息栏。
class OnlineViewer extends StatefulWidget {
  const OnlineViewer({
    super.key,
    required this.workKey,
    required this.onClose,
    required this.onWorkChanged,
  });

  final String workKey;
  final VoidCallback onClose;
  final ValueChanged<String> onWorkChanged;

  @override
  State<OnlineViewer> createState() => _OnlineViewerState();
}

class _OnlineViewerState extends State<OnlineViewer> {
  var _media = 0;
  var _info = true;
  late String _key = widget.workKey;
  final _focus = FocusNode(debugLabel: 'online-viewer');

  @override
  void initState() {
    super.initState();
    // 页面已经持有焦点，autofocus 不会抢；打开时主动接过来。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OnlineViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workKey != _key) {
      _key = widget.workKey;
      _media = 0;
    }
  }

  void _work(int delta) {
    final scope = OnlineScope.of(context);
    final items = scope.data.list.items;
    final i = items.indexWhere((w) => w.key == widget.workKey);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= items.length) return;
    final key = items[j].key;
    scope.actions.onSelect(key);
    widget.onWorkChanged(key);
  }

  KeyEventResult _keys(FocusNode _, KeyEvent e, int mediaCount) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final scope = OnlineScope.of(context);
    final a = scope.actions;
    final k = e.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (k == LogicalKeyboardKey.escape) {
      widget.onClose();
    } else if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.arrowRight) {
      final d = k == LogicalKeyboardKey.arrowLeft ? -1 : 1;
      if (shift) {
        _work(d);
      } else {
        final next = _media + d;
        if (next >= 0 && next < mediaCount) {
          setState(() => _media = next);
        } else {
          _work(d);
        }
      }
    } else if (k == LogicalKeyboardKey.keyF && !ctrl) {
      if (scope.data.status.favoritesWritable) {
        a.onToggleFavorite(widget.workKey);
      }
    } else if (k == LogicalKeyboardKey.keyC && ctrl) {
      a.onCopyPrompt([widget.workKey]);
    } else if (k == LogicalKeyboardKey.enter) {
      final mode = scope.data.send.remembered ?? OnlineSendMode.replace;
      widget.onClose();
      a.onSend(widget.workKey, mode);
    } else if (k == LogicalKeyboardKey.keyI) {
      setState(() => _info = !_info);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = OnlineScope.of(context);
    final data = scope.data;
    final items = data.list.items;
    final index = items.indexWhere((w) => w.key == widget.workKey);
    if (index < 0) return const SizedBox.shrink();
    final w = items[index];
    final detail = data.detail?.key == w.key ? data.detail : null;
    final media = detail == null || detail.media.isEmpty
        ? [
            OnlineMedia(
              thumb: w.thumb,
              image: w.thumb,
              width: w.width,
              height: w.height,
            ),
          ]
        : detail.media;
    final m = _media.clamp(0, media.length - 1);
    final current = media[m];
    const fg = Color(0xFFEEEEEE);
    const dim = Color(0xFF999999);

    Widget arrow(String glyph, VoidCallback? onTap, {required bool left}) =>
        Positioned(
          left: left ? 18 : null,
          right: left ? null : 18,
          top: 0,
          bottom: 0,
          child: Center(
            child: Opacity(
              opacity: onTap == null ? .3 : 1,
              child: UiPressable(
                onTap: onTap,
                builder: (context, hover) => Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: hover ? .18 : .1),
                    shape: BoxShape.circle,
                  ),
                  child: UiGlyph(glyph, size: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        );

    final canPrev = m > 0 || index > 0;
    final canNext = m < media.length - 1 || index < items.length - 1;
    Widget kb(List<String> keys, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        for (final k in keys) _DarkKey(k),
        Text(label, style: UiText.sans(11.5, color: dim)),
      ],
    );

    final stage = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 10,
              children: [
                OnlineSourceMark(data.source, size: 22, light: true),
                Expanded(
                  child: Row(
                    spacing: 10,
                    children: [
                      Flexible(
                        child: Text(
                          w.title ?? '#${w.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            14,
                            weight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      if (w.author != null)
                        Text(w.author!, style: UiText.sans(12, color: dim)),
                    ],
                  ),
                ),
                Text(
                  media.length > 1 || w.mediaCount > 1
                      ? l10n.online_viewerPosition(
                          m + 1,
                          w.mediaCount,
                          index + 1,
                          items.length,
                        )
                      : l10n.online_viewerWorkPosition(index + 1, items.length),
                  key: const Key('online-viewer-position'),
                  style: UiText.mono(12, color: const Color(0xFFAAAAAA)),
                ),
                UiIconBox(
                  glyph: UiGlyphs.external,
                  glyphSize: 16,
                  color: const Color(0xFFCCCCCC),
                  tooltip: l10n.online_openInBrowser,
                  onTap: () => scope.actions.onOpenInBrowser(w.key),
                ),
                UiIconBox(
                  key: const Key('online-viewer-close'),
                  glyph: UiGlyphs.close,
                  glyphSize: 17,
                  color: const Color(0xFFCCCCCC),
                  tooltip: l10n.online_close,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: current.aspect,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: current.image == null
                            ? const ColoredBox(color: Color(0xFF1A1A1A))
                            : Image(
                                key: const Key('online-viewer-image'),
                                image: current.image!,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                errorBuilder: (_, _, _) =>
                                    const ColoredBox(color: Color(0xFF1A1A1A)),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              arrow(
                UiGlyphs.chevronLeft,
                canPrev
                    ? () => m > 0 ? setState(() => _media = m - 1) : _work(-1)
                    : null,
                left: true,
              ),
              arrow(
                UiGlyphs.chevronRight,
                canNext
                    ? () => m < media.length - 1
                          ? setState(() => _media = m + 1)
                          : _work(1)
                    : null,
                left: false,
              ),
            ],
          ),
        ),
        SizedBox(
          key: const Key('online-viewer-strip'),
          height: 92,
          child: media.length < 2
              ? null
              : Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        for (final (i, x) in media.indexed)
                          UiPressable(
                            onTap: () => setState(() => _media = i),
                            builder: (context, hover) => Opacity(
                              opacity: i == m ? 1 : (hover ? .8 : .5),
                              child: Container(
                                width: 56,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: i == m
                                      ? const [
                                          BoxShadow(
                                            color: Colors.white,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: x.thumb == null
                                      ? null
                                      : Image(
                                          image: x.thumb!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 6,
            children: [
              kb(['←', '→'], l10n.online_keyImage),
              kb(['Shift', '←', '→'], l10n.online_keyWork),
              kb(['F'], l10n.online_favorite),
              kb(['Ctrl', 'C'], l10n.online_copyPrompt),
              kb(['Enter'], l10n.online_send),
              kb(['I'], l10n.online_keyInfo),
              kb(['Esc'], l10n.online_close),
            ],
          ),
        ),
      ],
    );

    return Focus(
      focusNode: _focus,
      onKeyEvent: (n, e) => _keys(n, e, media.length),
      child: Material(
        key: const Key('online-viewer'),
        color: const Color(0xFF0B0B0B),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: stage),
            if (_info) const OnlineInspector(width: 380, viewer: true),
          ],
        ),
      ),
    );
  }
}

class _DarkKey extends StatelessWidget {
  const _DarkKey(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 18,
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFF1F1F1F),
      borderRadius: BorderRadius.all(Radius.circular(4)),
      border: Border(
        top: BorderSide(color: Color(0xFF3A3A3A)),
        left: BorderSide(color: Color(0xFF3A3A3A)),
        right: BorderSide(color: Color(0xFF3A3A3A)),
        bottom: BorderSide(color: Color(0xFF3A3A3A), width: 2),
      ),
    ),
    child: Text(
      label,
      style: UiText.mono(
        10.5,
        weight: FontWeight.w500,
        color: const Color(0xFFBBBBBB),
        height: 1.2,
      ),
    ),
  );
}
