import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../kit/ui_controls.dart';
import '../kit/ui_text.dart';
import 'viewer_contract.dart';
import 'viewer_format.dart';
import 'viewer_page.dart';
import 'viewer_parts.dart';

/// 胶片条（82 高）：按原图比例的缩略图（52 高，当前张 60 高加白框），按天分隔（按时间排序时），
/// 两端渐隐；当前张换了自动滚到可见处；滚到窗口边缘续读。生成结果居中、不分隔。
class ViewerFilmstrip extends StatefulWidget {
  const ViewerFilmstrip({super.key});

  static const height = 82.0;

  @override
  State<ViewerFilmstrip> createState() => _ViewerFilmstripState();
}

class _ViewerFilmstripState extends State<ViewerFilmstrip> {
  final _scroll = ScrollController();
  final _currentKey = GlobalKey();
  String? _shown;
  int _edgeAt = -1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_edge);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _edge() {
    if (!_scroll.hasClients) return;
    final scope = ViewerPageScope.of(context);
    final count = scope.data.items.length;
    if (_edgeAt == count) return;
    final p = _scroll.position;
    if (p.pixels < 240 && p.pixels < p.maxScrollExtent) {
      _edgeAt = count;
      scope.actions.onLoadMore(forward: false);
    } else if (p.maxScrollExtent - p.pixels < 240 && p.maxScrollExtent > 0) {
      _edgeAt = count;
      scope.actions.onLoadMore(forward: true);
    }
  }

  void _reveal(String key) {
    if (_shown == key) return;
    _shown = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _currentKey.currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final gen = data.mode == ViewerMode.generation;
    final byDate =
        !gen &&
        (data.scope?.sort == ViewerSort.modified ||
            data.scope?.sort == ViewerSort.created);
    _reveal(data.currentKey);

    final children = <Widget>[];
    DateTime? last;
    for (final it in data.items) {
      final d = it.date;
      if (byDate &&
          d != null &&
          (last == null || !DateUtils.isSameDay(d, last))) {
        children.add(_DayLabel(viewerDay(context, d)));
        last = d;
      }
      final on = it.key == data.currentKey;
      final thumb = _Thumb(
        key: on ? _currentKey : ValueKey('viewer-film-${it.key}'),
        item: it,
        on: on,
        onTap: () => scope.actions.onSelect(it.key),
      );
      children.add(
        on
            ? KeyedSubtree(key: const Key('viewer-film-current'), child: thumb)
            : thumb,
      );
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: children,
    );
    return SizedBox(
      key: const Key('viewer-filmstrip'),
      height: ViewerFilmstrip.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LayoutBuilder(
                builder: (context, box) => Listener(
                  // 竖滚轮也横着滚。
                  onPointerSignal: (e) {
                    if (e is PointerScrollEvent && _scroll.hasClients) {
                      final p = _scroll.position;
                      final d = e.scrollDelta.dy != 0
                          ? e.scrollDelta.dy
                          : e.scrollDelta.dx;
                      _scroll.jumpTo(
                        (p.pixels + d).clamp(0, p.maxScrollExtent),
                      );
                    }
                  },
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: box.maxWidth - 28,
                        minHeight: box.maxHeight,
                      ),
                      child: Align(
                        alignment: gen
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: row,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _Fade(left: true),
          const _Fade(left: false),
        ],
      ),
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.left});
  final bool left;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left ? 0 : null,
    right: left ? null : 0,
    top: 0,
    bottom: 0,
    width: 60,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: [ViewerInk.stage, ViewerInk.stage.withValues(alpha: 0)],
          ),
        ),
      ),
    ),
  );
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.only(left: 8, right: 6),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: ViewerInk.divider)),
    ),
    child: Text(text, style: UiText.sans(11, color: const Color(0x8CFFFFFF))),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    super.key,
    required this.item,
    required this.on,
    required this.onTap,
  });
  final ViewerItem item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = on ? 60.0 : 52.0;
    final w = (h * item.aspect).roundToDouble().clamp(24.0, 160.0);
    return UiPressable(
      onTap: on ? null : onTap,
      builder: (context, hover) => Container(
        width: w,
        height: h,
        margin: on ? const EdgeInsets.symmetric(horizontal: 4) : null,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(5),
          boxShadow: on
              ? const [
                  BoxShadow(color: Colors.white, spreadRadius: 2),
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: on ? 1 : (hover ? .8 : .5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: item.thumb == null
                ? null
                : Image(
                    image: item.thumb!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          ),
        ),
      ),
    );
  }
}
