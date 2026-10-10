import 'dart:async';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'explore_hover_data.dart';
import '../ui/explore_hover_preview_view.dart';

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
    return info == null
        ? const SizedBox.shrink()
        : buildExploreHoverPreview(context, info, _targetRect(info));
  }
}
