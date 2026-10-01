import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/account_manager_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/settings/account_detail_tile.dart';
import '../../../widgets/settings/account_profile_sheet.dart';
import '../../../widgets/settings/saved_accounts_section.dart';
import '../widgets/settings_card.dart';

/// 账户设置板块
///
/// 分为两个区块：当前账号卡片（点击编辑资料）和已保存账号列表
/// （切换、删除、添加账号）。
class AccountSettingsSection extends ConsumerStatefulWidget {
  const AccountSettingsSection({super.key});

  @override
  ConsumerState<AccountSettingsSection> createState() =>
      _AccountSettingsSectionState();
}

class _AccountSettingsSectionState
    extends ConsumerState<AccountSettingsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          // 移除默认padding，因为AccountDetailTile内部已有margin
          child: Padding(
            padding: EdgeInsets.zero,
            child: AccountDetailTile(
              onEdit: () => _showProfileSheet(context),
              onLogin: () => _navigateToLogin(context),
            ),
          ),
        ),
        const SavedAccountsSection(),
      ],
    );
  }

  /// 显示账号资料编辑底部面板
  void _showProfileSheet(BuildContext context) {
    final authState = ref.read(authNotifierProvider);
    final accountId = authState.accountId;

    if (accountId == null) {
      AppToast.info(context, context.l10n.settings_pleaseLoginFirst);
      return;
    }

    final accounts = ref.read(accountManagerNotifierProvider).accounts;
    final account = accounts.where((a) => a.id == accountId).firstOrNull;

    if (account == null) {
      AppToast.info(context, context.l10n.settings_accountNotFound);
      return;
    }

    AccountProfileBottomSheet.show(context: context, account: account);
  }

  /// 导航到登录页面
  void _navigateToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }
}
