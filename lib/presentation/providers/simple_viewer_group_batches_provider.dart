import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';

final simpleViewerGroupBatchesProvider =
    NotifierProvider<SimpleViewerGroupBatches, bool>(
      SimpleViewerGroupBatches.new,
    );

class SimpleViewerGroupBatches extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .read(localStorageServiceProvider)
          .getSetting<bool>(
            StorageKeys.simpleViewerGroupBatches,
            defaultValue: false,
          ) ??
      false;

  Future<void> setGrouped(bool grouped) async {
    state = grouped;
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.simpleViewerGroupBatches, grouped);
  }
}

/// Presentation only, shared by both output viewers. Keep the existing setting
/// and provider names for compatibility; saving and generation retain batches.
final simpleViewerSingleImagesProvider = Provider<bool>(
  (ref) => !ref.watch(simpleViewerGroupBatchesProvider),
);
