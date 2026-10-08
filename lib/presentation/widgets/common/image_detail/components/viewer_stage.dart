import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'viewer_icon.dart';

/// Reusable stage for images, videos, or other page content. Page adapters own
/// their data, transformations, and actions; this widget only arranges slots.
class ViewerStage extends StatefulWidget {
  const ViewerStage({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.pageBuilder,
    required this.topBar,
    this.pageController,
    this.filmstrip,
    this.panel,
    this.panelVisible,
    this.onTogglePanel,
    this.extraShortcuts = const {},
    this.handleInfoShortcut = true,
    this.onEscape,
    this.previousLabel = 'Previous',
    this.nextLabel = 'Next',
  }) : assert(itemCount > 0),
       assert(currentIndex >= 0 && currentIndex < itemCount);
  final int itemCount, currentIndex;
  final ValueChanged<int> onIndexChanged;
  final IndexedWidgetBuilder pageBuilder;
  final Widget topBar;
  final PageController? pageController;
  final Widget? filmstrip, panel;

  /// Null uses the responsive default: open dock, closed drawer.
  final bool? panelVisible;
  final VoidCallback? onTogglePanel, onEscape;
  final Map<ShortcutActivator, VoidCallback> extraShortcuts;
  final bool handleInfoShortcut;
  final String previousLabel, nextLabel;

  static const topBarHeight = 52.0, filmstripHeight = 82.0;
  static const panelWidth = 360.0, drawerWidth = 340.0;
  static const background = Colors.black;
  static bool isNarrow(double width) => width - panelWidth < 760;

  @override
  State<ViewerStage> createState() => _ViewerStageState();
}

class _ViewerStageState extends State<ViewerStage> {
  late final PageController _ownedController;
  PageController get _controller => widget.pageController ?? _ownedController;
  bool? _manualPanelVisible;
  bool _narrow = false;
  int _hoverQuarter = 0;
  bool get _visible =>
      widget.panel != null &&
      (widget.panelVisible ?? _manualPanelVisible ?? !_narrow);

  @override
  void initState() {
    super.initState();
    _ownedController = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant ViewerStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageController == null &&
        widget.currentIndex != oldWidget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _controller.hasClients &&
            _controller.page?.round() != widget.currentIndex) {
          _controller.jumpToPage(widget.currentIndex);
        }
      });
    }
  }

  void _togglePanel() {
    if (widget.onTogglePanel != null) {
      widget.onTogglePanel!();
    } else {
      setState(() => _manualPanelVisible = !_visible);
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.itemCount || !_controller.hasClients) {
      return;
    }
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    for (final shortcut in widget.extraShortcuts.entries) {
      if (shortcut.key.accepts(event, HardwareKeyboard.instance)) {
        shortcut.value();
        return KeyEventResult.handled;
      }
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _narrow && _visible) {
      _togglePanel();
    } else if (key == LogicalKeyboardKey.escape && widget.onEscape != null) {
      widget.onEscape!();
    } else if (key == LogicalKeyboardKey.keyI &&
        widget.handleInfoShortcut &&
        widget.panel != null &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      _togglePanel();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _goTo(widget.currentIndex - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _goTo(widget.currentIndex + 1);
    } else if (key == LogicalKeyboardKey.home) {
      _goTo(0);
    } else if (key == LogicalKeyboardKey.end) {
      _goTo(widget.itemCount - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _narrow = ViewerStage.isNarrow(constraints.maxWidth);
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200);
      final stage = Column(
        children: [
          SizedBox(
            key: const Key('viewer-top-slot'),
            height: ViewerStage.topBarHeight,
            child: widget.topBar,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => MouseRegion(
                onHover: (event) {
                  final q = event.localPosition.dx < box.maxWidth / 4
                      ? -1
                      : event.localPosition.dx > box.maxWidth * 3 / 4
                      ? 1
                      : 0;
                  if (q != _hoverQuarter) setState(() => _hoverQuarter = q);
                },
                onExit: (_) {
                  if (_hoverQuarter != 0) setState(() => _hoverQuarter = 0);
                },
                child: Stack(
                  key: const Key('viewer-image-area'),
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(72, 8, 72, 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: PageView.builder(
                          key: const Key('viewer-pages'),
                          controller: _controller,
                          itemCount: widget.itemCount,
                          onPageChanged: widget.onIndexChanged,
                          itemBuilder: widget.pageBuilder,
                        ),
                      ),
                    ),
                    if (widget.currentIndex > 0)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(child: _arrow(false)),
                      ),
                    if (widget.currentIndex < widget.itemCount - 1)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(child: _arrow(true)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.filmstrip != null)
            SizedBox(
              key: const Key('viewer-filmstrip-slot'),
              height: ViewerStage.filmstripHeight,
              child: ClipRect(child: widget.filmstrip!),
            ),
        ],
      );
      return Focus(
        autofocus: true,
        onKeyEvent: _key,
        child: ColoredBox(
          color: ViewerStage.background,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Row(
                children: [
                  Expanded(child: stage),
                  if (!_narrow && widget.panel != null)
                    AnimatedContainer(
                      key: const Key('viewer-panel-dock'),
                      duration: duration,
                      curve: Curves.easeInOut,
                      width: _visible ? ViewerStage.panelWidth : 0,
                      child: ClipRect(
                        child: OverflowBox(
                          minWidth: ViewerStage.panelWidth,
                          maxWidth: ViewerStage.panelWidth,
                          alignment: Alignment.topLeft,
                          child: IgnorePointer(
                            ignoring: !_visible,
                            child: ExcludeSemantics(
                              excluding: !_visible,
                              child: widget.panel!,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_narrow && widget.panel != null && _visible)
                Positioned(
                  key: const Key('viewer-panel-drawer'),
                  top: ViewerStage.topBarHeight,
                  bottom: 0,
                  right: 0,
                  width: ViewerStage.drawerWidth,
                  child: TweenAnimationBuilder<double>(
                    duration: duration,
                    tween: Tween(begin: ViewerStage.drawerWidth, end: 0),
                    builder: (context, offset, child) => Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 20,
                            offset: Offset(-6, 0),
                          ),
                        ],
                      ),
                      child: widget.panel!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _arrow(bool next) => Tooltip(
    message: next ? widget.nextLabel : widget.previousLabel,
    child: Material(
      key: Key(next ? 'viewer-next' : 'viewer-previous'),
      shape: const CircleBorder(),
      color: Colors.white.withValues(
        alpha: _hoverQuarter == (next ? 1 : -1) ? .18 : .08,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _goTo(widget.currentIndex + (next ? 1 : -1)),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: ViewerIcon(
              next ? 'chevR' : 'chevL',
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }
}
