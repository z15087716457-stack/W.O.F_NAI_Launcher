// 在线画廊假数据：预览入口、交互测试、基准截图和原型对照共用。
// 标题、作者、数字照 HTML 原型（.devin/mockups/online/mock.html）的示意数据。
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

import 'online_contract.dart';

/// 按图片键（原型里的 `c03`、`t08`……）取图；null 时卡片画控件底。
typedef OnlineImageLoader = ImageProvider? Function(String key);

abstract final class OnlineFixture {
  /// 默认图：按键生成一张小渐变图（不依赖仓库外的文件）。
  static ImageProvider gradient(String key) =>
      _cache.putIfAbsent(key, () => MemoryImage(_gradientPng(key)));

  static final _cache = <String, ImageProvider>{};

  static Uint8List _gradientPng(String key) {
    final h = key.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0xFFFFFF);
    final image = img.Image(width: 24, height: 32);
    final a = _hsv((h % 360).toDouble(), .45, .80);
    final b = _hsv(((h ~/ 7) % 360).toDouble(), .55, .35);
    for (var y = 0; y < 32; y++) {
      final t = y / 31;
      for (var x = 0; x < 24; x++) {
        final u = (t * .8 + x / 23 * .2).clamp(0, 1);
        image.setPixelRgb(
          x,
          y,
          (a.$1 + (b.$1 - a.$1) * u).round(),
          (a.$2 + (b.$2 - a.$2) * u).round(),
          (a.$3 + (b.$3 - a.$3) * u).round(),
        );
      }
    }
    return img.encodePng(image);
  }

  static (int, int, int) _hsv(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - ((h / 60) % 2 - 1).abs());
    final m = v - c;
    final (r, g, b) = switch (h ~/ 60) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return (
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }

  /// 比例 → 原图尺寸（短边 1000，保证比例和原型一致）。
  static (int, int) _dims(double r) =>
      r >= 1 ? ((r * 1000).round(), 1000) : (1000, (1000 / r).round());

  static const _w = [
    ('c03', .68, '星降る夜', 'アイんむー', 12840, 962, 4, 'V4.5'),
    ('t08', 1.46, '無題', 'Shimozawa', 5420, 311, 1, 'V4.5'),
    ('c14', .68, '堕天使——周末的追忆与琉璃', '2000年的寂寞', 9310, 840, 12, 'V4.5'),
    ('t12', 1.76, '夜行列車', 'LaraZoa', 3022, 188, 3, 'V4'),
    ('c16', .68, '久しぶりのみゃー', 'にくまん', 7731, 604, 2, 'V4.5'),
    ('t37', 1.0, '無題', 'ブラツ', 2210, 97, 1, 'V3'),
    ('c15', .68, '水中散歩', '琉璃', 6105, 455, 6, 'V4.5'),
    ('t10', 2.39, '灯籠流し', 'Thx', 1840, 120, 1, 'V4.5'),
    ('c12', .68, 'ネオン街', 'haha', 4412, 286, 1, 'V5'),
    ('t19', 1.46, '白昼夢', 'mofu', 3390, 201, 2, 'V4.5'),
    ('c19', .68, '海辺のカフェ', '夜鷹', 2954, 174, 1, 'V4.5'),
    ('t04', .77, '放課後の屋上', 'アイんむー', 8820, 701, 5, 'V4.5'),
    ('c05', .68, '月下美人', '進捗ダメです', 5177, 390, 1, 'V4'),
    ('t36', 1.6, '風の通り道', 'Shimozawa', 1504, 66, 1, 'V4.5'),
    ('c08', .68, '青の群像', 'LaraZoa', 6630, 512, 8, 'V4.5'),
    ('t24', 1.0, '秘密基地', 'にくまん', 2380, 143, 1, 'V5'),
    ('c10', .68, '廃墟の朝', 'ブラツ', 3011, 208, 1, 'V4.5'),
    ('t27', 1.46, '帰り道', '琉璃', 1960, 87, 2, 'V4.5'),
    ('c02', .68, '雨宿り', 'Thx', 4890, 333, 1, 'V4.5'),
    ('c06', .68, '春の訪れ', 'haha', 2275, 150, 3, 'V4'),
    ('t41', 1.46, '深海', 'mofu', 3720, 244, 1, 'V4.5'),
    ('c04', .68, '蒼', '夜鷹', 5233, 401, 1, 'V4.5'),
    ('c20', .68, '猫と少女', 'アイんむー', 6402, 498, 2, 'V4.5'),
    ('t44', 1.61, '赤い回廊', '2000年的寂寞', 1222, 58, 1, 'V4.5'),
    ('c01', .68, '無題', '進捗ダメです', 980, 41, 1, 'V4.5'),
    ('c11', .68, '夏の終わり', 'Shimozawa', 2101, 132, 1, 'V4.5'),
    ('t05', .7, '星海', 'LaraZoa', 3399, 260, 4, 'V4.5'),
    ('c17', .68, '無題', 'ブラツ', 1677, 90, 1, 'V3'),
  ];

  static const _db = [
    ('c04', .68, 'g', 412, 380),
    ('t09', 1.46, 's', 288, 260),
    ('c05', .68, 'g', 356, 301),
    ('c02', .68, 's', 198, 177),
    ('t16', 1.46, 'g', 240, 211),
    ('c06', .68, 'g', 175, 160),
    ('t07', 1.0, 's', 301, 288),
    ('c20', .68, 'g', 150, 141),
    ('c13', .68, 'q', 122, 115),
    ('t35', 1.46, 'g', 190, 170),
    ('c09', .68, 'g', 133, 121),
    ('c18', .68, 's', 102, 96),
    ('t45', 1.46, 'g', 88, 80),
    ('c07', .68, 's', 97, 90),
    ('t14', .71, 'g', 77, 70),
    ('c16', .68, 'g', 64, 61),
    ('t49', 1.46, 'g', 59, 52),
    ('c19', .68, 's', 58, 50),
    ('t26', .71, 'g', 51, 44),
    ('c03', .68, 'g', 47, 40),
  ];

  static const _authors = [
    ('LaraZoa', 'c08', 24),
    ('にくまん', 'c16', 19),
    ('2000年的寂寞', 'c14', 17),
    ('進捗ダメです', 'c05', 12),
    ('ブラツ', 'c10', 9),
    ('Thx', 'c02', 7),
    ('haha', 'c12', 5),
  ];

  static const prompt =
      '1girl, solo, white hair, long hair, blue eyes, sailor collar, school uniform, '
      'partially submerged, ocean, light rays, looking at viewer, 0.8::artist:ningen mame::, '
      'artist:ciloranko, 1.2::artist:wlop::, year 2025, very aesthetic, masterpiece, no text';
  static const negative =
      'lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, '
      'worst quality, jpeg artifacts, signature, watermark, blurry';
  static const siteTags = [
    'オリジナル',
    '女の子',
    '白髪',
    '海',
    'NovelAI',
    'セーラー服',
    '透明感',
  ];

  static const sources = [
    OnlineSourceStatus(
      source: OnlineSource.aiTag,
      ranking: true,
      favorites: true,
      favoritesWritable: true,
      favoritesLocal: true,
      promptQuery: true,
      multiMedia: true,
    ),
    OnlineSourceStatus(
      source: OnlineSource.danbooru,
      ranking: true,
      favorites: true,
      favoritesWritable: true,
      ratings: true,
      dateRange: true,
      fuzzy: true,
      account: OnlineAccountState.signedIn,
      accountName: 'piedriver',
    ),
    OnlineSourceStatus(
      source: OnlineSource.safebooru,
      ranking: true,
      dateRange: true,
      fuzzy: true,
    ),
    OnlineSourceStatus(
      source: OnlineSource.gelbooru,
      favorites: true,
      ratings: true,
      dateRange: true,
      fuzzy: true,
      account: OnlineAccountState.keyConfigured,
    ),
  ];

  static const recent = [
    OnlineRecent(kind: OnlineRecentKind.work, text: 'ocean'),
    OnlineRecent(kind: OnlineRecentKind.prompt, text: 'artist:ciloranko'),
    OnlineRecent(kind: OnlineRecentKind.author, text: 'アイんむー'),
    OnlineRecent(kind: OnlineRecentKind.work, text: '1girl, white hair'),
    OnlineRecent(kind: OnlineRecentKind.prompt, text: '::artist:wlop::'),
    OnlineRecent(kind: OnlineRecentKind.work, text: '夜景 V4.5'),
  ];

  static const blacklist = OnlineBlacklist(
    tags: [
      'guro', 'comic', 'text_focus', 'monochrome', 'furry', 'lowres', //
      'watermark', 'censored', '3d', 'realistic', 'ai-generated', 'sketch',
    ],
    danbooruSync: true,
    danbooruCount: 5,
  );

  static const months = [
    '2026-09',
    '2026-08',
    '2026-07',
    '2026-06',
    '2026-05',
    '2026-04',
  ];
  static const timeRanges = [
    'all',
    'y2026',
    'q2026Q3',
    'q2026Q2',
    'y2025',
    'older',
  ];

  /// AI TAG 作品（原型 `W`）。
  static List<OnlineWork> aiTagWorks({
    OnlineImageLoader? image,
    Set<int> favorited = const {4},
    bool ranked = false,
    String? author,
  }) {
    final load = image ?? gradient;
    return [
      for (final (i, (k, r, t, a, v, f, n, m)) in _w.indexed)
        () {
          final (w, h) = _dims(r);
          return OnlineWork(
            key: k,
            id: 2158843 + i * 311,
            thumb: load(k),
            width: w,
            height: h,
            title: t,
            author: author ?? a,
            authorId: a.hashCode & 0xFFFF,
            views: v,
            favorites: f,
            mediaCount: n,
            model: m,
            favorited: favorited.contains(i),
            rank: ranked ? i + 1 : null,
          );
        }(),
    ];
  }

  /// Danbooru 帖子（原型 `DB`）。
  static List<OnlineWork> booruPosts({
    OnlineImageLoader? image,
    bool ranked = false,
  }) {
    final load = image ?? gradient;
    return [
      for (final (i, (k, r, rt, sc, f)) in _db.indexed)
        () {
          final (w, h) = _dims(r);
          return OnlineWork(
            key: 'db-$k',
            id: 7400000 + i * 137,
            thumb: load(k),
            width: w,
            height: h,
            score: sc,
            favorites: f,
            rating: switch (rt) {
              'g' => OnlineRating.general,
              's' => OnlineRating.sensitive,
              'q' => OnlineRating.questionable,
              _ => OnlineRating.explicit,
            },
            rank: ranked ? i + 1 : null,
          );
        }(),
    ];
  }

  static OnlineFavorites favorites({
    OnlineImageLoader? image,
    String? collectionId,
    int? authorId,
  }) {
    final load = image ?? gradient;
    return OnlineFavorites(
      total: 163,
      ungrouped: 41,
      collections: const [
        OnlineCollection(id: 'style', name: '画风参考', count: 58),
        OnlineCollection(id: 'comp', name: '构图', count: 22),
        OnlineCollection(id: 'color', name: '色彩', count: 42),
      ],
      authors: [
        for (final (i, (n, k, c)) in _authors.indexed)
          OnlineFavoriteAuthor(
            id: 100 + i,
            name: n,
            count: c,
            avatar: load(k),
            savedAt: DateTime(2026, 8, 12),
          ),
      ],
      collectionId: collectionId,
      authorId: authorId,
    );
  }

  /// AI TAG 详情（原型检查器：多图 4 张，第一张是卡片图）。
  static OnlineDetail aiTagDetail(
    OnlineWork w, {
    OnlineImageLoader? image,
    bool loading = false,
  }) {
    final load = image ?? gradient;
    if (loading) return OnlineDetail(key: w.key, loading: true);
    final keys = [
      w.key,
      'c08',
      'c04',
      'c19',
      'c15',
      'c16',
      'c20',
      'c12',
      'c06',
      'c05',
      'c18',
      'c03',
    ];
    return OnlineDetail(
      key: w.key,
      media: [
        for (final k in keys.take(w.mediaCount))
          OnlineMedia(
            thumb: load(k),
            image: load(k),
            width: k == w.key ? w.width : 1000,
            height: k == w.key ? w.height : 1471,
          ),
      ],
      createdAt: DateTime(2026, 9, 28),
      prompt: prompt,
      negative: negative,
      params: const OnlineParams(
        model: 'NAI Diffusion V4.5 Full',
        width: 832,
        height: 1216,
        seed: 1313949686,
        sampler: 'Euler Ancestral',
        steps: 28,
        cfg: 5,
      ),
      siteTags: siteTags,
      authorSavedCount: 12,
      authorAvatar: load('c20'),
      canSendParams: true,
    );
  }

  /// Danbooru 帖子详情（原型检查器）。
  static OnlineDetail booruDetail(OnlineWork w, {OnlineImageLoader? image}) {
    return OnlineDetail(
      key: w.key,
      media: [
        OnlineMedia(thumb: w.thumb, image: w.thumb, width: 1240, height: 1754),
      ],
      fileType: 'PNG',
      fileBytes: 2202010,
      tagGroups: const {
        OnlineTagGroup.artist: [OnlineTag('ningen_mame')],
        OnlineTagGroup.copyright: [
          OnlineTag('blue_archive', translation: '蔚蓝档案'),
        ],
        OnlineTagGroup.character: [
          OnlineTag('shiroko_(blue_archive)', translation: '砂狼白子'),
        ],
        OnlineTagGroup.general: [
          OnlineTag('1girl', translation: '1个女孩'),
          OnlineTag('solo', translation: '单人'),
          OnlineTag('animal_ears', translation: '兽耳'),
          OnlineTag('grey_hair', translation: '灰发'),
          OnlineTag('blue_eyes', translation: '蓝眼睛'),
          OnlineTag('scarf', translation: '围巾'),
        ],
      },
    );
  }

  /// 原型主界面（`#a`）：AI TAG 搜索 “ocean”，选中第一张，已加载 128 张 · 3 页。
  static OnlineViewData view({
    OnlineImageLoader? image,
    OnlineSource source = OnlineSource.aiTag,
    OnlineMode mode = OnlineMode.search,
    OnlineCardSize cardSize = OnlineCardSize.medium,
    bool inspectorOpen = true,
    bool sidebarOpen = true,
    List<OnlineSourceStatus>? statuses,
    OnlineList? list,
    String? selectedKey = 'c03',
    bool detailLoading = false,
    String? collectionId,
    int? authorId,
    OnlineQuery? query,
    OnlineFilters? filters,
    OnlineSendContext send = const OnlineSendContext(
      promptLength: 386,
      characterCount: 2,
    ),
  }) {
    final booru = source != OnlineSource.aiTag;
    final ranked = mode == OnlineMode.ranking;
    final fav = mode == OnlineMode.favorites && !booru;
    final works = booru
        ? booruPosts(image: image, ranked: ranked)
        : fav && authorId != null
        ? [
            for (final (i, w) in aiTagWorks(
              image: image,
              author: 'LaraZoa',
            ).indexed)
              if (i % 3 != 1) w,
          ]
        : fav
        ? (() {
            final all = aiTagWorks(image: image, favorited: const {});
            return [
              for (final w in [...all.skip(2), ...all.take(2)])
                OnlineWork(
                  key: w.key,
                  id: w.id,
                  thumb: w.thumb,
                  width: w.width,
                  height: w.height,
                  title: w.title,
                  author: w.author,
                  views: w.views,
                  favorites: w.favorites,
                  mediaCount: w.mediaCount,
                  model: w.model,
                  favorited: true,
                ),
            ];
          })()
        : aiTagWorks(image: image, ranked: ranked);
    final l =
        list ??
        OnlineList(
          key: '${source.name}:${mode.name}',
          items: works,
          pages: booru ? 6 : (ranked ? 1 : 3),
          hasMore: !fav,
        );
    final key = selectedKey == 'c03' && booru ? 'db-c04' : selectedKey;
    final selected = key == null
        ? null
        : l.items.where((w) => w.key == key).firstOrNull ??
              (fav ? l.items.firstOrNull : null);
    return OnlineViewData(
      source: source,
      sources: statuses ?? sources,
      mode: mode,
      query:
          query ??
          (booru
              ? const OnlineQuery(
                  tags: ['shiroko_(blue_archive)', '1girl', '-comic'],
                )
              : mode == OnlineMode.search
              ? const OnlineQuery(work: 'ocean')
              : const OnlineQuery()),
      filters:
          filters ??
          OnlineFilters(
            timeRanges: timeRanges,
            ratings: booru
                ? const {OnlineRating.general, OnlineRating.sensitive}
                : const OnlineFilters().ratings,
          ),
      ranking: OnlineRanking(months: months, date: DateTime(2026, 10, 5)),
      recent: recent,
      favorites: source == OnlineSource.aiTag
          ? favorites(
              image: image,
              collectionId: collectionId,
              authorId: authorId,
            )
          : null,
      blacklist: blacklist,
      list: l,
      selectedKey: selected?.key,
      detail: selected == null
          ? null
          : booru
          ? booruDetail(selected, image: image)
          : aiTagDetail(selected, image: image, loading: detailLoading),
      cardSize: cardSize,
      sidebarOpen: sidebarOpen,
      inspectorOpen: inspectorOpen,
      send: send,
    );
  }
}
