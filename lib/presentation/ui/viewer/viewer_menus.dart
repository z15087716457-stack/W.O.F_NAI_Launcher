import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'viewer_contract.dart';
import 'viewer_format.dart';
import 'viewer_info.dart';
import 'viewer_page.dart';
import 'viewer_parts.dart';

/// 菜单行：32 高、圆角 7、13 号字、图标 15（原型 `.mi`）。
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
    this.danger = false,
    this.active = false,
    this.indent = 0,
  });
  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  final Widget? trailing;
  final bool danger;

  /// 子菜单展开中（底色常亮）。
  final bool active;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 32,
        padding: EdgeInsets.only(left: 10 + indent, right: 10),
        decoration: BoxDecoration(
          color: hover || active ? c.control : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: danger ? c.error : c.muted),
          child: Row(
            spacing: 10,
            children: [
              ?icon,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(13, color: danger ? c.error : c.ink),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _icon(String glyph, {Color? color, bool filled = false}) => Builder(
  builder: (context) => UiGlyph(
    glyph,
    size: 15,
    filled: filled,
    color: color ?? IconTheme.of(context).color,
  ),
);

Widget _kb(BuildContext context, String text) =>
    Text(text, style: UiText.mono(11, color: context.ui.faint));

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
    color: context.ui.line,
  );
}

String _keyOf(ViewerViewData d, ViewerCommand c) {
  final a = d.keys[c]?.firstOrNull ?? ViewerKeys.defaults[c]?.firstOrNull;
  return a == null ? '' : viewerKeyLabels(a).join(' ');
}

/// 收藏集：收藏（F）· 各收藏集勾选 · 新建收藏集。勾选不关菜单，可以连着点。
class _CollectionsList extends StatelessWidget {
  const _CollectionsList();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final item = data.current;
    if (item == null) return const SizedBox.shrink();
    final list = data.collections;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
          child: Text(
            l10n.imageViewer_collections,
            style: UiText.sans(11, weight: FontWeight.w600, color: c.faint),
          ),
        ),
        _Row(
          key: const Key('viewer-col-favorite'),
          icon: _icon(
            UiGlyphs.heartLib,
            color: item.favorite ? c.fav : null,
            filled: item.favorite,
          ),
          label: l10n.imageViewer_favorite,
          trailing: _kb(context, _keyOf(data, ViewerCommand.favorite)),
          onTap: () => a.onSetFavorite(item.key, !item.favorite),
        ),
        if (list != null && list.isNotEmpty) ...[
          const _Sep(),
          for (final col in list)
            _Row(
              key: Key('viewer-col-${col.id}'),
              indent: col.depth * 14.0,
              icon: col.member
                  ? _icon(UiGlyphs.check, color: c.accent)
                  : _icon(UiGlyphs.plus, color: c.faint),
              label: col.name,
              onTap: () => a.onToggleCollection(item.key, col.id, !col.member),
            ),
        ],
        const _Sep(),
        _Row(
          key: const Key('viewer-col-new'),
          icon: _icon(UiGlyphs.plus),
          label: l10n.imageViewer_newCollection,
          onTap: () {
            scope.controller.closePopover();
            a.onCreateCollection(item.key);
          },
        ),
      ],
    );
  }
}

/// 心形按钮弹出的收藏集菜单（和更多菜单里的子菜单是同一份）。
class ViewerCollectionsMenu extends StatelessWidget {
  const ViewerCollectionsMenu({super.key});

  @override
  Widget build(BuildContext context) => const UiPopoverSurface(
    key: Key('viewer-collections'),
    width: 210,
    padding: EdgeInsets.all(5),
    child: _CollectionsList(),
  );
}

/// 更多：复制图片 / 复制文件路径 / 复制全部提示词 / 存为块 · 加入收藏集 › / 移动到 / 复制到 · 移到回收站。
/// “加入收藏集”在左边展开子菜单（同一个浮层，向左长）。
class ViewerMoreMenu extends StatefulWidget {
  const ViewerMoreMenu({super.key});

  @override
  State<ViewerMoreMenu> createState() => _ViewerMoreMenuState();
}

class _ViewerMoreMenuState extends State<ViewerMoreMenu> {
  var _sub = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final data = scope.data;
    final item = data.current;
    if (item == null) return const SizedBox.shrink();
    final has = data.actions.contains;
    final meta =
        data.detail?.key == item.key &&
        data.detail!.status == ViewerMetaStatus.ready;
    final gallery = data.mode == ViewerMode.gallery;
    void run(ViewerAction a) {
      scope.controller.closePopover();
      scope.actions.onAction(item.key, a);
    }

    final rows = <Widget>[
      if (has(ViewerAction.copyImage))
        _Row(
          key: const Key('viewer-more-copyImage'),
          icon: _icon(UiGlyphs.copy),
          label: l10n.imageViewer_copyImage,
          onTap: () => run(ViewerAction.copyImage),
        ),
      if (has(ViewerAction.copyPath))
        _Row(
          key: const Key('viewer-more-copyPath'),
          icon: _icon(ViewerGlyphs.link),
          label: l10n.imageViewer_copyPath,
          onTap: () => run(ViewerAction.copyPath),
        ),
      if (has(ViewerAction.copyAllPrompts) && meta)
        _Row(
          key: const Key('viewer-more-copyAllPrompts'),
          icon: _icon(UiGlyphs.copy),
          label: l10n.imageViewer_copyAllPrompts,
          onTap: () => run(ViewerAction.copyAllPrompts),
        ),
      if (has(ViewerAction.saveAsBlock) && meta)
        _Row(
          key: const Key('viewer-more-saveAsBlock'),
          icon: _icon(ViewerGlyphs.block),
          label: l10n.imageViewer_saveBlockEllipsis,
          onTap: () => run(ViewerAction.saveAsBlock),
        ),
      if (gallery) ...[
        const _Sep(),
        _Row(
          key: const Key('viewer-more-collections'),
          icon: _icon(UiGlyphs.heartLib),
          label: l10n.imageViewer_addToCollection,
          active: _sub,
          trailing: UiGlyph(UiGlyphs.chevronRight, size: 13, color: c.faint),
          onTap: () => setState(() => _sub = !_sub),
        ),
        if (has(ViewerAction.moveTo))
          _Row(
            key: const Key('viewer-more-moveTo'),
            icon: _icon(ViewerGlyphs.moveTo),
            label: l10n.imageViewer_moveTo,
            onTap: () => run(ViewerAction.moveTo),
          ),
        if (has(ViewerAction.copyTo))
          _Row(
            key: const Key('viewer-more-copyTo'),
            icon: _icon(ViewerGlyphs.layers),
            label: l10n.imageViewer_copyTo,
            onTap: () => run(ViewerAction.copyTo),
          ),
        const _Sep(),
        _Row(
          key: const Key('viewer-more-delete'),
          icon: _icon(ViewerGlyphs.trash),
          danger: true,
          label: l10n.imageViewer_moveToTrash,
          trailing: _kb(context, _keyOf(data, ViewerCommand.delete)),
          onTap: () {
            scope.controller.closePopover();
            scope.controller.requestDelete();
          },
        ),
      ],
    ];
    // 子菜单顶端对齐“加入收藏集”这一行（它前面有几行、一条分隔线）。
    final before = [
      ViewerAction.copyImage,
      ViewerAction.copyPath,
      if (meta) ViewerAction.copyAllPrompts,
      if (meta) ViewerAction.saveAsBlock,
    ].where(has).length;
    final top = before * 32.0 + 9 - 6;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (_sub)
          Padding(
            padding: EdgeInsets.only(top: top),
            child: const ViewerCollectionsMenu(),
          ),
        UiPopoverSurface(
          key: const Key('viewer-more'),
          width: 268,
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ],
    );
  }
}

/// 缩放比例：适应 / 50% / 100% / 200% / 400%。
class ViewerZoomMenu extends StatelessWidget {
  const ViewerZoomMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ViewerPageScope.of(context);
    final z = scope.controller.zoom;
    final data = scope.data;
    UiMenuItem pct(double s, {String? trailing}) => UiMenuItem(
      key: Key('viewer-zoom-${(s * 100).round()}'),
      label: '${(s * 100).round()}%',
      trailing: trailing,
      checked: !z.fitted && (z.scale - s).abs() < 1e-6,
      onTap: () => z.setScale(s),
    );
    return UiMenu(
      key: const Key('viewer-zoom-list'),
      width: 160,
      onClose: scope.controller.closePopover,
      items: [
        UiMenuItem(
          key: const Key('viewer-zoom-fit'),
          label: l10n.imageViewer_zoomFitShort,
          trailing: _keyOf(data, ViewerCommand.zoomFit),
          checked: z.fitted,
          onTap: z.reset,
        ),
        pct(.5),
        pct(1, trailing: _keyOf(data, ViewerCommand.zoomActual)),
        pct(2),
        pct(4),
      ],
    );
  }
}

/// 快捷键表（按 ? 打开）：浏览 / 缩放 / 操作三组，按当前快捷键设置显示。始终深色。
class ViewerHelpDialog extends StatelessWidget {
  const ViewerHelpDialog({super.key, required this.onClose});

  /// 再按一次 ? 关闭（Esc 由弹窗宿主处理）。
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final data = ViewerPageScope.of(context).data;
    final gallery = data.mode == ViewerMode.gallery;
    List<String> k(ViewerCommand c) {
      final a =
          data.keys[c]?.firstOrNull ?? ViewerKeys.defaults[c]?.firstOrNull;
      return a == null ? const [] : viewerKeyLabels(a);
    }

    Widget row(List<String> keys, String label, {String? text}) => SizedBox(
      height: 26,
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 96,
            child: text != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ViewerKeycap(text),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ViewerKeycaps(keys),
                  ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(13, color: const Color(0xFFE8E8E8)),
            ),
          ),
        ],
      ),
    );
    Widget group(String title, List<Widget> rows) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              title,
              style: UiText.sans(
                12,
                weight: FontWeight.w700,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );

    final help = [
      ...?data.keys[ViewerCommand.help],
      if (data.keys[ViewerCommand.help] == null)
        ...ViewerKeys.defaults[ViewerCommand.help]!,
    ];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            help.any((a) => a.accepts(e, HardwareKeyboard.instance))) {
          onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _helpBox(context, row, group, k, gallery, data),
    );
  }

  Widget _helpBox(
    BuildContext context,
    Widget Function(List<String>, String, {String? text}) row,
    Widget Function(String, List<Widget>) group,
    List<String> Function(ViewerCommand) k,
    bool gallery,
    ViewerViewData data,
  ) {
    final l10n = context.l10n;
    return Container(
      key: const Key('viewer-help'),
      width: 900,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border.all(color: const Color(0xFF2C2C2C)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 68,
            offset: Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 10,
            children: [
              Text(
                l10n.imageViewer_helpTitle,
                style: UiText.sans(
                  15,
                  weight: FontWeight.w700,
                  color: const Color(0xFFEEEEEE),
                ),
              ),
              Text(
                l10n.imageViewer_helpHint,
                style: UiText.sans(12, color: const Color(0xFF888888)),
              ),
              const Spacer(),
              ViewerKeycaps(k(ViewerCommand.help)),
              Text(
                l10n.imageViewer_helpClose,
                style: UiText.sans(12, color: const Color(0xFF888888)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 26,
            children: [
              group(l10n.imageViewer_helpBrowse, [
                row([
                  ...k(ViewerCommand.previous),
                  ...k(ViewerCommand.next),
                ], l10n.imageViewer_helpPrevNext),
                row([
                  ...k(ViewerCommand.first),
                  ...k(ViewerCommand.last),
                ], l10n.imageViewer_helpFirstLast),
                row(k(ViewerCommand.toggleInfo), l10n.imageViewer_helpInfo),
                row(k(ViewerCommand.fullscreen), l10n.imageViewer_fullscreen),
                row(k(ViewerCommand.close), l10n.imageViewer_helpClose2),
              ]),
              group(l10n.imageViewer_helpZoom, [
                row([
                  ...k(ViewerCommand.zoomIn),
                  ...k(ViewerCommand.zoomOut),
                ], l10n.imageViewer_helpZoomInOut),
                row(k(ViewerCommand.zoomFit), l10n.imageViewer_hintFit),
                row(k(ViewerCommand.zoomActual), l10n.imageViewer_helpActual),
                row(
                  const [],
                  l10n.imageViewer_helpWheel,
                  text: l10n.imageViewer_keyWheel,
                ),
                row(
                  const [],
                  l10n.imageViewer_helpDouble,
                  text: l10n.imageViewer_keyDouble,
                ),
              ]),
              group(l10n.imageViewer_helpActions, [
                if (data.actions.contains(ViewerAction.reuse))
                  row(k(ViewerCommand.reuse), l10n.imageViewer_reuse),
                row(
                  k(ViewerCommand.copyPrompt),
                  l10n.imageViewer_helpCopyPrompt,
                ),
                if (gallery) ...[
                  row(k(ViewerCommand.favorite), l10n.imageViewer_favorite),
                  row(k(ViewerCommand.delete), l10n.imageViewer_moveToTrash),
                  row(k(ViewerCommand.undo), l10n.imageViewer_helpUndo),
                ],
                if (data.actions.contains(ViewerAction.save))
                  row(k(ViewerCommand.save), l10n.imageViewer_save),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

/// 受保护的图删除前确认。
class ViewerDeleteDialog extends StatelessWidget {
  const ViewerDeleteDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final name = ViewerPageScope.of(context).data.detail?.fileName;
    return SizedBox(
      key: const Key('viewer-delete'),
      width: 420,
      child: UiPopoverSurface(
        radius: 14,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: UiGlyph(
                      ViewerGlyphs.trash,
                      size: 16,
                      color: c.error,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          l10n.imageViewer_protectedTitle,
                          style: UiText.sans(
                            15,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          [?name, l10n.imageViewer_protectedBody].join('\n'),
                          style: UiText.sans(
                            12.5,
                            color: c.muted,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            UiDialogFooter(
              children: [
                const Spacer(),
                UiBtn(
                  onTap: onCancel,
                  children: [Text(l10n.imageViewer_cancel)],
                ),
                UiBtn(
                  key: const Key('viewer-delete-confirm'),
                  tone: UiBtnTone.primary,
                  color: c.onBrand,
                  onTap: onConfirm,
                  children: [Text(l10n.imageViewer_moveToTrash)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
