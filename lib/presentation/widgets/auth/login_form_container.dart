import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth_feature_flags.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/auth_mode_provider.dart';
import '../../providers/guest_session_provider.dart';
import 'auth_mode_switcher.dart';
import 'credentials_login_form.dart';
import 'entry_controls.dart';
import 'third_party_api_login_card.dart';
import 'token_login_card.dart';

/// 登录表单容器 - 支持 Token、邮箱密码和第三方站点登录
class LoginFormContainer extends ConsumerWidget {
  /// 登录成功回调
  final VoidCallback? onLoginSuccess;

  /// 是否显示游客入口。仅登录页等未认证语境传 true；
  /// 已登录的添加账号等复用场景默认不显示。
  final bool showGuestEntry;
  final bool compact;

  const LoginFormContainer({
    super.key,
    this.onLoginSuccess,
    this.showGuestEntry = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(authModeProvider);
    final effectiveMode =
        currentMode == AuthMode.credentials &&
            !AuthFeatureFlags.credentialsLoginEnabled
        ? AuthMode.token
        : currentMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthModeSwitcher(compact: compact),
        const SizedBox(height: 18),
        // 切换登录方式时高度平滑过渡，新表单淡入并轻微上移
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            child: switch (effectiveMode) {
              AuthMode.credentials => CredentialsLoginForm(
                key: const Key('credentials_form'),
                onLoginSuccess: onLoginSuccess,
              ),
              AuthMode.token => TokenLoginCard(
                key: const Key('token_form'),
                onLoginSuccess: onLoginSuccess,
              ),
              AuthMode.thirdParty => ThirdPartyApiLoginCard(
                key: const Key('third_party_form'),
                onLoginSuccess: onLoginSuccess,
              ),
            },
          ),
        ),
        if (showGuestEntry) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.auth_localOnlyNote,
                  style: TextStyle(
                    fontSize: 12,
                    color: EntryPalette.of(context).faint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 按钮自带 8px 内边距，右移让文字与卡片内容对齐
              Transform.translate(
                offset: const Offset(8, 0),
                child: EntrySkipButton(
                  key: const Key('auth_guest_entry'),
                  onPressed: () {
                    ref
                        .read(guestSessionNotifierProvider.notifier)
                        .enterGuest();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
