import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../ui/kit/ui_new_badge.dart';

/// Kept alive for the root container's lifetime, i.e. one application launch.
final newBadgeServiceProvider = Provider<NewBadgeService>(
  (ref) => NewBadgeService(ref.read(localStorageServiceProvider)),
);

class NewBadgeService implements UiNewBadgeStore {
  NewBadgeService(this._storage)
    : _seenBeforeLaunch = Set.unmodifiable(
        (_storage.getSetting<List<dynamic>>(storageKey) ?? const [])
            .cast<String>(),
      );

  static const storageKey = 'seen_new_badge_ids_v1';
  final LocalStorageService _storage;
  final Set<String> _seenBeforeLaunch;
  final Set<String> _seenThisLaunch = {};

  @override
  bool showNewBadge(String id) => !_seenBeforeLaunch.contains(id);

  @override
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

/// 把本次启动的已见记录挂到界面层（[UiNewBadges]）。
class NewBadgeScope extends ConsumerWidget {
  const NewBadgeScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UiNewBadges(store: ref.watch(newBadgeServiceProvider), child: child);
}
