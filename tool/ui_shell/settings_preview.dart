// 设置页预览：本地模拟器，按契约回调改假数据（自动保存、撤销、恢复默认、快捷键录制……），
// 让每个按钮在预览里都“真的”起作用。只给 preview_main.dart 用，不进应用。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_search.dart';

import 'model_providers_preview.dart';

class SettingsPreviewSim extends ChangeNotifier {
  SettingsPreviewSim({required this.log}) {
    providers.addListener(notifyListeners);
  }

  final ValueChanged<String> log;

  /// 模型与接口 → 服务商：新工作台（本地模拟器）。
  late final providers = ModelProvidersPreviewSim(log: log);

  /// 主题设置改了：预览跟着切深浅色。
  ValueChanged<String>? onTheme;

  var _scene = SettingsScene.ready;
  var _page = SettingsPageId.overview;
  late SettingsViewData _data = _extras(SettingsFixture.view());

  /// 预览额外带上：基础提示词编辑；小号的余额和订阅“未读取”（非当前账号不自动登录查询）。
  static SettingsViewData _extras(SettingsViewData d) => d.copyWith(
    agent: d.agent.copyWith(systemPrompt: SettingsFixture.systemPrompt),
    account: SettingsAccountData(
      monthlyAnlas: d.account.monthlyAnlas,
      todayUsed: d.account.todayUsed,
      accounts: [
        for (final a in d.account.accounts)
          a.current || a.expired
              ? a
              : SettingsAccount(
                  id: a.id,
                  name: a.name,
                  tier: null,
                  anlas: null,
                  loginKind: a.loginKind,
                  maskedId: a.maskedId,
                  lastUsedAt: a.lastUsedAt,
                  isDefault: a.isDefault,
                  color: a.color,
                ),
      ],
    ),
  );
  final _undo = <String, (SettingKey, Object?)>{};
  var _n = 0;
  Timer? _download;
  Timer? _install;
  final _build = <SettingsRagSourceKind, Timer>{};

  @override
  void dispose() {
    _stopRag();
    providers.dispose();
    super.dispose();
  }

  void _stopRag() {
    _download?.cancel();
    _install?.cancel();
    for (final t in _build.values) {
      t.cancel();
    }
    _build.clear();
  }

  SettingsScene get scene => _scene;
  set scene(SettingsScene s) {
    _scene = s;
    _stopRag();
    _data = _extras(SettingsFixture.view(page: _page, scene: s));
    _undo.clear();
    notifyListeners();
  }

  SettingsViewData data({required bool dark}) {
    final m = _data.models;
    final d = _data.copyWith(
      models: SettingsModelsData(
        providers: m.providers,
        assignments: m.assignments,
        presets: m.presets,
        requests: m.requests,
        requestTotal: m.requestTotal,
        workbench: _scene == SettingsScene.fresh
            ? ProvidersFixture.empty
            : providers.data,
      ),
    );
    final v = d.values.text(SettingKey.themeMode);
    if (v == 'system' || (v == 'dark') == dark) return d;
    return d.copyWith(
      values: _data.values.copyWith(
        SettingKey.themeMode,
        dark ? 'dark' : 'light',
      ),
    );
  }

  void _set(
    SettingKey k,
    Object? value, {
    required String title,
    bool record = true,
  }) {
    final before = _data.values[k];
    final def = SettingSpec.of(k).defaultValue;
    final modified = {..._data.modified};
    value == def ? modified.remove(k) : modified.add(k);
    final id = 'c${++_n}';
    if (record) _undo[id] = (k, before);
    final change = SettingsChange(
      id: id,
      title: title,
      from: '$before',
      to: '$value',
      at: SettingsFixture.now,
      undoable: record,
    );
    _data = _data.copyWith(
      values: _data.values.copyWith(k, value),
      modified: modified,
      lastChange: change,
      recent: [change, ..._data.recent].take(5).toList(),
      restartPending: _data.restartPending || SettingSpec.of(k).restart,
    );
    notifyListeners();
  }

  SettingsActions actions(BuildContext context) {
    String t(SettingKey k) => settingTitle(context, k);
    return SettingsActions(
      providers: providers.actions,
      onCopyModelConfig: () => log('onCopyModelConfig'),
      onOpenPage: (p) {
        _page = p;
        _data = _data.copyWith(page: p);
        notifyListeners();
      },
      onChanged: (k, v) {
        _set(k, v, title: t(k));
        if (k == SettingKey.themeMode) onTheme?.call('$v');
      },
      onReset: (k) => _set(k, SettingSpec.of(k).defaultValue, title: t(k)),
      onResetPage: (p) {
        for (final k
            in _data.modified
                .where((k) => SettingSpec.of(k).page == p)
                .toList()) {
          _set(k, SettingSpec.of(k).defaultValue, title: t(k), record: false);
        }
        log('onResetPage(${p.name})');
      },
      onUndo: (id) {
        final u = _undo.remove(id);
        if (u == null) return log('onUndo($id)：假数据里没有这条');
        _set(u.$1, u.$2, title: t(u.$1), record: false);
      },
      onChannelChanged: (c) {
        _data = _data.copyWith(canvas: SettingsCanvasData(channel: c));
        notifyListeners();
      },
      onShortcutRecorded: (id, keys) => _shortcut(id, (x) => keys),
      onShortcutCleared: (id) => _shortcut(id, (x) => const []),
      onShortcutReset: (id) => _shortcut(id, (x) => x.defaultKeys),
      onSaveInstructions:
          ({
            required global,
            required prefix,
            required expectedGlobal,
            required expectedPrefix,
          }) async {
            _data = _data.copyWith(
              agent: _data.agent.copyWith(
                globalInstructions: global,
                systemPrefix: prefix,
              ),
            );
            log('onSaveInstructions');
            notifyListeners();
            return true;
          },
      onSaveSystemPrompt:
          ({
            required scope,
            required text,
            required workspaceId,
            required expectedText,
          }) async {
            log(
              'onSaveSystemPrompt(${scope.name}, ${text == null ? 'null' : '${text.length} 字'}, $workspaceId)',
            );
            await Future<void>.delayed(const Duration(milliseconds: 400));
            final sp = _data.agent.systemPrompt;
            if (sp == null) return false;
            final ws = scope == SettingsPromptScope.workspace;
            if (ws && workspaceId != sp.workspaceId) return false;
            _data = _data.copyWith(
              agent: _data.agent.copyWith(
                systemPrompt: SettingsSystemPrompt(
                  builtin: sp.builtin,
                  global: ws ? sp.global : text,
                  workspaceId: sp.workspaceId,
                  workspaceName: sp.workspaceName,
                  workspace: ws ? text : sp.workspace,
                ),
              ),
            );
            notifyListeners();
            return true;
          },
      onAddBlacklistTag: (tag) => _blacklist([..._data.privacy.blacklist, tag]),
      onRemoveBlacklistTag: (tag) =>
          _blacklist([..._data.privacy.blacklist]..remove(tag)),
      onRestart: () => log('onRestart（真实应用重启 Studio）'),
      onAddAccount: () => log('onAddAccount'),
      onSwitchAccount: (id) => log('onSwitchAccount($id)'),
      onDeleteAccount: (id) => log('onDeleteAccount($id)'),
      onPickPath: (k) {
        log('onPickPath(${k.name})');
        if (k != SettingKey.ragPythonPath) return;
        _set(k, r'C:\Python312\python.exe', title: t(k));
        _setRag(pythonPending: true);
      },
      onOpenPath: (k) => log('onOpenPath(${k.name})'),
      onOpenFolder: (f) => log('onOpenFolder(${f.name})'),
      onClearCache: (k) => log('onClearCache(${k.name})'),
      onCleanThumbnails: () => log('onCleanThumbnails'),
      onRescanGallery: () => log('onRescanGallery'),
      onTestProvider: (id) => log('onTestProvider($id)'),
      onDeleteProvider: (id) => log('onDeleteProvider($id)'),
      onRequestDetails: (id) => log('onRequestDetails($id)'),
      onAssign:
          (
            task, {
            providerId,
            modelId,
            presetId,
            reasoningEffort,
            clearReasoningEffort = false,
          }) => log(
            'onAssign(${task.name}, $providerId, $modelId, $presetId, '
            '$reasoningEffort, clearReasoningEffort: $clearReasoningEffort)',
          ),
      onRagSourceEnabled: (k, v) => _source(
        k,
        (x) => _src(
          x,
          enabled: v,
          state: !v
              ? SettingsRagState.off
              : (x.done > 0 ? SettingsRagState.ready : SettingsRagState.empty),
        ),
      ),
      onRagPause: (k) {
        _build.remove(k)?.cancel();
        _source(k, (x) => _src(x, state: SettingsRagState.paused));
      },
      onRagResume: _runBuild,
      onRagBuild: (k) => _plan(k, rebuild: false),
      onRagRebuild: (k) => _plan(k, rebuild: true),
      onRagCancelPlan: () => _setRag(plan: null),
      onRagStartPlan: () {
        final plan = _data.rag.plan;
        if (plan == null || plan.loading) return;
        _setRag(plan: null);
        if (plan.rebuild) _source(plan.kind, (x) => _src(x, done: 0));
        _runBuild(plan.kind);
      },
      onRagClear: (k) {
        _build.remove(k)?.cancel();
        _source(
          k,
          (x) => _src(x, state: SettingsRagState.empty, done: 0, error: null),
        );
      },
      onRagRefresh: () => log('onRagRefresh'),
      onRagCheckRuntime: () {
        _setRag(checking: true);
        Timer(
          const Duration(milliseconds: 900),
          () => _setRag(checking: false),
        );
      },
      onRagInstallRuntime: ({required cuda}) => _runInstall(cuda),
      onRagCancelInstall: () {
        _install?.cancel();
        _setRag(install: null, error: '已取消安装');
      },
      onRagUsePython: () => _runInstall(_data.rag.runtimeCuda),
      onRagDownload: _runDownload,
      onRagCancelDownload: () {
        _download?.cancel();
        _setRag(download: null);
      },
      onRagDiscoverModels: () {
        // 第一次演示“没找到”，再点一次演示找到。
        if (!_data.rag.modelsMissing) return _setRag(modelsMissing: true);
        _data = _data.copyWith(
          values: _data.values
              .copyWith(
                SettingKey.ragEmbedPath,
                r'E:\A.I\NovelAI\04_工具\models\embeddinggemma-2',
              )
              .copyWith(
                SettingKey.ragRerankPath,
                r'E:\A.I\NovelAI\04_工具\models\Qwen3-Reranker-0.6B',
              ),
        );
        _setRag(modelsMissing: false);
      },
      onUpscaleInstall: (id) => log('onUpscaleInstall($id)'),
      onUpscaleCancel: (id) => log('onUpscaleCancel($id)'),
      onTestComfy: () => log('onTestComfy'),
      onCheckEndpoints: () => log('onCheckEndpoints'),
      onResetScopes: (s) =>
          log('onResetScopes(${s.map((e) => e.name).join(',')})'),
      onRestoreBackup: (id) => log('onRestoreBackup($id)'),
      onCheckUpdate: () => log('onCheckUpdate'),
      onInstallUpdate: () => log('onInstallUpdate'),
      onCopyDiagnostics: () => log('onCopyDiagnostics'),
      onShortcutsResetAll: () => log('onShortcutsResetAll'),
      onMcpMode: (id, m) => log('onMcpMode($id, ${m.name})'),
    );
  }

  void _shortcut(String id, List<String> Function(SettingsShortcut) keys) {
    final list = [
      for (final x in _data.shortcuts.shortcuts)
        x.id == id
            ? SettingsShortcut(
                id: x.id,
                context: x.context,
                label: x.label,
                keys: keys(x),
                defaultKeys: x.defaultKeys,
              )
            : x,
    ];
    // 重新算冲突：同一上下文里组合相同。
    String? clash(SettingsShortcut x) => x.keys.isEmpty
        ? null
        : list
              .where(
                (y) =>
                    y.id != x.id &&
                    y.context == x.context &&
                    y.keys.join('+') == x.keys.join('+'),
              )
              .firstOrNull
              ?.id;
    _data = _data.copyWith(
      shortcuts: SettingsShortcutsData(
        contexts: _data.shortcuts.contexts,
        shortcuts: [
          for (final x in list)
            SettingsShortcut(
              id: x.id,
              context: x.context,
              label: x.label,
              keys: x.keys,
              defaultKeys: x.defaultKeys,
              conflictWith: clash(x),
            ),
        ],
      ),
    );
    log(
      'shortcut($id) → ${keys(list.firstWhere((x) => x.id == id)).join('+')}',
    );
    notifyListeners();
  }

  void _blacklist(List<String> tags) {
    final p = _data.privacy;
    _data = _data.copyWith(
      privacy: SettingsPrivacyData(
        blacklist: tags,
        danbooruUser: p.danbooruUser,
        lastSyncAt: p.lastSyncAt,
      ),
    );
    notifyListeners();
  }

  // ── 语义检索模拟：下载、安装、建库都按定时器走进度。

  static const _keep = Object();

  void _setRag({
    Object? install = _keep,
    Object? download = _keep,
    Object? plan = _keep,
    Object? error = _keep,
    bool? checking,
    bool? runtimeReady,
    bool? runtimeCuda,
    bool? pythonPending,
    bool? modelsMissing,
    SettingsRagStep? runtime,
    SettingsRagStep? embedder,
    SettingsRagStep? reranker,
    List<SettingsRagSource>? sources,
  }) {
    final r = _data.rag;
    _data = _data.copyWith(
      rag: SettingsRagData(
        runtime: runtime ?? r.runtime,
        embedder: embedder ?? r.embedder,
        reranker: reranker ?? r.reranker,
        device: r.device,
        sources: sources ?? r.sources,
        indexBytes: r.indexBytes,
        checking: checking ?? r.checking,
        runtimeReady: runtimeReady ?? r.runtimeReady,
        runtimeCuda: runtimeCuda ?? r.runtimeCuda,
        runtimePython: r.runtimePython.isEmpty && (runtimeReady ?? false)
            ? r'%APPDATA%\nai_launcher\rag\python\python.exe'
            : r.runtimePython,
        pythonPending: pythonPending ?? r.pythonPending,
        install: identical(install, _keep)
            ? r.install
            : install as SettingsRagInstall?,
        download: identical(download, _keep)
            ? r.download
            : download as SettingsRagDownload?,
        modelsMissing: modelsMissing ?? r.modelsMissing,
        plan: identical(plan, _keep) ? r.plan : plan as SettingsRagPlan?,
        error: identical(error, _keep) ? r.error : error as String?,
      ),
    );
    notifyListeners();
  }

  SettingsRagSource _src(
    SettingsRagSource x, {
    SettingsRagState? state,
    bool? enabled,
    int? done,
    int? total,
    Object? error = _keep,
  }) => SettingsRagSource(
    kind: x.kind,
    state: state ?? x.state,
    enabled: enabled ?? x.enabled,
    done: done ?? x.done,
    total: total ?? x.total,
    secondary: x.secondary,
    skipped: x.skipped,
    error: identical(error, _keep) ? x.error : error as String?,
  );

  void _source(
    SettingsRagSourceKind k,
    SettingsRagSource Function(SettingsRagSource) f,
  ) => _setRag(
    sources: [for (final x in _data.rag.sources) x.kind == k ? f(x) : x],
  );

  /// 每个来源假想的（资料份数 / 图片张数，片段数）。
  static const _planTotals = {
    SettingsRagSourceKind.tags: (0, 182340),
    SettingsRagSourceKind.wiki: (1204, 12406),
    SettingsRagSourceKind.blocks: (842, 842),
    SettingsRagSourceKind.gallery: (12408, 9120),
  };

  void _plan(SettingsRagSourceKind k, {required bool rebuild}) {
    _setRag(
      plan: SettingsRagPlan(kind: k, rebuild: rebuild, loading: true),
    );
    Timer(const Duration(milliseconds: 700), () {
      if (_data.rag.plan?.kind != k) return;
      final (docs, total) = _planTotals[k]!;
      final gallery = k == SettingsRagSourceKind.gallery;
      _setRag(
        plan: SettingsRagPlan(
          kind: k,
          rebuild: rebuild,
          total: total,
          documents: gallery ? 0 : docs,
          images: gallery ? docs : 0,
          roots: gallery
              ? const [r'E:\A.I\NovelAI\outputs', r'E:\A.I\NovelAI\01_图库']
              : const [],
        ),
      );
    });
  }

  void _runBuild(SettingsRagSourceKind k) {
    _build.remove(k)?.cancel();
    final x0 = _data.rag.sources.firstWhere((x) => x.kind == k);
    final total = x0.total > 0
        ? x0.total
        : (k == SettingsRagSourceKind.gallery
              ? _planTotals[k]!.$1
              : _planTotals[k]!.$2);
    _source(
      k,
      (x) =>
          _src(x, state: SettingsRagState.building, total: total, error: null),
    );
    _build[k] = Timer.periodic(const Duration(milliseconds: 250), (t) {
      final x = _data.rag.sources.firstWhere((x) => x.kind == k);
      final done = (x.done + (total / 24).ceil()).clamp(0, total);
      _source(
        k,
        (x) => _src(
          x,
          done: done,
          state: done >= total ? SettingsRagState.ready : null,
        ),
      );
      if (done >= total) _build.remove(k)?.cancel();
    });
  }

  void _runInstall(bool cuda) {
    _install?.cancel();
    final phases = [
      SettingsRagInstallPhase.existing,
      SettingsRagInstallPhase.download,
      SettingsRagInstallPhase.create,
      if (cuda) SettingsRagInstallPhase.cuda,
      SettingsRagInstallPhase.packages,
      SettingsRagInstallPhase.check,
    ];
    var tick = 0;
    _setRag(
      error: null,
      install: SettingsRagInstall(phase: phases.first),
      runtime: const SettingsRagStep(value: '安装中', tone: SettingsTone.warn),
    );
    _install = Timer.periodic(const Duration(milliseconds: 400), (t) {
      tick++;
      final i = tick ~/ 4;
      if (i >= phases.length) {
        t.cancel();
        _setRag(
          install: null,
          runtimeReady: true,
          runtimeCuda: cuda,
          pythonPending: false,
          runtime: SettingsRagStep(
            value: cuda ? 'CUDA 12.4' : 'CPU',
            detail: '独立 Python · 不影响放大组件',
          ),
        );
        return;
      }
      _setRag(
        install: SettingsRagInstall(
          phase: phases[i],
          elapsed: Duration(seconds: (tick % 4) * 7),
          detail: 'step ${i + 1}/${phases.length} · pip install …',
        ),
      );
    });
  }

  void _runDownload(SettingsRagModel m) {
    _download?.cancel();
    const total = 1180 * 1024 * 1024;
    var received = 0;
    var verify = 0;
    _setRag(
      error: null,
      download: SettingsRagDownload(model: m, total: total),
    );
    _download = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (received < total) {
        received = (received + total ~/ 18).clamp(0, total);
        _setRag(
          download: SettingsRagDownload(
            model: m,
            received: received,
            total: total,
          ),
        );
        return;
      }
      if (verify++ < 4) {
        _setRag(
          download: SettingsRagDownload(
            model: m,
            received: total,
            total: total,
            verifying: true,
          ),
        );
        return;
      }
      t.cancel();
      final embed = m == SettingsRagModel.embedder;
      _data = _data.copyWith(
        values: _data.values.copyWith(
          embed ? SettingKey.ragEmbedPath : SettingKey.ragRerankPath,
          embed
              ? r'%APPDATA%\nai_launcher\rag\models\embeddinggemma-2'
              : r'%APPDATA%\nai_launcher\rag\models\Qwen3-Reranker-0.6B',
        ),
      );
      const embedStep = SettingsRagStep(
        value: 'EmbeddingGemma 2',
        detail: '文字 + 图片',
      );
      const rerankStep = SettingsRagStep(
        value: 'Qwen3-Reranker 0.6B',
        detail: '仅文字',
      );
      _setRag(
        download: null,
        modelsMissing: false,
        embedder: embed ? embedStep : null,
        reranker: embed ? null : rerankStep,
      );
    });
  }
}
