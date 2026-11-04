import 'package:flutter/foundation.dart';

/// 默认快捷键定义
/// 包含所有快捷键的ID常量和默认配置
class ShortcutIds {
  // 页面导航快捷键
  static const String navigateToGeneration = 'navigate_to_generation';
  static const String navigateToLocalGallery = 'navigate_to_local_gallery';
  static const String navigateToOnlineGallery = 'navigate_to_online_gallery';
  static const String navigateToTagLibrary = 'navigate_to_tag_library';
  static const String navigateToStatistics = 'navigate_to_statistics';
  static const String navigateToSettings = 'navigate_to_settings';
  static const String navigateToVibeLibrary = 'navigate_to_vibe_library';
  static const String navigateToStyleExplore = 'navigate_to_style_explore';
  static const String navigateToPreciseRefLibrary =
      'navigate_to_precise_ref_library';
  static const String navigateToTagWiki = 'navigate_to_tag_wiki';

  // 生成页面快捷键
  static const String generateImage = 'generate_image';
  static const String cancelGeneration = 'cancel_generation';
  static const String clearPrompt = 'clear_prompt';
  static const String togglePromptMode = 'toggle_prompt_mode';
  static const String openTagLibrary = 'open_tag_library';
  static const String saveImage = 'save_image';
  static const String upscaleImage = 'upscale_image';
  static const String copyImage = 'copy_image';
  static const String fullscreenPreview = 'fullscreen_preview';
  static const String openParamsPanel = 'open_params_panel';
  static const String openHistoryPanel = 'open_history_panel';
  static const String reuseParams = 'reuse_params';

  // 画廊快捷键（查看器）
  static const String previousImage = 'previous_image';
  static const String nextImage = 'next_image';
  static const String zoomIn = 'zoom_in';
  static const String zoomOut = 'zoom_out';
  static const String resetZoom = 'reset_zoom';
  static const String toggleFullscreen = 'toggle_fullscreen';
  static const String closeViewer = 'close_viewer';
  static const String toggleInfoPanel = 'toggle_info_panel';
  static const String toggleFavorite = 'toggle_favorite';
  static const String copyPrompt = 'copy_prompt';
  static const String reuseGalleryParams = 'reuse_gallery_params';
  static const String deleteImage = 'delete_image';

  // 画廊快捷键（列表）
  static const String previousPage = 'previous_page';
  static const String nextPage = 'next_page';
  static const String refreshGallery = 'refresh_gallery';
  static const String focusSearch = 'focus_search';
  static const String enterSelectionMode = 'enter_selection_mode';
  static const String clearFilter = 'clear_filter';
  static const String toggleCategoryPanel = 'toggle_category_panel';
  static const String jumpToDate = 'jump_to_date';
  static const String openFolder = 'open_folder';

  // 随机配置页面快捷键

  // 全局应用快捷键
  static const String minimizeToTray = 'minimize_to_tray';
  static const String quitApp = 'quit_app';
  static const String showShortcutHelp = 'show_shortcut_help';
  static const String toggleTheme = 'toggle_theme';
  static const String openResourceWindow = 'open_resource_window';

  // Vibe库快捷键
  static const String vibeImport = 'vibe_import';
  static const String vibeExport = 'vibe_export';

  // Vibe详情页快捷键
  static const String vibeDetailSendToGeneration =
      'vibe_detail_send_to_generation';
  static const String vibeDetailExport = 'vibe_detail_export';
  static const String vibeDetailRename = 'vibe_detail_rename';
  static const String vibeDetailDelete = 'vibe_detail_delete';
  static const String vibeDetailToggleFavorite = 'vibe_detail_toggle_favorite';
  static const String vibeDetailPrevSubVibe = 'vibe_detail_prev_sub_vibe';
  static const String vibeDetailNextSubVibe = 'vibe_detail_next_sub_vibe';
}

/// 快捷键上下文枚举
enum ShortcutContext {
  global, // 全局
  generation, // 生成页
  gallery, // 画廊列表
  viewer, // 图片查看器
  settings, // 设置
  input, // 输入框（编辑状态）
  vibeDetail, // Vibe 详情页
}

/// 默认快捷键配置
class DefaultShortcuts {
  static const navigation = <String, String>{
    ShortcutIds.navigateToGeneration: 'ctrl+1',
    ShortcutIds.navigateToStyleExplore: 'ctrl+2',
    ShortcutIds.navigateToLocalGallery: 'ctrl+3',
    ShortcutIds.navigateToOnlineGallery: 'ctrl+4',
    ShortcutIds.navigateToTagLibrary: 'ctrl+5',
    ShortcutIds.navigateToVibeLibrary: 'ctrl+6',
    ShortcutIds.navigateToPreciseRefLibrary: 'ctrl+7',
    ShortcutIds.navigateToTagWiki: 'ctrl+8',
    ShortcutIds.navigateToStatistics: 'ctrl+9',
    ShortcutIds.navigateToSettings: 'ctrl+comma',
  };

  /// 获取所有默认快捷键配置
  /// 格式: Map<快捷键ID, 默认快捷键字符串>
  static Map<String, String> get all => _forPlatform({
    // 页面导航
    ...navigation,

    // 生成页面
    ShortcutIds.generateImage: 'ctrl+enter',
    ShortcutIds.cancelGeneration: 'escape',
    ShortcutIds.clearPrompt: 'ctrl+l',
    ShortcutIds.togglePromptMode: 'ctrl+m',
    ShortcutIds.openTagLibrary: 'ctrl+t',
    ShortcutIds.upscaleImage: 'ctrl+u',
    ShortcutIds.saveImage: 'ctrl+s',
    ShortcutIds.copyImage: 'ctrl+shift+c',
    ShortcutIds.fullscreenPreview: 'f11',
    ShortcutIds.openParamsPanel: 'alt+p',
    ShortcutIds.openHistoryPanel: 'alt+h',
    ShortcutIds.reuseParams: 'ctrl+r',

    // 画廊查看器
    ShortcutIds.previousImage: 'arrowleft',
    ShortcutIds.nextImage: 'arrowright',
    ShortcutIds.zoomIn: 'equal',
    ShortcutIds.zoomOut: 'minus',
    ShortcutIds.resetZoom: '0',
    ShortcutIds.toggleFullscreen: 'f11',
    ShortcutIds.closeViewer: 'escape',
    ShortcutIds.toggleInfoPanel: 'i',
    ShortcutIds.toggleFavorite: 'f',
    ShortcutIds.copyPrompt: 'ctrl+c',
    ShortcutIds.reuseGalleryParams: 'ctrl+r',
    ShortcutIds.deleteImage: 'delete',

    // 画廊列表
    ShortcutIds.previousPage: 'pageup',
    ShortcutIds.nextPage: 'pagedown',
    ShortcutIds.refreshGallery: 'f5',
    ShortcutIds.focusSearch: 'ctrl+f',
    ShortcutIds.enterSelectionMode: 'ctrl+a',
    ShortcutIds.clearFilter: 'ctrl+shift+c',
    ShortcutIds.toggleCategoryPanel: 'ctrl+b',
    ShortcutIds.jumpToDate: 'ctrl+g',
    ShortcutIds.openFolder: 'ctrl+o',

    // 全局
    ShortcutIds.minimizeToTray: 'ctrl+shift+m',
    ShortcutIds.quitApp: 'ctrl+q',
    ShortcutIds.showShortcutHelp: 'f1',
    ShortcutIds.toggleTheme: 'ctrl+shift+t',
    // Unassigned action placeholder; users/main agent can bind a shortcut.
    ShortcutIds.openResourceWindow: '',

    // Vibe库
    ShortcutIds.vibeImport: 'ctrl+i',
    ShortcutIds.vibeExport: 'ctrl+shift+e',

    // Vibe详情页
    ShortcutIds.vibeDetailSendToGeneration: 'enter',
    ShortcutIds.vibeDetailExport: 'ctrl+e',
    ShortcutIds.vibeDetailRename: 'f2',
    ShortcutIds.vibeDetailDelete: 'delete',
    ShortcutIds.vibeDetailToggleFavorite: 'f',
    ShortcutIds.vibeDetailPrevSubVibe: 'arrowleft',
    ShortcutIds.vibeDetailNextSubVibe: 'arrowright',
  });

  // macOS 上按不到或被系统占用的默认键，换成 Mac 的习惯键：(W.O.F 原值, Mac 值)，
  // Mac 值为空表示 Mac 上默认不设键。配置里的 ctrl 在 Mac 上是 ⌘、meta 是 Control（见 ShortcutParser）。
  // 读配置时会把存下来的默认值刷新成当前的（ShortcutConfig.withCurrentDefaults），不用另外迁移。
  static const macOverrides = <String, (String, String)>{
    // Mac 键盘上的「删除」是 ⌫；不用单独的 ⌫，免得在输入框里删字时被截走。⌘⌫ 同访达「移到废纸篓」
    ShortcutIds.deleteImage: ('delete', 'ctrl+backspace'),
    ShortcutIds.vibeDetailDelete: ('delete', 'ctrl+backspace'),
    // 窗口键交给系统菜单：⌘M 最小化到程序坞、⌘Q 退出、⌘W 关窗口、⌘H 隐藏。
    // 「隐藏到菜单栏」「退出应用」Mac 上默认不设键（⌘H、⌘Q 就是）；
    // 生成页「切换正/负面」让出 ⌘M，改 ⇧⌘M（「隐藏到托盘」的默认是它，macOS 上空出来了）
    ShortcutIds.minimizeToTray: ('ctrl+shift+m', ''),
    ShortcutIds.quitApp: ('ctrl+q', ''),
    ShortcutIds.togglePromptMode: ('ctrl+m', 'ctrl+shift+m'),
    // F11 被系统「显示桌面」占用：查看器全屏、生成页全屏预览用 Mac 的全屏键 ⌃⌘F（同系统菜单「进入全屏」）。
    // 两者在不同页面，不算冲突；别的页面里 ⌃⌘F 照样交给系统菜单
    ShortcutIds.toggleFullscreen: ('f11', 'ctrl+meta+f'),
    ShortcutIds.fullscreenPreview: ('f11', 'ctrl+meta+f'),
    // ⌥ 加字母在 Mac 上用来打特殊字符（⌥P 是 π、⌥H 是 ˙），快捷键组件不给输入框让路，
    // 在提示词里打这些字符会被截走：参数面板、历史面板改 ⌃⌘P、⌃⌘H
    ShortcutIds.openParamsPanel: ('alt+p', 'ctrl+meta+p'),
    ShortcutIds.openHistoryPanel: ('alt+h', 'ctrl+meta+h'),
    // F 键在 Mac 上要按 fn：刷新用 ⌘R，快捷键帮助用 ⌘/
    ShortcutIds.refreshGallery: ('f5', 'ctrl+r'),
    ShortcutIds.showShortcutHelp: ('f1', 'ctrl+slash'),
  };

  static Map<String, String> _forPlatform(Map<String, String> defaults) {
    if (defaultTargetPlatform != TargetPlatform.macOS) return defaults;
    return {
      ...defaults,
      for (final MapEntry(key: id, value: (_, mac)) in macOverrides.entries)
        id: mac,
    };
  }

  /// 获取快捷键的上下文
  static ShortcutContext getContext(String shortcutId) {
    switch (shortcutId) {
      // 页面导航
      case ShortcutIds.navigateToGeneration:
      case ShortcutIds.navigateToLocalGallery:
      case ShortcutIds.navigateToOnlineGallery:
      case ShortcutIds.navigateToTagLibrary:
      case ShortcutIds.navigateToStatistics:
      case ShortcutIds.navigateToSettings:
      case ShortcutIds.navigateToVibeLibrary:
      case ShortcutIds.navigateToStyleExplore:
      case ShortcutIds.navigateToPreciseRefLibrary:
      case ShortcutIds.navigateToTagWiki:
      case ShortcutIds.minimizeToTray:
      case ShortcutIds.quitApp:
      case ShortcutIds.showShortcutHelp:
      case ShortcutIds.toggleTheme:
      case ShortcutIds.openResourceWindow:
        return ShortcutContext.global;

      // 生成页面
      case ShortcutIds.generateImage:
      case ShortcutIds.cancelGeneration:
      case ShortcutIds.clearPrompt:
      case ShortcutIds.togglePromptMode:
      case ShortcutIds.openTagLibrary:
      case ShortcutIds.upscaleImage:
      case ShortcutIds.fullscreenPreview:
      case ShortcutIds.saveImage:
      case ShortcutIds.copyImage:
      case ShortcutIds.openParamsPanel:
      case ShortcutIds.openHistoryPanel:
      case ShortcutIds.reuseParams:
        return ShortcutContext.generation;

      // 画廊查看器
      case ShortcutIds.previousImage:
      case ShortcutIds.nextImage:
      case ShortcutIds.zoomIn:
      case ShortcutIds.zoomOut:
      case ShortcutIds.resetZoom:
      case ShortcutIds.toggleFullscreen:
      case ShortcutIds.closeViewer:
      case ShortcutIds.toggleInfoPanel:
      case ShortcutIds.toggleFavorite:
      case ShortcutIds.copyPrompt:
      case ShortcutIds.reuseGalleryParams:
      case ShortcutIds.deleteImage:
        return ShortcutContext.viewer;

      // 画廊列表
      case ShortcutIds.previousPage:
      case ShortcutIds.nextPage:
      case ShortcutIds.refreshGallery:
      case ShortcutIds.focusSearch:
      case ShortcutIds.enterSelectionMode:
      case ShortcutIds.clearFilter:
      case ShortcutIds.toggleCategoryPanel:
      case ShortcutIds.jumpToDate:
      case ShortcutIds.openFolder:
        return ShortcutContext.gallery;

      // Vibe库
      case ShortcutIds.vibeImport:
      case ShortcutIds.vibeExport:
        return ShortcutContext.global;

      // Vibe详情页
      case ShortcutIds.vibeDetailSendToGeneration:
      case ShortcutIds.vibeDetailExport:
      case ShortcutIds.vibeDetailRename:
      case ShortcutIds.vibeDetailDelete:
      case ShortcutIds.vibeDetailToggleFavorite:
      case ShortcutIds.vibeDetailPrevSubVibe:
      case ShortcutIds.vibeDetailNextSubVibe:
        return ShortcutContext.vibeDetail;

      default:
        return ShortcutContext.global;
    }
  }

  /// 获取快捷键的i18n键
  static String getI18nKey(String shortcutId) {
    return 'shortcut_action_$shortcutId';
  }

  /// 获取快捷键的默认启用状态
  static bool isEnabledByDefault(String shortcutId) {
    // 所有快捷键默认启用
    return true;
  }
}
