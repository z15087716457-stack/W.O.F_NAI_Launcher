import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage_windows/flutter_secure_storage_windows.dart';
import 'package:nai_launcher/core/storage/application_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as system_paths;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _ForbiddenLegacyPaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    fail('Prepared storage must not read the old AppData provider');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory fixture;

  setUp(() async {
    final paths = PathProviderPlatform.instance;
    final preferences = SharedPreferencesStorePlatform.instance;
    fixture = await Directory.systemTemp.createTemp(
      'application-storage-test-',
    );
    SharedPreferences.setMockInitialValues({});
    addTearDown(() async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = preferences;
      PathProviderPlatform.instance = paths;
      expect(
        p.isWithin(Directory.systemTemp.absolute.path, fixture.absolute.path),
        isTrue,
      );
      expect(p.basename(fixture.path), startsWith('application-storage-test-'));
      await fixture.delete(recursive: true);
    });
  });

  test(
    'existing native preferences retain their format and survive restart',
    () async {
      final directory = Directory(p.join(fixture.path, 'user-data'));
      await directory.create();
      final file = File(p.join(directory.path, 'shared_preferences.json'));
      await file.writeAsString(
        jsonEncode({
          'flutter.name': 'existing preference',
          'flutter.list': ['one', 'two'],
          'external.setting': 'keep',
        }),
      );
      initializeApplicationStorage(directory);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('name'), 'existing preference');
      expect(prefs.getStringList('list'), ['one', 'two']);
      expect(prefs.getKeys(), isNot(contains('external.setting')));
      await Future.wait([
        for (var i = 0; i < 20; i++) prefs.setInt('number-$i', i),
        prefs.setBool('enabled', true),
        prefs.setDouble('scale', 1.5),
      ]);
      SharedPreferences.setMockInitialValues({});
      initializeApplicationStorage(directory);
      final reopened = await SharedPreferences.getInstance();
      expect(reopened.getBool('enabled'), true);
      expect(reopened.getDouble('scale'), 1.5);
      for (var i = 0; i < 20; i++) {
        expect(reopened.getInt('number-$i'), i);
      }
      await reopened.remove('name');
      await reopened.clear();
      expect(jsonDecode(await file.readAsString()), {
        'external.setting': 'keep',
      });
    },
  );

  test(
    'native encrypted credentials use only the selected adjacent profile',
    () async {
      final first = Directory(p.join(fixture.path, 'first', 'user-data'));
      final second = Directory(p.join(fixture.path, 'second', 'user-data'));
      await first.create(recursive: true);
      await second.create(recursive: true);
      PathProviderPlatform.instance = _ForbiddenLegacyPaths();
      initializeApplicationStorage(first);
      expect(
        (await system_paths.getApplicationSupportDirectory()).path,
        first.path,
      );
      const options = {'useBackwardCompatibility': 'false'};
      final native = FlutterSecureStorageWindows();
      await native.write(
        key: 'fixture',
        value: 'synthetic-first-value',
        options: options,
      );
      final file = File(p.join(first.path, 'flutter_secure_storage.dat'));
      final encrypted = await file.readAsBytes();
      expect(
        utf8.decode(encrypted, allowMalformed: true),
        isNot(contains('synthetic-first-value')),
      );
      // A new instance after initialization reads the existing encrypted format.
      initializeApplicationStorage(first);
      expect(
        await FlutterSecureStorageWindows().read(
          key: 'fixture',
          options: options,
        ),
        'synthetic-first-value',
      );
      initializeApplicationStorage(second);
      expect(await native.read(key: 'fixture', options: options), isNull);
      await native.write(
        key: 'fixture',
        value: 'synthetic-second-value',
        options: options,
      );
      expect(
        await native.read(key: 'fixture', options: options),
        'synthetic-second-value',
      );
      expect(await file.readAsBytes(), encrypted);
      initializeApplicationStorage(first);
      expect(
        await native.read(key: 'fixture', options: options),
        'synthetic-first-value',
      );
      await native.delete(key: 'fixture', options: options);
      expect(await native.read(key: 'fixture', options: options), isNull);
    },
    skip: !Platform.isWindows,
  );
}
