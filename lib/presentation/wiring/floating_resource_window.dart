import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/floating_resource_windows_provider.dart';
import '../ui/kit/ui_block_pill.dart';
import '../ui/kit/ui_colors.dart';
import '../ui/kit/ui_glyph.dart';
import '../ui/kit/ui_text.dart';
import '../ui/refs/refs_contract.dart';
import '../widgets/gallery/local_image_card.dart';
import '../widgets/prompt/blocks/prompt_block_colors.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'floating_resource_drag.dart';
import 'floating_resource_sources.dart';
import 'floating_resource_windows_host.dart';

/// D04 资源小窗的正式外观（原型 `.devin/mockups/d04-float/`）：
/// 标题栏（拖动 / 收起 / 关闭）· 搜索框 · 网格或块列表 · 右下角缩放。
Widget floatingResourceWindowBuilder(
  BuildContext context,
  FloatingWindowData window,
  FloatingWindowController controller,
) => FloatingResourceWindow(
  key: ValueKey('floating-window-${window.id}'),
  window: window,
  controller: controller,
);

String floatingResourceTitle(BuildContext context, FloatingResourceKind kind) {
  final l = context.l10n;
  return switch (kind) {
    FloatingResourceKind.gallery => l.localGallery_title,
    FloatingResourceKind.blocks => l.blocks_title,
    FloatingResourceKind.vibe => l.refs_vibeTitle,
    FloatingResourceKind.precise => l.refs_preciseTitle,
  };
}

String floatingResourceGlyph(FloatingResourceKind kind) => switch (kind) {
  FloatingResourceKind.gallery => UiGlyphs.picture,
  FloatingResourceKind.blocks => UiGlyphs.layers,
  FloatingResourceKind.vibe => UiGlyphs.spark,
  FloatingResourceKind.precise => UiGlyphs.personStar,
};

class FloatingResourceWindow extends ConsumerStatefulWidget {
  const FloatingResourceWindow({
    super.key,
    required this.window,
    required this.controller,
  });
  final FloatingWindowData window;
  final FloatingWindowController controller;

  @override
  ConsumerState<FloatingResourceWindow> createState() =>
      _FloatingResourceWindowState();
}

class _FloatingResourceWindowState
    extends ConsumerState<FloatingResourceWindow> {
  late final _query = TextEditingController(text: widget.window.query);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => widget.controller.setQuery(value),
    );
  }

  void _submitted(String value) {
    _debounce?.cancel();
    widget.controller.setQuery(value);
    if (widget.window.kind == FloatingResourceKind.gallery) {
      unawaited(
        ref
            .read(floatingGalleryQueryActionsProvider)
            .confirm(widget.window.id, value),
      );
    }
  }

  bool get _focused {
    final windows = ref.watch(floatingResourceWindowsProvider);
    return windows.isNotEmpty && windows.last.id == widget.window.id;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final w = widget.window;
    final ctl = widget.controller;
    final focused = _focused;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: focused ? c.strong.withValues(alpha: .5) : c.border,
          ),
          // 与 UiPopoverSurface 同一套分层阴影；聚焦窗口加深一档。
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: (c.dark ? .32 : .07) * (focused ? 1.6 : 1),
              ),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .36 : .10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .4 : .10),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TitleBar(window: w, controller: ctl),
                  if (!w.minimized) ...[
                    _SearchBox(
                      controller: _query,
                      onChanged: _changed,
                      onSubmitted: _submitted,
                      hint: switch (w.kind) {
                        FloatingResourceKind.gallery =>
                          context.l10n.floating_searchGallery,
                        _ => context.l10n.floating_searchName,
                      },
                    ),
                    Expanded(
                      child: switch (w.kind) {
                        FloatingResourceKind.gallery => _GalleryBody(id: w.id),
                        FloatingResourceKind.blocks => _BlocksBody(id: w.id),
                        FloatingResourceKind.vibe => _RefsBody(
                          id: w.id,
                          kind: RefsKind.vibe,
                        ),
                        FloatingResourceKind.precise => _RefsBody(
                          id: w.id,
                          kind: RefsKind.precise,
                        ),
                      },
                    ),
                  ],
                ],
              ),
              if (!w.minimized)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: ctl.resizeHandle(
                      key: Key('floating-resize-${w.id}'),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CustomPaint(painter: _GripPainter(c.faint)),
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

class _TitleBar extends ConsumerWidget {
  const _TitleBar({required this.window, required this.controller});
  final FloatingWindowData window;
  final FloatingWindowController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    final l = context.l10n;
    final count = switch (window.kind) {
      FloatingResourceKind.gallery =>
        ref
            .watch(floatingGalleryPageProvider((id: window.id, page: 0)))
            .valueOrNull
            ?.totalCount,
      FloatingResourceKind.blocks =>
        ref.watch(floatingBlocksProvider(window.id)).valueOrNull?.length,
      _ => ref.watch(floatingRefsProvider(window.id)).valueOrNull?.length,
    };
    // 宿主收起时窗口高 32，标题栏同高。
    return SizedBox(
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: window.minimized
              ? null
              : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: controller.moveHandle(
                  key: Key('floating-title-${window.id}'),
                  child: GestureDetector(
                    onDoubleTap: () =>
                        controller.setMinimized(!window.minimized),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        spacing: 7,
                        children: [
                          UiGlyph(
                            floatingResourceGlyph(window.kind),
                            size: 14,
                            color: c.muted,
                          ),
                          Flexible(
                            child: Text(
                              floatingResourceTitle(context, window.kind),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                12.5,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          if (count != null)
                            Text(
                              '· $count',
                              style: UiText.sans(11.5, color: c.faint),
                            ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _IconBtn(
              key: Key('floating-minimize-${window.id}'),
              glyph: window.minimized ? UiGlyphs.chevronDown : UiGlyphs.minus,
              tooltip: window.minimized
                  ? l.floating_expand
                  : l.floating_collapse,
              onTap: () => controller.setMinimized(!window.minimized),
            ),
            _IconBtn(
              key: Key('floating-close-${window.id}'),
              glyph: UiGlyphs.close,
              tooltip: l.common_close,
              onTap: controller.close,
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });
  final String glyph;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hover ? c.hover : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: UiGlyph(widget.glyph, size: 13, color: c.muted),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.hint,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 28,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        spacing: 6,
        children: [
          UiGlyph(UiGlyphs.search, size: 13, color: c.faint),
          Expanded(
            child: TextField(
              key: const Key('floating-search'),
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: UiText.sans(12, color: c.ink, height: 1.2),
              cursorHeight: 14,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: UiText.sans(12, color: c.faint, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: UiText.sans(12, color: context.ui.faint),
      ),
    ),
  );
}

Widget _async<T>(
  BuildContext context,
  AsyncValue<T> value,
  bool Function(T) empty,
  Widget Function(T) data,
) {
  final l = context.l10n;
  // 依赖变化（状态、模型、缩略图版本）重算时沿用旧数据，避免列表闪成转圈。
  return value.when(
    skipLoadingOnReload: true,
    data: (v) => empty(v) ? _Status(l.floating_empty) : data(v),
    loading: () => const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
    error: (e, _) => _Status(l.floating_loadFailed),
  );
}

/// 图库：沿用图库卡片（自带缩略图加载与拖出协议），一页 60 张，底部「加载更多」。
class _GalleryBody extends ConsumerStatefulWidget {
  const _GalleryBody({required this.id});
  final String id;

  @override
  ConsumerState<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends ConsumerState<_GalleryBody> {
  var _pages = 1;
  String? _lastQuery;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(floatingResourceQueryProvider(widget.id));
    if (query?.query != _lastQuery) {
      _lastQuery = query?.query;
      _pages = 1;
    }
    final first = ref.watch(
      floatingGalleryPageProvider((id: widget.id, page: 0)),
    );
    return _async(context, first, (p) => p.records.isEmpty, (page) {
      final records = [
        for (var i = 0; i < _pages; i++)
          ...?ref
              .watch(floatingGalleryPageProvider((id: widget.id, page: i)))
              .valueOrNull
              ?.records,
      ];
      final more = page.totalCount > records.length;
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = ((constraints.maxWidth - 16 + 6) / (78 + 6))
              .floor()
              .clamp(2, 8);
          final cell = (constraints.maxWidth - 16 - 6 * (cols - 1)) / cols;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: records.length,
                  itemBuilder: (context, i) {
                    final r = records[i];
                    return LocalImageCard(
                      key: ValueKey('floating-gallery-${r.path}'),
                      record: r,
                      width: cell,
                      height: cell * 4 / 3,
                      dragWrapper: (child) =>
                          FloatingResourceDrag.gallery(record: r, child: child),
                    );
                  },
                ),
              ),
              if (more)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: TextButton(
                        key: const Key('floating-gallery-more'),
                        onPressed: () => setState(() => _pages++),
                        child: Text(
                          context.l10n.floating_loadMore,
                          style: UiText.sans(12, color: context.ui.muted),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    });
  }
}

/// 块库：块芯片列表，拖到提示词框（沿用积木浮窗的拖放数据）。
class _BlocksBody extends ConsumerWidget {
  const _BlocksBody({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    return _async(
      context,
      ref.watch(floatingBlocksProvider(id)),
      (b) => b.isEmpty,
      (blocks) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        itemCount: blocks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final b = blocks[i];
          final color = promptBlockColorFromString(b.color);
          final row = Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              spacing: 7,
              children: [
                UiBlockIcon(b.iconName, size: 13, color: color),
                Expanded(
                  child: Text(
                    b.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(12, color: c.ink),
                  ),
                ),
              ],
            ),
          );
          return Draggable<PromptBlockDragData>(
            key: ValueKey('floating-block-${b.id}'),
            data: FloatingResourceDrag.block(b.id),
            rootOverlay: true,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 200,
                child: Opacity(opacity: .9, child: row),
              ),
            ),
            childWhenDragging: Opacity(opacity: .35, child: row),
            child: MouseRegion(cursor: SystemMouseCursors.grab, child: row),
          );
        },
      ),
    );
  }
}

/// Vibe / 精准参考：缩略图网格，拖到生成页对应行。
class _RefsBody extends ConsumerWidget {
  const _RefsBody({required this.id, required this.kind});
  final String id;
  final RefsKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ui;
    return _async(
      context,
      ref.watch(floatingRefsProvider(id)),
      (e) => e.isEmpty,
      (entries) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 96,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 3 / 4,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          Widget tile({double? width}) => Tooltip(
            message: e.name,
            waitDuration: const Duration(milliseconds: 600),
            child: Container(
              width: width,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (e.thumb case final thumb?)
                    Image(
                      image: thumb,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Center(
                        child: UiGlyph(
                          UiGlyphs.picture,
                          size: 18,
                          color: c.faint,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: UiGlyph(
                        UiGlyphs.picture,
                        size: 18,
                        color: c.faint,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 3),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x99000000)],
                        ),
                      ),
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(10.5, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          return Draggable<RefsEntryDragData>(
            key: ValueKey('floating-ref-${e.key}'),
            data: FloatingResourceDrag.refs(kind, [e.key]),
            rootOverlay: true,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Opacity(
              opacity: .85,
              child: SizedBox(width: 64, height: 86, child: tile()),
            ),
            childWhenDragging: Opacity(opacity: .35, child: tile()),
            child: MouseRegion(cursor: SystemMouseCursors.grab, child: tile()),
          );
        },
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    canvas.drawLine(Offset(w - 4, h - 10), Offset(w - 10, h - 4), p);
    canvas.drawLine(Offset(w - 4, h - 6), Offset(w - 6, h - 4), p);
  }

  @override
  bool shouldRepaint(_GripPainter old) => old.color != color;
}
