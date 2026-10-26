import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Secure extends SecureStorageService {
  final tokens = <String, String>{};
  bool failNextWrite = false;
  @override
  Future<void> saveAccountToken(String id, String token) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('credential write failed');
    }
    tokens[id] = token;
  }

  @override
  Future<void> deleteAccountToken(String id) async {
    tokens.remove(id);
  }

  @override
  Future<void> deleteAccountAccessKey(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late Box box;
  late ProviderContainer container;
  late AccountManagerNotifier notifier;
  late SavedAccount a;
  late _Secure secure;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account_mutations_');
    Hive.init(directory.path);
    box = await Hive.openBox('accounts');
    a = SavedAccount(
      id: 'A',
      email: 'a.fixture',
      nickname: 'old',
      createdAt: DateTime.utc(2026),
      subscriptionExpiresAt: 100,
    );
    final b = SavedAccount(
      id: 'B',
      email: 'b.fixture',
      nickname: 'B',
      createdAt: DateTime.utc(2026),
      isDefault: true,
    );
    await box.put('saved_accounts', jsonEncode([a.toJson(), b.toJson()]));
    secure = _Secure()..tokens['A'] = 'fixture';
    container = ProviderContainer(
      overrides: [secureStorageServiceProvider.overrideWithValue(secure)],
    );
    notifier = container.read(accountManagerNotifierProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> loaded() async {
    final ready = Completer<void>();
    final sub = container.listen(accountManagerNotifierProvider, (_, next) {
      if (!next.isLoading && !ready.isCompleted) ready.complete();
    }, fireImmediately: true);
    await ready.future;
    sub.close();
    expect(container.read(accountManagerNotifierProvider).error, isNull);
  }

  SavedAccount current() => container
      .read(accountManagerNotifierProvider)
      .accounts
      .firstWhere((account) => account.id == 'A');
  void expectPersisted() {
    final stored = (jsonDecode(box.get('saved_accounts') as String) as List)
        .map(
          (value) =>
              SavedAccount.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    expect(stored, container.read(accountManagerNotifierProvider).accounts);
  }

  for (final profileFirst in [true, false]) {
    test(
      'profile edit merges with subscription refresh; profileFirst=$profileFirst',
      () async {
        await loaded();
        final actions = [
          () => notifier.updateNickname(a.id, 'new'),
          () => notifier.updateSubscriptionExpiry('A', 200),
        ];
        if (!profileFirst) actions.setAll(0, actions.reversed.toList());
        await Future.wait(actions.map((action) => action()));
        expect(current().nickname, 'new');
        expect(current().subscriptionExpiresAt, 200);
        expectPersisted();
      },
    );
  }

  test('independent avatar and nickname edits both persist', () async {
    await loaded();
    await Future.wait([
      notifier.updateAvatar(a.id, 'fixture-avatar.png'),
      notifier.updateNickname(a.id, 'new'),
    ]);
    expect(current().avatarPath, 'fixture-avatar.png');
    expect(current().nickname, 'new');
    expectPersisted();
  });

  test(
    'default and last-used updates survive an overlapping profile edit',
    () async {
      await loaded();
      await Future.wait([
        notifier.setDefaultAccount('A'),
        notifier.updateLastUsed('A'),
        notifier.updateNickname(a.id, 'new'),
      ]);
      expect(current().isDefault, isTrue);
      expect(current().lastUsedAt, isNotNull);
      expect(current().nickname, 'new');
      expect(
        container
            .read(accountManagerNotifierProvider)
            .accounts
            .where((a) => a.isDefault),
        hasLength(1),
      );
      expectPersisted();
    },
  );

  test(
    'two concurrent additions of the same identifier update one account',
    () async {
      await loaded();
      final results = await Future.wait([
        notifier.addAccount(
          identifier: 'c.fixture',
          token: 'first',
          nickname: 'first',
        ),
        notifier.addAccount(
          identifier: 'c.fixture',
          token: 'second',
          nickname: 'second',
          setAsDefault: true,
        ),
        notifier.updateSubscriptionExpiry('A', 200),
      ]);
      final accounts = container.read(accountManagerNotifierProvider).accounts;
      expect(accounts, hasLength(3));
      final added = accounts.singleWhere((a) => a.email == 'c.fixture');
      expect(added.nickname, 'second');
      expect(added.isDefault, isTrue);
      expect((results[0] as SavedAccount).id, added.id);
      expect((results[1] as SavedAccount).id, added.id);
      expect(secure.tokens[added.id], 'second');
      expect(current().subscriptionExpiresAt, 200);
      expectPersisted();
    },
  );

  test('deletion cannot be undone by late profile or expiry writes', () async {
    await loaded();
    await Future.wait([
      notifier.removeAccount('A'),
      notifier.updateNickname(a.id, 'new'),
      notifier.updateSubscriptionExpiry('A', 200),
    ]);
    expect(
      container.read(accountManagerNotifierProvider).accounts.map((a) => a.id),
      ['B'],
    );
    expect(secure.tokens, isNot(contains('A')));
    expectPersisted();
  });

  test(
    'an update requested during loading waits for the saved accounts',
    () async {
      await notifier.updateSubscriptionExpiry('A', 200);
      await loaded();
      expect(current().subscriptionExpiresAt, 200);
      expectPersisted();
    },
  );

  test(
    'a failed credential write does not block the following profile edit',
    () async {
      await loaded();
      secure.failNextWrite = true;
      final failed = expectLater(
        notifier.addAccount(
          identifier: 'c.fixture',
          token: 'failed',
          nickname: 'C',
        ),
        throwsStateError,
      );
      final edit = notifier.updateNickname(a.id, 'new');
      await failed;
      await edit;
      expect(current().nickname, 'new');
      expect(
        container.read(accountManagerNotifierProvider).accounts,
        hasLength(2),
      );
      expectPersisted();
    },
  );

  test(
    'token refresh queued after deletion cannot recreate saved credentials',
    () async {
      await loaded();
      final deleting = notifier.removeAccount('A');
      final refreshing = expectLater(
        notifier.updateAccountToken('A', 'late'),
        throwsStateError,
      );
      await deleting;
      await refreshing;
      expect(secure.tokens, isNot(contains('A')));
      expectPersisted();
    },
  );
}
