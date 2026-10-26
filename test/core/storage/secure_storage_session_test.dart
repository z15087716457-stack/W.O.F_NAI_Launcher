import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';

class Disk extends Mock implements FlutterSecureStorage {}

void main() {
  late Disk disk;
  late SecureStorageService storage;
  setUp(() async {
    disk = Disk();
    when(
      () => disk.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => disk.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(disk.deleteAll).thenAnswer((_) async {});
    storage = SecureStorageService(storage: disk);
    await storage.clearAll();
  });
  tearDown(() => storage.clearAll());

  test('same-token login advances session ownership', () async {
    await storage.saveAccessToken('pst-fixture-session-A');
    final previous = storage.authRevision;
    await storage.saveAccessToken('pst-fixture-session-A');
    expect(storage.authRevision, greaterThan(previous));
  });
  for (final logout in [false, true]) {
    test(
      'cold token read cannot restore an obsolete session: logout=$logout',
      () async {
        final pending = Completer<String?>();
        when(
          () => disk.read(key: any(named: 'key')),
        ).thenAnswer((_) => pending.future);
        final read = storage.getAccessToken();
        if (logout) {
          await storage.clearAuth();
        } else {
          await storage.saveAccessToken('pst-fixture-session-B');
        }
        pending.complete('pst-fixture-session-A');
        expect(await read, logout ? null : 'pst-fixture-session-B');
        if (!logout) {
          expect(await storage.getAccessToken(), 'pst-fixture-session-B');
        }
      },
    );
  }
}
