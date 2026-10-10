// 新界面预览：不接后端，用假数据驱动，能切状态 / 主题 / 语言 / 时间范围。
// 运行：flutter run -d windows -t tool/ui_shell/preview_main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_contract.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_fixture.dart';
import 'package:nai_launcher/presentation/ui/statistics/statistics_page.dart';

void main() => runApp(const _PreviewApp());

enum _Scene { ready, loading, empty, error, updating, failed, artistsPending }

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  var _scene = _Scene.ready;
  var _dark = false;
  var _locale = const Locale('zh');
  var _range = StatsRange.all;
  var _naiOnly = false;
  var _refreshing = false;
  String? _lastAction;

  StatsViewData get _data => StatsFixture.view(
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

  void _log(String s) => setState(() => _lastAction = s);

  StatsActions get _actions => StatsActions(
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
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<_Scene>(
                      value: _scene,
                      items: [
                        for (final s in _Scene.values)
                          DropdownMenuItem(value: s, child: Text(s.name)),
                      ],
                      onChanged: (s) => setState(() => _scene = s!),
                    ),
                    DropdownButton<Locale>(
                      value: _locale,
                      items: [
                        for (final l in AppLocalizations.supportedLocales)
                          DropdownMenuItem(value: l, child: Text('$l')),
                      ],
                      onChanged: (l) => setState(() => _locale = l!),
                    ),
                    FilterChip(
                      label: const Text('dark'),
                      selected: _dark,
                      onSelected: (v) => setState(() => _dark = v),
                    ),
                    if (_lastAction != null)
                      Text(_lastAction!, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StatisticsPage(data: _data, actions: _actions),
            ),
          ],
        ),
      ),
    );
  }
}
