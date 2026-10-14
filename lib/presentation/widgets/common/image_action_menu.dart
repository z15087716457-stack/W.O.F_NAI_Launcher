import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// A compact image menu shared by generated images and the local gallery.
/// Flutter owns submenu positioning, keyboard traversal and edge avoidance.
class ImageMenuAction<T> {
  const ImageMenuAction({
    this.key,
    required this.label,
    required this.icon,
    this.value,
    this.enabled = true,
    this.destructive = false,
    this.children = const [],
  });

  const ImageMenuAction.divider()
    : key = null,
      label = '',
      icon = Icons.more_horiz,
      value = null,
      enabled = false,
      destructive = false,
      children = const [];

  final Key? key;
  final String label;
  final IconData icon;
  final T? value;
  final bool enabled;
  final bool destructive;
  final List<ImageMenuAction<T>> children;
  bool get isDivider => label.isEmpty;
}

/// Optional visual styles; existing image menus keep their current appearance.
class ImageActionMenuStyle {
  const ImageActionMenuStyle({
    this.menu,
    this.item,
    this.quickAction,
    this.iconSize,
    this.disabledColor,
  });

  final MenuStyle? menu;
  final ButtonStyle? item;
  final ButtonStyle? quickAction;
  final double? iconSize;
  final Color? disabledColor;
}

class ImageActionMenu {
  const ImageActionMenu._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Offset position,
    required List<ImageMenuAction<T>> actions,
    List<ImageMenuAction<T>> quickActions = const [],
    double? width = 248,
    ImageActionMenuStyle? appearance,
  }) async {
    final overlay = Navigator.of(context).overlay!;
    final box = overlay.context.findRenderObject()! as RenderBox;
    final route = _ImageMenuRoute<T>(
      position: box.globalToLocal(position),
      actions: actions,
      quickActions: quickActions,
      width: width,
      appearance: appearance,
      barrierText: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    final result = await Navigator.of(context).push<T>(route);
    await route.completed;
    return result;
  }
}

class _ImageMenuRoute<T> extends PopupRoute<T> {
  _ImageMenuRoute({
    required this.position,
    required this.actions,
    required this.quickActions,
    required this.width,
    required this.appearance,
    required this.barrierText,
  });
  final Offset position;
  final List<ImageMenuAction<T>> actions;
  final List<ImageMenuAction<T>> quickActions;
  final double? width;
  final ImageActionMenuStyle? appearance;
  final String barrierText;
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => barrierText;
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Duration get reverseTransitionDuration => Duration.zero;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _ImageMenu<T>(route: this);
}

class _ImageMenu<T> extends StatefulWidget {
  const _ImageMenu({required this.route});
  final _ImageMenuRoute<T> route;
  @override
  State<_ImageMenu<T>> createState() => _ImageMenuState<T>();
}

class _ImageMenuState<T> extends State<_ImageMenu<T>> {
  final _controller = MenuController();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.open(position: widget.route.position);
    });
  }

  void _select(T? value) {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop(value);
  }

  MenuStyle _menuStyle({double? width = 248}) {
    final colors = Theme.of(context).colorScheme;
    final base = MenuStyle(
      alignment: Alignment.topLeft,
      backgroundColor: WidgetStatePropertyAll(colors.surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(4),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: .16)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      minimumSize: WidgetStatePropertyAll(Size(width ?? 0, 0)),
      maximumSize: WidgetStatePropertyAll(Size(width ?? 320, double.infinity)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .4)),
        ),
      ),
    );
    return widget.route.appearance?.menu?.merge(base) ?? base;
  }

  Widget _item(ImageMenuAction<T> action, {bool quick = false}) {
    if (action.isDivider) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Divider(height: 1),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final color = action.destructive ? colors.error : colors.onSurface;
    final base = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, quick ? 36 : 32)),
      fixedSize: WidgetStatePropertyAll(Size(double.infinity, quick ? 36 : 32)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: quick ? 6 : 10, vertical: 6),
      ),
      backgroundColor: quick
          ? WidgetStatePropertyAll(colors.surfaceContainerLow)
          : null,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontSize: quick ? 12 : 13),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? widget.route.appearance?.disabledColor ??
                  Theme.of(context).disabledColor
            : color,
      ),
      overlayColor: WidgetStatePropertyAll(
        colors.onSurface.withValues(alpha: .06),
      ),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final override = quick
        ? widget.route.appearance?.quickAction
        : widget.route.appearance?.item;
    final style = override?.merge(base) ?? base;
    final leading = Icon(
      action.icon,
      size: widget.route.appearance?.iconSize ?? 16,
      color: action.destructive && action.enabled ? colors.error : null,
    );
    final label = Text(
      action.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (action.children.isNotEmpty) {
      return SubmenuButton(
        key: action.key,
        style: style,
        menuStyle: _menuStyle(
          width: 232,
        ).copyWith(alignment: AlignmentDirectional.topEnd),
        useRootOverlay: true,
        leadingIcon: leading,
        menuChildren: [
          for (final child in action.children)
            SizedBox(width: 220, child: _item(child)),
        ],
        child: label,
      );
    }
    return MenuItemButton(
      key: action.key,
      style: style,
      closeOnActivate: false,
      leadingIcon: leading,
      onPressed: action.enabled ? () => _select(action.value) : null,
      child: label,
    );
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    key: const Key('image-action-menu'),
    controller: _controller,
    useRootOverlay: true,
    crossAxisUnconstrained: false,
    style: _menuStyle(width: widget.route.width),
    onClose: () => _select(null),
    menuChildren: [
      if (widget.route.quickActions.isNotEmpty) ...[
        SizedBox(
          width: 236,
          child: Row(
            children: [
              for (final action in widget.route.quickActions)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _item(action, quick: true),
                  ),
                ),
            ],
          ),
        ),
        _item(ImageMenuAction<T>.divider()),
      ],
      ...widget.route.actions.map(_item),
    ],
    child: const SizedBox.expand(),
  );
}
