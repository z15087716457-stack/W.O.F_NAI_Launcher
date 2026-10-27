import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// 左栏是补全候选（标签 · 中文名 · 热度）；**右键**某个候选在右侧打开它的关联标签栏，
/// 关联栏开着时左栏**左键**只关闭关联栏；关联栏里左键追加，可连续加、已加的打勾。
/// 键盘：↑↓ 移动，Tab / Enter 补全或追加，Esc 先关关联栏再关整个（键盘在绑定里处理）。
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
  static const rowHeight = 30.0;
  static const maxRows = 8;
  static const headerHeight = 26.0;
  static const footerHeight = 26.0;

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
      _keepVisible(_scroll, state.selectedIndex);
      if (state.relatedFor != null) {
        _keepVisible(_relatedScroll, state.relatedSelected);
      }
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

  void _keepVisible(ScrollController scroll, int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      const h = PromptAutocompletePopup.rowHeight;
      final top = i * h, bottom = top + h;
      final pos = scroll.position;
      if (top < pos.pixels) {
        scroll.jumpTo(top);
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        scroll.jumpTo(bottom - pos.viewportDimension);
      }
    });
  }

  /// 当前词左下角相对编辑区的位置；找不到可编辑渲染对象时放在编辑区底部。
  Offset _anchor(double popupWidth) {
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
    // 两栏放不下时整体往左让，宁可盖住一点左侧也不出窗口。
    final screen = MediaQuery.sizeOf(context).width;
    final origin = root.localToGlobal(Offset.zero).dx;
    final maxX = (screen - origin - popupWidth - 8).clamp(
      -origin + 8,
      double.infinity,
    );
    return Offset(local.dx.clamp(-origin + 8, maxX), local.dy + 4);
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

  Widget _overlay(BuildContext context) {
    final state = widget.controller.value;
    if (!state.visible) return const SizedBox.shrink();
    final c = context.ui;
    final l = context.l10n;
    final related = state.relatedFor;
    final rows = state.candidates.length.clamp(
      1,
      PromptAutocompletePopup.maxRows,
    );
    final listHeight = rows * PromptAutocompletePopup.rowHeight;
    final width =
        PromptAutocompletePopup.width +
        (related == null ? 0 : PromptAutocompletePopup.relatedWidth + 1);

    Widget column({
      required Key key,
      required double width,
      required String title,
      String? tail,
      required Widget body,
    }) => SizedBox(
      key: key,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: PromptAutocompletePopup.headerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                spacing: 6,
                children: [
                  Text(
                    title,
                    style: UiText.sans(
                      11,
                      weight: FontWeight.w500,
                      color: c.muted,
                      height: 1,
                    ),
                  ),
                  if (tail != null)
                    Flexible(
                      child: Text(
                        tail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.faint, height: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: listHeight, child: body),
        ],
      ),
    );

    final main = _List(
      key: const Key('prompt-autocomplete-list'),
      controller: _scroll,
      count: state.candidates.length,
      row: (i) {
        final cand = state.candidates[i];
        final selected = i == state.selectedIndex;
        return _Row(
          key: Key('prompt-autocomplete-$i'),
          tag: TagNormalizer.toDisplay(cand.canonicalTag),
          zh: _zh(cand),
          count: cand.postCount > 0 ? _count(cand.postCount) : null,
          leading: _Dot(TagCategoryVisuals.color(context, cand.category)),
          selected: selected,
          // 关联栏开着时主栏选中项退成描边：键盘焦点在右边。
          dim: related != null && related.index != i,
          source: related?.index == i,
          // 关联栏开着时左键只关掉关联栏（用户 10-27：右键开、左键关），不顺手补全。
          onTap: related != null
              ? widget.controller.closeRelated
              : () => widget.onAccept(i),
          onSecondaryTap: () => widget.controller.openRelated(i),
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
                return _Row(
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
                );
              },
            );
      side = Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.border)),
        ),
        child: column(
          key: const Key('prompt-autocomplete-related'),
          width: PromptAutocompletePopup.relatedWidth,
          title: l.tagExpansion_relatedTitle,
          tail: '· ${TagNormalizer.toDisplay(related.canonicalTag)}',
          body: body,
        ),
      );
    }

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        offset: _anchor(width),
        // 点候选不让编辑框失焦（失焦会清掉候选）。
        child: TextFieldTapRegion(
          child: UiPopoverSurface(
            key: const Key('prompt-autocomplete'),
            width: width + 2,
            radius: 9,
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    column(
                      key: const Key('prompt-autocomplete-main'),
                      width: PromptAutocompletePopup.width,
                      title: l.prompt_autocompleteTitle,
                      tail: '${state.candidates.length}',
                      body: main,
                    ),
                    ?side,
                  ],
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

/// 候选列表：固定行高；滚轮在这里吃掉，不冒泡到外层提示词框。
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
      child: ListView.builder(
        controller: controller,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemExtent: PromptAutocompletePopup.rowHeight,
        itemCount: count,
        itemBuilder: (context, i) => row(i),
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
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
            children: [
              leading,
              // 标签和中文名一起占满中间，热度数字始终贴右对齐。
              Expanded(
                child: Row(
                  spacing: 7,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          12.5,
                          color: muted ? c.faint : c.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (zh != null)
                      Flexible(
                        flex: 2,
                        child: Text(
                          zh!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(11.5, color: c.faint, height: 1.2),
                        ),
                      ),
                  ],
                ),
              ),
              if (count != null)
                Text(count!, style: UiText.mono(10.5, color: c.faint)),
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
  final bool related;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('prompt-autocomplete-footer'),
      height: PromptAutocompletePopup.footerHeight,
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        related ? l.prompt_autocompleteHintRelated : l.prompt_autocompleteHint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: UiText.sans(10.5, color: c.faint, height: 1),
      ),
    );
  }
}
