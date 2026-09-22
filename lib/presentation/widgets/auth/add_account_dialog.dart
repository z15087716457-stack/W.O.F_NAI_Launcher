import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../providers/auth_mode_provider.dart';
import '../../providers/auth_provider.dart';
import 'login_form_container.dart';

/// 添加账号对话框
///
/// 导航栏账号菜单与设置页账号列表共用：重置登录模式、清除遗留错误状态后
/// 弹出内嵌 [LoginFormContainer] 的对话框。
abstract final class AddAccountDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    // 重置 AuthMode 为当前默认登录模式
    ref.read(authModeNotifierProvider.notifier).reset();
    // 立即清除之前的登录错误状态（无延迟）
    ref.read(authNotifierProvider.notifier).clearError(delayMs: 0);

    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      context.l10n.auth_addAccount,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                // 登录表单容器（支持账号密码和Token两种方式）
                LoginFormContainer(
                  onLoginSuccess: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
