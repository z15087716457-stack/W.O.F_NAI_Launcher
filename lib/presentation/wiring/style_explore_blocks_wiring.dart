import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import 'blocks_preferences.dart';
import '../providers/layout_state_provider.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../router/app_router.dart';
import 'blocks_actions.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_dock.dart';
import '../ui/blocks/blocks_instance.dart';
import '../utils/prompt_block_bundle_insertion.dart';
import '../utils/prompt_block_generation_settings_applier.dart';
import '../utils/prompt_block_instance_bundle.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/prompt/blocks/prompt_block_colors.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'style_explore_backend.dart';
import 'style_explore_mapping.dart';

BlockData styleExploreBlockData(
  PromptBlock block,
  PromptBlockLibraryState library,
) => BlockData(
  id: block.id,
  title: block.displayTitle,
  color: promptBlockColorFromString(block.color),
  icon: block.iconName,
  look:
      BlockAppearance.values.asNameMap()[block.appearance] ??
      BlockAppearance.classic,
  atoms: block.atomsOrSplit,
  negativeAtoms: block.negativeAtomsOrSplit,
  params: block.generationSettings == null
      ? null
      : BlockParams(
          model: block.generationSettings!.model,
          steps: block.generationSettings!.steps,
          scale: block.generationSettings!.scale,
          cfgRescale: block.generationSettings!.cfgRescale,
          sampler: block.generationSettings!.sampler,
          noiseSchedule: block.generationSettings!.noiseSchedule,
          width: block.generationSettings!.width,
          height: block.generationSettings!.height,
        ),
  tags: [
    for (final tag in block.tags)
      BlockTag(tag.name, promptBlockColorFromString(tag.color)),
  ],
  folderId: block.folderId,
  folderName: library.folderById(block.folderId ?? '')?.name,
  thumb: block.hasThumbnail
      ? BlockThumb(
          FileImage(File(block.thumbnail!)),
          offsetX: block.thumbnailOffsetX,
          offsetY: block.thumbnailOffsetY,
          scale: block.thumbnailScale,
        )
      : null,
  useCount: block.useCount,
  favorite: block.isFavorite,
  createdAt: block.createdAt,
  updatedAt: block.updatedAt,
  sourcePath: block.sourcePath,
  importedAt: block.importedAt,
  reading: block.readingTranslationZh,
  readingNeedsReview: block.readingTranslationNeedsReview,
);

BlockRollSettings styleExploreBlockRules(PillInstanceSettings s) =>
    BlockRollSettings(
      mode: BlockMode.values.byName(s.mode.name),
      countMin: s.countMin,
      countMax: s.countMax,
      order: BlockOrder.values.byName(s.order.name),
      weightEnabled: s.weightEnabled,
      weightMin: s.weightMin,
      weightMax: s.weightMax,
      weightAverage: s.weightAverage,
      leftDispersion: s.leftDispersion,
      rightDispersion: s.rightDispersion,
      softBalance: s.softBalance,
      softBalanceStrength: s.softBalanceStrength,
      probability: s.triggerProbability,
    );
PillInstanceSettings styleExplorePillRules(BlockRollSettings s) =>
    PillInstanceSettings(
      mode: PillRollMode.values.byName(s.mode.name),
      countMin: s.countMin,
      countMax: s.countMax,
      order: PillRollOrder.values.byName(s.order.name),
      weightEnabled: s.weightEnabled,
      weightMin: s.weightMin,
      weightMax: s.weightMax,
      weightAverage: s.weightAverage,
      leftDispersion: s.leftDispersion,
      rightDispersion: s.rightDispersion,
      softBalance: s.softBalance,
      softBalanceStrength: s.softBalanceStrength,
      triggerProbability: s.probability,
    );
List<BlockDrawn> styleExploreDrawn(String text) => [
  for (final atom in PillRollEngine.splitTopLevelAtoms(text))
    if (RegExp(r'^([-+]?\d+(?:\.\d+)?)::([\s\S]*)::$').firstMatch(atom)
        case final match?)
      BlockDrawn(match.group(2)!.trim(), double.parse(match.group(1)!))
    else
      BlockDrawn(atom),
];

Future<void> _blockAction(
  BuildContext context,
  FutureOr<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      AppToast.error(context, context.l10n.styleExplore_operationFailed);
    }
  }
}

Future<void> _editBlock(BuildContext context, WidgetRef ref, String? id) async {
  await ref.read(promptBlockLibraryNotifierProvider.future);
  if (!context.mounted) return;
  await BlocksActions(ref, context, () => context.mounted).edit(id: id);
}

Future<int?> insertStyleExploreBlock(
  BuildContext context,
  WidgetRef ref,
  String id, {
  String? scope,
  int? offset,
  bool Function()? alive,
}) async {
  try {
    final original = ref
        .read(promptBlockLibraryNotifierProvider)
        .valueOrNull
        ?.blockById(id);
    if (original == null) throw StateError(context.l10n.blocks_missing);
    final target = ref.read(pillActiveEditorTargetProvider);
    final lane = scope ?? target?.scope ?? PillScopes.main;
    final caret =
        offset ??
        target?.caret ??
        ref.read(pillWorkspaceProvider(lane)).document.text.length;
    final write = ref
        .read(styleExploreBackendProvider)
        .captureDraft(
          alive: () {
            if (!context.mounted ||
                alive?.call() == false ||
                (scope == null &&
                    ref.read(pillActiveEditorTargetProvider) != target)) {
              return false;
            }
            final latest = ref
                .read(promptBlockLibraryNotifierProvider)
                .valueOrNull
                ?.blockById(id);
            return latest != null &&
                latest.copyWith(
                      useCount: original.useCount,
                      updatedAt: original.updatedAt,
                    ) ==
                    original;
          },
        );
    var inserted = 0;
    await write(() {
      inserted = insertPromptBlockBundle(
        ref,
        scope: lane,
        offset: caret,
        blockId: id,
      );
    });
    await ref.read(blocksPreferencesProvider.notifier).recordUse(id);
    return inserted;
  } catch (_) {
    if (context.mounted) {
      AppToast.error(context, context.l10n.styleExplore_operationFailed);
    }
    return null;
  }
}

Future<void> openStyleExploreVariable(
  BuildContext context,
  WidgetRef ref,
  int index,
) async {
  final instances = styleExploreVariableInstances(
    ref.read(pillWorkspaceProvider(PillScopes.main)).document,
  );
  if (index < 0 || index >= instances.length) return;
  final marker = instances[index].key;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: StyleExploreVariableWiring(
        marker: marker,
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    ),
  );
}

class StyleExploreVariableWiring extends ConsumerWidget {
  const StyleExploreVariableWiring({
    super.key,
    required this.marker,
    required this.onDismiss,
  });
  final String marker;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(pillWorkspaceProvider(PillScopes.main));
    final instance = workspace.document.instances[marker];
    if (instance == null) return const SizedBox.shrink();
    final library =
        ref.watch(promptBlockLibraryNotifierProvider).valueOrNull ??
        PromptBlockLibraryState(blocks: [], folders: []);
    final block = library.blockById(instance.blockId);
    final bundle = readPromptBlockInstanceBundle(ref, PillScopes.main, marker);
    for (final member in bundle.members) {
      ref.watch(pillWorkspaceProvider(member.scope));
    }
    final source = bundle.members.firstWhere(
      (member) => member.instance.settings.hasRoll,
      orElse: () => BundleMember(PillScopes.main, marker, instance),
    );
    final settings = source.instance.settings;
    final atoms = instance.useNegativeContent
        ? block?.negativeAtomsOrSplit ?? <String>[]
        : block?.atomsOrSplit ?? <String>[];
    final send =
        workspace.document.instances[marker]?.enabled == false || block == null
        ? ''
        : instance.settings.hasRoll
        ? instance.currentRoll ?? ''
        : instance.useNegativeContent
        ? block.negativeContent
        : block.content;
    final index = atoms.isEmpty
        ? 0
        : (instance.sequenceCursor -
                  (instance.lastRollCount ?? instance.settings.countMin)) %
              atoms.length;
    bool current() =>
        context.mounted &&
        bundle.members.every(
          (member) => identical(
            ref
                .read(pillWorkspaceProvider(member.scope))
                .document
                .instances[member.marker],
            member.instance,
          ),
        );
    void change(FutureOr<void> Function() action) => unawaited(
      _blockAction(context, () async {
        final write = ref
            .read(styleExploreBackendProvider)
            .captureDraft(alive: current);
        await write(action);
      }),
    );
    void each(
      void Function(
        PillWorkspaceNotifier notifier,
        String marker,
        PillInstance instance,
      )
      action,
    ) {
      if (!current()) return;
      for (final member in bundle.members) {
        action(
          ref.read(pillWorkspaceProvider(member.scope).notifier),
          member.marker,
          member.instance,
        );
      }
    }

    void rules(PillInstanceSettings rules) => each(
      (notifier, marker, instance) => notifier.updateInstanceSettings(
        marker,
        rules.copyWith(
          mode:
              bundle.isPaired &&
                  bundle.mask & (instance.useNegativeContent ? 2 : 1) == 0
              ? PillRollMode.fixed
              : rules.mode,
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: BlockInstanceCard(
        data: BlockInstanceViewData(
          block: styleExploreBlockData(
            block ??
                PromptBlock.create(
                  id: instance.blockId,
                  title: context.l10n.blocks_missing,
                  content: '',
                ),
            library,
          ),
          settings: styleExploreBlockRules(settings),
          locked: source.instance.locked,
          enabled: instance.enabled,
          drawn: styleExploreDrawn(send),
          send: send,
          skipped:
              instance.settings.hasRoll &&
              instance.currentRoll == '' &&
              instance.enabled,
          seqIndex: index,
          seqCount: instance.lastRollCount ?? instance.settings.countMin,
          prevText: atoms.isEmpty ? null : atoms[(index - 1) % atoms.length],
          nextText: atoms.isEmpty ? null : atoms[(index + 1) % atoms.length],
          side: block?.negativeContent.isNotEmpty == true
              ? bundle.mask == 3
                    ? BlockScopeSide.both
                    : bundle.mask == 2
                    ? BlockScopeSide.negative
                    : BlockScopeSide.positive
              : null,
          evolution: source.instance.evolutionEnabled,
          missing: block == null,
        ),
        actions: BlockInstanceActions(
          onReroll: () =>
              change(() => rollPromptBlockBundle(ref, PillScopes.main, marker)),
          onStep: (delta) => change(
            () => rollPromptBlockBundle(
              ref,
              PillScopes.main,
              marker,
              direction: delta,
            ),
          ),
          onLockChanged: (value) => change(
            () => each((notifier, marker, instance) {
              if (instance.locked != value) notifier.toggleLocked(marker);
            }),
          ),
          onEnabledChanged: (value) => change(
            () => each((notifier, marker, instance) {
              if (instance.enabled != value) notifier.toggleEnabled(marker);
            }),
          ),
          onEvolutionChanged: (value) => change(
            () => each((notifier, marker, instance) {
              if (instance.evolutionEnabled != value) {
                notifier.toggleEvolution(marker);
              }
            }),
          ),
          onModeChanged: (mode) => change(
            () => rules(
              settings.copyWith(mode: PillRollMode.values.byName(mode.name)),
            ),
          ),
          onSaveSettings: (value) =>
              change(() => rules(styleExplorePillRules(value))),
          onSideChanged: (side) => change(
            () => updatePromptBlockBundleScope(
              ref,
              PillScopes.main,
              marker,
              side == BlockScopeSide.both
                  ? 3
                  : side == BlockScopeSide.negative
                  ? 2
                  : 1,
            ),
          ),
          onRemove: () => change(() {
            removePromptBlockBundle(ref, PillScopes.main, marker);
            onDismiss();
          }),
          onEditBlock: () => unawaited(
            _blockAction(
              context,
              () => _editBlock(context, ref, instance.blockId),
            ),
          ),
          onApplyParams: () => change(() {
            if (block?.generationSettings != null) {
              applyPromptBlockGenerationSettings(
                ref,
                block!.generationSettings!,
              );
            }
          }),
          onShowInLibrary: () {
            onDismiss();
            context.go(
              AppRoutes.promptBlockLibrary,
              extra: PromptBlockLibraryLocation(instance.blockId),
            );
          },
          onCopySend: () => unawaited(
            _blockAction(
              context,
              () => Clipboard.setData(ClipboardData(text: send)),
            ),
          ),
          sample: (rules, times) {
            final rng = Random();
            var cursor = instance.sequenceCursor;
            final settings = styleExplorePillRules(rules);
            return List.generate(times.clamp(0, 100), (_) {
              if (settings.mode == PillRollMode.fixed) {
                return [for (final atom in atoms) BlockDrawn(atom)];
              }
              if (settings.mode == PillRollMode.sequential) {
                final result = PillRollEngine.rollInstanceSequential(
                  settings: settings,
                  atoms: atoms,
                  cursor: cursor,
                  rng: rng,
                );
                cursor = result.$2;
                return styleExploreDrawn(result.$1);
              }
              return styleExploreDrawn(
                PillRollEngine.rollInstance(
                  settings: settings,
                  atoms: atoms,
                  rng: rng,
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

class StyleExploreBlocksDockWiring extends ConsumerStatefulWidget {
  const StyleExploreBlocksDockWiring({super.key});
  @override
  ConsumerState<StyleExploreBlocksDockWiring> createState() =>
      _StyleExploreBlocksDockWiringState();
}

class _StyleExploreBlocksDockWiringState
    extends ConsumerState<StyleExploreBlocksDockWiring> {
  String _query = '';
  var _filter = const BlocksDockFilter.all();

  Future<void> _insert(String id) async {
    await insertStyleExploreBlock(context, ref, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promptBlockLibraryNotifierProvider);
    final library =
        state.valueOrNull ?? PromptBlockLibraryState(blocks: [], folders: []);
    final prefs =
        ref.watch(blocksPreferencesProvider).valueOrNull ??
        const BlocksPreferences();
    final scope = _filter.folderId;
    final folders = scope == null
        ? library.folders
        : [
            if (library.folderById(scope) case final folder?) folder,
            ...library.folders.where(
              (folder) =>
                  library.folders.getDescendantIds(scope).contains(folder.id),
            ),
          ];
    final groups = [
      for (final folder in folders)
        BlocksDockGroup(
          id: folder.id,
          name: folder.name,
          count: library.blocksInFolder(folder.id).length,
          blocks: library
              .blocksInFolder(folder.id)
              .map((block) => styleExploreBlockData(block, library))
              .toList(),
          expanded: !prefs.collapsed.contains(folder.id),
        ),
      if (scope == null)
        BlocksDockGroup(
          id: '',
          name: context.l10n.blocks_uncategorized,
          count: library.blocksInFolder(null).length,
          blocks: library
              .blocksInFolder(null)
              .map((block) => styleExploreBlockData(block, library))
              .toList(),
          expanded: !prefs.collapsed.contains(''),
        ),
    ];
    final results = library.blocks
        .where(
          (block) => '${block.title} ${block.content} ${block.negativeContent}'
              .toLowerCase()
              .replaceAll('_', ' ')
              .contains(_query.toLowerCase().replaceAll('_', ' ')),
        )
        .map((block) => styleExploreBlockData(block, library))
        .toList();
    return Material(
      type: MaterialType.transparency,
      child: BlocksDock(
        data: BlocksDockViewData(
          total: library.blocks.length,
          loading: state.isLoading,
          query: _query,
          filter: _filter,
          chips: [
            for (final folder in library.foldersIn(null))
              BlocksDockChip(
                id: folder.id,
                name: folder.name,
                count: library.blocksInFolderTree(folder.id).length,
              ),
          ],
          favorites: library.favoriteBlocks
              .map((block) => styleExploreBlockData(block, library))
              .toList(),
          recent: [
            for (final id in prefs.recentIds)
              if (library.blockById(id) case final block?)
                styleExploreBlockData(block, library),
          ],
          groups: groups,
          results: results,
        ),
        actions: BlocksDockActions(
          onQueryChanged: (value) => setState(() => _query = value),
          onFilterChanged: (value) => setState(() => _filter = value),
          onInsert: (id) => unawaited(_blockAction(context, () => _insert(id))),
          dragDataOf: (id) => PromptBlockDragData(blockId: id),
          onCreate: () => unawaited(
            _blockAction(context, () => _editBlock(context, ref, null)),
          ),
          onEdit: (id) => unawaited(
            _blockAction(context, () => _editBlock(context, ref, id)),
          ),
          onOpenLibrary: () => context.go(AppRoutes.promptBlockLibrary),
          onShowInLibrary: (id) => context.go(
            AppRoutes.promptBlockLibrary,
            extra: PromptBlockLibraryLocation(id),
          ),
          onClose: () => unawaited(
            _blockAction(
              context,
              () => ref
                  .read(layoutStateNotifierProvider.notifier)
                  .setBlockLibraryPanelExpanded(false),
            ),
          ),
          onToggleGroup: (id, expanded) => unawaited(
            _blockAction(
              context,
              () => ref
                  .read(blocksPreferencesProvider.notifier)
                  .change(
                    (prefs) => prefs.copyWith(
                      collapsed: expanded
                          ? (Set.of(prefs.collapsed)..remove(id))
                          : {...prefs.collapsed, id},
                    ),
                  ),
            ),
          ),
          onSetFavorite: (id, value) => unawaited(
            _blockAction(context, () async {
              await ref
                  .read(promptBlockLibraryNotifierProvider.notifier)
                  .setBlockFavorite(id, value);
            }),
          ),
          onAddToPalette: (id) => unawaited(
            _blockAction(
              context,
              () => ref
                  .read(promptBlockPaletteNotifierProvider.notifier)
                  .addBlock(id),
            ),
          ),
        ),
      ),
    );
  }
}
