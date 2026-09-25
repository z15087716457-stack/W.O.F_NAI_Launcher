import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../providers/auth_mode_provider.dart';
import '../../providers/auth_provider.dart';
import 'entry_controls.dart';
import 'login_form_container.dart';

/// 添加账号对话框
///
/// 导航栏账号菜单与设置页账号列表共用：重置登录模式、清除遗留错误状态后
/// 弹出内嵌 [LoginFormContainer] 的对话框，样式与登录页的表单卡一致。
abstract final class AddAccountDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    // 重置 AuthMode 为当前默认登录模式
    ref.read(authModeNotifierProvider.notifier).reset();
    // 立即清除之前的登录错误状态（无延迟）
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);

    return showDialog(
      context: context,
      builder: (dialogContext) {
        final palette = EntryPalette.of(dialogContext);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: palette.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.auth_addAccount,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(8, 0),
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(
                            dialogContext,
                          ).closeButtonTooltip,
                          iconSize: 18,
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 登录表单容器（Token、邮箱密码、第三方站点）
                  LoginFormContainer(
                    onLoginSuccess: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
