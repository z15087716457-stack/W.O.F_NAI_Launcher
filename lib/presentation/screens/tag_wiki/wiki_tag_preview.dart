import 'dart:async';
import 'dart:math' as math;

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../core/autocomplete/completion_models.dart';

/// Hosts the single tag preview overlay shared by body links, chip clouds and
/// the co-occurrence grid. Hovering a target for 300ms opens the card below
/// the pointer; leaving both the target and the card for 200ms closes it.
class WikiTagPreviewHost {
  WikiTagPreviewHost({required this.context, required this.builder});

  /// Build context that owns the overlay (the screen's).
  final BuildContext context;

  /// Builds the card content for the hovered candidate.
  final Widget Function(CompletionCandidate candidate) builder;

  static const _showDelay = Duration(milliseconds: 300);
  static const _hideDelay = Duration(milliseconds: 200);
  static const _cardWidth = 260.0;
  // Estimated height used only to decide whether the card flips above the
  // pointer; the card anchors its bottom edge when it flips, so the real
  // height does not matter.
  static const _estimatedHeight = 190.0;

  OverlayEntry? _entry;
  Timer? _showTimer;
  Timer? _hideTimer;
  CompletionCandidate? _candidate;
  Offset _position = Offset.zero;

  bool get isShowing => _entry != null;

  /// Call from MouseRegion/MarkdownBody hover handlers.
  void hover(CompletionCandidate candidate, Offset position) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_entry != null) {
      if (_candidate != candidate || _position != position) {
        _candidate = candidate;
        _position = position;
        _entry!.markNeedsBuild();
      }
      return;
    }
    _candidate = candidate;
    _position = position;
    _showTimer ??= Timer(_showDelay, _insert);
  }

  /// Call when the pointer leaves a previewable target.
  void leave() {
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry == null) return;
    _hideTimer ??= Timer(_hideDelay, dismiss);
  }

  /// The card itself calls this on enter so the pointer may move inside.
  void enterCard() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void dismiss() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _showTimer = null;
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
    _candidate = null;
  }

  void dispose() => dismiss();

  void _insert() {
    _showTimer = null;
    if (!context.mounted) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
  }

  Widget _buildOverlay(BuildContext context) {
    final candidate = _candidate;
    if (candidate == null) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final left = (_position.dx + 10)
        .clamp(8.0, math.max(8.0, size.width - _cardWidth - 8))
        .toDouble();
    final showBelow = _position.dy + 6 + _estimatedHeight <= size.height;
    return Positioned(
      left: left,
      top: showBelow ? _position.dy + 6 : null,
      bottom: showBelow ? null : size.height - _position.dy + 6,
      width: _cardWidth,
      child: MouseRegion(
        onEnter: (_) => enterCard(),
        onExit: (_) => leave(),
        child: builder(candidate),
      ),
    );
  }
}
