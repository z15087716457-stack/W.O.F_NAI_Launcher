import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/shortcuts/shortcut_config.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/subscription_expiry_utils.dart';
import '../../data/models/auth/saved_account.dart';
import '../../data/models/upscale/local_upscale_models.dart';
import '../../data/models/user/user_subscription.dart';
import '../../l10n/app_localizations.dart';
import '../providers/account_manager_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bulk_operation_provider.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/layout_state_provider.dart';
import '../providers/nav_activity_provider.dart';
import '../providers/settings_navigation_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/update_provider.dart';
import '../router/app_branch.dart';
import '../ui/nav/nav_contract.dart';
import '../ui/nav/nav_shell.dart';
import '../widgets/auth/account_switch_helper.dart';
import '../widgets/auth/add_account_dialog.dart';

const navBranchPages = <AppBranch, NavPage>{
  AppBranch.generation: NavPage.generation,
  AppBranch.styleExplore: NavPage.styleExplore,
  AppBranch.localGallery: NavPage.localGallery,
  AppBranch.onlineGallery: NavPage.onlineGallery,
  AppBranch.promptBlockLibrary: NavPage.promptBlocks,
  AppBranch.vibeLibrary: NavPage.vibeLibrary,
  AppBranch.preciseRefLibrary: NavPage.preciseRef,
  AppBranch.tagWiki: NavPage.tagWiki,
  AppBranch.statistics: NavPage.statistics,
  AppBranch.settings: NavPage.settings,
};

NavPage navPageForBranch(AppBranch branch) => navBranchPages[branch]!;
AppBranch navBranchForPage(NavPage page) =>
    navBranchPages.entries.firstWhere((entry) => entry.value == page).key;

Map<NavPage, List<String>> navShortcutKeycaps(ShortcutConfig? config) {
  if (config == null || !config.enableShortcuts) return const {};
  return Map.unmodifiable({
    for (final entry in globalNavigationShortcutBranches.entries)
      if (config.getEffectiveShortcut(entry.key) case final String shortcut)
        if (ShortcutParser.parse(shortcut) case final ParsedShortcut parsed)
          navPageForBranch(entry.value): List<String>.unmodifiable(
            parsed.displayLabel.split('+'),
          ),
  });
}

NavAccountData navAccountData({
  required AuthState auth,
  required List<SavedAccount> sortedAccounts,
  required SubscriptionState subscription,
  DateTime? now,
}) {
  NavAccount convert(SavedAccount account) {
    final expiry = account.subscriptionExpiresAt;
    final info = expiry == null
        ? null
        : getSubscriptionExpiryInfo(expiry, now: now);
    final path = account.avatarPath;
    return NavAccount(
      id: account.id,
      name: account.displayName,
      avatar: path != null && path.isNotEmpty && File(path).existsSync()
          ? FileImage(File(path))
          : null,
      tokenLogin: account.accountType == AccountType.token,
      subscription: info == null || !info.hasValidDate
          ? null
          : NavSubscription(
              expiresAt: info.expiryDate,
              daysLeft: info.daysLeft,
              state: info.isExpired
                  ? NavSubscriptionState.expired
                  : info.isExpiringSoon
                  ? NavSubscriptionState.expiringSoon
                  : NavSubscriptionState.ok,
            ),
    );
  }

  final current = auth.isAuthenticated
      ? sortedAccounts
            .where((account) => account.id == auth.accountId)
            .firstOrNull
      : null;
  return NavAccountData(
    current: current == null ? null : convert(current),
    others: List.unmodifiable(
      sortedAccounts.where((account) => account.id != current?.id).map(convert),
    ),
    anlas: auth.isAuthenticated ? subscription.balance : null,
    plan: auth.isAuthenticated ? subscription.subscription?.tierName : null,
    busy: auth.isLoading,
  );
}

NavGeneration navGenerationData(
  ImageGenerationState generation,
  NavGenerationResult? unread, {
  required bool visible,
}) {
  if (generation.isGenerating) {
    final bytes =
        generation.streamPreviewSlots.reversed
            .where((slot) => slot.previewBytes?.isNotEmpty == true)
            .firstOrNull
            ?.previewBytes ??
        generation.streamPreview;
    return NavGeneration(
      state: NavGenerationState.running,
      current: generation.currentImage,
      total: generation.totalImages,
      progress: generation.progress.isFinite
          ? generation.progress.clamp(0.0, 1.0)
          : null,
      preview: bytes == null || bytes.isEmpty ? null : MemoryImage(bytes),
    );
  }
  if (visible || unread == null) return const NavGeneration.idle();
  return NavGeneration(
    state: unread.status == GenerationStatus.completed
        ? NavGenerationState.done
        : NavGenerationState.failed,
    current: unread.total,
    total: unread.total,
    error: unread.error?.split('\n').first,
  );
}

NavTask navTaskData(
  NavBackgroundTask task,
  AppLocalizations l10n, {
  bool canUndo = false,
}) {
  final local = task.local;
  final bulk = task.bulk;
  final kind = switch (task.source) {
    NavTaskSource.localUpscale => NavTaskKind.localUpscale,
    NavTaskSource.cloudUpscale => NavTaskKind.cloudUpscale,
    NavTaskSource.bulkOperation => switch (bulk!.currentOperation!) {
      BulkOperationType.delete => NavTaskKind.bulkDelete,
      BulkOperationType.export => NavTaskKind.bulkExport,
      BulkOperationType.metadataEdit => NavTaskKind.bulkMetadata,
      BulkOperationType.addToCollection => NavTaskKind.bulkAddToCollection,
      BulkOperationType.removeFromCollection =>
        NavTaskKind.bulkRemoveFromCollection,
      BulkOperationType.toggleFavorite => NavTaskKind.bulkFavorite,
    },
  };
  return NavTask(
    id: task.id,
    kind: kind,
    done: bulk?.currentProgress,
    total: bulk?.totalItems,
    fraction: bulk != null && bulk.totalItems > 0
        ? bulk.progressPercentage / 100
        : local?.progress?.fraction,
    phase: local?.cancelling == true
        ? l10n.localUpscale_cancelling
        : switch (local?.progress?.phase) {
            LocalUpscalePhase.preparing => l10n.localUpscale_preparing,
            LocalUpscalePhase.encoding => l10n.localUpscale_encoding,
            LocalUpscalePhase.inference => l10n.localUpscale_inference,
            LocalUpscalePhase.decoding => l10n.localUpscale_decoding,
            LocalUpscalePhase.resizing => l10n.localUpscale_resizing,
            LocalUpscalePhase.complete => l10n.localUpscale_complete,
            null => null,
          },
    finished: task.finished,
    action: canUndo
        ? NavTaskAction.undo
        : local?.running == true && !task.finished
        ? local!.cancelling
              ? NavTaskAction.cancelling
              : NavTaskAction.cancel
        : NavTaskAction.none,
  );
}

final navCommandsProvider = Provider<NavCommands>((ref) => const NavCommands());

class NavCommands {
  const NavCommands();

  Future<void> switchAccount(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final auth = ref.read(authNotifierProvider);
    final account = ref
        .read(accountManagerNotifierProvider)
        .accounts
        .where((account) => account.id == id)
        .firstOrNull;
    if (auth.isLoading ||
        account == null ||
        (auth.isAuthenticated && auth.accountId == id)) {
      return;
    }
    await AccountSwitchHelper.switchToAccount(context, ref, account);
  }

  void addAccount(BuildContext context, WidgetRef ref) {
    if (!ref.read(authNotifierProvider).isLoading) {
      AddAccountDialog.show(context, ref);
    }
  }

  void manageAccounts(WidgetRef ref, StatefulNavigationShell shell) {
    ref.read(settingsAccountOpenRequestProvider.notifier).state++;
    shell.goBranch(AppBranch.settings.index);
  }

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authNotifierProvider);
    if (auth.isLoading || !auth.isAuthenticated) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.auth_logout),
        content: Text(context.l10n.auth_logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final current = ref.read(authNotifierProvider);
    if (current.isAuthenticated &&
        !current.isLoading &&
        current.accountId == auth.accountId) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

class NavWiring extends ConsumerStatefulWidget {
  const NavWiring({
    super.key,
    required this.navigationShell,
    required this.child,
  });
  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  ConsumerState<NavWiring> createState() => _NavWiringState();
}

class _NavWiringState extends ConsumerState<NavWiring> {
  void _ifMounted(VoidCallback action) {
    if (mounted) action();
  }

  @override
  Widget build(BuildContext context) {
    final branch = AppBranch.values[widget.navigationShell.currentIndex];
    final activity = ref.watch(navActivityProvider);
    final activityController = ref.read(navActivityProvider.notifier);
    if (activityController.currentBranch != branch) {
      Future.microtask(() {
        if (mounted) {
          activityController.setCurrentBranch(
            AppBranch.values[widget.navigationShell.currentIndex],
          );
        }
      });
    }
    final layout = ref.watch(layoutStateNotifierProvider);
    final layoutController = ref.read(layoutStateNotifierProvider.notifier);
    final config = ref.watch(shortcutConfigNotifierProvider).valueOrNull;
    final auth = ref.watch(authNotifierProvider);
    ref.watch(accountManagerNotifierProvider);
    final accounts = ref
        .read(accountManagerNotifierProvider.notifier)
        .sortedAccounts;
    final subscription = ref.watch(subscriptionNotifierProvider);
    final generation = ref.watch(imageGenerationNotifierProvider);
    final commands = ref.read(navCommandsProvider);
    return NavShell(
      data: NavViewData(
        current: navPageForBranch(branch),
        shortcuts: navShortcutKeycaps(config),
        showShortcutsInTips: config?.showShortcutInTooltip ?? true,
        hidden: Set.unmodifiable(
          layout.mainNavHiddenBranches.map(navPageForBranch),
        ),
        ctrlNumbers: layout.mainNavCtrlNumbers,
        ctrlHintSeen: layout.mainNavCtrlHintSeen,
        pinned: layout.mainNavRailExpanded,
        reducedMotion: ref.watch(canvasReducedMotionNotifierProvider),
        updateAvailable: ref.watch(updateStateProvider).hasNewVersion,
        account: navAccountData(
          auth: auth,
          sortedAccounts: accounts,
          subscription: subscription,
        ),
        generation: navGenerationData(
          generation,
          activity.unreadGeneration,
          visible: branch == AppBranch.generation,
        ),
        tasks: List.unmodifiable(
          activity.tasks.map(
            (task) => navTaskData(
              task,
              context.l10n,
              canUndo: activityController.canUndoTask(task.id),
            ),
          ),
        ),
      ),
      actions: NavActions(
        onOpenPage: (page) {
          final branch = navBranchForPage(page);
          activityController.setCurrentBranch(branch);
          widget.navigationShell.goBranch(branch.index);
        },
        onPinnedChanged: (value) =>
            unawaited(layoutController.setMainNavRailExpanded(value)),
        onHiddenChanged: (pages) => unawaited(
          layoutController.setMainNavHiddenBranches(
            pages.map(navBranchForPage).toSet(),
          ),
        ),
        onCtrlNumbersChanged: (value) =>
            unawaited(layoutController.setMainNavCtrlNumbers(value)),
        onCtrlHintSeen: () =>
            unawaited(layoutController.setMainNavCtrlHintSeen(true)),
        onSwitchAccount: (id) => _ifMounted(
          () => unawaited(commands.switchAccount(context, ref, id)),
        ),
        onAddAccount: () => _ifMounted(() => commands.addAccount(context, ref)),
        onManageAccounts: () => _ifMounted(
          () => commands.manageAccounts(ref, widget.navigationShell),
        ),
        onLogout: () =>
            _ifMounted(() => unawaited(commands.logout(context, ref))),
        onCancelTask: activityController.cancelTask,
        onUndoTask: (id) => unawaited(activityController.undoTask(id)),
      ),
      child: widget.child,
    );
  }
}
