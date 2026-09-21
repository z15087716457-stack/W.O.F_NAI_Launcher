import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_error_service.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/services/date_formatting_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guest_session_provider.dart';
import '../../widgets/auth/account_avatar.dart';
import '../../widgets/auth/login_form_container.dart';
import '../../widgets/branding/brand_entry_scene.dart';
import '../../widgets/auth/network_troubleshooting_dialog.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/themed_divider.dart';
import '../../widgets/common/update_notice_banner.dart';

/// Brand entry page; account and authentication behavior stays in the providers.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _avatarService = AvatarService();
  final _authErrorService = AuthErrorService();
  final _dateFormattingService = DateFormattingService();

  OverlayEntry? _loadingOverlayEntry;
  bool _showTroubleshootingButton = false;

  @override
  void initState() {
    super.initState();
    Future(() => ref.read(authModeNotifierProvider.notifier).reset());
  }

  @override
  void dispose() {
    _removeLoadingOverlay();
    super.dispose();
  }

  void _showLoadingOverlay() {
    if (_loadingOverlayEntry != null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      AppLogger.w(
        '[LoginScreen] Cannot show loading overlay: no overlay found',
      );
      return;
    }

    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlay(onDismiss: _removeLoadingOverlay),
    );

    overlay.insert(_loadingOverlayEntry!);
    AppLogger.d('[LoginScreen] Loading overlay shown');
  }

  void _removeLoadingOverlay() {
    if (_loadingOverlayEntry == null) return;

    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
    AppLogger.d('[LoginScreen] Loading overlay removed');
  }

  void _hideTroubleshootingButton() {
    if (mounted && _showTroubleshootingButton) {
      setState(() => _showTroubleshootingButton = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountManagerNotifierProvider);
    final accounts = accountState.accounts;
    final isLoading = accountState.isLoading;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      _handleAuthStateChange(previous, next);
    });

    return Stack(
      children: [
        BrandEntryScene(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildMainContent(
                      context,
                      theme,
                      isLoading,
                      accounts,
                    ),
                  ),
                  if (_showTroubleshootingButton) ...[
                    const SizedBox(height: 12),
                    _TroubleshootingButton(),
                  ],
                  const SizedBox(height: 22),
                  _LoginTip(theme: theme),
                ],
              );
            },
          ),
        ),
        const Positioned(
          top: 52,
          left: 0,
          right: 0,
          child: UpdateNoticeBanner(),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ThemeData theme,
    bool isLoading,
    List<SavedAccount> accounts,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: LinearProgressIndicator(),
      );
    }

    if (accounts.isEmpty) {
      return const LoginFormContainer(showGuestEntry: true, compact: true);
    }

    return _QuickLoginView(
      theme: theme,
      accounts: accounts,
      onAvatarTap: (account) => _showAvatarOptions(context, ref, account),
      onAccountSelectorTap: (accounts, current) =>
          _showAccountSelector(context, ref, accounts, current),
      onQuickLogin: (account) => _handleQuickLogin(context, ref, account),
      onAddAccount: () => _showAddAccountDialog(context),
      onGuestEntry: () {
        ref.read(guestSessionNotifierProvider.notifier).enterGuest();
      },
    );
  }

  void _handleAuthStateChange(AuthState? previous, AuthState next) {
    // 监听 loading 状态
    if (next.isLoading && previous?.isLoading != true) {
      _showLoadingOverlay();
      _hideTroubleshootingButton();
    } else if (!next.isLoading && previous?.isLoading == true) {
      _removeLoadingOverlay();
    }

    // 监听登录成功
    if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
      _hideTroubleshootingButton();
    }

    // 监听登录错误
    if (next.hasError && previous?.errorCode != next.errorCode) {
      _handleAuthError(next);
    }
  }

  void _handleAuthError(AuthState state) {
    AppLogger.d(
      '[LoginScreen] Showing error Toast: ${state.errorCode}',
      'LOGIN',
    );

    final l10n = context.l10n;
    final errorText = _authErrorService.getErrorText(
      l10n,
      state.errorCode!,
      state.httpStatusCode,
    );
    final recoveryHint = _authErrorService.getErrorRecoveryHint(
      l10n,
      state.errorCode!,
      state.httpStatusCode,
    );

    final isNetworkError =
        state.errorCode == AuthErrorCode.networkTimeout ||
        state.errorCode == AuthErrorCode.networkError;

    if (isNetworkError && mounted) {
      setState(() => _showTroubleshootingButton = true);
    }

    final errorMessage = (recoveryHint != null && recoveryHint != errorText)
        ? '$errorText\n💡 $recoveryHint'
        : errorText;

    AppToast.error(context, errorMessage);
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 500);
  }

  Future<void> _handleQuickLogin(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);

    // 如果已经认证，不执行
    if (ref.read(authNotifierProvider).isAuthenticated) return;

    final token = await accountNotifier.getAccountToken(account.id);

    if (!context.mounted) return;
    if (token == null) {
      AppToast.info(context, context.l10n.auth_tokenNotFound);
      return;
    }

    // 再次检查是否已认证
    if (ref.read(authNotifierProvider).isAuthenticated) return;

    AppLogger.d(
      '[LoginScreen] _handleQuickLogin: switching account with type ${account.accountType}...',
      'LOGIN',
    );

    final success = await authNotifier.switchAccount(
      account.id,
      token,
      displayName: account.displayName,
      accountType: account.accountType,
    );

    if (!context.mounted) return;

    AppLogger.d('[LoginScreen] _handleQuickLogin: result=$success', 'LOGIN');

    if (success) {
      accountNotifier.updateLastUsed(account.id);
    }
  }

  void _showAccountSelector(
    BuildContext context,
    WidgetRef ref,
    List<SavedAccount> accounts,
    SavedAccount currentAccount,
  ) {
    final sortedAccounts = List<SavedAccount>.from(accounts)
      ..sort((a, b) {
        final aTime = a.lastUsedAt ?? a.createdAt;
        final bTime = b.lastUsedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    final defaultAccount = sortedAccounts.first;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Text(context.l10n.auth_selectAccount),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...accounts.map(
                (account) => _AccountListItem(
                  account: account,
                  isSelected: account.id == currentAccount.id,
                  isDefault: account.id == defaultAccount.id,
                  createdDate: _dateFormattingService.formatDate(
                    account.createdAt,
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _handleQuickLogin(context, ref, account);
                  },
                  onDelete: () =>
                      _showDeleteAccountDialog(context, ref, account),
                ),
              ),
              const ThemedDivider(),
              ListTile(
                // FEAT-30：与账户头像同形（微圆角方形）；动作位
                // 保留 primaryContainer 色与用户头像的品牌蓝区分
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: avatarBorderRadius(36),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(context.l10n.auth_addAccount),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _showAddAccountDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.auth_deleteAccount),
        content: Text(
          context.l10n.auth_deleteAccountConfirm(account.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              ref
                  .read(accountManagerNotifierProvider.notifier)
                  .removeAccount(account.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(context.l10n.common_delete),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    ref.read(authModeNotifierProvider.notifier).reset();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      context.l10n.auth_addAccount,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                LoginFormContainer(
                  onLoginSuccess: () => Navigator.pop(dialogContext),
                  showGuestEntry: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.auth_selectFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImageFromGallery(context, ref, account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.auth_takePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImageFromGallery(context, ref, account);
              },
            ),
            if (account.avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text(
                  context.l10n.auth_removeAvatar,
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeAvatar(context, ref, account);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    try {
      final result = await _avatarService.pickAndSaveAvatar(account);

      if (result.isSuccess && result.path != null) {
        final updatedAccount = account.copyWith(avatarPath: result.path);
        await ref
            .read(accountManagerNotifierProvider.notifier)
            .updateAccount(updatedAccount);

        if (context.mounted) {
          AppToast.success(context, context.l10n.common_success);
        }
      } else if (result.isFailure && context.mounted) {
        AppToast.error(
          context,
          result.errorMessage ?? context.l10n.common_error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.common_error);
      }
    }
  }

  Future<void> _removeAvatar(
    BuildContext context,
    WidgetRef ref,
    SavedAccount account,
  ) async {
    try {
      await _avatarService.removeAvatar(account);
      final updatedAccount = account.copyWith(avatarPath: null);
      await ref
          .read(accountManagerNotifierProvider.notifier)
          .updateAccount(updatedAccount);

      if (context.mounted) {
        AppToast.success(context, context.l10n.common_success);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.common_error);
      }
    }
  }
}

/// 登录提示文本
class _LoginTip extends StatelessWidget {
  final ThemeData theme;

  const _LoginTip({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.auth_loginTip,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 网络故障排除按钮
class _TroubleshootingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => NetworkTroubleshootingDialog.show(context),
        icon: const Icon(Icons.help_outline, size: 18),
        label: Text(context.l10n.auth_viewTroubleshootingTips),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// 快速登录视图
class _QuickLoginView extends ConsumerWidget {
  final ThemeData theme;
  final List<SavedAccount> accounts;
  final void Function(SavedAccount) onAvatarTap;
  final void Function(List<SavedAccount>, SavedAccount) onAccountSelectorTap;
  final void Function(SavedAccount) onQuickLogin;
  final VoidCallback onAddAccount;
  final VoidCallback onGuestEntry;

  const _QuickLoginView({
    required this.theme,
    required this.accounts,
    required this.onAvatarTap,
    required this.onAccountSelectorTap,
    required this.onQuickLogin,
    required this.onAddAccount,
    required this.onGuestEntry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedAccounts = List<SavedAccount>.from(accounts)
      ..sort((a, b) {
        final aTime = a.lastUsedAt ?? a.createdAt;
        final bTime = b.lastUsedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    final defaultAccount = sortedAccounts.first;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AccountAvatar(
              account: defaultAccount,
              size: 56,
              showEditBadge: true,
              onTap: () => onAvatarTap(defaultAccount),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountSelectorButton(
                    account: defaultAccount,
                    accounts: accounts,
                    onTap: () => onAccountSelectorTap(accounts, defaultAccount),
                  ),
                  Text(
                    context.l10n.auth_switchAccount,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: _QuickLoginButton(
            account: defaultAccount,
            onLogin: onQuickLogin,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onAddAccount,
          icon: const Icon(Icons.add, size: 18),
          label: Text(context.l10n.auth_addAccount),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('auth_guest_entry_quick_login'),
            onPressed: onGuestEntry,
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: Text(context.l10n.auth_guestEntry),
          ),
        ),
      ],
    );
  }
}

/// 账号选择器按钮
class _AccountSelectorButton extends StatelessWidget {
  final SavedAccount account;
  final List<SavedAccount> accounts;
  final VoidCallback onTap;

  const _AccountSelectorButton({
    required this.account,
    required this.accounts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                account.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一键登录按钮
class _QuickLoginButton extends ConsumerWidget {
  final SavedAccount account;
  final void Function(SavedAccount) onLogin;

  const _QuickLoginButton({required this.account, required this.onLogin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return FilledButton.icon(
      onPressed: authState.isLoading ? null : () => onLogin(account),
      icon: authState.isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login),
      label: Text(context.l10n.auth_quickLogin),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

/// 账号列表项
class _AccountListItem extends StatelessWidget {
  final SavedAccount account;
  final bool isSelected;
  final bool isDefault;
  final String createdDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AccountListItem({
    required this.account,
    required this.isSelected,
    required this.isDefault,
    required this.createdDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: AccountAvatarSmall(
        account: account,
        size: 40,
        isSelected: isSelected,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(account.displayName, overflow: TextOverflow.ellipsis),
          ),
          if (isDefault)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.l10n.common_default,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.check,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
        ],
      ),
      subtitle: Text(
        context.l10n.auth_createdAt(createdDate),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

/// 加载遮罩
class _LoadingOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const _LoadingOverlay({required this.onDismiss});

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.auth_loggingIn,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.auth_pleaseWait,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
