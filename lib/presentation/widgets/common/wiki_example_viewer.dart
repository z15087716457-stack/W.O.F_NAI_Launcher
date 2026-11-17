import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/wiki/wiki_example_repository.dart';
import '../../ui/kit/ui_controls.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_glyph.dart';
import '../../ui/kit/ui_text.dart';

final _wikiViewers = Expando<Future<void>>();

/// Wiki 示例图大图：全窗口深色灯箱。顶栏标题 / 序号 / 来源 / 关闭，中间可缩放，
/// 两侧箭头与 ←→ 在同一标签的示例间切换，底部说明和缩略图条。Esc 或单击大图关闭。
Future<void> showWikiExampleViewer(
  BuildContext context, {
  required List<WikiExample> examples,
  required int initial,
  required BaseCacheManager cache,
}) {
  final items = examples.where((e) => e.largeUrl != null).toList();
  if (items.isEmpty) return Future.value();
  final overlay = Overlay.of(context, rootOverlay: true);
  final active = _wikiViewers[overlay];
  if (active != null) return active;
  final done = Completer<void>();
  final previousFocus = FocusManager.instance.primaryFocus;
  late OverlayEntry entry;
  void close() {
    if (done.isCompleted) return;
    done.complete();
    entry.remove();
    entry.dispose();
    _wikiViewers[overlay] = null;
    if (previousFocus?.context != null) previousFocus!.requestFocus();
  }

  final start = items.indexWhere(
    (e) =>
        e.reference.occurrenceKey == examples[initial].reference.occurrenceKey,
  );
  // One root entry prevents rapid opens from stacking Navigator dialogs.
  entry = OverlayEntry(
    builder: (context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(
            dismissible: true,
            onDismiss: close,
            semanticsLabel: context.l10n.common_close,
            color: const Color(0xE6080808),
          ),
          Material(
            type: MaterialType.transparency,
            child: FocusScope(
              autofocus: true,
              child: WikiExampleViewer(
                examples: items,
                initial: start < 0 ? 0 : start,
                cache: cache,
                onClose: close,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  _wikiViewers[overlay] = done.future;
  overlay.insert(entry);
  return done.future;
}

/// DText 说明转成纯文本：`[[tag|label]]` 取 label，`[[tag]]` 取 tag。
String wikiExampleCaptionText(String caption) => wikiImageCaptionText(caption);

class WikiExampleViewer extends StatefulWidget {
  const WikiExampleViewer({
    super.key,
    required this.examples,
    required this.initial,
    required this.cache,
    required this.onClose,
    this.embedded = false,
    this.onChanged,
  });
  final List<WikiExample> examples;
  final int initial;
  final BaseCacheManager cache;
  final VoidCallback onClose;
  final bool embedded;
  final ValueChanged<int>? onChanged;

  @override
  State<WikiExampleViewer> createState() => _WikiExampleViewerState();
}

class _WikiExampleViewerState extends State<WikiExampleViewer> {
  late var _index = widget.initial.clamp(0, widget.examples.length - 1);
  final _focus = FocusNode();
  final _zoom = TransformationController();
  var _revision = 0;

  Color get _ink => widget.embedded ? context.ui.ink : const Color(0xFFF2F2F2);
  Color get _muted =>
      widget.embedded ? context.ui.muted : const Color(0xFFA3A3A3);
  Color get _chip =>
      widget.embedded ? context.ui.control : const Color(0x1FFFFFFF);
  Color get _chipHover =>
      widget.embedded ? context.ui.hover : const Color(0x33FFFFFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.embedded) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(WikiExampleViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.embedded) return;
    final before = oldWidget.examples[_index].reference.occurrenceKey;
    _index = widget.initial;
    if (widget.examples[_index].reference.occurrenceKey != before) {
      _zoom.value = Matrix4.identity();
    }
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
    _jump((_index + delta) % widget.examples.length);
  }

  void _jump(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _zoom.value = Matrix4.identity();
    });
    if (widget.embedded) _focus.requestFocus();
    widget.onChanged?.call(index);
  }

  void _close() => widget.onClose();

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
    String? glyph,
    String? label,
    bool compact = false,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: compact
            ? 24
            : widget.embedded
            ? 28
            : 32,
        padding: EdgeInsets.symmetric(
          horizontal: compact
              ? 4.5
              : widget.embedded
              ? (label == null ? 6 : 10)
              : label == null
              ? 8
              : 12,
        ),
        decoration: BoxDecoration(
          color: hover ? _chipHover : _chip,
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            if (glyph != null) UiGlyph(glyph, size: 15, color: _ink),
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
      width: widget.embedded ? 29 : 44,
      height: widget.embedded ? 34 : 44,
      decoration: BoxDecoration(
        color: hover
            ? _chipHover
            : widget.embedded
            ? Theme.of(context).colorScheme.surface
            : _chip,
        shape: widget.embedded ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: widget.embedded ? BorderRadius.circular(7) : null,
        border: widget.embedded ? Border.all(color: context.ui.border) : null,
      ),
      child: Center(
        child: UiGlyph(
          delta < 0 ? UiGlyphs.chevronLeft : UiGlyphs.chevronRight,
          size: widget.embedded ? 15 : 20,
          color: _ink,
        ),
      ),
    ),
  );

  Widget _image(WikiExample example) {
    final url = example.largeUrl!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.embedded ? _focus.requestFocus : _close,
      child: InteractiveViewer(
        key: ValueKey('wiki-viewer-zoom-${example.reference.occurrenceKey}'),
        transformationController: _zoom,
        minScale: 1,
        maxScale: 5,
        // 撑满可用区域：720 预览图在大窗口里放大到能看清，而不是缩在中间。
        child: SizedBox.expand(
          child: KeyedSubtree(
            key: ValueKey('wiki-viewer-rev-$_revision'),
            child: CachedNetworkImage(
              key: ValueKey(
                'wiki-example-large-${example.reference.occurrenceKey}',
              ),
              imageUrl: url,
              cacheManager: widget.cache,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, _) => Center(
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
                    UiGlyph(UiGlyphs.image, size: 28, color: _muted),
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
          key: Key('wiki-viewer-thumb-${e.reference.occurrenceKey}'),
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
                  ? Center(
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

  Widget _embedded(WikiExample example, String caption, String section) {
    final c = context.ui;
    return Material(
      key: const Key('wiki-image-preview-panel'),
      elevation: 14,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              key: const Key('wiki-preview-header'),
              padding: const EdgeInsets.fromLTRB(12, 5, 4, 5),
              child: Row(
                spacing: 6,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.wiki_imagePreviewTitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  _button(
                    key: const Key('wiki-viewer-source'),
                    glyph: UiGlyphs.external,
                    compact: true,
                    tooltip: example.sourceUrl,
                    onTap: () => launchUrl(Uri.parse(example.sourceUrl)),
                  ),
                  _button(
                    key: const Key('wiki-viewer-close'),
                    glyph: UiGlyphs.close,
                    compact: true,
                    tooltip: context.l10n.common_close,
                    onTap: _close,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ColoredBox(
                key: const Key('wiki-preview-image'),
                color: c.page,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _image(example),
                    ),
                    if (_many) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _arrow(-1),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _arrow(1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              key: const Key('wiki-preview-details'),
              constraints: BoxConstraints(
                maxHeight: (constraints.maxHeight * .32).clamp(0, 170),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 7,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            section,
                            style: UiText.sans(11, color: c.muted),
                          ),
                        ),
                        Text(
                          '${_index + 1} / ${widget.examples.length}',
                          key: const Key('wiki-viewer-index'),
                          style: UiText.mono(11, color: c.muted),
                        ),
                      ],
                    ),
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        key: const Key('wiki-viewer-caption'),
                        style: UiText.sans(12, color: c.ink, height: 1.5),
                      ),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            '${example.reference.kind.name} #${example.postId}',
                            style: UiText.mono(11, color: c.muted),
                          ),
                        ),
                        ValueListenableBuilder<Matrix4>(
                          valueListenable: _zoom,
                          builder: (context, matrix, _) => _button(
                            key: const Key('wiki-viewer-reset-zoom'),
                            label:
                                '${(matrix.getMaxScaleOnAxis() * 100).round()}%',
                            tooltip: context.l10n.blocks_resetZoom,
                            onTap: () => _zoom.value = Matrix4.identity(),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final example = widget.examples[_index];
    final caption = wikiExampleCaptionText(example.reference.caption);
    final section = example.reference.sectionText;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      child: widget.embedded
          ? _embedded(example, caption, section)
          : SafeArea(
              child: Column(
                key: const Key('wiki-viewer'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l.wiki_imagePanelTitle,
                                style: UiText.sans(
                                  14,
                                  weight: FontWeight.w600,
                                  color: _ink,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                '${example.reference.kind == WikiImageKind.asset ? 'Asset ' : ''}#${example.postId}',
                                style: UiText.mono(
                                  12,
                                  color: _muted,
                                  height: 1.2,
                                ),
                              ),
                              if (_many)
                                Text(
                                  '${_index + 1} / ${widget.examples.length}',
                                  key: const Key('wiki-viewer-index'),
                                  style: UiText.mono(
                                    12,
                                    color: _muted,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _button(
                          key: const Key('wiki-viewer-source'),
                          glyph: UiGlyphs.external,
                          label: MediaQuery.sizeOf(context).width >= 480
                              ? l.wiki_source
                              : null,
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
                        // 空白与大图均可单击关闭，拖动／缩放仍由图片手势接管。
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
                  if (caption.isNotEmpty || section.isNotEmpty || _many)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                      child: Column(
                        spacing: 12,
                        children: [
                          if (section.isNotEmpty)
                            Text(
                              section,
                              style: UiText.sans(11, color: _muted),
                              textAlign: TextAlign.center,
                            ),
                          if (caption.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 760,
                                maxHeight: 120,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  caption,
                                  key: const Key('wiki-viewer-caption'),
                                  textAlign: TextAlign.center,
                                  style: UiText.sans(
                                    13,
                                    color: _ink,
                                    height: 1.5,
                                  ),
                                ),
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
