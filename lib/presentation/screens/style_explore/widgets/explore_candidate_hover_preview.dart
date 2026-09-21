import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 候选堆缩略图悬停预览（FEAT-41）：首次悬停 800ms 后弹大图，预览存续期
/// 滑到相邻缩略图 0 延迟直切，离开缩略图区 200ms 宽限后关闭并结束会话。
///
/// Overlay 骨架照 `common/hover_image_preview.dart` 先例（OverlayEntry +
/// Material elevation 8）；差异点：会话延迟/宽限计时、整层 IgnorePointer、
/// 防遮挡定位（优先缩略图行上方、放不下翻转、最终夹取在窗口内——
/// CompositedTransformFollower 无翻转/夹取能力，这里按锚点全局矩形 +
/// CustomSingleChildLayout 求位，锚点随悬停项切换）。
class ExploreCandidateHoverSession {
  /// 首次悬停到弹预览的延迟（对齐块 chip 悬停 Tooltip 的 800ms 先例）。
  static const Duration firstHoverDelay = Duration(milliseconds: 800);

  /// 离开全部缩略图后的宽限：期内回到任一缩略图免延迟直切。
  static const Duration leaveGrace = Duration(milliseconds: 200);

  /// 当前悬停项快照（含无图项）；null = 指针不在任何缩略图上。
  ExploreCandidateHoverInfo? _hovered;

  /// 浮层当前展示的项；浮层持 candidateId 随锚点项拆卸重校验关闭。
  ExploreCandidateHoverInfo? _shown;

  OverlayEntry? _entry;
  Timer? _delayTimer;
  Timer? _graceTimer;

  /// 本会话内 800ms 延迟已满足：之后悬停切换全部 0 延迟。
  bool _unlocked = false;

  /// dispose 后全部入口空操作：持有方先 dispose 会话、包装件随后拆卸的
  /// 顺序下，remove 不再起新的宽限计时器（防 pending timer 泄漏）。
  bool _disposed = false;

  /// 悬停进入任一缩略图。会话未解锁时起 800ms 计时（期间跨缩略图滑动
  /// 不重置，到点按当时悬停项弹出）；已解锁则有图直切、无图撤浮层。
  void hoverEnter(ExploreCandidateHoverInfo info) {
    if (_disposed) return;
    _graceTimer?.cancel();
    _graceTimer = null;
    _hovered = info;
    if (_unlocked) {
      if (info.hasImage) {
        _show(info);
      } else {
        // 悬停无图项（pending/failed/无副本）不弹浮层，但不断会话。
        _removeEntry();
      }
      return;
    }
    _delayTimer ??= Timer(firstHoverDelay, _onDelayElapsed);
  }

  /// 悬停离开某缩略图。仅当它是当前悬停项时生效（元素复用/乱序事件兜底）。
  void hoverExit(String candidateId) {
    if (_disposed || _hovered?.candidateId != candidateId) return;
    _hovered = null;
    _startGrace();
  }

  /// 点按缩略图（开详情/分支点选）：即时撤掉浮层防残余，会话与解锁态
  /// 保留——点完继续滑动到下一张仍是 0 延迟。
  void dismissPreview() => _removeEntry();

  /// 悬停/展示项从树上消失（候选被删、筛选切换、列表拆卸）时的重校验。
  void remove(String candidateId) {
    if (_disposed) return;
    final wasHovered = _hovered?.candidateId == candidateId;
    if (wasHovered) _hovered = null;
    if (_shown?.candidateId == candidateId) _removeEntry();
    // 悬停项被拆走 = 锚点已失、无从宽限，直接结束会话（下次悬停重新计
    // 800ms）；同时不产生新计时器，保证持有方拆卸期干净。
    if (wasHovered) _endSession();
  }

  /// 同位元素配置更新（如同候选 filePath 变化）：悬停/展示中则同步快照。
  void updateHover(String previousId, ExploreCandidateHoverInfo info) {
    if (_disposed) return;
    if (_hovered?.candidateId == previousId) _hovered = info;
    if (_shown?.candidateId != previousId) return;
    _removeEntry();
    if (info.hasImage && _unlocked) _show(info);
  }

  /// 结束会话：取消全部计时器并撤浮层。由持有方 dispose 时调用。
  void dispose() {
    _disposed = true;
    _delayTimer?.cancel();
    _delayTimer = null;
    _graceTimer?.cancel();
    _graceTimer = null;
    _unlocked = false;
    _removeEntry();
  }

  void _onDelayElapsed() {
    _delayTimer = null;
    _unlocked = true;
    final hovered = _hovered;
    if (hovered != null && hovered.hasImage) _show(hovered);
  }

  void _startGrace() {
    _graceTimer?.cancel();
    _graceTimer = Timer(leaveGrace, _endSession);
  }

  /// 宽限超时：关浮层、结束会话（下次悬停重新计 800ms）。
  void _endSession() {
    _graceTimer = null;
    _delayTimer?.cancel();
    _delayTimer = null;
    _unlocked = false;
    _removeEntry();
  }

  void _show(ExploreCandidateHoverInfo info) {
    _shown = info;
    final entry = _entry;
    if (entry != null) {
      entry.markNeedsBuild();
      return;
    }
    if (!info.anchorContext.mounted) {
      _shown = null;
      return;
    }
    final overlay = Overlay.maybeOf(info.anchorContext);
    if (overlay == null) {
      _shown = null;
      return;
    }
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
    _shown = null;
  }

  Rect? _targetRect(ExploreCandidateHoverInfo info) {
    final anchorContext = info.anchorContext;
    if (!anchorContext.mounted) return null;
    final box = anchorContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Widget _buildOverlay(BuildContext context) {
    final info = _shown;
    if (info == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final filePath = info.filePath;
    return Positioned.fill(
      // 整层不吃鼠标事件：滑过浮层不阻塞下方缩略图的悬停切换。
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _HoverPreviewLayoutDelegate(targetRect: _targetRect(info)),
          child: Material(
            key: const Key('explore-candidate-hover-preview'),
            elevation: 8,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: KeyedSubtree(
              key: ValueKey('explore-candidate-hover-${info.candidateId}'),
              child: Stack(
                children: [
                  if (filePath != null)
                    (info.imageBuilder ?? _defaultImageBuilder)(
                      context,
                      filePath,
                    ),
                  if (info.badgeText.isNotEmpty)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: _HoverPreviewBadge(text: info.badgeText),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 悬停项快照：enter 时由包装件上报给会话。
class ExploreCandidateHoverInfo {
  const ExploreCandidateHoverInfo({
    required this.candidateId,
    required this.anchorContext,
    required this.badgeText,
    this.filePath,
    this.imageBuilder,
  });

  final String candidateId;

  /// 锚点 context（取缩略图全局矩形定位浮层）。
  final BuildContext anchorContext;

  /// 角标文案（'#序号 · 第N轮'，调用方按现成 l10n 拼好）。
  final String badgeText;

  /// 预览图文件路径；null = 无图项（不弹浮层）。
  final String? filePath;

  /// 图片构建器（可注入，测试规避 fakeAsync 真文件 I/O）。
  final Widget Function(BuildContext context, String filePath)? imageBuilder;

  bool get hasImage => filePath != null;
}

/// 缩略图包装件：上报悬停进/出与拆卸，点按即时撤浮层。
/// 不改变 child 的尺寸、点击与选择态行为。
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
  final String candidateId;
  final String badgeText;
  final String? filePath;
  final Widget Function(BuildContext context, String filePath)? imageBuilder;
  final Widget child;

  @override
  State<ExploreCandidateHoverThumb> createState() =>
      _ExploreCandidateHoverThumbState();
}

class _ExploreCandidateHoverThumbState
    extends State<ExploreCandidateHoverThumb> {
  ExploreCandidateHoverInfo _info() => ExploreCandidateHoverInfo(
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
      widget.session.updateHover(oldWidget.candidateId, _info());
    }
  }

  @override
  void dispose() {
    widget.session.remove(widget.candidateId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.session.hoverEnter(_info()),
      onExit: (_) => widget.session.hoverExit(widget.candidateId),
      child: Listener(
        onPointerDown: (_) => widget.session.dismissPreview(),
        child: widget.child,
      ),
    );
  }
}

/// 浮层定位：优先缩略图上方，放不下翻转到下方，两侧都不足取余量大的
/// 一侧，最终夹取在窗口内（四周留 _margin）。
///
/// 锚点矩形在 build 阶段预取成值——layout 阶段读外部 render box 的几何
/// （localToGlobal 走祖先链 applyPaintTransform）是非法的。
class _HoverPreviewLayoutDelegate extends SingleChildLayoutDelegate {
  _HoverPreviewLayoutDelegate({required this.targetRect});

  final Rect? targetRect;

  static const double _previewMaxSide = 320;
  static const double _gap = 6;
  static const double _margin = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: math.min(
        _previewMaxSide,
        math.max(0.0, constraints.maxWidth - _margin * 2),
      ),
      maxHeight: math.min(
        _previewMaxSide,
        math.max(0.0, constraints.maxHeight - _margin * 2),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final rect = targetRect;
    if (rect == null) return const Offset(-10000, -10000);
    final aboveDy = rect.top - _gap - childSize.height;
    final belowDy = rect.bottom + _gap;
    double dy;
    if (aboveDy >= _margin) {
      dy = aboveDy;
    } else if (belowDy + childSize.height <= size.height - _margin) {
      dy = belowDy;
    } else {
      final aboveSpace = rect.top - _margin;
      final belowSpace = size.height - _margin - rect.bottom;
      dy = aboveSpace >= belowSpace ? aboveDy : belowDy;
    }
    dy = dy.clamp(
      _margin,
      math.max(_margin, size.height - _margin - childSize.height),
    );
    final dx = (rect.center.dx - childSize.width / 2).clamp(
      _margin,
      math.max(_margin, size.width - _margin - childSize.width),
    );
    return Offset(dx.toDouble(), dy.toDouble());
  }

  @override
  bool shouldRelayout(covariant _HoverPreviewLayoutDelegate oldDelegate) =>
      true;
}

Widget _defaultImageBuilder(BuildContext context, String filePath) {
  return Image.file(
    File(filePath),
    fit: BoxFit.contain,
    cacheWidth: 720,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => SizedBox(
      width: 120,
      height: 120,
      child: StudioIcon(
        Icons.broken_image_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
  );
}

class _HoverPreviewBadge extends StatelessWidget {
  const _HoverPreviewBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}
