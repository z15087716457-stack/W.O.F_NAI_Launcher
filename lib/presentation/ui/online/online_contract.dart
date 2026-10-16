// 在线画廊契约：界面（lib/presentation/ui/online/）只认这里的数据和回调。
// 接线方（lib/presentation/wiring/）负责：从 OnlineGalleryNotifier / OnlineFavoritesNotifier /
// 黑名单 / 账号 provider 组装 OnlineViewData，把 OnlineActions 接到这些 notifier 和生图页入口上。
// 界面不 import 任何 provider、service、数据模型或旧界面。
//
// 界面自己管的状态（不需要接线）：多选模式和勾选集合、大图查看器开关和当前第几张图、
// 各个浮层的开关、搜索框里正在输入还没提交的文字、悬停。
import 'package:flutter/material.dart';

/// 四个来源，对应 `GallerySourceId`。
enum OnlineSource { aiTag, danbooru, safebooru, gelbooru }

/// 浏览方式，对应 `GalleryViewMode`（search / popular / favorites）。
enum OnlineMode { search, ranking, favorites }

/// 卡片大小。目标宽 160 / 210 / 280（存 `OnlineGalleryColumnWidthStore`，读到旧值按最近一档）。
/// 列数 = ⌈(可用宽 + 12) / (目标宽 + 12)⌉，卡片宽按列数均分，所以实际宽不超过目标宽。
enum OnlineCardSize { small, medium, large }

/// Danbooru 系评级 g / s / q / e。
enum OnlineRating { general, sensitive, questionable, explicit }

/// AI TAG 模型版本，对应 `aiTagModelVersion` 的 '3' / '4' / '4.5' / '5'；null = 全部。
enum OnlineModel { v3, v4, v45, v5 }

/// Danbooru 系排行粒度，对应 `PopularScale`。
enum OnlineRankScale { day, week, month }

/// “发送到生图”的三种方式。
enum OnlineSendMode {
  /// 替换正向 + 负面，清空生图页的角色框（以前卡片按钮 / AI TAG 详情的行为）。
  replace,

  /// 只替换正向 + 负面，保留角色框。
  promptOnly,

  /// 提示词 + 生成参数：走本地图库“复用参数”同一条链
  /// （`MetadataImportCoordinator.applyOfficialSelection`）。只有 [OnlineDetail.canSendParams] 时可选。
  withParams,
}

/// 最近搜索的种类：作品搜索词 / Prompt 搜索词 / 作者。
enum OnlineRecentKind { work, prompt, author }

/// 来源账号状态，只用于来源卡副标题和“换来源”浮层。
enum OnlineAccountState {
  /// 不用登录（AI TAG、Safebooru）。
  none,

  /// Danbooru 已登录，[OnlineSourceStatus.accountName] 是用户名。
  signedIn,

  /// Danbooru 未登录。
  signedOut,

  /// Gelbooru API Key 已配置 / 失效 / 没配置（和以前 `_buildUserButton` 的三种状态一致）。
  keyConfigured,
  keyInvalid,
  keyMissing,
}

/// Danbooru 系检查器里的标签分组，颜色界面自己定。
enum OnlineTagGroup { artist, copyright, character, general, meta }

/// 一个来源能做什么。接线方从 `gallerySourceCapabilities[source]` 填，
/// AI TAG 的本地收藏另算（[favoritesLocal] = true）。界面不按来源名判断能力。
@immutable
class OnlineSourceStatus {
  const OnlineSourceStatus({
    required this.source,
    this.ranking = false,
    this.favorites = false,
    this.favoritesWritable = false,
    this.favoritesLocal = false,
    this.ratings = false,
    this.dateRange = false,
    this.fuzzy = false,
    this.promptQuery = false,
    this.multiMedia = false,
    this.account = OnlineAccountState.none,
    this.accountName,
  });

  final OnlineSource source;

  /// 有排行（`supportsRanking`）。没有时左栏“热门”灰掉并写“没有排行”。
  final bool ranking;

  /// 有收藏（AI TAG 本地收藏也算）。没有时左栏“收藏”灰掉并写“不支持收藏”。
  final bool favorites;

  /// 收藏可写（`supportsWritableFavorites`，或 AI TAG 本地收藏）。false 且 [favorites] 时左栏写“只读”。
  final bool favoritesWritable;

  /// AI TAG 的本地收藏：左栏显示子集和收藏的作者、收藏数。
  final bool favoritesLocal;

  final bool ratings;
  final bool dateRange;
  final bool fuzzy;

  /// 作品 + Prompt 两段搜索框（`supportsPromptQuery`）；false 时是标签块搜索框。
  final bool promptQuery;

  /// 多图作品和生成参数（`supportsMultipleMedia`）。
  final bool multiMedia;

  final OnlineAccountState account;
  final String? accountName;

  bool get needsLogin =>
      account == OnlineAccountState.signedOut ||
      account == OnlineAccountState.keyMissing ||
      account == OnlineAccountState.keyInvalid;
}

@immutable
class OnlineViewData {
  const OnlineViewData({
    required this.source,
    required this.sources,
    this.mode = OnlineMode.search,
    this.query = const OnlineQuery(),
    this.filters = const OnlineFilters(),
    this.ranking = const OnlineRanking(),
    this.recent = const [],
    this.favorites,
    this.blacklist = const OnlineBlacklist(),
    this.list = const OnlineList(),
    this.selectedKey,
    this.detail,
    this.cardSize = OnlineCardSize.medium,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.send = const OnlineSendContext(),
    this.canReturn = false,
    this.reducedMotion = false,
  });

  /// 当前来源（`currentSourceId`）。
  final OnlineSource source;

  /// 四个来源的能力和账号，按 [OnlineSource] 顺序，“换来源”浮层逐行显示。
  final List<OnlineSourceStatus> sources;

  final OnlineMode mode;
  final OnlineQuery query;
  final OnlineFilters filters;
  final OnlineRanking ranking;

  /// 当前来源的最近搜索，新的在前，最多 8 条（新功能，SharedPreferences）。
  final List<OnlineRecent> recent;

  /// AI TAG 本地收藏的左栏和作者头部数据；只在 [OnlineSourceStatus.favoritesLocal] 时用。
  final OnlineFavorites? favorites;

  final OnlineBlacklist blacklist;

  /// 卡片墙（当前来源 + 浏览方式的 `ModeCache`；AI TAG 收藏是本地收藏列表）。
  final OnlineList list;

  /// 检查器显示哪张（[OnlineWork.key]）。界面单击卡片回调 [OnlineActions.onSelect]，接线方改这里。
  final String? selectedKey;

  /// [selectedKey] 的详情。还没拉到时传 `OnlineDetail(key, loading: true)`；没选中时 null。
  /// AI TAG 详情走 provider 现有的并发槽和 `cachedDetailFor`。
  final OnlineDetail? detail;

  final OnlineCardSize cardSize;

  /// 左栏 / 检查器是否展开（用户点收起按钮会回调；窗口太窄时界面自己临时收起，不回调）。
  final bool sidebarOpen;
  final bool inspectorOpen;

  final OnlineSendContext send;

  /// “只看 TA”之后有可返回的结果（`authorReturnContext != null`），筛选行显示“返回之前的结果”。
  final bool canReturn;

  /// 设置里的“减少动态效果”；系统级的界面自己读 `MediaQuery`。
  final bool reducedMotion;

  OnlineSourceStatus get status => sources.firstWhere(
    (s) => s.source == source,
    orElse: () => OnlineSourceStatus(source: source),
  );
}

/// 搜索框内容（已提交的；正在输入的界面自己管）。
@immutable
class OnlineQuery {
  const OnlineQuery({
    this.work = '',
    this.prompt = '',
    this.tags = const [],
    this.fuzzy = false,
    this.favoritesFilter = '',
  });

  /// AI TAG 作品段（`searchQuery`，月榜时是 `popularQuery`）。
  final String work;

  /// AI TAG Prompt 段（`promptQuery` / `popularPromptQuery`）。
  final String prompt;

  /// Danbooru 系标签，按空格拆好；`-` 开头是排除。
  final List<String> tags;

  /// 模糊匹配（`fuzzySearchEnabled`）。
  final bool fuzzy;

  /// AI TAG 本地收藏里的搜索（新功能，标题 / 作者 / 标签在内存里过滤）。
  final String favoritesFilter;
}

@immutable
class OnlineFilters {
  const OnlineFilters({
    this.naiOnly = true,
    this.model,
    this.timeRange = 'all',
    this.timeRanges = const ['all'],
    this.ratings = const {
      OnlineRating.general,
      OnlineRating.sensitive,
      OnlineRating.questionable,
      OnlineRating.explicit,
    },
    this.dateRange,
  });

  /// AI TAG 仅 NAI 图片（`aiTagNaiOnly`，搜索和月榜都生效）。
  final bool naiOnly;

  /// AI TAG 模型（只在搜索）。规则由接线方保持：选了版本自动打开仅 NAI，关掉仅 NAI 连带清版本。
  final OnlineModel? model;

  /// AI TAG 时间范围 id（`aiTagTimeRange`）：`all`、`y2025`、`q2025Q3`、`older`。
  final String timeRange;

  /// 可选的时间范围 id（`AiTagSourceConfig.searchTimeRanges`），界面按 id 写文案。
  final List<String> timeRanges;

  /// Danbooru / Gelbooru 评级（`selectedRatings`）。
  final Set<OnlineRating> ratings;

  /// Danbooru 系日期范围（`dateRangeStart` / `dateRangeEnd`）；null = 不限。
  final DateTimeRange? dateRange;
}

@immutable
class OnlineRanking {
  const OnlineRanking({
    this.period = 'current',
    this.months = const [],
    this.scale = OnlineRankScale.day,
    this.date,
  });

  /// AI TAG 月榜：`current`（实时月榜）或 `2026-09` 这样的月份（`aiTagPopularPeriod`）。
  final String period;

  /// AI TAG 可选月份（`AiTagSourceConfig.availableMonths`），新的在前。
  /// 前 4 个平铺在筛选行，其余收进“更早归档”。
  final List<String> months;

  /// Danbooru 系热门的日 / 周 / 月（`popularScale`）和日期（`popularDate`，null = 今天）。
  final OnlineRankScale scale;
  final DateTime? date;
}

@immutable
class OnlineRecent {
  const OnlineRecent({required this.kind, required this.text});
  final OnlineRecentKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is OnlineRecent && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);
}

/// AI TAG 本地收藏。
@immutable
class OnlineFavorites {
  const OnlineFavorites({
    this.total = 0,
    this.ungrouped = 0,
    this.collections = const [],
    this.authors = const [],
    this.collectionId,
    this.authorId,
  });

  /// [collectionId] 取这个值表示“未分组”（原“根收藏”）。
  static const ungroupedId = '';

  /// 全部收藏数（`favoritedWorkIds.length`）和未分组数。
  final int total;
  final int ungrouped;

  final List<OnlineCollection> collections;
  final List<OnlineFavoriteAuthor> authors;

  /// 正在看的子集：null = 全部，[ungroupedId] = 未分组，其余是子集 id。
  final String? collectionId;

  /// 正在只看的收藏作者；非 null 时卡片墙上方显示作者头部，优先于 [collectionId]。
  final int? authorId;

  OnlineFavoriteAuthor? get author =>
      authors.where((a) => a.id == authorId).firstOrNull;
}

@immutable
class OnlineCollection {
  const OnlineCollection({
    required this.id,
    required this.name,
    required this.count,
  });
  final String id;
  final String name;
  final int count;
}

@immutable
class OnlineFavoriteAuthor {
  const OnlineFavoriteAuthor({
    required this.id,
    required this.name,
    this.count = 0,
    this.avatar,
    this.savedAt,
  });

  final int id;
  final String name;

  /// 收藏里这个作者的作品数。
  final int count;

  /// 头像：用收藏里这个作者第一张作品的缩略图；null 时界面写首字。
  final ImageProvider? avatar;
  final DateTime? savedAt;
}

@immutable
class OnlineBlacklist {
  const OnlineBlacklist({
    this.tags = const [],
    this.danbooruSync = false,
    this.danbooruCount = 0,
  });

  /// 本地屏蔽的标签。左栏写“屏蔽 N 个标签”（N = 本地标签数，同步来的在浮层里另写）。
  final List<String> tags;

  /// 同步 Danbooru 账号黑名单的开关和同步来的标签数；未登录 Danbooru 时界面不显示这一行。
  final bool danbooruSync;
  final int danbooruCount;
}

/// 卡片墙。
@immutable
class OnlineList {
  const OnlineList({
    this.key = '',
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.pages = 0,
    this.hasMore = false,
    this.appendError,
    this.error,
    this.blocked,
    this.initialOffset = 0,
  });

  /// 列表身份（`currentCacheKey`）。变了界面就换一个滚动位置，用 [initialOffset] 恢复。
  final String key;

  final List<OnlineWork> items;

  /// 第一页还在加载：整面墙画按比例的骨架。
  final bool loading;

  /// 正在追加下一页：墙底部补一排骨架。
  final bool loadingMore;

  /// 已加载的页数（`page`）；跳到页浮层默认填下一页。
  final int pages;
  final bool hasMore;

  /// 追加下一页失败（`appendErrorCode`）：墙底部写清哪一页、什么原因，[OnlineActions.onRetryPage]。
  final OnlineAppendError? appendError;

  /// 第一页就失败：整面墙显示错误和重试（已本地化的原因）。
  final String? error;

  /// 到底时被黑名单挡掉的张数（新功能，可选）；拿不到干净的数就传 null，界面不写这一句。
  final int? blocked;

  /// 这个列表上次的滚动位置（`scrollOffset`）。
  final double initialOffset;
}

@immutable
class OnlineAppendError {
  const OnlineAppendError({required this.page, required this.reason});
  final int page;

  /// 已本地化的原因，例如“AI TAG 响应超时”。
  final String reason;
}

/// 一张卡片。
@immutable
class OnlineWork {
  const OnlineWork({
    required this.key,
    required this.id,
    this.thumb,
    this.width = 0,
    this.height = 0,
    this.title,
    this.author,
    this.authorId,
    this.views,
    this.favorites,
    this.score,
    this.rating,
    this.mediaCount = 1,
    this.rank,
    this.model,
    this.favorited = false,
    this.mediaLabel,
  });

  /// `stableKey`（`ai_tag:2158843`），回调原样传回。
  final String key;

  /// 站点上的作品号 / 帖子号。
  final int id;

  /// 缩略图（`previewUrl` 经 `DanbooruImageCacheManager`）。null 时画控件底。
  final ImageProvider? thumb;

  /// 原图尺寸；不知道时传 0，卡片按 1:1 占位（AI TAG 详情回来后再给真尺寸）。
  final int width;
  final int height;

  /// AI TAG：标题、作者、浏览、收藏。有 [title] 或 [author] 时卡片下面写两行。
  final String? title;
  final String? author;
  final int? authorId;
  final int? views;
  final int? favorites;

  /// Danbooru 系：分数、收藏数（[favorites]）、帖子号；卡片下面写一行。
  final int? score;
  final OnlineRating? rating;

  /// 多图作品的图数（`mediaCount`），> 1 时右上角写数量。
  final int mediaCount;

  /// 排行名次（`rank`），只在排行里显示。
  final int? rank;

  /// 模型短名（`V4.5`），悬停时左下角和尺寸一起写。
  final String? model;

  /// 已收藏（AI TAG 本地 `isFavorite`，Danbooru 系 `favoritedPostKeys`）。
  final bool favorited;

  /// `GIF` / `Video`（`mediaTypeLabel`），有就在左上角写。
  final String? mediaLabel;

  double get aspect => width > 0 && height > 0 ? width / height : 1;
  bool get isAiTag => title != null || author != null;
}

/// 检查器 / 大图查看器的详情。
@immutable
class OnlineDetail {
  const OnlineDetail({
    required this.key,
    this.loading = false,
    this.error,
    this.media = const [],
    this.createdAt,
    this.prompt,
    this.negative,
    this.params,
    this.siteTags = const [],
    this.tagGroups = const {},
    this.fileType,
    this.fileBytes,
    this.authorFavorited = false,
    this.authorSavedCount = 0,
    this.authorAvatar,
    this.canSendParams = false,
  });

  final String key;
  final bool loading;

  /// 已本地化的失败原因。
  final String? error;

  /// 这件作品的所有图（AI TAG 多图；Danbooru 系只有一张）。
  final List<OnlineMedia> media;
  final DateTime? createdAt;

  /// 正向 / 负面。Danbooru 系没有，界面显示分组标签。
  final String? prompt;
  final String? negative;

  /// 生成参数（AI TAG 解析出的 `NaiImageMetadata`）；null 时不显示参数格。
  final OnlineParams? params;

  /// AI TAG 站点标签（点一下加入作品搜索）。
  final List<String> siteTags;

  /// Danbooru 系分组标签；翻译走现有 `observeTagReadings`。
  final Map<OnlineTagGroup, List<OnlineTag>> tagGroups;

  /// Danbooru 系文件类型（`PNG`）和大小。
  final String? fileType;
  final int? fileBytes;

  /// 作者是否已收藏（AI TAG 本地作者收藏），以及收藏里有几张 TA 的作品（“你收藏了 TA 12 张”，0 不写）。
  final bool authorFavorited;
  final int authorSavedCount;
  final ImageProvider? authorAvatar;

  /// “提示词 + 生成参数”可用（有 `naiMetadata`）。
  final bool canSendParams;
}

@immutable
class OnlineMedia {
  const OnlineMedia({this.thumb, this.image, this.width = 0, this.height = 0});

  /// 缩略图（胶片条）和大图（`displayUrl`）。
  final ImageProvider? thumb;
  final ImageProvider? image;
  final int width;
  final int height;

  double get aspect => width > 0 && height > 0 ? width / height : 1;
}

@immutable
class OnlineParams {
  const OnlineParams({
    this.model,
    this.width,
    this.height,
    this.seed,
    this.sampler,
    this.steps,
    this.cfg,
  });

  /// 显示名（`NAI Diffusion V4.5 Full`）。
  final String? model;
  final int? width;
  final int? height;
  final int? seed;

  /// 显示名（`Euler Ancestral`）。
  final String? sampler;
  final int? steps;
  final double? cfg;
}

@immutable
class OnlineTag {
  const OnlineTag(this.name, {this.translation});
  final String name;
  final String? translation;
}

/// 标签补全的一条候选（`TagExpansionWrapper` 现有的补全源）。
@immutable
class OnlineSuggestion {
  const OnlineSuggestion(this.tag, {this.translation, this.count});
  final String tag;
  final String? translation;
  final int? count;
}

/// “发送到生图”浮层要说清会覆盖什么。
@immutable
class OnlineSendContext {
  const OnlineSendContext({
    this.promptLength = 0,
    this.characterCount = 0,
    this.remembered,
  });

  /// 生图页现在正向的字数和角色框个数（真实状态）。
  final int promptLength;
  final int characterCount;

  /// 用户勾了“记住这次的选择”后存的方式（SharedPreferences）。有值时点“发送到生图”直接按它发，不弹浮层。
  final OnlineSendMode? remembered;
}

/// Wiring supplies isolated, read-only translation. UI keeps the original
/// section layout, hover state and canonical tag search callbacks.
typedef OnlineTranslationBuilder =
    Widget Function(
      BuildContext context,
      String identity,
      String content,
      Widget Function(Widget action, Widget? translated) section,
    );

@immutable
class OnlineActions {
  const OnlineActions({
    this.translationBuilder,
    required this.onSourceChanged,
    required this.onModeChanged,
    required this.onSearch,
    required this.onSuggest,
    required this.onRecent,
    required this.onClearRecent,
    required this.onNaiOnlyChanged,
    required this.onModelChanged,
    required this.onTimeRangeChanged,
    required this.onRatingsChanged,
    required this.onDateRangeChanged,
    required this.onRankPeriodChanged,
    required this.onRankScaleChanged,
    required this.onRankDateChanged,
    required this.onCollectionSelected,
    required this.onAuthorSelected,
    required this.onCreateCollection,
    required this.onRenameCollection,
    required this.onDeleteCollection,
    required this.onMoveToCollection,
    required this.onAuthorWorks,
    required this.onUnfavoriteAuthor,
    required this.onReturn,
    required this.onBlacklistAdd,
    required this.onBlacklistRemove,
    required this.onDanbooruSyncChanged,
    required this.onCardSizeChanged,
    required this.onSidebarChanged,
    required this.onInspectorChanged,
    required this.onSelect,
    required this.onLoadMore,
    required this.onRetryPage,
    required this.onRetry,
    required this.onJumpToPage,
    required this.onRefresh,
    required this.onScrollOffset,
    required this.onToggleFavorite,
    required this.onFavoriteMany,
    required this.onCopyPrompt,
    required this.onDownload,
    required this.onSend,
    required this.onOpenInBrowser,
    required this.onTagTap,
    required this.onToggleAuthorFavorite,
    required this.onOnlyAuthor,
    required this.onLogin,
    required this.onApiKeyHelp,
  });

  final OnlineTranslationBuilder? translationBuilder;

  /// 换来源（`setSource`）。每个来源记住自己的浏览方式、搜索词和滚动位置，接线方不要清掉。
  final ValueChanged<OnlineSource> onSourceChanged;

  /// 换浏览方式（`setViewMode`）。界面只对来源支持的方式回调。
  final ValueChanged<OnlineMode> onModeChanged;

  /// 提交搜索（回车 / 删标签块 / 点最近搜索以外的地方）：AI TAG 用 work + prompt，
  /// Danbooru 系用 tags + fuzzy，收藏用 favoritesFilter。接线方写最近搜索。
  final ValueChanged<OnlineQuery> onSearch;

  /// 标签补全：返回 [fragment]（当前正在输入的词）的候选，最多 8 条。
  /// [prompt] = true 是 AI TAG 的 Prompt 段（按逗号分词），否则按空格分词。
  final Future<List<OnlineSuggestion>> Function(
    String fragment, {
    required bool prompt,
  })
  onSuggest;

  /// 点最近搜索：按种类填回对应搜索段并搜索（作者 = 只看 TA）。
  final ValueChanged<OnlineRecent> onRecent;
  final VoidCallback onClearRecent;

  final ValueChanged<bool> onNaiOnlyChanged;
  final ValueChanged<OnlineModel?> onModelChanged;
  final ValueChanged<String> onTimeRangeChanged;
  final ValueChanged<Set<OnlineRating>> onRatingsChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  /// AI TAG 月榜月份（`setAiTagPopularPeriod`）。
  final ValueChanged<String> onRankPeriodChanged;
  final ValueChanged<OnlineRankScale> onRankScaleChanged;
  final ValueChanged<DateTime> onRankDateChanged;

  /// AI TAG 收藏：选子集（null 全部，[OnlineFavorites.ungroupedId] 未分组）/ 只看某个收藏作者。
  final ValueChanged<String?> onCollectionSelected;
  final ValueChanged<int> onAuthorSelected;

  /// 子集管理（右键菜单、“+”）。新建返回新子集 id。
  final Future<String> Function(String name) onCreateCollection;
  final void Function(String id, String name) onRenameCollection;
  final ValueChanged<String> onDeleteCollection;

  /// 把作品移到子集（拖到左栏 / 右键“移到子集”），走 `moveToCollection`。
  final void Function(List<String> keys, String? collectionId)
  onMoveToCollection;

  /// 作者头部：在 AI TAG 看 TA 的全部作品（以前的“查看此作者”）/ 取消收藏作者。
  final ValueChanged<int> onAuthorWorks;
  final ValueChanged<int> onUnfavoriteAuthor;

  /// 返回只看 TA 之前的结果（`returnFromAiTagAuthorSearch`）。
  final VoidCallback onReturn;

  final ValueChanged<String> onBlacklistAdd;
  final ValueChanged<String> onBlacklistRemove;
  final ValueChanged<bool> onDanbooruSyncChanged;

  final ValueChanged<OnlineCardSize> onCardSizeChanged;
  final ValueChanged<bool> onSidebarChanged;
  final ValueChanged<bool> onInspectorChanged;

  /// 单击卡片 / 方向键 / 大图里切作品：检查器换成这张，接线方开始拉详情。
  final ValueChanged<String> onSelect;

  /// 滚到距底 200 以内（`loadMore`）。界面在 [OnlineList.hasMore] 且没在加载时才回调。
  final VoidCallback onLoadMore;
  final VoidCallback onRetryPage;

  /// 第一页失败后的重试。
  final VoidCallback onRetry;

  /// 跳到页（`goToPage`）。
  final ValueChanged<int> onJumpToPage;
  final VoidCallback onRefresh;

  /// 滚动停下后的位置（`saveScrollOffset`）。
  final ValueChanged<double> onScrollOffset;

  /// 收藏 / 取消收藏一张（F、卡片心形、检查器按钮）。Gelbooru 只读时界面不回调。
  final ValueChanged<String> onToggleFavorite;

  /// 多选“收藏到”：AI TAG 放进子集（null 未分组；[newCollection] 非 null 时先新建再收藏），
  /// Danbooru 直接收藏到网站（忽略子集）。
  final void Function(
    List<String> keys,
    String? collectionId, {
    String? newCollection,
  })
  onFavoriteMany;

  /// 复制 Prompt（Danbooru 系复制标签）。多选时按顺序拼接、每条之间空一行；
  /// AI TAG 没加载详情的先 `loadDetail`（遵守并发槽）。
  final ValueChanged<List<String>> onCopyPrompt;

  /// 下载。[all] = true 时多图作品下载全部图，否则只下当前这张（[mediaIndex]）。
  final void Function(List<String> keys, {bool all, int mediaIndex}) onDownload;

  /// 发送到生图。[remember] = true 时存下 [mode]，以后直接按它发。发送后切到生图页。
  final void Function(String key, OnlineSendMode mode, {bool remember}) onSend;

  final ValueChanged<String> onOpenInBrowser;

  /// 点站点标签 / Danbooru 分组标签：加入当前搜索（AI TAG 作品段、Danbooru 系标签块）并搜索。
  final ValueChanged<String> onTagTap;

  /// 收藏 / 取消收藏这张作品的作者（AI TAG 本地作者收藏）。
  final ValueChanged<String> onToggleAuthorFavorite;

  /// 只看 TA：在 AI TAG 搜这个作者（会记下返回上下文）。
  final ValueChanged<String> onOnlyAuthor;

  /// 登录 Danbooru（`DanbooruLoginDialog`）/ 配置 Gelbooru API Key（`GelbooruCredentialsDialog`）。
  final ValueChanged<OnlineSource> onLogin;

  /// 打开“去哪里拿 API Key”的说明页。
  final ValueChanged<OnlineSource> onApiKeyHelp;

  static final none = OnlineActions(
    onSourceChanged: (_) {},
    onModeChanged: (_) {},
    onSearch: (_) {},
    onSuggest: (_, {required prompt}) async => const [],
    onRecent: (_) {},
    onClearRecent: () {},
    onNaiOnlyChanged: (_) {},
    onModelChanged: (_) {},
    onTimeRangeChanged: (_) {},
    onRatingsChanged: (_) {},
    onDateRangeChanged: (_) {},
    onRankPeriodChanged: (_) {},
    onRankScaleChanged: (_) {},
    onRankDateChanged: (_) {},
    onCollectionSelected: (_) {},
    onAuthorSelected: (_) {},
    onCreateCollection: (_) async => '',
    onRenameCollection: (_, _) {},
    onDeleteCollection: (_) {},
    onMoveToCollection: (_, _) {},
    onAuthorWorks: (_) {},
    onUnfavoriteAuthor: (_) {},
    onReturn: () {},
    onBlacklistAdd: (_) {},
    onBlacklistRemove: (_) {},
    onDanbooruSyncChanged: (_) {},
    onCardSizeChanged: (_) {},
    onSidebarChanged: (_) {},
    onInspectorChanged: (_) {},
    onSelect: (_) {},
    onLoadMore: () {},
    onRetryPage: () {},
    onRetry: () {},
    onJumpToPage: (_) {},
    onRefresh: () {},
    onScrollOffset: (_) {},
    onToggleFavorite: (_) {},
    onFavoriteMany: (_, _, {newCollection}) {},
    onCopyPrompt: (_) {},
    onDownload: (_, {all = false, mediaIndex = 0}) {},
    onSend: (_, _, {remember = false}) {},
    onOpenInBrowser: (_) {},
    onTagTap: (_) {},
    onToggleAuthorFavorite: (_) {},
    onOnlyAuthor: (_) {},
    onLogin: (_) {},
    onApiKeyHelp: (_) {},
  );
}
