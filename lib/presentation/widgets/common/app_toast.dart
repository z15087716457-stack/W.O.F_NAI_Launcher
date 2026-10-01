import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info, progress }

abstract class ToastController {
  void updateProgress(double? progress, {String? message, String? subtitle});
  void complete({String? message});
  void fail({String? message});
  void dismiss();
}

class _NoOpToastController implements ToastController {
  @override
  void updateProgress(double? progress, {String? message, String? subtitle}) {}
  @override
  void complete({String? message}) {}
  @override
  void fail({String? message}) {}
  @override
  void dismiss() {}
}

/// One measured stack per overlay keeps long messages and progress aligned.
class AppToast {
  static final _stacks = <OverlayState, _ToastStackManager>{};
  static void success(BuildContext context, String message) =>
      _show(context, message, ToastType.success);
  static void error(BuildContext context, String message) =>
      _show(context, message, ToastType.error);
  static void warning(BuildContext context, String message) =>
      _show(context, message, ToastType.warning);
  static void info(BuildContext context, String message) =>
      _show(context, message, ToastType.info);
  static void successOnOverlay(OverlayState? overlay, String message) =>
      _onOverlay(overlay, message, ToastType.success);
  static void errorOnOverlay(OverlayState? overlay, String message) =>
      _onOverlay(overlay, message, ToastType.error);

  static _ToastStackManager? _manager(OverlayState? overlay) {
    if (overlay == null || !overlay.mounted) return null;
    return _stacks.putIfAbsent(
      overlay,
      () => _ToastStackManager(overlay, () => _stacks.remove(overlay)),
    );
  }

  static ToastController showProgress(
    BuildContext context,
    String message, {
    double? progress,
    String? subtitle,
  }) {
    final manager = _manager(Overlay.maybeOf(context, rootOverlay: true));
    if (manager == null) return _NoOpToastController();
    // A replaced controller owns only its own record, never the next task.
    for (final record in manager.records.toList()) {
      if (record.type == ToastType.progress) record.dismiss();
    }
    return manager.add(
      message,
      ToastType.progress,
      progress: progress,
      subtitle: subtitle,
    );
  }

  static void _onOverlay(
    OverlayState? overlay,
    String message,
    ToastType type,
  ) => _manager(overlay)?.add(message, type);
  static void _show(BuildContext context, String message, ToastType type) {
    if (Platform.isWindows) {
      _onOverlay(Overlay.maybeOf(context, rootOverlay: true), message, type);
      return;
    }
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = _style(scheme, type);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: scheme.surfaceContainerLow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        content: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onSurface)),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _ToastStackManager {
  _ToastStackManager(this.overlay, this.onDispose) {
    entry = OverlayEntry(builder: (context) => _ToastStack(this));
    overlay.insert(entry);
  }
  final OverlayState overlay;
  final VoidCallback onDispose;
  late final OverlayEntry entry;
  final records = <_ToastRecord>[];
  bool disposed = false;
  _ToastRecord add(
    String message,
    ToastType type, {
    double? progress,
    String? subtitle,
  }) {
    final record = _ToastRecord(this, message, type, progress, subtitle);
    records.add(record);
    if (type != ToastType.progress) record.scheduleClose();
    changed();
    return record;
  }

  void changed() {
    if (!disposed && overlay.mounted) entry.markNeedsBuild();
  }

  void remove(_ToastRecord record) {
    if (disposed || !records.remove(record)) return;
    record.close();
    if (records.isEmpty) {
      dispose();
      entry.remove();
      entry.dispose();
    } else {
      changed();
    }
  }

  void dispose() {
    if (disposed) return;
    disposed = true;
    for (final record in records) {
      record.close();
    }
    records.clear();
    onDispose();
  }
}

class _ToastRecord implements ToastController {
  _ToastRecord(
    this.manager,
    this.message,
    this.type,
    double? value,
    this.subtitle,
  ) : progress = value?.clamp(0, 1).toDouble();
  final _ToastStackManager manager;
  String message;
  String? subtitle;
  ToastType type;
  double? progress;
  bool closing = false, closed = false, hovered = false;
  Timer? timer;
  DateTime? expiresAt;
  Duration remaining = const Duration(seconds: 4);
  void scheduleClose() {
    timer?.cancel();
    remaining = const Duration(seconds: 4);
    expiresAt = null;
    if (!hovered) resume();
  }

  void pause() {
    hovered = true;
    timer?.cancel();
    if (expiresAt case final date?) {
      remaining = date.difference(DateTime.now());
      if (remaining.isNegative) remaining = Duration.zero;
    }
    expiresAt = null;
  }

  void resume() {
    hovered = false;
    if (type == ToastType.progress || closed || closing) return;
    timer?.cancel();
    expiresAt = DateTime.now().add(remaining);
    timer = Timer(remaining, dismiss);
  }

  @override
  void updateProgress(double? value, {String? message, String? subtitle}) {
    if (closed || closing || type != ToastType.progress) return;
    progress = value?.clamp(0, 1).toDouble();
    if (message != null) this.message = message;
    if (subtitle != null) this.subtitle = subtitle;
    manager.changed();
  }

  void finish(ToastType type, String? message) {
    if (closed || closing || this.type != ToastType.progress) return;
    this.type = type;
    progress = null;
    if (message != null) this.message = message;
    scheduleClose();
    manager.changed();
  }

  @override
  void complete({String? message}) => finish(ToastType.success, message);
  @override
  void fail({String? message}) => finish(ToastType.error, message);
  @override
  void dismiss() {
    if (closed || closing) return;
    timer?.cancel();
    closing = true;
    manager.changed();
  }

  void close() {
    closed = true;
    timer?.cancel();
  }
}

class _ToastStack extends StatefulWidget {
  const _ToastStack(this.manager);
  final _ToastStackManager manager;
  @override
  State<_ToastStack> createState() => _ToastStackState();
}

class _ToastStackState extends State<_ToastStack> {
  @override
  void dispose() {
    widget.manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top: media.padding.top + 14,
      right: 14,
      child: SizedBox(
        width: (media.size.width - 28).clamp(0, 350).toDouble(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (media.size.height - media.padding.vertical - 28).clamp(
              0,
              double.infinity,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final record in widget.manager.records)
                  Padding(
                    key: ObjectKey(record),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ToastCard(record),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard(this.record);
  final _ToastRecord record;
  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  bool _dismissing = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dismissing) {
      if (widget.record.closing) {
        _dismiss();
      } else if (MediaQuery.disableAnimationsOf(context)) {
        _animation.value = 1;
      } else {
        _animation.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.record.closing) _dismiss();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) await _animation.reverse();
      if (mounted) widget.record.manager.remove(widget.record);
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record,
        theme = Theme.of(context),
        scheme = theme.colorScheme;
    final (icon, color) = _style(scheme, record.type);
    final language = Localizations.localeOf(context).languageCode;
    String label(String zh, String en, String ja) => language == 'zh'
        ? zh
        : language == 'ja'
        ? ja
        : en;
    final title = switch (record.type) {
      ToastType.success => label('已完成', 'Completed', '完了'),
      ToastType.error => label('操作失败', 'Action failed', '操作失敗'),
      ToastType.warning => label('请留意', 'Please note', 'ご注意'),
      ToastType.info => label('提示', 'Notice', 'お知らせ'),
      ToastType.progress => label('正在处理', 'In progress', '処理中'),
    };
    final card = MouseRegion(
      onEnter: (_) => record.pause(),
      onExit: (_) => record.resume(),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: scheme.surfaceContainerLow,
          elevation: 0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.brightness == Brightness.dark ? .2 : .09,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(13, 12, 9, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.55,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (record.subtitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          record.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            height: 1.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (record.type == ToastType.progress) ...[
                        const SizedBox(height: 10),
                        if (MediaQuery.disableAnimationsOf(context) &&
                            record.progress == null)
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else
                          LinearProgressIndicator(
                            value: record.progress,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                            color: color,
                            backgroundColor: color.withValues(alpha: .1),
                          ),
                        if (record.progress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(record.progress! * 100).round()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    key: const Key('toast-dismiss'),
                    padding: EdgeInsets.zero,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: record.dismiss,
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return card;
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic),
        ),
        child: card,
      ),
    );
  }
}

(IconData, Color) _style(ColorScheme scheme, ToastType type) => switch (type) {
  ToastType.success => (Icons.check_rounded, const Color(0xff26825f)),
  ToastType.error => (Icons.priority_high_rounded, scheme.error),
  ToastType.warning => (Icons.warning_amber_rounded, const Color(0xffb47a16)),
  ToastType.info => (Icons.info_outline_rounded, scheme.primary),
  ToastType.progress => (Icons.sync_rounded, scheme.primary),
};
