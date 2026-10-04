import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/krita/bridge_session.dart';
import 'bridge_draft_snapshot.dart';
import 'krita_bridge_notifier.dart';

enum BridgeAgentPhase { waiting, working, synced, changed, failed }

class BridgeAgentFeedback {
  const BridgeAgentFeedback(this.phase, {this.activity});
  final BridgeAgentPhase phase;
  final BridgeActivity? activity;
}

final bridgeAgentFeedbackProvider =
    StateNotifierProvider<BridgeAgentFeedbackController, BridgeAgentFeedback>((
      ref,
    ) {
      final controller = BridgeAgentFeedbackController(
        ref.read(kritaBridgeNotifierProvider),
        ref.read(bridgeDraftVersionProvider),
      );
      ref.listen(kritaBridgeNotifierProvider, (_, next) {
        controller.updateDraft(ref.read(bridgeDraftVersionProvider));
        controller.updateBridge(next);
      });
      ref.listen(bridgeDraftVersionProvider, (_, next) {
        controller.updateDraft(next);
      });
      return controller;
    });

/// Presentation timing never blocks requests or changes their completion order.
class BridgeAgentFeedbackController extends StateNotifier<BridgeAgentFeedback> {
  BridgeAgentFeedbackController(
    this._bridge,
    this._version, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const BridgeAgentFeedback(BridgeAgentPhase.waiting)) {
    updateBridge(_bridge);
  }

  static const minimumWorkingDuration = Duration(milliseconds: 600);
  final DateTime Function() _clock;
  KritaBridgeState _bridge;
  String _version;
  String? _outcomeMarker;
  String? _confirmedVersion;
  bool _changed = false;
  DateTime? _workingSince;
  Timer? _timer;

  void updateDraft(String version) {
    if (_version == version) return;
    _version = version;
    _confirmedVersion = null;
    _changed = true;
    _timer?.cancel();
    _workingSince = null;
    final active = _bridge.session.agentActivity;
    state = BridgeAgentFeedback(
      active == null ? BridgeAgentPhase.changed : BridgeAgentPhase.working,
      activity: active,
    );
  }

  void updateBridge(KritaBridgeState bridge) {
    final reset = !bridge.enabled || _bridge.secret != bridge.secret;
    _bridge = bridge;
    if (reset) {
      _timer?.cancel();
      _workingSince = null;
      _outcomeMarker = null;
      _confirmedVersion = null;
      _changed = false;
    }
    if (!bridge.enabled) {
      state = const BridgeAgentFeedback(BridgeAgentPhase.waiting);
      return;
    }

    final active = bridge.session.agentActivity;
    final latest = bridge.session.latestAgentActivity;
    final outcome =
        bridge.session.latestAgentOutcome ??
        (latest?.status != BridgeActivityStatus.running ? latest : null);
    final marker = outcome == null
        ? null
        : '${outcome.key}:${outcome.status}:${outcome.finishedAt}:'
              '${outcome.confirmedDraftVersion}';
    final newOutcome = marker != null && marker != _outcomeMarker;
    if (newOutcome) {
      _outcomeMarker = marker;
      if (outcome!.status == BridgeActivityStatus.completed &&
          outcome.confirmedDraftVersion == _version) {
        _confirmedVersion = _version;
        _changed = false;
      } else {
        _confirmedVersion = null;
        _changed = outcome.status == BridgeActivityStatus.completed;
      }
    }
    _timer?.cancel();
    if (active != null) {
      _workingSince ??= _clock();
      state = BridgeAgentFeedback(BridgeAgentPhase.working, activity: active);
      return;
    }
    // A request can start and finish before Flutter paints its first frame.
    if (newOutcome &&
        state.phase != BridgeAgentPhase.working &&
        outcome?.finishedAt != null &&
        _clock().difference(outcome!.finishedAt!).inMilliseconds < 100) {
      _workingSince ??= _clock();
    }
    final elapsed = _workingSince == null
        ? minimumWorkingDuration
        : _clock().difference(_workingSince!);
    if (elapsed < minimumWorkingDuration) {
      state = BridgeAgentFeedback(BridgeAgentPhase.working, activity: outcome);
      _timer = Timer(minimumWorkingDuration - elapsed, _settle);
    } else {
      _settle();
    }
  }

  void _settle() {
    _workingSince = null;
    final latest = _bridge.session.latestAgentActivity;
    final outcome = _bridge.session.latestAgentOutcome ?? latest;
    final failed =
        outcome?.status == BridgeActivityStatus.failed ||
        outcome?.status == BridgeActivityStatus.disconnected;
    state = BridgeAgentFeedback(
      _changed
          ? BridgeAgentPhase.changed
          : failed
          ? BridgeAgentPhase.failed
          : _confirmedVersion == _version
          ? BridgeAgentPhase.synced
          : BridgeAgentPhase.waiting,
      activity: outcome,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
