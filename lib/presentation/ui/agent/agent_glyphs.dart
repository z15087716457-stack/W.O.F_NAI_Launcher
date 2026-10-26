import 'package:flutter/material.dart';
export '../../../core/nai_agent/prompt_set_icons.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_svg_icon.dart';

/// 侧栏用到的线性图标（24 网格、1.7 描边），照抄 `.devin/mockups/agent-redesign/mock.html` 的 `const P`。
abstract final class AgentGlyphs {
  static const psGrid =
      'M4 4h6.5v6.5H4zM13.5 4H20v6.5h-6.5zM4 13.5h6.5V20H4zM13.5 13.5H20V20h-6.5z';
  static const psfilm =
      'M7 4v16M17 4v16M3 9h4M3 15h4M17 9h4M17 15h4M3 4h18v16h-18z';
  static const psheart =
      'M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.3a4.3 4.3 0 0 1 7.5 2.5C19.5 15.4 12 20 12 20z';
  static const pscamera =
      'M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1zM8.5 13a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0 -7 0';
  static const psflag = 'M5 21V4M5 4h11l-2 4 2 4H5';
  static const pssword =
      'M14.5 17.5 3 6V3h3l11.5 11.5M13 19l6-6M16 16l4 4M19 21l2-2';
  static const psflame =
      'M12 21a6 6 0 0 0 6-6c0-4-3-6-4-10-2 2-3 4-3 6-1-1-2-2-2-3.5C7 9 6 11.5 6 15a6 6 0 0 0 6 6z';
  static const psskull =
      'M12 3a8 8 0 0 0-5 14.2V20h10v-2.8A8 8 0 0 0 12 3zM7.5 12a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0M13.5 12a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0';
  static const pswind = 'M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h7';
  static const psrain =
      'M7 15a4 4 0 0 1 .4-8A5.5 5.5 0 0 1 18 8.5 3.3 3.3 0 0 1 17.5 15zM8 18l-1 3M12 18l-1 3M16 18l-1 3';
  static const pssnow =
      'M12 2v20M4 6.5l16 11M20 6.5l-16 11M9 3.5l3 2 3-2M9 20.5l3-2 3 2';
  static const pssun =
      'M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0';
  static const psmoon = 'M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z';
  static const psleaf = 'M5 19c0-8 5-14 15-14 0 10-6 15-14 15M5 19l7-7';
  static const psumbrella =
      'M3 12a9 9 0 0 1 18 0zM12 12v6a2 2 0 0 1-4 0M12 3v0';
  static const pscoffee =
      'M4 9h12v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM16 10h1.5a2.5 2.5 0 0 1 0 5H16M8 3v3M12 3v3';
  static const psmusic =
      'M9 18V5l11-2v13M3 18a3 3 0 1 0 6 0a3 3 0 1 0 -6 0M14 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0';
  static const psmail = 'm3 7 9 6 9-6M3 5h18v14h-18z';
  static const psdoor =
      'M6 21V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v17M3 21h18M14.5 12h.01';
  static const psshirt =
      'M8 3 4 6l2 4 2-1v12h8V9l2 1 2-4-4-3c-.5 1.5-2 2.5-4 2.5S8.5 4.5 8 3z';
  static const psdress = 'M9 3h6l-1 5 4.5 13h-13L10 8zM10 8h4';
  static const pshat = 'M2.5 17.5h19M6 17.5c0-6 2.4-10 6-10s6 4 6 10M9 13h6';
  static const psmask =
      'M4 5l8 3 8-3v8c0 5-8 8-8 8s-8-3-8-8zM7 11h2M15 11h2M9 16q3-2 6 0';
  static const pssmile =
      'M12 3a9 9 0 100 18 9 9 0 000-18M8 9v1M16 9v1M8 14q4 5 8 0';
  static const pshome = 'M3 11l9-8 9 8M6 9v12h12V9M10 21v-7h4v7';
  static const pstree = 'M12 2L5 10h3l-5 7h7v5h4v-5h7l-5-7h3z';
  static const psmountain = 'M2 21L10 4l5 10 3-5 5 12zM7 10l3 2 3-2';
  static const pswave =
      'M2 8q3-4 6 0t6 0 6 0M2 13q3-4 6 0t6 0 6 0M2 18q3-4 6 0t6 0 6 0';
  static const pscar =
      'M4 11l2-6h12l2 6v8H4zM4 11h16M7 15h1M16 15h1M6 19v2M18 19v2';
  static const psgift =
      'M3 8h18v4H3zM5 12v9h14v-9M12 8v13M12 8C3 8 5 1 9 4zM12 8c9 0 7-7 3-4z';
  static const pspalette =
      'M12 3a9 9 0 100 18h2a2 2 0 000-4h-1a2 2 0 010-4h4c6 0 4-10-5-10zM7 9v.01M10 6v.01M15 6v.01M18 9v.01';
  static const help = 'M12 3a9 9 0 100 18 9 9 0 000-18M9.5 9a2.5 2.5 0 115 0c0 2-2.5 2-2.5 4M12 17v.01';
  static const plus = 'M12 5v14M5 12h14';
  static const chevron = 'M6 9l6 6 6-6';
  static const chevronRight = 'M9 6l6 6-6 6';
  static const clock =
      'M12 3.5a8.5 8.5 0 100 17 8.5 8.5 0 000-17zM12 7.5V12l3 2';
  static const more =
      'M5.5 10.9a1.1 1.1 0 100 2.2 1.1 1.1 0 000-2.2zM12 10.9a1.1 1.1 0 100 2.2 1.1 1.1 0 000-2.2zM18.5 10.9a1.1 1.1 0 100 2.2 1.1 1.1 0 000-2.2z';
  static const side =
      'M5.5 4h13A2.5 2.5 0 0121 6.5v11a2.5 2.5 0 01-2.5 2.5h-13A2.5 2.5 0 013 17.5v-11A2.5 2.5 0 015.5 4zM15 4v16';
  static const clip =
      'M20.5 11.5l-8.2 8.2a5 5 0 01-7-7l8.6-8.6a3.4 3.4 0 014.8 4.8l-8.5 8.5a1.8 1.8 0 01-2.6-2.6L15.5 7';
  static const image =
      'M6.5 3.5h11a3 3 0 013 3v11a3 3 0 01-3 3h-11a3 3 0 01-3-3v-11a3 3 0 013-3zM9 7.2a1.8 1.8 0 100 3.6 1.8 1.8 0 000-3.6zM20.5 15l-5-5-11 10.5';
  static const check = 'M5 12.5l4.5 4.5L19 7.5';
  static const close = 'M6.5 6.5l11 11M17.5 6.5l-11 11';
  static const eye =
      'M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12zM12 9.2a2.8 2.8 0 100 5.6 2.8 2.8 0 000-5.6z';
  static const undo = 'M9 14L4 9l5-5M4 9h10.5a5.5 5.5 0 010 11H11';
  static const copy =
      'M11.5 9h6.5a2.5 2.5 0 012.5 2.5V18a2.5 2.5 0 01-2.5 2.5h-6.5A2.5 2.5 0 019 18v-6.5A2.5 2.5 0 0111.5 9zM5 15V5.5A2 2 0 017 3.5h9.5';
  static const refresh = 'M20.5 12a8.5 8.5 0 11-2.6-6.1L20.5 8.5M20.5 3.5v5h-5';
  static const at =
      'M12 8.2a3.8 3.8 0 100 7.6 3.8 3.8 0 000-7.6zM15.8 8.2V13a2.7 2.7 0 005.4 0v-1A9.2 9.2 0 1017.5 19';
  static const search =
      'M11 4.5a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM20 20l-4.2-4.2';
  static const book =
      'M4.5 19V5.5A2.5 2.5 0 017 3h12.5v14H7a2.5 2.5 0 00-2.5 2.5A2.5 2.5 0 007 22h12.5';
  static const layers =
      'M12 3l9 4.5-9 4.5-9-4.5zM3 12l9 4.5 9-4.5M3 16.5L12 21l9-4.5';
  static const folder =
      'M5.5 5.5h4l2 2h7a2 2 0 012 2V17a2 2 0 01-2 2h-13a2 2 0 01-2-2V7.5a2 2 0 012-2z';
  static const file =
      'M14 3.5H7a2 2 0 00-2 2v13a2 2 0 002 2h10a2 2 0 002-2v-10zM14 3.5v5h5';
  static const gen =
      'M12 3.5l1.8 4.7 4.7 1.8-4.7 1.8L12 16.5l-1.8-4.7L5.5 10l4.7-1.8zM18.5 15.5l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z';
  static const shield =
      'M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.2-4.3-1.2-7.5-4.6-7.5-9.2V6z';
  static const bolt = 'M13 2.5L4.5 14H11l-1 7.5L18.5 10H12z';
  static const zoom = 'M14.5 3.5h6v6M9.5 20.5h-6v-6M20.5 3.5l-7 7M3.5 20.5l7-7';
  static const star =
      'M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 17l-5.2 2.7 1-5.9-4.3-4.1 5.9-.8z';
  static const wand =
      'M4 20L15.5 8.5M14 4.5V3M19.5 10H21M17.8 6.2l1-1M12.5 7.5l4 4';
  static const compare =
      'M5 4.5h4a1.5 1.5 0 011.5 1.5v12A1.5 1.5 0 019 19.5H5A1.5 1.5 0 013.5 18V6A1.5 1.5 0 015 4.5zM15 4.5h4A1.5 1.5 0 0120.5 6v12a1.5 1.5 0 01-1.5 1.5h-4a1.5 1.5 0 01-1.5-1.5V6A1.5 1.5 0 0115 4.5z';
  static const hand =
      'M12 21a7 7 0 01-7-7V9.5a1.5 1.5 0 013 0V12M8 12V5.5a1.5 1.5 0 013 0V11M11 11V4.5a1.5 1.5 0 013 0V11M14 11V6a1.5 1.5 0 013 0v8a7 7 0 01-5 7';
  static const pen = 'M4 20h4L19 9l-4-4L4 16zM13.5 6.5l4 4';
  static const trash =
      'M4 7h16M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13M10 11v5.5M14 11v5.5';
  static const terminal = 'M4 17l6-5-6-5M12 19h8';
  static const steer = 'M4 7h11M4 12h7M4 17h11M17 10l3 2-3 2';
  static const send = 'M12 19V5M5.5 11.5L12 5l6.5 6.5';
  static const stop = 'M8.5 8.5h7v7h-7z';
  static const info =
      'M12 8v.01M11 12h1v5h1M12 3.5a8.5 8.5 0 100 17 8.5 8.5 0 000-17z';
  static const alert = 'M12 4l9 16H3zM12 10v4M12 17v.01';
  static const gear =
      'M12 8.5a3.5 3.5 0 100 7 3.5 3.5 0 000-7zM12 3v2.5M12 18.5V21M3 12h2.5M18.5 12H21M5.6 5.6l1.8 1.8M16.6 16.6l1.8 1.8M5.6 18.4l1.8-1.8M16.6 7.4l1.8-1.8';
  static const sliders = 'M4 7h10M18 7h2M4 17h4M12 17h8M16 5v4M10 15v4';
  static const memory =
      'M8 4.5h8A3.5 3.5 0 0119.5 8v8a3.5 3.5 0 01-3.5 3.5H8A3.5 3.5 0 014.5 16V8A3.5 3.5 0 018 4.5zM9 9.5h6M9 12h6M9 14.5h4';
}

String agentPromptSetGlyph(String name) => switch (name) {
  'film' => AgentGlyphs.psfilm,
  'book' => AgentGlyphs.book,
  'star' => AgentGlyphs.star,
  'heart' => AgentGlyphs.psheart,
  'spark' => AgentGlyphs.gen,
  'camera' => AgentGlyphs.pscamera,
  'flag' => AgentGlyphs.psflag,
  'sword' => AgentGlyphs.pssword,
  'shield' => AgentGlyphs.shield,
  'bolt' => AgentGlyphs.bolt,
  'flame' => AgentGlyphs.psflame,
  'skull' => AgentGlyphs.psskull,
  'wind' => AgentGlyphs.pswind,
  'rain' => AgentGlyphs.psrain,
  'snow' => AgentGlyphs.pssnow,
  'sun' => AgentGlyphs.pssun,
  'moon' => AgentGlyphs.psmoon,
  'leaf' => AgentGlyphs.psleaf,
  'umbrella' => AgentGlyphs.psumbrella,
  'coffee' => AgentGlyphs.pscoffee,
  'music' => AgentGlyphs.psmusic,
  'mail' => AgentGlyphs.psmail,
  'door' => AgentGlyphs.psdoor,
  'shirt' => AgentGlyphs.psshirt,
  'dress' => AgentGlyphs.psdress,
  'hat' => AgentGlyphs.pshat,
  'mask' => AgentGlyphs.psmask,
  'smile' => AgentGlyphs.pssmile,
  'home' => AgentGlyphs.pshome,
  'tree' => AgentGlyphs.pstree,
  'mountain' => AgentGlyphs.psmountain,
  'wave' => AgentGlyphs.pswave,
  'car' => AgentGlyphs.pscar,
  'gift' => AgentGlyphs.psgift,
  'palette' => AgentGlyphs.pspalette,
  _ => throw ArgumentError.value(name, 'name', 'Unknown prompt-set glyph'),
};

/// 线性图标。
class AgentIcon extends StatelessWidget {
  const AgentIcon(
    this.path, {
    super.key,
    this.size = 16,
    this.color,
    this.stroke = 1.7,
  });
  final String path;
  final double size;
  final Color? color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? context.ui.muted;
    return UiSvgIcon.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="$stroke" stroke-linecap="round" '
      'stroke-linejoin="round"><path d="$path"/></svg>',
      size: size,
      colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// NAI Agent 标志：对话气泡里一颗星火（「会动手的助手」）。
class AgentMark extends StatelessWidget {
  const AgentMark({super.key, this.size = 16, this.color, this.stroke = 1.6});
  final double size;
  final Color? color;
  final double stroke;

  static const _bubble =
      'M4 6a2.5 2.5 0 012.5-2.5h11A2.5 2.5 0 0120 6v9a2.5 2.5 0 01-2.5 2.5H11l-4.5 3.5v-3.5A2.5 2.5 0 014 15z';
  static const _spark =
      'M12 6.8l1.2 2.6 2.6 1.2-2.6 1.2L12 14.4l-1.2-2.6-2.6-1.2 2.6-1.2z';

  @override
  Widget build(BuildContext context) {
    final ink = color ?? IconTheme.of(context).color ?? context.ui.ink;
    return UiSvgIcon.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$_bubble" fill="none" stroke="#000" stroke-width="$stroke" stroke-linejoin="round"/>'
      '<path d="$_spark" fill="#000"/></svg>',
      size: size,
      colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// Anlas 水滴币。
class AgentAnlas extends StatelessWidget {
  const AgentAnlas({super.key, this.size = 14, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => UiSvgIcon.string(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#000" fill-rule="evenodd" '
    'd="M12 2.5c3.4 4.2 6.5 7.6 6.5 11.5a6.5 6.5 0 01-13 0c0-3.9 3.1-7.3 6.5-11.5zm0 6.2c-1.6 2-3 3.6-3 5.4a3 3 0 006 0c0-1.8-1.4-3.4-3-5.4z"/></svg>',
    size: size,
    colorFilter: ColorFilter.mode(color ?? context.ui.ink, BlendMode.srcIn),
    excludeFromSemantics: true,
  );
}

/// 侧栏收起时开关右上角的小圆点。
enum AgentToggleBadge {
  none,

  /// 有聊天在跑（蓝）。
  running,

  /// 有提问 / 审批 / 付费确认在等你（橙）。
  waiting,

  /// 收起期间有任务跑完了，还没看（绿）。
  done,
}

/// 工具栏里的 Agent 开关（生图页提示词工具区、窗口标题栏）。
/// 开着时浅蓝底 + 蓝描边，和工具栏其他按钮同一套外观。
class AgentToggleButton extends StatefulWidget {
  const AgentToggleButton({
    super.key,
    required this.expanded,
    required this.onPressed,
    required this.tooltip,
    this.size = 28,
    this.badge = AgentToggleBadge.none,
  });
  final bool expanded;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  /// 只在收起（[expanded] 为 false）时画。
  final AgentToggleBadge badge;

  @override
  State<AgentToggleButton> createState() => _AgentToggleButtonState();
}

class _AgentToggleButtonState extends State<AgentToggleButton> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = widget.expanded;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            key: const Key('agent-toggle'),
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? Color.lerp(c.bg, c.accent, .12)
                  : _hover
                  ? c.hover
                  : null,
              borderRadius: BorderRadius.circular(7),
              border: on
                  ? Border.all(color: c.accent.withValues(alpha: .3))
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AgentMark(size: 17, color: on ? c.accent : c.muted),
                if (!on && widget.badge != AgentToggleBadge.none)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      key: Key('agent-toggle-badge-${widget.badge.name}'),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (widget.badge) {
                          AgentToggleBadge.running => c.accent,
                          AgentToggleBadge.waiting => c.warn,
                          _ => c.ok,
                        },
                        border: Border.all(color: c.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 快捷信息图标键 → 侧栏图标路径（设置页的图标选择用同一组键）。
const agentQuickGlyphKeys = [
  'eye',
  'image',
  'spark',
  'layers',
  'pen',
  'search',
  'book',
  'wand',
  'compare',
  'star',
  'sliders',
  'folder',
];

String agentQuickGlyph(String key) => switch (key) {
  'eye' => AgentGlyphs.eye,
  'image' => AgentGlyphs.image,
  'layers' => AgentGlyphs.layers,
  'pen' => AgentGlyphs.pen,
  'search' => AgentGlyphs.search,
  'book' => AgentGlyphs.book,
  'wand' => AgentGlyphs.wand,
  'compare' => AgentGlyphs.compare,
  'star' => AgentGlyphs.star,
  'sliders' => AgentGlyphs.sliders,
  'folder' => AgentGlyphs.folder,
  _ => AgentGlyphs.gen,
};
