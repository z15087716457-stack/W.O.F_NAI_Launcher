import 'package:flutter/widgets.dart';

import '../kit/ui_fixture_image.dart';
import 'explore_contract.dart';

/// 假数据：照原型 `.devin/mockups/style-explore/mock.html` 的示意数据生成（同一个随机种子，
/// 画师串、收藏、分组和原型一致）。只给预览和测试用。
typedef ExploreFixtureImages = ImageProvider? Function(String name);

abstract final class ExploreFixture {
  static final now = DateTime(2026, 10, 6, 19, 2);

  static ImageProvider? _gradient(String name) =>
      UiFixtureImage.gradient('x$name');

  static const pink = Color(0xFFD6336C);
  static const blue = Color(0xFF1C7ED6);

  static const variables = [
    ExploreVariable(
      title: '400精选画师池',
      color: pink,
      icon: 'palette',
      poolSize: 400,
      evolution: true,
    ),
    ExploreVariable(title: '收藏艺术家池', color: blue, icon: 'star', poolSize: 86),
  ];

  static const _im = [
    'u1', 'c01', 'c02', 'c03', 'c04', 'c05', 'c06', 'c07', //
    'c08', 'c12', 'c14', 'c15', 'c16', 'c19',
  ];
  static const _ar = [
    'ciloranko', 'sincos', 'rella', 'mika pikazo', 'fuzichoco', 'kantoku', //
    'atdan', 'modare', 'ningen mame', 'yoneyama mai', 'nardack', 'tiv',
    'quasarcake', 'ogipote', 'toosaka asagi', 'kawacy', 'namie', 'rurudo',
    'mignon', 'torino aqua', 'houk1se1', 'ke-ta', 'wanke', 'void_0',
    'ask (askzy)', 'momoko (momopoco)',
  ];
  static const _w = ['1.2', '1.0', '0.9', '0.8', '0.7', '0.6', '0.5'];

  static const _head =
      'scenery, panorama, from behind, green theme, blue theme, plant, '
      'detailed background, (extremely vibrant colors), magical atmosphere, '
      'dynamic composition, sitting, wide shot, white dress, blue flower, '
      'frilled dress, giant, 0.8::artist:sincos::';
  static const _tail =
      'artist:asteroid_ill, candid, year 2025, very aesthetic, masterpiece, '
      'sketch, lineart, solo, no text';
  static const negative =
      'lowres, artistic error, film grain, scan artifacts, worst quality, '
      'bad quality, jpeg artifacts, very displeasing, chromatic aberration, '
      'dithering, halftone, screentone, multiple views, logo, too many '
      'watermarks, negative space, blank page';

  static String atomRaw(String w, String a) =>
      w.isEmpty ? 'artist:$a' : '$w::artist:$a::';

  /// 原型的示意画师串：(图名, 粉色池画师, 蓝色池画师)。
  static final List<(String, List<ExploreAtom>, List<ExploreAtom>)> _raw = () {
    var seed = 7;
    double rnd() => (seed = (seed * 16807) % 2147483647) / 2147483647;
    T pick<T>(List<T> a) => a[(rnd() * a.length).floor()];
    final out = <(String, List<ExploreAtom>, List<ExploreAtom>)>[];
    for (var i = 1; i <= 38; i++) {
      final n = 1 + (rnd() * 2).floor();
      final used = <String>{};
      String u() {
        String a;
        do {
          a = pick(_ar);
        } while (used.contains(a));
        used.add(a);
        return a;
      }

      final pk = <ExploreAtom>[];
      for (var j = 0; j < n; j++) {
        final w = pick(_w);
        pk.add(ExploreAtom.parse(atomRaw(w, u())));
      }
      final w = rnd() < .5 ? '' : pick(_w);
      final bl = [ExploreAtom.parse(atomRaw(w, u()))];
      out.add((_im[(i * 5 + 3) % _im.length], pk, bl));
    }
    out[26] = (
      'u1',
      const [],
      [ExploreAtom.parse(atomRaw('0.6', 'ciloranko'))],
    );
    return out;
  }();

  static const _hearts = {26, 33, 30, 28, 22, 17};
  static const _groups = {26: 'g1', 30: 'g1', 37: 'g1', 33: 'g2', 22: 'g2'};
  static const groups = [
    ExploreGroup(id: 'g1', name: '冷色调'),
    ExploreGroup(id: 'g2', name: '厚涂'),
  ];

  static ExploreCandidate _candidate(
    int index, {
    required String key,
    required String roundId,
    required int number,
    required DateTime at,
    required ExploreFixtureImages images,
    ExploreCandidateState state = ExploreCandidateState.done,
    bool? favorite,
    bool noGroup = false,
    ExploreOp? op,
    String? lineId,
    int? generation,
    List<String> parentKeys = const [],
    List<ExploreAtom> changed = const [],
    String? opNote,
    bool inEvolution = false,
    String? error,
  }) {
    final (img, pk, bl) = _raw[index];
    final draws = [
      ExploreDraw(
        title: variables[0].title,
        color: pink,
        icon: 'palette',
        evolution: true,
        atoms: pk,
      ),
      ExploreDraw(
        title: variables[1].title,
        color: blue,
        icon: 'star',
        atoms: bl,
      ),
    ];
    final pkText = pk.map((a) => a.raw).join(', ');
    final blText = bl.map((a) => a.raw).join(', ');
    final parts = [_head, if (pkText.isNotEmpty) pkText, blText, _tail];
    final prompt = parts.join(', ');
    final hits = <ExploreHit>[
      if (pkText.isNotEmpty)
        ExploreHit(
          start: prompt.indexOf(pkText),
          end: prompt.indexOf(pkText) + pkText.length,
          color: pink,
        ),
      ExploreHit(
        start: prompt.indexOf(blText, _head.length),
        end: prompt.indexOf(blText, _head.length) + blText.length,
        color: blue,
      ),
    ];
    final done = state == ExploreCandidateState.done;
    return ExploreCandidate(
      key: key,
      roundId: roundId,
      number: number,
      state: state,
      image: done ? images(img) : null,
      thumb: done ? images(img) : null,
      favorite: favorite ?? _hearts.contains(index),
      groupId: noGroup ? null : _groups[index],
      draws: done ? draws : const [],
      prompt: done ? prompt : '',
      negative: done ? negative : '',
      hits: done ? hits : const [],
      seed: done
          ? (index == 26 ? 3274348526 : 1938821004 + index * 7919)
          : null,
      elapsed: done
          ? Duration(milliseconds: index == 26 ? 14800 : 12600 + index * 61)
          : null,
      model: 'NAI Diffusion V5 Full',
      steps: 28,
      scale: 5,
      sampler: 'DPM++ 2M SDE',
      createdAt: at,
      error: error,
      op: op,
      lineId: lineId,
      generation: generation,
      parentKeys: parentKeys,
      changedAtoms: changed,
      opNote: opNote,
      inEvolution: inEvolution,
    );
  }

  static String basicKey(int number) => 'c$number';

  /// 柔光画风 · 400 池。[running] = 第 3 轮正在出图（9 / 12）；[failed] = 第 3 轮第 6 张失败。
  static ExploreRunView run({
    ExploreFixtureImages? images,
    bool running = false,
    bool failed = false,
  }) {
    final img = images ?? _gradient;
    final r1 = DateTime(2026, 10, 6, 16, 5);
    final r2 = DateTime(2026, 10, 6, 17, 20);
    final r3 = DateTime(2026, 10, 6, 18, 54);
    final parentOf = {0, 2, 3, 6};
    final candidates = <ExploreCandidate>[];
    for (var i = 0; i < 38; i++) {
      final round = i < 16 ? 'r1' : (i < 26 ? 'r2' : 'r3');
      final at = i < 16 ? r1 : (i < 26 ? r2 : r3);
      var state = ExploreCandidateState.done;
      if (running && i >= 26) {
        final j = i - 26;
        state = j >= 9
            ? ExploreCandidateState.pending
            : j == 8
            ? ExploreCandidateState.running
            : state;
      }
      if (failed && i == 31) state = ExploreCandidateState.failed;
      candidates.add(
        _candidate(
          i,
          key: basicKey(i + 1),
          roundId: round,
          number: i + 1,
          at: at.add(Duration(seconds: 15 * (i % 16))),
          images: img,
          state: state,
          error: state == ExploreCandidateState.failed
              ? '服务器繁忙（429），已自动重试 3 次'
              : null,
          inEvolution: (i >= 26 && parentOf.contains(i - 26)) || i == 17,
        ),
      );
    }

    // 柔光主线：第 1 代 4 个父本 → 8 张子代；第 2 代 4 个父本 → 10 张；第 3 代 5 个父本 → 12 张。
    const ops = [
      ExploreOp.crossover, ExploreOp.mutation, ExploreOp.crossover, //
      ExploreOp.injection, ExploreOp.mutation, ExploreOp.crossover,
      ExploreOp.crossover, ExploreOp.mutation, ExploreOp.injection,
      ExploreOp.crossover, ExploreOp.mutation, ExploreOp.crossover,
    ];
    var number = 39;
    List<String> children(
      String lineId,
      int gen,
      List<int> sources,
      DateTime at,
      List<String> parents,
    ) {
      final keys = <String>[];
      for (final (j, s) in sources.indexed) {
        final key = 'k$gen-${j + 1}';
        final (_, pk, bl) = _raw[s];
        final op = ops[j % ops.length];
        candidates.add(
          _candidate(
            s,
            key: key,
            roundId: '$lineId-g$gen',
            number: number++,
            at: at.add(Duration(seconds: 15 * j)),
            images: img,
            favorite: gen == 3 && (j == 1 || j == 6),
            noGroup: true,
            op: op,
            lineId: lineId,
            generation: gen,
            parentKeys: [parents[j % parents.length]],
            changed: op == ExploreOp.mutation
                ? [if (pk.isNotEmpty) pk.last else bl.first]
                : op == ExploreOp.injection
                ? [bl.first]
                : const [],
            opNote: switch (op) {
              ExploreOp.mutation => '替换 1 位画师、调整 1 个权重',
              ExploreOp.injection => '从池里注入 1 位新画师',
              ExploreOp.crossover => '两个父本各取一半',
            },
          ),
        );
        keys.add(key);
      }
      return keys;
    }

    ExploreParent parent(int index, String id, double pref) {
      final (name, pk, bl) = _raw[index];
      return ExploreParent(
        id: id,
        candidateKey: basicKey(index + 1),
        image: img(name),
        atoms: [...pk, ...bl],
        preference: pref,
      );
    }

    final g1 = [
      parent(26, 'p1-1', 1),
      parent(28, 'p1-2', 1),
      parent(29, 'p1-3', 1),
      parent(32, 'p1-4', 1),
    ];
    final g1Kids = children(
      'l1',
      1,
      [2, 3, 4, 5, 6, 7, 8, 9],
      DateTime(2026, 10, 6, 18, 10),
      [for (final p in g1) p.candidateKey!],
    );
    final g2 = [
      parent(4, 'p2-1', 1.5),
      parent(6, 'p2-2', 1),
      parent(8, 'p2-3', 1),
      parent(26, 'p2-4', 1),
    ];
    final g2Kids = children(
      'l1',
      2,
      [10, 11, 12, 13, 14, 15, 0, 1, 2, 3],
      DateTime(2026, 10, 6, 18, 30),
      [for (final p in g2) p.candidateKey!],
    );
    final g3 = [
      parent(26, 'p3-1', 3),
      parent(28, 'p3-2', 2),
      parent(29, 'p3-3', 1.5),
      parent(32, 'p3-4', 1),
      parent(17, 'p3-5', .75),
    ];
    final g3Kids = running
        ? const <String>[]
        : children(
            'l1',
            3,
            [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 1],
            DateTime(2026, 10, 6, 18, 48),
            [for (final p in g3) p.candidateKey!],
          );
    final cold1 = [parent(30, 'q1-1', 1), parent(37, 'q1-2', 1)];
    final coldKids = children(
      'l2',
      1,
      [5, 9, 13, 21],
      DateTime(2026, 10, 6, 17, 40),
      [for (final p in cold1) p.candidateKey!],
    );
    final cold2 = [parent(9, 'q2-1', 1), parent(13, 'q2-2', 1)];

    final rounds = [
      ExploreRound(
        id: 'r1',
        number: 1,
        createdAt: r1,
        keys: [for (var i = 1; i <= 16; i++) basicKey(i)],
      ),
      ExploreRound(
        id: 'r2',
        number: 2,
        createdAt: r2,
        keys: [for (var i = 17; i <= 26; i++) basicKey(i)],
      ),
      ExploreRound(
        id: 'r3',
        number: 3,
        createdAt: r3,
        keys: [for (var i = 27; i <= 38; i++) basicKey(i)],
      ),
      for (final (id, gen, keys, at) in [
        ('l1', 1, g1Kids, DateTime(2026, 10, 6, 18, 10)),
        ('l1', 2, g2Kids, DateTime(2026, 10, 6, 18, 30)),
        ('l2', 1, coldKids, DateTime(2026, 10, 6, 17, 40)),
        if (g3Kids.isNotEmpty) ('l1', 3, g3Kids, DateTime(2026, 10, 6, 18, 48)),
      ])
        ExploreRound(
          id: '$id-g$gen',
          number: 0,
          createdAt: at,
          keys: keys,
          kind: ExploreRoundKind.deep,
          lineName: id == 'l1' ? '柔光主线' : '冷色支线',
          generation: gen,
        ),
    ];

    return ExploreRunView(
      id: 'run1',
      name: '柔光画风 · 400 池',
      createdAt: r1,
      candidates: candidates,
      rounds: rounds,
      groups: groups,
      lines: [
        ExploreLine(
          id: 'l1',
          name: '柔光主线',
          generations: [
            ExploreGeneration(
              number: 1,
              parents: g1,
              childKeys: g1Kids,
              picked: 4,
            ),
            ExploreGeneration(
              number: 2,
              parents: g2,
              childKeys: g2Kids,
              fromGeneration: 1,
              picked: 3,
              backcross: true,
            ),
            ExploreGeneration(
              number: 3,
              parents: g3,
              childKeys: g3Kids,
              fromGeneration: 2,
              picked: 3,
              backcross: true,
            ),
          ],
        ),
        ExploreLine(
          id: 'l2',
          name: '冷色支线',
          generations: [
            ExploreGeneration(
              number: 1,
              parents: cold1,
              childKeys: coldKids,
              picked: 2,
            ),
            ExploreGeneration(
              number: 2,
              parents: cold2,
              fromGeneration: 1,
              picked: 2,
            ),
          ],
        ),
      ],
      progress: running
          ? const ExploreProgress(done: 9, total: 12, round: 3)
          : null,
    );
  }

  static List<ExploreRunSummary> runs({
    ExploreFixtureImages? images,
    bool running = false,
  }) {
    final img = images ?? _gradient;
    List<ImageProvider?> t(List<int> i) => [for (final x in i) img(_im[x])];
    return [
      ExploreRunSummary(
        id: 'run1',
        name: '柔光画风 · 400 池',
        updatedAt: DateTime(2026, 10, 6, 18, 54),
        total: 38,
        favorites: 6,
        lines: 2,
        thumbs: t([0, 3, 7]),
        state: running ? ExploreRunState.running : ExploreRunState.idle,
        done: 9,
        target: 12,
      ),
      ExploreRunSummary(
        id: 'run2',
        name: '冷色厚涂对比',
        updatedAt: DateTime(2026, 10, 6, 11, 20),
        total: 12,
        favorites: 2,
        thumbs: t([5, 9, 11]),
      ),
      ExploreRunSummary(
        id: 'run3',
        name: '赛璐璐 × 水彩',
        updatedAt: DateTime(2026, 10, 4, 21, 3),
        total: 24,
        favorites: 4,
        lines: 2,
        thumbs: t([2, 6, 12]),
        state: ExploreRunState.paused,
        done: 5,
        target: 8,
      ),
      ExploreRunSummary(
        id: 'run4',
        name: '收藏池随机 09-28',
        updatedAt: DateTime(2026, 10, 2, 15, 41),
        total: 9,
        thumbs: t([8, 10, 13]),
        state: ExploreRunState.failed,
        failed: 2,
      ),
      ExploreRunSummary(
        id: 'run5',
        name: '400 池初筛',
        updatedAt: DateTime(2026, 9, 21, 20, 12),
        total: 56,
        favorites: 11,
        thumbs: t([1, 4, 7]),
      ),
    ];
  }

  static const blockFolders = [
    ExploreBlockFolder(id: null, name: '块库'),
    ExploreBlockFolder(id: 'f-style', name: '画风', depth: 1),
    ExploreBlockFolder(id: 'f-artist', name: '画师组合', depth: 2),
    ExploreBlockFolder(id: 'f-char', name: '角色', depth: 1),
    ExploreBlockFolder(id: 'f-scene', name: '场景', depth: 1),
  ];

  /// 主界面（有 3 轮候选、2 条进化线）。
  static ExploreViewData view({
    ExploreFixtureImages? images,
    bool running = false,
    bool failed = false,
    ExploreCardSize cardSize = ExploreCardSize.large,
    bool inspectorOpen = true,
    List<ExploreVariable> vars = variables,
    ExploreUndo? undo,
  }) => ExploreViewData(
    now: now,
    runs: runs(images: images, running: running),
    run: run(images: images, running: running, failed: failed),
    variables: vars,
    generate: running
        ? const ExploreGenerate(
            phase: ExploreGeneratePhase.running,
            done: 9,
            total: 12,
            count: 12,
          )
        : const ExploreGenerate(),
    cardSize: cardSize,
    inspectorOpen: inspectorOpen,
    blockFolders: blockFolders,
    undo: undo,
  );

  /// 首次使用（还没有探索）。
  static ExploreViewData empty({
    ExploreFixtureImages? images,
    List<ExploreVariable> vars = variables,
  }) => ExploreViewData(
    now: now,
    runs: const [],
    variables: vars,
    blockFolders: blockFolders,
  );
}
