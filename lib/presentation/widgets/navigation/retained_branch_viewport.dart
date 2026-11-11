import 'package:flutter/widgets.dart';

/// Keeps an inactive route alive without laying it out for every window resize.
/// The branch receives the current viewport again as soon as it becomes active.
class RetainedBranchViewport extends StatefulWidget {
  const RetainedBranchViewport({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<RetainedBranchViewport> createState() => _RetainedBranchViewportState();
}

class _RetainedBranchViewportState extends State<RetainedBranchViewport> {
  BoxConstraints? _constraints;
  MediaQueryData? _media;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.active || _constraints == null) {
          _constraints = constraints;
          _media = media;
        }
        final viewport = _constraints!;
        return TickerMode(
          enabled: widget.active,
          child: ConstraintsTransformBox(
            alignment: Alignment.topLeft,
            constraintsTransform: (_) => viewport,
            child: MediaQuery(data: _media!, child: widget.child),
          ),
        );
      },
    );
  }
}
