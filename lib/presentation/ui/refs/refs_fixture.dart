import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'refs_contract.dart';

/// Vibe 库 / 精准参考库的假数据：和原型（.devin/mockups/refs/mock.html）同一批条目。
/// 名称、参数、次数是示意；`Ref_20260817_001408` 取自用户截图。
abstract final class RefsFixture {
  /// 相对时间的基准。
  static final now = DateTime(2026, 8, 23, 15);

  static const v45 = RefsModel(
    name: 'V4.5 Full',
    shortName: 'V4.5',
    vibeUsable: true,
    preciseUsable: true,
  );

  static const v5 = RefsModel(
    name: 'V5 Full',
    shortName: 'V5',
    vibeUsable: false,
    preciseUsable: false,
    switchTarget: 'V4.5 Full',
  );

  static DateTime _ago({int h = 0, int d = 0}) =>
      now.subtract(Duration(hours: h, days: d));

  static DateTime _day(int m, int d) => DateTime(2026, m, d, 20);

  static List<RefsEntry> vibes([ImageProvider? Function(String)? image]) {
    final load = image ?? UiFixtureImage.gradient;
    RefsEntry e(
      String key,
      String name,
      String img,
      double s,
      double i, {
      RefsVibeSource src = RefsVibeSource.png,
      RefsEncoding enc = RefsEncoding.ready,
      String? encodedFor,
      bool raw = false,
      String cat = 'style',
      bool fav = false,
      int used = 0,
      DateTime? last,
      bool gen = false,
      List<String> bundle = const [],
      List<String> tags = const [],
    }) => RefsEntry(
      key: key,
      name: name,
      thumb: load(img),
      favorite: fav,
      inGeneration: gen,
      strength: s,
      infoExtracted: i,
      source: src,
      encoding: enc,
      encodedFor: encodedFor,
      hasRaw: raw,
      bundleCount: bundle.length,
      bundleThumbs: [for (final b in bundle.skip(1).take(2)) ?load(b)],
      categoryId: cat,
      tags: tags,
      usedCount: used,
      lastUsed: last,
      createdAt: DateTime(2026, 8, 12, 21, 4),
      fileName:
          '$name.${switch (src) {
            RefsVibeSource.png => 'png',
            RefsVibeSource.vibeFile => 'naiv4vibe',
            RefsVibeSource.bundle => 'naiv4vibebundle',
            RefsVibeSource.rawImage => 'jpg',
          }}',
    );
    return [
      e(
        'c03',
        '星海夜光',
        'c03',
        .6,
        .7,
        raw: true,
        fav: true,
        used: 24,
        gen: true,
        last: _ago(h: 2),
        tags: const ['夜景', '冷色', '发光'],
      ),
      e(
        'c15',
        '水下光束',
        'c15',
        .55,
        .8,
        raw: true,
        cat: 'light',
        fav: true,
        used: 18,
        gen: true,
        last: _ago(h: 2),
      ),
      e(
        'c14',
        '青蓝群像',
        'c14',
        .65,
        .85,
        src: RefsVibeSource.bundle,
        fav: true,
        used: 31,
        gen: true,
        last: _ago(d: 1),
        bundle: const ['c14', 'c08', 'c04', 'c05', 'c18'],
      ),
      e(
        'c12',
        '霓虹波普',
        'c12',
        .7,
        1,
        src: RefsVibeSource.vibeFile,
        cat: 'tone',
        used: 9,
        last: _ago(d: 3),
      ),
      e(
        'c11',
        '红色走廊',
        'c11',
        .45,
        .6,
        enc: RefsEncoding.reencode,
        encodedFor: 'V4',
        raw: true,
        cat: 'light',
        used: 6,
        last: _day(8, 16),
        tags: const ['走廊', '暖光', '室内'],
      ),
      e(
        'c10',
        '绿光隧道',
        'c10',
        .5,
        .7,
        src: RefsVibeSource.vibeFile,
        cat: 'light',
        used: 3,
        last: _day(8, 15),
      ),
      e('c13', '暗红古城', 'c13', .6, .7, raw: true, used: 11, last: _ago(d: 5)),
      e(
        'c07',
        '雨衣街头',
        'c07',
        .4,
        .5,
        src: RefsVibeSource.vibeFile,
        enc: RefsEncoding.unusable,
        encodedFor: 'V4',
        cat: 'char',
        used: 2,
        last: _day(8, 14),
      ),
      e('u1', '柔光原野', 'u1', .6, .7, raw: true, used: 15, last: _ago(d: 1)),
      e(
        'c01',
        '废墟晨光',
        'c01',
        .5,
        .7,
        src: RefsVibeSource.rawImage,
        enc: RefsEncoding.encodeOnUse,
        raw: true,
        cat: 'light',
      ),
      e(
        'c17',
        '厚涂硬汉',
        'c17',
        .75,
        .7,
        raw: true,
        cat: 'impasto',
        used: 4,
        last: _day(8, 13),
      ),
      e(
        'c18',
        '都市俯瞰',
        'c18',
        .55,
        .65,
        src: RefsVibeSource.vibeFile,
        cat: 'comp',
        used: 5,
        last: _day(8, 12),
      ),
      e(
        'c16',
        '猫耳剑士',
        'c16',
        .6,
        .7,
        raw: true,
        cat: 'char',
        used: 7,
        last: _ago(d: 4),
      ),
      e(
        'c19',
        '红裙阳台',
        'c19',
        .5,
        .75,
        raw: true,
        cat: 'char',
        used: 3,
        last: _day(8, 11),
      ),
      e(
        'c08',
        '波普双人',
        'c08',
        .65,
        .9,
        src: RefsVibeSource.vibeFile,
        cat: 'tone',
        used: 6,
        last: _day(8, 10),
      ),
    ];
  }

  static List<RefsEntry> precise([ImageProvider? Function(String)? image]) {
    final load = image ?? UiFixtureImage.gradient;
    RefsEntry e(
      String name,
      String img,
      RefsPreciseType t,
      double s,
      double f, {
      bool fav = false,
      int used = 0,
      DateTime? last,
      bool gen = false,
    }) => RefsEntry(
      key: img,
      name: name,
      thumb: load(img),
      favorite: fav,
      inGeneration: gen,
      type: t,
      strength: s,
      fidelity: f,
      usedCount: used,
      lastUsed: last,
      createdAt: DateTime(2026, 8, 17, 0, 14),
      imageSize: const Size(1024, 1536),
      imageFormat: 'PNG',
    );
    const c = RefsPreciseType.character,
        s = RefsPreciseType.style,
        b = RefsPreciseType.both;
    return [
      e(
        'Ref_20260817_001408',
        'c20',
        c,
        1,
        1,
        fav: true,
        used: 4,
        gen: true,
        last: _ago(h: 3),
      ),
      e('银发水手服', 'c02', c, 1, .8, used: 7, last: _ago(d: 1)),
      e('猫耳剑士', 'c16', c, .9, 1, used: 3, last: _ago(d: 3)),
      e('霓虹厚涂', 'c12', s, .8, .7, fav: true, used: 9, last: _ago(d: 1)),
      e('星海夜景', 'c03', s, .6, .9, used: 5, last: _ago(d: 4)),
      e('红裙少女', 'c19', b, 1, 1, used: 2, last: _day(8, 15)),
      e('雨衣街头', 'c07', b, .85, .9, used: 1, last: _day(8, 14)),
      e('红色走廊', 'c11', s, .7, .6, used: 2, last: _day(8, 13)),
      e('蓝发人设', 'c04', c, 1, 1, fav: true, used: 11, last: _ago(d: 2)),
      e('白发少女', 'c05', c, .95, .9, used: 6, last: _day(8, 12)),
      e('厚涂人像', 'c17', s, .75, .8, used: 3, last: _day(8, 11)),
      e('波普双人', 'c08', b, .9, .85, used: 2, last: _day(8, 10)),
      e('羊角少女', 'c06', c, 1, 1, used: 1, last: _day(8, 9)),
      e('夜空萤火', 'g18', s, .65, .8),
      e('绿光隧道', 'c10', s, .6, .7, used: 1, last: _day(8, 8)),
    ];
  }

  static const categories = [
    RefsCategory(id: 'style', name: '画风', count: 46),
    RefsCategory(id: 'night', name: '夜景', count: 12, parentId: 'style'),
    RefsCategory(id: 'impasto', name: '厚涂', count: 9, parentId: 'style'),
    RefsCategory(id: 'light', name: '光影', count: 31),
    RefsCategory(id: 'tone', name: '色调', count: 18),
    RefsCategory(id: 'char', name: '角色', count: 14),
    RefsCategory(id: 'comp', name: '构图', count: 7),
  ];

  static const vibeCounts = RefsCounts(
    all: 128,
    favorites: 12,
    inGeneration: 3,
    uncategorized: 12,
    needsEncoding: 13,
    sources: {
      RefsVibeSource.png: 74,
      RefsVibeSource.vibeFile: 36,
      RefsVibeSource.bundle: 6,
      RefsVibeSource.rawImage: 12,
    },
  );

  static const preciseCounts = RefsCounts(
    all: 28,
    favorites: 5,
    inGeneration: 1,
    types: {
      RefsPreciseType.character: 14,
      RefsPreciseType.style: 9,
      RefsPreciseType.both: 5,
    },
  );

  static List<RefsBundleChild> bundle([
    ImageProvider? Function(String)? image,
  ]) {
    final load = image ?? UiFixtureImage.gradient;
    const names = ['青蓝群像', '波普粉紫', '蓝发特写', '白发水面', '都市蓝调'];
    const keys = ['c14', 'c08', 'c04', 'c05', 'c18'];
    const s = [.65, .5, .6, .55, .4], e = [.85, .7, .8, .7, .6];
    return [
      for (var i = 0; i < 5; i++)
        RefsBundleChild(
          name: names[i],
          thumb: load(keys[i]),
          strength: s[i],
          infoExtracted: e[i],
        ),
    ];
  }

  static RefsDetail? detail(
    RefsKind kind,
    String? key,
    List<RefsEntry> entries, [
    ImageProvider? Function(String)? image,
  ]) {
    final e = entries.where((x) => x.key == key).firstOrNull;
    if (e == null) return null;
    return RefsDetail(
      key: e.key,
      image: e.thumb,
      bundle: e.isBundle ? bundle(image) : const [],
      bundleEncodedFor: e.isBundle ? 'V4.5' : null,
    );
  }

  static RefsTray vibeTray(List<RefsEntry> entries, {bool dim = false}) =>
      RefsTray(
        items: [
          for (final e in entries.where((x) => x.inGeneration))
            RefsTrayItem(
              id: 'gen-${e.key}',
              entryKey: e.key,
              thumb: e.thumb,
              value: e.strength,
              enabled: !dim,
            ),
        ],
      );

  static RefsTray preciseTray(List<RefsEntry> entries) => RefsTray(
    items: [
      for (final e in entries.where((x) => x.inGeneration))
        RefsTrayItem(
          id: 'gen-${e.key}',
          entryKey: e.key,
          thumb: e.thumb,
          value: e.strength,
        ),
    ],
    otherVibes: 3,
  );

  static RefsViewData vibe({
    ImageProvider? Function(String)? image,
    RefsModel model = v45,
    String? selectedKey = 'c03',
    bool empty = false,
    RefsFilter filter = const RefsFilter(),
    RefsDropSummary? drop,
    RefsImportDraft? importDraft,
    RefsCardSize cardSize = RefsCardSize.medium,
  }) {
    final entries = empty ? const <RefsEntry>[] : vibes(image);
    return RefsViewData(
      kind: RefsKind.vibe,
      now: now,
      model: model,
      entries: entries,
      counts: empty ? const RefsCounts() : vibeCounts,
      categories: empty ? const [] : categories,
      filter: filter,
      selectedKey: empty ? null : selectedKey,
      detail: empty ? null : detail(RefsKind.vibe, selectedKey, entries, image),
      tray: vibeTray(entries, dim: !model.vibeUsable),
      cardSize: cardSize,
      folderPath: r'E:\A.I\NovelAI\NAI\vibes',
      exportFolder: r'E:\A.I\NovelAI\导出\vibes',
      drop: drop,
      importDraft: importDraft,
    );
  }

  static RefsViewData preciseView({
    ImageProvider? Function(String)? image,
    RefsModel model = v45,
    String? selectedKey = 'c20',
    bool empty = false,
    RefsFilter filter = const RefsFilter(),
  }) {
    final entries = empty ? const <RefsEntry>[] : precise(image);
    return RefsViewData(
      kind: RefsKind.precise,
      now: now,
      model: model,
      entries: entries,
      counts: empty ? const RefsCounts() : preciseCounts,
      filter: filter,
      selectedKey: empty ? null : selectedKey,
      detail: empty
          ? null
          : detail(RefsKind.precise, selectedKey, entries, image),
      tray: preciseTray(entries),
      importType: filter.type ?? RefsPreciseType.both,
    );
  }

  static const drop = RefsDropSummary(vibePngs: 2, bundles: 1, images: 3);

  static RefsImportDraft importDraft([ImageProvider? Function(String)? image]) {
    final load = image ?? UiFixtureImage.gradient;
    return RefsImportDraft(
      categoryId: 'style',
      rows: [
        RefsImportRow(
          id: 'r1',
          name: '暗巷红光',
          ext: '.png',
          kind: RefsImportKind.vibePng,
          thumb: load('c09'),
          encodedFor: 'V4.5',
        ),
        RefsImportRow(
          id: 'r2',
          name: '羊角少女',
          ext: '.naiv4vibe',
          kind: RefsImportKind.vibeFile,
          thumb: load('c06'),
          encodedFor: 'V4',
          encodedForCurrent: false,
        ),
        RefsImportRow(
          id: 'r3',
          name: '夏日合集',
          ext: '.naiv4vibebundle',
          kind: RefsImportKind.bundle,
          encodedFor: 'V4.5',
          bundle: [
            for (final k in [
              'c14',
              'c08',
              'c04',
              'c05',
              'c18',
              'c03',
              'c15',
              'c12',
            ])
              RefsBundleChild(name: k, thumb: load(k)),
          ],
        ),
        RefsImportRow(
          id: 'r4',
          name: '草图_0821',
          ext: '.jpg',
          kind: RefsImportKind.image,
          thumb: load('g41'),
        ),
        RefsImportRow(
          id: 'r5',
          name: '街景_0822',
          ext: '.jpg',
          kind: RefsImportKind.image,
          thumb: load('g19'),
        ),
        RefsImportRow(
          id: 'r6',
          name: '银发水手服',
          ext: '.png',
          kind: RefsImportKind.image,
          thumb: load('c02'),
          duplicate: true,
        ),
      ],
    );
  }

  /// 生图页“从 Vibe 库添加”。
  static RefsPickerData vibePicker([ImageProvider? Function(String)? image]) {
    final all = vibes(image);
    RefsEntry at(String k) => all.firstWhere((e) => e.key == k);
    return RefsPickerData(
      kind: RefsKind.vibe,
      now: now,
      model: v45,
      entries: [
        for (final k in [
          'c12', 'c11', 'c10', 'c13', 'u1', 'c01', 'c17', 'c18', 'c16', //
          'c19', 'c08', 'c07', 'c03', 'c15', 'c14',
        ])
          at(k),
      ],
      categories: categories.where((c) => c.parentId == null).toList(),
      recent: const ['c03', 'c15', 'c14', 'u1', 'c13', 'c16', 'c17'],
      inUse: 3,
    );
  }

  static RefsPickerData precisePicker([
    ImageProvider? Function(String)? image,
  ]) => RefsPickerData(
    kind: RefsKind.precise,
    now: now,
    model: v45,
    entries: precise(image),
    recent: const ['c20', 'c02', 'c12', 'c04'],
    inUse: 1,
  );
}
