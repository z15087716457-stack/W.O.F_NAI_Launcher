import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/update_check_service.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/repositories/gallery_folder_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/tag_index_import_provider.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/settings_screen.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_path_tile.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_toggle.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/update_check_dialog.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/app_logger_test_isolation.dart';
import 'model_management_section_test.dart' show MemorySettings;

class _Settings extends MemorySettings {
  @override
  String getLocaleCode() => values[StorageKeys.locale] as String? ?? 'zh';
  @override
  Future<void> deleteSetting(String key) async => values.remove(key);
}

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
}

class _Picker extends FilePicker {
  String? directory, save;
  FilePickerResult? files;
  int directoryCalls = 0;
  List<String>? extensions;
  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    directoryCalls++;
    return directory;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async => save;
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
    extensions = allowedExtensions;
    return files;
  }
}

class _Service extends Mock implements UpdateCheckService {}

class _Updates extends UpdateStateNotifier {
  _Updates(this.storage, this.service);
  final _Settings storage;
  final _Service service;
  bool prerelease = false;
  int checks = 0;
  bool? manual;
  @override
  UpdateState build() => const UpdateState();
  @override
  Future<void> checkForUpdates({bool manual = false}) async {
    checks++;
    this.manual = manual;
    state = const UpdateState(status: UpdateStatus.upToDate);
  }

  @override
  Future<void> setIncludePrerelease(bool value) async {
    prerelease = value;
    storage.values[StorageKeys.includePrereleaseUpdates] = value;
  }

  void show(UpdateState value) => state = value;
}

class _Import extends TagIndexImportNotifier {
  _Import(super.ref);
  void showProgress() => state = const TagIndexImportState(
    isImporting: true,
    processedLines: 2,
    totalLines: 5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final capturing =
      Platform.environment['CAPTURE_GALLERY_ABOUT_NAVIGATION'] == '1';
  final dark = Platform.environment['STUDIO_APPEARANCE'] == 'dark';
  final capture = GlobalKey();
  late Directory temp;
  late _Settings storage;
  late _Picker picker;
  late _Service service;
  late _Updates updates;
  late _Import importer;
  late FilePicker originalPicker;
  final launched = <String>[];
  const urlChannels = [
    'plugins.flutter.io/url_launcher',
    'plugins.flutter.io/url_launcher_windows',
  ];
  const savePath = r'E:\Illustration\NovelAI\图库与文件\长路径示例\临时存储堆';
  const vibePath = r'E:\Illustration\NovelAI\Vibe 素材库\风格与参考素材';

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('gallery_about_navigation_');
    PathProviderPlatform.instance = _Paths(temp.path);
    Hive.init('${temp.path}/hive');
    await Hive.openBox(StorageKeys.settingsBox);
    AppLoggerTestIsolation.setUp();
    await AppLogger.initialize(
      isTestEnvironment: true,
      enableFileLogging: false,
    );
    PackageInfo.setMockInitialValues(
      appName: 'W.O.F NAI Studio',
      packageName: 'nai_launcher',
      version: '1.1.1',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppVersion.initialize();
    if (capturing) {
      await loadStudioCaptureFonts();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
    try {
      originalPicker = FilePicker.platform;
    } catch (_) {
      originalPicker = _Picker();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    await Hive.box(StorageKeys.settingsBox).clear();
    VibeLibraryPathHelper.instance.clearCache();
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.vibeLibrarySavePath, vibePath);
    storage = _Settings()
      ..values[StorageKeys.settingsFontScale] = 1.0
      ..values[StorageKeys.studioThemeMode] = dark ? 'dark' : 'light'
      ..values[StorageKeys.imageSavePath] = savePath
      ..values[StorageKeys.autoSaveImages] = false;
    picker = _Picker();
    FilePicker.platform = picker;
    service = _Service();
    updates = _Updates(storage, service);
    when(() => service.getLastCheckTime()).thenAnswer(
      (_) async => DateTime.now().subtract(const Duration(hours: 22)),
    );
    when(
      () => service.shouldIncludePrerelease(),
    ).thenAnswer((_) => updates.prerelease);
    launched.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in urlChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        if (call.method == 'canLaunch') return true;
        if (call.method == 'launch' || call.method == 'launchUrl') {
          launched.add((call.arguments as Map)['url'] as String);
          return true;
        }
        return true;
      });
    }
  });
  tearDown(() async {
    FilePicker.platform = originalPicker;
    for (final name in urlChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), null);
    }
    await AppLogger.setFileLoggingEnabled(false);
  });
  tearDownAll(() async {
    await AppLoggerTestIsolation.tearDown();
    VibeLibraryPathHelper.instance.clearCache();
    await Hive.close();
    assert(temp.absolute.path.startsWith(Directory.systemTemp.absolute.path));
    assert(temp.path.contains('gallery_about_navigation_'));
    await temp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    int page = 9,
    Size size = const Size(1280, 960),
    double scale = 1,
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    storage.values[StorageKeys.settingsFontScale] = scale;
    storage.values[StorageKeys.locale] = locale.languageCode;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          updateCheckServiceReadyProvider.overrideWith((ref) async => service),
          updateStateProvider.overrideWith(() => updates),
          tagIndexImportProvider.overrideWith((ref) => importer = _Import(ref)),
        ],
        child: MaterialApp(
          theme: AppTheme.getTheme(
            AppStyle.geist,
            dark ? Brightness.dark : Brightness.light,
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              RepaintBoundary(key: capture, child: child),
          home: SettingsScreen(initialSectionIndex: page),
        ),
      ),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    return ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
  }

  Finder within(String parent, String child) => find.descendant(
    of: find.byKey(Key(parent)),
    matching: find.byKey(Key(child)),
  );
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.runAsync(() => tester.tap(finder));
    await settle(tester);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (!capturing) return;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pixels = await boundary.toImage();
      final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
      final file = File(
        '.dart_tool/gallery-about-navigation-captures/$name-${dark ? 'dark' : 'light'}.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      pixels.dispose();
    });
  }

  for (final page in [3, 9]) {
    for (final layout in [
      ('wide', const Size(1440, 1100), 1.0),
      ('narrow', const Size(400, 900), 1.3),
      ('large', const Size(1120, 1000), 1.5),
    ]) {
      testWidgets(
        '${page == 3 ? 'gallery' : 'about'} remains usable at ${layout.$1}',
        (tester) async {
          await pump(tester, page: page, size: layout.$2, scale: layout.$3);
          await shot(tester, '${page == 3 ? 'gallery' : 'about'}-${layout.$1}');
          final end = page == 3
              ? find.text('导入标签索引…')
              : find.byKey(const Key('about-open-project'));
          await tester.ensureVisible(end);
          await settle(tester);
          expect(tester.takeException(), isNull);
          await shot(
            tester,
            '${page == 3 ? 'gallery' : 'about'}-${layout.$1}-bottom',
          );
          if (page == 3) {
            expect(find.byType(SettingsPathTile), findsNWidgets(2));
            expect(find.text(savePath), findsOneWidget);
            expect(find.text(vibePath), findsOneWidget);
          }
        },
      );
    }
  }

  testWidgets(
    'C navigation has ten text-only entries and search at the upper left',
    (tester) async {
      await pump(tester, size: const Size(1440, 1100));
      final sidebar = tester.getRect(
        find.byKey(const Key('settings-sidebar-surface')),
      );
      final search = tester.getRect(
        find.byKey(const Key('settings-open-search')),
      );
      expect(search.left, greaterThan(sidebar.left));
      expect(search.right, lessThan(sidebar.right));
      expect(
        search.bottom,
        lessThan(
          tester
              .getRect(find.byKey(const ValueKey('settings-nav-appearance')))
              .top,
        ),
      );
      for (final destination in SettingsDestination.values) {
        final row = find.byKey(ValueKey('settings-nav-${destination.name}'));
        expect(row, findsOneWidget);
        expect(
          find.descendant(of: row, matching: find.byType(Icon)),
          findsNothing,
        );
      }
      expect(
        find.byKey(const Key('settings-nav-selection-line')),
        findsOneWidget,
      );
      await shot(tester, 'sidebar-c');
      await tap(tester, find.byKey(const Key('settings-open-search')));
      await tester.enterText(
        find.byKey(const Key('settings-search-input')),
        'Vibe',
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Vibe库路径').last);
      expect(find.byType(SettingsPathTile), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await shot(tester, 'search-gallery-target');
    },
  );

  testWidgets(
    'search remains available with keyboard and compact category navigation',
    (tester) async {
      await pump(tester, size: const Size(400, 900), scale: 1.3);
      expect(find.byKey(const Key('settings-sidebar-surface')), findsNothing);
      expect(
        find.byType(DropdownButtonFormField<SettingsDestination>),
        findsOneWidget,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-search-input')), findsOneWidget);
      await shot(tester, 'search-compact');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save folder cancel, selection, open and reset use the original settings',
    (tester) async {
      final container = await pump(tester, page: 3);
      final change = within('image-save-path-setting', 'settings-path-change');
      await tap(tester, change);
      expect(storage.values[StorageKeys.imageSavePath], savePath);
      picker.directory = '${temp.path}/chosen-images';
      await tap(tester, change);
      expect(storage.values[StorageKeys.imageSavePath], picker.directory);
      expect(
        container.read(imageSaveSettingsNotifierProvider).customPath,
        picker.directory,
      );
      await tap(
        tester,
        within('image-save-path-setting', 'settings-path-open'),
      );
      expect(launched.single, Uri.directory(picker.directory!).toString());
      await tap(
        tester,
        within('image-save-path-setting', 'settings-path-reset'),
      );
      expect(
        container.read(imageSaveSettingsNotifierProvider).hasCustomPath,
        false,
      );
      expect(storage.values[StorageKeys.autoSaveImages], false);
      await shot(tester, 'gallery-default-save');
    },
  );

  testWidgets(
    'Vibe path changes and resets without changing the image save path',
    (tester) async {
      await pump(tester, page: 3);
      picker.directory = '${temp.path}/chosen-vibes';
      await tap(
        tester,
        within('vibe-library-path-setting', 'settings-path-change'),
      );
      expect(VibeLibraryPathHelper.instance.getCustomPath(), picker.directory);
      expect(
        await tester.runAsync(() => Directory(picker.directory!).exists()),
        true,
      );
      await tap(
        tester,
        within('vibe-library-path-setting', 'settings-path-open'),
      );
      expect(launched.single, Uri.directory(picker.directory!).toString());
      await tap(
        tester,
        within('vibe-library-path-setting', 'settings-path-reset'),
      );
      expect(VibeLibraryPathHelper.instance.hasCustomPath, false);
      final defaultPath = await tester.runAsync(
        () => VibeLibraryPathHelper.instance.getPath(),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SettingsPathTile>(
              find.byKey(const Key('vibe-library-path-setting')),
            )
            .path,
        defaultPath,
      );
      expect(storage.values[StorageKeys.imageSavePath], savePath);
      await shot(tester, 'gallery-default-vibe');
    },
  );

  testWidgets('auto save and thumbnail quality still persist independently', (
    tester,
  ) async {
    await pump(tester, page: 3);
    await tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('gallery-auto-save-setting')),
        matching: find.byType(SettingsToggle),
      ),
    );
    expect(storage.values[StorageKeys.autoSaveImages], true);
    await tap(tester, find.text('标清'));
    expect(
      (await SharedPreferences.getInstance()).getString(
        StorageKeys.localGalleryThumbnailQuality,
      ),
      'sd',
    );
    expect(storage.values[StorageKeys.autoSaveImages], true);
    expect(storage.values[StorageKeys.imageSavePath], savePath);
  });

  testWidgets(
    'source removal confirms and only removes the source association',
    (tester) async {
      final folder = (await tester.runAsync(
        () => Directory('${temp.path}/source-with-original').create(),
      ))!;
      final original = (await tester.runAsync(
        () => File(
          '${folder.path}/original.png',
        ).writeAsString('original fixture'),
      ))!;
      await tester.runAsync(
        () => GalleryFolderRepository.instance.setExtraRootPaths([folder.path]),
      );
      await pump(tester, page: 3);
      await tap(tester, find.text('移除该图库源'));
      await tap(tester, find.text('取消').last);
      expect(await GalleryFolderRepository.instance.getExtraRootPaths(), [
        p.normalize(folder.path),
      ]);
      await tap(tester, find.text('移除该图库源'));
      await tap(tester, find.text('确定').last);
      expect(
        await GalleryFolderRepository.instance.getExtraRootPaths(),
        isEmpty,
      );
      expect(
        await tester.runAsync(() => original.readAsString()),
        'original fixture',
      );
      await shot(tester, 'gallery-no-sources');
    },
  );

  testWidgets(
    'cancelled add/import are inert and importing disables only the import action',
    (tester) async {
      await pump(tester, page: 3);
      await tap(tester, find.text('添加文件夹'));
      await tap(tester, find.text('导入标签索引…'));
      expect(picker.extensions, ['jsonl']);
      expect(
        await GalleryFolderRepository.instance.getExtraRootPaths(),
        isEmpty,
      );
      importer.showProgress();
      await tester.pump();
      final button = tester.widget<OutlinedButton>(
        find
            .ancestor(
              of: find.text('导入标签索引…'),
              matching: find.byType(OutlinedButton),
            )
            .first,
      );
      expect(button.onPressed, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await shot(tester, 'gallery-importing');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'about groups have consistent action edges and explicit restoration controls',
    (tester) async {
      await pump(tester, size: const Size(1440, 1100));
      final update = tester.getRect(
        find.byKey(const Key('about-version-group')),
      );
      final prefs = tester.getRect(
        find.byKey(const Key('about-preferences-group')),
      );
      final diagnostics = tester.getRect(
        find.byKey(const Key('about-diagnostics-group')),
      );
      expect(update.left, prefs.left);
      expect(update.right, diagnostics.right);
      expect(update.bottom, lessThanOrEqualTo(prefs.top));
      expect(prefs.bottom, lessThanOrEqualTo(diagnostics.top));
      final right = tester
          .getRect(find.byKey(const Key('about-check-update')))
          .right;
      for (final key in [
        'preferences-import',
        'preferences-restore-previous',
        'preferences-restore-defaults',
        'about-view-licenses',
        'about-open-project',
      ]) {
        expect(tester.getRect(find.byKey(Key(key))).right, closeTo(right, 1));
      }
      await tap(tester, find.byKey(const Key('preferences-restore-defaults')));
      expect(find.text('外观、声音与操作'), findsOneWidget);
      await shot(tester, 'preferences-scope');
      await tap(tester, find.text('取消').last);
    },
  );

  testWidgets(
    'preference export includes allowed preferences and no account fixture',
    (tester) async {
      storage.values['account-private-fixture'] = 'not-a-real-secret';
      picker.save = '${temp.path}/export.json';
      await pump(tester);
      await tap(tester, find.byKey(const Key('preferences-export')));
      final raw = await tester.runAsync(
        () => File(picker.save!).readAsString(),
      );
      final values = SettingsPreferencesService(storage).decode(raw!);
      expect(
        values[StorageKeys.studioThemeMode],
        storage.values[StorageKeys.studioThemeMode],
      );
      expect(raw, isNot(contains('account-private-fixture')));
    },
  );

  Future<void> selectImport(WidgetTester tester) async {
    final file = File('${temp.path}/import.json');
    await tester.runAsync(
      () => file.writeAsString(
        SettingsPreferencesService(
          storage,
        ).encode({StorageKeys.historyClickBehavior: 'select_preview'}),
      ),
    );
    picker.files = FilePickerResult([
      PlatformFile(name: 'import.json', path: file.path, size: 20),
    ]);
    await tap(tester, find.byKey(const Key('preferences-import')));
  }

  testWidgets(
    'preference import confirmation can cancel without changing values',
    (tester) async {
      storage.values[StorageKeys.historyClickBehavior] = 'open_detail';
      await pump(tester);
      final before = Map<String, Object?>.of(storage.values);
      await selectImport(tester);
      expect(find.textContaining('将应用 1 项偏好'), findsOneWidget);
      await shot(tester, 'preferences-import-confirm');
      await tap(tester, find.text('取消').last);
      expect(storage.values, before);
    },
  );
  testWidgets(
    'import backs up preferences and previous restoration recovers them',
    (tester) async {
      storage.values[StorageKeys.historyClickBehavior] = 'open_detail';
      await pump(tester);
      await selectImport(tester);
      await tap(tester, find.text('确认应用').last);
      expect(
        storage.values[StorageKeys.historyClickBehavior],
        'select_preview',
      );
      await tap(tester, find.byKey(const Key('preferences-restore-previous')));
      expect(find.textContaining('当前偏好会自动备份'), findsOneWidget);
      await tap(tester, find.text('确认应用').last);
      expect(storage.values[StorageKeys.historyClickBehavior], 'open_detail');
    },
  );
  testWidgets(
    'a newer preference change prevents an old import confirmation from overwriting it',
    (tester) async {
      storage.values[StorageKeys.historyClickBehavior] = 'open_detail';
      await pump(tester);
      await selectImport(tester);
      storage.values[StorageKeys.historyClickBehavior] = 'select_preview';
      await tap(tester, find.text('确认应用').last);
      expect(
        storage.values[StorageKeys.historyClickBehavior],
        'select_preview',
      );
      expect(find.textContaining('操作未完成'), findsOneWidget);
    },
  );

  testWidgets(
    'log toggle controls logger and persists only in isolated fixture storage',
    (tester) async {
      await pump(tester);
      final toggle = find.descendant(
        of: find.byKey(const Key('about-logging-setting')),
        matching: find.byType(SettingsToggle),
      );
      await tap(tester, toggle);
      expect(AppLogger.fileLoggingEnabled, true);
      expect(storage.values[StorageKeys.fileLoggingEnabled], true);
      await tap(tester, toggle);
      expect(AppLogger.fileLoggingEnabled, false);
      expect(storage.values[StorageKeys.fileLoggingEnabled], false);
    },
  );

  testWidgets(
    'manual update opens the existing dialog and a busy check cannot repeat',
    (tester) async {
      await pump(tester);
      await tap(tester, find.byKey(const Key('about-check-update')));
      expect(updates.checks, 1);
      expect(updates.manual, true);
      expect(find.byType(UpdateCheckDialog), findsOneWidget);
      await shot(tester, 'update-dialog');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      updates.show(const UpdateState(status: UpdateStatus.checking));
      await tester.pump();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('about-check-update')))
            .onPressed,
        isNull,
      );
      await shot(tester, 'update-checking');
      expect(updates.checks, 1);
    },
  );
  testWidgets('prerelease remains an independently saved update option', (
    tester,
  ) async {
    await pump(tester);
    await tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('about-prerelease-setting')),
        matching: find.byType(SettingsToggle),
      ),
    );
    expect(updates.prerelease, true);
    expect(storage.values[StorageKeys.includePrereleaseUpdates], true);
    expect(updates.checks, 0);
  });
  testWidgets(
    'font licenses and source project still open their original destinations',
    (tester) async {
      await pump(tester);
      await tap(tester, find.byKey(const Key('about-open-project')));
      expect(
        launched.single,
        'https://github.com/z15087716457-stack/W.O.F_NAI_Launcher',
      );
      await tap(tester, find.byKey(const Key('about-view-licenses')));
      expect(find.byType(LicensePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in const [Locale('en'), Locale('ja'), Locale('zh', 'TW')]) {
    for (final page in [3, 9]) {
      testWidgets(
        '${page == 3 ? 'gallery' : 'about'} wraps ${locale.toLanguageTag()} at compact enlarged size',
        (tester) async {
          await pump(
            tester,
            page: page,
            locale: locale,
            size: const Size(400, 900),
            scale: 1.3,
          );
          await shot(
            tester,
            '${page == 3 ? 'gallery' : 'about'}-${locale.toLanguageTag()}-narrow',
          );
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1200),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await shot(
            tester,
            '${page == 3 ? 'gallery' : 'about'}-${locale.toLanguageTag()}-narrow-bottom',
          );
        },
      );
    }
  }
}
