import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/nav_activity_provider.dart';
import 'package:nai_launcher/presentation/providers/settings_navigation_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/router/app_branch.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_shell.dart';
import 'package:nai_launcher/presentation/wiring/nav_wiring.dart';

class _Shell extends Mock implements StatefulNavigationShell {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_Shell';
}

class _Storage extends LocalStorageService {
  final settings = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      settings[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async =>
      settings[key] = value;
}

class _Auth extends AuthNotifier {
  int logouts = 0;
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'current');
  void emit(AuthState value) => state = value;
  @override
  Future<void> logout({AuthErrorCode? errorCode, int? httpStatusCode}) async {
    logouts++;
  }
}

class _Accounts extends AccountManagerNotifier {
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [
      SavedAccount(
        id: 'current',
        email: 'current@example.test',
        nickname: 'Current',
        createdAt: DateTime(2026),
      ),
      SavedAccount(
        id: 'other',
        email: 'other@example.test',
        nickname: 'Other',
        createdAt: DateTime(2026, 2),
      ),
    ],
  );
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      trainingStepsLeft: TrainingStepsInfo(
        fixedTrainingStepsLeft: 100,
        purchasedTrainingSteps: 200,
      ),
    ),
  );
}

class _Shortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _Update extends UpdateStateNotifier {
  @override
  UpdateState build() => const UpdateState(status: UpdateStatus.available);
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void emit(ImageGenerationState value) => state = value;
}

class _Local extends LocalUpscaleTask {
  int cancellations = 0;
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState();
  void emit(LocalUpscaleTaskState value) => state = value;
  @override
  void cancel() {
    cancellations++;
    state = const LocalUpscaleTaskState(running: true, cancelling: true);
  }
}

class _Cloud extends CloudUpscaleTask {
  @override
  CloudUpscaleState build() => const CloudUpscaleState();
}

class _Bulk extends BulkOperationNotifier {
  int undos = 0;
  @override
  BulkOperationState build() => const BulkOperationState();
  void emit(BulkOperationState value) => state = value;
  @override
  Future<void> undo() async {
    undos++;
    state = state.copyWith(canUndo: false);
  }
}

class _Commands extends NavCommands {
  final switched = <String>[];
  int additions = 0;
  int logouts = 0;
  @override
  Future<void> switchAccount(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async => switched.add(id);
  @override
  void addAccount(BuildContext context, WidgetRef ref) => additions++;
  @override
  Future<void> logout(BuildContext context, WidgetRef ref) async {
    logouts++;
  }
}

void main() {
  test('the branch/page map is bijective without changing router ordinals', () {
    expect(navBranchPages.length, AppBranch.values.length);
    expect(navBranchPages.values.toSet(), NavPage.values.toSet());
    for (final branch in AppBranch.values) {
      expect(navBranchForPage(navPageForBranch(branch)), branch);
    }
    expect(
      navPageForBranch(AppBranch.promptBlockLibrary),
      NavPage.promptBlocks,
    );
    expect(navBranchForPage(NavPage.preciseRef), AppBranch.preciseRefLibrary);
  });

  test(
    'shortcut keycaps use the existing formatter and omit unbound or disabled keys',
    () {
      final config = ShortcutConfig.createDefault()
          .setCustomShortcut(
            ShortcutIds.navigateToGeneration,
            'shift+alt+ctrl+a',
          )
          .setEnabled(ShortcutIds.navigateToLocalGallery, false)
          .setCustomShortcut(ShortcutIds.navigateToTagWiki, '');
      final caps = navShortcutKeycaps(config);
      expect(caps[NavPage.generation], ['Ctrl', 'Alt', 'Shift', 'A']);
      expect(caps[NavPage.settings], ['Ctrl', ',']);
      expect(caps.containsKey(NavPage.localGallery), isFalse);
      expect(caps.containsKey(NavPage.tagWiki), isFalse);
      expect(
        navShortcutKeycaps(config.copyWith(enableShortcuts: false)),
        isEmpty,
      );
      expect(navShortcutKeycaps(null), isEmpty);
    },
  );

  test(
    'account mapping follows authenticated identity and subscription expiry semantics',
    () {
      final now = DateTime(2026, 10, 11, 12);
      SavedAccount account(
        String id,
        int days, {
        AccountType type = AccountType.token,
      }) => SavedAccount(
        id: id,
        email: '$id@example.test',
        nickname: id,
        createdAt: now,
        accountType: type,
        subscriptionExpiresAt:
            now.add(Duration(days: days)).millisecondsSinceEpoch ~/ 1000,
      );
      final data = navAccountData(
        auth: const AuthState(
          status: AuthStatus.authenticated,
          accountId: 'current',
        ),
        sortedAccounts: [
          account('soon', 2),
          account('current', 20, type: AccountType.credentials),
          account('expired', -1),
        ],
        subscription: const SubscriptionState.loaded(
          UserSubscription(
            tier: 3,
            trainingStepsLeft: TrainingStepsInfo(
              fixedTrainingStepsLeft: 10,
              purchasedTrainingSteps: 20,
            ),
          ),
        ),
        now: now,
      );
      expect(data.current!.id, 'current');
      expect(data.current!.tokenLogin, isFalse);
      expect(data.current!.subscription!.state, NavSubscriptionState.ok);
      expect(data.others.map((account) => account.id), ['soon', 'expired']);
      expect(
        data.others.first.subscription!.state,
        NavSubscriptionState.expiringSoon,
      );
      expect(
        data.others.last.subscription!.state,
        NavSubscriptionState.expired,
      );
      expect(data.anlas, 30);
      expect(data.plan, 'Opus');
      final guest = navAccountData(
        auth: const AuthState(status: AuthStatus.unauthenticated),
        sortedAccounts: [account('saved', 2)],
        subscription: const SubscriptionState.initial(),
        now: now,
      );
      expect(guest.current, isNull);
      expect(guest.others.single.id, 'saved');
      expect(guest.anlas, isNull);
      expect(guest.plan, isNull);
      final busy = navAccountData(
        auth: const AuthState(status: AuthStatus.loading),
        sortedAccounts: [],
        subscription: const SubscriptionState.initial(),
      );
      expect(busy.busy, isTrue);
    },
  );

  test(
    'running generation uses the latest stream slot and clamps progress',
    () {
      final earlier = Uint8List.fromList([1]);
      final latest = Uint8List.fromList([2]);
      final data = navGenerationData(
        ImageGenerationState(
          status: GenerationStatus.generating,
          currentImage: 2,
          totalImages: 4,
          progress: 2,
          streamPreview: earlier,
          streamPreviewSlots: [
            StreamPreviewSlot(
              imageNumber: 2,
              totalImages: 4,
              progress: .5,
              previewBytes: latest,
            ),
          ],
        ),
        null,
        visible: false,
      );
      expect(data.state, NavGenerationState.running);
      expect(data.current, 2);
      expect(data.total, 4);
      expect(data.progress, 1);
      expect((data.preview! as MemoryImage).bytes, same(latest));
      const unread = NavGenerationResult(
        status: GenerationStatus.error,
        total: 0,
        error: 'first\nsecond',
      );
      expect(
        navGenerationData(
          const ImageGenerationState(),
          unread,
          visible: false,
        ).error,
        'first',
      );
      expect(
        navGenerationData(
          const ImageGenerationState(),
          unread,
          visible: true,
        ).state,
        NavGenerationState.idle,
      );
    },
  );

  late ProviderContainer container;
  late _Shell shell;
  late int branchIndex;
  late _Commands commands;
  Future<void> mount(
    WidgetTester tester, {
    bool realCommands = false,
    bool desktop = false,
  }) async {
    branchIndex = AppBranch.statistics.index;
    shell = _Shell();
    when(() => shell.currentIndex).thenAnswer((_) => branchIndex);
    when(() => shell.goBranch(any())).thenAnswer((call) {
      branchIndex = call.positionalArguments.first as int;
    });
    commands = _Commands();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) => _Storage()),
        authNotifierProvider.overrideWith(_Auth.new),
        accountManagerNotifierProvider.overrideWith(_Accounts.new),
        subscriptionNotifierProvider.overrideWith(_Subscription.new),
        shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
        updateStateProvider.overrideWith(_Update.new),
        imageGenerationNotifierProvider.overrideWith(_Generation.new),
        localUpscaleTaskProvider.overrideWith(_Local.new),
        cloudUpscaleTaskProvider.overrideWith(_Cloud.new),
        bulkOperationNotifierProvider.overrideWith(_Bulk.new),
        if (!realCommands) navCommandsProvider.overrideWithValue(commands),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: desktop
              ? DesktopShell(
                  navigationShell: shell,
                  content: const Text('Content'),
                )
              : Scaffold(
                  body: NavWiring(
                    navigationShell: shell,
                    child: const Text('Content'),
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  NavShell view(WidgetTester tester) =>
      tester.widget<NavShell>(find.byType(NavShell));

  testWidgets(
    'wiring assembles providers and connects every preference and navigation action',
    (tester) async {
      await mount(tester);
      final data = view(tester).data;
      expect(data.current, NavPage.statistics);
      expect(data.account.current!.id, 'current');
      expect(data.account.others.single.id, 'other');
      expect(data.account.anlas, 300);
      expect(data.account.plan, 'Opus');
      expect(data.updateAvailable, isTrue);
      expect(data.shortcuts.length, 10);
      final actions = view(tester).actions;
      actions.onPinnedChanged(true);
      actions.onHiddenChanged({NavPage.localGallery});
      actions.onCtrlNumbersChanged(false);
      actions.onCtrlHintSeen();
      actions.onSwitchAccount('other');
      actions.onAddAccount();
      actions.onLogout();
      await tester.pumpAndSettle();
      expect(view(tester).data.pinned, isTrue);
      expect(view(tester).data.hidden, {NavPage.localGallery});
      expect(view(tester).data.ctrlNumbers, isFalse);
      expect(view(tester).data.ctrlHintSeen, isTrue);
      expect(commands.switched, ['other']);
      expect(commands.additions, 1);
      expect(commands.logouts, 1);
      actions.onOpenPage(NavPage.localGallery);
      await tester.pumpAndSettle();
      verify(() => shell.goBranch(AppBranch.localGallery.index)).called(1);
      actions.onManageAccounts();
      expect(container.read(settingsAccountOpenRequestProvider), 1);
      verify(() => shell.goBranch(AppBranch.settings.index)).called(1);
      expect(find.text('Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wiring clears unread generation on direct route changes, not only navigation clicks',
    (tester) async {
      await mount(tester);
      final generation =
          container.read(imageGenerationNotifierProvider.notifier)
              as _Generation;
      generation.emit(
        const ImageGenerationState(
          status: GenerationStatus.generating,
          generationRunId: 1,
        ),
      );
      generation.emit(
        const ImageGenerationState(
          status: GenerationStatus.error,
          generationRunId: 1,
          errorMessage: 'failed',
        ),
      );
      await tester.pump();
      expect(view(tester).data.generation.state, NavGenerationState.failed);
      branchIndex = AppBranch.generation.index;
      container
          .read(layoutStateNotifierProvider.notifier)
          .setMainNavRailExpanded(true);
      await tester.pumpAndSettle();
      expect(view(tester).data.generation.state, NavGenerationState.idle);
      expect(container.read(navActivityProvider).unreadGeneration, isNull);
    },
  );

  testWidgets('local cancellation and bulk undo only target valid task IDs', (
    tester,
  ) async {
    await mount(tester);
    final local = container.read(localUpscaleTaskProvider.notifier) as _Local;
    local.emit(
      const LocalUpscaleTaskState(
        running: true,
        progress: LocalUpscaleProgress(LocalUpscalePhase.inference, .4),
      ),
    );
    await tester.pump();
    final task = view(tester).data.tasks.single;
    expect(task.kind, NavTaskKind.localUpscale);
    expect(task.fraction, .4);
    expect(task.action, NavTaskAction.cancel);
    view(tester).actions.onCancelTask('stale');
    view(tester).actions.onCancelTask(task.id);
    view(tester).actions.onCancelTask(task.id);
    expect(local.cancellations, 1);
    final bulk =
        container.read(bulkOperationNotifierProvider.notifier) as _Bulk;
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isOperationInProgress: true,
      ),
    );
    bulk.emit(
      const BulkOperationState(
        currentOperation: BulkOperationType.delete,
        isCompleted: true,
        canUndo: true,
      ),
    );
    await tester.pump();
    final undo = view(tester).data.tasks.last;
    expect(undo.action, NavTaskAction.undo);
    view(tester).actions.onUndoTask('stale');
    view(tester).actions.onUndoTask(undo.id);
    view(tester).actions.onUndoTask(undo.id);
    await tester.pump();
    expect(bulk.undos, 1);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('all six bulk operation types map to the matching task kind', (
    tester,
  ) async {
    await mount(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(NavShell)))!;
    const expected = [
      NavTaskKind.bulkDelete,
      NavTaskKind.bulkExport,
      NavTaskKind.bulkMetadata,
      NavTaskKind.bulkAddToCollection,
      NavTaskKind.bulkRemoveFromCollection,
      NavTaskKind.bulkFavorite,
    ];
    for (final type in BulkOperationType.values) {
      final task = navTaskData(
        NavBackgroundTask(
          id: 'bulk',
          source: NavTaskSource.bulkOperation,
          bulk: BulkOperationState(
            currentOperation: type,
            currentProgress: 3,
            totalItems: 10,
          ),
        ),
        l10n,
      );
      expect(task.kind, expected[type.index]);
      expect(task.done, 3);
      expect(task.total, 10);
      expect(task.fraction, .3);
    }
  });

  testWidgets(
    'logout confirms and does not apply to an account changed during the dialog',
    (tester) async {
      await mount(tester, realCommands: true);
      final auth = container.read(authNotifierProvider.notifier) as _Auth;
      view(tester).actions.onLogout();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(auth.logouts, 0);
      view(tester).actions.onLogout();
      await tester.pumpAndSettle();
      auth.emit(
        const AuthState(status: AuthStatus.authenticated, accountId: 'other'),
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(auth.logouts, 0);
      view(tester).actions.onLogout();
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(auth.logouts, 1);
    },
  );

  testWidgets(
    'deferred account callbacks do nothing after the shell is disposed',
    (tester) async {
      await mount(tester);
      final actions = view(tester).actions;
      await tester.pumpWidget(const SizedBox());
      actions.onSwitchAccount('other');
      actions.onAddAccount();
      actions.onManageAccounts();
      actions.onLogout();
      await tester.pump();
      expect(commands.switched, isEmpty);
      expect(commands.additions, 0);
      expect(commands.logouts, 0);
      expect(container.read(settingsAccountOpenRequestProvider), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'DesktopShell installs the locked navigation shell around existing content',
    (tester) async {
      await mount(tester, desktop: true);
      expect(find.byType(NavWiring), findsOneWidget);
      expect(find.byType(NavShell), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
