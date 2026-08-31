import '../models/vibe/vibe_library_entry.dart';
import '../models/vibe/vibe_reference.dart';
import 'vibe_import_service.dart';
import 'vibe_library_storage_service.dart';

/// VibeLibraryNotifier 的导入仓库适配器
/// 实现 VibeLibraryImportRepository 接口以适配 VibeImportService
class VibeLibraryNotifierImportRepository
    implements VibeLibraryImportRepository {
  VibeLibraryNotifierImportRepository({
    required this.onGetAllEntries,
    required this.onFindEntryByName,
    required this.onSaveEntry,
    this.onSaveBundleEntry,
  });

  final Future<List<VibeLibraryEntry>> Function() onGetAllEntries;
  final Future<VibeLibraryEntry?> Function(String name) onFindEntryByName;
  final Future<VibeLibraryEntry?> Function(VibeLibraryEntry) onSaveEntry;
  final Future<VibeLibraryEntry?> Function(
    List<VibeReference> vibes, {
    required String name,
    String? categoryId,
    List<String>? tags,
    VibeLibraryEntry? replaceEntry,
  })?
  onSaveBundleEntry;

  @override
  Future<List<VibeLibraryEntry>> getAllEntries() async {
    return onGetAllEntries();
  }

  @override
  Future<VibeLibraryEntry?> findEntryByName(String name) {
    return onFindEntryByName(name);
  }

  @override
  Future<VibeLibraryEntry> saveEntry(VibeLibraryEntry entry) async {
    final saved = await onSaveEntry(entry);
    if (saved == null) {
      throw StateError('Failed to save entry: ${entry.name}');
    }
    return saved;
  }

  @override
  Future<VibeLibraryEntry> saveBundleEntry(
    List<VibeReference> vibes, {
    required String name,
    String? categoryId,
    List<String>? tags,
    VibeLibraryEntry? replaceEntry,
  }) async {
    final saver = onSaveBundleEntry;
    if (saver == null) {
      throw StateError('Bundle import requires a bundle-aware repository');
    }

    final saved = await saver(
      vibes,
      name: name,
      categoryId: categoryId,
      tags: tags,
      replaceEntry: replaceEntry,
    );
    if (saved == null) {
      throw StateError('Failed to save bundle entry: $name');
    }
    return saved;
  }
}

/// 直接使用存储层的导入仓库。
///
/// 批量导入期间避免每保存一个条目就触发 provider 全量重建，
/// 导入完成后再统一 reload UI。
class VibeLibraryStorageImportRepository
    implements VibeLibraryImportRepository {
  VibeLibraryStorageImportRepository(this._storage);

  final VibeLibraryStorageService _storage;

  @override
  Future<List<VibeLibraryEntry>> getAllEntries() {
    return _storage.getAllEntries();
  }

  @override
  Future<VibeLibraryEntry?> findEntryByName(String name) {
    return _storage.findEntryByName(name);
  }

  @override
  Future<VibeLibraryEntry> saveEntry(VibeLibraryEntry entry) {
    return _storage.saveEntry(entry);
  }

  @override
  Future<VibeLibraryEntry> saveBundleEntry(
    List<VibeReference> vibes, {
    required String name,
    String? categoryId,
    List<String>? tags,
    VibeLibraryEntry? replaceEntry,
  }) {
    return _storage.saveBundleEntry(
      vibes,
      name: name,
      categoryId: categoryId,
      tags: tags,
      replaceEntry: replaceEntry,
    );
  }
}
