import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_error_service.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_mode_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guest_session_provider.dart';
import '../../themes/studio_typography.dart';
import '../../widgets/auth/account_avatar.dart';
import '../../widgets/auth/entry_controls.dart';
import '../../widgets/auth/login_form_container.dart';
import '../../widgets/auth/network_troubleshooting_dialog.dart';
import '../../widgets/branding/brand_entry_scene.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/update_notice_banner.dart';

/// 登录页：整页「去噪」场景加一张磨砂卡片。
///
/// 有保存的账号时是快速登录卡：账号行可在卡内展开切换 / 删除，一键登录
/// （回车也可），添加账号，右下角 SKIP 以游客进入。没有账号或点了添加
/// 账号时换成登录表单卡。认证与账号逻辑都在 provider 里，这里只负责
/// 展示与转发；登录中不再弹全屏遮罩，按钮内显示进度、背景加速去噪。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _avatarService = AvatarService();
  final _authErrorService = AuthErrorService();

  String? _selectedId;
  bool _listOpen = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    Future(() => ref.read(authModeNotifierProvider.notifier).reset());
  }

  List<SavedAccount> _sorted(List<SavedAccount> accounts) {
    return List<SavedAccount>.from(accounts)..sort((a, b) {
      final aTime = a.lastUsedAt ?? a.createdAt;
      final bTime = b.lastUsedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountManagerNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final accounts = _sorted(accountState.accounts);

    final Widget card;
    if (accountState.isLoading) {
      card = EntryCard(
        key: const ValueKey('entry_card_loading'),
        child: SizedBox(
          height: 96,
          child: Center(
            child: EntryBusyDots(color: EntryPalette.of(context).faint),
          ),
        ),
      );
    } else if (accounts.isEmpty || _adding) {
      card = _buildFormCard(context, canGoBack: accounts.isNotEmpty);
    } else {
      card = _buildQuickCard(context, accounts, authState);
    }

    return Stack(
      children: [
        BrandEntryScene(
          busy: authState.isLoading,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: card,
          ),
        ),
        const Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: UpdateNoticeBanner(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 表单卡

  Widget _buildFormCard(BuildContext context, {required bool canGoBack}) {
    final l10n = context.l10n;
    final palette = EntryPalette.of(context);
    final busy = ref.watch(authNotifierProvider.select((s) => s.isLoading));
    return EntryCard(
      key: const ValueKey('entry_card_form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  canGoBack ? l10n.auth_addAccount : l10n.auth_login,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
              if (canGoBack)
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: EntryGhostButton(
                    key: const Key('auth_back'),
                    icon: Icons.chevron_left,
                    label: l10n.auth_back,
                    onPressed: busy ? null : _closeAddForm,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LoginFormContainer(
            showGuestEntry: true,
            compact: true,
            onLoginSuccess: () {
              if (mounted) setState(() => _adding = false);
            },
          ),
        ],
      ),
    );
  }

  void _openAddForm() {
    _clearStaleError();
    ref.read(authModeNotifierProvider.notifier).reset();
    setState(() {
      _adding = true;
      _listOpen = false;
    });
  }

  void _closeAddForm() {
    _clearStaleError();
    setState(() => _adding = false);
  }

  // -------------------------------------------------------------- 快速登录卡

  Widget _buildQuickCard(
    BuildContext context,
    List<SavedAccount> accounts,
    AuthState authState,
  ) {
    final l10n = context.l10n;
    final busy = authState.isLoading;
    final selected = accounts.firstWhere(
      (account) => account.id == _selectedId,
      orElse: () => accounts.first,
    );
    final errorCode = authState.errorCode;
    final showError = errorCode != null && !busy;
    final isNetworkError =
        errorCode == AuthErrorCode.networkTimeout ||
        errorCode == AuthErrorCode.networkError;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _handleQuickLogin(selected),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
            _handleQuickLogin(selected),
      },
      child: Focus(
        autofocus: true,
        child: EntryCard(
          key: const ValueKey('entry_card_quick'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountRow(
                account: selected,
                subtitle: _accountSubtitle(context, selected),
                onTap: busy
                    ? null
                    : () => setState(() => _listOpen = !_listOpen),
                onAvatarTap: busy
                    ? null
                    : (anchor) => _showAvatarMenu(anchor, selected),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _listOpen
                    ? _AccountList(
                        accounts: accounts,
                        selectedId: selected.id,
                        subtitleOf: (account) =>
                            _accountSubtitle(context, account),
                        onSelect: _selectAccount,
                        onDelete: (account) =>
                            _confirmDeleteAccount(context, account),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: EntryPrimaryButton(
                  key: const Key('auth_quick_login'),
                  label: l10n.auth_quickLogin,
                  busy: busy,
                  busyLabel: l10n.auth_loggingIn,
                  onPressed: () => _handleQuickLogin(selected),
                ),
              ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                  child: EntryAlert(
                    title: _authErrorService.getErrorText(
                      l10n,
                      errorCode,
                      authState.httpStatusCode,
                    ),
                    hint: _authErrorService.getErrorRecoveryHint(
                      l10n,
                      errorCode,
                      authState.httpStatusCode,
                    ),
                    actionLabel: isNetworkError
                        ? l10n.auth_viewTroubleshootingTips
                        : null,
                    onAction: () => NetworkTroubleshootingDialog.show(context),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  EntryGhostButton(
                    key: const Key('auth_add_account'),
                    icon: Icons.add,
                    label: l10n.auth_addAccount,
                    onPressed: busy ? null : _openAddForm,
                  ),
                  const Spacer(),
                  EntrySkipButton(
                    key: const Key('auth_guest_entry_quick_login'),
                    onPressed: () => ref
                        .read(guestSessionNotifierProvider.notifier)
                        .enterGuest(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _accountSubtitle(BuildContext context, SavedAccount account) {
    final endpoint = ref
        .read(accountManagerNotifierProvider.notifier)
        .getAccountApiEndpoint(account.id);
    if (endpoint.isThirdParty) {
      final host = Uri.tryParse(endpoint.mainBaseUrl)?.host ?? '';
      return host.isNotEmpty ? host : endpoint.mainBaseUrl;
    }
    return account.accountType == AccountType.credentials
        ? 'NovelAI · ${context.l10n.auth_email}'
        : 'NovelAI · Token';
  }

  /// 切换账号或打开表单时收起上一次的失败提示。
  void _clearStaleError() {
    final auth = ref.read(authNotifierProvider);
    if (auth.hasError && !auth.isLoading) {
      ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);
    }
  }

  void _selectAccount(SavedAccount account) {
    _clearStaleError();
    setState(() {
      _selectedId = account.id;
      _listOpen = false;
    });
  }

  Future<void> _handleQuickLogin(SavedAccount account) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);
    final auth = ref.read(authNotifierProvider);
    if (auth.isAuthenticated || auth.isLoading) return;
    if (_listOpen) setState(() => _listOpen = false);

    final token = await accountNotifier.getAccountToken(account.id);
    if (!mounted) return;
    if (token == null) {
      AppToast.info(context, context.l10n.auth_tokenNotFound);
      return;
    }
    // 取 Token 期间可能已经登录或正在登录
    final latest = ref.read(authNotifierProvider);
    if (latest.isAuthenticated || latest.isLoading) return;

    AppLogger.d(
      '[LoginScreen] quick login with account type ${account.accountType}',
      'LOGIN',
    );
    final success = await authNotifier.switchAccount(
      account.id,
      token,
      displayName: account.displayName,
      accountType: account.accountType,
    );
    AppLogger.d('[LoginScreen] quick login result=$success', 'LOGIN');
    if (success) accountNotifier.updateLastUsed(account.id);
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    SavedAccount account,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.auth_deleteAccount),
        content: Text(l10n.auth_deleteAccountConfirm(account.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(accountManagerNotifierProvider.notifier)
        .removeAccount(account.id);
    if (!mounted) return;
    setState(() {
      if (_selectedId == account.id) _selectedId = null;
    });
  }

  Future<void> _showAvatarMenu(
    BuildContext anchor,
    SavedAccount account,
  ) async {
    final box = anchor.findRenderObject();
    final overlay = Overlay.of(anchor).context.findRenderObject();
    if (box is! RenderBox || overlay is! RenderBox) return;
    final l10n = anchor.l10n;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy + box.size.height + 4, 0, 0),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: anchor,
      position: position,
      items: [
        PopupMenuItem(value: 'pick', child: Text(l10n.settings_changeAvatar)),
        if (account.avatarPath != null)
          PopupMenuItem(value: 'remove', child: Text(l10n.auth_removeAvatar)),
      ],
    );
    if (!mounted) return;
    if (choice == 'pick') {
      await _pickImageFromGallery(account);
    } else if (choice == 'remove') {
      await _removeAvatar(account);
    }
  }

  Future<void> _pickImageFromGallery(SavedAccount account) async {
    try {
      final result = await _avatarService.pickAndSaveAvatar(account);
      if (result.isSuccess && result.path != null) {
        await ref
            .read(accountManagerNotifierProvider.notifier)
            .updateAccount(account.copyWith(avatarPath: result.path));
        if (mounted) AppToast.success(context, context.l10n.common_success);
      } else if (result.isFailure && mounted) {
        AppToast.error(
          context,
          result.errorMessage ?? context.l10n.common_error,
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, context.l10n.common_error);
    }
  }

  Future<void> _removeAvatar(SavedAccount account) async {
    try {
      await _avatarService.removeAvatar(account);
      await ref
          .read(accountManagerNotifierProvider.notifier)
          .updateAccount(account.copyWith(avatarPath: null));
      if (mounted) AppToast.success(context, context.l10n.common_success);
    } catch (e) {
      if (mounted) AppToast.error(context, context.l10n.common_error);
    }
  }
}

/// 当前账号行：头像（点击换头像）、名称与账号类型，整行点击展开账号列表。
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.subtitle,
    required this.onTap,
    required this.onAvatarTap,
  });

  final SavedAccount account;
  final String subtitle;
  final VoidCallback? onTap;
  final void Function(BuildContext anchor)? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return InkWell(
      key: const Key('auth_account_selector'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: palette.hover,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Builder(
              builder: (anchor) => Tooltip(
                message: context.l10n.settings_changeAvatar,
                child: AccountAvatar(
                  account: account,
                  size: 40,
                  showEditBadge: false,
                  onTap: onAvatarTap == null
                      ? null
                      : () => onAvatarTap!(anchor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudioTypography.data.copyWith(
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: context.l10n.auth_selectAccount,
              child: Icon(Icons.unfold_more, size: 18, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡片内展开的账号列表：点选只切换当前账号，不直接登录。
class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.selectedId,
    required this.subtitleOf,
    required this.onSelect,
    required this.onDelete,
  });

  final List<SavedAccount> accounts;
  final String selectedId;
  final String Function(SavedAccount) subtitleOf;
  final ValueChanged<SavedAccount> onSelect;
  final ValueChanged<SavedAccount> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: palette.border),
        const SizedBox(height: 6),
        for (final account in accounts)
          _AccountListItem(
            account: account,
            subtitle: subtitleOf(account),
            selected: account.id == selectedId,
            onTap: () => onSelect(account),
            onDelete: () => onDelete(account),
          ),
      ],
    );
  }
}

class _AccountListItem extends StatefulWidget {
  const _AccountListItem({
    required this.account,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final SavedAccount account;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_AccountListItem> createState() => _AccountListItemState();
}

class _AccountListItemState extends State<_AccountListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = EntryPalette.of(context);
    return InkWell(
      key: ValueKey('auth_account_${widget.account.id}'),
      onTap: widget.onTap,
      onHover: (hover) => setState(() => _hover = hover),
      borderRadius: BorderRadius.circular(8),
      hoverColor: palette.hover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            AccountAvatar(
              account: widget.account,
              size: 28,
              showEditBadge: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudioTypography.data.copyWith(
                      fontSize: 11,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.selected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.check, size: 16, color: palette.blue),
              ),
            const SizedBox(width: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _hover ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_hover,
                child: Tooltip(
                  message: context.l10n.auth_deleteAccount,
                  child: InkWell(
                    key: ValueKey('auth_account_delete_${widget.account.id}'),
                    onTap: widget.onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
