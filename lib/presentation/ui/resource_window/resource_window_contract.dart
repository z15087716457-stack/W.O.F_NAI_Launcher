import 'package:flutter/widgets.dart';

import '../kit/ui_resource_kind.dart';

/// E05 独立资源窗口（原型 `.devin/mockups/d04-window/mock.html`）：界面只认这份契约。
///
/// 这个窗口跑在**单独的 Flutter 引擎**里（`desktop_multi_window`），没有 ProviderScope、
/// 不开任何库；所有数据由子窗口控制器经方法通道向主窗口要，整理成下面的结构交给界面。
///
/// 口径：
/// - [ResourceWindowViewData.items] 已按分组 / 搜索 / 筛选 / 排序处理好，界面不再二次筛选。
/// - 文案（分组名、筛选名、按钮名、副标题）由控制器用本地化写好，界面不拼业务文字。
/// - 视图模式默认跟随主程序（图库 `GalleryViewMode`、块库 `BlocksView`）；大小滑杆在
///   火车流下是行高，其余是列宽。

/// 卡片墙排布。图库：方格 / 瀑布 / 火车流；块库：瀑布 / 方格 / 列表；Vibe / 精准：方格 / 列表。
enum ResourceLayout { grid, masonry, justified, list }

enum ResourceBadgeTone { plain, ok, warn, accent }

@immutable
class ResourceGroup {
  const ResourceGroup({
    required this.id,
    required this.label,
    this.count,
    this.glyph,
    this.color,
    this.parentId,
  });

  final String id;

  /// Stable parent group ID; null denotes a section root.
  final String? parentId;
  final String label;
  final int? count;

  /// `UiGlyphs` 路径；与 [color] 二选一（块库文件夹、Vibe 分类用色块）。
  final String? glyph;
  final Color? color;
}

@immutable
class ResourceGroupSection {
  const ResourceGroupSection({required this.title, required this.groups});
  final String title;
  final List<ResourceGroup> groups;
}

/// 工具条上的筛选片（仅 NAI / 收藏 / 正面 / 当前模型可用…）。
@immutable
class ResourceChip {
  const ResourceChip({
    required this.id,
    required this.label,
    this.on = false,
    this.glyph,
  });
  final String id;
  final String label;
  final bool on;
  final String? glyph;
}

@immutable
class ResourceOption {
  const ResourceOption({required this.id, required this.label});
  final String id;
  final String label;
}

/// 卡片墙里的一项。四类资源共用，按 [FloatingResourceKind] 取用不同字段。
@immutable
class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.title,
    this.meta,
    this.thumb,
    this.aspect,
    this.badge,
    this.badgeTone = ResourceBadgeTone.plain,
    this.favorite = false,
    this.color,
    this.iconKey,
    this.positive,
    this.negative,
    this.folder,
    this.date,
  });

  final String id;

  /// 图库：时间（`16:24`）；块：块名；Vibe / 精准：名称。
  final String title;

  /// 卡片右下角等宽小字：图库尺寸、Vibe `0.6 · 1.0`、块词数。
  final String? meta;
  final ImageProvider? thumb;

  /// 宽 / 高；瀑布流、火车流按它排。没有时按 2:3。
  final double? aspect;

  /// 左上角角标：图库模型版本、Vibe 编码状态、精准参考类型。
  final String? badge;
  final ResourceBadgeTone badgeTone;
  final bool favorite;

  /// 块：主题色与图标（`ui_block_pill` 的图标键）。
  final Color? color;
  final String? iconKey;

  /// 块：正面 / 负面内容预览；图库：[positive] 是提示词。
  final String? positive;
  final String? negative;

  /// 块：所在文件夹名。
  final String? folder;

  /// 图库：按天分段用。
  final DateTime? date;
}

@immutable
class ResourceActionSpec {
  const ResourceActionSpec({
    required this.id,
    required this.label,
    this.glyph,
    this.primary = false,
  });
  final String id;
  final String label;
  final String? glyph;

  /// 主按钮（蓝色、Enter 触发）。每个详情最多一个。
  final bool primary;
}

/// 底部详情条（选中一项时）。
@immutable
class ResourceDetail {
  const ResourceDetail({
    required this.itemId,
    required this.title,
    this.subtitle,
    this.body,
    this.negative,
    this.actions = const [],
  });
  final String itemId;
  final String title;
  final String? subtitle;

  /// 等宽一行：提示词 / 块正面内容 / 标签。
  final String? body;
  final String? negative;
  final List<ResourceActionSpec> actions;
}

@immutable
class ResourceWindowViewData {
  const ResourceWindowViewData({
    required this.kind,
    this.counts = const {},
    this.sections = const [],
    this.groupId,
    this.query = '',
    this.queryHint = '',
    this.chips = const [],
    this.sorts = const [],
    this.sortId,
    this.layouts = const [ResourceLayout.grid],
    this.layout = ResourceLayout.grid,
    this.cellSize = 132,
    this.cellRange = const (96.0, 220.0),
    this.items = const [],
    this.total = 0,
    this.hasMore = false,
    this.loading = false,
    this.error,
    this.selectedId,
    this.detail,
    this.alwaysOnTop = false,
    this.connected = true,
    this.statusNote,
    this.now,
  });

  final FloatingResourceKind kind;

  /// 标签页上的数量（还没数出来的不给）。
  final Map<FloatingResourceKind, int> counts;
  final List<ResourceGroupSection> sections;
  final String? groupId;
  final String query;
  final String queryHint;
  final List<ResourceChip> chips;
  final List<ResourceOption> sorts;
  final String? sortId;

  /// 当前资源支持的排布，第一个是主程序没有设置时的默认。
  final List<ResourceLayout> layouts;
  final ResourceLayout layout;

  /// 火车流：行高；其余：列宽。块库列表模式不用。
  final double cellSize;
  final (double, double) cellRange;
  final List<ResourceItem> items;
  final int total;
  final bool hasMore;
  final bool loading;
  final String? error;
  final String? selectedId;
  final ResourceDetail? detail;
  final bool alwaysOnTop;

  /// 主窗口通道是否在线（主窗口退出 / 重启时为 false）。
  final bool connected;

  /// 侧栏底部的一行状态（“索引最新 · 2 分钟前”）。
  final String? statusNote;

  /// 图库按天分段的“今天”。为 null 时用 `DateTime.now()`。
  final DateTime? now;
}

/// 包一层原生拖动（子窗口里由控制器用 `ResourceWindowDrag` 实现）。界面只负责把卡片交出去。
typedef ResourceDragWrap = Widget Function(ResourceItem item, Widget child);

@immutable
class ResourceWindowActions {
  const ResourceWindowActions({
    required this.onKind,
    required this.onGroup,
    required this.onQuery,
    required this.onChip,
    required this.onSort,
    required this.onLayout,
    required this.onCellSize,
    required this.onSelect,
    required this.onOpen,
    required this.onAction,
    required this.onFavorite,
    required this.onLoadMore,
    required this.onAlwaysOnTop,
    required this.onNewWindow,
    this.onRetry,
    this.dragWrap,
  });

  final ValueChanged<FloatingResourceKind> onKind;
  final ValueChanged<String> onGroup;

  /// 输入时连续调用（控制器自己防抖）；`submit` 为 true 是回车确认（记搜索历史）。
  final void Function(String query, {bool submit}) onQuery;
  final ValueChanged<String> onChip;
  final ValueChanged<String> onSort;
  final ValueChanged<ResourceLayout> onLayout;

  /// 拖动结束才回调持久化；拖动中界面自己预览。
  final ValueChanged<double> onCellSize;
  final ValueChanged<String> onSelect;

  /// 双击：图库看大图，其余编辑（在主窗口打开）。
  final ValueChanged<String> onOpen;
  final void Function(String itemId, String actionId) onAction;
  final ValueChanged<String> onFavorite;
  final VoidCallback onLoadMore;
  final ValueChanged<bool> onAlwaysOnTop;
  final VoidCallback onNewWindow;
  final VoidCallback? onRetry;
  final ResourceDragWrap? dragWrap;

  /// 预览 / 夹具用：所有操作写进 [log]。
  static ResourceWindowActions logging(void Function(String) log) =>
      ResourceWindowActions(
        onKind: (k) => log('kind:${k.name}'),
        onGroup: (g) => log('group:$g'),
        onQuery: (q, {submit = false}) => log('query:$q:$submit'),
        onChip: (c) => log('chip:$c'),
        onSort: (s) => log('sort:$s'),
        onLayout: (l) => log('layout:${l.name}'),
        onCellSize: (s) => log('cell:${s.round()}'),
        onSelect: (id) => log('select:$id'),
        onOpen: (id) => log('open:$id'),
        onAction: (id, a) => log('action:$id:$a'),
        onFavorite: (id) => log('favorite:$id'),
        onLoadMore: () => log('more'),
        onAlwaysOnTop: (v) => log('top:$v'),
        onNewWindow: () => log('new'),
        onRetry: () => log('retry'),
      );
}
