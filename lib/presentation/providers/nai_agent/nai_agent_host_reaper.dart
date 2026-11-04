import 'dart:async';

import '../../../core/utils/app_logger.dart';
import 'nai_agent_workspace_controller.dart';

/// Closes the Agent's Node hosts after the panel has been closed, with nothing
/// running, for [idle]; reopening the panel starts the selected chat's host
/// again and it resumes the conversation from its session file.
///
/// The user chose 30 minutes. The clock starts when the panel is closed and no
/// chat is busy; opening the panel or any run stops it.
class NaiAgentHostReaper {
  NaiAgentHostReaper(this.controller, {this.idle = defaultIdle}) {
    _panelOpen = controller.settings.panelExpanded;
    controller.addListener(_changed);
    _changed();
  }

  static const defaultIdle = Duration(minutes: 30);

  final NaiAgentWorkspaceController controller;
  final Duration idle;
  Timer? _timer;
  bool _panelOpen = false, _released = false, _releasing = false;
  bool _disposed = false;

  void _changed() {
    if (_disposed) return;
    final open = controller.settings.panelExpanded;
    final opened = open && !_panelOpen;
    _panelOpen = open;
    if (opened && _released && !_releasing) _restore();
    if (open || _releasing || !controller.hostsIdle) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer(idle, () => unawaited(_release()));
  }

  Future<void> _release() async {
    _timer = null;
    if (_disposed || _panelOpen || !controller.hostsIdle) return;
    _releasing = true;
    try {
      if (await controller.releaseIdleHosts()) {
        _released = true;
        AppLogger.i(
          'Agent panel closed and idle for ${idle.inMinutes} min, '
              'closed its Node host',
          'NaiAgent',
        );
      }
    } finally {
      _releasing = false;
    }
    // Opened while the hosts were shutting down.
    if (!_disposed && _panelOpen && _released) _restore();
  }

  void _restore() {
    _released = false;
    unawaited(
      controller.loadHistory().catchError((Object error) {
        AppLogger.w('Agent host restart failed: $error', 'NaiAgent');
      }),
    );
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    controller.removeListener(_changed);
  }
}
