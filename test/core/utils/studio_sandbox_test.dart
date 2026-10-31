import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:nai_launcher/core/utils/app_support_directory.dart';
import 'package:nai_launcher/core/utils/studio_sandbox.dart';
import 'package:nai_launcher/core/storage/sandbox_credential_store.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/core/utils/hive_storage_helper.dart';
import 'package:nai_launcher/core/utils/precise_ref_library_path_helper.dart';

class Credentials extends Mock implements FlutterSecureStorage {}

class Paths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => 'injected-support';
  @override
  Future<String?> getApplicationDocumentsPath() async => 'injected-documents';
  @override
  Future<String?> getTemporaryPath() async => 'injected-temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('environment opt-in is absolute and invalid values fail closed', () {
    expect(studioSandboxRoot({}), isNull);
    expect(
      () => studioSandboxRoot({'NAI_STUDIO_SANDBOX': ''}),
      throwsArgumentError,
    );
    expect(
      () => studioSandboxRoot({'NAI_STUDIO_SANDBOX': 'relative'}),
      throwsArgumentError,
    );
    expect(
      studioSandboxRoot({'NAI_STUDIO_SANDBOX': Directory.systemTemp.path}),
      p.normalize(Directory.systemTemp.path),
    );
  });
  test(
    'actual environment routes support/documents/temp/legacy only to sandbox, otherwise delegates',
    () async {
      final original = PathProviderPlatform.instance;
      PathProviderPlatform.instance = Paths();
      addTearDown(() => PathProviderPlatform.instance = original);
      final sandbox = studioSandboxRoot();
      if (sandbox != null) {
        expect(
          (await getApplicationSupportDirectory()).path,
          p.join(sandbox, 'user-data'),
        );
        expect(
          (await getApplicationDocumentsDirectory()).path,
          p.join(sandbox, 'documents'),
        );
        expect(
          (await getTemporaryDirectory()).path,
          p.join(sandbox, 'user-data', 'temp'),
        );
        expect(
          (await getLegacyApplicationSupportDirectory()).path,
          p.join(sandbox, 'user-data'),
        );
        expect(studioWindowTitle('Studio'), 'Studio [sandbox]');
        expect(
          await HiveStorageHelper.instance.getPath(),
          p.join(sandbox, 'user-data', 'hive'),
        );
        expect(
          await PreciseRefLibraryPathHelper.instance.getDefaultPath(),
          p.join(sandbox, 'documents', 'NAI_Launcher', 'precise_refs'),
        );
        final oldHive = File(p.join(sandbox, 'documents', 'settings.hive'));
        await oldHive.writeAsBytes([1, 2, 3]);
        final target = p.join(sandbox, 'user-data', 'migration-must-skip');
        await HiveStorageHelper.instance.migrateFromOldLocation(target);
        expect(await oldHive.exists(), true);
        expect(await Directory(target).exists(), false);
        expect(
          studioTemporaryRoot().path,
          p.join(sandbox, 'user-data', 'temp'),
        );
      } else {
        expect(
          (await getApplicationSupportDirectory()).path,
          'injected-support',
        );
        expect(
          (await getApplicationDocumentsDirectory()).path,
          'injected-documents',
        );
        expect((await getTemporaryDirectory()).path, 'injected-temp');
        expect(
          (await getLegacyApplicationSupportDirectory()).path,
          'injected-support',
        );
        expect(studioWindowTitle('Studio'), 'Studio');
        expect(studioTemporaryRoot().path, Directory.systemTemp.path);
      }
    },
  );
  test(
    'sandbox SharedPreferences persists in sandbox file, not plugin AppData',
    () async {
      final temp = await Directory.systemTemp.createTemp('sandbox-prefs-');
      final original = SharedPreferencesStorePlatform.instance;
      final originalPaths = PathProviderPlatform.instance;
      addTearDown(() async {
        SharedPreferencesStorePlatform.instance = original;
        PathProviderPlatform.instance = originalPaths;
        await temp.delete(recursive: true);
      });
      SharedPreferences.setMockInitialValues({'formal-only': true});
      initializeSandboxStorage(root: temp.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getBool('formal-only'), isNull);
      await prefs.setString('sample', 'sandbox');
      await prefs.setStringList('list', ['a', 'b']);
      await prefs.reload();
      expect(prefs.getString('sample'), 'sandbox');
      expect(prefs.getStringList('list'), ['a', 'b']);
      expect(
        await File(
          p.join(temp.path, 'user-data', 'shared_preferences.json'),
        ).exists(),
        true,
      );
      await prefs.remove('sample');
      expect(prefs.getString('sample'), isNull);
      await prefs.clear();
      expect(await SharedPreferencesStorePlatform.instance.getAll(), isEmpty);
    },
  );
  test(
    'sandbox credentials never call Windows credential manager, including deleteAll',
    () async {
      final disk = Credentials();
      final a = SandboxCredentialStore(sandbox: 'sandbox-a', storage: disk);
      final b = SandboxCredentialStore(sandbox: 'sandbox-b', storage: disk);
      await a.write(key: 'token', value: 'test-only');
      expect(await a.read(key: 'token'), 'test-only');
      expect(await b.read(key: 'token'), isNull);
      await b.deleteAll();
      expect(await a.read(key: 'token'), 'test-only');
      await a.delete(key: 'token');
      expect(await a.read(key: 'token'), isNull);
      await a.deleteAll();
      verifyZeroInteractions(disk);
    },
  );
  test(
    'SecureStorageService uses sandbox boundary under real environment opt-in',
    () async {
      final disk = Credentials();
      if (studioSandboxRoot() == null) {
        when(
          () => disk.read(key: 'ordinary'),
        ).thenAnswer((_) async => 'injected');
        expect(
          await SecureStorageService(storage: disk).read('ordinary'),
          'injected',
        );
        verify(() => disk.read(key: 'ordinary')).called(1);
      } else {
        final service = SecureStorageService(storage: disk);
        await service.write('ordinary', 'sandbox');
        expect(await service.read('ordinary'), 'sandbox');
        await service.clearAll();
        expect(await service.read('ordinary'), isNull);
        verifyZeroInteractions(disk);
      }
    },
  );
}
