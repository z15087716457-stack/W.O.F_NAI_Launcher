import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../core/utils/localization_extension.dart';
import 'library_icon.dart';
import 'library_status_colors.dart';
import '../../themes/studio_typography.dart';

BoxDecoration librarySelectionDecoration(ThemeData theme) => BoxDecoration(
  borderRadius: BorderRadius.circular(10),
  boxShadow: [
    BoxShadow(
      color: theme.colorScheme.primary.withValues(alpha: .16),
      spreadRadius: 5,
    ),
    BoxShadow(color: theme.colorScheme.primary, spreadRadius: 2),
  ],
);

class LibraryHoverActionBar extends StatelessWidget {
  const LibraryHoverActionBar({super.key, required this.children, this.backgroundColor});
  final Color? backgroundColor;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 3),
          color: backgroundColor ?? Colors.black.withValues(alpha: .78),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white, size: 13),
          child: DefaultTextStyle(
            style: StudioTypography.body.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            child: Row(children: children),
          ),
        ),
      ),
    ),
  );
}

class LibraryCard extends StatefulWidget {
  const LibraryCard({
    super.key,
    this.thumbnail,
    required this.title,
    this.trailingBadge,
    this.metaLine,
    this.isSelected = false,
    this.isInGeneration = false,
    this.isFavorite = false,
    this.bundleCount = 0,
    this.bundleBackThumbnails = const [],
    this.checkbox,
    this.hoverActions,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTapDown,
    this.onFavoriteToggle,
    this.hasError = false,
    this.onLongPress,
    this.onRetry,
    this.forceHover = false,
    this.imageAlignment = Alignment.center,
  });
  final Uint8List? thumbnail;
  final String title;
  final Widget? trailingBadge, metaLine, hoverActions;
  final bool isSelected, isInGeneration, isFavorite, hasError, forceHover;
  final int bundleCount;
  final List<Uint8List> bundleBackThumbnails;
  final bool? checkbox;
  final VoidCallback? onTap,
      onDoubleTap,
      onFavoriteToggle,
      onLongPress,
      onRetry;
  final GestureTapDownCallback? onSecondaryTapDown;
  final Alignment imageAlignment;
  @override
  State<LibraryCard> createState() => _LibraryCardState();
}

class _LibraryCardState extends State<LibraryCard> {
  bool _hovered = false;
  Widget _image(Uint8List? bytes, {bool back = false}) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: colors.surfaceContainerHighest,
        child: bytes != null && bytes.isNotEmpty
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                alignment: widget.imageAlignment,
                gaplessPlayback: true,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, error, stack) => _placeholder(error: true),
              )
            : _placeholder(error: widget.hasError && !back),
      ),
    );
  }

  Widget _placeholder({required bool error}) => Center(
    child: error
        ? IconButton(
            onPressed: widget.onRetry,
            tooltip: context.l10n.common_retry,
            icon: LibraryIcon(
              'warn',
              size: 24,
              color: Theme.of(context).colorScheme.error,
            ),
          )
        : const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final hover = _hovered || widget.forceHover;
    final shadow = Colors.black.withValues(
      alpha: theme.brightness == Brightness.dark ? .45 : .14,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress,
        onSecondaryTapDown: widget.onSecondaryTapDown,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight.isFinite
                ? math.min(c.maxWidth * 1.25, math.max(0, c.maxHeight - 46))
                : c.maxWidth * 1.25;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: const Key('library-card-image'),
                  height: h.toDouble(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      if (widget.bundleCount > 1)
                        for (final layer in [1, 0])
                          Transform.translate(
                            key: ValueKey('library-card-back-$layer'),
                            offset: Offset(
                              layer == 0 ? 5 : 9,
                              layer == 0 ? -5 : -9,
                            ),
                            child: Transform.rotate(
                              angle: (layer == 0 ? 2.5 : 5) * math.pi / 180,
                              child: Opacity(
                                opacity: layer == 0 ? .85 : .6,
                                child: _image(
                                  widget.bundleBackThumbnails.length > layer
                                      ? widget.bundleBackThumbnails[layer]
                                      : null,
                                  back: true,
                                ),
                              ),
                            ),
                          ),
                      AnimatedContainer(
                        key: const Key('library-card-selection'),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 120),
                        decoration: widget.isSelected
                            ? librarySelectionDecoration(theme)
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: hover
                                    ? [
                                        BoxShadow(
                                          color: shadow,
                                          blurRadius: 26,
                                          offset: const Offset(0, 10),
                                        ),
                                      ]
                                    : null,
                              ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _image(widget.thumbnail),
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: colors.onSurface.withValues(
                                      alpha: .07,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.checkbox != null)
                        Positioned(
                          left: 7,
                          top: 7,
                          child: Container(
                            key: const Key('library-card-checkbox'),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.checkbox!
                                  ? colors.primary
                                  : Colors.black.withValues(alpha: .22),
                              border: Border.all(
                                width: 2,
                                color: widget.checkbox!
                                    ? colors.primary
                                    : Colors.white,
                              ),
                            ),
                            child: widget.checkbox!
                                ? const Center(
                                    child: LibraryIcon(
                                      'check',
                                      size: 12,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : null,
                          ),
                        )
                      else if (widget.isInGeneration)
                        Positioned(
                          left: 7,
                          top: 7,
                          child: Container(
                            key: const Key('library-card-in-generation'),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LibraryIcon(
                                  'check',
                                  size: 10,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.library_inGeneration,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.isFavorite || hover)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Material(
                            color: Colors.white.withValues(alpha: .94),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: widget.onFavoriteToggle,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                key: const Key('library-card-favorite'),
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: LibraryIcon(
                                    'star',
                                    size: 13,
                                    filled: widget.isFavorite,
                                    color: widget.isFavorite
                                        ? LibraryStatusColors(theme).favorite
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.bundleCount > 1)
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: Container(
                            key: const Key('library-card-bundle'),
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .72),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LibraryIcon(
                                  'layers',
                                  size: 11,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.bundleCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (hover && widget.hoverActions != null)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: widget.hoverActions!,
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'HarmonyOS Sans SC',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            if (widget.trailingBadge != null) ...[
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: c.maxWidth * .65,
                                ),
                                child: widget.trailingBadge!,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (widget.metaLine != null)
                          DefaultTextStyle(
                            style: TextStyle(
                              fontFamily: 'Geist Mono',
                              fontFamilyFallback: const [
                                'HarmonyOS Sans SC',
                                'Pretendard',
                              ],
                              fontSize: 11,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: .7,
                              ),
                              height: 1.4,
                            ),
                            child: widget.metaLine!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
