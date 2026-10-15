import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_instance.dart';
import '../utils/prompt_block_instance_bundle.dart';
import 'blocks_actions.dart';
import 'blocks_generation_target.dart';
import 'blocks_mapping.dart';

List<BlockDrawn> blockDrawnOf(String text) => [
  for (final atom in PillRollEngine.splitTopLevelAtoms(text))
    if (RegExp(r'^([-+]?\d+(?:\.\d+)?)::([\s\S]*)::$').firstMatch(atom)
        case final match?)
      BlockDrawn(match.group(2)!.trim(), double.parse(match.group(1)!))
    else
      BlockDrawn(atom),
];

class BlockInstanceWiring extends ConsumerWidget {
  const BlockInstanceWiring({
    super.key,
    required this.scope,
    required this.marker,
    required this.onDismiss,
    this.allowEvolutionToggle = false,
  });
  final String scope;
  final String marker;
  final VoidCallback onDismiss;
  final bool allowEvolutionToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(pillWorkspaceProvider(scope));
    final instance = workspace.document.instances[marker];
    final library =
        ref.watch(promptBlockLibraryNotifierProvider).valueOrNull ??
        PromptBlockLibraryState(blocks: const [], folders: const []);
    if (instance == null) return const SizedBox.shrink();
    final bundle = readPromptBlockInstanceBundle(ref, scope, marker);
    for (final member in bundle.members) {
      ref.watch(pillWorkspaceProvider(member.scope));
    }
    final block = library.blockById(instance.blockId);
    final source = bundle.members.firstWhere(
      (m) => m.instance.settings.hasRoll,
      orElse: () => BundleMember(scope, marker, instance),
    );
    final settings = source.instance.settings;
    final atoms = instance.useNegativeContent
        ? block?.negativeAtomsOrSplit ?? <String>[]
        : block?.atomsOrSplit ?? <String>[];
    final send = !instance.enabled || block == null
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
    final host = BlocksActions(ref, context, () => context.mounted);
    final updates = [
      for (final member in bundle.members)
        (
          ref.read(pillWorkspaceProvider(member.scope).notifier),
          member.marker,
          member.instance,
          member.scope,
        ),
    ];
    bool current() =>
        context.mounted &&
        updates.every(
          (entry) => identical(
            ref
                .read(pillWorkspaceProvider(entry.$4))
                .document
                .instances[entry.$2],
            entry.$3,
          ),
        );
    void each(
      void Function(PillWorkspaceNotifier, String, PillInstance) action,
    ) {
      if (!current()) return;
      for (final entry in updates) {
        action(entry.$1, entry.$2, entry.$3);
      }
    }

    final missing = PromptBlock.create(
      id: instance.blockId,
      title: context.l10n.blocks_missing,
      content: '',
    );
    return Material(
      type: MaterialType.transparency,
      child: BlockInstanceCard(
        data: BlockInstanceViewData(
          block: blockDataOf(block ?? missing, library),
          settings: toBlockRollSettings(settings),
          locked: source.instance.locked,
          enabled: instance.enabled,
          drawn: blockDrawnOf(send),
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
              ? (bundle.mask == 3
                    ? BlockScopeSide.both
                    : bundle.mask == 2
                    ? BlockScopeSide.negative
                    : BlockScopeSide.positive)
              : null,
          evolution: allowEvolutionToggle
              ? source.instance.evolutionEnabled
              : null,
          missing: block == null,
          catalog: blocksParamCatalog,
        ),
        actions: BlockInstanceActions(
          onReroll: () {
            if (current()) rollPromptBlockBundle(ref, scope, marker);
          },
          onStep: (delta) {
            if (current()) {
              rollPromptBlockBundle(ref, scope, marker, direction: delta);
            }
          },
          onLockChanged: (value) => each((n, marker, i) {
            if (i.locked != value) n.toggleLocked(marker);
          }),
          onEnabledChanged: (value) => each((n, marker, i) {
            if (i.enabled != value) n.toggleEnabled(marker);
          }),
          onEvolutionChanged: !allowEvolutionToggle
              ? null
              : (value) {
                  if (!settings.hasRoll || !instance.enabled || !current()) {
                    return;
                  }
                  unawaited(
                    host.run(
                      () => ref
                          .read(blocksGenerationTargetProvider)
                          .commit(
                            () => each((n, marker, i) {
                              if (i.evolutionEnabled != value) {
                                n.toggleEvolution(marker);
                              }
                            }),
                            alive: () => context.mounted,
                            unchanged: current,
                          ),
                    ),
                  );
                },
          onModeChanged: (mode) => each(
            (n, marker, i) => n.updateInstanceSettings(
              marker,
              settings.copyWith(
                mode:
                    bundle.isPaired &&
                        bundle.mask & (i.useNegativeContent ? 2 : 1) == 0
                    ? PillRollMode.fixed
                    : PillRollMode.values.byName(mode.name),
              ),
            ),
          ),
          onSaveSettings: (value) => each(
            (n, marker, i) => n.updateInstanceSettings(
              marker,
              toPillSettings(value).copyWith(
                mode:
                    bundle.isPaired &&
                        bundle.mask & (i.useNegativeContent ? 2 : 1) == 0
                    ? PillRollMode.fixed
                    : PillRollMode.values.byName(value.mode.name),
              ),
            ),
          ),
          onSideChanged: (side) {
            if (current()) {
              updatePromptBlockBundleScope(
                ref,
                scope,
                marker,
                side == BlockScopeSide.both
                    ? 3
                    : side == BlockScopeSide.negative
                    ? 2
                    : 1,
              );
            }
          },
          onEditBlock: () {
            if (block != null) host.edit(id: block.id);
          },
          onRemove: () {
            if (current()) {
              removePromptBlockBundle(ref, scope, marker);
              onDismiss();
            }
          },
          onApplyParams: () {
            if (block != null) host.applyParams(block.id);
          },
          onShowInLibrary: () {
            onDismiss();
            host.showInLibrary(instance.blockId);
          },
          onCopySend: () =>
              host.run(() => Clipboard.setData(ClipboardData(text: send))),
          sample: (rules, times) {
            final rng = Random();
            var cursor = instance.sequenceCursor;
            return List.generate(times.clamp(0, 100), (_) {
              final s = toPillSettings(rules);
              if (s.mode == PillRollMode.fixed) {
                return [for (final atom in atoms) BlockDrawn(atom)];
              }
              if (s.mode == PillRollMode.sequential) {
                final result = PillRollEngine.rollInstanceSequential(
                  settings: s,
                  atoms: atoms,
                  cursor: cursor,
                  rng: rng,
                );
                cursor = result.$2;
                return blockDrawnOf(result.$1);
              }
              return blockDrawnOf(
                PillRollEngine.rollInstance(
                  settings: s,
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
