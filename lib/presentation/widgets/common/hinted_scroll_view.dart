import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';

/// A constrained settings viewport with a separate, unobstructed scroll hint.
class HintedScrollView extends StatefulWidget {
  const HintedScrollView({super.key, required this.child});

  final Widget child;

  @override
  State<HintedScrollView> createState() => _HintedScrollViewState();
}

class _HintedScrollViewState extends State<HintedScrollView> {
  static const _hintHeight = 22.0;
  final _scroll = ScrollController();
  bool _overflows = false;
  bool _hasMore = false;
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
    // The hint must not create its own overflow after content shrinks.
    final reservedHeight = _overflows ? _hintHeight : 0.0;
    final overflows = position.maxScrollExtent > reservedHeight + .5;
    final hasMore = overflows && position.extentAfter > .5;
    if (_overflows == overflows && _hasMore == hasMore) return;
    setState(() {
      _overflows = overflows;
      _hasMore = hasMore;
    });
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth != 0 || _refreshPending) return false;
    _refreshPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPending = false;
      _refresh();
    });
    return false;
  }

  void _scrollDown() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    _scroll.animateTo(
      math.min(
        position.maxScrollExtent,
        position.pixels + position.viewportDimension * .7,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: SingleChildScrollView(
              controller: _scroll,
              primary: false,
              child: widget.child,
            ),
          ),
        ),
        if (_overflows)
          Container(
            height: _hintHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0),
                  theme.colorScheme.surface.withValues(alpha: .35),
                ],
              ),
            ),
            child: _hasMore
                ? Center(
                    child: IconButton(
                      key: const ValueKey('settings-scroll-down'),
                      tooltip: context.l10n.localUpscale_scrollDown,
                      onPressed: _scrollDown,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: _hintHeight,
                      ),
                      iconSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
