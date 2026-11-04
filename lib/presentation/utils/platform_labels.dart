import '../../core/utils/desktop_platform.dart';
import '../../l10n/app_localizations.dart';

// 按平台叫法挑的文案：macOS 上说「访达」「菜单栏」，其他平台用调用处原来的词条。

/// 「在文件夹中显示」「在资源管理器中显示」：macOS 上叫「在访达中显示」；[label] 是其他平台
/// 用的原词条。
String showInFileManagerLabel(AppLocalizations l10n, String label) =>
    usesMacOSConventions ? l10n.common_showInFinder : label;

/// 「最小化到托盘」：Mac 没有托盘，托盘图标在 Mac 上是菜单栏图标，这个功能是把窗口藏起来、
/// 留着菜单栏图标，所以叫「隐藏到菜单栏」。
String minimizeToTrayLabel(AppLocalizations l10n) => usesMacOSConventions
    ? l10n.shortcut_action_hide_to_menu_bar
    : l10n.shortcut_action_minimize_to_tray;

/// 查看器里找不到图时的说明：macOS 上说「在访达里」，不说「在资源管理器里」。
String imageMissingHintLabel(AppLocalizations l10n) => usesMacOSConventions
    ? l10n.imageViewer_missingHintFinder
    : l10n.imageViewer_missingHint;

/// 外观「跟随系统」的说明：macOS 上说「按 macOS 设置」。
String followSystemAppearanceLabel(AppLocalizations l10n) =>
    usesMacOSConventions ? l10n.set_apSystemSubMac : l10n.set_apSystemSub;

/// 存储页的剩余空间：Windows 带盘符（「E: 盘剩余 …」）；macOS 没有盘符（这里拿到的盘只是「/」），
/// 只写剩余多少。
String diskFreeLabel(AppLocalizations l10n, String disk, String size) =>
    usesMacOSConventions
    ? l10n.set_stFreeMac(size)
    : l10n.set_stFree(disk, size);
