import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/datasources/remote/nai_auth_api_service.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import 'entry_controls.dart';

/// Token 登录卡片组件
class TokenLoginCard extends ConsumerStatefulWidget {
  /// 登录成功回调
  final VoidCallback? onLoginSuccess;

  const TokenLoginCard({super.key, this.onLoginSuccess});

  @override
  ConsumerState<TokenLoginCard> createState() => _TokenLoginCardState();
}

class _TokenLoginCardState extends ConsumerState<TokenLoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    // 清除可能残留的全局错误状态
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = context.l10n;
    final busy = authState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntryTextField(
            label: l10n.settings_nickname,
            controller: _nicknameController,
            hintText: l10n.auth_nicknameHint,
            textInputAction: TextInputAction.next,
            enabled: !busy,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.auth_nicknameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          EntryTextField(
            label: 'API Token',
            controller: _tokenController,
            hintText: 'pst-',
            monospace: true,
            obscureText: _obscureToken,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            enabled: !busy,
            labelAction: EntryLink(
              label: l10n.auth_getToken,
              tooltip: l10n.auth_tokenGuide,
              external: true,
              onTap: _openTokenGuide,
            ),
            trailing: [
              EntryFieldAction(
                icon: Icons.content_paste,
                tooltip: l10n.common_paste,
                onPressed: busy ? null : _pasteFromClipboard,
              ),
              EntryFieldAction(
                icon: _obscureToken
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                tooltip: l10n.auth_toggleVisibility,
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.auth_tokenRequired;
              }
              if (!NAIAuthApiService.isValidTokenFormat(value)) {
                return l10n.auth_tokenInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          EntryPrimaryButton(
            label: l10n.auth_validateAndLogin,
            busy: busy,
            busyLabel: l10n.auth_loggingIn,
            onPressed: _handleLogin,
          ),
          if (authState.hasError && !busy) ...[
            const SizedBox(height: 12),
            EntryAlert(
              title: _getErrorMessage(authState.errorCode),
              hint: _getErrorRecoveryHint(
                authState.errorCode,
                authState.httpStatusCode,
              ),
              actionLabel: _isNetworkError(authState.errorCode)
                  ? l10n.common_retry
                  : null,
              onAction: _handleLogin,
            ),
          ],
        ],
      ),
    );
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _tokenController.text = data!.text!.trim();
    }
  }

  /// 打开 Token 获取指引
  Future<void> _openTokenGuide() async {
    const url = 'https://novelai.net/settings';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// 处理登录
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final token = _tokenController.text.trim();
    final nickname = _nicknameController.text.trim();

    // 保存 notifier 引用，避免 widget disposed 后使用 ref
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);

    // 执行登录验证
    final success = await authNotifier.loginWithToken(
      token,
      displayName: nickname,
    );

    if (success) {
      // 默认保存账号（首次使用）
      final identifier = 'token_${DateTime.now().millisecondsSinceEpoch}';
      final account = await accountNotifier.addAccount(
        identifier: identifier,
        token: token,
        nickname: nickname,
        setAsDefault: true,
      );

      // 更新 AuthState 中的 accountId
      await authNotifier.loginWithToken(
        token,
        accountId: account.id,
        displayName: account.displayName,
      );

      // 检查 widget 是否仍然 mounted
      if (mounted) {
        widget.onLoginSuccess?.call();
      }
    } else {
      // 登录失败
      // 注意：这里不需要手动显示 Toast，因为 LoginScreen 监听了 AuthState 变化
      // 当 AuthState 变为 error 时，LoginScreen 会自动显示 Toast
      // 保留这里的 else 分支是为了逻辑清晰，如果有其他本地状态需要处理可以在这里添加
    }
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
        return context.l10n.auth_tokenInvalid;
      case AuthErrorCode.credentialsLoginUnavailable:
        return context.l10n.auth_error_credentialsLoginUnavailable;
      case AuthErrorCode.serverError:
        return context.l10n.auth_error_serverError;
      case AuthErrorCode.unknown:
      default:
        return context.l10n.auth_error_unknown;
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
}
