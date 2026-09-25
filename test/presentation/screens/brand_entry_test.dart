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
import 'package:nai_launcher/core/services/titlebar_region_service.dart';
import '../../helpers/light_theme_contrast.dart';
import 'package:nai_launcher/presentation/widgets/auth/entry_controls.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_entry_scene.dart';
import 'package:nai_launcher/presentation/widgets/branding/entry_field.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

import '../../helpers/studio_capture_fonts.dart';

class _Auth extends AuthNotifier {
  _Auth([this.initial = const AuthState(status: AuthStatus.unauthenticated)]);
  final AuthState initial;
  @override
  AuthState build() => initial;
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
  AuthState auth = const AuthState(status: AuthStatus.unauthenticated),
  Locale locale = const Locale('zh'),
  double textScale = 1,
  WarmupState warmup = const WarmupState(
    progress: WarmupProgress(progress: .42, currentTask: 'warmup_fonts'),
  ),
  // 打开动画时字符场一直在走，不能 pumpAndSettle，改为推进固定时长
  bool animate = false,
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
        authNotifierProvider.overrideWith(() => _Auth(auth)),
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
              // 字符场在“关闭动画”时只画一帧静态画面，测试才能 settle
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
                disableAnimations: !animate,
              ),
              child: IntegratedTitleBarShell(
                immersive: true,
                onToggleTheme: () =>
                    ref.read(themeNotifierProvider.notifier).nextTheme(),
                child: splash ? const SplashScreen() : const LoginScreen(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> settle() => animate
      ? tester.pump(const Duration(seconds: 1))
      : tester.pumpAndSettle();
  await settle();
  // Asset decoding uses real asynchronous IO in flutter_test.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(BrandLogo));
    await precacheImage(
      const AssetImage('assets/images/wof_logo_full.png'),
      context,
    );
  });
  await settle();
  return key;
}

double logoTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(BrandLogo)).dy;

/// Logo + 标语 + 卡片整体的中心落在视区高度 45% 处（视觉中心）。
void expectOpticallyCentered(WidgetTester tester) {
  final viewport = tester.getRect(find.byKey(const Key('brand_entry_scroll')));
  final hero = tester.getRect(
    find
        .ancestor(of: find.byType(BrandLogo), matching: find.byType(Column))
        .first,
  );
  expect(
    (hero.center.dy - viewport.top) / viewport.height,
    moreOrLessEquals(.45, epsilon: .002),
  );
}

/// 首次登录：点「登录」按钮展开成表单卡。
Future<void> expandFirstRun(WidgetTester tester) async {
  final start = find.byKey(const Key('auth_start_login'));
  await tester.ensureVisible(start);
  await tester.tap(start);
  await tester.pumpAndSettle();
}

SavedAccount _account(String id, String nickname, {DateTime? lastUsed}) =>
    SavedAccount(
      id: id,
      email: '$id@example.invalid',
      nickname: nickname,
      createdAt: DateTime(2026),
      lastUsedAt: lastUsed,
    );

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
    testWidgets(
      'login and splash share the entry scene in ${brightness.name}',
      (tester) async {
        var key = await pumpEntry(tester, brightness: brightness);
        expect(find.byType(BrandLogo), findsOneWidget);
        expect(find.byType(EntryField), findsOneWidget);
        // 首次登录先只有一颗按钮，表单收着
        expect(
          find.byKey(const Key('auth_start_login')).hitTestable(),
          findsOneWidget,
        );
        expect(find.byType(TextField).first.hitTestable(), findsNothing);
        expectOpticallyCentered(tester);
        final startTop = logoTop(tester);
        await capture(tester, key, 'login-start-${brightness.name}');

        await expandFirstRun(tester);
        expect(find.byType(TextField).first.hitTestable(), findsOneWidget);
        if (TitleBarRegionService.isSupported) {
          // 登录页标题栏收成页面底色，不再显示 Logo 标题
          expect(
            find.byKey(const ValueKey('immersive_title_bar')),
            findsOneWidget,
          );
          expect(find.text('NAI Studio'), findsNothing);
        }
        final buttonLabel = find.text('验证并登录');
        expect(
          DefaultTextStyle.of(tester.element(buttonLabel)).style.color,
          Colors.white,
        );
        expectOpticallyCentered(tester);
        final formTop = logoTop(tester);
        expect(formTop, lessThan(startTop - 100));
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'login-${brightness.name}');

        await tester.pumpWidget(const SizedBox());
        key = await pumpEntry(tester, brightness: brightness, splash: true);
        expect(find.text('42%'), findsOneWidget);
        expect(
          tester
              .widget<BootProgressBar>(
                find.byKey(const Key('brand_warmup_progress')),
              )
              .value,
          .42,
        );
        // 进度区比表单矮，整体仍在视觉中心，Logo 因此低一些
        expectOpticallyCentered(tester);
        expect(logoTop(tester), greaterThan(formTop));
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'splash-${brightness.name}');
      },
    );
  }

  testWidgets('appearance preserves entered values and guest entry works', (
    tester,
  ) async {
    final key = await pumpEntry(tester);
    await expandFirstRun(tester);
    await tester.enterText(find.byType(TextField).first, '我的工作室');
    await tester.enterText(
      find.byType(TextField).last,
      'test-only-placeholder',
    );
    await tester.tap(find.byKey(const Key('brand_appearance_toggle')));
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
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
  });

  testWidgets('empty token shows inline validation instead of submitting', (
    tester,
  ) async {
    await pumpEntry(tester);
    await expandFirstRun(tester);
    await tester.tap(find.text('验证并登录'));
    await tester.pumpAndSettle();
    expect(find.text('请输入昵称'), findsOneWidget);
    expect(find.text('请输入 Token'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
        await expandFirstRun(tester);
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

  testWidgets('first run: the login button opens into the form and back', (
    tester,
  ) async {
    await pumpEntry(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LoginScreen)),
    );
    // 表单是否可用看第一个输入框能否点到
    final form = find.byType(TextField).first;

    // 回车展开，光标落在第一个输入框
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(form.hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.enterText(find.byType(TextField).first, '我的工作室');

    // Esc 收起，再展开时输入还在
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(form.hitTestable(), findsNothing);
    expect(
      find.byKey(const Key('auth_start_login')).hitTestable(),
      findsOneWidget,
    );
    await expandFirstRun(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '我的工作室',
    );

    // 「返回」同样收起；收起时 SKIP 就在按钮下方
    await tester.tap(find.byKey(const Key('auth_back')));
    await tester.pumpAndSettle();
    expect(form.hitTestable(), findsNothing);
    expectOpticallyCentered(tester);
    await tester.tap(find.byKey(const Key('auth_guest_entry_start')));
    await tester.pump();
    expect(container.read(guestSessionNotifierProvider), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the login button grows into the card around its centre', (
    tester,
  ) async {
    await pumpEntry(tester, animate: true);
    final card = find.byKey(const ValueKey('entry_card_first'));
    final startTop = logoTop(tester);
    final startHeight = tester.getSize(card).height;

    await tester.tap(find.byKey(const Key('auth_start_login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // 长到一半：卡片在变高，整体一直保持在视觉中心
    final midHeight = tester.getSize(card).height;
    expect(midHeight, greaterThan(startHeight + 40));
    expectOpticallyCentered(tester);
    expect(logoTop(tester), lessThan(startTop));

    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getSize(card).height, greaterThan(midHeight));
    expectOpticallyCentered(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.getSize(card).height, moreOrLessEquals(startHeight));
    expect(logoTop(tester), moreOrLessEquals(startTop, epsilon: .01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'saved accounts: selector, inline list, add form and guest entry '
      '(${brightness.name})',
      (tester) async {
        final key = await pumpEntry(
          tester,
          brightness: brightness,
          accounts: [
            _account('main', '我的创作空间', lastUsed: DateTime(2026, 9)),
            _account('alt', '工作室副号'),
          ],
        );
        // 最近使用的账号排在最前、作为当前账号
        expect(find.text('我的创作空间'), findsOneWidget);
        expect(find.text('NovelAI · Token'), findsOneWidget);
        expect(find.byKey(const Key('auth_quick_login')), findsOneWidget);
        // 矮卡片也整体居中
        expectOpticallyCentered(tester);
        final quickTop = logoTop(tester);
        await capture(tester, key, 'login-saved-${brightness.name}');

        // 账号列表在卡片内展开，点选只切换当前账号；展开只向下延伸
        await tester.tap(find.byKey(const Key('auth_account_selector')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('auth_account_alt')), findsOneWidget);
        expect(logoTop(tester), quickTop);
        await capture(tester, key, 'login-saved-list-${brightness.name}');
        await tester.tap(find.byKey(const ValueKey('auth_account_alt')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('auth_account_alt')), findsNothing);
        expect(find.text('工作室副号'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LoginScreen)),
        );
        expect(container.read(authNotifierProvider).isLoading, isFalse);

        // 添加账号在卡片内切到表单，可返回
        await tester.tap(find.byKey(const Key('auth_add_account')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('token_form')), findsOneWidget);
        // 换成高卡片后整体上移，重新居中
        expectOpticallyCentered(tester);
        expect(logoTop(tester), lessThan(quickTop - 40));
        await capture(tester, key, 'login-add-${brightness.name}');
        await tester.tap(find.byKey(const Key('auth_back')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('auth_quick_login')), findsOneWidget);
        expect(logoTop(tester), quickTop);

        final guest = find.byKey(const Key('auth_guest_entry_quick_login'));
        await tester.tap(guest);
        await tester.pump();
        expect(container.read(guestSessionNotifierProvider), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('switching cards glides the logo to the new optical centre', (
    tester,
  ) async {
    await pumpEntry(tester, accounts: [_account('main', 'PD')], animate: true);
    final quickTop = logoTop(tester);
    expectOpticallyCentered(tester);

    await tester.tap(find.byKey(const Key('auth_add_account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final midway = logoTop(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final formTop = logoTop(tester);
    expect(formTop, lessThan(quickTop - 40));
    expect(midway, lessThan(quickTop));
    expect(midway, greaterThan(formTop));
    expectOpticallyCentered(tester);

    await tester.tap(find.byKey(const Key('auth_back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(logoTop(tester), moreOrLessEquals(quickTop, epsilon: .01));
    expect(tester.takeException(), isNull);
    // 停掉一直在走的字符场
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('quick login failure is shown inside the card', (tester) async {
    final key = await pumpEntry(
      tester,
      accounts: [_account('main', 'PD')],
      auth: const AuthState(
        status: AuthStatus.error,
        errorCode: AuthErrorCode.networkError,
      ),
    );
    expect(find.byType(EntryAlert), findsOneWidget);
    expect(find.text('查看故障排除提示'), findsOneWidget);
    await capture(tester, key, 'login-saved-error');
    expect(tester.takeException(), isNull);
  });

  testWidgets('logging in keeps the button blue with a busy label', (
    tester,
  ) async {
    final key = await pumpEntry(
      tester,
      accounts: [_account('main', 'PD')],
      auth: const AuthState(status: AuthStatus.loading),
    );
    expect(find.text('登录中...'), findsOneWidget);
    expect(find.byType(EntryBusyDots), findsOneWidget);
    await capture(tester, key, 'login-saved-busy');
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
