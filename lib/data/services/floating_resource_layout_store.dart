import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';
import '../models/resources/floating_window_data.dart';

class FloatingResourceLayoutStore {
  FloatingResourceLayoutStore(this.storage);
  final LocalStorageService storage;

  List<FloatingWindowData> load() {
    final value = storage.getSetting<String>(
      StorageKeys.floatingResourceWindows,
    );
    if (value == null) return const [];
    return [
      for (final item in jsonDecode(value) as List)
        FloatingWindowData.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<void> save(List<FloatingWindowData> windows) => storage.setSetting(
    StorageKeys.floatingResourceWindows,
    jsonEncode(windows.map((window) => window.toJson()).toList()),
  );
}
