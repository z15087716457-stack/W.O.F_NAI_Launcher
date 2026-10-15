import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/rag/rag_settings.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/rag_provider.dart';
import '../../../providers/rag_model_download_provider.dart';
import '../widgets/settings_tile.dart';

/// Uses the existing settings rows; no locked page shell or golden is changed.
class RagSettingsSection extends ConsumerStatefulWidget {
  const RagSettingsSection({super.key});
  @override
  ConsumerState<RagSettingsSection> createState() => _RagSettingsSectionState();
}

class _RagSettingsSectionState extends ConsumerState<RagSettingsSection> {
  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.rag_operationFailed)),
        );
      }
    }
  }

  Future<void> _pick(String kind) async {
    String? path;
    if (kind == 'python') {
      path = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe'],
      ))?.files.single.path;
    } else {
      path = await FilePicker.platform.getDirectoryPath();
    }
    if (path == null || !mounted) return;
    final settings = ref.read(ragSettingsProvider);
    await ref.read(ragSettingsProvider.notifier).update(switch (kind) {
      'python' => settings.copyWith(python: path),
      'embedding' => settings.copyWith(embedding: path),
      _ => settings.copyWith(reranker: path),
    });
  }

  Future<void> _discover() async {
    for (final start in [
      Directory.current.path,
      p.dirname(Platform.resolvedExecutable),
    ]) {
      var cursor = start;
      for (var depth = 0; depth < 9; depth++) {
        final base = p.join(cursor, '04_工具', 'models');
        final embedding = p.join(base, 'embeddinggemma-2'),
            reranker = p.join(base, 'Qwen3-Reranker-0.6B');
        if (await File(p.join(embedding, 'model.safetensors')).exists() &&
            await File(p.join(reranker, 'model.safetensors')).exists()) {
          if (!mounted) return;
          await ref
              .read(ragSettingsProvider.notifier)
              .update(
                ref
                    .read(ragSettingsProvider)
                    .copyWith(embedding: embedding, reranker: reranker),
              );
          return;
        }
        final parent = p.dirname(cursor);
        if (parent == cursor) break;
        cursor = parent;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.rag_modelsMissing)));
    }
  }

  Future<void> _install() async {
    final l = context.l10n;
    final cuda = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.rag_installRuntime),
        content: Text(l.rag_installHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(l.common_cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CPU'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('CUDA / NVIDIA'),
          ),
        ],
      ),
    );
    if (cuda != null && mounted) {
      await ref.read(ragControllerProvider.notifier).installRuntime(cuda: cuda);
    }
  }

  Future<void> _preview({
    bool rebuild = false,
    RagSource source = RagSource.tags,
  }) async {
    final controller = ref.read(ragControllerProvider.notifier);
    final plan = await controller.preview(source: source);
    final roots = source == RagSource.gallery
        ? await ref.read(ragGalleryRootsProvider)()
        : const <String>[];
    if (!mounted) return;
    final l = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(rebuild ? l.rag_rebuild : l.rag_buildIndex),
        content: source == RagSource.gallery
            ? SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.rag_galleryPlan(
                          (plan['images'] as num).toInt(),
                          (plan['parameter_chunks'] as num).toInt(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final root in roots) Text(root, softWrap: true),
                    ],
                  ),
                ),
              )
            : Text(
                source == RagSource.tags
                    ? l.rag_plan((plan['total'] as num).toInt())
                    : l.rag_textPlan(
                        (plan['documents'] as num).toInt(),
                        (plan['total'] as num).toInt(),
                      ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.rag_start),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await controller.start(
        plan['plan_id'] as String,
        rebuild: rebuild,
        source: source,
      );
    }
  }

  Future<void> _clearSource(RagSource source) async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.rag_clear),
        content: Text(l.rag_clearHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.rag_clear),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await ref.read(ragControllerProvider.notifier).clear(source: source);
    }
  }

  Widget _textSource(RagSource source) {
    final l = context.l10n,
        settings = ref.watch(ragSettingsProvider),
        all = ref.watch(ragControllerProvider);
    final status = all.forSource(source),
        controller = ref.read(ragControllerProvider.notifier);
    final wiki = source == RagSource.wiki;
    final gallery = source == RagSource.gallery;
    final enabled = gallery
        ? settings.galleryEnabled
        : wiki
        ? settings.wikiEnabled
        : settings.blocksEnabled;
    final available = settings.enabled && enabled;
    final locked = status.busy || all.installPhase != null;
    final phase = switch (status.phase) {
      'off' => l.rag_off,
      'empty' => l.rag_empty,
      'loading' => l.rag_loading,
      'paused' => l.rag_paused,
      'building' => l.rag_building,
      'partial' => l.rag_partial,
      'ready' => l.rag_ready,
      _ => l.rag_unavailable,
    };
    return Column(
      key: Key('rag-${source.name}-index'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSwitchTile(
          key: Key('rag-${source.name}-enable'),
          title: Text(
            gallery
                ? l.rag_galleryEnabled
                : wiki
                ? l.rag_wikiEnabled
                : l.rag_blocksEnabled,
          ),
          subtitle: Text(
            gallery
                ? l.rag_galleryHint
                : wiki
                ? l.rag_wikiHint
                : l.rag_blocksHint,
          ),
          value: enabled,
          onChanged: all.installPhase != null
              ? null
              : (v) => _action(
                  () => ref
                      .read(ragSettingsProvider.notifier)
                      .update(
                        gallery
                            ? ref
                                  .read(ragSettingsProvider)
                                  .copyWith(galleryEnabled: v)
                            : wiki
                            ? ref
                                  .read(ragSettingsProvider)
                                  .copyWith(wikiEnabled: v)
                            : ref
                                  .read(ragSettingsProvider)
                                  .copyWith(blocksEnabled: v),
                      ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase),
              Text(
                gallery
                    ? l.rag_galleryCounts(
                        status.details['visual_indexed'] ?? 0,
                        status.details['images'] ?? 0,
                        status.details['parameters_indexed'] ?? 0,
                        status.details['skipped'] ?? 0,
                      )
                    : l.rag_textCounts(status.indexed, status.total),
              ),
              if (status.bytes > 0)
                Text(
                  l.rag_storage((status.bytes / 1048576).toStringAsFixed(1)),
                ),
              if (status.error != null)
                Text('${l.rag_operationFailed} (${status.error})'),
              if (status.busy)
                LinearProgressIndicator(
                  value: status.total > 0
                      ? (status.processed / status.total).clamp(0.0, 1.0)
                      : null,
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              key: Key('rag-${source.name}-preview'),
              onPressed: available && !locked && status.jobId == null
                  ? () => _action(() => _preview(source: source))
                  : null,
              child: Text(l.rag_buildIndex),
            ),
            if (available && (status.jobId != null || status.phase == 'paused'))
              OutlinedButton(
                onPressed: () => _action(
                  () => status.phase == 'paused'
                      ? controller.resume(source: source)
                      : controller.pause(source: source),
                ),
                child: Text(
                  status.phase == 'paused' ? l.rag_resume : l.rag_pause,
                ),
              ),
            OutlinedButton(
              onPressed: available && !locked && status.jobId == null
                  ? () => _action(() => _preview(source: source, rebuild: true))
                  : null,
              child: Text(l.rag_rebuild),
            ),
            TextButton(
              onPressed: available && !locked
                  ? () => _action(() => _clearSource(source))
                  : null,
              child: Text(l.rag_clear),
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n,
        settings = ref.watch(ragSettingsProvider),
        status = ref.watch(ragControllerProvider);
    final controller = ref.read(ragControllerProvider.notifier);
    final available = settings.enabled && settings.tagsEnabled;
    final installing = status.installPhase != null;
    final download = ref.watch(ragModelDownloadProvider);
    final runtime = installing ? null : ref.watch(ragRuntimeInfoProvider);
    final runtimeInfo = runtime?.valueOrNull;
    final locked = status.anyBusy || installing || download.active;
    Widget path(String title, String value, String kind) => SettingsTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.isEmpty ? l.rag_notConfigured : value),
          if (download.kind == kind) ...[
            Text(
              download.progress?.checking == true
                  ? l.rag_modelVerifying
                  : l.rag_modelDownloading,
            ),
            if (download.progress case final progress?) ...[
              Text(
                l.rag_downloadProgress(
                  (progress.received / 1048576).toStringAsFixed(1),
                  (progress.total / 1048576).toStringAsFixed(1),
                ),
              ),
              LinearProgressIndicator(value: progress.fraction),
            ],
          ],
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton(
            onPressed: locked ? null : () => _action(() => _pick(kind)),
            child: Text(l.rag_choose),
          ),
          if (kind != 'python')
            TextButton(
              key: Key('rag-download-$kind'),
              onPressed: download.kind == kind
                  ? ref.read(ragModelDownloadProvider.notifier).cancel
                  : locked
                  ? null
                  : () => ref
                        .read(ragModelDownloadProvider.notifier)
                        .download(kind),
              child: Text(
                download.kind == kind ? l.common_cancel : l.rag_downloadModel,
              ),
            ),
        ],
      ),
    );
    final enabled = [
      for (final source in RagSource.values)
        if (settings.enabledFor(source)) status.forSource(source),
    ];
    final poolIndexed = enabled.fold<int>(0, (n, s) => n + s.indexed);
    final poolTotal = enabled.fold<int>(0, (n, s) => n + s.total);
    final poolBytes = enabled.fold<int>(0, (n, s) => n + s.bytes);
    final poolPhase = enabled.isEmpty
        ? 'off'
        : enabled.any((s) => s.busy)
        ? 'building'
        : enabled.any((s) => s.error != null)
        ? 'error'
        : enabled.any((s) => s.phase == 'loading')
        ? 'loading'
        : poolIndexed == 0
        ? 'empty'
        : enabled.every((s) => s.complete)
        ? 'ready'
        : 'partial';
    final phase = switch (poolPhase) {
      'off' => l.rag_off,
      'loading' => l.rag_loading,
      'empty' => l.rag_empty,
      'ready' => l.rag_ready,
      'partial' => l.rag_partial,
      'building' => l.rag_building,
      'paused' => l.rag_paused,
      _ => l.rag_unavailable,
    };
    final installPhase = switch (status.installPhase) {
      'existing' => l.rag_runtimeExisting,
      'download' => l.rag_runtimeDownload,
      'create' => l.rag_runtimeCreate,
      'cuda' => l.rag_runtimeCuda,
      'packages' => l.rag_runtimePackages,
      'check' => l.rag_runtimeVerify,
      _ => l.rag_installing,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSwitchTile(
          key: const Key('rag-enable'),
          title: Text(l.rag_enabled),
          subtitle: Text(l.rag_enabledHint),
          value: settings.enabled,
          onChanged: installing
              ? null
              : (v) => _action(
                  () => ref
                      .read(ragSettingsProvider.notifier)
                      .update(settings.copyWith(enabled: v)),
                ),
        ),
        SettingsTile(
          title: Text(l.rag_status),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phase),
              Text(l.rag_poolHint),
              Text(l.rag_indexCounts(poolIndexed, poolTotal)),
              if (poolBytes > 0)
                Text(l.rag_storage((poolBytes / 1048576).toStringAsFixed(1))),
              if (status.error != null)
                Text('${l.rag_operationFailed} (${status.error})'),
              if (download.error != null)
                Text('${l.rag_operationFailed} (${download.error})'),
              if (status.error != null && status.installDetail.isNotEmpty)
                Text(
                  status.installDetail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: IconButton(
            onPressed: enabled.isNotEmpty && !locked
                ? () => controller.refresh()
                : null,
            icon: const Icon(Icons.refresh),
            tooltip: l.rag_refresh,
          ),
        ),
        if (status.busy)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(
              value: status.total > 0
                  ? (status.processed / status.total).clamp(0.0, 1.0)
                  : null,
            ),
          ),
        path(l.rag_embeddingPath, settings.embedding, 'embedding'),
        path(l.rag_rerankerPath, settings.reranker, 'reranker'),
        SettingsTile(
          title: Text(l.rag_modelMode),
          subtitle: Text(l.rag_modelModeHint),
          trailing: OutlinedButton(
            onPressed: locked ? null : () => _action(_discover),
            child: Text(l.rag_discover),
          ),
        ),
        path(
          l.rag_pythonPath,
          settings.python.isEmpty && runtimeInfo?.ready == true
              ? runtimeInfo!.python
              : settings.python,
          'python',
        ),
        SettingsTile(
          title: Text(l.rag_runtime),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                installing
                    ? installPhase
                    : runtimeInfo?.ready == true
                    ? l.rag_runtimeReady
                    : runtime?.isLoading == true
                    ? l.rag_runtimeExisting
                    : l.rag_runtimeHint,
              ),
              if (installing) ...[
                Text(l.rag_runtimeElapsed(status.installElapsed)),
                const LinearProgressIndicator(),
                if (status.installDetail.isNotEmpty)
                  Text(
                    status.installDetail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ],
          ),
          trailing: installing
              ? TextButton(
                  onPressed: controller.cancelInstall,
                  child: Text(l.common_cancel),
                )
              : runtimeInfo?.ready == true
              ? Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (settings.python.isNotEmpty &&
                        settings.python != runtimeInfo!.python)
                      TextButton(
                        onPressed: locked
                            ? null
                            : () => controller.installRuntime(
                                cuda: runtimeInfo.cuda,
                              ),
                        child: Text(l.rag_useRuntime),
                      )
                    else
                      Text(l.rag_runtimeReady),
                    IconButton(
                      onPressed: locked
                          ? null
                          : () => ref.invalidate(ragRuntimeInfoProvider),
                      tooltip: l.rag_runtimeCheck,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                )
              : OutlinedButton(
                  onPressed: locked || runtime?.isLoading == true
                      ? null
                      : () => _action(_install),
                  child: Text(l.rag_installRuntime),
                ),
        ),
        SettingsTile(
          title: Text(l.rag_device),
          trailing: DropdownButton<RagDevice>(
            value: settings.device,
            onChanged: locked
                ? null
                : (v) {
                    if (v != null) {
                      _action(
                        () => ref
                            .read(ragSettingsProvider.notifier)
                            .update(settings.copyWith(device: v)),
                      );
                    }
                  },
            items: [
              DropdownMenuItem(value: RagDevice.auto, child: Text(l.rag_auto)),
              const DropdownMenuItem(value: RagDevice.cpu, child: Text('CPU')),
              const DropdownMenuItem(
                value: RagDevice.cuda,
                child: Text('CUDA / NVIDIA'),
              ),
            ],
          ),
        ),
        SettingsSwitchTile(
          title: Text(l.rag_tagsEnabled),
          subtitle: Text(l.rag_tagsHint),
          value: settings.tagsEnabled,
          onChanged: installing
              ? null
              : (v) => _action(
                  () => ref
                      .read(ragSettingsProvider.notifier)
                      .update(settings.copyWith(tagsEnabled: v)),
                ),
        ),
        SettingsTile(
          title: Text(l.rag_context),
          subtitle: Text(l.rag_contextHint),
          trailing: DropdownButton<RagContextMode>(
            value: settings.mode,
            onChanged: (v) {
              if (v != null) {
                _action(
                  () => ref
                      .read(ragSettingsProvider.notifier)
                      .update(settings.copyWith(mode: v)),
                );
              }
            },
            items: [
              DropdownMenuItem(
                value: RagContextMode.before,
                child: Text(l.rag_contextBefore),
              ),
              DropdownMenuItem(
                value: RagContextMode.around,
                child: Text(l.rag_contextAround),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: available && !locked && status.jobId == null
                    ? () => _action(() => _preview())
                    : null,
                child: Text(l.rag_buildIndex),
              ),
              if (available &&
                  (status.jobId != null || status.phase == 'paused'))
                OutlinedButton(
                  onPressed: () => _action(
                    status.phase == 'paused'
                        ? controller.resume
                        : controller.pause,
                  ),
                  child: Text(
                    status.phase == 'paused' ? l.rag_resume : l.rag_pause,
                  ),
                ),
              OutlinedButton(
                onPressed: available && !locked && status.jobId == null
                    ? () => _action(() => _preview(rebuild: true))
                    : null,
                child: Text(l.rag_rebuild),
              ),
              TextButton(
                onPressed: available && !locked
                    ? () => _action(() async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(l.rag_clear),
                            content: Text(l.rag_clearHint),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(l.common_cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(l.rag_clear),
                              ),
                            ],
                          ),
                        );
                        if (yes == true) await controller.clear();
                      })
                    : null,
                child: Text(l.rag_clear),
              ),
            ],
          ),
        ),
        _textSource(RagSource.wiki),
        _textSource(RagSource.blocks),
        _textSource(RagSource.gallery),
        Text(l.rag_futureSources, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
