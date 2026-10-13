import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/vibe_library_storage_service.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../providers/image_generation_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../providers/vibe_library_category_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../ui/refs/refs_contract.dart';
import '../ui/refs/refs_picker.dart';
import 'refs_library_wiring.dart';
import 'refs_generation_target.dart';
import 'refs_mapping.dart';
import 'refs_platform.dart';

class RefsPickerSelection {
  const RefsPickerSelection(this.keys, {required this.replace});
  final List<String> keys;
  final bool replace;
}

class RefsPickerWiring extends ConsumerStatefulWidget {
  const RefsPickerWiring({super.key, required this.kind, this.single = false});
  final RefsKind kind;
  final bool single;

  static Future<RefsPickerSelection?> show(
    BuildContext context, {
    required RefsKind kind,
    bool single = false,
  }) => showDialog<RefsPickerSelection>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: RefsPickerWiring(kind: kind, single: single),
    ),
  );

  @override
  ConsumerState<RefsPickerWiring> createState() => _RefsPickerWiringState();
}

class _RefsPickerWiringState extends ConsumerState<RefsPickerWiring> {
  bool _closed = false;
  bool get _vibe => widget.kind == RefsKind.vibe;

  bool _close([RefsPickerSelection? selection]) {
    if (_closed || !mounted || ModalRoute.of(context)?.isCurrent == false) {
      return false;
    }
    _closed = true;
    Navigator.of(context).pop(selection);
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        (_vibe
                ? ref.read(vibeLibraryNotifierProvider.notifier).initialize()
                : ref
                      .read(preciseRefLibraryNotifierProvider.notifier)
                      .initialize())
            .catchError((Object error) {
              if (mounted) ref.read(refsPlatformProvider).error(context, error);
            }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(generationParamsNotifierProvider);
    final statuses = _vibe
        ? ref.watch(refsVibeStatusesProvider).valueOrNull ??
              <String, RefsVibeStatus>{}
        : <String, RefsVibeStatus>{};
    final tray = ref
        .read(refsGenerationTargetProvider)
        .tray(widget.kind, statuses: statuses);
    final used = tray.items.map((e) => e.entryKey).whereType<String>().toSet();
    final List<RefsEntry> entries;
    List<RefsCategory> categories = const [];
    if (_vibe) {
      final state = ref.watch(vibeLibraryNotifierProvider);
      final storage = ref.watch(vibeLibraryStorageServiceProvider);
      entries = [
        for (final entry in state.entries)
          mapVibeEntry(
            entry,
            model: params.model,
            status: statuses[entry.id],
            thumb: RefsLazyImage(
              storage,
              entry.id,
              storage.getDisplayThumbnailRevision(entry.id),
              () => storage.getDisplayThumbnail(entry.id),
            ),
            inGeneration: used.contains(entry.id),
          ),
      ];
      categories = refsCategories(
        ref.watch(vibeLibraryCategoryNotifierProvider).categories,
        entries,
      );
    } else {
      final state = ref.watch(preciseRefLibraryNotifierProvider);
      final storage = ref.watch(preciseRefLibraryStorageServiceProvider);
      entries = [
        for (final entry in state.entries)
          mapPreciseEntry(
            entry,
            thumb: RefsLazyImage(
              storage,
              entry.id,
              entry.hashCode,
              () => storage.getDisplayThumbnail(entry.id),
            ),
            inGeneration: used.contains(entry.id),
          ),
      ];
    }
    final sorted = filterRefsEntries(entries, const RefsFilter());
    void close() => _close();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: RefsPicker(
        data: RefsPickerData(
          kind: widget.kind,
          now: DateTime.now(),
          model: refsModel(params.model),
          costs: refsCosts(),
          entries: sorted,
          categories: categories,
          recent: sorted
              .where((e) => e.lastUsed != null)
              .take(7)
              .map((e) => e.key)
              .toList(),
          inUse: tray.items.length,
          single: widget.single,
        ),
        actions: RefsPickerActions(
          onConfirm: (keys, {required replace}) =>
              _close(RefsPickerSelection(keys, replace: replace)),
          onClose: close,
          onOpenLibrary: () {
            final platform = ref.read(refsPlatformProvider);
            final navigationContext = Navigator.of(context).context;
            if (_close()) platform.library(navigationContext, widget.kind);
          },
        ),
      ),
    );
  }
}
