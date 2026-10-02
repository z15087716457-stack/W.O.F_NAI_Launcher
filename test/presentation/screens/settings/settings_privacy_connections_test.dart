import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:nai_launcher/core/comfyui/builtin_workflows.dart';
import 'package:nai_launcher/core/comfyui/comfyui_models.dart';
import 'package:nai_launcher/core/comfyui/workflow_template.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/danbooru_tags_lazy_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/settings/proxy_settings.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/comfyui/comfyui_provider.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_blacklist_provider.dart';
import 'package:nai_launcher/presentation/providers/proxy_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/integrations_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/privacy_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_protection_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_toggle.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/workflow_import_wizard.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' show MemorySettings;

class _ComfySettings extends ComfyUISettings {
  @override
  ComfyUISettingsState build() => const ComfyUISettingsState(enabled: true);
  @override
  void setEnabled(bool value) => state = state.copyWith(enabled: value);
  @override
  void setServerUrl(String value) => state = state.copyWith(serverUrl: value);
}

class _ComfyConnection extends ComfyUIConnection {
  int tests = 0, disconnects = 0;
  final pending = Completer<bool>();
  @override
  ComfyUIConnectionStatus build() => ComfyUIConnectionStatus.disconnected;
  @override
  Future<bool> testConnection() {
    tests++;
    return pending.future;
  }

  @override
  void disconnect() {
    disconnects++;
    state = ComfyUIConnectionStatus.disconnected;
  }
}

class _Workflows extends ComfyUIWorkflows {
  int deletes = 0;
  @override
  List<WorkflowTemplate> build() => BuiltinWorkflows.all;
  void addFixture() => state = [
    ...state,
    const WorkflowTemplate(
      id: 'fixture',
      name: '自定义示例',
      description: '离线测试',
      slots: [],
      workflowJson: {},
    ),
  ];
  @override
  Future<void> removeCustomTemplate(String id) async {
    deletes++;
    state = state.where((w) => w.id != id).toList();
  }
}

class _Krita extends KritaBridgeNotifier {
  _Krita({bool starting = false}) {
    state = KritaBridgeState(
      enabled: true,
      status: starting
          ? KritaBridgeStatus.starting
          : KritaBridgeStatus.listening,
      port: 3571,
      discoveryFilePath:
          r'C:\Users\PieDriver\AppData\Roaming\nai-launcher\krita-bridge.json',
    );
  }
  int regenerations = 0;
  @override
  Future<void> regenerateSession() async {
    regenerations++;
  }

  @override
  Future<void> setEnabled(bool value) async => state = state.copyWith(
    enabled: value,
    status: value ? KritaBridgeStatus.listening : KritaBridgeStatus.disabled,
  );
}

class _Blacklist extends OnlineGalleryBlacklistNotifier {
  _Blacklist(super.ref, super.storage);
  int syncs = 0;
  final pending = Completer<void>();
  @override
  Future<void> syncNow({bool triggeredByStartup = false}) async {
    syncs++;
    state = state.copyWith(isSyncing: true);
    await pending.future;
    if (mounted) {
      state = state.copyWith(isSyncing: false, clearLastSyncError: true);
    }
  }
}

void main() {
  final capture = GlobalKey();
  final capturing = Platform.environment['CAPTURE_SETTINGS_CONNECTIONS'] == '1';
  final dark = Platform.environment['STUDIO_APPEARANCE'] == 'dark';
  late MemorySettings storage;
  late _ComfyConnection comfy;
  late _Workflows workflows;
  late _Krita krita;
  late _Blacklist blacklist;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  setUpAll(() async {
    if (!capturing) return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    int? tab,
    Size size = const Size(1040, 900),
    double scale = 1,
    bool starting = false,
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    storage = MemorySettings()
      ..values[StorageKeys.settingsFontScale] = scale
      ..values[StorageKeys.proxyEnabled] = true
      ..values[StorageKeys.proxyMode] = 'auto'
      ..values[StorageKeys.onlineGalleryBlacklistLastSyncError] =
          '请先登录 Danbooru 账号';
    comfy = _ComfyConnection();
    workflows = _Workflows();
    krita = _Krita(starting: starting);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          zhDictionaryServiceProvider.overrideWith(
            (ref) => ZhDictionaryService(),
          ),
          localStorageServiceProvider.overrideWithValue(storage),
          comfyUISettingsProvider.overrideWith(_ComfySettings.new),
          comfyUIConnectionProvider.overrideWith(() => comfy),
          comfyUIWorkflowsProvider.overrideWith(() => workflows),
          kritaBridgeNotifierProvider.overrideWith((ref) => krita),
          detectedSystemProxyProvider.overrideWith((ref) => null),
          onlineGalleryBlacklistNotifierProvider.overrideWith(
            (ref) => blacklist = _Blacklist(ref, storage),
          ),
          danbooruTagsLazyServiceProvider.overrideWith(
            (ref) => Completer<DanbooruTagsLazyService>().future,
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: settingsUiTheme(
            AppTheme.getTheme(
              AppStyle.geist,
              dark ? Brightness.dark : Brightness.light,
              fontConfig: FontConfig.defaultFont,
            ),
          ),
          builder: (context, child) => SettingsTypographyScope(
            child: RepaintBoundary(key: capture, child: child!),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tab == null ? '隐私与分享' : '连接与集成',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tab == null ? '控制分享信息与需要确认的操作。' : '管理外部工具、桥接连接与网络设置。',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 26),
                    if (tab == null)
                      const PrivacySettingsSection()
                    else
                      IntegrationsSettingsSection(initialTab: tab),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!capturing) return;
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory(
        '.dart_tool/settings-privacy-connections-captures',
      )..createSync(recursive: true);
      File(
        '${folder.path}/$name-${dark ? 'dark' : 'light'}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final spec in [
    (const Size(1040, 900), 1.0, 'wide'),
    (const Size(440, 900), 1.3, 'narrow'),
    (const Size(1120, 1000), 1.5, 'large'),
  ]) {
    for (final tab in <int?>[null, 0, 1, 2]) {
      testWidgets(
        '${tab == null ? "privacy" : "connection-$tab"} fits ${spec.$3}',
        (tester) async {
          await pump(tester, tab: tab, size: spec.$1, scale: spec.$2);
          if (tab == null) {
            final a = tester.getRect(
              find.byKey(const Key('privacy-strip-metadata')),
            );
            final b = tester.getRect(
              find.byKey(const Key('privacy-external-send')),
            );
            final c = tester.getRect(
              find.byKey(const Key('privacy-dangerous-actions')),
            );
            if (spec.$3 == 'wide') {
              expect(a.top, b.top);
              expect(a.bottom, b.bottom);
              expect(c.top, a.bottom);
              expect(b.left, greaterThan(a.right));
            } else {
              expect(b.top, greaterThanOrEqualTo(a.bottom));
            }
            expect(find.byType(SettingsProtectionTile), findsNWidgets(4));
            expect(find.text('立即同步'), findsOneWidget);
          } else {
            expect(find.text('ComfyUI'), findsOneWidget);
            expect(find.text('Krita'), findsOneWidget);
            expect(find.text('网络'), findsOneWidget);
            if (tab == 0) {
              expect(find.text('SeedVR2 超分'), findsOneWidget);
              expect(find.text('SeedVR2 分块超分'), findsOneWidget);
              expect(find.text('内置'), findsNWidgets(4));
              if (spec.$3 == 'wide') {
                final input = tester.getRect(
                  find.byKey(const Key('settings-comfyui-address')),
                );
                final test = tester.getRect(
                  find.byKey(const Key('settings-comfyui-test')),
                );
                expect(input.center.dy, closeTo(test.center.dy, 1));
              }
            }
          }
          expect(tester.takeException(), isNull);
          await snap(
            tester,
            '${tab == null ? "privacy-C" : "connection-A-$tab"}-${spec.$3}',
          );
        },
      );
    }
  }

  testWidgets('protection controls change only their own saved preference', (
    tester,
  ) async {
    final container = await pump(tester);
    for (final key in [
      'privacy-strip-metadata',
      'privacy-external-send',
      'privacy-dangerous-actions',
      'privacy-prevent-overwrite',
    ]) {
      final tile = find.byKey(Key(key));
      final before = tester.widget<SettingsProtectionTile>(tile).value;
      await tester.tap(
        find.descendant(of: tile, matching: find.byType(SettingsToggle)),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsProtectionTile>(tile).value, !before);
    }
    final settings = container.read(shareImageSettingsProvider);
    expect(settings.stripMetadataForCopyAndDrag, isTrue);
    expect(settings.warnExternalImageSend, isFalse);
    expect(settings.confirmDangerousActions, isFalse);
    expect(settings.preventOverwrite, isFalse);
    expect(settings.warnHighAnlasCost, isTrue);
  });

  testWidgets(
    'blacklist add, remove, auto sync and manual sync remain usable',
    (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextField).first, 'sample_tag');
      await tester.tap(find.widgetWithText(FilledButton, '添加'));
      await tester.pumpAndSettle();
      expect(blacklist.state.localTags, {'sample_tag'});
      expect(find.text('暂无本地黑名单标签'), findsNothing);
      tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
      await tester.pumpAndSettle();
      expect(blacklist.state.localTags, isEmpty);
      await tester.ensureVisible(find.text('启动时自动同步'));
      await tester.tap(find.text('启动时自动同步'));
      await tester.pumpAndSettle();
      expect(blacklist.state.autoSyncOnStartup, isFalse);
      final sync = find.widgetWithText(OutlinedButton, '立即同步');
      await tester.ensureVisible(sync);
      await tester.tap(sync);
      await tester.pump();
      expect(blacklist.syncs, 1);
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNull);
      blacklist.pending.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(sync).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ComfyUI address, busy test, import and custom deletion use existing actions',
    (tester) async {
      final container = await pump(tester, tab: 0);
      await tester.enterText(
        find.byType(TextField).first,
        'http://127.0.0.1:9000',
      );
      expect(
        container.read(comfyUISettingsProvider).serverUrl,
        'http://127.0.0.1:9000',
      );
      final test = find.byKey(const Key('settings-comfyui-test'));
      await tester.tap(test);
      await tester.pump();
      expect(comfy.tests, 1);
      expect(tester.widget<OutlinedButton>(test).onPressed, isNull);
      await snap(tester, 'connection-A-testing');
      comfy.pending.complete(true);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(test).onPressed, isNotNull);
      await tester.tap(find.text('导入'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkflowImportWizard), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      workflows.addFixture();
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('settings-workflow-fixture'));
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(workflows.deletes, 0);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      expect(workflows.deletes, 1);
      expect(find.text('自定义示例'), findsNothing);
      await tester.ensureVisible(find.byType(SettingsToggle));
      await tester.tap(find.byType(SettingsToggle));
      await tester.pumpAndSettle();
      expect(container.read(comfyUISettingsProvider).enabled, isFalse);
      expect(comfy.disconnects, 1);
      expect(find.text('工作流管理'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Krita regeneration is available while listening and disabled while starting',
    (tester) async {
      await pump(tester, tab: 1);
      await tester.tap(find.byKey(const Key('settings-krita-regenerate')));
      await tester.pumpAndSettle();
      expect(krita.regenerations, 1);
      await pump(tester, tab: 1, starting: true);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('settings-krita-regenerate')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'proxy auto and manual modes preserve inputs and traffic disclosure',
    (tester) async {
      final container = await pump(tester, tab: 2);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const Key('settings-proxy-test')));
      await tester.pumpAndSettle();
      expect(find.textContaining('未检测到系统代理'), findsWidgets);
      await tester.tap(find.text('手动'));
      await tester.pumpAndSettle();
      expect(
        container.read(proxySettingsNotifierProvider).mode,
        ProxyMode.manual,
      );
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, '127.0.0.1');
      await tester.enterText(find.byType(TextField).last, '7890');
      await tester.pumpAndSettle();
      expect(
        container.read(proxySettingsNotifierProvider).effectiveProxyAddress,
        '127.0.0.1:7890',
      );
      expect(find.textContaining('认证请求'), findsOneWidget);
      await snap(tester, 'connection-A-proxy-manual');
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in [const Locale('en'), const Locale('ja')]) {
    testWidgets(
      'privacy and connections retain narrow ${locale.languageCode} controls',
      (tester) async {
        await pump(
          tester,
          size: const Size(440, 900),
          scale: 1.3,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        await pump(
          tester,
          tab: 2,
          size: const Size(440, 900),
          scale: 1.3,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
