import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';

/// Kept alive for the root container's lifetime, i.e. one application launch.
final newBadgeServiceProvider = Provider<NewBadgeService>(
  (ref) => NewBadgeService(ref.read(localStorageServiceProvider)),
);

class NewBadgeService {
  NewBadgeService(this._storage)
    : _seenBeforeLaunch = Set.unmodifiable(
        (_storage.getSetting<List<dynamic>>(storageKey) ?? const [])
            .cast<String>(),
      );

  static const storageKey = 'seen_new_badge_ids_v1';
  final LocalStorageService _storage;
  final Set<String> _seenBeforeLaunch;
  final Set<String> _seenThisLaunch = {};

  bool showNewBadge(String id) => !_seenBeforeLaunch.contains(id);

  void markNewBadgeSeen(String id) {
    if (_seenBeforeLaunch.contains(id) || !_seenThisLaunch.add(id)) return;
    unawaited(
      _storage.setSetting(storageKey, <String>[
        ..._seenBeforeLaunch,
        ..._seenThisLaunch,
      ]),
    );
  }
}

/// Minimal adapter for existing string badge parameters. Call only when the
/// entry is presented (menus: when opened, panels: when built), not for preload.
/// Persistence is deferred until the rendered frame, never during build.
String? newBadgeLabel(BuildContext context, String id, String label) {
  final service = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(newBadgeServiceProvider);
  if (!service.showNewBadge(id)) return null;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) service.markNewBadgeSeen(id);
  });
  return label;
}
