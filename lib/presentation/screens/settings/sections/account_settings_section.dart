import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/account_manager_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../widgets/auth/add_account_dialog.dart';
import '../../../widgets/auth/subscription_expiry_text.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/settings/account_detail_tile.dart';
import '../../../widgets/settings/account_credentials_dialog.dart';
import '../../../widgets/settings/account_profile_sheet.dart';
import '../../../widgets/settings/saved_accounts_section.dart';
import '../widgets/settings_card.dart';
import '../widgets/settings_tile.dart';
import '../widgets/settings_ui_theme.dart';

final accountAutoLoginProvider = FutureProvider<bool>(
  (ref) async =>
      (await SharedPreferences.getInstance()).getBool(
        AuthNotifier.autoLoginPreferenceKey,
      ) ??
      true,
);

class AccountSettingsSection extends ConsumerWidget {
  const AccountSettingsSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String text(String zh, String en, String ja) =>
        settingsText(context, zh, en, ja);
    final auth = ref.watch(authNotifierProvider);
    final accounts = ref.watch(accountManagerNotifierProvider).accounts;
    final account = accounts.where((a) => a.id == auth.accountId).firstOrNull;
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    final loggedIn = auth.isAuthenticated && account != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          title: text('当前账号', 'Current account', '現在のアカウント'),
          child: AccountDetailTile(
            showExpiry: false,
            onEdit: () => AccountProfileBottomSheet.show(
              context: context,
              account: account!,
            ),
            onLogin: () => AddAccountDialog.show(context, ref),
          ),
        ),
        if (loggedIn)
          SettingsCard(
            child: Column(
              children: [
                ref
                    .watch(subscriptionNotifierProvider)
                    .maybeWhen(
                      loaded: (subscription) =>
                          subscription.tier > 0 &&
                              subscription.expiresAt != null
                          ? SettingsTile(
                              title: Text(
                                text(
                                  '订阅有效期',
                                  'Subscription expiry',
                                  'サブスクリプション有効期限',
                                ),
                              ),
                              subtitle: Text(
                                text(
                                  '账号到期后仍保留本地数据。',
                                  'Local data stays available after expiry.',
                                  '有効期限後もローカルデータは保持されます。',
                                ),
                              ),
                              trailing: SubscriptionExpiryText(
                                expiresAt: subscription.expiresAt!,
                              ),
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                SettingsTile(
                  title: Text(text('登录凭据', 'Sign-in credentials', 'ログイン認証')),
                  subtitle: Text(
                    text(
                      '验证并更新此账号的登录令牌。',
                      'Validate and update this account’s sign-in token.',
                      'ログイントークンを確認して更新します。',
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final changed = await showDialog<bool>(
                        context: context,
                        builder: (_) =>
                            AccountCredentialsDialog(account: account),
                      );
                      if (changed == true && context.mounted) {
                        AppToast.success(
                          context,
                          text('登录凭据已更新', 'Credentials updated', '認証情報を更新しました'),
                        );
                      }
                    },
                    child: Text(text('更新凭据', 'Update', '更新')),
                  ),
                ),
              ],
            ),
          ),
        const SavedAccountsSection(showAddButton: false),
        SettingsCard(
          title: text('登录偏好', 'Login preferences', 'ログイン設定'),
          child: Column(
            children: [
              SettingsTile(
                title: Text(text('默认账号', 'Default account', '既定のアカウント')),
                subtitle: Text(
                  text(
                    '在登录页优先选中此账号。',
                    'Preselected on the sign-in page.',
                    'ログイン画面で優先的に選択します。',
                  ),
                ),
                trailing: SizedBox(
                  key: const ValueKey('settings-default-account'),
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(manager.defaultAccount?.id),
                    initialValue: manager.defaultAccount?.id,
                    isExpanded: true,
                    itemHeight: 48,
                    hint: Text(text('暂无账号', 'No accounts', 'アカウントなし')),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: accounts.isEmpty
                        ? null
                        : (id) async {
                            if (id != null) {
                              await manager.setDefaultAccount(id);
                            }
                          },
                  ),
                ),
              ),
              ref
                  .watch(accountAutoLoginProvider)
                  .when(
                    data: (value) => SettingsSwitchTile(
                      title: Text(
                        text('启动时自动登录', 'Sign in automatically', '起動時に自動ログイン'),
                      ),
                      subtitle: Text(
                        text(
                          '使用上次的登录凭据；关闭后，下次启动进入登录页。',
                          'Use the last session. When off, the next launch opens sign-in.',
                          '前回の認証情報を使用します。オフにすると次回はログイン画面を開きます。',
                        ),
                      ),
                      value: value,
                      onChanged: (enabled) async {
                        try {
                          await (await SharedPreferences.getInstance()).setBool(
                            AuthNotifier.autoLoginPreferenceKey,
                            enabled,
                          );
                          ref.invalidate(accountAutoLoginProvider);
                        } catch (_) {
                          if (context.mounted) {
                            AppToast.error(
                              context,
                              text(
                                '登录偏好未保存，请重试。',
                                'Could not save the login preference.',
                                'ログイン設定を保存できませんでした。',
                              ),
                            );
                          }
                        }
                      },
                    ),
                    loading: () => const SizedBox(height: 32),
                    error: (_, _) => Text(
                      text(
                        '无法读取登录偏好。',
                        'Login preferences are unavailable.',
                        'ログイン設定を読み込めません。',
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
