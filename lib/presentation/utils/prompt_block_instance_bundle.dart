import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prompt_block/pill_document.dart';
import '../providers/pill_workspace_provider.dart';

class BundleMember {
  const BundleMember(this.scope, this.marker, this.instance);
  final String scope;
  final String marker;
  final PillInstance instance;
}

/// 一次插入的两侧实例。旧块实例没有 bundleId，继续保持独立行为。
class PromptBlockInstanceBundle {
  const PromptBlockInstanceBundle(this.positive, this.negative);
  final BundleMember? positive;
  final BundleMember? negative;

  bool get isPaired => positive != null && negative != null;
  int get mask =>
      positive?.instance.rollScopeMask ??
      (negative != null && negative!.instance.bundleId == null
          ? 2
          : negative?.instance.rollScopeMask ?? 1);
  PillRollMode get mode {
    final a = positive?.instance.settings.mode;
    final b = negative?.instance.settings.mode;
    return a != null && a != PillRollMode.fixed
        ? a
        : b ?? a ?? PillRollMode.fixed;
  }

  Iterable<BundleMember> get members => [
    if (positive != null) positive!,
    if (negative != null) negative!,
  ];
}

PromptBlockInstanceBundle readPromptBlockInstanceBundle(
  WidgetRef ref,
  String scope,
  String marker,
) {
  final local = ref
      .read(pillWorkspaceProvider(scope))
      .document
      .instances[marker];
  if (local == null) return const PromptBlockInstanceBundle(null, null);
  final self = BundleMember(scope, marker, local);
  final id = local.bundleId;
  if (id == null) {
    return local.useNegativeContent
        ? PromptBlockInstanceBundle(null, self)
        : PromptBlockInstanceBundle(self, null);
  }
  String? positiveScope;
  String? negativeScope;
  if (scope == PillScopes.main || scope == PillScopes.negative) {
    positiveScope = PillScopes.main;
    negativeScope = PillScopes.negative;
  } else {
    final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope);
    if (match != null) {
      positiveScope = PillScopes.charPos(match.group(1)!);
      negativeScope = PillScopes.charNeg(match.group(1)!);
    }
  }
  BundleMember? find(String? targetScope, bool negative) {
    if (targetScope == null) return null;
    final document = ref.read(pillWorkspaceProvider(targetScope)).document;
    for (final entry in document.instances.entries) {
      if (entry.value.bundleId == id &&
          entry.value.useNegativeContent == negative) {
        return BundleMember(targetScope, entry.key, entry.value);
      }
    }
    return null;
  }

  return PromptBlockInstanceBundle(
    find(positiveScope, false) ?? (local.useNegativeContent ? null : self),
    find(negativeScope, true) ?? (local.useNegativeContent ? self : null),
  );
}

void updatePromptBlockBundleScope(
  WidgetRef ref,
  String scope,
  String marker,
  int requestedMask,
) {
  final bundle = readPromptBlockInstanceBundle(ref, scope, marker);
  if (!bundle.isPaired) return;
  final mask = requestedMask == 0 ? 1 : requestedMask;
  final mode = bundle.mode;
  final template = bundle.members
      .firstWhere(
        (member) => member.instance.settings.mode != PillRollMode.fixed,
        orElse: () => bundle.positive!,
      )
      .instance
      .settings;
  for (final member in bundle.members) {
    final notifier = ref.read(pillWorkspaceProvider(member.scope).notifier);
    notifier.updateInstanceRollScopeMask(member.marker, mask);
    final bit = member.instance.useNegativeContent ? 2 : 1;
    notifier.updateInstanceSettings(
      member.marker,
      template.copyWith(mode: mask & bit == 0 ? PillRollMode.fixed : mode),
    );
  }
}

void rollPromptBlockBundle(
  WidgetRef ref,
  String scope,
  String marker, {
  int? direction,
}) {
  final bundle = readPromptBlockInstanceBundle(ref, scope, marker);
  for (final member in bundle.members) {
    final notifier = ref.read(pillWorkspaceProvider(member.scope).notifier);
    if (direction == null) {
      notifier.rollMarker(member.marker);
    } else {
      notifier.stepSequence(member.marker, direction);
    }
  }
}

void removePromptBlockBundle(WidgetRef ref, String scope, String marker) {
  final bundle = readPromptBlockInstanceBundle(ref, scope, marker);
  for (final member in bundle.members) {
    ref
        .read(pillWorkspaceProvider(member.scope).notifier)
        .removeMarker(member.marker);
  }
}
