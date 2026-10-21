import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../ui/kit/ui_controls.dart';
import '../../ui/kit/ui_glyph.dart';
import '../../ui/kit/ui_text.dart';

/// Wiki 示例图大图：全窗口深色灯箱。顶栏标题 / 序号 / 来源 / 关闭，中间可缩放，
/// 两侧箭头与 ←→ 在同一标签的示例间切换，底部说明和缩略图条。Esc 或点空白关闭。
Future<void> showWikiExampleViewer(
  BuildContext context, {
  required List<WikiExample> examples,
  required int initial,
  required BaseCacheManager cache,
}) {
  final items = examples.where((e) => e.largeUrl != null).toList();
  if (items.isEmpty) return Future.value();
  final start = items.indexWhere((e) => e.postId == examples[initial].postId);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.l10n.common_close,
    barrierColor: const Color(0xE6080808),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: WikiExampleViewer(
        examples: items,
        initial: start < 0 ? 0 : start,
        cache: cache,
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// DText 说明转成纯文本：`[[tag|label]]` 取 label，`[[tag]]` 取 tag。
String wikiExampleCaptionText(String caption) => caption
    .replaceAllMapped(RegExp(r'\[\[([^\]|]+)\|([^\]]*)\]\]'), (m) => m[2]!)
    .replaceAllMapped(
      RegExp(r'\[\[([^\]]+)\]\]'),
      (m) => m[1]!.replaceAll('_', ' '),
    )
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class WikiExampleViewer extends StatefulWidget {
  const WikiExampleViewer({
    super.key,
    required this.examples,
    required this.initial,
    required this.cache,
  });
  final List<WikiExample> examples;
  final int initial;
  final BaseCacheManager cache;

  @override
  State<WikiExampleViewer> createState() => _WikiExampleViewerState();
}

class _WikiExampleViewerState extends State<WikiExampleViewer> {
  late var _index = widget.initial.clamp(0, widget.examples.length - 1);
  final _focus = FocusNode();
  final _zoom = TransformationController();
  var _revision = 0;

  static const _ink = Color(0xFFF2F2F2);
  static const _muted = Color(0xFFA3A3A3);
  static const _chip = Color(0x1FFFFFFF);
  static const _chipHover = Color(0x33FFFFFF);

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
    _zoom.dispose();
    super.dispose();
  }

  bool get _many => widget.examples.length > 1;

  void _go(int delta) {
    if (!_many) return;
    setState(() {
      _index = (_index + delta) % widget.examples.length;
      _zoom.value = Matrix4.identity();
    });
  }

  void _jump(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _zoom.value = Matrix4.identity();
    });
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _retry(String url) async {
    await CachedNetworkImage.evictFromCache(url, cacheManager: widget.cache);
    if (mounted) setState(() => _revision++);
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(-1);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(1);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _button({
    required Key key,
    required String glyph,
    String? label,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 12),
        decoration: BoxDecoration(
          color: hover ? _chipHover : _chip,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            UiGlyph(glyph, size: 15, color: _ink),
            if (label != null)
              Text(label, style: UiText.sans(12.5, color: _ink, height: 1.2)),
          ],
        ),
      ),
    ),
  );

  Widget _arrow(int delta) => UiPressable(
    key: Key(delta < 0 ? 'wiki-viewer-prev' : 'wiki-viewer-next'),
    onTap: () => _go(delta),
    builder: (context, hover) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: hover ? _chipHover : _chip,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: UiGlyph(
          delta < 0 ? UiGlyphs.chevronLeft : UiGlyphs.chevronRight,
          size: 20,
          color: _ink,
        ),
      ),
    ),
  );

  Widget _image(WikiExample example) {
    final url = example.largeUrl!;
    return InteractiveViewer(
      key: ValueKey('wiki-viewer-zoom-${example.postId}'),
      transformationController: _zoom,
      minScale: 1,
      maxScale: 5,
      // 撑满可用区域：720 预览图在大窗口里放大到能看清，而不是缩在中间。
      child: SizedBox.expand(
        child: KeyedSubtree(
          key: ValueKey('wiki-viewer-rev-$_revision'),
          child: CachedNetworkImage(
            key: ValueKey('wiki-example-large-${example.postId}'),
            imageUrl: url,
            cacheManager: widget.cache,
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (context, _) => const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: _muted,
                ),
              ),
            ),
            errorWidget: (context, _, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const UiGlyph(UiGlyphs.image, size: 28, color: _muted),
                  Text(
                    context.l10n.wiki_exampleImagesUnavailable,
                    style: UiText.sans(13, color: _muted),
                  ),
                  _button(
                    key: const Key('wiki-viewer-retry'),
                    glyph: UiGlyphs.refresh,
                    label: context.l10n.common_retry,
                    tooltip: context.l10n.common_retry,
                    onTap: () => _retry(url),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _strip() => SizedBox(
    height: 56,
    child: ListView.separated(
      key: const Key('wiki-viewer-strip'),
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      itemCount: widget.examples.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, i) {
        final e = widget.examples[i];
        final on = i == _index;
        return UiPressable(
          key: Key('wiki-viewer-thumb-${e.postId}'),
          onTap: () => _jump(i),
          builder: (context, hover) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _chip,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: on
                    ? _ink
                    : hover
                    ? _muted
                    : Colors.transparent,
                width: on ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: on || hover ? 1 : .6,
              child: e.thumbnailUrl == null
                  ? const Center(
                      child: UiGlyph(UiGlyphs.image, size: 16, color: _muted),
                    )
                  : CachedNetworkImage(
                      imageUrl: e.thumbnailUrl!,
                      cacheManager: widget.cache,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final example = widget.examples[_index];
    final caption = wikiExampleCaptionText(example.reference.caption);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: SafeArea(
        child: Column(
          key: const Key('wiki-viewer'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
              child: Row(
                spacing: 8,
                children: [
                  Text(
                    l.wiki_exampleImages,
                    style: UiText.sans(
                      14,
                      weight: FontWeight.w600,
                      color: _ink,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '#${example.postId}',
                    style: UiText.mono(12, color: _muted, height: 1.2),
                  ),
                  if (_many)
                    Text(
                      '${_index + 1} / ${widget.examples.length}',
                      key: const Key('wiki-viewer-index'),
                      style: UiText.mono(12, color: _muted, height: 1.2),
                    ),
                  const Spacer(),
                  _button(
                    key: const Key('wiki-viewer-source'),
                    glyph: UiGlyphs.external,
                    label: l.wiki_source,
                    tooltip: example.sourceUrl,
                    onTap: () => launchUrl(Uri.parse(example.sourceUrl)),
                  ),
                  _button(
                    key: const Key('wiki-viewer-close'),
                    glyph: UiGlyphs.close,
                    tooltip: l.common_close,
                    onTap: _close,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // 点图外的空白关闭；图本身吃掉点击（缩放拖动不误关）。
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _close,
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _many ? 72 : 24,
                      ),
                      child: _image(example),
                    ),
                  ),
                  if (_many) ...[
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _arrow(-1)),
                    ),
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: _arrow(1)),
                    ),
                  ],
                ],
              ),
            ),
            if (caption.isNotEmpty || _many)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Column(
                  spacing: 12,
                  children: [
                    if (caption.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Text(
                          caption,
                          key: const Key('wiki-viewer-caption'),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(13, color: _ink, height: 1.5),
                        ),
                      ),
                    if (_many) _strip(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
