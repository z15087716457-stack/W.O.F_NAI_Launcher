import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/network/nai_api_endpoint.dart';
import 'saved_account.dart';

/// Account records and their API destinations must travel together.
class SavedAccountDirectory {
  const SavedAccountDirectory(this.accounts, this.endpoints);

  static const boxName = 'accounts';
  static const accountsKey = 'saved_accounts';
  static const endpointsKey = 'account_api_endpoints';
  final List<SavedAccount> accounts;
  final Map<String, NaiApiEndpointConfig> endpoints;

  factory SavedAccountDirectory.read(Box box) {
    final accounts =
        jsonDecode(box.get(accountsKey) as String? ?? '[]') as List;
    final endpoints =
        jsonDecode(box.get(endpointsKey) as String? ?? '{}')
            as Map<String, dynamic>;
    return SavedAccountDirectory(
      accounts
          .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      endpoints.map(
        (id, value) => MapEntry(
          id,
          NaiApiEndpointConfig.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
