import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/prompt_block/pill_document.dart';

/// A runtime-only snapshot of one instance that is managed by a deep round.
///
/// The snapshot is deliberately separate from [PillInstance]. A guard changes
/// only the projection; it never writes these values back to the workspace
/// document.
class DeepRoundManagedInstance {
  const DeepRoundManagedInstance({
    required this.scope,
    required this.marker,
    required this.blockId,
    required this.enteringCurrentRoll,
    required this.originalLocked,
  });

  final String scope;
  final String marker;
  final String blockId;
  final String? enteringCurrentRoll;
  final bool originalLocked;
}

/// The reason a guard owns an overlay entry.
enum DeepRoundRollOverrideKind { automaticSuppression, explicitTarget }

/// Runtime projection state for one deep-round session.
///
/// [overlay] intentionally uses a nullable map with key presence carrying
/// meaning: a missing marker is not managed, `null` means explicitly empty,
/// and a string is an explicit projected roll. The kind maps keep automatic
/// suppression distinguishable from an explicit target override.
class DeepRoundRollGuard {
  DeepRoundRollGuard({
    required this.ownerId,
    required this.runId,
    required this.roundId,
    required Map<String, Map<String, DeepRoundManagedInstance>> managed,
    required Map<String, Map<String, String?>> overlay,
    required Map<String, Map<String, DeepRoundRollOverrideKind>> kinds,
  }) : managed = _freezeNested(managed),
       overlay = _freezeNested(overlay),
       kinds = _freezeNested(kinds);

  factory DeepRoundRollGuard.capture({
    required String ownerId,
    required String runId,
    required String roundId,
    required Map<String, PillDocument> documents,
  }) {
    final managed = <String, Map<String, DeepRoundManagedInstance>>{};
    final overlay = <String, Map<String, String?>>{};
    final kinds = <String, Map<String, DeepRoundRollOverrideKind>>{};
    for (final entry in documents.entries) {
      final lane = <String, DeepRoundManagedInstance>{};
      final laneOverlay = <String, String?>{};
      final laneKinds = <String, DeepRoundRollOverrideKind>{};
      for (final instanceEntry in entry.value.instances.entries) {
        final instance = instanceEntry.value;
        if (!instance.enabled ||
            !instance.settings.hasRoll ||
            !instance.evolutionEnabled) {
          continue;
        }
        lane[instanceEntry.key] = DeepRoundManagedInstance(
          scope: entry.key,
          marker: instanceEntry.key,
          blockId: instance.blockId,
          enteringCurrentRoll: instance.currentRoll,
          originalLocked: instance.locked,
        );
        if (!instance.locked) {
          laneOverlay[instanceEntry.key] = null;
          laneKinds[instanceEntry.key] =
              DeepRoundRollOverrideKind.automaticSuppression;
        }
      }
      if (lane.isNotEmpty) managed[entry.key] = lane;
      if (laneOverlay.isNotEmpty) overlay[entry.key] = laneOverlay;
      if (laneKinds.isNotEmpty) kinds[entry.key] = laneKinds;
    }
    return DeepRoundRollGuard(
      ownerId: ownerId,
      runId: runId,
      roundId: roundId,
      managed: managed,
      overlay: overlay,
      kinds: kinds,
    );
  }

  final String ownerId;
  final String runId;
  final String roundId;
  final Map<String, Map<String, DeepRoundManagedInstance>> managed;
  final Map<String, Map<String, String?>> overlay;
  final Map<String, Map<String, DeepRoundRollOverrideKind>> kinds;

  bool owns({
    required String ownerId,
    required String runId,
    required String roundId,
  }) =>
      this.ownerId == ownerId && this.runId == runId && this.roundId == roundId;

  DeepRoundRollGuard withOverlay({
    required Map<String, Map<String, String?>> overlay,
    required Map<String, Map<String, DeepRoundRollOverrideKind>> kinds,
  }) {
    return DeepRoundRollGuard(
      ownerId: ownerId,
      runId: runId,
      roundId: roundId,
      managed: managed,
      overlay: overlay,
      kinds: kinds,
    );
  }

  DeepRoundManagedInstance? managedFor(String scope, String marker) {
    return managed[scope]?[marker];
  }

  DeepRoundRollOverrideKind? kindFor(String scope, String marker) {
    return kinds[scope]?[marker];
  }

  static Map<String, Map<String, T>> _freezeNested<T>(
    Map<String, Map<String, T>> source,
  ) {
    final frozen = <String, Map<String, T>>{
      for (final entry in source.entries)
        entry.key: Map<String, T>.unmodifiable(
          Map<String, T>.from(entry.value),
        ),
    };
    return Map<String, Map<String, T>>.unmodifiable(frozen);
  }
}

/// Owns the active deep-round guard for one provider container.
///
/// The controller has no persistence hooks. Workspace notifiers subscribe to
/// it so installing, changing, or clearing a guard only refreshes in-memory
/// projections.
class DeepRoundRollGuardController {
  DeepRoundRollGuard? _guard;
  final Set<void Function()> _listeners = <void Function()>{};

  DeepRoundRollGuard? get guard => _guard;

  void Function() addListener(void Function() listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  bool install(DeepRoundRollGuard next) {
    final current = _guard;
    if (current != null &&
        !current.owns(
          ownerId: next.ownerId,
          runId: next.runId,
          roundId: next.roundId,
        )) {
      return false;
    }
    _guard = next;
    _notify();
    return true;
  }

  /// Apply a candidate overlay to the current guard.
  ///
  /// All initially-unlocked managed instances are automatic null suppression;
  /// the main-lane target is then replaced by an explicit string override.
  /// Initially locked non-target instances are intentionally omitted from the
  /// overlay, while a target override remains explicit even if it was locked.
  bool updateCandidate({
    required String ownerId,
    required String runId,
    required String roundId,
    required String targetScope,
    required String targetMarker,
    required String mutatedText,
  }) {
    final current = _guard;
    if (current == null ||
        !current.owns(ownerId: ownerId, runId: runId, roundId: roundId)) {
      return false;
    }

    final overlay = <String, Map<String, String?>>{};
    final kinds = <String, Map<String, DeepRoundRollOverrideKind>>{};
    for (final laneEntry in current.managed.entries) {
      final laneOverlay = <String, String?>{};
      final laneKinds = <String, DeepRoundRollOverrideKind>{};
      for (final managedEntry in laneEntry.value.entries) {
        final managed = managedEntry.value;
        final isTarget =
            managed.scope == targetScope && managed.marker == targetMarker;
        if (isTarget) {
          laneOverlay[managed.marker] = mutatedText;
          laneKinds[managed.marker] = DeepRoundRollOverrideKind.explicitTarget;
        } else if (!managed.originalLocked) {
          laneOverlay[managed.marker] = null;
          laneKinds[managed.marker] =
              DeepRoundRollOverrideKind.automaticSuppression;
        }
      }
      if (laneOverlay.isNotEmpty) {
        overlay[laneEntry.key] = laneOverlay;
        kinds[laneEntry.key] = laneKinds;
      }
    }
    _guard = current.withOverlay(overlay: overlay, kinds: kinds);
    _notify();
    return true;
  }

  bool hasOverride(String scope, String marker, {PillInstance? instance}) {
    final current = _guard;
    final values = current?.overlay[scope];
    if (values == null || !values.containsKey(marker)) {
      return false;
    }
    final managed = current!.managedFor(scope, marker);
    if (managed == null ||
        (instance != null && instance.blockId != managed.blockId)) {
      return false;
    }
    return true;
  }

  /// Returns the effective random roll without mutating the workspace.
  String? effectiveRoll(String scope, String marker, PillInstance instance) {
    final current = _guard;
    if (current == null) return instance.currentRoll;
    final values = current.overlay[scope];
    if (values == null || !values.containsKey(marker)) {
      return instance.currentRoll;
    }
    final managed = current.managedFor(scope, marker);
    if (managed == null || instance.blockId != managed.blockId) {
      return instance.currentRoll;
    }
    final kind = current.kindFor(scope, marker);
    if (kind == DeepRoundRollOverrideKind.automaticSuppression &&
        instance.locked &&
        !managed.originalLocked) {
      return managed.enteringCurrentRoll;
    }
    return values[marker];
  }

  bool clear({
    required String ownerId,
    required String runId,
    required String roundId,
  }) {
    final current = _guard;
    if (current == null ||
        !current.owns(ownerId: ownerId, runId: runId, roundId: roundId)) {
      return false;
    }
    _guard = null;
    _notify();
    return true;
  }

  /// Test-only escape hatch for isolating provider containers.
  void clearForTesting() {
    if (_guard == null) return;
    _guard = null;
    _notify();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

final deepRoundRollGuardControllerProvider =
    Provider<DeepRoundRollGuardController>(
      (ref) => DeepRoundRollGuardController(),
    );
