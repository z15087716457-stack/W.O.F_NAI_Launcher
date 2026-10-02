import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/account_manager_provider.dart';
import '../../../widgets/auth/add_account_dialog.dart';
import '../../../widgets/common/app_toast.dart';
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
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!auth.isAuthenticated)
          SettingsCard(
            child: SettingsTile(
              title: Text(text('尚未登录', 'Not signed in', '未ログイン')),
              trailing: OutlinedButton(
                onPressed: () => AddAccountDialog.show(context, ref),
                child: Text(context.l10n.settings_goToLogin),
              ),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
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
                      key: const Key('settings-account-auto-login'),
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
