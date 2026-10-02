import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/account_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_toggle.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/shortcut_settings_panel.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/settings/account_subscription_summary.dart';
import 'package:nai_launcher/presentation/widgets/auth/subscription_expiry_text.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_binding_editor.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'model_management_section_test.dart' as harness;
import 'settings_round_widgets_test.dart' show MemoryShortcuts;

final _expiry =
    DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch ~/ 1000;
final _accounts = [
  SavedAccount(
    id: 'current',
    email: 'fixture',
    nickname: '鳄鱼',
    createdAt: DateTime(2026),
    isDefault: true,
    subscriptionExpiresAt: _expiry,
  ),
  SavedAccount(
    id: 'other',
    email: 'fixture-other',
    nickname: 'PD',
    createdAt: DateTime(2026),
    subscriptionExpiresAt:
        DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch ~/
        1000,
  ),
];

class _Accounts extends AccountManagerNotifier {
  _Accounts(this.seed);
  final List<SavedAccount> seed;
  @override
  AccountManagerState build() => AccountManagerState(accounts: seed);
  @override
  Future<String?> getAccountToken(String accountId) async => 'offline-fixture';
  @override
  Future<void> setDefaultAccount(String id) async {
    state = state.copyWith(
      accounts: [
        for (final a in state.accounts) a.copyWith(isDefault: a.id == id),
      ],
    );
  }
}

class _Auth extends AuthNotifier {
  _Auth(this.initialId);
  final String? initialId;
  @override
  AuthState build() => AuthState(
    status: initialId == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated,
    accountId: initialId,
  );
  @override
  Future<bool> switchAccount(
    String accountId,
    String token, {
    String? displayName,
    required AccountType accountType,
  }) async {
    state = AuthState(status: AuthStatus.authenticated, accountId: accountId);
    return true;
  }
}

class _Subscription extends SubscriptionNotifier {
  _Subscription(this.seed);
  final SubscriptionState seed;
  @override
  SubscriptionState build() {
    final id = ref.watch(authNotifierProvider).accountId;
    return id == 'current'
        ? seed
        : const SubscriptionState.error('offline-fixture');
  }
}

void main() {
  final capture = GlobalKey();
  final capturing = Platform.environment['CAPTURE_SETTINGS_LAYOUT'] == '1';
  final dark = Platform.environment['STUDIO_APPEARANCE'] == 'dark';
  setUpAll(() async {
    if (!capturing) return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool shortcuts = false,
    Size size = const Size(1040, 820),
    double scale = 1,
    List<SavedAccount>? accounts,
    String? accountId = 'current',
    SubscriptionState? subscription,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = harness.MemorySettings()
      ..values[StorageKeys.settingsFontScale] = scale;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          shortcutStorageProvider.overrideWithValue(MemoryShortcuts()),
          accountManagerNotifierProvider.overrideWith(
            () => _Accounts(accounts ?? _accounts),
          ),
          authNotifierProvider.overrideWith(() => _Auth(accountId)),
          subscriptionNotifierProvider.overrideWith(
            () => _Subscription(
              subscription ??
                  SubscriptionState.loaded(
                    UserSubscription(
                      tier: 3,
                      active: true,
                      expiresAt: _expiry,
                      trainingStepsLeft: const TrainingStepsInfo(
                        fixedTrainingStepsLeft: 2678,
                      ),
                    ),
                  ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: settingsUiTheme(
            AppTheme.getTheme(
              AppStyle.geist,
              dark ? Brightness.dark : Brightness.light,
              fontConfig: FontConfig.defaultFont,
            ),
          ),
          builder: (context, child) => SettingsTypographyScope(
            child: RepaintBoundary(key: capture, child: child!),
          ),
          home: Scaffold(
            body: shortcuts
                ? Builder(
                    builder: (context) => TextButton(
                      onPressed: () => ShortcutSettingsPanel.show(context),
                      child: const Text('打开快捷键'),
                    ),
                  )
                : const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'NovelAI 账号',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 24),
                          AccountSettingsSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    if (shortcuts) {
      await tester.tap(find.text('打开快捷键'));
      await tester.pumpAndSettle();
    }
    return container;
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!capturing) return;
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('.dart_tool/settings-layout-captures')
        ..createSync(recursive: true);
      File(
        '${folder.path}/$name-${dark ? 'dark' : 'light'}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final spec in [
    (const Size(1040, 820), 1.0, 'wide'),
    (const Size(400, 760), 1.3, 'narrow'),
  ]) {
    testWidgets(
      'account C fits ${spec.$3} and keeps credentials and preferences usable',
      (tester) async {
        final container = await pump(tester, size: spec.$1, scale: spec.$2);
        final current = find.byKey(const ValueKey('settings-account-current'));
        expect(
          find.descendant(of: current, matching: find.text('鳄鱼')),
          findsOneWidget,
        );
        expect(find.byType(AccountSubscriptionSummary), findsOneWidget);
        expect(
          find.descendant(
            of: current,
            matching: find.byType(SubscriptionExpiryText),
          ),
          findsOneWidget,
        );
        await snap(tester, 'account-C-${spec.$3}');
        final update = find.byKey(
          const Key('settings-account-update-credentials'),
        );
        await tester.ensureVisible(update);
        await tester.pumpAndSettle();
        await tester.tap(update);
        await tester.pumpAndSettle();
        expect(find.text('更新登录凭据'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('settings-account-credential')),
              )
              .controller!
              .text,
          isEmpty,
        );
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        final pref = find.byKey(const Key('settings-default-account'));
        await tester.ensureVisible(pref);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('PD').last);
        await tester.pumpAndSettle();
        expect(
          container
              .read(accountManagerNotifierProvider.notifier)
              .defaultAccount
              ?.id,
          'other',
        );
        expect(container.read(authNotifierProvider).accountId, 'current');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'shortcut C fits ${spec.$3}, categories and global search work',
      (tester) async {
        final container = await pump(
          tester,
          shortcuts: true,
          size: spec.$1,
          scale: spec.$2,
        );
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        final theme = Theme.of(
          tester.element(find.byType(ShortcutSettingsPanel)),
        );
        expect(
          (theme.dialogTheme.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(6),
        );
        expect(dialog.clipBehavior, Clip.antiAlias);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('shortcut-display-tooltips')))
              .left,
          tester.getRect(find.byType(TextField)).left,
        );
        await snap(tester, 'shortcuts-C-${spec.$3}');
        await tester.tap(find.byKey(const ValueKey('shortcut-display-menus')));
        await tester.pumpAndSettle();
        expect(
          container
              .read(shortcutConfigNotifierProvider)
              .requireValue
              .showInMenus,
          isTrue,
        );
        if (spec.$3 == 'wide') {
          await tester.tap(
            find.byKey(const ValueKey('shortcut-category-generation')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('shortcut-binding-generate_image')),
            findsOneWidget,
          );
          expect(
            find.byKey(
              const ValueKey('shortcut-binding-navigate_to_generation'),
            ),
            findsNothing,
          );
          await tester.tap(
            find.byKey(const ValueKey('shortcut-category-global')),
          );
          await tester.pumpAndSettle();
        } else {
          expect(
            find.byKey(const Key('shortcut-category-compact')),
            findsOneWidget,
          );
        }
        await tester.enterText(find.byType(TextField), 'Ctrl+,');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('shortcut-binding-navigate_to_settings')),
          findsOneWidget,
        );
        final edit = find.descendant(
          of: find.byKey(
            const ValueKey('shortcut-binding-navigate_to_settings'),
          ),
          matching: find.byIcon(Icons.edit),
        );
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(find.byType(ShortcutBindingEditor), findsOneWidget);
        await tester.ensureVisible(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'no-match-fixture');
        await tester.pumpAndSettle();
        expect(find.text('未找到匹配的快捷键'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ShortcutSettingsPanel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('shortcut editor saves and reset-all restores the binding', (
    tester,
  ) async {
    final container = await pump(tester, shortcuts: true);
    await tester.enterText(find.byType(TextField), 'Ctrl+,');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ShortcutBindingEditor),
        matching: find.text('Ctrl+,'),
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.f12);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.f12);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, '保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      container
          .read(shortcutConfigNotifierProvider)
          .requireValue
          .bindings['navigate_to_settings']!
          .effectiveShortcut,
      'ctrl+shift+f12',
    );
    await tester.tap(find.text('重置全部为默认'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '重置'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(shortcutConfigNotifierProvider)
          .requireValue
          .bindings['navigate_to_settings']!
          .effectiveShortcut,
      'ctrl+comma',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'auto-login preference persists when revisiting the account page',
    (tester) async {
      await pump(tester);
      await tester.ensureVisible(
        find.byKey(const Key('settings-account-auto-login')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SettingsToggle));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool(
          AuthNotifier.autoLoginPreferenceKey,
        ),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await pump(tester);
      expect(
        tester.widget<SettingsToggle>(find.byType(SettingsToggle)).value,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final grace in [false, true]) {
    testWidgets(
      'expired and grace subscriptions keep correct status, grace=$grace',
      (tester) async {
        await pump(
          tester,
          subscription: SubscriptionState.loaded(
            UserSubscription(
              tier: 3,
              active: false,
              isGracePeriod: grace,
              expiresAt:
                  DateTime.now()
                      .subtract(const Duration(days: 2))
                      .millisecondsSinceEpoch ~/
                  1000,
            ),
          ),
        );
        final current = find.byKey(const ValueKey('settings-account-current'));
        expect(
          find.descendant(of: current, matching: find.text('Opus')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: current,
            matching: find.byType(SubscriptionExpiryText),
          ),
          findsOneWidget,
        );
        final status = find.descendant(
          of: current,
          matching: find.text(grace ? '宽限期' : '已过期'),
        );
        expect(status, findsOneWidget);
        expect(
          tester.widget<Text>(status).style?.color,
          grace
              ? Colors.orange
              : Theme.of(tester.element(current)).colorScheme.error,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final state in [
    const SubscriptionState.loading(),
    const SubscriptionState.error('fixture'),
    const SubscriptionState.loaded(UserSubscription(tier: 0)),
  ]) {
    testWidgets(
      'account handles ${state.runtimeType} without fictional balance or stale expiry',
      (tester) async {
        await pump(tester, subscription: state);
        expect(find.byType(AccountSubscriptionSummary), findsOneWidget);
        expect(
          find.byKey(const Key('settings-account-update-credentials')),
          findsOneWidget,
        );
        final current = find.byKey(const ValueKey('settings-account-current'));
        expect(
          find.descendant(
            of: current,
            matching: find.byType(SubscriptionExpiryText),
          ),
          findsNothing,
        );
        if (!state.isLoaded) expect(find.textContaining('2,678'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'switch changes the expanded account and cannot show previous account balance',
    (tester) async {
      final container = await pump(tester);
      await tester.tap(
        find.byKey(const ValueKey('settings-account-switch-other')),
      );
      await tester.pumpAndSettle();
      expect(container.read(authNotifierProvider).accountId, 'other');
      expect(find.byType(AccountSubscriptionSummary), findsOneWidget);
      expect(find.textContaining('2,678'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('settings-account-other')),
          matching: find.byKey(
            const Key('settings-account-update-credentials'),
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty signed-out account page retains sign-in and auto-login preferences',
    (tester) async {
      await pump(tester, accounts: [], accountId: null);
      expect(find.byType(AccountSubscriptionSummary), findsNothing);
      expect(find.text('尚未登录'), findsOneWidget);
      expect(find.text('启动时自动登录'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await snap(tester, 'account-C-empty');
    },
  );

  testWidgets(
    'short shortcut window retains scrollable controls and category picker',
    (tester) async {
      await pump(
        tester,
        shortcuts: true,
        size: const Size(480, 420),
        scale: 1.3,
      );
      expect(
        find.byKey(const Key('shortcut-category-compact')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await snap(tester, 'shortcuts-C-short');
    },
  );
}
