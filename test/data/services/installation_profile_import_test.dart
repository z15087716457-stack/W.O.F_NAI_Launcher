import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage_windows/flutter_secure_storage_windows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/application_storage.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/services/installation_profile_import.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_dialog_kit.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_installation_import.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ProfilePaths extends PathProviderPlatform {
  _ProfilePaths(this.directory);
  final Directory directory;
  @override
  Future<String?> getApplicationSupportPath() async => directory.path;
  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp, old, current, gallery, moved;
  late String missing;
  late File sourceSettings;
  late InstallationProfile profile;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('studio-import-test-');
    old = await Directory(
      p.join(temp.path, 'older', 'user-data'),
    ).create(recursive: true);
    current = await Directory(
      p.join(temp.path, 'newer', 'user-data'),
    ).create(recursive: true);
    gallery = await Directory(p.join(old.path, 'images')).create();
    moved = await Directory(p.join(temp.path, 'moved')).create();
    missing = p.join(temp.path, 'missing');
    final hive = await Directory(p.join(old.path, 'hive')).create();
    Hive.init(hive.path);
    final accounts = await Hive.openBox('accounts');
    await accounts.put(
      'saved_accounts',
      jsonEncode([
        SavedAccount(
          id: 'fixture',
          email: 'fixture-account',
          createdAt: DateTime.utc(2020),
        ),
      ]),
    );
    await accounts.close();
    final settings = await Hive.openBox('settings');
    await settings.putAll({
      StorageKeys.studioThemeMode: 'dark',
      StorageKeys.galleryExtraRoots: [missing],
      StorageKeys.preciseRefLibrarySavePath: missing,
      'private_unrelated_setting': 'ignored',
    });
    await settings.close();
    sourceSettings = File(p.join(hive.path, 'settings.hive'));
    profile = (await InstallationProfile.inspect(old.parent, current))!;
  });
  tearDown(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test(
    'preview reads only supported settings and resolves legacy source paths',
    () async {
      expect(profile.settings.preferences, {
        StorageKeys.studioThemeMode: 'dark',
      });
      expect(profile.missing, {missing});
      expect(profile.accounts.accounts.single.id, 'fixture');
      final bytes = await sourceSettings.readAsBytes();
      expect(await profile.folderSettings({missing: moved.path}), {
        StorageKeys.imageSavePath: gallery.path,
        StorageKeys.galleryCategoryBasePath: gallery.path,
        StorageKeys.gallerySourcePaths: [gallery.path, moved.path],
        StorageKeys.preciseRefLibrarySavePath: moved.path,
      });
      expect(
        (await profile.folderSettings(
          {},
        ))[StorageKeys.preciseRefLibrarySavePath],
        isNull,
      );
      expect(await sourceSettings.readAsBytes(), bytes);
      expect(await InstallationProfile.inspect(old, old), isNull);
      expect(await InstallationProfile.inspect(current, current), isNull);
    },
  );

  test(
    'legacy Documents images remain a browse source and category anchor',
    () async {
      final imported = (await InstallationProfile.inspect(
        old,
        current,
        legacyGallery: moved,
      ))!;
      final selected = await imported.folderSettings({});
      expect(selected[StorageKeys.galleryCategoryBasePath], moved.path);
      expect(selected[StorageKeys.imageSavePath], gallery.path);
      expect(selected[StorageKeys.gallerySourcePaths], [
        gallery.path,
        moved.path,
      ]);
    },
  );

  test(
    'explicit empty gallery list overrides legacy roots and images',
    () async {
      final settings = await Hive.openBox('settings');
      await settings.put(StorageKeys.gallerySourcePaths, []);
      await settings.close();
      final empty = (await InstallationProfile.inspect(old, current))!;
      expect(
        (await empty.folderSettings({}))[StorageKeys.gallerySourcePaths],
        isEmpty,
      );
    },
  );

  test(
    'DPAPI reuses account-specific credentials and never touches either profile',
    () async {
      final paths = PathProviderPlatform.instance;
      final prefs = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        PathProviderPlatform.instance = paths;
        SharedPreferencesStorePlatform.instance = prefs;
      });
      initializeApplicationStorage(old);
      const options = {'useBackwardCompatibility': 'false'};
      final native = FlutterSecureStorageWindows();
      const tokenKey = '${StorageKeys.accountTokenPrefix}fixture';
      const refreshKey = '${StorageKeys.accountAccessKeyPrefix}fixture';
      for (final entry in {
        tokenKey: 'synthetic-token',
        refreshKey: 'synthetic-refresh',
        'other': 'unrelated',
      }.entries) {
        await native.write(
          key: entry.key,
          value: entry.value,
          options: options,
        );
      }
      final source = File(p.join(old.path, 'flutter_secure_storage.dat'));
      final encrypted = await source.readAsBytes();
      initializeApplicationStorage(current);
      expect(await profile.readAccountCredentials(), {
        tokenKey: 'synthetic-token',
        refreshKey: 'synthetic-refresh',
      });
      expect(await source.readAsBytes(), encrypted);
      expect(await native.read(key: tokenKey, options: options), isNull);
      await source.writeAsBytes([1, 2, 3, 4]);
      expect(await profile.readAccountCredentials(), isEmpty);
      expect(await source.readAsBytes(), [1, 2, 3, 4]);
    },
    skip: !Platform.isWindows,
  );

  test(
    'second installation reconnects moved references without deleting the first library originals',
    () async {
      final previousPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _ProfilePaths(current);
      addTearDown(() => PathProviderPlatform.instance = previousPaths);
      PreciseRefLibraryStorageService.registerEntryAdapter();
      final entry = PreciseRefLibraryEntry.create(
        name: 'original',
        imagePath: missing,
      );
      final name = '${entry.id}.png';
      final oldEntries = await Hive.openBox<PreciseRefLibraryEntry>(
        PreciseRefLibraryStorageService.entriesBoxName,
      );
      await oldEntries.put(
        entry.id,
        entry.copyWith(imagePath: p.join(missing, name), isFavorite: true),
      );
      await oldEntries.close();
      final original = File(p.join(moved.path, name));
      final otherOriginal = File(
        p.join(moved.path, '11111111-1111-4111-8111-111111111111.png'),
      );
      final otherStaged = File('${otherOriginal.path}.deleting-123');
      for (final file in [original, otherOriginal, otherStaged]) {
        await file.writeAsString('fixture');
      }
      Hive.init(p.join(current.path, 'hive'));
      final settings = await Hive.openBox('settings');
      await settings.put(StorageKeys.preciseRefLibrarySavePath, moved.path);
      final library = PreciseRefLibraryStorageService();
      await profile.linkReferences(library, moved.path);
      await profile.linkReferences(library, moved.path);
      final linked = (await library.getAllEntries()).single;
      expect(linked.imagePath, original.path);
      expect(linked.isFavorite, isTrue);
      for (final file in [original, otherOriginal, otherStaged]) {
        expect(await file.readAsString(), 'fixture');
      }
      await library.close();
    },
  );

  testWidgets(
    'preview relinks a missing folder once across roles and can be cancelled',
    (t) async {
      Map<String, String>? result;
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showSettingsDialog(
                  context,
                  (_) => InstallationImportPreview(
                    profile: profile,
                    chooseDirectory: () async => moved.path,
                  ),
                ),
                child: const Text('Open preview'),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await t.tap(find.text('Open preview'));
        await t.pumpAndSettle();
      }

      await open();
      final l = AppLocalizations.of(
        t.element(find.byType(InstallationImportPreview)),
      )!;
      expect(find.textContaining(l.set_importMissingFolder), findsOneWidget);
      await t.ensureVisible(find.text(l.set_choose));
      await t.tap(find.text(l.set_choose));
      await t.pumpAndSettle();
      expect(find.text(moved.path), findsOneWidget);
      await t.tap(find.text(l.common_cancel));
      await t.pumpAndSettle();
      expect(result, isNull);
      await open();
      await t.ensureVisible(find.text(l.set_choose));
      await t.tap(find.text(l.set_choose));
      await t.pumpAndSettle();
      await t.tap(find.text(l.set_importIt));
      await t.pumpAndSettle();
      expect(result, {missing: moved.path});
    },
  );
}
