import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// Flutter's test clock dependency; no additional runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/data/datasources/remote/nai_user_info_api_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Api extends Mock implements NAIUserInfoApiService {}

class _Accounts extends AccountManagerNotifier {
  @override
  AccountManagerState build() => const AccountManagerState(isLoading: false);

  @override
  Future<void> updateSubscriptionExpiry(String accountId, int? expiresAt) =>
      Future.value();
}

/// An Opus account; [usage] is its free-generation quota (V5).
Map<String, dynamic> _subscription(int balance, {OpusUsage? usage}) => {
  'tier': 3,
  'active': true,
  'trainingStepsLeft': {
    'fixedTrainingStepsLeft': balance,
    'purchasedTrainingSteps': 0,
  },
  if (usage != null) 'usage': usage.toJson(),
};

/// Logged in to [id]. [validated]: the balance the token validation brought
/// along (it asks `/user/subscription` itself); null when it brought none.
AuthState _account(String id, {int? validated, OpusUsage? usage}) => AuthState(
  status: AuthStatus.authenticated,
  accountId: id,
  subscriptionInfo: validated == null
      ? null
      : _subscription(validated, usage: usage),
);

const _signedOut = AuthState(status: AuthStatus.unauthenticated);

class _Auth extends AuthNotifier {
  _Auth(this._start);
  final AuthState _start;

  @override
  AuthState build() => _start;

  void set(AuthState next) => state = next;
}

final _request = RequestOptions(path: '/user/subscription');

/// Stands in for a caller that is about to stop something because the cached
/// balance looks too low (the Agent's price checks).
final _beforeBlocking = Provider<Future<void> Function()>(
  (ref) =>
      () => refreshBalanceBeforeBlocking(ref),
);

/// The app with one balance notifier against a fake NovelAI, watched the way
/// the balance chip and the other screens watch it.
class _App {
  _App(this.async, {AuthState? auth, this.offline = false}) {
    when(
      () =>
          api.getUserSubscription(receiveTimeout: any(named: 'receiveTimeout')),
    ).thenAnswer((_) async {
      requests.add(async.elapsed);
      final wait = hold;
      if (wait != null) await wait.future;
      if (offline) {
        throw DioException(
          requestOptions: _request,
          type: DioExceptionType.connectionError,
          error: const SocketException('Connection refused'),
        );
      }
      return _subscription(balance, usage: usage);
    });
    container = ProviderContainer(
      overrides: [
        opusPriceClockProvider.overrideWithValue(() => async.elapsed),
        authNotifierProvider.overrideWith(
          () => _Auth(auth ?? _account('first')),
        ),
        naiUserInfoApiServiceProvider.overrideWithValue(api),
        accountManagerNotifierProvider.overrideWith(_Accounts.new),
      ],
    );
    container.listen(
      subscriptionNotifierProvider,
      (_, __) => notifications++,
      fireImmediately: true,
    );
    async.flushMicrotasks();
  }

  final FakeAsync async;
  final api = _Api();
  late final ProviderContainer container;

  /// When each balance request went out.
  final requests = <Duration>[];
  int notifications = 0;
  int balance = 100;
  OpusUsage? usage;
  bool offline;

  /// While set, a request waits for it before answering.
  Completer<void>? hold;

  int? get shown => container.read(subscriptionNotifierProvider).balance;

  /// The login state changes (login, logout, another account, a new token).
  void auth(AuthState next) {
    (container.read(authNotifierProvider.notifier) as _Auth).set(next);
    container.read(subscriptionNotifierProvider);
    async.flushMicrotasks();
  }

  /// A click on the balance (chip, quota capsule, Opus chip).
  Future<bool> click() =>
      container.read(subscriptionNotifierProvider.notifier).refreshBalance();

  void dispose() => container.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  // Nothing here has a platform branch any more; the window signal itself is
  // platform code (menu bar on macOS, tray on Windows). Run it on both.
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    group('${platform.name}: nothing asks by itself', () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      tearDown(() {
        debugDefaultTargetPlatformOverride = null;
        AppVisibility.instance.debugSet(true);
      });

      test('start-up asks once, then hours visible and idle ask nothing', () {
        fakeAsync((async) {
          final app = _App(async);
          expect(app.requests, [Duration.zero]);
          expect(app.shown, 100);
          async.elapse(const Duration(hours: 3));
          // Before: every 30 s, 360 more.
          expect(app.requests, [Duration.zero]);
          app.dispose();
        });
      });

      test('the balance the token validation brought is the start-up one', () {
        fakeAsync((async) {
          final app = _App(async, auth: _account('first', validated: 90));
          expect(app.shown, 90);
          async.elapse(const Duration(hours: 3));
          // The validation asked; before: every 30 s from there on.
          expect(app.requests, isEmpty);
          app.dispose();
        });
      });

      test('hiding and showing the window asks nothing', () {
        fakeAsync((async) {
          final app = _App(async);
          for (var i = 0; i < 20; i++) {
            AppVisibility.instance.debugSet(false);
            async.elapse(const Duration(minutes: 3));
            AppVisibility.instance.debugSet(true);
            async.elapse(const Duration(seconds: 40));
          }
          AppVisibility.instance
            ..debugSet(false)
            ..debugSet(true);
          async.elapse(const Duration(minutes: 5));
          // Before: once at every show, and every 30 s while shown.
          expect(app.requests, [Duration.zero]);
          app.dispose();
        });
      });
    });
  }

  group('login and accounts', () {
    test('a login asks once; logging out asks nothing; logging in again '
        'asks once', () {
      fakeAsync((async) {
        final app = _App(async, auth: _signedOut);
        expect(app.requests, isEmpty);
        expect(app.shown, isNull);

        async.elapse(const Duration(minutes: 1));
        app.auth(_account('first'));
        expect(app.requests, [const Duration(minutes: 1)]);
        expect(app.shown, 100);
        async.elapse(const Duration(hours: 1));
        expect(app.requests, hasLength(1));

        app.auth(_signedOut);
        expect(app.shown, isNull);
        async.elapse(const Duration(hours: 1));
        expect(app.requests, hasLength(1));

        app.balance = 70;
        app.auth(_account('first'));
        expect(app.requests, hasLength(2));
        expect(app.shown, 70);
        async.elapse(const Duration(hours: 1));
        // Before: every 30 s after each login.
        expect(app.requests, hasLength(2));
        app.dispose();
      });
    });

    test('a login whose validation brought the balance asks nothing more', () {
      fakeAsync((async) {
        final app = _App(async, auth: _signedOut);
        app.auth(_account('first', validated: 40));
        expect(app.shown, 40);
        async.elapse(const Duration(hours: 1));
        expect(app.requests, isEmpty);
        app.dispose();
      });
    });

    test('each account switch asks once for the new account', () {
      fakeAsync((async) {
        final app = _App(async);
        expect(app.requests, hasLength(1));
        app.balance = 30;
        app.auth(_account('second'));
        expect(app.requests, hasLength(2));
        expect(app.shown, 30);
        app.balance = 20;
        app.auth(_account('third'));
        expect(app.requests, hasLength(3));
        expect(app.shown, 20);
        // Back to an account whose validation brought its balance.
        app.auth(_account('first', validated: 100));
        expect(app.requests, hasLength(3));
        expect(app.shown, 100);
        async.elapse(const Duration(hours: 1));
        expect(app.requests, hasLength(3));
        app.dispose();
      });
    });

    // AuthNotifier marks the session loading while it checks the new token;
    // a failure puts back the account it had, error attached
    // (previousState.copyWith(errorCode: ...)).
    test('a failed login or switch keeps the balance a click brought', () {
      fakeAsync((async) {
        final app = _App(async, auth: _account('first', validated: 100));
        app.balance = 80;
        app.click();
        async.flushMicrotasks();
        expect(app.shown, 80);

        final signedIn = app.container.read(authNotifierProvider);
        for (final error in [
          AuthErrorCode.networkError,
          AuthErrorCode.authFailed,
        ]) {
          app.auth(signedIn.copyWith(status: AuthStatus.loading));
          app.auth(signedIn.copyWith(errorCode: error));
          // Before: the start-up 100 again, until the next click.
          expect(app.shown, 80, reason: '$error');
        }
        async.elapse(const Duration(hours: 1));
        expect(app.shown, 80);
        expect(app.requests, [Duration.zero]);
        app.dispose();
      });
    });

    test('a switch or a logout that passes through loading still resets', () {
      fakeAsync((async) {
        final app = _App(async, auth: _account('first', validated: 100));
        app.balance = 80;
        app.click();
        async.flushMicrotasks();

        final first = app.container.read(authNotifierProvider);
        app.auth(first.copyWith(status: AuthStatus.loading));
        app.auth(_account('second', validated: 30));
        expect(app.shown, 30);

        app.balance = 25;
        app.auth(_account('second').copyWith(status: AuthStatus.loading));
        app.auth(_account('third'));
        expect(app.shown, 25);
        expect(app.requests, hasLength(2));

        app.auth(_account('third').copyWith(status: AuthStatus.loading));
        app.auth(_signedOut);
        expect(app.shown, isNull);
        app.balance = 10;
        app.auth(_account('third'));
        expect(app.shown, 10);
        expect(app.requests, hasLength(3));
        app.dispose();
      });
    });

    test('a session update (new token, profile) asks nothing', () {
      fakeAsync((async) {
        final app = _App(async);
        async.elapse(const Duration(seconds: 40));
        app.auth(
          AuthState(
            status: AuthStatus.authenticated,
            accountId: 'first',
            displayName: 'Updated',
            subscriptionInfo: _subscription(100),
          ),
        );
        async.elapse(const Duration(hours: 1));
        // Before: the poll went on every 30 s.
        expect(app.requests, [Duration.zero]);
        app.dispose();
      });
    });
  });

  group('clicks', () {
    test('each click asks once', () {
      fakeAsync((async) {
        final app = _App(async);
        for (final balance in [90, 80, 70]) {
          async.elapse(const Duration(minutes: 10));
          app.balance = balance;
          app.click();
          async.flushMicrotasks();
          expect(app.shown, balance);
        }
        expect(app.requests, [
          Duration.zero,
          const Duration(minutes: 10),
          const Duration(minutes: 20),
          const Duration(minutes: 30),
        ]);
        app.dispose();
      });
    });

    test(
      'clicks while a request is out add one more after it, not one each',
      () {
        fakeAsync((async) {
          final app = _App(async);
          app.hold = Completer<void>();
          app.click();
          async.flushMicrotasks();
          app
            ..click()
            ..click();
          async.flushMicrotasks();
          expect(app.requests, hasLength(2));
          app.balance = 60;
          app.hold!.complete();
          app.hold = null;
          async.flushMicrotasks();
          expect(app.requests, hasLength(3));
          expect(app.shown, 60);
          app.dispose();
        });
      },
    );

    test('a failed click keeps the balance on screen and nothing retries', () {
      fakeAsync((async) {
        final app = _App(async);
        app.offline = true;
        late bool answered;
        app.click().then((value) => answered = value);
        async.flushMicrotasks();
        expect(answered, isFalse);
        expect(app.shown, 100);
        expect(app.container.read(subscriptionNotifierProvider).isLoaded, true);
        async.elapse(const Duration(hours: 1));
        // Before: backoff retries and a network probe.
        expect(app.requests, hasLength(2));
        app.dispose();
      });
    });

    test('a start-up that cannot reach the server waits for a click', () {
      fakeAsync((async) {
        final app = _App(async, offline: true);
        expect(app.requests, [Duration.zero]);
        expect(app.shown, isNull);
        async.elapse(const Duration(hours: 1));
        // Before: backoff retries and a network probe.
        expect(app.requests, [Duration.zero]);

        app
          ..offline = false
          ..balance = 55;
        app.click();
        async.flushMicrotasks();
        expect(app.requests, hasLength(2));
        expect(app.shown, 55);
        // The clicked balance counts as loaded: a token update carrying an
        // older one does not replace it, and asks nothing.
        app.auth(_account('first', validated: 99));
        expect(app.shown, 55);
        expect(app.requests, hasLength(2));
        app.dispose();
      });
    });

    test('an unchanged answer does not notify the screens', () {
      fakeAsync((async) {
        final app = _App(async);
        // The initial state, then the first answer.
        expect(app.notifications, 2);
        app
          ..click()
          ..click();
        async.flushMicrotasks();
        expect(app.requests, hasLength(3));
        expect(app.notifications, 2);
        app.balance = 80;
        app.click();
        async.flushMicrotasks();
        expect(app.notifications, 3);
        app.dispose();
      });
    });
  });

  group('a low cached balance about to block', () {
    test('asks once, right then', () {
      fakeAsync((async) {
        final app = _App(async, auth: _account('first', validated: 5));
        expect(app.shown, 5);
        app.balance = 500;
        var done = false;
        app.container.read(_beforeBlocking)().then((_) => done = true);
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(app.requests, [Duration.zero]);
        expect(app.shown, 500);
        async.elapse(const Duration(hours: 1));
        expect(app.requests, hasLength(1));
        app.dispose();
      });
    });

    test('a request already out answers it; no second one', () {
      fakeAsync((async) {
        final app = _App(async, auth: _account('first', validated: 5));
        app
          ..hold = Completer<void>()
          ..balance = 500;
        app.click();
        async.flushMicrotasks();
        var done = false;
        app.container.read(_beforeBlocking)().then((_) => done = true);
        async.flushMicrotasks();
        expect(done, isFalse);
        app.hold!.complete();
        app.hold = null;
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(app.shown, 500);
        expect(app.requests, hasLength(1));
        app.dispose();
      });
    });

    test('does nothing where the balance never started', () async {
      final api = _Api();
      final container = ProviderContainer(
        overrides: [naiUserInfoApiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      await container.read(_beforeBlocking)();
      expect(container.exists(subscriptionNotifierProvider), isFalse);
      verifyNever(
        () => api.getUserSubscription(
          receiveTimeout: any(named: 'receiveTimeout'),
        ),
      );
    });
  });

  group('an Opus-free price on a quota nearly used up', () {
    // What a V5 request costs: free on the Opus quota until the server says
    // it ran out (usage.isNegative), then Anlas.
    int v5(UserSubscription? subscription) =>
        subscription?.isOpusUsageExhausted == true ? 30 : 0;

    Future<bool>? recheck(_App app, int Function(UserSubscription?) price) =>
        app.container
            .read(subscriptionNotifierProvider.notifier)
            .recheckBeforeOpusFreePrice(price);

    test('asks once before the price, and the answer prices it', () {
      fakeAsync((async) {
        // Both pools under 5 %: the cached answer still counts it free.
        final app = _App(
          async,
          auth: _account(
            'first',
            validated: 100,
            usage: const OpusUsage(percent: 3, purchasedPercent: 4),
          ),
        );
        final cached = app.container.read(subscriptionNotifierProvider);
        expect(v5(cached.subscription), 0);
        app.usage = const OpusUsage(isNegative: true);
        final asked = recheck(app, v5);
        expect(asked, isNotNull);
        var done = false;
        asked!.then((_) => done = true);
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(app.requests, [Duration.zero]);
        expect(
          v5(app.container.read(subscriptionNotifierProvider).subscription),
          30,
        );
        async.elapse(const Duration(hours: 1));
        expect(app.requests, hasLength(1));
        app.dispose();
      });
    });

    for (final (name, usage, price) in [
      (
        'regular quota left',
        const OpusUsage(percent: 5, purchasedPercent: 0),
        v5,
      ),
      (
        'reserve quota left',
        const OpusUsage(percent: 0, purchasedPercent: 5),
        v5,
      ),
      (
        'an exhausted quota does not change this price',
        const OpusUsage(isNegative: true),
        (UserSubscription? _) => 30,
      ),
      ('no quota data', null, v5),
      (
        'a price the quota does not change',
        const OpusUsage(percent: 1),
        (UserSubscription? _) => 30,
      ),
    ]) {
      test('asks nothing: $name', () {
        fakeAsync((async) {
          final app = _App(
            async,
            auth: _account('first', validated: 100, usage: usage),
          );
          expect(recheck(app, price), isNull);
          async.elapse(const Duration(hours: 1));
          expect(app.requests, isEmpty);
          app.dispose();
        });
      });
    }

    for (final fail in [false, true]) {
      test(
        'exhausted paid price joins concurrent checks and waits for fresh demand after 30 s (failed: $fail)',
        () {
          fakeAsync((async) {
            const exhausted = OpusUsage(isNegative: true);
            final app =
                _App(
                    async,
                    auth: _account('first', validated: 100, usage: exhausted),
                    offline: fail,
                  )
                  ..usage = exhausted
                  ..hold = Completer<void>();
            expect(app.requests, isEmpty);
            expect(recheck(app, v5), isNotNull);
            expect(recheck(app, v5), isNotNull);
            async.flushMicrotasks();
            expect(app.requests, [Duration.zero]);
            async.elapse(const Duration(seconds: 5));
            app.hold!.complete();
            app.hold = null;
            async.flushMicrotasks();
            async.elapse(const Duration(seconds: 29));
            expect(recheck(app, v5), isNull);
            expect(app.requests, hasLength(1));
            async.elapse(const Duration(minutes: 5));
            expect(app.requests, hasLength(1));
            app.offline = false;
            app.usage = const OpusUsage(percent: 40);
            expect(recheck(app, v5), isNotNull);
            async.flushMicrotasks();
            expect(app.requests, hasLength(2));
            expect(
              v5(app.container.read(subscriptionNotifierProvider).subscription),
              0,
            );
            app.dispose();
          });
        },
      );
    }

    test(
      'an explicit refresh still bypasses the depleted-price reuse window',
      () {
        fakeAsync((async) {
          const exhausted = OpusUsage(isNegative: true);
          final app = _App(
            async,
            auth: _account('A', validated: 100, usage: exhausted),
          )..usage = exhausted;
          expect(recheck(app, v5), isNotNull);
          async.flushMicrotasks();
          expect(recheck(app, v5), isNull);
          app.usage = const OpusUsage(percent: 50);
          app.click();
          async.flushMicrotasks();
          expect(app.requests, hasLength(2));
          expect(
            v5(app.container.read(subscriptionNotifierProvider).subscription),
            0,
          );
          app.dispose();
        });
      },
    );

    test(
      'exhausted price cache is scoped to the authenticated session, even when switching back before an old answer',
      () {
        fakeAsync((async) {
          const exhausted = OpusUsage(isNegative: true);
          final app = _App(
            async,
            auth: _account('A', validated: 100, usage: exhausted),
          )..usage = exhausted;
          final old = Completer<void>();
          app.hold = old;
          expect(recheck(app, v5), isNotNull);
          async.flushMicrotasks();
          app.auth(_account('B', validated: 200, usage: exhausted));
          app.hold = null;
          expect(recheck(app, v5), isNotNull);
          async.flushMicrotasks();
          expect(app.requests, hasLength(2));
          expect(recheck(app, v5), isNull);
          app.auth(_signedOut);
          app.auth(_account('A', validated: 300, usage: exhausted));
          app.balance = 300;
          expect(recheck(app, v5), isNotNull);
          async.flushMicrotasks();
          expect(app.requests, hasLength(3));
          app.balance = 999;
          app.usage = const OpusUsage(percent: 80);
          old.complete();
          async.flushMicrotasks();
          expect(app.shown, 300);
          expect(
            v5(app.container.read(subscriptionNotifierProvider).subscription),
            30,
          );
          expect(recheck(app, v5), isNull);
          app.dispose();
        });
      },
    );

    test('asks nothing for an account that is not Opus', () {
      fakeAsync((async) {
        final app = _App(
          async,
          auth: AuthState(
            status: AuthStatus.authenticated,
            accountId: 'first',
            subscriptionInfo: {
              ..._subscription(100, usage: const OpusUsage(percent: 1)),
              'tier': 2,
            },
          ),
        );
        expect(recheck(app, v5), isNull);
        expect(app.requests, isEmpty);
        app.dispose();
      });
    });

    test('a request already out answers it; no second one', () {
      fakeAsync((async) {
        final app = _App(
          async,
          auth: _account(
            'first',
            validated: 100,
            usage: const OpusUsage(percent: 1),
          ),
        );
        app
          ..hold = Completer<void>()
          ..usage = const OpusUsage(isNegative: true);
        app.click();
        async.flushMicrotasks();
        var done = false;
        recheck(app, v5)!.then((_) => done = true);
        async.flushMicrotasks();
        expect(done, isFalse);
        app.hold!.complete();
        app.hold = null;
        async.flushMicrotasks();
        expect(done, isTrue);
        expect(app.requests, hasLength(1));
        app.dispose();
      });
    });
  });

  test('network failures are told apart from error answers', () {
    DioException error(DioExceptionType type, {Object? cause, int? status}) =>
        DioException(
          requestOptions: _request,
          type: type,
          error: cause,
          response: status == null
              ? null
              : Response(requestOptions: _request, statusCode: status),
        );
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
    ]) {
      expect(
        isSubscriptionNetworkFailure(error(type)),
        isTrue,
        reason: '$type',
      );
    }
    expect(
      isSubscriptionNetworkFailure(
        error(DioExceptionType.unknown, cause: const SocketException('x')),
      ),
      isTrue,
    );
    for (final status in [401, 402, 404, 429, 503]) {
      expect(
        isSubscriptionNetworkFailure(
          error(DioExceptionType.badResponse, status: status),
        ),
        isFalse,
        reason: '$status',
      );
    }
    expect(
      isSubscriptionNetworkFailure(error(DioExceptionType.cancel)),
      isFalse,
    );
  });
}
