// 画风探索预览：一个本地模拟器，按契约回调改假数据，让每个按钮在预览里都“真的”起作用
// （抽候选、收藏、归组、删除撤销、进化、两两比较、培育下一代……出图用定时器假装）。
// 只给 preview_main.dart 用，不进应用。
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';

/// 预设状态（预览顶栏切换）。
enum ExploreScene { main, generating, failed, empty, noVariables, v45 }

final _images = <String, ImageProvider?>{};

/// 优先用原型图（.devin/mockups/style-explore/assets），没有用渐变图。
ImageProvider? explorePreviewImage(String name) =>
    _images.putIfAbsent(name, () {
      final f = File('../../mockups/style-explore/assets/$name.jpg');
      return f.existsSync() ? FileImage(f) : UiFixtureImage.gradient(name);
    });

class ExplorePreviewSim extends ChangeNotifier {
  ExplorePreviewSim({required this.log}) {
    _reset();
  }

  final ValueChanged<String> log;

  var _scene = ExploreScene.main;
  ExploreRunView? _run;
  var _runs = <ExploreRunSummary>[];
  var _count = 10;
  var _size = ExploreCardSize.large;
  var _inspector = true;
  var _editor = 384.0;
  var _fullscreen = false;
  ExploreUndo? _undo;
  List<ExploreCandidate> _trash = const [];
  var _undoId = 0;
  var _seq = 100;
  Timer? _timer;
  final _rng = math.Random(7);

  ExploreScene get scene => _scene;
  set scene(ExploreScene s) {
    _scene = s;
    _reset();
    notifyListeners();
  }

  bool get v45 => _scene == ExploreScene.v45;
  bool get fullscreen => _fullscreen;

  void _reset() {
    _timer?.cancel();
    _undo = null;
    final running = _scene == ExploreScene.generating;
    final base = ExploreFixture.view(
      images: explorePreviewImage,
      running: running,
      failed: _scene == ExploreScene.failed,
    );
    _run = _scene == ExploreScene.empty || _scene == ExploreScene.noVariables
        ? null
        : base.run;
    _runs = _run == null ? [] : [...base.runs];
    if (running) _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  ExploreViewData get data {
    final p = _run?.progress;
    return ExploreViewData(
      now: ExploreFixture.now,
      runs: _runs,
      run: _run,
      variables: _scene == ExploreScene.noVariables
          ? const []
          : ExploreFixture.variables,
      generate: p != null && p.round != null
          ? ExploreGenerate(
              phase: ExploreGeneratePhase.running,
              done: p.done,
              total: p.total,
              count: _count,
            )
          : ExploreGenerate(
              count: _count,
              phase: p != null
                  ? ExploreGeneratePhase.busy
                  : ExploreGeneratePhase.ready,
            ),
      cardSize: _size,
      inspectorOpen: _inspector,
      editorWidth: _editor,
      blockFolders: ExploreFixture.blockFolders,
      undo: _undo,
      fullscreen: _fullscreen,
    );
  }

  // ───────────── 改数据的小工具 ─────────────

  void _update(ExploreRunView Function(ExploreRunView r) f) {
    final r = _run;
    if (r != null) _run = f(r);
  }

  ExploreRunView _with(
    ExploreRunView r, {
    String? name,
    List<ExploreCandidate>? candidates,
    List<ExploreRound>? rounds,
    List<ExploreGroup>? groups,
    List<ExploreLine>? lines,
    ExploreProgress? Function()? progress,
  }) => ExploreRunView(
    id: r.id,
    name: name ?? r.name,
    createdAt: r.createdAt,
    candidates: candidates ?? r.candidates,
    rounds: rounds ?? r.rounds,
    groups: groups ?? r.groups,
    lines: lines ?? r.lines,
    progress: progress != null ? progress() : r.progress,
  );

  void _mapCandidates(
    Iterable<String> keys,
    ExploreCandidate Function(ExploreCandidate c) f,
  ) {
    final set = keys.toSet();
    _update(
      (r) => _with(
        r,
        candidates: [
          for (final c in r.candidates) set.contains(c.key) ? f(c) : c,
        ],
      ),
    );
  }

  ExploreLine _lineWith(
    ExploreLine l, {
    String? name,
    List<ExploreGeneration>? generations,
  }) => ExploreLine(
    id: l.id,
    name: name ?? l.name,
    generations: generations ?? l.generations,
  );

  ExploreGeneration _genWith(
    ExploreGeneration g, {
    List<ExploreParent>? parents,
    List<String>? childKeys,
  }) => ExploreGeneration(
    number: g.number,
    parents: parents ?? g.parents,
    childKeys: childKeys ?? g.childKeys,
    fromGeneration: g.fromGeneration,
    picked: g.picked,
    backcross: g.backcross,
  );

  /// 用已有的一张候选当模板造一张新的（同一套抽取结果，换个 key / 序号 / 状态）。
  ExploreCandidate _clone(
    ExploreCandidate t, {
    required String key,
    required String roundId,
    required int number,
    ExploreOp? op,
    String? lineId,
    int? generation,
    List<String> parentKeys = const [],
  }) => ExploreCandidate(
    key: key,
    roundId: roundId,
    number: number,
    state: ExploreCandidateState.pending,
    width: t.width,
    height: t.height,
    draws: t.draws,
    prompt: t.prompt,
    negative: t.negative,
    hits: t.hits,
    seed: 1000000000 + _rng.nextInt(999999999),
    elapsed: Duration(milliseconds: 11000 + _rng.nextInt(5000)),
    model: t.model,
    steps: t.steps,
    scale: t.scale,
    sampler: t.sampler,
    createdAt: ExploreFixture.now,
    op: op,
    lineId: lineId,
    generation: generation,
    parentKeys: parentKeys,
    opNote: switch (op) {
      ExploreOp.mutation => '替换 1 位画师、调整 1 个权重',
      ExploreOp.injection => '从池里注入 1 位新画师',
      ExploreOp.crossover => '两个父本各取一半',
      null => null,
    },
    changedAtoms: op == ExploreOp.mutation || op == ExploreOp.injection
        ? [t.atoms.last]
        : const [],
  );

  /// 新候选借用假数据里海选候选的抽取结果和图。
  late final List<ExploreCandidate> _templates = [
    for (final c in ExploreFixture.run(images: explorePreviewImage).candidates)
      if (c.done && c.op == null) c,
  ];

  /// 每 0.7 秒出一张：排队 → 生成中 → 完成。
  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
  }

  void _tick() {
    final r = _run;
    final p = r?.progress;
    if (r == null || p == null || p.paused) return;
    final pending = [
      for (final c in r.candidates)
        if (c.state == ExploreCandidateState.running ||
            c.state == ExploreCandidateState.pending)
          c,
    ];
    final running = pending
        .where((c) => c.state == ExploreCandidateState.running)
        .firstOrNull;
    final template = _templates[_rng.nextInt(_templates.length)];
    if (running != null) {
      _mapCandidates(
        [running.key],
        (c) => c.copyWith(
          state: ExploreCandidateState.done,
          image: c.image ?? template.image,
          thumb: c.thumb ?? template.thumb,
        ),
      );
    }
    final next = pending
        .where((c) => c.state == ExploreCandidateState.pending)
        .firstOrNull;
    if (next != null) {
      _mapCandidates([
        next.key,
      ], (c) => c.copyWith(state: ExploreCandidateState.running));
    }
    final done = p.done + (running != null ? 1 : 0);
    _update(
      (r) => _with(
        r,
        progress: () => next == null && running != null
            ? null
            : ExploreProgress(
                done: done,
                total: p.total,
                round: p.round,
                lineName: p.lineName,
                generation: p.generation,
              ),
      ),
    );
    if (_run?.progress == null) {
      _timer?.cancel();
      log('这批生成完了');
    }
    notifyListeners();
  }

  void _generate() {
    if (_run == null) {
      _run = ExploreRunView(
        id: 'run-new',
        name: '400精选画师池 · 10-06',
        createdAt: ExploreFixture.now,
      );
      _runs = [
        ExploreRunSummary(
          id: 'run-new',
          name: _run!.name,
          updatedAt: ExploreFixture.now,
        ),
        ...ExploreFixture.runs(images: explorePreviewImage),
      ];
    }
    final r = _run!;
    final templates = _templates;
    final roundNo =
        r.rounds.where((x) => x.kind == ExploreRoundKind.basic).length + 1;
    final id = 'r${_seq++}';
    var n = r.candidates.fold(0, (m, c) => math.max(m, c.number));
    final fresh = [
      for (var i = 0; i < _count; i++)
        _clone(
          templates[_rng.nextInt(templates.length)],
          key: 'n${_seq++}',
          roundId: id,
          number: ++n,
        ),
    ];
    _run = _with(
      r,
      candidates: [...r.candidates, ...fresh],
      rounds: [
        ...r.rounds,
        ExploreRound(
          id: id,
          number: roundNo,
          createdAt: ExploreFixture.now,
          keys: [for (final c in fresh) c.key],
        ),
      ],
      progress: () => ExploreProgress(done: 0, total: _count, round: roundNo),
    );
    log('抽 $_count 张候选（第 $roundNo 轮）');
    _startTicker();
  }

  void _children(String lineId, int count) {
    final r = _run;
    if (r == null) return;
    final line = r.lines.firstWhere((l) => l.id == lineId);
    final gen = line.current;
    final templates = [
      for (final p in gen.parents)
        if (p.candidateKey != null) ?r.candidate(p.candidateKey!),
    ];
    final pool = templates.isEmpty ? _templates : templates;
    var n = r.candidates.fold(0, (m, c) => math.max(m, c.number));
    const ops = ExploreOp.values;
    final fresh = [
      for (var i = 0; i < count; i++)
        _clone(
          pool[i % pool.length],
          key: 'k${_seq++}',
          roundId: '$lineId-g${gen.number}',
          number: ++n,
          op: ops[_rng.nextInt(ops.length)],
          lineId: lineId,
          generation: gen.number,
          parentKeys: [
            for (final p in gen.parents.take(2))
              if (p.candidateKey != null) p.candidateKey!,
          ],
        ),
    ];
    _run = _with(
      r,
      candidates: [...r.candidates, ...fresh],
      lines: [
        for (final l in r.lines)
          l.id == lineId
              ? _lineWith(
                  l,
                  generations: [
                    ...l.generations.take(l.generations.length - 1),
                    _genWith(
                      gen,
                      childKeys: [
                        ...gen.childKeys,
                        for (final c in fresh) c.key,
                      ],
                    ),
                  ],
                )
              : l,
      ],
      progress: () => ExploreProgress(
        done: 0,
        total: count,
        lineName: line.name,
        generation: gen.number,
      ),
    );
    log('${line.name} 第 ${gen.number} 代生成 $count 张子代');
    _startTicker();
  }

  ExploreParent _parentOf(ExploreCandidate c) => ExploreParent(
    id: 'p${_seq++}',
    candidateKey: c.key,
    image: c.thumb ?? c.image,
    atoms: c.atoms,
  );

  ExploreParent _custom(String raw) => ExploreParent(
    id: 'p${_seq++}',
    atoms: [
      for (final s in raw.split(','))
        if (s.trim().isNotEmpty)
          ExploreAtom(raw: s.trim(), text: s.trim().replaceAll('artist:', '')),
    ],
  );

  // ───────────── 回调 ─────────────

  ExploreActions get actions => ExploreActions(
    onOpenRun: (id) => log('打开探索 $id（预览里不切换）'),
    onNewRun: () => _set(() {
      _timer?.cancel();
      _run = null;
      log('新建探索：回到首次使用页，抽第一批时创建');
    }),
    onRenameRun: (id, name) => _set(() {
      _update((r) => _with(r, name: name));
      _runs = [
        for (final s in _runs)
          s.id == id
              ? ExploreRunSummary(
                  id: s.id,
                  name: name,
                  updatedAt: s.updatedAt,
                  total: s.total,
                  favorites: s.favorites,
                  lines: s.lines,
                  thumbs: s.thumbs,
                  state: s.state,
                  done: s.done,
                  target: s.target,
                  failed: s.failed,
                )
              : s,
      ];
      log('改名：$name');
    }),
    onDeleteRun: (id) => _set(() {
      _runs = [
        for (final s in _runs)
          if (s.id != id) s,
      ];
      if (_run?.id == id) {
        _timer?.cancel();
        _run = null;
      }
      log('删除探索 $id');
    }),
    onGenerate: () => _set(_generate),
    onStop: () => _set(() {
      _timer?.cancel();
      _update(
        (r) => _with(
          r,
          candidates: [
            for (final c in r.candidates)
              if (c.done || c.state == ExploreCandidateState.failed) c,
          ],
          progress: () => null,
        ),
      );
      log('停止：没出的取消掉');
    }),
    onPause: () => _set(() {
      final p = _run?.progress;
      if (p == null) return;
      _update(
        (r) => _with(
          r,
          progress: () => ExploreProgress(
            done: p.done,
            total: p.total,
            round: p.round,
            lineName: p.lineName,
            generation: p.generation,
            paused: true,
          ),
        ),
      );
      log('暂停');
    }),
    onResume: () => _set(() {
      final p = _run?.progress;
      if (p == null) return;
      _update(
        (r) => _with(
          r,
          progress: () => ExploreProgress(
            done: p.done,
            total: p.total,
            round: p.round,
            lineName: p.lineName,
            generation: p.generation,
          ),
        ),
      );
      log('继续');
    }),
    onCountChanged: (v) => _set(() => _count = v),
    onRetryFailed: () => _set(() {
      final failed = [
        for (final c in _run?.candidates ?? const <ExploreCandidate>[])
          if (c.state == ExploreCandidateState.failed) c.key,
      ];
      final t = _templates.first;
      _mapCandidates(
        failed,
        (c) => c.copyWith(
          state: ExploreCandidateState.done,
          image: t.image,
          thumb: t.thumb,
          error: () => null,
        ),
      );
      log('重试 ${failed.length} 张失败的候选');
    }),
    onSetFavorite: (keys, v) => _set(() {
      _mapCandidates(keys, (c) => c.copyWith(favorite: v));
      log('${v ? '收藏' : '取消收藏'} ${keys.length} 张');
    }),
    onAssignGroup: (keys, g) => _set(() {
      _mapCandidates(keys, (c) => c.copyWith(groupId: () => g));
      final name = _run?.groups.where((x) => x.id == g).firstOrNull?.name;
      log(g == null ? '移出分组 ${keys.length} 张' : '归到「$name」${keys.length} 张');
    }),
    onCreateGroup: (name, keys) => _set(() {
      final id = 'g${_seq++}';
      _update(
        (r) => _with(
          r,
          groups: [
            ...r.groups,
            ExploreGroup(id: id, name: name),
          ],
        ),
      );
      _mapCandidates(keys, (c) => c.copyWith(groupId: () => id));
      log('新分组「$name」');
    }),
    onRenameGroup: (id, name) => _set(() {
      _update(
        (r) => _with(
          r,
          groups: [
            for (final g in r.groups)
              g.id == id ? ExploreGroup(id: id, name: name) : g,
          ],
        ),
      );
      log('分组改名：$name');
    }),
    onDeleteGroup: (id) => _set(() {
      final keys = [
        for (final c in _run!.candidates)
          if (c.groupId == id) c.key,
      ];
      _mapCandidates(keys, (c) => c.copyWith(groupId: () => null));
      _update(
        (r) => _with(
          r,
          groups: [
            for (final g in r.groups)
              if (g.id != id) g,
          ],
        ),
      );
      log('删除分组');
    }),
    onDeleteCandidates: (keys) => _set(() {
      final set = keys.toSet();
      _trash = [
        for (final c in _run!.candidates)
          if (set.contains(c.key)) c,
      ];
      _update(
        (r) => _with(
          r,
          candidates: [
            for (final c in r.candidates)
              if (!set.contains(c.key)) c,
          ],
        ),
      );
      _undo = ExploreUndo(id: 'u${_undoId++}', count: keys.length);
    }),
    onUndoDelete: () => _set(() {
      _update((r) => _with(r, candidates: [...r.candidates, ..._trash]));
      _trash = const [];
      _undo = null;
      log('撤销删除');
    }),
    onDismissUndo: () => _set(() => _undo = null),
    onCopyArtists: (keys) => log('复制 ${keys.length} 张的画师串'),
    onApplyToEditor: (k) => log('套用 $k 的正向到编辑区'),
    onSaveBlock: (d) => log(
      '存为块「${d.title}」：${d.fullText != null ? '完整正向' : '${d.atoms.length} 位画师'}'
      ' → ${d.folderId ?? '根目录'}',
    ),
    onStartEvolution: (plan) => _set(() {
      final r = _run!;
      final parents = [
        for (final k in plan.candidateKeys)
          if (r.candidate(k) case final c?) _parentOf(c),
        for (final s in plan.customParents) _custom(s),
      ];
      _mapCandidates(plan.candidateKeys, (c) => c.copyWith(inEvolution: true));
      String lineId;
      if (plan.joinLineId case final id?) {
        lineId = id;
        _update(
          (r) => _with(
            r,
            lines: [
              for (final l in r.lines)
                l.id == id
                    ? _lineWith(
                        l,
                        generations: [
                          ...l.generations.take(l.generations.length - 1),
                          _genWith(
                            l.current,
                            parents: [...l.current.parents, ...parents],
                          ),
                        ],
                      )
                    : l,
            ],
          ),
        );
        log('加入 ${parents.length} 个父本');
      } else {
        lineId = 'l${_seq++}';
        _update(
          (r) => _with(
            r,
            lines: [
              ...r.lines,
              ExploreLine(
                id: lineId,
                name: plan.newLineName ?? '进化线',
                generations: [
                  ExploreGeneration(
                    number: 1,
                    parents: parents,
                    picked: plan.candidateKeys.length,
                  ),
                ],
              ),
            ],
          ),
        );
        log('新建进化线「${plan.newLineName}」');
      }
      if (plan.generate case final n?) _children(lineId, n);
    }),
    onCompare: (lineId, a, b, result) => _set(() {
      double delta(String id) => switch (result) {
        ExploreCompareResult.left => id == a ? .25 : -.1,
        ExploreCompareResult.right => id == b ? .25 : -.1,
        ExploreCompareResult.neither => -.1,
        ExploreCompareResult.skip => 0,
      };
      _update(
        (r) => _with(
          r,
          lines: [
            for (final l in r.lines)
              l.id == lineId
                  ? _lineWith(
                      l,
                      generations: [
                        ...l.generations.take(l.generations.length - 1),
                        _genWith(
                          l.current,
                          parents: [
                            for (final p in l.current.parents)
                              p.id == a || p.id == b
                                  ? ExploreParent(
                                      id: p.id,
                                      atoms: p.atoms,
                                      candidateKey: p.candidateKey,
                                      image: p.image,
                                      preference: math.max(
                                        .25,
                                        p.preference + delta(p.id),
                                      ),
                                    )
                                  : p,
                          ],
                        ),
                      ],
                    )
                  : l,
          ],
        ),
      );
      log('比较：${result.name}');
    }),
    onBreed: (lineId, keys) => _set(() {
      final r = _run!;
      final line = r.lines.firstWhere((l) => l.id == lineId);
      final parents = [
        for (final k in keys)
          if (r.candidate(k) case final c?) _parentOf(c),
      ];
      _update(
        (r) => _with(
          r,
          lines: [
            for (final l in r.lines)
              l.id == lineId
                  ? _lineWith(
                      l,
                      generations: [
                        ...l.generations,
                        ExploreGeneration(
                          number: line.current.number + 1,
                          parents: parents,
                          fromGeneration: line.current.number,
                          picked: keys.length,
                        ),
                      ],
                    )
                  : l,
          ],
        ),
      );
      _children(lineId, 8);
    }),
    onGenerateChildren: (lineId, n) => _set(() => _children(lineId, n)),
    onRenameLine: (id, name) => _set(() {
      _update(
        (r) => _with(
          r,
          lines: [
            for (final l in r.lines) l.id == id ? _lineWith(l, name: name) : l,
          ],
        ),
      );
      log('进化线改名：$name');
    }),
    onDeleteLine: (id) => _set(() {
      final kids = {
        for (final c in _run!.candidates)
          if (c.lineId == id) c.key,
      };
      _update(
        (r) => _with(
          r,
          lines: [
            for (final l in r.lines)
              if (l.id != id) l,
          ],
          candidates: [
            for (final c in r.candidates)
              if (!kids.contains(c.key)) c,
          ],
        ),
      );
      log('删除进化线（${kids.length} 张子代）');
    }),
    onOpenVariable: (i) => log('在提示词里打开第 ${i + 1} 个随机块的实例卡'),
    onOpenBlockLibrary: () => log('打开块库侧栏'),
    onCardSizeChanged: (s) => _set(() => _size = s),
    onInspectorChanged: (v) => _set(() => _inspector = v),
    onEditorWidthChanged: (w) => _set(() => _editor = w),
    onFullscreenChanged: (v) => _set(() => _fullscreen = v),
    onCaptionOverStage: (v) => log('窗口按钮${v ? '压在黑底上（换浅色）' : '跟主题'}'),
  );
}
