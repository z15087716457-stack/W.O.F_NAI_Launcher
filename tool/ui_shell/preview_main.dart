// 新界面预览：不接后端，用假数据驱动，能切状态 / 主题 / 语言。
// 运行：flutter run -d windows -t tool/ui_shell/preview_main.dart
// 主导航包着页面：切到“统计”显示统计页，“在线画廊”显示在线画廊，“Vibe 库 / 精准参考库”显示参考库，
// “块库”显示块库管理页，“生图”显示块库侧栏 + 带药丸的提示词（点药丸开实例卡），
// “设置”显示新设置页，“本地画廊”显示大图查看器（全屏时藏起主导航）；生图页工具条的增强 / 放大 / 编辑 / 局部重绘 / 导演工具
// 由画布工具模拟器接管（都由本地模拟器驱动），其他页显示占位。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_labels.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/ui/online/online_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';

import 'blocks_preview.dart';
import 'explore_preview.dart';
import 'gen_preview.dart';
import 'online_preview.dart';
import 'refs_preview.dart';
import 'settings_preview.dart';
import 'tools_preview.dart';
import 'viewer_preview.dart';

void main() => runApp(const _PreviewApp());

enum _Scene { ready, loading, empty, error, updating, failed, artistsPending }

enum _Gen { idle, running, done, failed }

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  var _dark = false;
  var _locale = const Locale('zh');
  String? _lastAction;

  // 主导航
  var _page = NavPage.generation;
  var _gen = _Gen.idle;
  var _tasks = false;
  var _pinned = false;
  var _hidden = <NavPage>{};
  var _ctrlNumbers = true;
  var _ctrlHintSeen = false;
  var _update = false;
  var _signedIn = true;
  final _cancelling = <String>{};
  final _undone = <String>{};

  // 统计页
  var _scene = _Scene.ready;
  var _range = StatsRange.all;
  var _naiOnly = false;
  var _refreshing = false;

  // 在线画廊
  late final _online = OnlinePreviewSim(log: _log)..addListener(_rebuild);

  // Vibe / 精准参考库
  late final _refs = RefsPreviewSim(log: _log)..addListener(_rebuild);
  var _picker = false;

  // 块系统
  late final _blocks = BlocksPreviewSim(log: _log)..addListener(_rebuild);

  // 本地画廊大图
  late final _viewer = ViewerPreviewSim(log: _log)
    ..addListener(_rebuild)
    ..onClose = () => _log('关闭大图（真实应用回到本地画廊）');

  // 设置页
  late final _settings = SettingsPreviewSim(log: _log)
    ..addListener(_rebuild)
    ..onTheme = (v) => setState(() => _dark = v == 'dark');

  // 画风探索
  late final _explore = ExplorePreviewSim(log: _log)..addListener(_rebuild);

  // 生图页
  // 生图页 + 画布工具（工具条面板、编辑器、导演工具）
  late final _tools = ToolsPreviewSim(log: _log)..addListener(_rebuild);
  late final _genSim = _tools.gen..addListener(_rebuild);

  /// 画布视觉通道：每次打开预览随机一个种子（同正式版“每次进来主题不一样”）。
  var _channelOn = true;
  var _channel = ChannelSettings(seed: math.Random().nextInt(1 << 31));

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _online.dispose();
    _refs.dispose();
    _blocks.dispose();
    _viewer.dispose();
    _explore.dispose();
    _settings.dispose();
    _tools.dispose();
    super.dispose();
  }

  void _log(String s) => setState(() => _lastAction = s);

  NavViewData get _nav {
    final base = NavFixture.view(
      current: _page,
      pinned: _pinned,
      hidden: _hidden,
      ctrlHintSeen: _ctrlHintSeen,
      updateAvailable: _update,
      account: _signedIn ? null : const NavAccountData(),
      generation: switch (_gen) {
        _Gen.idle => const NavGeneration.idle(),
        _Gen.running => NavFixture.running,
        _Gen.done => const NavGeneration(
          state: NavGenerationState.done,
          total: 4,
        ),
        _Gen.failed => const NavGeneration(
          state: NavGenerationState.failed,
          error: 'Anlas 不足，需要 20，剩余 12',
        ),
      },
      tasks: _tasks
          ? [
              for (final t in NavFixture.tasks)
                if (!_undone.contains(t.id))
                  _cancelling.contains(t.id)
                      ? NavTask(
                          id: t.id,
                          kind: t.kind,
                          fraction: t.fraction,
                          phase: t.phase,
                          action: NavTaskAction.cancelling,
                        )
                      : t,
            ]
          : const [],
    );
    return NavViewData(
      current: base.current,
      shortcuts: base.shortcuts,
      hidden: base.hidden,
      ctrlNumbers: _ctrlNumbers,
      ctrlHintSeen: base.ctrlHintSeen,
      pinned: base.pinned,
      updateAvailable: base.updateAvailable,
      account: base.account,
      generation: base.generation,
      tasks: base.tasks,
    );
  }

  NavActions get _navActions => NavActions(
    onOpenPage: (p) => setState(() {
      _page = p;
      if (p == NavPage.generation && _gen != _Gen.running) _gen = _Gen.idle;
    }),
    onPinnedChanged: (v) => setState(() => _pinned = v),
    onHiddenChanged: (v) => setState(() => _hidden = v),
    onCtrlNumbersChanged: (v) => setState(() => _ctrlNumbers = v),
    onCtrlHintSeen: () => setState(() => _ctrlHintSeen = true),
    onSwitchAccount: (id) => _log('onSwitchAccount($id)'),
    onAddAccount: () => _log('onAddAccount'),
    onManageAccounts: () => _log('onManageAccounts'),
    onLogout: () => setState(() => _signedIn = false),
    onCancelTask: (id) => setState(() => _cancelling.add(id)),
    onUndoTask: (id) => setState(() => _undone.add(id)),
  );

  StatsViewData get _stats => StatsFixture.view(
    range: _range,
    naiOnly: _naiOnly,
    loading: _scene == _Scene.loading,
    empty: _scene == _Scene.empty,
    error: _scene == _Scene.error ? 'database is locked' : null,
    artistsPending: _scene == _Scene.artistsPending,
    sync: _refreshing || _scene == _Scene.updating
        ? StatsSyncState.updating
        : _scene == _Scene.failed
        ? StatsSyncState.failed
        : StatsSyncState.idle,
  );

  StatsActions get _statsActions => StatsActions(
    onRangeChanged: (r) => setState(() => _range = r),
    onNaiOnlyChanged: (v) => setState(() => _naiOnly = v),
    onRefresh: () {
      setState(() => _refreshing = true);
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _refreshing = false);
      });
    },
    onOpenGallery: (f) => _log('onOpenGallery($f)'),
    onGoGenerate: () => _log('onGoGenerate'),
    onAddGalleryFolder: () => _log('onAddGalleryFolder'),
  );

  /// 生图页；“视觉通道”打开时画布换成通道假画布（ChannelFixtureCanvas），显示设置里出通道一节。
  Widget _generationPage() {
    final data = _genSim.data;
    final channel = _channelOn ? _channel : null;
    void set(ChannelSettings v) {
      _log('onChannelChanged($v)');
      setState(() => _channel = v);
    }

    return GenerationPage(
      data: data.copyWith(canvas: data.canvas.withChannel(channel)),
      actions: _genSim.actions.withChannel(_channelOn ? set : null),
      slots: GenSlots(
        editor: _genSim.editor,
        dock: _genSim.dock(),
        toolSheet: _tools.sheet(),
        canvas: _channelOn
            ? (context, tile) => ChannelFixtureCanvas(
                settings: _channel,
                onSettingsChanged: set,
                generating: data.generate.state == GenRunState.generating,
                images: genPreviewImage,
              )
            : null,
      ),
    );
  }

  Widget _dropdown<T>(T value, List<T> values, ValueChanged<T> onChanged) =>
      DropdownButton<T>(
        value: value,
        isDense: true,
        items: [
          for (final v in values)
            DropdownMenuItem(value: v, child: Text(v is Enum ? v.name : '$v')),
        ],
        onChanged: (v) => onChanged(v as T),
      );

  Widget _chip(String label, bool value, ValueChanged<bool> onChanged) =>
      FilterChip(
        label: Text(label),
        selected: value,
        visualDensity: VisualDensity.compact,
        onSelected: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _dark ? GeistTheme.dark : GeistTheme.light,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Column(
          children: [
            Material(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _dropdown(
                      _locale,
                      AppLocalizations.supportedLocales,
                      (l) => setState(() => _locale = l),
                    ),
                    _chip('dark', _dark, (v) => setState(() => _dark = v)),
                    const Text('导航：'),
                    _dropdown(
                      _gen,
                      _Gen.values,
                      (g) => setState(() => _gen = g),
                    ),
                    _chip('后台任务', _tasks, (v) {
                      setState(() {
                        _tasks = v;
                        _cancelling.clear();
                        _undone.clear();
                      });
                    }),
                    _chip('更新', _update, (v) => setState(() => _update = v)),
                    _chip(
                      '已登录',
                      _signedIn,
                      (v) => setState(() => _signedIn = v),
                    ),
                    _chip(
                      'Ctrl 说明未看',
                      !_ctrlHintSeen,
                      (v) => setState(() => _ctrlHintSeen = !v),
                    ),
                    const Text('统计：'),
                    _dropdown(
                      _scene,
                      _Scene.values,
                      (s) => setState(() => _scene = s),
                    ),
                    const Text('在线画廊：'),
                    _dropdown(
                      _online.scene,
                      OnlineScene.values,
                      (s) => setState(() => _online.scene = s),
                    ),
                    const Text('参考库：'),
                    _dropdown(
                      _refs.scene,
                      RefsScene.values,
                      (s) => setState(() => _refs.scene = s),
                    ),
                    _chip(
                      '生图页选择器',
                      _picker,
                      (v) => setState(() => _picker = v),
                    ),
                    const Text('块库：'),
                    _dropdown(
                      _blocks.scene,
                      BlocksScene.values,
                      (s) => setState(() => _blocks.scene = s),
                    ),
                    const Text('大图：'),
                    _dropdown(
                      _viewer.scene,
                      ViewerScene.values,
                      (s) => setState(() => _viewer.scene = s),
                    ),
                    const Text('生图：'),
                    _dropdown(
                      _genSim.scene,
                      GenScene.values,
                      (s) => setState(() => _genSim.scene = s),
                    ),
                    _chip(
                      '视觉通道',
                      _channelOn,
                      (v) => setState(() => _channelOn = v),
                    ),
                    const Text('画布工具：'),
                    _dropdown(
                      _tools.scene,
                      ToolsScene.values,
                      (s) => setState(() {
                        _page = NavPage.generation;
                        _tools.scene = s;
                      }),
                    ),
                    const Text('画风探索：'),
                    _dropdown(
                      _explore.scene,
                      ExploreScene.values,
                      (s) => setState(() => _explore.scene = s),
                    ),
                    const Text('设置：'),
                    _dropdown(
                      _settings.scene,
                      SettingsScene.values,
                      (s) => setState(() {
                        _page = NavPage.settings;
                        _settings.scene = s;
                      }),
                    ),
                    if (_lastAction != null)
                      Text(_lastAction!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            if (_page == NavPage.localGallery && _viewer.fullscreen)
              Expanded(
                child: ImageViewerPage(
                  data: _viewer.data,
                  actions: _viewer.actions,
                ),
              )
            else if (_page == NavPage.generation &&
                _tools.view == ToolsView.director)
              Expanded(
                child: ToolsDirectorPage(
                  data: _tools.director,
                  actions: _tools.directorActions,
                ),
              )
            else if (_page == NavPage.styleExplore && _explore.fullscreen)
              Expanded(child: _explorePage())
            else
              Expanded(
                child: NavShell(
                  data: _nav,
                  actions: _navActions,
                  child: switch (_page) {
                    NavPage.statistics => StatisticsPage(
                      data: _stats,
                      actions: _statsActions,
                    ),
                    NavPage.onlineGallery => OnlineGalleryPage(
                      data: _online.data,
                      actions: _online.actions,
                    ),
                    NavPage.vibeLibrary || NavPage.preciseRef => _refsPage(),
                    NavPage.promptBlocks => BlocksLibraryPage(
                      data: _blocks.data,
                      actions: _blocks.actions,
                    ),
                    NavPage.generation when _tools.view == ToolsView.editor =>
                      ToolsEditorPage(
                        data: _tools.editor,
                        actions: _tools.editorActions,
                        slots: const ToolsEditorSlots(
                          canvas: ToolsFixtureStage.builder,
                        ),
                      ),
                    NavPage.generation =>
                      _genSim.scene == GenScene.blocksDemo
                          ? BlocksGenerationMock(log: _log)
                          : _generationPage(),
                    NavPage.styleExplore => _explorePage(),
                    NavPage.localGallery => ImageViewerPage(
                      data: _viewer.data,
                      actions: _viewer.actions,
                    ),
                    NavPage.settings => Builder(
                      builder: (context) => SettingsPage(
                        data: _settings.data(dark: _dark),
                        actions: _settings.actions(context),
                      ),
                    ),
                    _ => _Placeholder(page: _page),
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on _PreviewAppState {
  void _closePicker() {
    _picker = false;
    _rebuild();
  }

  Widget _explorePage() => StyleExplorePage(
    data: _explore.data,
    actions: _explore.actions,
    editor: (context, parts) =>
        exploreFixtureEditor(context, parts, v45: _explore.v45),
  );

  Widget _refsPage() {
    _refs.kind = _page == NavPage.vibeLibrary
        ? RefsKind.vibe
        : RefsKind.precise;
    final page = RefsLibraryPage(data: _refs.data, actions: _refs.actions);
    if (!_picker) return page;
    final vibe = _refs.kind == RefsKind.vibe;
    return Stack(
      children: [
        page,
        const Positioned.fill(child: ColoredBox(color: Color(0x33000000))),
        Center(
          child: RefsPicker(
            data: vibe
                ? RefsFixture.vibePicker(refsPreviewImage)
                : RefsFixture.precisePicker(refsPreviewImage),
            actions: RefsPickerActions(
              onConfirm: (keys, {required replace}) {
                _log('picker.onConfirm($keys, replace: $replace)');
                _closePicker();
              },
              onClose: () => _closePicker(),
              onOpenLibrary: () => _closePicker(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.page});
  final NavPage page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(page.icon, size: 40, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              page.label(context),
              style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
