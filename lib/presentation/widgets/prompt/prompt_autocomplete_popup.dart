import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/text_editing_projection.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/autocomplete/prompt_autocomplete_controller.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_glyph.dart';
import '../../ui/kit/ui_popover.dart';
import '../../ui/kit/ui_text.dart';
import '../autocomplete/tag_category_visuals.dart';

/// B06 输入补全候选层：跟在当前词下方，不抢焦点。
///
/// 左栏是补全候选（标签 · 中文名 · 热度）；**→**（或右键）在右侧打开当前候选的关联标签栏，
/// **←** 关闭回到左栏；关联栏里回车 / 点击追加，可连续加、已加的打勾。左栏点击直接补全。
/// 键盘：↑↓ 在当前栏移动，Tab / Enter 补全或追加，Esc 先关关联栏再关整个（键盘在控制器里处理）。
/// 滚轮只滚候选列表，不带动下面的提示词框。
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

class PromptAutocompletePopup extends ConsumerStatefulWidget {
  const PromptAutocompletePopup({
    super.key,
    required this.controller,
    required this.onAccept,
    required this.child,
  });

  static const width = 300.0;
  static const relatedWidth = 240.0;
  static const maxListHeight = 240.0;

  final PromptAutocompleteController controller;

  /// 关联栏开着时，下标指关联候选（绑定会转给 acceptRelated）。
  final ValueChanged<int> onAccept;
  final Widget child;

  @override
  ConsumerState<PromptAutocompletePopup> createState() =>
      _PromptAutocompletePopupState();
}

class _PromptAutocompletePopupState
    extends ConsumerState<PromptAutocompletePopup> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _childKey = GlobalKey();
  final _scroll = ScrollController();
  final _relatedScroll = ScrollController();
  final _selectedRow = GlobalKey();
  final _selectedRelatedRow = GlobalKey();
  late final String _surface = 'prompt-autocomplete-${identityHashCode(this)}';
  late final AutoTagTranslationController _translation;
  Set<String> _observed = const {};

  @override
  void initState() {
    super.initState();
    _translation = ref.read(autoTagTranslationProvider);
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
    _translation.clearSurface(_surface);
    _scroll.dispose();
    _relatedScroll.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    // 编辑区被卸载时绑定会在 deactivate 里 dismiss：此时正处于构建阶段，
    // 不能直接 show/hide 弹层，挪到这一帧之后。
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
      return;
    }
    final state = widget.controller.value;
    if (state.visible && !_portal.isShowing) {
      _portal.show();
    } else if (!state.visible && _portal.isShowing) {
      _portal.hide();
    }
    _report(state);
    if (state.visible) {
      setState(() {});
      // 锚点依赖编辑区这一帧的排版：排完再定一次位置，避免先贴在行首。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller.value.visible) setState(() {});
      });
    }
  }

  /// 把弹层里的标签报给「自动翻译可见标签」：开关关着时它什么也不做，
  /// 开着才为词典里没有中文名的标签排队翻译（10-27 用户决定：不强制）。
  void _report(PromptAutocompleteState state) {
    final next = state.visible ? state.visibleTags.toSet() : const <String>{};
    if (next.isEmpty && _observed.isEmpty) return;
    final t = _translation;
    for (final tag in _observed.difference(next)) {
      t.observe(surface: _surface, tag: tag, visible: false);
    }
    final names = {
      for (final c in [...state.candidates, ...state.related])
        c.canonicalTag: c.translation,
    };
    for (final tag in next.difference(_observed)) {
      t.observe(
        surface: _surface,
        tag: tag,
        visible: true,
        existingNameZh: names[tag],
      );
    }
    _observed = next;
  }

  void _keepVisible(ScrollController scroll, GlobalKey selected) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = selected.currentContext?.findRenderObject() as RenderBox?;
      if (!scroll.hasClients || row == null) return;
      final viewport = RenderAbstractViewport.of(row);
      final top = viewport.getOffsetToReveal(row, 0).offset;
      // Column 已布局实际行高；下方保留一个完整候选再开始滚动。
      final next = (row.parentData! as FlexParentData).nextSibling;
      final bottom = viewport.getOffsetToReveal(next ?? row, 1).offset;
      final pos = scroll.position;
      final target = top < pos.pixels
          ? top
          : math.max(pos.pixels, math.min(top, bottom));
      final clamped = target.clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (clamped != pos.pixels) {
        scroll.jumpTo(clamped);
      }
    });
  }

  /// 在同一个 Overlay 坐标系里留出边距，空间不足时向上展开。
  ({Offset offset, bool above, double height}) _placement(
    RenderBox overlay,
    Size viewport,
    double popupWidth,
  ) {
    final root = _childKey.currentContext!.findRenderObject()! as RenderBox;
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
    final field = e ?? root;
    final caret = e == null
        ? Rect.fromLTWH(0, root.size.height, 0, 0)
        : e.getLocalRectForCaret(
            displayPositionForEditable(
              e,
              TextPosition(offset: widget.controller.value.anchorTextOffset),
            ),
          );
    Offset point(Offset p) => overlay.globalToLocal(field.localToGlobal(p));
    final top = point(caret.topLeft), bottom = point(caret.bottomLeft);
    final below = math.max(0.0, viewport.height - bottom.dy - 12);
    final above = math.max(0.0, top.dy - 12);
    final opensAbove = below < 300 && above > below;
    final anchor = Offset(
      bottom.dx.clamp(8.0, math.max(8.0, viewport.width - popupWidth - 8)),
      opensAbove ? top.dy - 4 : bottom.dy + 4,
    );
    return (
      offset: root.globalToLocal(overlay.localToGlobal(anchor)),
      above: opensAbove,
      height: opensAbove ? above : below,
    );
  }

  static String _count(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(1)}m'
      : n >= 1000
      ? '${(n / 1000).toStringAsFixed(1)}k'
      : '$n';

  String? _zh(CompletionCandidate cand) {
    final tr = _translation.nameFor(cand.canonicalTag) ?? cand.translation;
    return tr == null || tr.trim().isEmpty ? null : tr;
  }

  @override
  Widget build(BuildContext context) {
    // 自动翻译回来的中文名也要刷新到弹层上。
    if (widget.controller.value.visible) ref.watch(autoTagTranslationProvider);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _overlay,
        child: KeyedSubtree(key: _childKey, child: widget.child),
      ),
    );
  }

  Widget _overlay(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topLeft,
        child: _popup(context, constraints.biggest),
      ),
    ),
  );

  Widget _popup(BuildContext context, Size viewport) {
    final state = widget.controller.value;
    if (!state.visible) return const SizedBox.shrink();
    final c = context.ui;
    final l = context.l10n;
    final related = state.relatedFor;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    // 首次宽度容下整行快捷键提示，不随候选内容或选中项改变。
    final mainWidth = math.max(
      PromptAutocompletePopup.width,
      (TextPainter.computeWidth(
                text: TextSpan(
                  text: l.prompt_autocompleteHint,
                  style: _Footer.textStyle,
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                locale: Localizations.localeOf(context),
              ) +
              _Footer.padding.horizontal)
          .ceilToDouble(),
    );
    final desiredWidth =
        mainWidth +
        (related == null ? 0 : PromptAutocompletePopup.relatedWidth + 1) +
        2;
    final width = math.min(desiredWidth, viewport.width - 16);
    final stacked = related != null && width - 2 <= 420;
    final placement = _placement(overlay, viewport, width);
    _keepVisible(_scroll, _selectedRow);
    if (related != null) _keepVisible(_relatedScroll, _selectedRelatedRow);

    Widget column({
      required Key key,
      required String title,
      String? tail,
      required Widget body,
    }) => Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 5),
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                title,
                style: UiText.sans(
                  11,
                  weight: FontWeight.w500,
                  color: c.muted,
                  height: 1.3,
                ),
              ),
              if (tail != null)
                Text(tail, style: UiText.sans(11, color: c.faint, height: 1.3)),
            ],
          ),
        ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: PromptAutocompletePopup.maxListHeight,
            ),
            child: body,
          ),
        ),
      ],
    );

    final main = _List(
      key: const Key('prompt-autocomplete-list'),
      controller: _scroll,
      count: state.candidates.length,
      row: (i) {
        final cand = state.candidates[i];
        final selected = i == state.selectedIndex;
        return KeyedSubtree(
          key: selected ? _selectedRow : null,
          child: _Row(
            key: Key('prompt-autocomplete-$i'),
            tag: TagNormalizer.toDisplay(cand.canonicalTag),
            zh: _zh(cand),
            count: cand.postCount > 0 ? _count(cand.postCount) : null,
            leading: _Dot(TagCategoryVisuals.color(context, cand.category)),
            selected: selected,
            // 关联栏开着时主栏选中项退成描边：键盘焦点在右边。
            dim: related != null && related.index != i,
            source: related?.index == i,
            // 鼠标：左键补全，右键开关联（键盘 → / ← 开关，见控制器）。
            onTap: () {
              widget.controller.closeRelated();
              widget.onAccept(i);
            },
            onSecondaryTap: () => widget.controller.openRelated(i),
          ),
        );
      },
    );

    Widget? side;
    if (related != null) {
      final body = state.relatedLoading
          ? const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              ),
            )
          : state.related.isEmpty
          ? Center(
              child: Text(
                l.tagExpansion_noResults,
                style: UiText.sans(11.5, color: c.faint),
              ),
            )
          : _List(
              key: const Key('prompt-autocomplete-related-list'),
              controller: _relatedScroll,
              count: state.related.length,
              row: (i) {
                final cand = state.related[i];
                final added = state.relatedAdded.contains(cand.canonicalTag);
                return KeyedSubtree(
                  key: i == state.relatedSelected ? _selectedRelatedRow : null,
                  child: _Row(
                    key: Key('prompt-autocomplete-related-$i'),
                    tag: TagNormalizer.toDisplay(cand.canonicalTag),
                    zh: _zh(cand),
                    count: cand.postCount > 0 ? _count(cand.postCount) : null,
                    leading: SizedBox(
                      width: 12,
                      child: added
                          ? UiGlyph(UiGlyphs.check, size: 12, color: c.ok)
                          : null,
                    ),
                    selected: i == state.relatedSelected,
                    muted: added,
                    onTap: () => widget.onAccept(i),
                  ),
                );
              },
            );
      side = Container(
        decoration: BoxDecoration(
          border: stacked
              ? Border(top: BorderSide(color: c.border))
              : Border(left: BorderSide(color: c.border)),
        ),
        child: column(
          key: const Key('prompt-autocomplete-related'),
          title: l.tagExpansion_relatedTitle,
          tail: '· ${TagNormalizer.toDisplay(related.canonicalTag)}',
          body: body,
        ),
      );
    }

    return CompositedTransformFollower(
      link: _link,
      offset: placement.offset,
      followerAnchor: placement.above
          ? Alignment.bottomLeft
          : Alignment.topLeft,
      // 点候选不让编辑框失焦（失焦会清掉候选）。
      child: TextFieldTapRegion(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: placement.height),
          child: UiPopoverSurface(
            key: const Key('prompt-autocomplete'),
            width: width,
            radius: 9,
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Flex(
                    direction: stacked ? Axis.vertical : Axis.horizontal,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: stacked
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: related == null || stacked
                            ? 1
                            : mainWidth.round(),
                        child: column(
                          key: const Key('prompt-autocomplete-main'),
                          title: l.prompt_autocompleteTitle,
                          tail: '${state.candidates.length}',
                          body: main,
                        ),
                      ),
                      if (side != null)
                        Flexible(
                          flex: stacked
                              ? 1
                              : (PromptAutocompletePopup.relatedWidth + 1)
                                    .round(),
                          child: side,
                        ),
                    ],
                  ),
                ),
                _Footer(related: related != null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 候选按内容增高；数量有限，直接布局全部行以支持精确的键盘滚动。
class _List extends StatelessWidget {
  const _List({
    super.key,
    required this.controller,
    required this.count,
    required this.row,
  });
  final ScrollController controller;
  final int count;
  final Widget Function(int) row;

  @override
  Widget build(BuildContext context) => Listener(
    // 外层编辑区自己也是可滚动的：在这里认领滚轮事件，避免两层一起滚。
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        GestureBinding.instance.pointerSignalResolver.register(event, (e) {
          final s = e as PointerScrollEvent;
          if (!controller.hasClients) return;
          final pos = controller.position;
          controller.jumpTo(
            (pos.pixels + s.scrollDelta.dy).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            ),
          );
        });
      }
    },
    child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: controller,
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, row),
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.tag,
    required this.zh,
    required this.count,
    required this.leading,
    required this.selected,
    required this.onTap,
    this.onSecondaryTap,
    this.dim = false,
    this.source = false,
    this.muted = false,
  });
  final String tag;
  final String? zh, count;
  final Widget leading;
  final bool selected, dim, source, muted;
  final VoidCallback onTap;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final active = selected && !dim;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onSecondaryTap: onSecondaryTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: source
                ? c.accent.withValues(alpha: c.dark ? .16 : .08)
                : active
                ? c.hover
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            spacing: 7,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 5), child: leading),
              // 标签和中文名一起占满中间，热度数字始终贴右对齐。
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 2,
                  children: [
                    Text(
                      tag,
                      style: UiText.sans(
                        12.5,
                        color: muted ? c.faint : c.ink,
                        height: 1.4,
                      ),
                    ),
                    if (zh != null)
                      Text(
                        zh!,
                        style: UiText.sans(11.5, color: c.faint, height: 1.45),
                      ),
                  ],
                ),
              ),
              if (count != null)
                Text(
                  count!,
                  softWrap: false,
                  textAlign: TextAlign.right,
                  style: UiText.mono(11, color: c.faint, height: 1.45),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// 一行浅色操作提示：主栏时提示右键关联，关联栏开着时提示追加 / 关闭。
class _Footer extends StatelessWidget {
  const _Footer({required this.related});
  static const padding = EdgeInsets.symmetric(horizontal: 11, vertical: 6);
  static final textStyle = UiText.sans(11, height: 1.45);
  final bool related;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('prompt-autocomplete-footer'),
      margin: const EdgeInsets.only(top: 3),
      padding: padding,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        related ? l.prompt_autocompleteHintRelated : l.prompt_autocompleteHint,
        style: textStyle.copyWith(color: c.faint),
      ),
    );
  }
}
