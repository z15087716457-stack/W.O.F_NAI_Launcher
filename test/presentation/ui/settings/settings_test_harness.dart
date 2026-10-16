import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

/// 主导航宽度：页面可用宽度 = 窗口宽 − 48。
const settingsRail = 48.0;

/// 按“窗口宽”装一个设置页（扣掉主导航），关掉动画，带窗口按钮避让。
/// 页面切换和标量修改由 [SettingsHostState] 在本地套用，其余回调记进 [rec]。
Future<SettingsRecorder> pumpSettings(
  WidgetTester tester, {
  SettingsPageId page = SettingsPageId.overview,
  SettingsScene scene = SettingsScene.ready,
  SettingsViewData? data,
  double window = 1600,
  double height = 1000,
  String locale = 'zh',
  bool dark = false,
  String initialQuery = '',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(window - settingsRail, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final rec = SettingsRecorder();
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('settings-capture'),
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
            child: SettingsHost(
              data:
                  data ??
                  SettingsFixture.view(page: page, scene: scene, dark: dark),
              rec: rec,
              initialQuery: initialQuery,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return rec;
}

/// 记录回调。
class SettingsRecorder {
  final calls = <String>[];
  final changes = <(SettingKey, Object?)>[];
  final pages = <SettingsPageId>[];
  ChannelSettings? channel;

  /// onSaveSystemPrompt 的返回值（false = 模拟工作区已变 / 写入失败）。
  var promptResult = true;
  Future<bool> Function({required String global, required String prefix})?
  saveInstructions;
  Future<bool> Function({
    required SettingsPromptScope scope,
    required String? text,
    required String workspaceId,
  })?
  saveSystemPrompt;

  bool has(String name) => calls.any((c) => c.startsWith(name));
}

class SettingsHost extends StatefulWidget {
  const SettingsHost({
    super.key,
    required this.data,
    required this.rec,
    this.initialQuery = '',
  });
  final SettingsViewData data;
  final SettingsRecorder rec;
  final String initialQuery;

  @override
  State<SettingsHost> createState() => SettingsHostState();
}

class SettingsHostState extends State<SettingsHost> {
  late var data = widget.data;
  var _n = 0;

  void updateData(SettingsViewData next) => setState(() => data = next);

  @override
  Widget build(BuildContext context) {
    final r = widget.rec;
    void call(String s) => r.calls.add(s);
    return SettingsPage(
      data: data,
      initialQuery: widget.initialQuery,
      actions: SettingsActions(
        onOpenPage: (p) {
          r.pages.add(p);
          setState(() => data = data.copyWith(page: p));
        },
        onChanged: (k, v) {
          r.changes.add((k, v));
          setState(
            () => data = data.copyWith(
              values: data.values.copyWith(k, v),
              lastChange: SettingsChange(
                id: 'c${++_n}',
                title: k.name,
                from: '',
                to: '$v',
                at: data.now,
              ),
            ),
          );
        },
        onReset: (k) => call('reset:${k.name}'),
        onResetPage: (p) => call('resetPage:${p.name}'),
        onUndo: (id) => call('undo:$id'),
        onChannelChanged: (c) {
          r.channel = c;
          setState(
            () => data = data.copyWith(canvas: SettingsCanvasData(channel: c)),
          );
        },
        onShortcutRecorded: (id, keys) => call('record:$id:${keys.join('+')}'),
        onShortcutCleared: (id) => call('clearShortcut:$id'),
        onShortcutReset: (id) => call('resetShortcut:$id'),
        onSaveInstructions:
            ({
              required global,
              required prefix,
              required expectedGlobal,
              required expectedPrefix,
            }) async {
              call('saveInstructions:$global');
              return await r.saveInstructions?.call(
                    global: global,
                    prefix: prefix,
                  ) ??
                  true;
            },
        onSaveSystemPrompt:
            ({
              required scope,
              required text,
              required workspaceId,
              required expectedText,
            }) async {
              call('savePrompt:${scope.name}:${text ?? 'null'}:$workspaceId');
              return await r.saveSystemPrompt?.call(
                    scope: scope,
                    text: text,
                    workspaceId: workspaceId,
                  ) ??
                  r.promptResult;
            },
        onDeleteAccount: (id) => call('deleteAccount:$id'),
        onSwitchAccount: (id) => call('switchAccount:$id'),
        onClearCache: (k) => call('clearCache:${k.name}'),
        onCleanThumbnails: () => call('cleanThumbs'),
        onRagResume: (k) => call('ragResume:${k.name}'),
        onRagPause: (k) => call('ragPause:${k.name}'),
        onRagSourceEnabled: (k, v) => call('ragEnabled:${k.name}:$v'),
        onRagBuild: (k) => call('ragBuild:${k.name}'),
        onRagRebuild: (k) => call('ragRebuild:${k.name}'),
        onRagStartPlan: () => call('ragStartPlan'),
        onRagCancelPlan: () => call('ragCancelPlan'),
        onRagClear: (k) => call('ragClear:${k.name}'),
        onRagInstallRuntime: ({required cuda}) => call('ragInstall:$cuda'),
        onRagCancelInstall: () => call('ragCancelInstall'),
        onRagUsePython: () => call('ragUsePython'),
        onRagDownload: (m) => call('ragDownload:${m.name}'),
        onRagCancelDownload: () => call('ragCancelDownload'),
        onRagDiscoverModels: () => call('ragDiscover'),
        onPickPath: (k) => call('pickPath:${k.name}'),
        onResetScopes: (s) =>
            call('resetScopes:${s.map((e) => e.name).join(',')}'),
        onAddBlacklistTag: (t) => call('addTag:$t'),
        onRemoveBlacklistTag: (t) => call('removeTag:$t'),
        onRestart: () => call('restart'),
        onDeleteProvider: (id) => call('deleteProvider:$id'),
        onTestComfy: () => call('testComfy'),
        onUpscaleInstall: (id) => call('install:$id'),
        onAssign:
            (
              t, {
              providerId,
              modelId,
              presetId,
              reasoningEffort,
              clearReasoningEffort = false,
            }) => call(
              'assign:${t.name}:$providerId:$modelId:$reasoningEffort:$clearReasoningEffort',
            ),
        onCopyDiagnostics: () => call('copyDiagnostics'),
      ),
    );
  }
}
