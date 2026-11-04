import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/shortcuts/default_shortcuts.dart';
import '../../../core/shortcuts/shortcut_manager.dart';
import '../../../core/shortcuts/shortcut_config.dart';
import '../../../core/utils/desktop_platform.dart';
import '../../providers/shortcuts_provider.dart';
import '../common/text_editing_shortcuts.dart';
import 'page_focus.dart';

/// 快捷键感知包装器
/// 自动处理快捷键的注册和注销
class ShortcutAwareWidget extends ConsumerStatefulWidget {
  /// 子组件
  final Widget child;

  /// 当前上下文类型
  final ShortcutContext contextType;

  /// 快捷键动作映射
  /// key: 快捷键ID, value: 回调函数
  final Map<String, VoidCallback> shortcuts;

  /// 是否自动聚焦
  final bool autofocus;

  /// 焦点节点（可选）
  final FocusNode? focusNode;

  const ShortcutAwareWidget({
    super.key,
    required this.child,
    required this.contextType,
    required this.shortcuts,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  ConsumerState<ShortcutAwareWidget> createState() =>
      _ShortcutAwareWidgetState();
}

class _ShortcutAwareWidgetState extends ConsumerState<ShortcutAwareWidget> {
  // Keep the subtree (and its focus/navigator) alive while the saved bindings
  // load or a user edits a shortcut. Flutter's Shortcuts refreshes its map.
  late final ShortcutConfig _defaults = ShortcutConfig.createDefault();

  @override
  Widget build(BuildContext context) {
    final config =
        ref.watch(shortcutConfigNotifierProvider).valueOrNull ?? _defaults;
    final bindings = <ShortcutActivator, Intent>{};
    if (config.enableShortcuts) {
      for (final entry in widget.shortcuts.entries) {
        final binding = config.bindings[entry.key];
        if (binding == null ||
            !binding.enabled ||
            (binding.context != ShortcutContext.global &&
                binding.context != widget.contextType)) {
          continue;
        }
        for (final key in AppShortcutManager.activatorsFor(
          binding.effectiveShortcut,
        )) {
          bindings[key] = _ShortcutIntent(
            entry.value,
            yieldsToTextField: _yieldsToTextField(key),
          );
        }
      }
    }
    return Shortcuts(
      shortcuts: bindings,
      child: Actions(
        actions: {_ShortcutIntent: _ShortcutAction()},
        child: ShortcutFocusAnchor(
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Leave standard text shortcuts and unmodified printable input to the editor.
bool _yieldsToTextField(ShortcutActivator key) {
  if (!usesMacOSConventions || key is! SingleActivator) return false;
  if (!key.alt && !key.control && key.meta) {
    if (key.shift) return key.trigger == LogicalKeyboardKey.keyZ;
    return const [
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.keyV,
      LogicalKeyboardKey.keyZ,
      LogicalKeyboardKey.keyY,
    ].contains(key.trigger);
  }
  if (key.alt || key.control || key.meta) return false;
  return key.trigger.keyLabel.runes.length == 1 ||
      key.trigger == LogicalKeyboardKey.space;
}

/// 内部 Intent 类，用于标识快捷键动作
class _ShortcutIntent extends Intent {
  final VoidCallback callback;

  /// 焦点在可编辑文本里时让给输入框（见 [_yieldsToTextField]）
  final bool yieldsToTextField;

  const _ShortcutIntent(this.callback, {this.yieldsToTextField = false});
}

/// 执行快捷键的回调。让给输入框的快捷键，焦点落在可编辑文本里时不启用：
/// 按键接着往上传，由输入框自己处理（⌘A 全选）。
class _ShortcutAction extends Action<_ShortcutIntent> {
  @override
  bool isEnabled(_ShortcutIntent intent) =>
      !intent.yieldsToTextField || !hasEditableTextFocus;

  @override
  Object? invoke(_ShortcutIntent intent) {
    intent.callback();
    return null;
  }
}

/// 全局快捷键包装器
/// 用于在应用级别注册全局快捷键
class GlobalShortcuts extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 快捷键动作映射
  final Map<String, VoidCallback> shortcuts;

  const GlobalShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return ShortcutAwareWidget(
      contextType: ShortcutContext.global,
      shortcuts: shortcuts,
      autofocus: true,
      child: child,
    );
  }
}

/// 页面级快捷键包装器
/// 用于在页面级别注册快捷键
class PageShortcuts extends StatelessWidget {
  /// 子组件
  final Widget child;

  /// 页面上下文类型
  final ShortcutContext contextType;

  /// 快捷键动作映射
  final Map<String, VoidCallback> shortcuts;

  const PageShortcuts({
    super.key,
    required this.child,
    required this.contextType,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return ShortcutAwareWidget(
      contextType: contextType,
      shortcuts: shortcuts,
      autofocus: true,
      child: child,
    );
  }
}
