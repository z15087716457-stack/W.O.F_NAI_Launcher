import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/danbooru_tags_lazy_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_blacklist_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/appearance_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/shortcut_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/shortcut_settings_panel.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/online_gallery/blacklist_settings_panel.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' show MemorySettings;
import 'settings_round_widgets_test.dart' show MemoryShortcuts;

class _Settings extends MemorySettings {
  @override
  String getLocaleCode() => values[StorageKeys.locale] as String? ?? 'zh';
  @override
  Future<void> deleteSetting(String key) async => values.remove(key);
}

class _Blacklist extends OnlineGalleryBlacklistNotifier {
  _Blacklist(super.ref, super.storage);
  @override
  Future<void> syncNow({bool triggeredByStartup = false}) async {}
  void showStatus(OnlineGalleryBlacklistState value) => state = value;
}

class _SoundPicker extends FilePicker {
  FilePickerResult? result;
  int calls = 0;
  List<String>? extensions;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    extensions = allowedExtensions;
    return result;
  }
}

void main() {
  final capture = GlobalKey();
  final capturing = Platform.environment['CAPTURE_SETTINGS_SIDE_GROUPS'] == '1';
  final dark = Platform.environment['STUDIO_APPEARANCE'] == 'dark';
  late _Settings storage;
  late _Blacklist blacklist;
  final played = <String?>[];
  Completer<bool>? pendingSound;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    played.clear();
    pendingSound = null;
  });
  setUpAll(() async {
    if (!capturing) return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String page = 'appearance',
    Size size = const Size(1280, 960),
    double scale = 1,
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    storage = _Settings()
      ..values[StorageKeys.settingsFontScale] = scale
      ..values[StorageKeys.studioThemeMode] = dark ? 'dark' : 'light'
      ..values[StorageKeys.locale] = locale.languageCode
      ..values[StorageKeys.historyClickBehavior] = 'select_preview'
      ..values[StorageKeys.onlineGalleryBlacklistLastSyncError] =
          '请先登录 Danbooru 账号';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          shortcutStorageProvider.overrideWithValue(MemoryShortcuts()),
          danbooruTagsLazyServiceProvider.overrideWith(
            (ref) => Completer<DanbooruTagsLazyService>().future,
          ),
          onlineGalleryBlacklistNotifierProvider.overrideWith(
            (ref) => blacklist = _Blacklist(ref, storage),
          ),
          allFontsProvider.overrideWith(
            (ref) async => {
              '应用默认': [FontConfig.defaultFont],
              '内置字体': [bundledPresets.first],
            },
          ),
          notificationSoundPreviewProvider.overrideWithValue((path) {
            played.add(path);
            return pendingSound?.future ?? Future.value(true);
          }),
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          page == 'appearance'
                              ? '常规与外观'
                              : page == 'controls'
                              ? '操作与快捷键'
                              : '在线画廊黑名单',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page == 'appearance'
                              ? '让工作台符合你的阅读与使用习惯。'
                              : page == 'controls'
                              ? '设置交互方式、画布操作和键盘快捷键。'
                              : '控制在线画廊中隐藏的标签。',
                        ),
                        const SizedBox(height: 30),
                        if (page == 'appearance')
                          const AppearanceSettingsSection(),
                        if (page == 'controls') ...[
                          const AppearanceSettingsSection(controlsOnly: true),
                          const ShortcutSettingsSection(),
                        ],
                        if (page == 'blacklist')
                          const OnlineGalleryBlacklistSettingsPanel(flat: true),
                      ],
                    ),
                  ),
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
      final pixels =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
      final path = File(
        '.dart_tool/settings-side-groups-captures/$name-${dark ? 'dark' : 'light'}.png',
      );
      path.parent.createSync(recursive: true);
      path.writeAsBytesSync(bytes!.buffer.asUint8List());
      pixels.dispose();
    });
  }

  for (final spec in [
    (const Size(1280, 960), 1.0, 'wide'),
    (const Size(400, 900), 1.3, 'narrow'),
    (const Size(1120, 1000), 1.5, 'large'),
  ]) {
    for (final page in ['appearance', 'controls', 'blacklist']) {
      testWidgets('$page side groups and geometry: ${spec.$3}', (tester) async {
        await pump(tester, page: page, size: spec.$1, scale: spec.$2);
        if (page != 'blacklist') {
          final group = tester.getRect(
            find.text(page == 'appearance' ? '文字与语言' : '浏览方式'),
          );
          final field = tester.getRect(
            find.text(page == 'appearance' ? '字体' : '历史记录点击行为'),
          );
          if (spec.$3 == 'wide') {
            expect(field.left, greaterThan(group.right));
            final row = tester.getRect(
              find.widgetWithText(
                SettingsTile,
                page == 'appearance' ? '字体' : '历史记录点击行为',
              ),
            );
            expect(group.top, greaterThanOrEqualTo(row.top));
            expect(group.bottom, lessThanOrEqualTo(row.bottom));
          } else {
            expect(field.top, greaterThan(group.bottom));
          }
          if (page == 'appearance') {
            expect(
              find.byKey(const ValueKey('studio_theme_light')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('studio_theme_dark')),
              findsOneWidget,
            );
            expect(find.text('仅调整设置页面与设置弹窗的字号'), findsOneWidget);
            expect(find.text('完成提醒'), findsNothing);
          } else {
            expect(find.textContaining('自动选中与跳转不受影响'), findsOneWidget);
            expect(
              find.byKey(const Key('settings-manage-shortcuts')),
              findsOneWidget,
            );
          }
        } else {
          final row = find.byKey(const Key('blacklist-startup-sync'));
          final rowRect = tester.getRect(row);
          final subtitle = tester.getRect(find.text('默认开启，可随时关闭'));
          final status = tester.getRect(
            find.byKey(const Key('blacklist-sync-status')),
          );
          final title = tester.getRect(find.text('启动时自动同步'));
          final toggle = tester.getRect(
            find.descendant(of: row, matching: find.byType(SettingsToggle)),
          );
          expect(rowRect.bottom - subtitle.bottom, greaterThanOrEqualTo(15));
          expect(status.top - rowRect.bottom, greaterThanOrEqualTo(12));
          expect(
            toggle.center.dy,
            closeTo((title.top + subtitle.bottom) / 2, 1),
          );
          expect(
            rowRect.top - tester.getRect(find.text('暂无本地黑名单标签')).bottom,
            greaterThanOrEqualTo(36),
          );
        }
        expect(tester.takeException(), isNull);
        await snap(tester, '$page-${spec.$3}');
        if (page != 'blacklist' && spec.$3 != 'wide') {
          await tester.ensureVisible(
            find.byKey(
              Key(
                page == 'appearance'
                    ? 'settings-preview-notification'
                    : 'settings-manage-shortcuts',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await snap(tester, '$page-${spec.$3}-bottom');
        }
      });
    }
  }

  testWidgets('inline themes save the actual selection', (tester) async {
    final container = await pump(tester);
    final target = dark ? Brightness.light : Brightness.dark;
    await tester.tap(find.byKey(ValueKey('studio_theme_${target.name}')));
    await tester.pumpAndSettle();
    expect(container.read(themeNotifierProvider), target);
    expect(storage.values[StorageKeys.studioThemeMode], target.name);
    expect(storage.values[StorageKeys.fontFamily], isNull);
  });

  testWidgets(
    'font and language buttons retain existing choice and save dialogs',
    (tester) async {
      final container = await pump(tester);
      await tester.tap(find.text('字体'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(bundledPresets.first.displayName));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-font-apply')));
      await tester.pumpAndSettle();
      expect(storage.values[StorageKeys.fontFamily], bundledPresets.first.key);
      await tester.tap(find.text('语言'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(of: find.byType(Dialog), matching: find.text('English'))
            .first,
      );
      await tester.pumpAndSettle();
      expect(container.read(localeNotifierProvider).languageCode, 'en');
      expect(storage.values[StorageKeys.locale], 'en');
    },
  );

  testWidgets('controls values keep dialog switching and shortcut entry', (
    tester,
  ) async {
    final container = await pump(tester, page: 'controls');
    await tester.tap(find.text('输出查看器'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('简单视图')),
    );
    await tester.pumpAndSettle();
    expect(container.read(simpleOutputViewerNotifierProvider), isTrue);
    expect(storage.values[StorageKeys.simpleOutputViewer], isTrue);
    await tester.tap(find.text('历史记录点击行为'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('经典')),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(historyClickBehaviorNotifierProvider),
      HistoryClickBehavior.openDetail,
    );
    await tester.tap(find.text('锁定画布相机'));
    await tester.pumpAndSettle();
    expect(storage.values[StorageKeys.canvasLockCamera], isTrue);
    await tester.tap(find.byKey(const Key('settings-manage-shortcuts')));
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutSettingsPanel), findsOneWidget);
    await snap(tester, 'shortcut-entry');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutSettingsPanel), findsNothing);
  });

  testWidgets('explicit sound picker cancels, chooses and restores default', (
    tester,
  ) async {
    FilePicker? original;
    try {
      original = FilePicker.platform;
    } catch (_) {}
    final picker = _SoundPicker();
    FilePicker.platform = picker;
    addTearDown(() {
      if (original != null) FilePicker.platform = original;
    });
    final container = await pump(tester);
    final choose = find.byKey(const Key('settings-select-sound'));
    await tester.ensureVisible(choose);
    await tester.tap(choose);
    await tester.pumpAndSettle();
    expect(picker.calls, 1);
    expect(picker.extensions, ['mp3', 'wav', 'ogg', 'm4a']);
    expect(
      container.read(notificationSettingsNotifierProvider).customSoundPath,
      isNull,
    );
    picker.result = FilePickerResult([
      PlatformFile(name: 'fixture.wav', path: 'C:/fixture.wav', size: 1),
    ]);
    await tester.tap(choose);
    await tester.pumpAndSettle();
    expect(
      container.read(notificationSettingsNotifierProvider).customSoundPath,
      'C:/fixture.wav',
    );
    expect(find.text('fixture.wav'), findsOneWidget);
    final context = tester.element(find.byType(AppearanceSettingsSection));
    await tester.tap(
      find.byTooltip(
        AppLocalizations.of(context)!.settings_notificationResetSound,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(notificationSettingsNotifierProvider).customSoundPath,
      isNull,
    );
    expect(storage.values[StorageKeys.notificationCustomSoundPath], isNull);
  });

  testWidgets(
    'sound and motion save independently; preview guards busy state',
    (tester) async {
      final container = await pump(tester);
      await tester.ensureVisible(find.text('完成音效'));
      await tester.tap(find.text('完成音效'));
      await tester.pumpAndSettle();
      expect(storage.values[StorageKeys.notificationSoundEnabled], isFalse);
      await tester.tap(find.text('减少画布动效'));
      await tester.pumpAndSettle();
      expect(storage.values[StorageKeys.canvasReducedMotion], isTrue);
      expect(
        container.read(notificationSettingsNotifierProvider).soundEnabled,
        isFalse,
      );
      pendingSound = Completer<bool>();
      final play = find.byKey(const Key('settings-preview-sound'));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(play).onPressed, isNull);
      await snap(tester, 'sound-preview-busy');
      expect(played, [null]);
      pendingSound!.complete(true);
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(play).onPressed, isNotNull);
      final notice = find.byKey(const Key('settings-preview-notification'));
      await tester.ensureVisible(notice);
      await tester.tap(notice);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('通知会显示在右上角'), findsOneWidget);
      await snap(tester, 'notification-preview');
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets(
    'blacklist footer shows success, never synced and saved startup toggle',
    (tester) async {
      await pump(tester, page: 'blacklist');
      await tester.tap(find.text('启动时自动同步'));
      await tester.pumpAndSettle();
      expect(
        storage.values[StorageKeys.onlineGalleryBlacklistAutoSync],
        isFalse,
      );
      blacklist.showStatus(const OnlineGalleryBlacklistState());
      await tester.pumpAndSettle();
      expect(find.textContaining('上次同步失败'), findsNothing);
      await snap(tester, 'blacklist-never-synced');
      blacklist.showStatus(
        OnlineGalleryBlacklistState(
          lastSyncAt: DateTime(2026, 10, 3, 12, 30),
          localTags: const {'test_tag'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-10-03 12:30'), findsOneWidget);
      await snap(tester, 'blacklist-success-tags');
    },
  );

  for (final locale in const [
    Locale('en'),
    Locale('ja'),
    Locale('zh', 'TW'),
    Locale('ko'),
  ]) {
    testWidgets('both grouped pages fit narrow $locale', (tester) async {
      for (final page in ['appearance', 'controls']) {
        await pump(
          tester,
          page: page,
          size: const Size(400, 900),
          scale: 1.3,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        await snap(tester, '$page-${locale.toLanguageTag()}-narrow');
      }
    });
  }
}
