import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'blocks_contract.dart';

/// 块系统假数据：标题和文件夹名取自用户截图（同原型 `BK`），内容 / 项数 / 次数是示意。
/// 预览、测试、和原型对照都用这一份。
abstract final class BlocksFixture {
  static final now = DateTime(2026, 10, 11, 20, 0);

  static const _slate = Color(0xFF607D8B);
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFB8C00);
  static const _yellow = Color(0xFFFDD835);
  static const _green = Color(0xFF43A047);
  static const _cyan = Color(0xFF00ACC1);
  static const _blue = Color(0xFF1E88E5);
  static const _purple = Color(0xFF8E24AA);
  static const _pink = Color(0xFFD81B60);

  static const tagPerson = BlockTag('人物', Color(0xFF2563EB));
  static const tagQuality = BlockTag('质量', Color(0xFF16A34A));
  static const tagNegative = BlockTag('负面', Color(0xFFDC2626));
  static const tagLab = BlockTag('实验', Color(0xFF9333EA));
  static const tagV5 = BlockTag('V5 专用', Color(0xFFEA580C));

  static const catalog = BlockParamCatalog(
    models: {
      'nai-diffusion-4-5-full': 'V4.5 Full',
      'nai-diffusion-4-5-curated': 'V4.5 Curated',
      'nai-diffusion-5-full': 'V5 Full',
    },
    samplers: {
      'k_euler_ancestral': 'Euler Ancestral',
      'k_euler': 'Euler',
      'k_dpmpp_2s_ancestral': 'DPM++ 2S Ancestral',
      'k_dpmpp_2m_sde': 'DPM++ 2M SDE',
    },
    noiseSchedules: {
      'karras': 'Karras',
      'exponential': 'Exponential',
      'polyexponential': 'Polyexponential',
    },
  );

  static const y99Params = BlockParams(
    model: 'nai-diffusion-4-5-full',
    steps: 28,
    scale: 5,
    cfgRescale: 0,
    sampler: 'k_euler_ancestral',
  );

  /// 文件夹（树序）：画风下面两个子文件夹。
  static const folders = [
    BlocksFolder(id: 'f-style', name: '画风', count: 164, hasChildren: true),
    BlocksFolder(
      id: 'f-style-3d',
      name: '3D 与写实',
      count: 18,
      parentId: 'f-style',
      depth: 1,
    ),
    BlocksFolder(
      id: 'f-style-line',
      name: '线稿',
      count: 9,
      parentId: 'f-style',
      depth: 1,
    ),
    BlocksFolder(id: 'f-official', name: 'NovelAI 官方预设', count: 12),
    BlocksFolder(id: 'f-char', name: '角色', count: 73),
    BlocksFolder(id: 'f-general', name: '通用', count: 21),
    BlocksFolder(id: 'f-func', name: '功能', count: 48),
    BlocksFolder(id: 'f-v5', name: 'V5', count: 26),
    BlocksFolder(id: 'f-wardrobe', name: '衣柜', count: 171),
    BlocksFolder(id: 'f-chain', name: '串串', count: 50),
    BlocksFolder(id: 'f-artists', name: '画师集', count: 97),
    BlocksFolder(id: 'f-nsfw', name: '瑟瑟', count: 15),
  ];

  static const collections = [
    BlocksCollection(id: 'k-artists', name: '常用画师', count: 8),
    BlocksCollection(id: 'k-daily', name: '日常出图', count: 4),
  ];

  static const tags = [
    BlocksTagInfo(tagPerson, 42),
    BlocksTagInfo(tagQuality, 18),
    BlocksTagInfo(tagNegative, 11),
    BlocksTagInfo(tagLab, 7),
    BlocksTagInfo(tagV5, 26),
  ];

  static const _folderNames = {
    'f-style': '画风',
    'f-official': 'NovelAI 官方预设',
    'f-char': '角色',
    'f-general': '通用',
    'f-func': '功能',
    'f-v5': 'V5',
    'f-wardrobe': '衣柜',
    'f-artists': '画师集',
  };

  static const _artists = [
    'ciloranko', 'sincos', 'rella', 'mika pikazo', 'fuzichoco', 'kantoku', //
    'atdan', 'modare', 'wlop', 'ningen mame', 'yoneyama mai', 'nardack',
    'tiv', 'asteroid_ill', 'hiten', 'mignon', 'void_0', 'kawacy',
  ];

  static List<String> _pool(int n, List<String> head) => [
    ...head,
    for (var i = head.length; i < n; i++)
      'artist:${_artists[i % _artists.length]}${i ~/ _artists.length == 0 ? '' : ' ${i ~/ _artists.length + 1}'}',
  ];

  /// (key, 标题, 颜色, 图标, 文件夹, 预览图 key, 收藏, 用过, 正文, 项数, 负面, 改动距今天数)
  static const _rows = <(String, String, Color, String?, String, String?, bool, int, String, int, bool, int)>[
    (
      'y99',
      '1999',
      _slate,
      null,
      'f-style',
      'c02',
      false,
      31,
      '{{artist:yoneyama mai}}, {rella}, {artist:raoem}, ximo, year 2024, {{{reverse:1999}}}, grey theme, depth of field, cinematic lighting',
      9,
      false,
      0,
    ),
    (
      'pk',
      '400精选画师池',
      _pink,
      'palette',
      'f-artists',
      null,
      true,
      126,
      'artist:ciloranko, artist:sincos, artist:rella, artist:mika pikazo, artist:fuzichoco, artist:kantoku, artist:atdan, artist:modare',
      400,
      false,
      1,
    ),
    (
      'cy',
      '苍羽凛',
      _blue,
      'person',
      'f-char',
      'c05',
      true,
      52,
      'girl, 1.5::loli, child::, 1.4::silver hair::, 1.3::long hair::, 0.3::fluffy hair, messy hair::, pale skin, hair between eyes, blue eyes',
      41,
      false,
      1,
    ),
    (
      'bl',
      '收藏艺术家池',
      _cyan,
      'palette',
      'f-artists',
      null,
      true,
      88,
      'artist:asteroid_ill, artist:ningen mame, artist:yoneyama mai, artist:nardack, artist:tiv',
      86,
      false,
      2,
    ),
    (
      'd3',
      '3D写实',
      _slate,
      null,
      'f-style',
      'c17',
      false,
      14,
      '3d, realistic, photorealistic, octane render, subsurface scattering, ray tracing, 8k',
      7,
      false,
      2,
    ),
    (
      'fj',
      '风景, 全景, 从后方, 绿…',
      _green,
      'landscape',
      'f-general',
      null,
      false,
      22,
      'scenery, panorama, from behind, green theme, blue theme, plant, detailed background',
      7,
      false,
      3,
    ),
    (
      'aq',
      'amazing quality',
      _orange,
      'sparkle',
      'f-official',
      null,
      true,
      210,
      'amazing quality, very aesthetic, masterpiece, absurdres',
      4,
      false,
      4,
    ),
    (
      'sy',
      '空白页, 水印, 过多水印',
      _red,
      'shield',
      'f-general',
      null,
      true,
      64,
      'blank page, watermark, too many watermarks, signature, text, logo',
      6,
      true,
      4,
    ),
    (
      'ak',
      'akakura',
      _slate,
      null,
      'f-style',
      'c07',
      false,
      6,
      'artist:akakura, 0.8::sketch::, lineart',
      3,
      false,
      5,
    ),
    (
      'pf',
      '黑色小披肩, 蓝色蝴蝶…',
      _purple,
      'dress',
      'f-wardrobe',
      null,
      false,
      17,
      'black capelet, blue butterfly brooch, white blouse, ruffled shirt, long sleeves, frilled cuffs',
      6,
      false,
      5,
    ),
    (
      'zr',
      '1.05::自然色彩, 柔和色…',
      _orange,
      'sun',
      'f-style',
      null,
      false,
      19,
      '1.05::natural colors::, soft colors, pastel colors, muted colors',
      4,
      false,
      6,
    ),
    (
      'af',
      'airfish-asteroid',
      _slate,
      null,
      'f-style',
      'c08',
      false,
      4,
      'artist:airfish, artist:asteroid_ill, 0.6::watercolor::, soft lighting',
      4,
      false,
      7,
    ),
    (
      'lk',
      '0.8::轮廓光, 环境光',
      _yellow,
      'sparkle',
      'f-general',
      null,
      false,
      27,
      '0.8::rim light, ambient light::',
      1,
      false,
      8,
    ),
    (
      'ao',
      'AO酱',
      _blue,
      'person',
      'f-char',
      'c12',
      false,
      9,
      '1girl, ao-chan, blue hair, short hair, ahoge, blue eyes, school uniform',
      18,
      false,
      9,
    ),
    (
      'yb',
      '眼睛崩坏, 空洞的眼睛',
      _red,
      'shield',
      'f-general',
      null,
      false,
      41,
      'bad eyes, empty eyes, asymmetrical eyes, cross-eyed, extra pupils, heterochromia',
      6,
      true,
      10,
    ),
    (
      'kx',
      '0.80::看向观者',
      _slate,
      null,
      'f-general',
      null,
      false,
      30,
      '0.8::looking at viewer::, 1.03::facing viewer::',
      2,
      false,
      11,
    ),
    (
      'yr',
      '2026年, 2025年',
      _slate,
      null,
      'f-v5',
      null,
      false,
      40,
      'year 2026, year 2025',
      2,
      false,
      12,
    ),
    (
      'xs',
      '1.5::像素线稿',
      _orange,
      'brush',
      'f-style',
      null,
      false,
      5,
      '1.5::pixel art::, 0.55::lineart::, limited palette',
      3,
      false,
      12,
    ),
    (
      'hz',
      '画师合作, 发光皮肤',
      _pink,
      'palette',
      'f-artists',
      null,
      false,
      3,
      'artist collaboration, glowing skin, artist:wlop, artist:hiten, artist:mignon',
      5,
      false,
      13,
    ),
    (
      'ne',
      'nero claudius (fate)',
      _red,
      'person',
      'f-char',
      null,
      false,
      7,
      'nero claudius (fate)',
      1,
      false,
      14,
    ),
    (
      'ka',
      'KA酱',
      _blue,
      'person',
      'f-char',
      null,
      false,
      6,
      '1girl, ka-chan, red hair, twintails, green eyes',
      20,
      false,
      15,
    ),
    (
      'ln',
      '乐奈',
      _blue,
      'person',
      'f-char',
      'c16',
      false,
      12,
      '1girl, kaname rana, white hair, heterochromia, cat ears',
      24,
      false,
      16,
    ),
  ];

  static List<BlockData> blocks([ImageProvider Function(String key)? image]) {
    final load = image ?? UiFixtureImage.gradient;
    return [
      for (final (i, r) in _rows.indexed)
        BlockData(
          id: r.$1,
          title: r.$2,
          color: r.$3,
          icon: r.$4,
          folderId: r.$5,
          folderName: _folderNames[r.$5],
          thumb: r.$6 == null
              ? null
              : BlockThumb(load(r.$6!), offsetY: r.$1 == 'cy' ? -.45 : -.5),
          favorite: r.$7,
          useCount: r.$8,
          atoms: r.$11 ? const [] : _atoms(r.$9, r.$10),
          negativeAtoms: r.$1 == 'y99'
              ? const ['lowres', 'jpeg artifacts', 'blurry']
              : const [],
          params: r.$1 == 'y99' ? y99Params : null,
          tags: switch (r.$1) {
            'y99' => const [tagLab, tagQuality],
            'cy' || 'ao' || 'ka' || 'ln' || 'ne' => const [tagPerson],
            'aq' => const [tagQuality],
            'yr' => const [tagV5],
            _ => const [],
          },
          look: switch (r.$1) {
            'kx' => BlockAppearance.stripes,
            'lk' => BlockAppearance.gradient,
            _ => BlockAppearance.classic,
          },
          createdAt: DateTime(2026, 8, 21 + i % 7, 18),
          updatedAt: now.subtract(Duration(days: r.$12, minutes: 66 + i * 13)),
          sourcePath: r.$1 == 'y99' ? 'artists/1999.txt' : null,
          importedAt: r.$1 == 'y99' ? DateTime(2026, 8, 21, 18) : null,
          sourceState: r.$1 == 'y99'
              ? BlockSourceState.synced
              : BlockSourceState.none,
        ).withNegative(r.$11 ? _atoms(r.$9, r.$10) : null),
    ];
  }

  static List<String> _atoms(String text, int n) {
    final head = text.split(', ');
    return n <= head.length ? head.take(n).toList() : _pool(n, head);
  }

  static BlockData byId(String id, [ImageProvider Function(String)? image]) =>
      blocks(image).firstWhere((b) => b.id == id);

  /// 管理页卡片墙的顺序（原型 `GRID_KEYS`），其余排在后面。
  static const grid = [
    'y99', 'pk', 'cy', 'bl', 'd3', 'fj', 'aq', 'sy', //
    'ak', 'pf', 'zr', 'af', 'lk', 'ao', 'yb', 'kx',
  ];

  static BlocksLibraryViewData library({
    ImageProvider Function(String)? image,
    String? selectedId = 'y99',
    BlocksScope scope = const BlocksScope.all(),
    BlocksView view = BlocksView.grid,
    BlocksSort sort = BlocksSort.updated,
    Set<BlocksQuick> quick = const {},
    String query = '',
    bool empty = false,
    bool loading = false,
    double cardSize = .5,
    bool inspectorOpen = true,
    bool sidebarOpen = true,
    List<BlockData>? blocks,
  }) {
    final all = BlocksFixture.blocks(image);
    final ordered = [
      for (final k in grid) all.firstWhere((b) => b.id == k),
      ...all.where((b) => !grid.contains(b.id)),
    ];
    return BlocksLibraryViewData(
      now: now,
      loading: loading,
      blocks: empty ? const [] : (blocks ?? ordered),
      counts: empty
          ? const BlocksCounts()
          : const BlocksCounts(
              all: 703,
              recent: 32,
              favorites: 12,
              uncategorized: 26,
            ),
      folders: empty ? const [] : folders,
      collections: empty ? const [] : collections,
      tags: empty ? const [] : tags,
      scope: scope,
      sort: sort,
      view: view,
      quick: quick,
      query: query,
      cardSize: cardSize,
      selectedId: empty ? null : selectedId,
      inspectorOpen: inspectorOpen,
      sidebarOpen: sidebarOpen,
      catalog: catalog,
      paletteIds: const {'aq'},
    );
  }

  static BlocksDockViewData dock({
    ImageProvider Function(String)? image,
    BlocksDockFilter filter = const BlocksDockFilter.all(),
    String query = '',
  }) {
    final all = blocks(image);
    BlockData b(String id) => all.firstWhere((x) => x.id == id);
    List<BlockData> extra(
      String prefix,
      Color color,
      String icon,
      List<String> names,
    ) => [
      for (final (i, n) in names.indexed)
        BlockData(
          id: '$prefix$i',
          title: n,
          color: color,
          icon: icon,
          atoms: const ['artist:example'],
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final groups = [
      BlocksDockGroup(
        id: 'f-artists',
        name: '画师集',
        count: 97,
        blocks: [
          b('pk'),
          b('bl'),
          b('hz'),
          ...extra('pa', _pink, 'palette', ['厚涂系 12 人', '赛璐璐系']),
          ...extra('pc', _cyan, 'palette', ['水彩画师']),
        ],
      ),
      BlocksDockGroup(
        id: 'f-style',
        name: '画风',
        count: 164,
        blocks: [
          b('y99'),
          b('d3'),
          b('ak'),
          b('af'),
          b('zr'),
          b('xs'),
          ...extra('st', _slate, '', ['0.7::写实']),
          ...extra('sp', _purple, 'sparkle', ['幻梦']),
        ],
      ),
      BlocksDockGroup(
        id: 'f-char',
        name: '角色',
        count: 73,
        blocks: [
          b('cy'),
          b('ka'),
          ...extra('ch', _blue, 'person', ['碧 悠纪', '莲见 慕心']),
          b('ln'),
          b('ao'),
          b('ne'),
        ],
      ),
      BlocksDockGroup(
        id: 'f-wardrobe',
        name: '衣柜',
        count: 171,
        blocks: [
          b('pf'),
          ...extra('wd', _purple, 'dress', ['哥特萝莉裙', '水手服']),
        ],
      ),
    ];
    final q = query.trim().toLowerCase();
    return BlocksDockViewData(
      total: 703,
      query: query,
      filter: filter,
      chips: const [
        BlocksDockChip(id: 'f-artists', name: '画师集', count: 97),
        BlocksDockChip(id: 'f-style', name: '画风', count: 164),
        BlocksDockChip(id: 'f-char', name: '角色', count: 73),
        BlocksDockChip(id: 'f-wardrobe', name: '衣柜', count: 171),
        BlocksDockChip(id: 'f-chain', name: '串串', count: 50),
        BlocksDockChip(id: 'f-general', name: '通用', count: 21),
      ],
      favorites: filter.isAll || filter.favorites
          ? [b('pk'), b('bl'), b('cy'), b('sy'), b('aq')]
          : const [],
      recent: filter.isAll
          ? [b('y99'), b('lk'), b('kx'), b('yr'), b('pf')]
          : const [],
      groups: filter.favorites
          ? const []
          : filter.folderId == null
          ? groups
          : groups.where((g) => g.id == filter.folderId).toList(),
      results: q.isEmpty
          ? const []
          : [
              for (final x in all)
                if (x.title.toLowerCase().contains(q) ||
                    x.content.toLowerCase().contains(q))
                  x,
            ],
    );
  }

  static BlockInstanceViewData instanceRandom({
    bool locked = false,
    bool enabled = true,
  }) => BlockInstanceViewData(
    block: byId('pk'),
    settings: const BlockRollSettings(
      mode: BlockMode.random,
      countMin: 1,
      countMax: 2,
      weightEnabled: true,
    ),
    locked: locked,
    enabled: enabled,
    drawn: const [
      BlockDrawn('artist:sincos', .8),
      BlockDrawn('artist:rella', 1.2),
    ],
    send: '0.8::artist:sincos::, 1.2::artist:rella::',
    side: BlockScopeSide.positive,
  );

  static BlockInstanceViewData instanceSeq([
    ImageProvider Function(String)? image,
  ]) => BlockInstanceViewData(
    block: byId('cy', image),
    settings: const BlockRollSettings(mode: BlockMode.sequential),
    locked: true,
    drawn: const [BlockDrawn('girl', .8)],
    send: '0.8::girl::',
    seqIndex: 6,
    seqCount: 1,
    prevText: '1.5::loli, child::',
    nextText: '1.4::silver hair::',
    catalog: catalog,
  );

  static BlockInstanceViewData instanceFixed([
    ImageProvider Function(String)? image,
  ]) => BlockInstanceViewData(
    block: byId('y99', image),
    settings: const BlockRollSettings(),
    side: BlockScopeSide.both,
    send: byId('y99').content,
    catalog: catalog,
  );

  /// 按规则造几次“抽取结果”（预览和测试用，确定性的）。
  static List<List<BlockDrawn>> sample(
    BlockData block,
    BlockRollSettings s,
    int times, {
    int seed = 7,
  }) {
    final r = math.Random(seed);
    final pool = block.atoms;
    if (pool.isEmpty) return const [];
    return [
      for (var t = 0; t < times; t++)
        [
          for (
            var i = 0;
            i < s.countMin + r.nextInt(s.countMax - s.countMin + 1);
            i++
          )
            BlockDrawn(
              pool[r.nextInt(pool.length)],
              s.weightEnabled
                  ? ((s.weightMin +
                                    (s.weightMax - s.weightMin) *
                                        (.2 + r.nextDouble() * .5)) *
                                10)
                            .round() /
                        10
                  : null,
            ),
        ],
    ];
  }

  static BlockEditData edit([ImageProvider Function(String)? image]) {
    final b = byId('y99', image);
    return BlockEditData(
      draft: BlockDraft.of(b),
      blockId: b.id,
      folders: folders,
      tags: [for (final t in tags) t.tag],
      catalog: catalog,
      sourcePath: b.sourcePath,
      importedAt: b.importedAt,
      sourceState: b.sourceState,
      folderName: b.folderName,
    );
  }

  static const quick = BlockQuickSaveData(
    atoms: ['white dress', 'blue flower', 'frilled dress'],
    title: '白裙蓝花',
    icon: 'dress',
    folders: folders,
    folderId: 'f-wardrobe',
  );
}

extension on BlockData {
  BlockData withNegative(List<String>? negative) => negative == null
      ? this
      : BlockData(
          id: id,
          title: title,
          color: color,
          icon: icon,
          look: look,
          atoms: atoms,
          negativeAtoms: negative,
          params: params,
          tags: tags,
          folderId: folderId,
          folderName: folderName,
          thumb: thumb,
          useCount: useCount,
          favorite: favorite,
          createdAt: createdAt,
          updatedAt: updatedAt,
          sourcePath: sourcePath,
          importedAt: importedAt,
          sourceState: sourceState,
        );
}
