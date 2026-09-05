import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/guest_session_provider.dart';

void main() {
  test('guest session is in-memory and defaults to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(guestSessionNotifierProvider), isFalse);
    container.read(guestSessionNotifierProvider.notifier).enterGuest();
    expect(container.read(guestSessionNotifierProvider), isTrue);

    container.read(guestSessionNotifierProvider.notifier).clear();
    expect(container.read(guestSessionNotifierProvider), isFalse);
  });

  test('guest session is not shared by a new provider container', () {
    final first = ProviderContainer();
    final second = ProviderContainer();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    first.read(guestSessionNotifierProvider.notifier).enterGuest();

    expect(first.read(isGuestSessionProvider), isTrue);
    expect(second.read(isGuestSessionProvider), isFalse);
  });
}
