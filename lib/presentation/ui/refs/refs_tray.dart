import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_page.dart';
import 'refs_parts.dart';
import 'refs_sidebar.dart';

/// 底部托盘 76：生图页现在用着的 Vibe / 精准参考。卡片拖进来 = 加入，按住 Shift = 替换。
class RefsTrayBar extends StatefulWidget {
  const RefsTrayBar({super.key});

  @override
  State<RefsTrayBar> createState() => _RefsTrayBarState();
}

class _RefsTrayBarState extends State<RefsTrayBar> {
  var _over = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final tray = data.tray;
    final k = data.costs;
    final vibe = data.kind == RefsKind.vibe;
    final n = tray.items.length;
    final usable = vibe ? data.model.vibeUsable : data.model.preciseUsable;

    final head = SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: vibe ? 4 : 3,
        children: [
          Row(
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  vibe ? l10n.refs_trayVibe : l10n.refs_trayPrecise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
              ),
              Text(
                vibe ? '$n/${k.maxVibes}' : '$n',
                style: UiText.mono(12, weight: FontWeight.w500, color: c.muted),
              ),
            ],
          ),
          if (vibe) RefsMeter(used: n, max: k.maxVibes, free: k.freeVibes),
          Text(
            vibe
                ? l10n.refs_trayVibeCost(k.freeVibes, k.extraPerVibe)
                : l10n.refs_trayPreciseCost(k.precise, n * k.precise),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(11, color: c.faint),
          ),
        ],
      ),
    );

    final thumbs = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        for (final it in tray.items)
          _TrayThumb(
            key: Key('refs-tray-${it.id}'),
            item: it,
            dim: !it.enabled || !usable,
            precise: !vibe,
            onRemove: () => a.onTrayRemove(it.id),
          ),
        _AddTile(active: _over),
      ],
    );

    final conflict = !vibe && tray.otherVibes > 0
        ? _Conflict(
            count: tray.otherVibes,
            paused: tray.vibesPaused,
            onToggle: () => a.onPauseVibes(!tray.vibesPaused),
          )
        : null;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        final ok = d.data is RefsCardDrag && usable;
        if (ok) setState(() => _over = true);
        return ok;
      },
      onLeave: (_) => setState(() => _over = false),
      onAcceptWithDetails: (d) {
        setState(() => _over = false);
        scope.controller.add(
          (d.data as RefsCardDrag).keys,
          replace: HardwareKeyboard.instance.isShiftPressed,
        );
      },
      builder: (context, _, _) => Container(
        key: const Key('refs-tray'),
        height: 76,
        padding: const EdgeInsets.only(left: 18, right: 16),
        decoration: BoxDecoration(
          color: _over
              ? Color.alphaBlend(c.accent.withValues(alpha: .06), c.panel)
              : c.panel,
          border: Border(top: BorderSide(color: _over ? c.accent : c.line)),
        ),
        child: Row(
          spacing: 12,
          children: [
            head,
            // 缩略图按实际宽度排（最多占 70%，再多横向滚动）；提示文字吃剩下的空间，窄了先省略它。
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Row(
                  spacing: 12,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: box.maxWidth * .7),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: thumbs,
                      ),
                    ),
                    if (vibe)
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Text(
                            l10n.refs_trayHint,
                            key: const Key('refs-tray-hint'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11, color: c.faint, height: 1.5),
                          ),
                        ),
                      )
                    else if (conflict != null)
                      Flexible(child: conflict),
                  ],
                ),
              ),
            ),
            if (vibe && n > 0)
              UiBtn(
                key: const Key('refs-tray-clear'),
                size: UiBtnSize.small,
                tone: UiBtnTone.ghost,
                onTap: a.onTrayClear,
                children: [Text(l10n.refs_clear)],
              ),
            UiBtn(
              key: const Key('refs-go-generation'),
              onTap: a.onGoGeneration,
              children: [
                Text(l10n.refs_goGeneration),
                const UiGlyph(UiGlyphs.arrowRight, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrayThumb extends StatefulWidget {
  const _TrayThumb({
    super.key,
    required this.item,
    required this.dim,
    required this.precise,
    required this.onRemove,
  });
  final RefsTrayItem item;
  final bool dim;
  final bool precise;
  final VoidCallback onRemove;

  @override
  State<_TrayThumb> createState() => _TrayThumbState();
}

class _TrayThumbState extends State<_TrayThumb> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final it = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Opacity(
        opacity: widget.dim ? .4 : 1,
        child: Container(
          width: 44,
          height: 52,
          clipBehavior: Clip.antiAlias,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: c.line),
          ),
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefsImage(
                it.thumb,
                alignment: widget.precise
                    ? const Alignment(0, -.6)
                    : Alignment.center,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 15,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xBF000000)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      RefsFormat.two(it.value),
                      style: UiText.mono(
                        9.5,
                        weight: FontWeight.w500,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (_hover)
                Positioned(
                  right: 2,
                  top: 2,
                  child: UiPressable(
                    key: const Key('refs-tray-remove'),
                    onTap: widget.onRemove,
                    builder: (_, _) => Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: const UiGlyph(
                        UiGlyphs.close,
                        size: 9,
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: context.l10n.refs_trayDropHere,
      child: UiDashedBox(
        key: const Key('refs-tray-add'),
        radius: 7,
        color: active ? c.accent : c.strong,
        dash: 4,
        gap: 3,
        child: SizedBox(
          width: 44,
          height: 52,
          child: Center(
            child: UiGlyph(
              UiGlyphs.plus,
              size: 16,
              color: active ? c.accent : c.faint,
            ),
          ),
        ),
      ),
    );
  }
}

/// 精准参考托盘：生图页还有 Vibe 时说明不兼容，给“暂停 Vibe / 恢复”。
class _Conflict extends StatelessWidget {
  const _Conflict({
    required this.count,
    required this.paused,
    required this.onToggle,
  });
  final int count;
  final bool paused;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final text = paused
        ? l10n.refs_conflictPaused(count)
        : l10n.refs_conflict(count);
    final parts = text.split('**');
    return Container(
      key: const Key('refs-conflict'),
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: paused ? c.control : c.warnBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          UiGlyph(
            paused ? UiGlyphs.infoCircle : UiGlyphs.alert,
            size: 15,
            color: paused ? c.muted : c.warn,
          ),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (i, p) in parts.indexed)
                    TextSpan(
                      text: p,
                      style: i.isOdd
                          ? const TextStyle(fontWeight: FontWeight.w600)
                          : null,
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.ink, height: 1.45),
            ),
          ),
          UiPressable(
            key: const Key('refs-pause-vibes'),
            onTap: onToggle,
            builder: (_, hover) => Text(
              paused ? l10n.refs_resumeVibes : l10n.refs_pauseVibes,
              style: UiText.sans(
                12,
                weight: FontWeight.w600,
                color: hover ? c.ink : c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
