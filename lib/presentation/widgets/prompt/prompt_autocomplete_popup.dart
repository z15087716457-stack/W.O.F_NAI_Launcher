import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/autocomplete/prompt_autocomplete_controller.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_popover.dart';
import '../../ui/kit/ui_text.dart';
import '../autocomplete/tag_candidate_title.dart';

/// B06 输入补全候选层：跟在当前词下方，不抢焦点；鼠标点选或 ↑↓ + Tab/Enter（键盘由绑定处理）。
Widget promptAutocompletePopupBuilder(
  BuildContext context,
  PromptAutocompleteController controller,
  ValueChanged<int> accept,
  Widget child,
) => PromptAutocompletePopup(
  controller: controller,
  onAccept: accept,
  child: child,
);

class PromptAutocompletePopup extends StatefulWidget {
  const PromptAutocompletePopup({
    super.key,
    required this.controller,
    required this.onAccept,
    required this.child,
  });

  static const width = 300.0;
  static const rowHeight = 30.0;
  static const maxRows = 8;

  final PromptAutocompleteController controller;
  final ValueChanged<int> onAccept;
  final Widget child;

  @override
  State<PromptAutocompletePopup> createState() =>
      _PromptAutocompletePopupState();
}

class _PromptAutocompletePopupState extends State<PromptAutocompletePopup> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _childKey = GlobalKey();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void didUpdateWidget(covariant PromptAutocompletePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _changed();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _scroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final visible = widget.controller.value.visible;
    if (visible && !_portal.isShowing) {
      _portal.show();
    } else if (!visible && _portal.isShowing) {
      _portal.hide();
    }
    if (visible) {
      setState(() {});
      _keepSelectedVisible();
    }
  }

  void _keepSelectedVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final i = widget.controller.value.selectedIndex;
      const h = PromptAutocompletePopup.rowHeight;
      final top = i * h, bottom = top + h;
      final pos = _scroll.position;
      if (top < pos.pixels) {
        _scroll.jumpTo(top);
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        _scroll.jumpTo(bottom - pos.viewportDimension);
      }
    });
  }

  /// 当前词左下角相对编辑区的位置；找不到可编辑渲染对象时放在编辑区底部。
  Offset _anchor() {
    final root = _childKey.currentContext?.findRenderObject();
    if (root is! RenderBox || !root.hasSize) return Offset.zero;
    RenderEditable? editable;
    void visit(RenderObject o) {
      if (editable != null) return;
      if (o is RenderEditable) {
        editable = o;
        return;
      }
      o.visitChildren(visit);
    }

    visit(root);
    final e = editable;
    if (e == null || !e.hasSize) return Offset(0, root.size.height);
    final offset = widget.controller.value.anchorTextOffset;
    final caret = e.getLocalRectForCaret(TextPosition(offset: offset));
    final local = root.globalToLocal(e.localToGlobal(caret.bottomLeft));
    final maxX = (root.size.width - PromptAutocompletePopup.width).clamp(
      0.0,
      double.infinity,
    );
    return Offset(local.dx.clamp(0.0, maxX), local.dy + 4);
  }

  static String _count(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(1)}m'
      : n >= 1000
      ? '${(n / 1000).toStringAsFixed(1)}k'
      : '$n';

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          final state = widget.controller.value;
          if (!state.visible) return const SizedBox.shrink();
          final c = context.ui;
          final rows = state.candidates.length.clamp(
            1,
            PromptAutocompletePopup.maxRows,
          );
          return Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _link,
              offset: _anchor(),
              // 点候选不让编辑框失焦（失焦会清掉候选）。
              child: TextFieldTapRegion(
                child: UiPopoverSurface(
                  key: const Key('prompt-autocomplete'),
                  width: PromptAutocompletePopup.width,
                  radius: 8,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SizedBox(
                    height: rows * PromptAutocompletePopup.rowHeight,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.zero,
                      itemExtent: PromptAutocompletePopup.rowHeight,
                      itemCount: state.candidates.length,
                      itemBuilder: (context, i) {
                        final cand = state.candidates[i];
                        final selected = i == state.selectedIndex;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            key: Key('prompt-autocomplete-$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onAccept(i),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? c.hover : null,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                spacing: 6,
                                children: [
                                  Expanded(
                                    child: TagCandidateTitle(
                                      title: TagNormalizer.toDisplay(
                                        cand.canonicalTag,
                                      ),
                                      category: cand.category,
                                      style: UiText.sans(
                                        12.5,
                                        color: c.ink,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (cand.translation case final tr?
                                      when tr.isNotEmpty)
                                    Flexible(
                                      child: Text(
                                        tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: UiText.sans(
                                          11.5,
                                          color: c.muted,
                                        ),
                                      ),
                                    ),
                                  if (cand.postCount > 0)
                                    Text(
                                      _count(cand.postCount),
                                      style: UiText.mono(10.5, color: c.faint),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: KeyedSubtree(key: _childKey, child: widget.child),
      ),
    );
  }
}
