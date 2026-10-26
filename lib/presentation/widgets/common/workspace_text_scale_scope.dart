import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/workspace_text_settings_provider.dart';

/// Wiring host: exposes the preference without scaling navigation or controls.
class WorkspaceTextScaleHost extends ConsumerWidget {
  const WorkspaceTextScaleHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _WorkspaceTextScale(
    scale: ref.watch(workspaceFontScaleProvider),
    child: child,
  );
}

class _WorkspaceTextScale extends InheritedWidget {
  const _WorkspaceTextScale({required this.scale, required super.child});
  final double scale;
  @override
  bool updateShouldNotify(_WorkspaceTextScale oldWidget) =>
      scale != oldWidget.scale;
}

class _InlineTextScale extends InheritedWidget {
  const _InlineTextScale({required super.child});
  @override
  bool updateShouldNotify(_InlineTextScale oldWidget) => false;
}

/// A creative-text region. Nested regions replace (never multiply) scaling.
/// Pure UI components remain usable without Riverpod; their wiring owns a host.
class WorkspaceTextScaleScope extends StatelessWidget {
  const WorkspaceTextScaleScope({super.key, required this.child});
  final Widget child;

  /// Explicit creative scale only (not inherited system/settings scaling).
  static double scaleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InlineTextScale>() != null
      ? 1
      : context
                .dependOnInheritedWidgetOfExactType<_WorkspaceTextScale>()
                ?.scale ??
            1;

  /// WidgetSpan already scales its entire child. Avoid scaling its text twice.
  static Widget inline(Widget child) =>
      _InlineTextScale(child: MediaQuery.withNoTextScaling(child: child));

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_InlineTextScale>() !=
        null) {
      return child;
    }
    final scale = context
        .dependOnInheritedWidgetOfExactType<_WorkspaceTextScale>()
        ?.scale;
    if (scale == null) return child;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}
