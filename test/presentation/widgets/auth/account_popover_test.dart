import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/settings_navigation_provider.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/auth/account_popover.dart';
import 'package:nai_launcher/presentation/widgets/auth/login_form_container.dart';
import 'package:nai_launcher/presentation/widgets/navigation/main_nav_rail.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Shell extends Mock implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_Shell';
}

class _Storage extends LocalStorageService {
  @override
  bool getMainNavRailExpanded() => false;
}

class _Accounts extends AccountManagerNotifier {
  _Accounts(this.accounts);
  final List<SavedAccount> accounts;
  final List<String> tokenReads = [];
  @override
  AccountManagerState build() => AccountManagerState(accounts: accounts);
  @override
  Future<String?> getAccountToken(String id) async {
    tokenReads.add(id);
    return 'offline-test-token';
  }

  void replace(List<SavedAccount> accounts) =>
      state = state.copyWith(accounts: accounts);
}

class _Auth extends AuthNotifier {
  _Auth(this.initial);
  final AuthState initial;
  final List<String> switches = [];
  int logouts = 0;
  @override
  AuthState build() => initial;
  void replace(AuthState value) => state = value;
  @override
  Future<bool> switchAccount(
    String id,
    String token, {
    String? displayName,
    required AccountType accountType,
  }) async {
    switches.add(id);
    state = AuthState(
      status: AuthStatus.authenticated,
      accountId: id,
      displayName: displayName,
    );
    return true;
  }

  @override
  Future<void> logout({AuthErrorCode? errorCode, int? httpStatusCode}) async {
    logouts++;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _Updates extends UpdateStateNotifier {
  @override
  UpdateState build() => const UpdateState();
}

SavedAccount _account(String id, String name, {int? expiry}) => SavedAccount(
  id: id,
  email: '$id@example.test',
  nickname: name,
  createdAt: DateTime(2026),
  subscriptionExpiresAt: expiry,
);

void main() {
  setUpAll(() async {
    if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final boundary = GlobalKey();
  late _Auth auth;
  late _Accounts accounts;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    bool dark = false,
    Size size = const Size(640, 760),
    List<SavedAccount>? saved,
    AuthState? session,
    Locale locale = const Locale('zh'),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    accounts = _Accounts(
      saved ??
          [
            _account('pd', 'PD', expiry: 0),
            _account(
              'fish',
              '鳄鱼',
              expiry:
                  DateTime.now()
                      .add(const Duration(days: 4))
                      .millisecondsSinceEpoch ~/
                  1000,
            ),
          ],
    );
    auth = _Auth(
      session ??
          const AuthState(status: AuthStatus.authenticated, accountId: 'pd'),
    );
    final shell = _Shell();
    when(() => shell.currentIndex).thenReturn(0);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Row(
              children: [
                MainNavRail(navigationShell: shell),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('account-settings-route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Storage()),
          authNotifierProvider.overrideWith(() => auth),
          accountManagerNotifierProvider.overrideWith(() => accounts),
          updateStateProvider.overrideWith(_Updates.new),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              RepaintBoundary(key: boundary, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MainNavRail)),
    );
    await tester.tap(find.byKey(const Key('main-nav-avatar')));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/account-popover-captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
      'approved panel, current identity, live updates and keyboard switch; dark=$dark',
      (tester) async {
        final previous = debugDisableShadows;
        addTearDown(() => debugDisableShadows = previous);
        if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
          debugDisableShadows = false;
        }
        await pump(tester, dark: dark);
        expect(
          find.byKey(const ValueKey('account-popover-switch-pd')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('account-popover-switch-fish')),
          findsOneWidget,
        );
        expect(find.text('订阅已到期'), findsOneWidget);
        expect(find.text('当前'), findsOneWidget);
        expect(find.textContaining('1970'), findsNothing);
        expect(
          tester.getSize(find.byKey(const Key('main-nav-avatar'))),
          const Size(40, 40),
        );
        expect(
          tester.getTopLeft(find.byKey(const Key('account-popover'))),
          const Offset(56, 8),
        );
        expect(
          tester.getSize(find.byKey(const Key('account-popover'))).width,
          314,
        );
        await capture(tester, '${dark ? 'dark' : 'light'}-panel');
        accounts.replace([
          accounts.accounts.first,
          accounts.accounts.last.copyWith(nickname: '新昵称'),
        ]);
        await tester.pumpAndSettle();
        expect(find.text('新昵称'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(accounts.tokenReads, ['fish']);
        expect(auth.switches, ['fish']);
        expect(container.read(authNotifierProvider).accountId, 'fish');
        expect(find.byType(AccountPopover), findsNothing);
        expect(tester.takeException(), isNull);
        debugDisableShadows = previous;
      },
    );
  }

  testWidgets('manage opens the account settings route', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('account-popover-manage')));
    await tester.pumpAndSettle();
    expect(find.text('account-settings-route'), findsOneWidget);
    expect(container.read(settingsAccountOpenRequestProvider), 1);
    expect(accounts.tokenReads, isEmpty);
  });

  testWidgets('logout runs after dismissal', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('account-popover-logout')));
    await tester.pumpAndSettle();
    expect(auth.logouts, 1);
    expect(find.byType(AccountPopover), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'add opens the existing login dialog without changing the current account',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('account-popover-add')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginFormContainer), findsOneWidget);
      expect(find.byType(AccountPopover), findsNothing);
      expect(container.read(authNotifierProvider).accountId, 'pd');
      expect(accounts.tokenReads, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('outside click and Escape dismiss without account writes', (
    tester,
  ) async {
    await pump(tester);
    await tester.tapAt(const Offset(610, 650));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPopover), findsNothing);
    await tester.tap(find.byKey(const Key('main-nav-avatar')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AccountPopover), findsNothing);
    expect(auth.logouts, 0);
    expect(auth.switches, isEmpty);
  });

  testWidgets(
    'saved accounts in guest mode are available and never marked current',
    (tester) async {
      await pump(
        tester,
        session: const AuthState(status: AuthStatus.unauthenticated),
      );
      expect(find.text('尚未登录'), findsOneWidget);
      expect(find.text('当前'), findsNothing);
      expect(
        find.byKey(const ValueKey('account-popover-switch-pd')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('account-popover-switch-pd')));
      await tester.pumpAndSettle();
      expect(auth.switches, ['pd']);
    },
  );

  testWidgets('an account with a failed session can be selected again', (
    tester,
  ) async {
    await pump(
      tester,
      session: const AuthState(
        status: AuthStatus.error,
        accountId: 'pd',
        errorCode: AuthErrorCode.authFailed,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('account-popover-switch-pd')));
    await tester.pumpAndSettle();
    expect(auth.switches, ['pd']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an account removed during dismissal is not used from a stale menu',
    (tester) async {
      await pump(tester);
      await tester.tap(
        find.byKey(const ValueKey('account-popover-switch-fish')),
      );
      accounts.replace([accounts.accounts.first]);
      await tester.pumpAndSettle();
      expect(accounts.tokenReads, isEmpty);
      expect(auth.switches, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switch controls are disabled while authentication is pending', (
    tester,
  ) async {
    await pump(tester);
    auth.replace(const AuthState(status: AuthStatus.loading, accountId: 'pd'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-popover-switch-fish')));
    await tester.tap(find.byKey(const Key('account-popover-add')));
    await tester.tap(find.byKey(const Key('account-popover-logout')));
    await tester.pumpAndSettle();
    expect(auth.switches, isEmpty);
    expect(auth.logouts, 0);
    expect(find.byType(AccountPopover), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'long names, many accounts and short windows remain usable; $locale',
      (tester) async {
        await pump(
          tester,
          locale: locale,
          size: const Size(390, 360),
          saved: [
            _account('pd', '很长的账号昵称 A long account display name'),
            for (var i = 0; i < 12; i++)
              _account('saved-$i', '备用账号 $i · Long display name'),
          ],
        );
        final rect = tester.getRect(find.byKey(const Key('account-popover')));
        expect(rect.left, greaterThanOrEqualTo(8));
        expect(rect.right, lessThanOrEqualTo(382));
        expect(rect.bottom, lessThanOrEqualTo(352));
        expect(
          find.byKey(const Key('account-popover-add')).hitTestable(),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('account-popover-switch-saved-11')),
          130,
          scrollable: find
              .descendant(
                of: find.byType(AccountPopover),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        if (locale.languageCode == 'zh') {
          await capture(tester, 'short-many-long-names');
        }
        await tester.tap(
          find.byKey(const ValueKey('account-popover-switch-saved-11')),
        );
        await tester.pumpAndSettle();
        expect(auth.switches, ['saved-11']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty accounts in a very short window can reach all actions', (
    tester,
  ) async {
    await pump(
      tester,
      size: const Size(320, 240),
      saved: [],
      session: const AuthState(status: AuthStatus.unauthenticated),
    );
    await tester.ensureVisible(find.byKey(const Key('account-popover-manage')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('account-popover-manage')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
