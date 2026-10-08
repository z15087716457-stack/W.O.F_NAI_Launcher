import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/shortcuts/default_shortcuts.dart';
import '../shortcuts/shortcut_aware_widget.dart';
import '../navigation/window_chrome_layout.dart';
import 'library_icon.dart';
import 'library_shell.dart';

enum LibraryCardSize {
  small(140),
  medium(180),
  large(240);

  const LibraryCardSize(this.width);
  final double width;
  static Future<LibraryCardSize> load(String key) async {
    final value = (await SharedPreferences.getInstance()).getString(key);
    return values.where((e) => e.name == value).firstOrNull ?? medium;
  }

  Future<void> save(String key) async =>
      (await SharedPreferences.getInstance()).setString(key, name);
}

/// Includes the grid and inspector so search works from either pane.
class LibrarySearchScope extends StatelessWidget {
  const LibrarySearchScope({
    super.key,
    required this.child,
    required this.focusNode,
    required this.controller,
    required this.onChanged,
  });
  final Widget child;
  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => ShortcutAwareWidget(
    contextType: ShortcutContext.gallery,
    shortcuts: {ShortcutIds.focusSearch: () => focusNode.requestFocus()},
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          if (FocusManager.instance.primaryFocus?.context?.widget
              is! EditableText) {
            focusNode.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (focusNode.hasFocus) {
            controller.clear();
            onChanged('');
          }
        },
      },
      child: child,
    ),
  );
}

class LibraryNavHeader extends StatelessWidget {
  const LibraryNavHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });
  final String title;
  final Widget? icon, trailing;
  @override
  Widget build(BuildContext context) => WindowHeaderDragSurface(
    child: Container(
      height: LibraryShell.headerHeight,
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Expanded(
            child: IgnorePointer(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}

class LibraryNavItem extends StatelessWidget {
  const LibraryNavItem({
    super.key,
    required this.title,
    this.icon,
    this.count,
    this.isSelected = false,
    this.isDropTarget = false,
    this.onTap,
    this.indent = 0,
  });
  final String title;
  final Widget? icon;
  final int? count;
  final bool isSelected, isDropTarget;
  final VoidCallback? onTap;
  final double indent;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isDropTarget
            ? colors.primary.withValues(alpha: .1)
            : isSelected
            ? colors.surfaceContainerHighest
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: isDropTarget
              ? BorderSide(color: colors.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 32,
            padding: EdgeInsets.only(left: 10 + indent, right: 10),
            child: Row(
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: 15,
                      color: colors.onSurfaceVariant,
                    ),
                    child: icon!,
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'Geist Mono',
                      fontSize: 11.5,
                      color: colors.onSurfaceVariant.withValues(alpha: .7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LibraryNavSection extends StatelessWidget {
  const LibraryNavSection({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.only(left: 18, right: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: .7),
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class LibraryToolbar extends StatefulWidget {
  const LibraryToolbar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.cardSize,
    required this.onCardSizeChanged,
    this.searchKey,
    this.searchFocusNode,
    this.sortBuilder,
    this.trailingBuilder,
    this.leading,
    this.reserveWindowButtons = false,
  });
  final TextEditingController searchController;
  final String searchHint;
  final Key? searchKey;
  final FocusNode? searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final LibraryCardSize cardSize;
  final ValueChanged<LibraryCardSize> onCardSizeChanged;
  final Widget Function(bool compact)? sortBuilder;
  final List<Widget> Function(bool compact)? trailingBuilder;
  final Widget? leading;
  final bool reserveWindowButtons;
  @override
  State<LibraryToolbar> createState() => _LibraryToolbarState();
}

class _LibraryToolbarState extends State<LibraryToolbar> {
  final _searchFocus = FocusNode();
  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Container(
      height: LibraryShell.headerHeight,
      padding: EdgeInsets.only(
        left: 18,
        right: widget.reserveWindowButtons ? 150 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 890;
          return Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: TextField(
                      key: widget.searchKey,
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode ?? _searchFocus,
                      onChanged: widget.onSearchChanged,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        constraints: const BoxConstraints.tightFor(height: 36),
                        isDense: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: LibraryIcon('search', size: 15),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 35,
                          minHeight: 15,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.sortBuilder != null) ...[
                widget.sortBuilder!(compact),
                const SizedBox(width: 8),
              ],
              _sizeSegment(context),
              const SizedBox(width: 8),
              ...(widget.trailingBuilder?.call(compact) ?? const <Widget>[]),
            ],
          );
        },
      ),
    );
    return widget.searchFocusNode == null
        ? LibrarySearchScope(
            focusNode: _searchFocus,
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            child: content,
          )
        : content;
  }

  Widget _sizeSegment(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labels = [
      context.l10n.library_sizeSmall,
      context.l10n.library_sizeMedium,
      context.l10n.library_sizeLarge,
    ];
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final size in LibraryCardSize.values)
            Material(
              color: widget.cardSize == size
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? colors.surfaceContainerHigh
                        : colors.surfaceContainer)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                key: ValueKey('library-card-size-${size.name}'),
                borderRadius: BorderRadius.circular(5),
                onTap: () => widget.onCardSizeChanged(size),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      labels[size.index],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: widget.cardSize == size
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: widget.cardSize == size
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LibraryFilterRow extends StatelessWidget {
  const LibraryFilterRow({super.key, required this.chips, this.countText});
  final List<Widget> chips;
  final String? countText;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: LibraryShell.filterHeight,
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  chips[i],
                ],
              ],
            ),
          ),
        ),
        if (countText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              countText!,
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: .7),
              ),
            ),
          ),
      ],
    ),
  );
}
