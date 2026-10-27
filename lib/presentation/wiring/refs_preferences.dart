import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../ui/refs/refs_contract.dart';

/// Cross-entry notification only; persisted truth remains RefsPreferenceStore.
/// Keeps a mounted main page and resource windows on the same sort without
/// replacing that page's current search/category/selection.
final refsSortChangedProvider =
    StateProvider.family<({RefsSort sort, bool descending})?, RefsKind>(
      (ref, kind) => null,
    );

class RefsPreferences {
  const RefsPreferences({
    this.filter = const RefsFilter(),
    this.cardSize = RefsCardSize.medium,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.exportFolder = '',
  });

  final RefsFilter filter;
  final RefsCardSize cardSize;
  final bool sidebarOpen;
  final bool inspectorOpen;
  final String exportFolder;
}

class RefsPreferenceStore {
  const RefsPreferenceStore(this.storage, this.kind);

  final LocalStorageService storage;
  final RefsKind kind;
  String get prefix => 'refs_${kind.name}';

  RefsPreferences read() {
    Object? value(String name) => storage.getSetting<Object>('${prefix}_$name');
    Map<String, dynamic> filter = {};
    final savedFilter = value('filter');
    if (savedFilter is String) {
      try {
        final decoded = jsonDecode(savedFilter);
        if (decoded is Map<String, dynamic>) filter = decoded;
      } on FormatException {
        filter = {};
      }
    }
    return RefsPreferences(
      filter: RefsFilter(
        view: _enum(RefsView.values, filter['view'], RefsView.all),
        quick: _enum(RefsQuick.values, filter['quick'], RefsQuick.all),
        sort: _enum(RefsSort.values, filter['sort'], RefsSort.lastUsed),
        descending: filter['descending'] is bool
            ? filter['descending'] as bool
            : true,
      ),
      cardSize: _enum(
        RefsCardSize.values,
        value('card_size'),
        RefsCardSize.medium,
      ),
      sidebarOpen: value('sidebar_open') is bool
          ? value('sidebar_open') as bool
          : true,
      inspectorOpen: value('inspector_open') is bool
          ? value('inspector_open') as bool
          : true,
      exportFolder: value('export_folder') is String
          ? value('export_folder') as String
          : '',
    );
  }

  Future<void> saveFilter(RefsFilter filter) => storage.setSetting(
    '${prefix}_filter',
    jsonEncode({
      'view': filter.view.name,
      'quick': filter.quick.name,
      'sort': filter.sort.name,
      'descending': filter.descending,
    }),
  );
  Future<void> saveCardSize(RefsCardSize value) =>
      storage.setSetting('${prefix}_card_size', value.name);
  Future<void> saveSidebar(bool value) =>
      storage.setSetting('${prefix}_sidebar_open', value);
  Future<void> saveInspector(bool value) =>
      storage.setSetting('${prefix}_inspector_open', value);
  Future<void> saveExportFolder(String value) =>
      storage.setSetting('${prefix}_export_folder', value);

  T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;
}
