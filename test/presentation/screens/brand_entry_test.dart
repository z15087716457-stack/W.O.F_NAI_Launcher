import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/app_version.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/guest_session_provider.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/providers/warmup_provider.dart';
import 'package:nai_launcher/presentation/screens/auth/login_screen.dart';
import 'package:nai_launcher/presentation/screens/splash/splash_screen.dart';
import 'package:nai_launcher/presentation/providers/theme_provider.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import '../../helpers/light_theme_contrast.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_entry_scene.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

import '../../helpers/studio_capture_fonts.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _Accounts extends AccountManagerNotifier {
  _Accounts(this.accounts);
  final List<SavedAccount> accounts;
  @override
  AccountManagerState build() => AccountManagerState(accounts: accounts);
}

class _Updates extends UpdateStateNotifier {
  @override
  UpdateState build() => const UpdateState();
}

class _Warmup extends WarmupNotifier {
  _Warmup(this.initial);
  final WarmupState initial;
  @override
  WarmupState build() => initial;
  void complete() => state = WarmupState.complete();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final file = File('.dart_tool/brand-entry-captures/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Future<GlobalKey> pumpEntry(
  WidgetTester tester, {
  Size size = const Size(1280, 960),
  Brightness brightness = Brightness.dark,
  bool splash = false,
  List<SavedAccount> accounts = const [],
  Locale locale = const Locale('zh'),
  double textScale = 1,
  WarmupState warmup = const WarmupState(
    progress: WarmupProgress(progress: .42, currentTask: 'warmup_fonts'),
  ),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  final storage = InMemoryLocalStorageService();
  await storage.setStudioThemeMode(brightness.name);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        accountManagerNotifierProvider.overrideWith(() => _Accounts(accounts)),
        updateStateProvider.overrideWith(_Updates.new),
        localStorageServiceProvider.overrideWithValue(storage),
        warmupNotifierProvider.overrideWith(() => _Warmup(warmup)),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: ref.watch(studioLightThemeProvider),
          darkTheme: ref.watch(studioDarkThemeProvider),
          themeMode: ref.watch(themeNotifierProvider) == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
              ),
              child: IntegratedTitleBarShell(
                child: splash ? const SplashScreen() : const LoginScreen(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Asset decoding uses real asynchronous IO in flutter_test.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(BrandLogo));
    await precacheImage(
      const AssetImage('assets/images/wof_logo_full.png'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/images/wof_logo_block.png'),
      context,
    );
  });
  await tester.pumpAndSettle();
  return key;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    PackageInfo.setMockInitialValues(
      appName: 'W.O.F NAI Studio',
      packageName: 'nai_launcher',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppVersion.initialize();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final brightness in Brightness.values) {
    testWidgets('real login and splash render in ${brightness.name}', (
      tester,
    ) async {
      var key = await pumpEntry(tester, brightness: brightness);
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byKey(const Key('token_form')), findsOneWidget);
      final buttonLabel = find.text('验证并登录');
      expect(
        DefaultTextStyle.of(tester.element(buttonLabel)).style.color,
        Colors.white,
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.login))).color,
        Colors.white,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      await capture(tester, key, 'login-${brightness.name}');
      await tester.pumpWidget(const SizedBox());
      key = await pumpEntry(tester, brightness: brightness, splash: true);
      expect(find.text('42%'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('brand_warmup_progress')),
            )
            .value,
        .42,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'splash-${brightness.name}');
    });
  }

  testWidgets(
    'appearance preserves entered values and guest entry still works',
    (tester) async {
      final key = await pumpEntry(tester);
      await tester.enterText(find.byType(TextFormField).first, '我的工作室');
      await tester.enterText(
        find.byType(TextFormField).last,
        'test-only-placeholder',
      );
      await tester.tap(find.byKey(const Key('brand_appearance_toggle')));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields.first.controller!.text, '我的工作室');
      expect(fields.last.controller!.text, 'test-only-placeholder');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      );
      expect(container.read(themeNotifierProvider), Brightness.light);
      await capture(tester, key, 'login-light-after-switch');
      await tester.ensureVisible(find.byKey(const Key('auth_guest_entry')));
      await tester.tap(find.byKey(const Key('auth_guest_entry')));
      await tester.pump();
      expect(container.read(guestSessionNotifierProvider), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      'all forms fit narrow ${locale.languageCode} at enlarged text',
      (tester) async {
        final key = await pumpEntry(
          tester,
          size: const Size(390, 780),
          locale: locale,
          textScale: 1.25,
        );
        for (final mode in ['credentials', 'third_party', 'token']) {
          final tab = find.byKey(Key('auth_mode_$mode'));
          await tester.ensureVisible(tab);
          await tester.tap(tab);
          await tester.pumpAndSettle();
          expect(find.byKey(Key('${mode}_form')), findsOneWidget);
          await tester.ensureVisible(find.byKey(const Key('auth_guest_entry')));
          expect(tester.takeException(), isNull);
        }
        await capture(tester, key, 'login-narrow-${locale.languageCode}');
      },
    );
  }

  testWidgets('saved accounts retain selector, quick login and guest entry', (
    tester,
  ) async {
    final key = await pumpEntry(
      tester,
      accounts: [
        SavedAccount(
          id: 'preview-account',
          email: 'studio@example.invalid',
          nickname: '我的创作空间',
          createdAt: DateTime(2026),
        ),
      ],
    );
    expect(find.text('我的创作空间'), findsOneWidget);
    final guest = find.byKey(const Key('auth_guest_entry_quick_login'));
    expect(guest, findsOneWidget);
    await capture(tester, key, 'login-saved-account');
    await tester.tap(guest);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    );
    expect(container.read(guestSessionNotifierProvider), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('warmup completion updates progress without losing appearance', (
    tester,
  ) async {
    await pumpEntry(tester, splash: true, brightness: Brightness.light);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SplashScreen)),
    );
    (container.read(warmupNotifierProvider.notifier) as _Warmup).complete();
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(container.read(themeNotifierProvider), Brightness.light);
    expect(tester.takeException(), isNull);
  });
}
