import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';

void main() {
  late Directory hiveDir;
  late Box accountsBox;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('account_manager_test_');
    Hive.init(hiveDir.path);
    accountsBox = await Hive.openBox('accounts');
  });

  setUp(() async {
    await accountsBox.clear();
  });

  tearDownAll(() async {
    await accountsBox.close();
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('正常更新并持久化到 Hive', () async {
    final account = SavedAccount.create(
      email: 'user1@example.com',
      nickname: 'User1',
    );
    await accountsBox.put('saved_accounts', jsonEncode([account.toJson()]));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(accountManagerNotifierProvider.notifier);
    // 等待初始化加载完成
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(
      container.read(accountManagerNotifierProvider).accounts,
      hasLength(1),
    );
    expect(
      container
          .read(accountManagerNotifierProvider)
          .accounts
          .first
          .subscriptionExpiresAt,
      isNull,
    );

    const newExpiry = 1788888888;
    await notifier.updateSubscriptionExpiry(account.id, newExpiry);

    // 1. 状态已更新
    final updatedAccount = container
        .read(accountManagerNotifierProvider)
        .accounts
        .first;
    expect(updatedAccount.subscriptionExpiresAt, newExpiry);

    // 2. Hive 持久化内容已写入
    final savedJson = accountsBox.get('saved_accounts') as String;
    final decodedList = jsonDecode(savedJson) as List<dynamic>;
    expect(decodedList.first['subscriptionExpiresAt'], newExpiry);
  });

  test('幂等性：值相同时不写盘且状态不产生无意义变更', () async {
    const existingExpiry = 1788888888;
    final account = SavedAccount.create(
      email: 'user2@example.com',
      nickname: 'User2',
      subscriptionExpiresAt: existingExpiry,
    );
    await accountsBox.put('saved_accounts', jsonEncode([account.toJson()]));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(accountManagerNotifierProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    var boxWriteCount = 0;
    final subscription = accountsBox.watch(key: 'saved_accounts').listen((_) {
      boxWriteCount++;
    });
    addTearDown(subscription.cancel);

    final stateBefore = container.read(accountManagerNotifierProvider);

    // 调用相同的值
    await notifier.updateSubscriptionExpiry(account.id, existingExpiry);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // 幂等：未触发写盘，状态对象保持一致
    expect(boxWriteCount, 0);
    expect(container.read(accountManagerNotifierProvider), same(stateBefore));
  });

  test('不存在的账号：静默返回，不写盘也不影响现有账号', () async {
    final account = SavedAccount.create(
      email: 'user3@example.com',
      nickname: 'User3',
    );
    await accountsBox.put('saved_accounts', jsonEncode([account.toJson()]));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(accountManagerNotifierProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    var boxWriteCount = 0;
    final subscription = accountsBox.watch(key: 'saved_accounts').listen((_) {
      boxWriteCount++;
    });
    addTearDown(subscription.cancel);

    final stateBefore = container.read(accountManagerNotifierProvider);

    // 针对不存在的账号更新
    await notifier.updateSubscriptionExpiry('non-existent-id', 1799999999);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(boxWriteCount, 0);
    expect(container.read(accountManagerNotifierProvider), same(stateBefore));
  });
}
