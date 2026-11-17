import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/widgets/auth/third_party_api_login_card.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Auth extends AuthNotifier {
  final requests = <({String token, NaiApiEndpointConfig endpoint})>[];

  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  void clearError({int delayMs = 100}) {}

  @override
  Future<bool> loginWithThirdPartyToken(
    String token, {
    required NaiApiEndpointConfig apiEndpoint,
    String? accountId,
    String? displayName,
  }) async {
    requests.add((token: token, endpoint: apiEndpoint));
    ref
        .read(naiApiEndpointServiceProvider)
        .setCurrent(
          NaiApiEndpointConfig.fromInput(
            mainBaseUrl: 'https://gateway.invalid/v1/novelai',
          ),
        );
    return true;
  }
}

class _Accounts extends AccountManagerNotifier {
  NaiApiEndpointConfig? savedEndpoint;
  String? savedToken;

  @override
  AccountManagerState build() => const AccountManagerState();

  @override
  Future<SavedAccount> addAccount({
    required String identifier,
    required String token,
    required String nickname,
    bool setAsDefault = false,
    AccountType accountType = AccountType.token,
    NaiApiEndpointConfig apiEndpoint = NaiApiEndpointConfig.official,
  }) async {
    savedEndpoint = apiEndpoint;
    savedToken = token;
    return SavedAccount(
      id: 'fixture',
      email: identifier,
      nickname: nickname,
      createdAt: DateTime(2026),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Auth auth,
  _Accounts accounts, {
  Locale locale = const Locale('zh'),
  double width = 420,
  VoidCallback? onSuccess,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(loadStudioCaptureFonts);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => auth),
        accountManagerNotifierProvider.overrideWith(() => accounts),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ThirdPartyApiLoginCard(onLoginSuccess: onSuccess),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pasted connection JSON saves the verified path and raw key', (
    tester,
  ) async {
    final auth = _Auth(), accounts = _Accounts();
    var success = false;
    await _pump(tester, auth, accounts, onSuccess: () => success = true);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), 'Offline gateway');
    await tester.enterText(
      fields.at(3),
      '{"_type":"newapi_channel_conn","url":"https://gateway.invalid","key":"sk-offline-fixture"}',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(auth.requests, hasLength(2));
    expect(auth.requests.first.endpoint.mainBaseUrl, 'https://gateway.invalid');
    expect(
      accounts.savedEndpoint?.mainBaseUrl,
      'https://gateway.invalid/v1/novelai',
    );
    expect(auth.requests.last.endpoint, accounts.savedEndpoint);
    expect(accounts.savedToken, 'sk-offline-fixture');
    expect(success, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'malformed connection JSON stays a form error without a request',
    (tester) async {
      final auth = _Auth(), accounts = _Accounts();
      await _pump(tester, auth, accounts);
      await tester.enterText(find.byType(TextField).at(3), '{invalid');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ThirdPartyApiLoginCard)),
      )!;
      expect(find.text(l10n.auth_connectionImportInvalid), findsOneWidget);
      expect(auth.requests, isEmpty);
      expect(accounts.savedToken, isNull);
    },
  );

  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final width in [320.0, 480.0]) {
      testWidgets('compatibility hint fits $locale at $width', (tester) async {
        await _pump(tester, _Auth(), _Accounts(), locale: locale, width: width);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
