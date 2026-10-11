import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_progress.dart';
import '../kit/ui_text.dart';
import 'nav_contract.dart';
import 'nav_labels.dart';
import 'nav_rail.dart';

final _thousands = NumberFormat('#,##0');

/// 小标签：高 18、圆角 4、控件底、次要字。
class _Mini extends StatelessWidget {
  const _Mini(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: UiText.sans(
          10.5,
          weight: FontWeight.w600,
          height: 1,
          color: c.muted,
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.margin);
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: margin, color: context.ui.line);
}

/// 悬停加底的行；[onTap] 为 null 时不可点。
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 7,
    this.padding = EdgeInsets.zero,
    this.height,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) => UiPressable(
    onTap: onTap,
    builder: (context, hover) => Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: hover ? context.ui.hover : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    ),
  );
}

/// 文字链接：强调色 12 / w500。
class _Link extends StatelessWidget {
  const _Link(this.text, {super.key, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => UiPressable(
    onTap: onTap,
    builder: (context, hover) => Text(
      text,
      style: UiText.sans(
        12,
        weight: FontWeight.w500,
        color: context.ui.accent,
      ).copyWith(decoration: hover ? TextDecoration.underline : null),
    ),
  );
}

/// 账号弹窗：宽 314、圆角 18、面板底。当前账号、订阅、Anlas 余额、切换列表、添加、管理 / 退出。
class NavAccountPopover extends StatelessWidget {
  const NavAccountPopover({
    super.key,
    required this.data,
    required this.onSwitch,
    required this.onAdd,
    required this.onManage,
    required this.onLogout,
  });

  final NavAccountData data;
  final ValueChanged<String> onSwitch;
  final VoidCallback onAdd;
  final VoidCallback onManage;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final cur = data.current;
    final busy = data.busy;

    String login(NavAccount a) =>
        a.tokenLogin ? l.navShell_accountToken : l.navShell_accountCredentials;
    String? subText(NavAccount a) => switch (a.subscription) {
      null => null,
      NavSubscription(state: NavSubscriptionState.expired) =>
        l.navShell_subExpired,
      final s => l.navShell_subExpires(
        DateFormat('yyyy-MM-dd').format(s.expiresAt),
        s.daysLeft,
      ),
    };
    Color subColor(NavAccount a) =>
        (a.subscription?.state ?? NavSubscriptionState.ok) ==
            NavSubscriptionState.ok
        ? c.muted
        : c.subWarn;

    return UiPopoverSurface(
      key: const Key('account-popover'),
      width: 314,
      radius: 18,
      color: c.panel,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 原型里 11 号字的行盒是整 15（Chrome 取整），这几行固定高度对齐。
          SizedBox(
            height: 15,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.navShell_accountTitle,
                    style: UiText.sans(11, color: c.muted),
                  ),
                ),
                Text(
                  'STUDIO',
                  style: UiText.sans(9, letterSpacing: 1.3, color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            spacing: 12,
            children: [
              NavAvatar(account: cur, size: 42, showSubscriptionDot: false),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            cur?.name ?? l.navShell_accountNotSignedIn,
                            key: const Key('account-popover-current-name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(
                              18,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (cur != null)
                          Container(
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 3,
                              children: [
                                UiGlyph(
                                  UiGlyphs.check,
                                  size: 11,
                                  color: c.accent,
                                ),
                                Text(
                                  l.navShell_accountCurrent,
                                  style: UiText.sans(
                                    10.5,
                                    weight: FontWeight.w500,
                                    height: 1,
                                    color: c.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      cur == null ? l.navShell_accountChoose : login(cur),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(11, color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cur != null && subText(cur) != null) ...[
            const SizedBox(height: 13),
            SizedBox(
              height: 15,
              child: Row(
                spacing: 7,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: subColor(cur),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subText(cur)!,
                      style: UiText.sans(11, color: subColor(cur)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (cur != null && data.anlas != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('account-popover-anlas'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    l.navShell_anlas,
                    style: UiText.sans(12, color: c.muted),
                  ),
                  const Spacer(),
                  Text(
                    _thousands.format(data.anlas),
                    style: UiText.mono(
                      15,
                      weight: FontWeight.w700,
                      height: 1.25,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (data.others.isNotEmpty) ...[
            const _Rule(EdgeInsets.fromLTRB(0, 16, 0, 12)),
            Container(
              height: 15,
              margin: const EdgeInsets.only(bottom: 4),
              child: Text(
                l.navShell_switchAccount,
                style: UiText.sans(11, color: c.muted),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final a in data.others)
                      _Row(
                        key: ValueKey('account-popover-switch-${a.id}'),
                        radius: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 7,
                        ),
                        onTap: busy ? null : () => onSwitch(a.id),
                        child: Row(
                          spacing: 10,
                          children: [
                            NavAvatar(
                              account: a,
                              size: 32,
                              muted: true,
                              showSubscriptionDot: false,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.sans(
                                      13,
                                      weight: FontWeight.w500,
                                      color: c.ink,
                                    ),
                                  ),
                                  Text(
                                    subText(a) ?? login(a),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiText.sans(11, color: subColor(a)),
                                  ),
                                ],
                              ),
                            ),
                            UiGlyph(
                              UiGlyphs.chevronRight,
                              size: 16,
                              color: c.muted,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _AddButton(
            key: const Key('account-popover-add'),
            label: l.navShell_addAccount,
            onTap: busy ? null : onAdd,
          ),
          const _Rule(EdgeInsets.fromLTRB(0, 14, 0, 6)),
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FooterAction(
                  key: const Key('account-popover-manage'),
                  icon: const Icon(StudioIcons.settingsGeneration, size: 14),
                  label: l.navShell_manageAccounts,
                  onTap: onManage,
                ),
                _FooterAction(
                  key: const Key('account-popover-logout'),
                  icon: const UiGlyph(UiGlyphs.logout, size: 14),
                  label: l.navShell_logout,
                  danger: true,
                  onTap: busy || cur == null ? null : onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => UiPressable(
    onTap: onTap,
    builder: (context, hover) {
      final c = context.ui;
      final fg = onTap == null ? c.faint : c.ink;
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: hover ? c.hover : c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            UiGlyph(UiGlyphs.plus, size: 15, color: fg),
            Text(
              label,
              style: UiText.sans(12.5, weight: FontWeight.w500, color: fg),
            ),
          ],
        ),
      );
    },
  );
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => UiPressable(
    onTap: onTap,
    builder: (context, hover) {
      final c = context.ui;
      final fg = onTap == null
          ? c.faint
          : hover
          ? (danger ? c.error : c.ink)
          : c.muted;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: IconTheme.merge(
          data: IconThemeData(color: fg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              icon,
              Text(label, style: UiText.sans(12, color: fg)),
            ],
          ),
        ),
      );
    },
  );
}

/// 后台任务弹层：宽 360。正在生成时生图列第一行；结束的任务在分隔线下面。
class NavTasksPopover extends StatelessWidget {
  const NavTasksPopover({
    super.key,
    required this.data,
    required this.onViewGeneration,
    required this.onCancel,
    required this.onUndo,
  });

  final NavViewData data;
  final VoidCallback onViewGeneration;
  final ValueChanged<String> onCancel;
  final ValueChanged<String> onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final g = data.generation;
    final running = data.tasks.where((t) => !t.finished).toList();
    final finished = data.tasks.where((t) => t.finished).toList();
    String? progressText(NavTask t) {
      final f = t.resolvedFraction;
      final count = t.done != null && t.total != null
          ? '${t.done} / ${t.total}'
          : null;
      final pct = t.fraction != null ? '${(t.fraction! * 100).round()}%' : null;
      final parts = [?t.phase, ?(count ?? pct)];
      return parts.isEmpty && f == null ? null : parts.join(' · ');
    }

    return UiPopoverSurface(
      key: const Key('main-nav-tasks-popover'),
      width: 360,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: Row(
              spacing: 8,
              children: [
                Text(
                  l.navShell_tasksTitle,
                  style: UiText.sans(13, weight: FontWeight.w700, color: c.ink),
                ),
                if (data.runningTasks > 0)
                  _Mini(l.navShell_tasksRunning(data.runningTasks)),
              ],
            ),
          ),
          if (g.state == NavGenerationState.running)
            _TaskRow(
              key: const Key('main-nav-task-generation'),
              icon: Icon(StudioIcons.generation, size: 17, color: c.muted),
              title: NavPage.generation.label(context),
              progress: g.total > 0 ? '${g.current} / ${g.total}' : null,
              fraction: g.ringFraction,
              action: _Link(
                l.navShell_taskView,
                key: const Key('main-nav-task-view'),
                onTap: onViewGeneration,
              ),
            ),
          for (final t in running)
            _TaskRow(
              key: ValueKey('main-nav-task-${t.id}'),
              icon: Icon(t.kind.icon, size: 17, color: c.muted),
              title: t.kind.label(context),
              progress: progressText(t),
              fraction: t.resolvedFraction,
              action: switch (t.action) {
                NavTaskAction.cancel => UiChipButton(
                  key: ValueKey('main-nav-task-cancel-${t.id}'),
                  height: 26,
                  onPressed: () => onCancel(t.id),
                  children: [Text(l.navShell_taskCancel)],
                ),
                NavTaskAction.cancelling => UiChipButton(
                  height: 26,
                  children: [
                    Text(
                      l.navShell_taskCancelling,
                      style: TextStyle(color: c.faint),
                    ),
                  ],
                ),
                _ => null,
              },
            ),
          if (finished.isNotEmpty) ...[
            if (running.isNotEmpty || g.state == NavGenerationState.running)
              const _Rule(EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
            for (final t in finished)
              _TaskRow(
                key: ValueKey('main-nav-task-${t.id}'),
                icon: UiGlyph(UiGlyphs.check, size: 16, color: c.ok),
                title: (t.total ?? t.done) == null
                    ? t.kind.label(context)
                    : l.navShell_taskImages(
                        t.kind.label(context),
                        t.total ?? t.done!,
                      ),
                titleWeight: FontWeight.w400,
                subtitle: l.navShell_taskJustDone,
                action: t.action == NavTaskAction.undo
                    ? _Link(
                        l.navShell_taskUndo,
                        key: ValueKey('main-nav-task-undo-${t.id}'),
                        onTap: () => onUndo(t.id),
                      )
                    : null,
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            child: Text(
              l.navShell_tasksFooter,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.icon,
    required this.title,
    this.titleWeight = FontWeight.w600,
    this.progress,
    this.fraction,
    this.subtitle,
    this.action,
  });

  final Widget icon;
  final String title;
  final FontWeight titleWeight;
  final String? progress;
  final double? fraction;

  /// 有副标题时不画进度条（已结束的任务）。
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: titleWeight,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (progress case final p?)
                      Text(p, style: UiText.mono(11, color: c.muted)),
                  ],
                ),
                if (subtitle case final s?)
                  Text(s, style: UiText.sans(11, color: c.faint))
                else ...[
                  const SizedBox(height: 5),
                  UiProgressBar(value: fraction),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// 右键导航栏弹出的小菜单。
class NavContextMenu extends StatelessWidget {
  const NavContextMenu({super.key, required this.onCustomize});
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) => UiPopoverSurface(
    width: 200,
    radius: 10,
    padding: const EdgeInsets.all(4),
    child: _Row(
      key: const Key('main-nav-customize-menu'),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      onTap: onCustomize,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.navShell_customizeMenu,
          style: UiText.sans(12.5, color: context.ui.ink),
        ),
      ),
    ),
  );
}

/// 自定义导航栏：勾掉不常用的页面、“按住 Ctrl 显示编号”开关。改动立即生效。
class NavCustomizePanel extends StatelessWidget {
  const NavCustomizePanel({
    super.key,
    required this.data,
    required this.onHiddenChanged,
    required this.onCtrlNumbersChanged,
    required this.onDone,
  });

  final NavViewData data;
  final ValueChanged<Set<NavPage>> onHiddenChanged;
  final ValueChanged<bool> onCtrlNumbersChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return UiPopoverSurface(
      key: const Key('main-nav-customize'),
      width: 320,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l.navShell_customize,
              style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 10),
            child: Text(
              l.navShell_customizeNote,
              style: UiText.sans(12, color: c.muted),
            ),
          ),
          for (final p in navGroups.expand((g) => g))
            _CheckRow(
              key: ValueKey('main-nav-customize-${p.name}'),
              page: p,
              checked: navLockedPages.contains(p) || !data.hidden.contains(p),
              locked: navLockedPages.contains(p),
              keys: data.shortcuts[p],
              onTap: () => onHiddenChanged(
                data.hidden.contains(p)
                    ? (Set.of(data.hidden)..remove(p))
                    : (Set.of(data.hidden)..add(p)),
              ),
            ),
          const _Rule(EdgeInsets.all(8)),
          _Row(
            key: const Key('main-nav-customize-ctrl'),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: () => onCtrlNumbersChanged(!data.ctrlNumbers),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.navShell_ctrlNumbers,
                    style: UiText.sans(13, color: c.ink),
                  ),
                ),
                UiSwitch(value: data.ctrlNumbers),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Row(
              children: [
                UiChipButton(
                  key: const Key('main-nav-customize-reset'),
                  onPressed: () {
                    onHiddenChanged(const {});
                    onCtrlNumbersChanged(true);
                  },
                  children: [Text(l.navShell_reset)],
                ),
                const Spacer(),
                UiChipButton(
                  key: const Key('main-nav-customize-done'),
                  primary: true,
                  onPressed: onDone,
                  children: [Text(l.navShell_done)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    super.key,
    required this.page,
    required this.checked,
    required this.locked,
    required this.keys,
    required this.onTap,
  });

  final NavPage page;
  final bool checked;
  final bool locked;
  final List<String>? keys;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final fg = checked ? c.ink : c.faint;
    return _Row(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: locked ? null : onTap,
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: checked ? c.accent : null,
              borderRadius: BorderRadius.circular(4),
              border: checked ? null : Border.all(color: c.strong, width: 1.5),
            ),
            child: checked
                ? const UiGlyph(
                    UiGlyphs.check,
                    size: 11,
                    strokeWidth: 3,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(
            width: 22,
            child: Icon(
              page.icon,
              size: 18,
              color: checked ? c.ink.withValues(alpha: .7) : c.faint,
            ),
          ),
          Expanded(
            child: Text(
              page.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(13, color: fg),
            ),
          ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: UiGlyph(UiGlyphs.lock, size: 13, color: c.faint),
            ),
          if (keys case final k?) UiKeycaps(k),
        ],
      ),
    );
  }
}
