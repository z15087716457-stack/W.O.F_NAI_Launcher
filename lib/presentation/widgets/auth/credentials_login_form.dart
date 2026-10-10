import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../providers/auth_mode_provider.dart';
import '../../providers/auth_provider.dart';
import 'entry_controls.dart';

/// 邮箱密码登录表单
class CredentialsLoginForm extends ConsumerStatefulWidget {
  /// 登录成功回调
  final VoidCallback? onLoginSuccess;

  const CredentialsLoginForm({super.key, this.onLoginSuccess});

  @override
  ConsumerState<CredentialsLoginForm> createState() =>
      _CredentialsLoginFormState();
}

class _CredentialsLoginFormState extends ConsumerState<CredentialsLoginForm> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  final formKey = GlobalKey<FormState>();

  // 本地错误状态（用于添加账号场景，避免影响全局 authState）
  AuthErrorCode? _localErrorCode;
  int? _localHttpStatusCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 清除可能残留的全局错误状态
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obscurePassword = ref.watch(obscurePasswordProvider);
    final authState = ref.watch(authNotifierProvider);
    final l10n = context.l10n;

    // 统一错误状态：优先使用本地错误（添加账号场景），否则使用全局状态
    final errorCode = _localErrorCode ?? authState.errorCode;
    final httpStatusCode = _localHttpStatusCode ?? authState.httpStatusCode;
    // 统一加载状态
    final isLoading = _isLoading || authState.isLoading;
    final hasError =
        !isLoading && (_localErrorCode != null || authState.hasError);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntryTextField(
            label: l10n.auth_email,
            controller: emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.auth_emailRequired;
              }
              if (!value.contains('@')) {
                return l10n.auth_emailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          EntryTextField(
            label: l10n.auth_password,
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            enabled: !isLoading,
            trailing: [
              EntryFieldAction(
                icon: obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                tooltip: l10n.auth_toggleVisibility,
                onPressed: () => ref
                    .read(authModeNotifierProvider.notifier)
                    .togglePasswordVisibility(),
              ),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.auth_passwordRequired;
              }
              if (value.length < 6) {
                return l10n.auth_passwordTooShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          // 窄窗口或放大字号时“忘记密码”换到下一行
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EntryCheckbox(
                value: ref.watch(autoLoginProvider),
                label: l10n.auth_autoLogin,
                onChanged: (_) => ref
                    .read(authModeNotifierProvider.notifier)
                    .toggleAutoLogin(),
              ),
              Transform.translate(
                offset: const Offset(8, 0),
                child: EntryGhostButton(
                  label: l10n.auth_forgotPassword,
                  onPressed: _openPasswordReset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EntryPrimaryButton(
            label: l10n.auth_loginButton,
            busy: isLoading,
            busyLabel: l10n.auth_loggingIn,
            onPressed: _handleLogin,
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            EntryAlert(
              title: _getErrorMessage(errorCode),
              hint: _getErrorRecoveryHint(errorCode, httpStatusCode),
              actionLabel: _isNetworkError(errorCode)
                  ? l10n.common_retry
                  : null,
              onAction: _handleLogin,
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorMessage(AuthErrorCode? errorCode) {
    switch (errorCode) {
      case AuthErrorCode.networkTimeout:
        return context.l10n.auth_error_networkTimeout;
      case AuthErrorCode.networkError:
        return context.l10n.auth_error_networkError;
      case AuthErrorCode.authFailed:
        return context.l10n.auth_error_authFailed;
      case AuthErrorCode.tokenInvalid:
        return context.l10n.auth_error_authFailed;
      case AuthErrorCode.credentialsLoginUnavailable:
        return context.l10n.auth_error_credentialsLoginUnavailable;
      case AuthErrorCode.serverError:
        return context.l10n.auth_error_serverError;
      case AuthErrorCode.unknown:
      default:
        return context.l10n.auth_loginFailed;
    }
  }

  /// 获取错误恢复建议
  String? _getErrorRecoveryHint(AuthErrorCode? errorCode, int? httpStatusCode) {
    switch (errorCode) {
      case AuthErrorCode.networkTimeout:
        return context.l10n.api_error_timeout_hint;
      case AuthErrorCode.networkError:
        return context.l10n.api_error_network_hint;
      case AuthErrorCode.authFailed:
        if (httpStatusCode == 401) {
          return context.l10n.api_error_401_hint;
        }
        return context.l10n.api_error_401_hint;
      case AuthErrorCode.tokenInvalid:
        return context.l10n.api_error_401_hint;
      case AuthErrorCode.credentialsLoginUnavailable:
        return context.l10n.auth_error_credentialsLoginUnavailable_hint;
      case AuthErrorCode.serverError:
        if (httpStatusCode == 503) {
          return context.l10n.api_error_503_hint;
        }
        return context.l10n.api_error_500_hint;
      case AuthErrorCode.unknown:
      default:
        return null;
    }
  }

  /// 检查是否为网络错误
  bool _isNetworkError(AuthErrorCode? errorCode) {
    return errorCode == AuthErrorCode.networkTimeout ||
        errorCode == AuthErrorCode.networkError;
  }

  /// 打开密码重置页面
  Future<void> _openPasswordReset() async {
    const url = ApiConstants.passwordResetUrl;
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// 处理登录
  Future<void> _handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    // 清除之前的本地错误状态
    setState(() {
      _localErrorCode = null;
      _localHttpStatusCode = null;
      _isLoading = true;
    });

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final currentAuthState = ref.read(authNotifierProvider);

    // 如果当前已登录（添加账号场景），使用不影响全局状态的登录方法
    if (currentAuthState.isAuthenticated) {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();
      final result = await authNotifier.tryAddAccount(email, password);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        widget.onLoginSuccess?.call();
      } else {
        // 登录失败，设置本地错误状态
        setState(() {
          _localErrorCode = result.errorCode;
          _localHttpStatusCode = result.httpStatusCode;
        });
      }
    } else {
      // 未登录状态，使用正常的登录流程
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text.trim();
      final success = await authNotifier.loginWithCredentials(email, password);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        widget.onLoginSuccess?.call();
      }
    }
  }
}
