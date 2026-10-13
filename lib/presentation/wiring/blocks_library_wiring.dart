import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/prompt_block_exchange.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/generation/generation_params_notifier.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_page.dart';
import '../ui/blocks/blocks_edit.dart';
import '../utils/prompt_block_generation_settings_applier.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import 'blocks_actions.dart';
import 'blocks_library_backend.dart';
import 'blocks_mapping.dart';
import 'blocks_platform.dart';
import 'blocks_preferences.dart';

final blockSourceStateProvider = FutureProvider.autoDispose
    .family<BlockSourceState, PromptBlock>((ref, block) async {
      if (block.sourcePath == null || block.sourceHash == null) {
        return BlockSourceState.none;
      }
      final file = File(block.sourcePath!);
      try {
        if (!await file.exists()) return BlockSourceState.missing;
        var bytes = await file.readAsBytes();
        if (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF) {
          bytes = bytes.sublist(3);
        }
        return PromptBlockExchange.contentHash(
                  utf8.decode(bytes, allowMalformed: true),
                ) ==
                block.sourceHash
            ? BlockSourceState.synced
            : BlockSourceState.changed;
      } on FileSystemException {
        return BlockSourceState.missing;
      }
    });

class BlocksLibraryWiring extends ConsumerStatefulWidget {
  const BlocksLibraryWiring({
    super.key,
    this.initialBlockId,
    this.initialRequest,
  });
  final String? initialBlockId;
  final Object? initialRequest;
  @override
  ConsumerState<BlocksLibraryWiring> createState() =>
      _BlocksLibraryWiringState();
}

class _BlocksLibraryWiringState extends ConsumerState<BlocksLibraryWiring> {
  String _query = '';
  String? _selected;
  Set<BlocksQuick> _quick = {};
  final _versions = <String, List<PromptBlock>>{};

  @override
  void didUpdateWidget(BlocksLibraryWiring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRequest != oldWidget.initialRequest ||
        widget.initialBlockId != oldWidget.initialBlockId) {
      _focusInitialBlock();
    }
  }

  void _focusInitialBlock() {
    final id = widget.initialBlockId;
    if (id == null) return;
    _query = '';
    _quick = {};
    _selected = id;
    final request = widget.initialRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.initialRequest != request || _selected != id) {
        return;
      }
      BlocksActions(
        ref,
        context,
        () => mounted,
      ).preference((value) => value.copyWith(scope: const BlocksScope.all()));
    });
  }

  BlockDraft? _editingDraftOf(String id) {
    if (!mounted) return null;
    BlockDraft? result;
    void visit(Element element) {
      if (result != null) return;
      final widget = element.widget;
      if (widget is BlockEditDialog && widget.data.blockId == id) {
        result = widget.data.draft;
      } else {
        element.visitChildElements(visit);
      }
    }

    (context as Element).visitChildElements(visit);
    return result;
  }

  @override
  void initState() {
    super.initState();
    _selected = ref.read(blocksLibrarySelectionProvider);
    _focusInitialBlock();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(promptBlockLibraryNotifierProvider);
    final preferencesAsync = ref.watch(blocksPreferencesProvider);
    final library =
        libraryAsync.valueOrNull ??
        PromptBlockLibraryState(blocks: const [], folders: const []);
    final preferences =
        preferencesAsync.valueOrNull ?? const BlocksPreferences();
    final palette = ref.watch(promptBlockPaletteNotifierProvider).valueOrNull;
    ref.listen(blocksLibrarySelectionProvider, (_, id) {
      setState(() {
        _selected = id;
        _query = '';
        _quick = {};
      });
    });
    ref.listen(promptBlockLibraryNotifierProvider, (_, next) {
      if (next.hasError) {
        AppToast.error(
          context,
          context.l10n.promptBlockLibrary_importFailed('${next.error}'),
        );
      }
    });
    final requested = _selected;
    final selected = requested == null ? null : library.blockById(requested);
    final source = selected == null
        ? null
        : ref.watch(blockSourceStateProvider(selected)).valueOrNull;
    final model = ref.watch(
      generationParamsNotifierProvider.select((p) => p.model),
    );
    final data = mapBlocksLibrary(
      library,
      preferences: preferences,
      query: _query,
      quick: _quick,
      loading: libraryAsync.isLoading || preferencesAsync.isLoading,
      selectedId: requested,
      catalog: blocksParamCatalog,
      paletteIds: palette?.blocks.map((b) => b.id).toSet() ?? {},
      sourceStates: {
        if (selected != null && source != null) selected.id: source,
      },
      incompatibility: (b) {
        final settings = b.generationSettings;
        if (settings == null) return null;
        try {
          validatePromptBlockGenerationSettings(
            settings,
            settings.model ?? model,
          );
          return null;
        } on StateError {
          return context.l10n.promptBlockLibrary_settingsIncompatible;
        }
      },
    );
    final host = BlocksActions(ref, context, () => mounted && context.mounted);
    final backend = ref.read(blocksLibraryBackendProvider);
    final platform = ref.read(blocksPlatformProvider);
    void run(Future<void> Function() action) {
      host.run(action);
    }

    void queued(Future<void> Function() action) =>
        run(() => backend.serialize(action));
    if (!data.loading && data.selectedId == null && requested != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selected == requested) setState(() => _selected = null);
      });
    }
    if (!data.loading && data.scope != preferences.scope) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          host.preference(
            (p) => p.scope == preferences.scope
                ? p.copyWith(scope: data.scope)
                : p,
          );
        }
      });
    }
    final displayedIds = data.blocks.map((b) => b.id).toSet();
    final liveIds = library.blocks.map((b) => b.id).toSet();
    _versions.removeWhere((id, _) => !liveIds.contains(id));
    for (final b in library.blocks) {
      if (!displayedIds.contains(b.id)) continue;
      final history = _versions.putIfAbsent(b.id, () => []);
      final snapshot = blockDraftSnapshot(
        BlockDraft.of(blockDataOf(b, library)),
      );
      if (history.isNotEmpty &&
          const DeepCollectionEquality().equals(
            snapshot,
            blockDraftSnapshot(
              BlockDraft.of(blockDataOf(history.last, library)),
            ),
          )) {
        history[history.length - 1] = b;
      } else {
        history.add(b);
        if (history.length > 12) history.removeAt(0);
      }
    }
    final actions = BlocksLibraryActions(
      onScopeChanged: (scope) {
        setState(() {
          _query = '';
          _selected = null;
        });
        host.preference((p) => p.copyWith(scope: scope));
      },
      onQueryChanged: (value) => setState(() => _query = value),
      onSortChanged: (sort, {required descending}) => host.preference(
        (p) => p.copyWith(sort: sort, descending: descending),
      ),
      onViewChanged: (view) => host.preference((p) => p.copyWith(view: view)),
      onQuickChanged: (quick) => setState(() => _quick = Set.of(quick)),
      onCardSizeChanged: (size) => host.preference(
        (p) =>
            p.copyWith(cardSize: size.isFinite ? size.clamp(0, 1) : p.cardSize),
      ),
      onSidebarChanged: (value) =>
          host.preference((p) => p.copyWith(sidebarOpen: value)),
      onInspectorChanged: (value) =>
          host.preference((p) => p.copyWith(inspectorOpen: value)),
      onSelect: (id) => setState(() => _selected = id),
      onInsert: host.insert,
      onSetFavorite: (ids, value) => queued(
        () => backend.notifier.setFavorite(ids.toSet().toList(), value),
      ),
      onDuplicate: (id) => host.run(() async {
        final scope = ref.read(blocksPreferencesProvider).requireValue.scope;
        final clone = await backend.duplicate(id);
        if (!mounted) return;
        if (scope.kind == BlocksScopeKind.recent &&
            ref.read(blocksPreferencesProvider).requireValue.scope == scope) {
          final target = clone.folderId == null
              ? const BlocksScope.uncategorized()
              : BlocksScope.folder(clone.folderId!);
          await ref
              .read(blocksPreferencesProvider.notifier)
              .change((p) => p.scope == scope ? p.copyWith(scope: target) : p);
        }
        if (mounted) setState(() => _selected = clone.id);
      }),
      onCopyText: (id) => run(() async {
        await Clipboard.setData(
          ClipboardData(text: backend.requireBlock(id).content),
        );
        if (context.mounted) {
          AppToast.success(context, context.l10n.common_copied);
        }
      }),
      onCreate: (draft) async {
        await host.run(() => backend.save(draft));
      },
      onSave: (id, draft) async {
        final initial = _editingDraftOf(id);
        final candidates = _versions[id] ?? const <PromptBlock>[];
        final expected = initial == null
            ? library.blockById(id)
            : candidates.reversed
                  .where(
                    (b) => const DeepCollectionEquality().equals(
                      blockDraftSnapshot(initial),
                      blockDraftSnapshot(
                        BlockDraft.of(blockDataOf(b, library)),
                      ),
                    ),
                  )
                  .firstOrNull;
        await host.run(() async {
          try {
            if (initial != null && expected == null) {
              throw StateError(context.l10n.bridge_conflict);
            }
            await backend.save(draft, id: id, expected: expected);
          } catch (_) {
            await platform.backupDraft(
              jsonEncode({
                'kind': 'pending-block-edit',
                'id': id,
                'before': expected?.toJson(),
                'draft': blockDraftSnapshot(draft),
              }),
            );
            rethrow;
          }
        });
      },
      onUpdate: (id, patch) => run(() => backend.patch(id, patch)),
      onBatchStyle: (ids, {color, look}) => run(
        () => backend.mapBlocks(
          ids,
          (b) => b.copyWith(
            color: color == null ? b.color : blockColorString(color),
            appearance: look?.name ?? b.appearance,
          ),
        ),
      ),
      onDelete: host.delete,
      onDropToFolder: (ids, folder, mode) => host.transfer(
        ids,
        PromptBlockTransferTarget(PromptBlockTransferKind.folder, folder),
        mode,
      ),
      onDropToCollection: (ids, collection, mode) => host.transfer(
        ids,
        PromptBlockTransferTarget(
          PromptBlockTransferKind.collection,
          collection,
        ),
        mode,
        sourceCollectionId: data.scope.kind == BlocksScopeKind.collection
            ? data.scope.id
            : null,
      ),
      onRemoveFromCollection: (ids, collection) =>
          run(() => backend.removeFromCollection(ids, collection)),
      onReorder: (id, before) {
        if (data.sort == BlocksSort.custom) {
          run(() => backend.reorder(id, before));
        }
      },
      onAddTag: (ids, tag) => run(
        () => backend.mapBlocks(
          ids,
          (b) => b.tags.any((t) => t.name == tag.name)
              ? b
              : b.copyWith(
                  tags: [
                    ...b.tags,
                    PromptBlockTag(
                      name: tag.name,
                      color: blockColorString(tag.color),
                    ),
                  ],
                ),
        ),
      ),
      onRemoveTag: (ids, tag) => run(
        () => backend.mapBlocks(
          ids,
          (b) => b.copyWith(tags: b.tags.where((t) => t.name != tag).toList()),
        ),
      ),
      onAddToPalette: (ids) => run(() async {
        final palette = ref.read(promptBlockPaletteNotifierProvider.notifier);
        for (final id in ids.toSet()) {
          await palette.addBlock(id);
        }
      }),
      onExport: (ids) => run(
        () => platform.exportTxt([
          for (final id in ids.toSet()) backend.requireBlock(id),
        ], context.l10n.common_export),
      ),
      onApplyParams: host.applyParams,
      onPickThumbnail: () =>
          host.run(platform.pickThumbnail).then((value) => value),
      onCaptureParams: host.captureParams,
      onCreateFolder: (name, {parentId}) => host.run(
        () => backend.serialize(
          () async => (await backend.notifier.createFolder(
            name: name,
            parentId: parentId,
          )).id,
        ),
      ),
      onRenameFolder: (id, name) => queued(() async {
        final folder = backend.library.folderById(id);
        if (folder != null) {
          await backend.notifier.updateFolder(folder.copyWith(name: name));
        }
      }),
      onDeleteFolder: host.deleteFolder,
      onToggleFolder: (id, expanded) => host.preference(
        (p) => p.copyWith(
          expanded: expanded
              ? {...p.expanded, id}
              : (Set.of(p.expanded)..remove(id)),
        ),
      ),
      onMoveFolder: (id, parent) => queued(() async {
        await backend.notifier.moveFolder(id, parent);
      }),
      onReorderFolder: (id, delta) => queued(() async {
        final folder = backend.library.folderById(id);
        if (folder == null || (delta != -1 && delta != 1)) return;
        final ids = backend.library
            .foldersIn(folder.parentId)
            .map((f) => f.id)
            .toList();
        final index = ids.indexOf(id);
        final next = (index + delta).clamp(0, ids.length - 1);
        if (index == next) return;
        ids.removeAt(index);
        ids.insert(next, id);
        await backend.notifier.reorderFolders(folder.parentId, ids);
      }),
      onCreateCollection: (name, {parentId, isFolder = false}) => host.run(
        () => backend.serialize(
          () async => (await backend.notifier.createCollection(
            name: name,
            parentId: parentId,
            isFolder: isFolder,
          )).id,
        ),
      ),
      onRenameCollection: (id, name) => queued(() async {
        await backend.notifier.renameCollection(id, name);
      }),
      onDeleteCollection: (id) => run(() async {
        final node = backend.library.collectionById(id);
        if (node == null) return;
        final confirmed = await ThemedConfirmDialog.showDelete(
          context: context,
          itemName: node.name,
          content: node.isFolder
              ? context.l10n.promptBlockLibrary_deleteCollectionFolderConfirm(
                  node.name,
                )
              : context.l10n.promptBlockLibrary_deleteCollectionConfirm(
                  node.name,
                ),
        );
        if (confirmed && context.mounted) {
          await backend.serialize(() => backend.notifier.deleteCollection(id));
        }
      }),
      onRenameTag: (name, newName) =>
          run(() => backend.changeTag(name, newName: newName)),
      onSetTagColor: (name, color) =>
          run(() => backend.changeTag(name, color: blockColorString(color))),
      onDeleteTag: (name) => run(() async {
        final confirmed = await ThemedConfirmDialog.showDelete(
          context: context,
          itemName: name,
        );
        if (confirmed && context.mounted) {
          await backend.changeTag(name, delete: true);
        }
      }),
      onImportTxt: host.importTxt,
      onImportFolder: host.importFolder,
      onImportCuration: host.importFolder,
      onExportBackup: () => run(() async {
        final title = context.l10n.promptBlockLibrary_exportLibraryBackup;
        final backup = await backend.notifier.exportLibrary();
        await platform.exportBackup(backup, title);
      }),
      onImportBackup: () => run(() async {
        final backup = await platform.pickBackup(
          context.l10n.promptBlockLibrary_libraryImportTitle,
        );
        if (backup != null && context.mounted) {
          await backend.serialize(() => backend.notifier.importLibrary(backup));
        }
      }),
    );
    return Material(
      type: MaterialType.transparency,
      child: BlocksLibraryPage(data: data, actions: actions),
    );
  }
}
