import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const onlineRail = 48.0;

/// 按“窗口宽”装一个在线画廊（扣掉主导航），关掉动画，带窗口按钮避让，图片先解码好。
/// 基准图要画真投影：测试体里先 `debugDisableShadows = false`，结束前改回 true。
Future<void> pumpOnline(
  WidgetTester tester, {
  required OnlineViewData data,
  OnlineActions? actions,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - onlineRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(onlineApp(data, actions, locale: locale, dark: dark));
  await precacheOnline(tester, data);
}

Widget onlineApp(
  OnlineViewData data,
  OnlineActions? actions, {
  String locale = 'zh',
  bool dark = false,
}) => RepaintBoundary(
  key: const Key('online-capture'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    locale: locale.contains('_')
        ? Locale(locale.split('_')[0], locale.split('_')[1])
        : Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: WindowChromeScope(
        child: OnlineGalleryPage(
          data: data,
          actions: actions ?? OnlineActions.none,
        ),
      ),
    ),
  ),
);

Future<void> precacheOnline(WidgetTester tester, OnlineViewData data) async {
  final images = <ImageProvider>{
    for (final w in data.list.items) ?w.thumb,
    for (final m in data.detail?.media ?? const <OnlineMedia>[]) ...[
      ?m.thumb,
      ?m.image,
    ],
    ?data.detail?.authorAvatar,
    for (final a in data.favorites?.authors ?? const <OnlineFavoriteAuthor>[])
      ?a.avatar,
  };
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(OnlineGalleryPage));
    for (final i in images) {
      await precacheImage(i, ctx);
    }
  });
  await tester.pumpAndSettle();
}

Future<TestGesture> hoverOver(WidgetTester tester, Finder f) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  await g.moveTo(tester.getCenter(f));
  await tester.pumpAndSettle();
  return g;
}

/// 记录所有回调，断言用。
class RecordingOnlineActions {
  final calls = <String>[];
  final searches = <OnlineQuery>[];
  final sends = <(String, OnlineSendMode, bool)>[];
  final selects = <String>[];
  final favorites = <String>[];
  final favoriteMany = <(List<String>, String?, String?)>[];
  final moves = <(List<String>, String?)>[];
  final copies = <List<String>>[];
  final downloads = <(List<String>, bool, int)>[];

  void _c(String s) => calls.add(s);

  OnlineActions get actions => OnlineActions(
    onSourceChanged: (s) => _c('source:${s.name}'),
    onModeChanged: (m) => _c('mode:${m.name}'),
    onSearch: searches.add,
    onSuggest: (frag, {required prompt}) async => [
      if ('ocean'.startsWith(frag))
        const OnlineSuggestion('ocean', translation: '海洋', count: 182000),
      if ('ocean_view'.startsWith(frag))
        const OnlineSuggestion('ocean_view', count: 3400),
    ],
    onRecent: (r) => _c('recent:${r.text}'),
    onClearRecent: () => _c('clearRecent'),
    onNaiOnlyChanged: (v) => _c('naiOnly:$v'),
    onModelChanged: (m) => _c('model:${m?.name}'),
    onTimeRangeChanged: (t) => _c('time:$t'),
    onRatingsChanged: (r) => _c('ratings:${r.map((x) => x.name).join(',')}'),
    onDateRangeChanged: (r) => _c('date:$r'),
    onRankPeriodChanged: (p) => _c('period:$p'),
    onRankScaleChanged: (s) => _c('scale:${s.name}'),
    onRankDateChanged: (d) => _c('rankDate:${d.toIso8601String()}'),
    onCollectionSelected: (id) => _c('collection:$id'),
    onAuthorSelected: (id) => _c('author:$id'),
    onCreateCollection: (name) async {
      _c('create:$name');
      return 'new';
    },
    onRenameCollection: (id, name) => _c('rename:$id:$name'),
    onDeleteCollection: (id) => _c('delete:$id'),
    onMoveToCollection: (keys, id) => moves.add((keys, id)),
    onAuthorWorks: (id) => _c('authorWorks:$id'),
    onUnfavoriteAuthor: (id) => _c('unfavAuthor:$id'),
    onReturn: () => _c('return'),
    onBlacklistAdd: (t) => _c('blAdd:$t'),
    onBlacklistRemove: (t) => _c('blRemove:$t'),
    onDanbooruSyncChanged: (v) => _c('sync:$v'),
    onCardSizeChanged: (s) => _c('size:${s.name}'),
    onSidebarChanged: (v) => _c('sidebar:$v'),
    onInspectorChanged: (v) => _c('inspector:$v'),
    onSelect: selects.add,
    onLoadMore: () => _c('loadMore'),
    onRetryPage: () => _c('retryPage'),
    onRetry: () => _c('retry'),
    onJumpToPage: (p) => _c('jump:$p'),
    onRefresh: () => _c('refresh'),
    onScrollOffset: (_) {},
    onToggleFavorite: favorites.add,
    onFavoriteMany: (keys, id, {newCollection}) =>
        favoriteMany.add((keys, id, newCollection)),
    onCopyPrompt: copies.add,
    onDownload: (keys, {all = false, mediaIndex = 0}) =>
        downloads.add((keys, all, mediaIndex)),
    onSend: (key, mode, {remember = false}) => sends.add((key, mode, remember)),
    onOpenInBrowser: (k) => _c('open:$k'),
    onTagTap: (t) => _c('tag:$t'),
    onToggleAuthorFavorite: (k) => _c('favAuthor:$k'),
    onOnlyAuthor: (k) => _c('onlyAuthor:$k'),
    onLogin: (s) => _c('login:${s.name}'),
    onApiKeyHelp: (s) => _c('apiKeyHelp:${s.name}'),
  );
}
