import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/subscription_expiry_utils.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/settings/widgets/settings_ui_theme.dart';
import '../common/studio_icons.dart';
import 'account_avatar.dart';
import 'subscription_expiry_text.dart';

enum AccountPopoverCommand { switchAccount, add, manage, logout }

class AccountPopoverAction {
  const AccountPopoverAction(this.command, {this.accountId});
  final AccountPopoverCommand command;
  final String? accountId;
}

/// A modal, undimmed panel beside the avatar. Actions run after dismissal so
/// account changes cannot dispose the menu while it is handling a pointer.
Future<AccountPopoverAction?> showAccountPopover(
  BuildContext context, {
  required Offset anchor,
}) => showDialog<AccountPopoverAction>(
  context: context,
  barrierColor: Colors.transparent,
  useSafeArea: false,
  animationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 160),
    reverseDuration: Duration(milliseconds: 120),
  ),
  builder: (context) => CustomSingleChildLayout(
    delegate: _AccountPopoverLayout(anchor, MediaQuery.paddingOf(context)),
    child: const AccountPopover(),
  ),
);

class _AccountPopoverLayout extends SingleChildLayoutDelegate {
  const _AccountPopoverLayout(this.anchor, this.padding);
  final Offset anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(
      314.0,
      math.max(0.0, constraints.maxWidth - padding.horizontal - 16),
    );
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.min(
        480,
        math.max(0.0, constraints.maxHeight - padding.vertical - 16),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    anchor.dx.clamp(
      padding.left + 8,
      math.max(
        padding.left + 8,
        size.width - padding.right - childSize.width - 8,
      ),
    ),
    anchor.dy.clamp(
      padding.top + 8,
      math.max(
        padding.top + 8,
        size.height - padding.bottom - childSize.height - 8,
      ),
    ),
  );

  @override
  bool shouldRelayout(_AccountPopoverLayout oldDelegate) =>
      anchor != oldDelegate.anchor || padding != oldDelegate.padding;
}

class AccountPopover extends ConsumerWidget {
  const AccountPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = ref.watch(authNotifierProvider);
    ref.watch(accountManagerNotifierProvider);
    final accounts = ref
        .read(accountManagerNotifierProvider.notifier)
        .sortedAccounts;
    final current = auth.isAuthenticated
        ? accounts.where((a) => a.id == auth.accountId).firstOrNull
        : null;
    final others = accounts.where((a) => a.id != current?.id).toList();
    final busy = auth.isLoading;
    final title = settingsText(
      context,
      '登录与账号',
      'Sign-in & accounts',
      'ログインとアカウント',
    );
    final muted = colors.onSurfaceVariant;
    TextStyle text(double size, {Color? color, FontWeight? weight}) =>
        theme.textTheme.bodyMedium!.copyWith(
          fontSize: size,
          height: 1.4,
          color: color ?? colors.onSurface,
          fontWeight: weight ?? FontWeight.w400,
        );
    void finish(AccountPopoverCommand command, [String? id]) =>
        Navigator.of(context).pop(AccountPopoverAction(command, accountId: id));

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: text(11, color: muted)),
            ),
            Text(
              'STUDIO',
              style: text(9, color: muted).copyWith(letterSpacing: 1.3),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            if (current != null)
              AccountAvatar(
                account: current,
                size: 42,
                muted: true,
                showEditBadge: false,
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  StudioIcons.settingsAccount,
                  size: 22,
                  color: muted,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          current?.displayName ??
                              (auth.isAuthenticated
                                  ? auth.displayName ??
                                        context.l10n.auth_currentAccount
                                  : settingsText(
                                      context,
                                      '尚未登录',
                                      'Not signed in',
                                      '未ログイン',
                                    )),
                          key: const Key('account-popover-current-name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(18, weight: FontWeight.w600),
                        ),
                      ),
                      if (auth.isAuthenticated) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 11,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                settingsText(context, '当前', 'Current', '現在'),
                                style: text(10, color: colors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    current == null
                        ? settingsText(
                            context,
                            '选择账号，继续创作',
                            'Choose an account to continue',
                            'アカウントを選択して続ける',
                          )
                        : _loginMethod(context, current),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text(11, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (current?.subscriptionExpiresAt != null) ...[
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _subscriptionColor(context, current!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _subscriptionLabel(context, current),
                  style: text(11, color: _subscriptionColor(context, current)),
                ),
              ),
            ],
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: .65),
          ),
          const SizedBox(height: 13),
          Text(context.l10n.auth_switchAccount, style: text(11, color: muted)),
          const SizedBox(height: 5),
        ],
      ],
    );
    final accountList = ListView.builder(
      primary: false,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: others.length,
      itemBuilder: (context, index) {
        final account = others[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            key: ValueKey('account-popover-switch-${account.id}'),
            autofocus: index == 0 && !busy,
            onTap: busy
                ? null
                : () => finish(AccountPopoverCommand.switchAccount, account.id),
            borderRadius: BorderRadius.circular(10),
            hoverColor: colors.onSurface.withValues(alpha: .04),
            focusColor: colors.primary.withValues(alpha: .09),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
              child: Row(
                children: [
                  AccountAvatar(
                    account: account,
                    size: 32,
                    muted: true,
                    showEditBadge: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(13, weight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.subscriptionExpiresAt == null
                              ? _loginMethod(context, account)
                              : _subscriptionLabel(context, account),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(
                            11,
                            color: account.subscriptionExpiresAt == null
                                ? muted
                                : _subscriptionColor(context, account),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 16, color: muted),
                ],
              ),
            ),
          ),
        );
      },
    );
    final quietButton = TextButton.styleFrom(
      foregroundColor: muted,
      textStyle: text(12),
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const Key('account-popover-add'),
          autofocus: others.isEmpty && !busy,
          onPressed: busy ? null : () => finish(AccountPopoverCommand.add),
          icon: const Icon(Icons.add, size: 15),
          label: Text(context.l10n.auth_addAccount),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            textStyle: text(12, weight: FontWeight.w500),
            side: BorderSide(color: colors.outlineVariant),
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
          ),
        ),
        const SizedBox(height: 15),
        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .65)),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: TextButton.icon(
                key: const Key('account-popover-manage'),
                onPressed: () => finish(AccountPopoverCommand.manage),
                style: quietButton,
                icon: const Icon(StudioIcons.settingsGeneration, size: 14),
                label: Text(
                  settingsText(context, '管理账号', 'Manage accounts', 'アカウント管理'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: TextButton.icon(
                key: const Key('account-popover-logout'),
                onPressed: busy
                    ? null
                    : () => finish(AccountPopoverCommand.logout),
                style: quietButton.copyWith(
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused)
                        ? colors.error
                        : muted,
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    colors.error.withValues(alpha: .06),
                  ),
                ),
                icon: const Icon(Icons.logout_outlined, size: 14),
                label: Text(
                  context.l10n.auth_logout,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Semantics(
      namesRoute: true,
      label: title,
      child: FocusTraversalGroup(
        child: Container(
          key: const Key('account-popover'),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: colors.shadow.withValues(alpha: .04),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Very short windows scroll the whole panel; normal windows
                  // scroll only saved accounts, keeping actions accessible.
                  if (constraints.maxHeight < 280) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          header,
                          if (others.isNotEmpty) accountList,
                          footer,
                        ],
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (others.isNotEmpty)
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: accountList,
                          ),
                        ),
                      footer,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _loginMethod(BuildContext context, SavedAccount account) =>
    account.accountType == AccountType.token
    ? context.l10n.auth_tokenLogin
    : context.l10n.auth_credentialsLogin;

String _subscriptionLabel(BuildContext context, SavedAccount account) {
  final info = getSubscriptionExpiryInfo(account.subscriptionExpiresAt!);
  return info.isExpired
      ? settingsText(context, '订阅已到期', 'Subscription expired', 'サブスクリプションの期限切れ')
      : SubscriptionExpiryText.dateStatusTextOf(
          context,
          info,
          withExpiresOnLabel: true,
        );
}

Color _subscriptionColor(BuildContext context, SavedAccount account) {
  final colors = Theme.of(context).colorScheme;
  final info = getSubscriptionExpiryInfo(account.subscriptionExpiresAt!);
  return info.isExpired || info.isExpiringSoon
      ? (colors.brightness == Brightness.dark
            ? const Color(0xFFD9A441)
            : const Color(0xFF98691D))
      : colors.onSurfaceVariant;
}
