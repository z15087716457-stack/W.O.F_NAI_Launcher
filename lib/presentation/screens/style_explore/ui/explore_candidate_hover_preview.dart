import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../actions/explore_candidate_hover_session.dart';
import '../actions/explore_hover_data.dart';
export '../actions/explore_candidate_hover_session.dart';
export '../actions/explore_hover_data.dart';

class ExploreCandidateHoverThumb extends StatefulWidget {
  const ExploreCandidateHoverThumb({
    super.key,
    required this.session,
    required this.candidateId,
    required this.badgeText,
    this.filePath,
    this.imageBuilder,
    required this.child,
  });
  final ExploreCandidateHoverSession session;
  final String candidateId, badgeText;
  final String? filePath;
  final Widget Function(BuildContext, String)? imageBuilder;
  final Widget child;
  @override
  State<ExploreCandidateHoverThumb> createState() => _HoverAnchorState();
}

class _HoverAnchorState extends State<ExploreCandidateHoverThumb> {
  ExploreCandidateHoverInfo get _info => ExploreCandidateHoverInfo(
    candidateId: widget.candidateId,
    anchorContext: context,
    badgeText: widget.badgeText,
    filePath: widget.filePath,
    imageBuilder: widget.imageBuilder,
  );
  @override
  void didUpdateWidget(covariant ExploreCandidateHoverThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidateId != widget.candidateId ||
        oldWidget.filePath != widget.filePath ||
        oldWidget.badgeText != widget.badgeText) {
      widget.session.updateHover(oldWidget.candidateId, _info);
    }
  }

  @override
  void dispose() {
    widget.session.remove(widget.candidateId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => widget.session.hoverEnter(_info),
    onExit: (_) => widget.session.hoverExit(widget.candidateId),
    child: Listener(
      onPointerDown: (_) => widget.session.dismissPreview(),
      child: widget.child,
    ),
  );
}
