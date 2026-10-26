import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../data/models/vibe/vibe_library_category.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/vibe_file_storage_service.dart';
import '../../data/services/vibe_import_service.dart';
import '../../data/services/vibe_library_import_repository_impl.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../providers/vibe_library_category_provider.dart';
import '../ui/kit/ui_dialog.dart';
import '../ui/refs/refs_contract.dart';
import '../ui/refs/refs_dialogs.dart';
import '../ui/refs/refs_page.dart';
import '../utils/dropped_file_reader.dart';
import 'refs_exporter.dart';
import 'refs_drop_reader.dart';
import 'refs_generation_target.dart';
import 'refs_import_session.dart';
import 'refs_mapping.dart';
import 'refs_platform.dart';
import 'refs_preferences.dart';

final refsVibeStatusesProvider =
    FutureProvider.autoDispose<Map<String, RefsVibeStatus>>((ref) async {
      final entries = ref.watch(
        vibeLibraryNotifierProvider.select((s) => s.entries),
      );
      final storage = ref.read(vibeLibraryStorageServiceProvider);
      final statuses = <String, RefsVibeStatus>{};
      for (final entry in entries) {
        final full = await storage.getEntrySnapshot(entry.id);
        if (full != null) {
          final vibes = full.isBundle && full.filePath != null
              ? await VibeFileStorageService().extractVibesFromBundle(
                  full.filePath!,
                )
              : full.isBundle
              ? refsBundleVibes(full)
              : [full.toVibeReference()];
          statuses[entry.id] = RefsVibeStatus.fromVibes(vibes);
        }
        await Future<void>.delayed(Duration.zero);
      }
      return statuses;
    });

class VibeLibraryWiring extends _RefsLibraryWiring {
  const VibeLibraryWiring({super.key}) : super(kind: RefsKind.vibe);
}

class PreciseRefLibraryWiring extends _RefsLibraryWiring {
  const PreciseRefLibraryWiring({super.key}) : super(kind: RefsKind.precise);
}

class _RefsLibraryWiring extends ConsumerStatefulWidget {
  const _RefsLibraryWiring({super.key, required this.kind});
  final RefsKind kind;
  @override
  ConsumerState<_RefsLibraryWiring> createState() => _RefsLibraryWiringState();
}

class _RefsLibraryWiringState extends ConsumerState<_RefsLibraryWiring> {
  final _page = GlobalKey<State<RefsLibraryPage>>();
  late RefsPreferenceStore _preferences;
  RefsFilter _filter = const RefsFilter();
  RefsCardSize _cardSize = RefsCardSize.medium;
  bool _sidebarOpen = true, _inspectorOpen = true, _loading = true;
  bool _cardChanged = false, _importing = false, _sending = false;
  String? _selectedKey, _folderPath;
  String _exportFolder = '';
  RefsDetail? _detail;
  Size? _detailSize;
  VibeLibraryEntry? _full;
  RefsVibeStatus? _fullStatus;
  int _selection = 0, _importGeneration = 0;
  RefsImportSession? _import;
  RefsDropSummary? _drop;
  int _hoverGeneration = 0;
  bool _hoverStarted = false, _dropBusy = false;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _hoverGeneration++;
    super.dispose();
  }

  Future<void> _queue = Future.value();
  bool _exportAll = false;

  bool get _vibe => widget.kind == RefsKind.vibe;
  RefsPlatform get _platform => ref.read(refsPlatformProvider);
  RefsGenerationTarget get _target => ref.read(refsGenerationTargetProvider);
  VibeLibraryNotifier get _library =>
      ref.read(vibeLibraryNotifierProvider.notifier);
  PreciseRefLibraryNotifier get _precise =>
      ref.read(preciseRefLibraryNotifierProvider.notifier);
  VibeLibraryStorageService get _storage =>
      ref.read(vibeLibraryStorageServiceProvider);
  bool _alive() => mounted && TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    _preferences = RefsPreferenceStore(
      ref.read(localStorageServiceProvider),
      widget.kind,
    );
    final saved = _preferences.read();
    _filter = saved.filter;
    _cardSize = saved.cardSize;
    _sidebarOpen = saved.sidebarOpen;
    _inspectorOpen = saved.inspectorOpen;
    _exportFolder = saved.exportFolder;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run(_initialize));
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final legacy = prefs.getString(
        _vibe ? 'vibe_library_card_size' : 'precise_ref_library_card_size',
      );
      if (!_cardChanged &&
          ref
                  .read(localStorageServiceProvider)
                  .getSetting<Object>('${_preferences.prefix}_card_size') ==
              null &&
          legacy != null) {
        _cardSize =
            RefsCardSize.values.where((s) => s.name == legacy).firstOrNull ??
            _cardSize;
        await _preferences.saveCardSize(_cardSize);
      }
      if (_vibe) {
        await _library.initialize();
        if (!mounted) return;
        final error = ref.read(vibeLibraryNotifierProvider).error;
        if (error != null) throw StateError(error);
        _folderPath = await _platform.libraryFolder();
      } else {
        await _precise.initialize();
        if (!mounted) return;
        final error = ref.read(preciseRefLibraryNotifierProvider).error;
        if (error != null) throw StateError(error);
      }
      if (_exportFolder.isEmpty) _exportFolder = _folderPath ?? '';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reportError(Object error) {
    if (mounted) _platform.error(context, error);
  }

  void _send(Future<void> Function() action) {
    if (_sending) return;
    _sending = true;
    final snapshot = _target.capture(withBackup: false);
    _run(() async {
      try {
        _target.check(snapshot, _alive);
        await action();
      } finally {
        _sending = false;
      }
    });
  }

  void _run(Future<void> Function() action) {
    final operation = _queue.then((_) async {
      if (!mounted) return;
      await action();
    });
    _queue = operation.catchError((Object error, StackTrace stack) {
      if (mounted) _platform.error(context, error);
    });
  }

  Future<void> _select(String key) async {
    final sequence = ++_selection;
    setState(() {
      _selectedKey = key;
      _detail = RefsDetail(key: key, loading: true);
      _full = null;
    });
    try {
      if (_vibe) {
        final entry = await _storage.getEntry(key);
        if (!mounted || sequence != _selection) return;
        if (entry == null) {
          throw StateError(currentL10n.preciseRefLib_imageMissing);
        }
        final vibes = entry.isBundle
            ? await _bundleVibes(entry)
            : <VibeReference>[];
        if (!mounted || sequence != _selection) return;
        final bytes = entry.isBundle
            ? entry.thumbnail ?? entry.vibeThumbnail ?? entry.rawImageData
            : entry.rawImageData ?? entry.thumbnail ?? entry.vibeThumbnail;
        final models = vibes.map((v) => v.encodingModel).toSet();
        setState(() {
          _full = entry;
          _fullStatus = RefsVibeStatus.fromVibes(
            entry.isBundle ? vibes : [entry.toVibeReference()],
          );
          _detail = RefsDetail(
            key: key,
            image: bytes == null ? null : MemoryImage(bytes),
            coverIndex: entry.thumbnail == null
                ? 0
                : vibes
                      .indexWhere(
                        (v) =>
                            v.thumbnail != null &&
                            refsBytesFingerprint(v.thumbnail!) ==
                                refsBytesFingerprint(entry.thumbnail!),
                      )
                      .clamp(0, vibes.isEmpty ? 0 : vibes.length - 1),
            bundle: [
              for (final v in vibes)
                RefsBundleChild(
                  name: v.displayName,
                  thumb: v.thumbnail == null ? null : MemoryImage(v.thumbnail!),
                  strength: v.strength,
                  infoExtracted: v.infoExtracted,
                ),
            ],
            bundleEncodedFor: models.length == 1 && models.single != null
                ? refsShortModel(models.single!)
                : null,
          );
        });
      } else {
        final bytes = await ref
            .read(preciseRefLibraryStorageServiceProvider)
            .readImageBytes(key);
        if (!mounted || sequence != _selection) return;
        if (bytes == null) {
          throw StateError(currentL10n.preciseRefLib_imageMissing);
        }
        final size = NaiResolutionAdapter.readImageSize(bytes);
        setState(() {
          _detailSize = size == null
              ? null
              : Size(size.$1.toDouble(), size.$2.toDouble());
          _detail = RefsDetail(key: key, image: MemoryImage(bytes));
        });
      }
    } catch (error) {
      if (!mounted || sequence != _selection) return;
      setState(() => _detail = RefsDetail(key: key));
      _platform.error(context, error);
    }
  }

  Future<List<VibeReference>> _bundleVibes(VibeLibraryEntry entry) async {
    if (entry.filePath == null) return refsBundleVibes(entry);
    final vibes = await VibeFileStorageService().extractVibesFromBundle(
      entry.filePath!,
    );
    if (vibes.isEmpty) {
      throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
    }
    return vibes;
  }

  Future<void> _refreshDetail() async {
    if (_selectedKey != null && mounted) await _select(_selectedKey!);
  }

  Future<void> _add(
    List<String> keys, {
    bool replace = false,
    Map<String, RefsSendOverride> overrides = const {},
  }) async {
    final result = _vibe
        ? await _target.addVibes(
            keys,
            replace: replace,
            overrides: overrides,
            alive: _alive,
          )
        : await _target.addPrecise(
            [
              for (final key in keys.toSet())
                ...ref
                    .read(preciseRefLibraryNotifierProvider)
                    .entries
                    .where((e) => e.id == key),
            ],
            replace: replace,
            alive: _alive,
          );
    if (mounted) {
      _platform.sent(
        context,
        result.count,
        truncated: result.truncated,
        kind: widget.kind,
      );
    }
  }

  Future<void> _mutateKeys(
    List<String> keys,
    Future<void> Function(String key) change,
  ) async {
    for (final key in keys.toSet()) {
      if (!mounted) return;
      await change(key);
    }
    if (_vibe) {
      await ref.read(vibeLibraryCategoryNotifierProvider.notifier).refresh();
    }
    await _refreshDetail();
  }

  Future<void> _saveParams(
    String key,
    RefsParamsPatch patch, {
    bool forceEncode = false,
  }) async {
    if (!_vibe) {
      final saved = await _precise.updateEntry(
        key,
        type: patch.type == null ? null : preciseRefType(patch.type!),
        strength: patch.strength,
        fidelity: patch.fidelity,
      );
      if (saved == null) {
        throw StateError(currentL10n.preciseRefLib_imageMissing);
      }
      return;
    }
    final entry = await _storage.getEntry(key);
    if (entry == null) throw StateError(currentL10n.preciseRefLib_imageMissing);
    if (entry.isBundle) {
      final vibes = await _bundleVibes(entry);
      await _saveBundle(key, {
        for (var i = 0; i < vibes.length; i++)
          i: RefsSendOverride(
            strength: patch.strength ?? vibes[i].strength,
            infoExtracted: patch.infoExtracted ?? vibes[i].infoExtracted,
          ),
      }, forceEncode: forceEncode);
      return;
    }
    final vibe = entry.toVibeReference();
    final model = ref.read(generationParamsNotifierProvider).model;
    final strength = patch.strength ?? vibe.strength;
    final info = patch.infoExtracted ?? vibe.infoExtracted;
    if (info != vibe.infoExtracted && !vibe.canReencodeFromRawSource) {
      throw StateError(currentL10n.preciseRefLib_imageMissing);
    }
    final needsEncode =
        forceEncode ||
        (vibe.canReencodeFromRawSource && info != vibe.infoExtracted);
    VibeReference? persisted;
    if (needsEncode) {
      if (!ModelSpecs.of(model).vibetransfer ||
          !vibe.canReencodeFromRawSource) {
        throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
      }
      if (!mounted ||
          !await _platform.confirmEncoding(
            context,
            count: 1,
            cost: refsCosts().encode,
            model: refsShortModel(model),
          )) {
        return;
      }
      if (!mounted ||
          ref.read(generationParamsNotifierProvider).model != model ||
          await _storage.getEntry(key) != entry) {
        throw StateError(currentL10n.bridge_conflict);
      }
      persisted = await ref
          .read(generationParamsNotifierProvider.notifier)
          .prepareVibeForLibraryParamSave(
            forceEncode
                ? vibe.copyWith(vibeEncoding: '', encodingModel: null)
                : vibe,
            strength: strength,
            infoExtracted: info,
            model: model,
          );
      if (persisted == null) {
        throw StateError(currentL10n.vibe_import_importFailed);
      }
    } else {
      persisted = vibe.copyWith(strength: strength, infoExtracted: info);
    }
    if (!mounted ||
        ref.read(generationParamsNotifierProvider).model != model ||
        await _storage.getEntry(key) != entry) {
      throw StateError(currentL10n.bridge_conflict);
    }
    final saved = await _library.saveEntryParams(
      key,
      strength: strength,
      infoExtracted: info,
      persistedVibeData: persisted,
    );
    if (saved == null) throw StateError(currentL10n.vibe_import_importFailed);
    await _refreshDetail();
  }

  Future<void> _saveBundle(
    String key,
    Map<int, RefsSendOverride> values, {
    bool forceEncode = false,
  }) async {
    final entry = await _storage.getEntry(key);
    if (entry == null) {
      throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
    }
    final vibes = await _bundleVibes(entry);
    final model = ref.read(generationParamsNotifierProvider).model;
    final changed = values.entries
        .where((e) => e.key >= 0 && e.key < vibes.length)
        .toList();
    for (final item in changed) {
      if (vibes[item.key].infoExtracted != item.value.infoExtracted &&
          !vibes[item.key].canReencodeFromRawSource) {
        throw StateError(currentL10n.preciseRefLib_imageMissing);
      }
    }
    bool needsEncoding(int index, RefsSendOverride patch) =>
        vibes[index].canReencodeFromRawSource &&
        (vibes[index].infoExtracted != patch.infoExtracted ||
            forceEncode && vibes[index].needsEncodingForModel(model));
    final needEncoding = changed
        .where((item) => needsEncoding(item.key, item.value))
        .length;
    if (needEncoding > 0 && !ModelSpecs.of(model).vibetransfer) {
      throw StateError(currentL10n.preciseRef_v4Only);
    }
    if (needEncoding > 0 &&
        (!mounted ||
            !await _platform.confirmEncoding(
              context,
              count: needEncoding,
              cost: refsCosts().encode,
              model: refsShortModel(model),
            ))) {
      return;
    }
    if (!mounted ||
        await _storage.getEntry(key) != entry ||
        ref.read(generationParamsNotifierProvider).model != model) {
      throw StateError(currentL10n.bridge_conflict);
    }
    final prepared = <int, VibeReference>{};
    for (final item in changed) {
      final vibe = vibes[item.key];
      final persisted = needsEncoding(item.key, item.value)
          ? await ref
                .read(generationParamsNotifierProvider.notifier)
                .prepareVibeForLibraryParamSave(
                  vibe,
                  strength: item.value.strength,
                  infoExtracted: item.value.infoExtracted,
                  model: model,
                )
          : vibe.copyWith(
              strength: item.value.strength,
              infoExtracted: item.value.infoExtracted,
            );
      if (persisted == null || !mounted) {
        throw StateError(currentL10n.vibe_import_importFailed);
      }
      prepared[item.key] = persisted;
    }
    if (!mounted ||
        await _storage.getEntry(key) != entry ||
        ref.read(generationParamsNotifierProvider).model != model) {
      throw StateError(currentL10n.bridge_conflict);
    }
    for (final item in changed) {
      final saved = await _library.saveBundleChildParams(
        key,
        childIndex: item.key,
        strength: item.value.strength,
        infoExtracted: item.value.infoExtracted,
        persistedVibeData: prepared[item.key],
      );
      if (saved == null) throw StateError(currentL10n.vibe_import_importFailed);
    }
    await _refreshDetail();
  }

  Future<void> _prepareImport(List<DroppedFileData> files) async {
    if (files.isEmpty || _importing) return;
    final generation = ++_importGeneration;
    if (!_vibe) {
      final type = preciseRefType(_filter.type ?? RefsPreciseType.both);
      final result = await _precise.importMany([
        for (final file in files)
          PreciseRefLibraryImportSource(
            loadBytes: () async => file.bytes,
            name: p.basenameWithoutExtension(file.fileName),
            type: type,
          ),
      ]);
      if (mounted) {
        _platform.imported(
          context,
          result.importedCount,
          result.failedCount,
          kind: widget.kind,
        );
      }
      return;
    }
    final session = await RefsImportSession.prepare(
      files,
      model: ref.read(generationParamsNotifierProvider).model,
      names: {
        ...ref.read(vibeLibraryNotifierProvider).entries.map((e) => e.name),
        ...?_import?.draft.rows.map((row) => row.name),
      },
      categoryId: _filter.categoryId == '' ? null : _filter.categoryId,
    );
    if (mounted && generation == _importGeneration) {
      setState(() => _import = session);
    }
  }

  Future<void> _confirmImport(RefsImportPlan plan) async {
    final session = _import;
    if (session == null || _importing) return;
    _importing = true;
    final generation = _importGeneration;
    bool alive() => mounted && generation == _importGeneration;
    try {
      final model = ref.read(generationParamsNotifierProvider).model;
      final library = _library;
      final importer = VibeImportService(
        repository: VibeLibraryStorageImportRepository(_storage),
      );
      final resolved = await session.resolveSkippedRows(plan, importer);
      if (!mounted || !alive()) return;
      final count = session.encodingCount(resolved);
      if (count > 0 &&
          (!ModelSpecs.of(model).vibetransfer ||
              !await _platform.confirmEncoding(
                context,
                count: count,
                cost: refsCosts().encode,
                model: refsShortModel(model),
              ))) {
        return;
      }
      if (!alive()) return;
      final result = await session.execute(
        resolved,
        importer,
        alive: alive,
        encode: (vibe) async {
          if (!alive() ||
              ref.read(generationParamsNotifierProvider).model != model) {
            throw StateError(currentL10n.bridge_conflict);
          }
          final encoded = await ref
              .read(generationParamsNotifierProvider.notifier)
              .prepareVibeForLibraryParamSave(
                vibe,
                strength: vibe.strength,
                infoExtracted: vibe.infoExtracted,
                model: model,
              );
          if (encoded == null) {
            throw StateError(currentL10n.vibe_import_importFailed);
          }
          return encoded;
        },
      );
      await library.reload();
      if (mounted && alive()) {
        setState(() => _import = null);
        _platform.imported(context, result.success, result.failed);
      }
    } finally {
      _importing = false;
    }
  }

  Future<void> _export(RefsExportPlan plan) async {
    final entries = <VibeLibraryEntry>[];
    for (final key in plan.keys.toSet()) {
      final entry = await _storage.getEntry(key);
      if (entry == null) {
        throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
      }
      entries.add(entry);
    }
    await RefsExporter.export(
      entries,
      plan,
      model: ref.read(generationParamsNotifierProvider).model,
    );
    await _preferences.saveExportFolder(plan.folder);
    if (mounted) {
      setState(() {
        _exportFolder = plan.folder;
        _exportAll = false;
      });
    }
  }

  Future<void> _setCover(String key, int index) async {
    final entry = await _storage.getEntry(key);
    if (entry == null) {
      throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
    }
    final vibes = await _bundleVibes(entry);
    if (index < 0 || index >= vibes.length) return;
    final preview = vibes[index].thumbnail;
    if (preview == null) {
      throw StateError(currentL10n.preciseRefLib_imageMissing);
    }
    await _library.updateEntryThumbnail(key, preview);
    await _refreshDetail();
  }

  Future<void> _pack(List<String> keys) async {
    final vibes = <VibeReference>[];
    for (final key in keys.toSet()) {
      final entry = await _storage.getEntry(key);
      if (entry == null) {
        throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
      }
      vibes.addAll(
        entry.isBundle ? await _bundleVibes(entry) : [entry.toVibeReference()],
      );
    }
    if (!mounted || vibes.isEmpty) return;
    final name = await _platform.bundleName(context);
    if (!mounted || name == null || name.trim().isEmpty) return;
    final saved = await _library.saveBundleEntry(
      vibes,
      name: name,
      categoryId: _filter.categoryId == '' ? null : _filter.categoryId,
    );
    if (saved == null) throw StateError(currentL10n.vibe_import_importFailed);
  }

  RefsActions _actions(List<RefsEntry> all) => RefsActions(
    onFilterChanged: (filter) {
      setState(() => _filter = filter);
      _run(() => _preferences.saveFilter(filter));
    },
    onCardSizeChanged: (size) {
      _cardChanged = true;
      setState(() => _cardSize = size);
      _run(() => _preferences.saveCardSize(size));
    },
    onSidebarChanged: (open) {
      setState(() => _sidebarOpen = open);
      _run(() => _preferences.saveSidebar(open));
    },
    onInspectorChanged: (open) {
      setState(() => _inspectorOpen = open);
      _run(() => _preferences.saveInspector(open));
    },
    onSelect: (key) => unawaited(_select(key)),
    onAddToGeneration: (keys, {replace = false, overrides = const {}}) =>
        _send(() => _add(keys, replace: replace, overrides: overrides)),
    onAddBundle: (key, {indexes, overrides = const {}, replace = false}) =>
        _send(() async {
          final result = await _target.addVibes(
            [key],
            indexes: indexes,
            childOverrides: overrides,
            replace: replace,
            alive: _alive,
          );
          if (mounted) {
            _platform.sent(context, result.count, truncated: result.truncated);
          }
        }),
    onSendImg2Img: (key) => _send(() async {
      final applied = await _target.sendImg2Img(key, alive: _alive);
      if (mounted && applied) _platform.generate(context);
    }),
    onSaveAsVibe: (key) => _run(() async {
      final entry = ref
          .read(preciseRefLibraryNotifierProvider)
          .entries
          .where((e) => e.id == key)
          .first;
      final bytes = await ref
          .read(preciseRefLibraryStorageServiceProvider)
          .readImageBytes(key);
      if (bytes == null) {
        throw StateError(currentL10n.preciseRefLib_imageMissing);
      }
      final saved = await _library.saveEntry(
        VibeLibraryEntry.fromVibeReference(
          name: entry.name,
          vibeData: VibeReference(
            displayName: entry.name,
            vibeEncoding: '',
            sourceType: VibeSourceType.rawImage,
            rawImageData: bytes,
            thumbnail: bytes,
          ),
        ),
      );
      if (saved == null) throw StateError(currentL10n.vibe_import_importFailed);
    }),
    onSetFavorite: (keys, favorite) => _run(
      () => _mutateKeys(keys, (key) async {
        final saved = _vibe
            ? await _library.setFavorite(key, favorite)
            : await _precise.setFavorite(key, favorite);
        if (saved == null) {
          throw StateError(currentL10n.preciseRefLib_imageMissing);
        }
      }),
    ),
    onRename: (key, name) => _run(
      () => _mutateKeys([key], (key) async {
        if (_vibe) {
          final result = await _library.renameEntry(key, name);
          if (!result.isSuccess) {
            throw StateError(currentL10n.vibe_import_importFailed);
          }
        } else {
          await _precise.updateEntry(key, name: name);
        }
      }),
    ),
    onUpdateParams: (key, patch) => _run(() => _saveParams(key, patch)),
    onSetStrengthMany: (keys, value) => _run(
      () => _mutateKeys(
        keys,
        (key) => _saveParams(key, RefsParamsPatch(strength: value)),
      ),
    ),
    onSetTypeMany: (keys, type) => _run(
      () => _mutateKeys(
        keys,
        (key) => _saveParams(key, RefsParamsPatch(type: type)),
      ),
    ),
    onSaveBundle: (key, values) => _run(() => _saveBundle(key, values)),
    onSplitBundle: (key) => _run(() async {
      final entry = await _storage.getEntry(key);
      if (entry == null) {
        throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
      }
      final vibes = await _bundleVibes(entry);
      final importer = VibeImportService(
        repository: VibeLibraryStorageImportRepository(_storage),
      );
      final result = await importer.importPrepared(
        name: entry.name,
        references: vibes,
        categoryId: entry.categoryId,
        tags: entry.tags,
      );
      await _library.reload();
      if (mounted) {
        _platform.imported(context, result.successCount, result.failCount);
      }
    }),
    onSetBundleCover: (key, index) => _run(() => _setCover(key, index)),
    onPackBundle: (keys) => _run(() => _pack(keys)),
    onEncodeNow: (key) => _run(
      () => _saveParams(key, const RefsParamsPatch(), forceEncode: true),
    ),
    onMoveToCategory: (keys, id) => _run(
      () => _mutateKeys(keys, (key) async {
        await _library.updateEntryCategory(key, id);
      }),
    ),
    onAddTags: (keys, tags) => _run(
      () => _mutateKeys(keys, (key) async {
        final entry = _library.getEntryById(key);
        if (entry != null) {
          await _library.updateEntryTags(
            key,
            {...entry.tags, ...tags}.toList(),
          );
        }
      }),
    ),
    onRemoveTag: (key, tag) => _run(
      () => _mutateKeys([key], (key) async {
        final entry = _library.getEntryById(key);
        if (entry != null) {
          await _library.updateEntryTags(
            key,
            entry.tags.where((t) => t != tag).toList(),
          );
        }
      }),
    ),
    onCreateCategory: (name, {parentId}) async {
      final saved = await _library.saveCategory(
        VibeLibraryCategory.create(name: name, parentId: parentId),
      );
      if (saved == null) throw StateError(currentL10n.vibe_import_importFailed);
      await ref.read(vibeLibraryCategoryNotifierProvider.notifier).refresh();
      return saved.id;
    },
    onRenameCategory: (id, name) => _run(() async {
      await _library.updateCategoryName(id, name);
      await ref.read(vibeLibraryCategoryNotifierProvider.notifier).refresh();
    }),
    onDeleteCategory: (id) => _run(() async {
      await _library.deleteCategory(id);
      await ref.read(vibeLibraryCategoryNotifierProvider.notifier).refresh();
      if (mounted && _filter.categoryId == id) {
        setState(() => _filter = _filter.copyWith(categoryId: () => null));
      }
    }),
    onMoveCategory: (id, parent) => _run(() async {
      final result = await _library.moveCategory(id, parent);
      if (result == null) {
        throw StateError(currentL10n.vibe_import_importFailed);
      }
      await ref.read(vibeLibraryCategoryNotifierProvider.notifier).refresh();
    }),
    onImport: (source) => _run(() async {
      final files = await _platform.pickFiles(widget.kind, source);
      if (mounted) await _prepareImport(files);
    }),
    onImportConfirm: (plan) => _run(() => _confirmImport(plan)),
    onImportCancel: () {
      _importGeneration++;
      setState(() => _import = null);
    },
    onExport: (plan) => _run(() => _export(plan)),
    onPickExportFolder: () async {
      final path = await _platform.folder();
      if (path != null) {
        await _preferences.saveExportFolder(path);
        if (mounted) setState(() => _exportFolder = path);
      }
      return path;
    },
    onExportAll: () => setState(() => _exportAll = true),
    onRescan: () => _run(() async {
      setState(() => _loading = true);
      try {
        if (_vibe) {
          final result = await _library.syncWithFileSystem();
          if (result.failedCount > 0) {
            throw StateError(currentL10n.vibe_import_importFailed);
          }
          await _library.reload();
        } else {
          await _precise.reload(showLoading: true);
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }),
    onOpenFolder: (key) => _run(() async {
      final path = key == null
          ? _folderPath
          : _vibe
          ? (await _storage.getEntry(key))?.filePath
          : ref
                .read(preciseRefLibraryNotifierProvider)
                .entries
                .where((e) => e.id == key)
                .firstOrNull
                ?.imagePath;
      if (path != null) await _platform.openFolder(path);
    }),
    onReplacePreview: (key) => _run(() async {
      final files = await _platform.pickFiles(
        RefsKind.vibe,
        RefsImportSource.images,
      );
      if (files.isEmpty) return;
      await _library.updateEntryThumbnail(key, files.first.bytes);
      await _refreshDetail();
    }),
    onCopyImage: (key) => _run(() async {
      final Uint8List? bytes;
      if (_vibe) {
        final entry = await _storage.getEntry(key);
        bytes = entry?.rawImageData ?? entry?.thumbnail ?? entry?.vibeThumbnail;
      } else {
        bytes = await ref
            .read(preciseRefLibraryStorageServiceProvider)
            .readImageBytes(key);
      }
      if (bytes == null) {
        throw StateError(currentL10n.preciseRefLib_imageMissing);
      }
      await _platform.copyImage(bytes);
    }),
    onDelete: (keys) => _run(
      () => _mutateKeys(keys, (key) async {
        final removed = _vibe
            ? await _library.deleteEntry(key)
            : await _precise.deleteEntry(key);
        if (!removed) throw StateError(currentL10n.vibe_import_importFailed);
        if (_selectedKey == key && mounted) {
          _selection++;
          setState(() {
            _selectedKey = null;
            _detail = null;
            _full = null;
          });
        }
      }),
    ),
    onTrayRemove: (id) =>
        _run(() => _target.removeTray(widget.kind, id, alive: _alive)),
    onTrayClear: () =>
        _run(() => _target.removeTray(widget.kind, null, alive: _alive)),
    onPauseVibes: (paused) =>
        _run(() => _target.pauseVibes(paused, alive: _alive)),
    onGoGeneration: () => _platform.generate(context),
    onSwitchModel: () => _run(() async {
      final snapshot = _target.capture();
      _target.check(snapshot, _alive);
      await ref.read(refsDraftBackupProvider).save(snapshot.json);
      _target.check(snapshot, _alive);
      ref
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV45Full);
    }),
  );

  Future<void> _summarizeDrop(List<DataReader> readers, int generation) async {
    bool current() => mounted && generation == _hoverGeneration;
    if (!current()) return;
    final model = ref.read(generationParamsNotifierProvider).model;
    final files = await RefsDropReader.read(
      readers,
      widget.kind,
      isCurrent: current,
    );
    if (!current()) return;
    final summary = await RefsDropReader.summarize(
      files,
      model,
      isCurrent: current,
    );
    if (current()) setState(() => _drop = summary);
  }

  Future<void> _dropFiles(Future<List<DroppedFileData>> captured) async {
    try {
      final files = await captured;
      final operation = _queue.then((_) async {
        if (mounted) await _prepareImport(files);
      });
      _queue = operation.catchError((Object error) => _reportError(error));
      await _queue;
    } catch (error) {
      _reportError(error);
    } finally {
      _dropBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(generationParamsNotifierProvider);
    final statuses = _vibe ? ref.watch(refsVibeStatusesProvider) : null;
    final tray = _target.tray(
      widget.kind,
      statuses: statuses?.valueOrNull ?? const {},
    );
    final inUse = tray.items
        .map((item) => item.entryKey)
        .whereType<String>()
        .toSet();
    final List<RefsEntry> all;
    var loading = _loading;
    List<RefsCategory> categories = const [];
    if (_vibe) {
      final state = ref.watch(vibeLibraryNotifierProvider);
      final storage = ref.watch(vibeLibraryStorageServiceProvider);
      loading =
          loading ||
          state.isLoading ||
          state.isInitializing ||
          (state.error != null && state.entries.isEmpty);
      all = [
        for (final entry in state.entries)
          mapVibeEntry(
            _full?.id == entry.id ? _full! : entry,
            model: params.model,
            status: _full?.id == entry.id
                ? _fullStatus
                : statuses?.valueOrNull?[entry.id],
            thumb: RefsLazyImage(
              storage,
              entry.id,
              storage.getDisplayThumbnailRevision(entry.id),
              () => storage.getDisplayThumbnail(entry.id),
            ),
            inGeneration: inUse.contains(entry.id),
          ),
      ];
      categories = refsCategories(
        ref.watch(vibeLibraryCategoryNotifierProvider).categories,
        all,
      );
    } else {
      final state = ref.watch(preciseRefLibraryNotifierProvider);
      final storage = ref.watch(preciseRefLibraryStorageServiceProvider);
      loading =
          loading ||
          state.isLoading ||
          (state.error != null && state.entries.isEmpty);
      all = [
        for (final entry in state.entries)
          mapPreciseEntry(
            entry,
            imageSize: entry.id == _selectedKey ? _detailSize : null,
            thumb: RefsLazyImage(
              storage,
              entry.id,
              entry.hashCode,
              () => storage.getDisplayThumbnail(entry.id),
            ),
            inGeneration: inUse.contains(entry.id),
          ),
      ];
    }
    final actions = _actions(all);
    RefsViewData data(List<RefsEntry> entries) => RefsViewData(
      kind: widget.kind,
      now: DateTime.now(),
      model: refsModel(params.model),
      costs: refsCosts(),
      entries: entries,
      counts: refsCounts(all),
      categories: categories,
      filter: _filter,
      selectedKey: _selectedKey,
      detail: _detail,
      tray: tray,
      cardSize: _cardSize,
      sidebarOpen: _sidebarOpen,
      inspectorOpen: _inspectorOpen,
      folderPath: _folderPath,
      exportFolder: _exportFolder,
      importType: _filter.type ?? RefsPreciseType.both,
      loading: loading,
      drop: _drop,
      importDraft: _import?.draft,
      reducedMotion: ref.watch(canvasReducedMotionNotifierProvider),
    );
    final page = RefsLibraryPage(
      key: _page,
      data: data(filterRefsEntries(all, _filter)),
      actions: actions,
    );
    return Material(
      type: MaterialType.transparency,
      child: DropRegion(
        formats: Formats.standardFormats,
        hitTestBehavior: HitTestBehavior.opaque,
        onDropOver: (event) {
          if (_dropBusy ||
              !event.session.allowedOperations.contains(DropOperation.copy)) {
            return DropOperation.none;
          }
          if (!_hoverStarted &&
              event.session.items.any((item) => item.dataReader != null)) {
            _hoverStarted = true;
            final generation = ++_hoverGeneration;
            final readers = [
              for (final item in event.session.items)
                if (item.dataReader case final reader?) reader,
            ];
            // Keep the existing exact preview, but don't read/parse entire
            // batches when the pointer only passes over the library briefly.
            _hoverTimer = Timer(const Duration(milliseconds: 200), () {
              unawaited(
                _summarizeDrop(readers, generation).catchError((Object _) {}),
              );
            });
          }
          return DropOperation.copy;
        },
        onDropLeave: (_) {
          _hoverTimer?.cancel();
          _hoverGeneration++;
          _hoverStarted = false;
          if (_drop != null) setState(() => _drop = null);
        },
        onPerformDrop: (event) async {
          if (_dropBusy) return;
          _dropBusy = true;
          _hoverTimer?.cancel();
          _hoverGeneration++;
          _hoverStarted = false;
          setState(() => _drop = null);
          final captured = RefsDropReader.read([
            for (final item in event.session.items)
              if (item.dataReader case final reader?) reader,
          ], widget.kind);
          unawaited(_dropFiles(captured));
        },
        child: UiModal(
          onDismiss: () => setState(() => _exportAll = false),
          dialog: _exportAll
              ? (_) => RefsScope(
                  data: data(all),
                  actions: actions,
                  controller: _page.currentState! as RefsController,
                  child: RefsExportDialog(
                    keys: all.map((e) => e.key).toList(),
                    onClose: () => setState(() => _exportAll = false),
                  ),
                )
              : null,
          child: page,
        ),
      ),
    );
  }
}
