part of 'explore_candidate_card.dart';

abstract class _ExploreCardController
    extends ConsumerState<ExploreCandidateCard> {
  bool _hover = false;
  Future<void> _heart() => ref
      .read(exploreRunListNotifierProvider.notifier)
      .updateReview(
        widget.run.id,
        widget.candidate.id,
        heart: !widget.candidate.review.heart,
      );

  Future<void> _more(Offset position) async {
    final l10n = context.l10n;
    final candidate = widget.candidate;
    final box = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & box.size,
      ),
      items: [
        PopupMenuItem(
          value: 'apply',
          child: Text(l10n.styleExplore_applyToEditor),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text(l10n.styleExplore_copyArtists),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: candidate.generation.filePath != null,
          child: Text(
            l10n.styleExplore_deleteImage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'apply':
        await ExploreCandidateActions.fixateAsTemplate(
          context,
          ref,
          candidate: candidate,
        );
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: exploreParentStringFor(candidate)),
        );
      case 'delete':
        await ExploreCandidateActions.deleteImage(
          context,
          ref,
          runId: widget.run.id,
          candidate: candidate,
        );
    }
  }
}
