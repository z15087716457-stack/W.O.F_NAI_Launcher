// 主导航契约：界面（lib/presentation/ui/nav/）只认这里的数据和回调。
// 接线方（lib/presentation/wiring/）负责：从 provider 组装 NavViewData，
// 把 NavActions 接到路由 / service 上。界面不 import 任何 provider、路由或旧界面。
import 'package:flutter/widgets.dart';

/// 导航栏上的页面。顺序和分组由界面固定（[navGroups]），接线方只做和 `AppBranch` 的一一映射。
enum NavPage {
  generation,
  styleExplore,
  localGallery,
  onlineGallery,
  promptBlocks,
  vibeLibrary,
  preciseRef,
  tagWiki,
  statistics,

  /// 设置固定在底部，不参与分组、不能隐藏。
  settings,
}

/// 四组，从上到下：创作 / 图库 / 素材 / 工具。组间画短线；整组都隐藏时短线也不画。
const navGroups = <List<NavPage>>[
  [NavPage.generation, NavPage.styleExplore],
  [NavPage.localGallery, NavPage.onlineGallery],
  [NavPage.promptBlocks, NavPage.vibeLibrary, NavPage.preciseRef],
  [NavPage.tagWiki, NavPage.statistics],
];

/// 不能隐藏的页面。
const navLockedPages = {NavPage.generation, NavPage.settings};

@immutable
class NavViewData {
  const NavViewData({
    required this.current,
    this.shortcuts = const {},
    this.showShortcutsInTips = true,
    this.hidden = const {},
    this.ctrlNumbers = true,
    this.ctrlHintSeen = true,
    this.pinned = false,
    this.reducedMotion = false,
    this.updateAvailable = false,
    this.account = const NavAccountData(),
    this.generation = const NavGeneration.idle(),
    this.tasks = const [],
  });

  /// 当前所在页（`navigationShell.currentIndex` 对应的页面）。
  final NavPage current;

  /// 每页的导航快捷键，按键帽拆好，例如 `['Ctrl', '1']`、`['Ctrl', ',']`。
  /// 用户改过的以用户的为准；没有绑定或已禁用的页面不放进来。
  /// 按住 Ctrl 显示的编号取自这里：只有“Ctrl + 单个键”的绑定才显示编号。
  final Map<NavPage, List<String>> shortcuts;

  /// 设置里的“提示中显示快捷键”。关掉后悬停提示只写页面名。
  final bool showShortcutsInTips;

  /// 用户在“自定义导航栏”里隐藏的页面。[navLockedPages] 里的页面放进来也不会被隐藏；
  /// 当前所在页即使被隐藏也临时显示，离开后才消失。
  final Set<NavPage> hidden;

  /// “按住 Ctrl 显示页面编号”开关。
  final bool ctrlNumbers;

  /// 第一次按住 Ctrl 时的说明条是否已经看过；false 时显示一次，松开 Ctrl 后回调 [NavActions.onCtrlHintSeen]。
  final bool ctrlHintSeen;

  /// 钉住展开：true 时导航栏常驻 236 宽并推开页面（存储键 `main_nav_rail_expanded`）。
  /// 不钉住时，展开是盖在页面上的浮层，由界面自己管理开关，不需要接线。
  final bool pinned;

  /// 设置里的“减少动态效果”（`canvasReducedMotionNotifierProvider`）；
  /// 系统级的减少动态效果界面自己读 `MediaQuery`，不用传。
  final bool reducedMotion;

  /// 设置图标上的更新红点（`updateStateProvider.hasNewVersion`）。
  final bool updateAvailable;

  final NavAccountData account;

  /// 生图状态，画在生图图标上（进度圈 / 完成点 / 失败点）和它的悬停提示里。
  final NavGeneration generation;

  /// 后台任务（本地放大、云端放大、批量操作）。为空时底部不显示后台任务图标。
  /// 任务结束后接线方继续保留 10 秒（[NavTask.finished] = true），再从列表里去掉。
  /// 生图不放在这里：正在生成时界面自己把 [generation] 列为第一行。
  final List<NavTask> tasks;
}

/// 账号区：头像、展开浮层头部、账号弹窗都用这一份。
@immutable
class NavAccountData {
  const NavAccountData({
    this.current,
    this.others = const [],
    this.anlas,
    this.plan,
    this.busy = false,
  });

  /// 当前登录的账号；未登录为 null（头像显示占位图标，弹窗显示“未登录”）。
  final NavAccount? current;

  /// 其他已保存的账号，按现有排序（`sortedAccounts` 去掉当前）。
  final List<NavAccount> others;

  /// Anlas 余额（`subscriptionNotifierProvider` 的 `anlasBalance`）；拿不到为 null，弹窗里不显示这一块。
  final int? anlas;

  /// 套餐名，例如 `Opus`；拿不到为 null，展开浮层头部只写 Anlas。
  final String? plan;

  /// 登录 / 切换进行中（`authNotifierProvider.isLoading`）：切换、添加、退出暂不可点，“管理账号”仍可点。
  final bool busy;
}

@immutable
class NavAccount {
  const NavAccount({
    required this.id,
    required this.name,
    this.avatar,
    this.tokenLogin = true,
    this.subscription,
  });

  final String id;

  /// 显示名（`displayName`）；没有自定义头像时取首字做头像。
  final String name;

  /// 自定义头像（`avatarPath` 读出来的图）；null 用首字头像。
  final ImageProvider? avatar;

  /// true = API Token 登录，false = 邮箱密码登录。
  final bool tokenLogin;

  /// 订阅到期信息；没有订阅数据为 null（不显示订阅行，也没有头像提醒点）。
  final NavSubscription? subscription;
}

enum NavSubscriptionState {
  ok,

  /// 快到期（`isExpiringSoon`）：订阅行琥珀色，头像右下角出现琥珀色点。
  expiringSoon,
  expired,
}

@immutable
class NavSubscription {
  const NavSubscription({
    required this.expiresAt,
    required this.daysLeft,
    required this.state,
  });

  final DateTime expiresAt;

  /// 剩余天数（`getSubscriptionExpiryInfo` 的口径）；已过期时不使用。
  final int daysLeft;
  final NavSubscriptionState state;
}

enum NavGenerationState {
  idle,

  /// 正在生成。
  running,

  /// 生成完成、用户还没回生图页看过。回到生图页后接线方改回 idle。
  done,

  /// 生成失败、用户还没回生图页看过。取消不算失败。
  failed,
}

@immutable
class NavGeneration {
  const NavGeneration({
    required this.state,
    this.current = 0,
    this.total = 0,
    this.progress,
    this.preview,
    this.error,
  });

  const NavGeneration.idle() : this(state: NavGenerationState.idle);

  final NavGenerationState state;

  /// 第几张 / 一共几张（`currentImage / totalImages`）。total > 1 时图标右下角显示“2/4”；
  /// done 时 [total] 是本批完成的张数。
  final int current;
  final int total;

  /// 当前这一张的进度 0–1（`progress`）；null 时进度圈按张数估算。
  final double? progress;

  /// 流式预览（`streamPreview`，或最新一个 `streamPreviewSlots` 的预览）；没有就不显示。
  final ImageProvider? preview;

  /// 失败原因（第一行即可）。
  final String? error;
}

enum NavTaskKind {
  localUpscale,
  cloudUpscale,

  /// 批量操作，对应 `BulkOperationType`。
  bulkDelete,
  bulkExport,
  bulkMetadata,
  bulkAddToCollection,
  bulkRemoveFromCollection,
  bulkFavorite,
}

/// 任务行右侧的操作。
enum NavTaskAction {
  none,

  /// 可取消（本地放大）→ [NavActions.onCancelTask]。
  cancel,

  /// 已经点了取消、正在停下：显示“正在取消”，不可点。
  cancelling,

  /// 刚完成且可撤销（批量操作 `canUndo`）→ [NavActions.onUndoTask]。
  undo,
}

@immutable
class NavTask {
  const NavTask({
    required this.id,
    required this.kind,
    this.done,
    this.total,
    this.fraction,
    this.phase,
    this.finished = false,
    this.action = NavTaskAction.none,
  });

  /// 接线方自定的稳定 id，回调时原样传回。
  final String id;
  final NavTaskKind kind;

  /// 已处理 / 总数（批量操作 `currentProgress / totalItems`）。有就显示“120 / 300”。
  final int? done;
  final int? total;

  /// 0–1；null 且没有 [done]/[total] 时进度条为不定状态。
  final double? fraction;

  /// 阶段名（本地放大的 `phase`，已本地化）；有就显示在百分比前面。
  final String? phase;

  /// 已结束（保留 10 秒）。结束的任务显示勾和“刚刚完成”，不计入“N 个进行中”。
  final bool finished;
  final NavTaskAction action;
}

@immutable
class NavActions {
  const NavActions({
    required this.onOpenPage,
    required this.onPinnedChanged,
    required this.onHiddenChanged,
    required this.onCtrlNumbersChanged,
    required this.onCtrlHintSeen,
    required this.onSwitchAccount,
    required this.onAddAccount,
    required this.onManageAccounts,
    required this.onLogout,
    required this.onCancelTask,
    required this.onUndoTask,
  });

  /// 切到某页（`navigationShell.goBranch`）。后台任务里生图那行的“查看”也走这里。
  final ValueChanged<NavPage> onOpenPage;

  /// 钉住 / 取消钉住。
  final ValueChanged<bool> onPinnedChanged;

  /// 新的隐藏集合（存 `main_nav_hidden_branches`）。“恢复默认”传空集合。
  final ValueChanged<Set<NavPage>> onHiddenChanged;

  /// “按住 Ctrl 显示页面编号”开关。“恢复默认”传 true。
  final ValueChanged<bool> onCtrlNumbersChanged;

  /// Ctrl 说明条看过了。
  final VoidCallback onCtrlHintSeen;

  /// 账号弹窗的四个命令。界面先关掉弹窗、等这一帧结束再回调，
  /// 回调里改账号状态不会拆掉正在处理点击的弹窗。
  final ValueChanged<String> onSwitchAccount;
  final VoidCallback onAddAccount;

  /// 打开设置的账号分区（`settingsAccountOpenRequestProvider` + 去设置页）。
  final VoidCallback onManageAccounts;
  final VoidCallback onLogout;

  final ValueChanged<String> onCancelTask;
  final ValueChanged<String> onUndoTask;

  static final none = NavActions(
    onOpenPage: (_) {},
    onPinnedChanged: (_) {},
    onHiddenChanged: (_) {},
    onCtrlNumbersChanged: (_) {},
    onCtrlHintSeen: () {},
    onSwitchAccount: (_) {},
    onAddAccount: () {},
    onManageAccounts: () {},
    onLogout: () {},
    onCancelTask: (_) {},
    onUndoTask: (_) {},
  );
}
