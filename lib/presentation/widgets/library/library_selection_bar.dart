import 'package:flutter/material.dart';
import '../../../core/utils/localization_extension.dart';
import 'library_icon.dart';

class LibraryAction {
  const LibraryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
    this.key,
  });
  final String label, icon;
  final VoidCallback? onPressed;
  final bool primary, destructive;
  final Key? key;
}

Color libraryBrandColor(ThemeData theme) =>
    theme.filledButtonTheme.style?.backgroundColor?.resolve(const {}) ??
    theme.colorScheme.primary;

class LibraryActionButton extends StatelessWidget {
  const LibraryActionButton({
    super.key,
    required this.action,
    this.iconOnly = false,
    this.dark = false,
    this.bordered = false,
    this.selected = false,
    this.height = 32,
    this.foreground,
  });
  final LibraryAction action;
  final bool iconOnly, dark, bordered, selected;
  final double height;
  final Color? foreground;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final filled = action.primary || selected;
    final compact = height <= 28;
    final radius = compact ? 6.0 : 7.0;
    return Tooltip(
      message: action.label,
      child: TextButton(
        key: action.key,
        onPressed: action.onPressed,
        style: TextButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly
                ? 6
                : compact
                ? 8
                : bordered
                ? 11
                : 10,
          ),
          minimumSize: Size(iconOnly ? 28 : 0, height),
          maximumSize: Size(double.infinity, height),
          backgroundColor: filled
              ? libraryBrandColor(theme)
              : bordered
              ? colors.surfaceContainer
              : Colors.transparent,
          disabledBackgroundColor: filled
              ? libraryBrandColor(theme).withValues(alpha: .45)
              : null,
          foregroundColor: filled
              ? Colors.white
              : foreground ??
                    (action.destructive
                        ? colors.error
                        : dark
                        ? Colors.white
                        : colors.onSurface),
          disabledForegroundColor: filled
              ? Colors.white.withValues(alpha: .7)
              : (foreground ?? (dark ? Colors.white : colors.onSurface))
                    .withValues(alpha: .4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: bordered && !filled
                ? BorderSide(color: colors.outlineVariant)
                : BorderSide.none,
          ),
          textStyle: TextStyle(
            fontFamily: 'HarmonyOS Sans SC',
            fontSize: compact ? 12 : 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LibraryIcon(
              action.icon,
              size: 14,
              strokeWidth: action.icon == 'more'
                  ? 3
                  : action.icon == 'plus'
                  ? 2.4
                  : action.icon == 'check'
                  ? 2.2
                  : 1.8,
            ),
            if (!iconOnly) ...[
              SizedBox(width: compact ? 5 : 6),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LibrarySelectionBar extends StatelessWidget {
  const LibrarySelectionBar({
    super.key,
    required this.selectedCount,
    required this.actions,
    required this.onExit,
    this.onSelectAll,
    this.onInvertSelection,
  });
  final int selectedCount;
  final List<LibraryAction> actions;
  final VoidCallback onExit;
  final VoidCallback? onSelectAll, onInvertSelection;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final label = context.l10n.library_selectedCount(selectedCount);
    double measure(String text, double size) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: 'HarmonyOS Sans SC', fontSize: size),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = p.width;
      p.dispose();
      return width;
    }

    final countWidth = measure(label, 12.5);
    final widths = actions.map((a) => measure(a.label, 12.5) + 40).toList();
    return LayoutBuilder(
      builder: (context, c) {
        final fixed =
            countWidth +
            20 +
            32 +
            18 +
            (onSelectAll == null ? 0 : 32) +
            (onInvertSelection == null ? 0 : 32);
        final full = fixed + widths.fold<double>(0, (a, b) => a + b + 4);
        final width = full.clamp(0, c.maxWidth);
        final visible = <LibraryAction>[], overflow = <LibraryAction>[];
        var used = fixed;
        for (var i = 0; i < actions.length; i++) {
          if (full <= c.maxWidth || used + widths[i] + 4 + 32 <= c.maxWidth) {
            visible.add(actions[i]);
            used += widths[i] + 4;
          } else {
            overflow.add(actions[i]);
          }
        }
        final dark = theme.brightness == Brightness.dark;
        final danger = dark ? const Color(0xFFC80029) : const Color(0xFFFF8A8A);
        Widget separator() => Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.only(left: 6, right: 2),
          color: colors.surface.withValues(alpha: .25),
        );
        final row = <Widget>[];
        for (var i = 0; i < visible.length; i++) {
          final a = visible[i], previous = i == 0 ? null : visible[i - 1];
          if (previous != null &&
              ((previous.primary && !a.primary) ||
                  (a.destructive && !previous.destructive))) {
            row.add(separator());
          }
          row.add(
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: LibraryActionButton(
                action: a,
                foreground: a.destructive ? danger : colors.surface,
              ),
            ),
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.onSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .45 : .14),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            width: width.toDouble(),
            height: 44,
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: IconTheme(
                  data: IconThemeData(color: colors.surface),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (onSelectAll != null)
                        _button(
                          context.l10n.common_selectAll,
                          'check',
                          onSelectAll!,
                          colors.surface,
                        ),
                      if (onInvertSelection != null)
                        _button(
                          context.l10n.library_invertSelection,
                          'swap',
                          onInvertSelection!,
                          colors.surface,
                        ),
                      ...row,
                      if (overflow.isNotEmpty)
                        PopupMenuButton<int>(
                          key: const Key('library-selection-overflow'),
                          tooltip: context.l10n.library_more,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 160),
                          onSelected: (i) => overflow[i].onPressed?.call(),
                          itemBuilder: (_) => [
                            for (var i = 0; i < overflow.length; i++)
                              PopupMenuItem(
                                value: i,
                                enabled: overflow[i].onPressed != null,
                                child: Text(overflow[i].label),
                              ),
                          ],
                          child: SizedBox(
                            width: 28,
                            height: 32,
                            child: Center(
                              child: LibraryIcon(
                                'more',
                                color: colors.surface,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      _button(
                        context.l10n.common_close,
                        'x',
                        onExit,
                        colors.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _button(String label, String icon, VoidCallback onTap, Color color) =>
      Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: 28,
            height: 32,
            child: Center(child: LibraryIcon(icon, color: color, size: 14)),
          ),
        ),
      );
}
