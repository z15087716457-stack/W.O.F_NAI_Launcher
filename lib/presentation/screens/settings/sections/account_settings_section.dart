import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
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
    final auth = ref.watch(authNotifierProvider);
    final accounts = ref.watch(accountManagerNotifierProvider).accounts;
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!auth.isAuthenticated)
          SettingsCard(
            child: SettingsTile(
              title: Text(context.l10n.auth_notSignedIn),
              trailing: OutlinedButton(
                onPressed: () => AddAccountDialog.show(context, ref),
                child: Text(context.l10n.settings_goToLogin),
              ),
            ),
          ),
        const SavedAccountsSection(showAddButton: false),
        SettingsCard(
          title: context.l10n.settings_loginPreferences,
          child: Column(
            children: [
              SettingsTile(
                title: Text(context.l10n.settings_defaultAccount2),
                subtitle: Text(context.l10n.settings_preselectedSignInPage),
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
                    hint: Text(context.l10n.settings_noAccounts),
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
                      title: Text(context.l10n.settings_signInAutomatically),
                      subtitle: Text(
                        context.l10n.settings_useLastSessionOffNext,
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
                              context.l10n.settings_couldNotSaveLoginPreference,
                            );
                          }
                        }
                      },
                    ),
                    loading: () => const SizedBox(height: 32),
                    error: (_, _) =>
                        Text(context.l10n.settings_loginPreferencesUnavailable),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
