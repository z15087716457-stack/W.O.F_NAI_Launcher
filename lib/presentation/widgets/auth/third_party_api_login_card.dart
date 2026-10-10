import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/nai_api_endpoint.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import 'entry_controls.dart';

/// 第三方 NAI-compatible API 登录卡片。
class ThirdPartyApiLoginCard extends ConsumerStatefulWidget {
  final VoidCallback? onLoginSuccess;

  const ThirdPartyApiLoginCard({super.key, this.onLoginSuccess});

  @override
  ConsumerState<ThirdPartyApiLoginCard> createState() =>
      _ThirdPartyApiLoginCardState();
}

class _ThirdPartyApiLoginCardState
    extends ConsumerState<ThirdPartyApiLoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _mainApiController = TextEditingController();
  final _imageApiController = TextEditingController();
  final _tokenController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);
  }

  @override
  void dispose() {
    _mainApiController.dispose();
    _imageApiController.dispose();
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
            label: l10n.auth_thirdPartyApiSite,
            controller: _mainApiController,
            hintText: 'https://example.com/api',
            monospace: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            enabled: !busy,
            validator: _validateMainApiUrl,
          ),
          const SizedBox(height: 14),
          EntryTextField(
            label: l10n.auth_imageApiSiteOptional,
            controller: _imageApiController,
            hintText: l10n.auth_imageApiSiteHint,
            monospace: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            enabled: !busy,
            validator: _validateImageApiUrl,
          ),
          const SizedBox(height: 14),
          EntryTextField(
            label: l10n.settings_nickname,
            controller: _nicknameController,
            hintText: l10n.auth_thirdPartyNicknameHint,
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
            hintText: l10n.auth_thirdPartyTokenHint,
            monospace: true,
            obscureText: _obscureToken,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            enabled: !busy,
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
              if (value == null || value.trim().isEmpty) {
                return l10n.auth_tokenRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Text(
            l10n.auth_thirdPartyCompatibilityHint,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.55,
              color: EntryPalette.of(context).faint,
            ),
          ),
          const SizedBox(height: 14),
          EntryPrimaryButton(
            label: l10n.auth_validateAndLogin,
            busy: busy,
            busyLabel: l10n.auth_loggingIn,
            onPressed: _handleLogin,
          ),
          if (authState.hasError && !busy) ...[
            const SizedBox(height: 12),
            EntryAlert(title: _getErrorMessage(authState.errorCode)),
          ],
        ],
      ),
    );
  }

  String? _validateMainApiUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.auth_thirdPartyApiSiteRequired;
    }

    try {
      NaiApiEndpointConfig.fromInput(
        mainBaseUrl: value,
        imageBaseUrl: _imageApiController.text,
      );
      return null;
    } on ArgumentError catch (e) {
      return e.message.toString();
    }
  }

  String? _validateImageApiUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      NaiApiEndpointConfig.fromInput(
        mainBaseUrl: _mainApiController.text,
        imageBaseUrl: value,
      );
      return null;
    } on ArgumentError catch (e) {
      return e.message.toString();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _tokenController.text = data!.text!.trim();
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final endpoint = NaiApiEndpointConfig.fromInput(
      mainBaseUrl: _mainApiController.text,
      imageBaseUrl: _imageApiController.text,
    );
    final token = _tokenController.text.trim();
    final nickname = _nicknameController.text.trim();

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);

    final success = await authNotifier.loginWithThirdPartyToken(
      token,
      apiEndpoint: endpoint,
      displayName: nickname,
    );

    if (!success) return;

    final account = await accountNotifier.addAccount(
      identifier: endpoint.mainBaseUrl,
      token: token,
      nickname: nickname,
      setAsDefault: true,
      apiEndpoint: endpoint,
    );

    await authNotifier.loginWithThirdPartyToken(
      token,
      apiEndpoint: endpoint,
      accountId: account.id,
      displayName: account.displayName,
    );

    if (mounted) {
      widget.onLoginSuccess?.call();
    }
  }

  String _getErrorMessage(AuthErrorCode? errorCode) {
    return switch (errorCode) {
      AuthErrorCode.networkTimeout => context.l10n.auth_error_networkTimeout,
      AuthErrorCode.networkError => context.l10n.auth_error_networkError,
      AuthErrorCode.authFailed => context.l10n.auth_error_authFailed,
      AuthErrorCode.tokenInvalid => context.l10n.auth_tokenInvalid,
      AuthErrorCode.credentialsLoginUnavailable =>
        context.l10n.auth_error_credentialsLoginUnavailable,
      AuthErrorCode.serverError => context.l10n.auth_error_serverError,
      AuthErrorCode.unknown || null => context.l10n.auth_error_unknown,
    };
  }
}
