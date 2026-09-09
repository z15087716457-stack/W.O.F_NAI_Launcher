import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';

void main() {
  group('SavedAccount JSON compatibility and subscriptionExpiresAt', () {
    test('legacy JSON without subscriptionExpiresAt defaults to null', () {
      final legacyJson = <String, dynamic>{
        'id': 'acc-123',
        'email': 'user@example.com',
        'nickname': 'TestUser',
        'createdAt': '2026-01-01T00:00:00.000',
        'isDefault': true,
        'accountType': 'token',
      };

      final account = SavedAccount.fromJson(legacyJson);

      expect(account.id, 'acc-123');
      expect(account.email, 'user@example.com');
      expect(account.nickname, 'TestUser');
      expect(account.subscriptionExpiresAt, isNull);
    });

    test('JSON round-trip with subscriptionExpiresAt', () {
      const expiresAt = 1788888888;
      final json = <String, dynamic>{
        'id': 'acc-456',
        'email': 'subscriber@example.com',
        'nickname': 'SubUser',
        'createdAt': '2026-06-01T12:00:00.000',
        'lastUsedAt': '2026-06-02T12:00:00.000',
        'isDefault': false,
        'accountType': 'credentials',
        'subscriptionExpiresAt': expiresAt,
      };

      final account = SavedAccount.fromJson(json);

      expect(account.id, 'acc-456');
      expect(account.subscriptionExpiresAt, expiresAt);

      final encodedJson = account.toJson();
      expect(encodedJson['subscriptionExpiresAt'], expiresAt);

      final restored = SavedAccount.fromJson(encodedJson);
      expect(restored, equals(account));
      expect(restored.subscriptionExpiresAt, expiresAt);
    });

    test('copyWith updates subscriptionExpiresAt cleanly', () {
      final account = SavedAccount.create(
        email: 'user@example.com',
        nickname: 'Alice',
      );
      expect(account.subscriptionExpiresAt, isNull);

      final updated = account.copyWith(subscriptionExpiresAt: 1800000000);
      expect(updated.subscriptionExpiresAt, 1800000000);
      expect(updated.id, account.id);
      expect(updated.email, account.email);

      final cleared = updated.copyWith(subscriptionExpiresAt: null);
      expect(cleared.subscriptionExpiresAt, isNull);
    });
  });
}
