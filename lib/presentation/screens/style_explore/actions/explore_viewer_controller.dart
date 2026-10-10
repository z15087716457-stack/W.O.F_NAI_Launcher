part of '../ui/explore_candidate_detail_dialog.dart';

abstract class _ExploreViewerController
    extends ConsumerState<ExploreCandidateDetailDialog> {
  late String? _current = widget.candidateIds.isEmpty
      ? null
      : widget.candidateIds[widget.initialIndex.clamp(
          0,
          widget.candidateIds.length - 1,
        )];
  late final _pages = PageController(initialPage: widget.initialIndex);
  final _transforms = <String, TransformationController>{};
  final _fitScales = <String, double>{};
  bool? _manualPanel;
  bool _closing = false;
  TransformationController get _transform =>
      _transforms.putIfAbsent(_current!, TransformationController.new);
  @override
  void dispose() {
    _pages.dispose();
    for (final c in _transforms.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _resolve(ExploreRun run) {
    if (run.candidateById(_current ?? '') != null) return _current;
    final previous = widget.candidateIds.indexOf(_current ?? '');
    for (var i = previous + 1; i < widget.candidateIds.length; i++) {
      if (run.candidateById(widget.candidateIds[i]) != null) {
        return widget.candidateIds[i];
      }
    }
    for (var i = previous - 1; i >= 0; i--) {
      if (run.candidateById(widget.candidateIds[i]) != null) {
        return widget.candidateIds[i];
      }
    }
    return null;
  }

  void _close([String? evolution]) {
    if (_closing) return;
    _closing = true;
    ref.read(exploreFocusedCandidateIdProvider.notifier).state = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId)
        ?.candidateById(_current ?? '')
        ?.id;
    Navigator.of(context).pop(evolution);
  }

  void _jump(List<ExploreCandidate> candidates, int index) {
    if (index < 0 || index >= candidates.length) return;
    setState(() => _current = candidates[index].id);
    if (_pages.hasClients) _pages.jumpToPage(index);
  }

  Future<void> _assign(ExploreRun run, ExploreCandidate c, int number) async {
    final id = number == 0 ? null : run.folders.elementAtOrNull(number - 1)?.id;
    if (number > 0 && id == null) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .assignCandidateFolder(
          run.id,
          c.id,
          number != 0 && c.folderId == id ? null : id,
        );
  }

  void _advance(ExploreRun run, String? folder) {
    if (folder == null) return;
    final visible = [
      for (final id in widget.candidateIds)
        if (run.candidateById(id) case final c?) c,
    ];
    final index = visible.indexWhere((c) => c.id == _current);
    for (var i = index + 1; i < visible.length; i++) {
      if (visible[i].folderId == null) {
        _jump(visible, i);
        return;
      }
    }
  }

  void _zoom(double factor) {
    setState(
      () =>
          _transform.value = _transform.value.clone()
            ..scaleByDouble(factor, factor, 1, 1),
    );
  }

  void _fit() {
    setState(() => _transform.value = Matrix4.identity());
  }

  void _original() {
    final s = 1 / (_fitScales[_current] ?? 1);
    setState(
      () => _transform.value = Matrix4.identity()..scaleByDouble(s, s, 1, 1),
    );
  }

  Future<void> _fullscreen() async {
    try {
      await windowManager.setFullScreen(!await windowManager.isFullScreen());
    } on MissingPluginException {
      // No native window in widget tests.
    }
  }

  void _help() => _showViewerHelp(context);
}
