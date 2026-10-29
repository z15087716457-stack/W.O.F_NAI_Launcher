import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// One received snapshot, with a local display cursor shared by count and paint.
class AgentStreamProgress extends ChangeNotifier {
  AgentStreamProgress(TickerProvider vsync, String initial)
    : _animation = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 100),
      ) {
    _animation.addListener(notifyListeners);
    update(initial, animate: false);
  }

  final AnimationController _animation;
  String text = '';
  List<int> _offsets = [0], _counts = [0];
  int _from = 0;

  int get _index =>
      (_from + (_offsets.length - 1 - _from) * _animation.value).floor();
  int get visibleOffset => _offsets[_index];
  int get visibleCharacters => _counts[_index];
  int get fromOffset => _offsets[_from];

  void update(String value, {required bool animate}) {
    final shown = visibleOffset;
    final append = value.startsWith(text);
    text = value;
    _offsets = [0];
    _counts = [0];
    for (final character in value.characters) {
      _offsets.add(_offsets.last + character.length);
      _counts.add(_counts.last + character.runes.length);
    }
    _from = append ? _offsets.indexWhere((offset) => offset >= shown) : 0;
    _animation.stop();
    if (animate && append && _from < _offsets.length - 1) {
      _animation.forward(from: 0);
    } else {
      _from = _offsets.length - 1;
      _animation.value = 1;
      notifyListeners();
    }
  }

  void finish() {
    _animation.stop();
    _animation.value = 1;
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}

/// Keeps native Text selection/layout; animation only invalidates its paint clip.
class AgentStreamReveal extends SingleChildRenderObjectWidget {
  const AgentStreamReveal({
    super.key,
    required this.progress,
    required super.child,
  });

  final AgentStreamProgress progress;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStreamReveal(progress);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderStreamReveal).progress = progress;
  }
}

class _RenderStreamReveal extends RenderProxyBox {
  _RenderStreamReveal(this._progress);
  AgentStreamProgress _progress;
  RenderParagraph? _paragraph;
  Path _prefix = Path();
  Offset _paragraphOffset = Offset.zero;

  set progress(AgentStreamProgress value) {
    if (!identical(value, _progress)) {
      if (attached) _progress.removeListener(markNeedsPaint);
      _progress = value;
      if (attached) _progress.addListener(markNeedsPaint);
    }
    // Called on received snapshots, never on the animation's per-frame ticks.
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    _paragraph = null;
    void findParagraph(RenderObject object) {
      if (_paragraph != null) return;
      if (object is RenderParagraph) {
        _paragraph = object;
      } else {
        object.visitChildren(findParagraph);
      }
    }

    child?.visitChildren(findParagraph);
    if (child is RenderParagraph) _paragraph = child as RenderParagraph;
    _prefix = Path();
    final paragraph = _paragraph;
    if (paragraph == null) return;
    _paragraphOffset = MatrixUtils.transformPoint(
      paragraph.getTransformTo(this),
      Offset.zero,
    );
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: _progress.fromOffset),
      boxHeightStyle: ui.BoxHeightStyle.max,
    );
    if (boxes.isEmpty) return;
    final lastTop = boxes.map((box) => box.top).reduce((a, b) => a > b ? a : b);
    _prefix.addRect(
      Rect.fromLTRB(0, 0, size.width, lastTop + _paragraphOffset.dy),
    );
    for (final box in boxes.where((box) => box.top >= lastTop)) {
      _prefix.addRect(box.toRect().shift(_paragraphOffset).inflate(.5));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paragraph = _paragraph;
    if (paragraph == null || _progress.visibleOffset >= _progress.text.length) {
      super.paint(context, offset);
      return;
    }
    final visible = Path()..addPath(_prefix, Offset.zero);
    for (final box in paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: _progress.fromOffset,
        extentOffset: _progress.visibleOffset,
      ),
      boxHeightStyle: ui.BoxHeightStyle.max,
    )) {
      visible.addRect(box.toRect().shift(_paragraphOffset).inflate(.5));
    }
    context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      visible,
      super.paint,
    );
  }
}
