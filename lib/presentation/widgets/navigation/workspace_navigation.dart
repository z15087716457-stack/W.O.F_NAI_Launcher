import 'package:flutter/widgets.dart';

import '../../router/app_branch.dart';

/// Lets Settings protect its draft when any workspace navigation is requested.
class SettingsDeparture {
  void Function(VoidCallback)? _guard;
  void attach(void Function(VoidCallback) guard) => _guard = guard;
  void detach(void Function(VoidCallback) guard) {
    if (_guard == guard) _guard = null;
  }

  void leave(VoidCallback navigate) {
    final guard = _guard;
    if (guard == null) {
      navigate();
    } else {
      guard(navigate);
    }
  }
}

class WorkspaceNavigation extends InheritedWidget {
  const WorkspaceNavigation({
    super.key,
    required this.select,
    required this.closeSettings,
    required this.settingsDeparture,
    required super.child,
  });
  final ValueChanged<AppBranch> select;
  final VoidCallback closeSettings;
  final SettingsDeparture settingsDeparture;
  static WorkspaceNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkspaceNavigation>();
  @override
  bool updateShouldNotify(WorkspaceNavigation old) =>
      old.settingsDeparture != settingsDeparture;
}
