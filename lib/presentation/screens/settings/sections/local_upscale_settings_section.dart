import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/upscale/local_upscale_models.dart';
import '../../../providers/generation/local_upscale_provider.dart';
import '../widgets/advanced_upscale_components.dart';

String localUpscaleErrorText(BuildContext context, LocalUpscaleError error) {
  final l = context.l10n;
  return switch (error) {
    LocalUpscaleError.unsupportedPlatform => l.localUpscale_unsupportedPlatform,
    LocalUpscaleError.engineMissing => l.localUpscale_engineMissing,
    LocalUpscaleError.integrity => l.localUpscale_integrity,
    LocalUpscaleError.modelMissing => l.localUpscale_modelMissing,
    LocalUpscaleError.invalidModel => l.localUpscale_invalidModel,
    LocalUpscaleError.invalidImage => l.localUpscale_invalidImage,
    LocalUpscaleError.sizeLimit => l.localUpscale_sizeLimit,
    LocalUpscaleError.noVulkan => l.localUpscale_noVulkan,
    LocalUpscaleError.noCuda => l.localUpscale_noCuda,
    LocalUpscaleError.noInt8 => l.localUpscale_noInt8,
    LocalUpscaleError.noRtx => l.localUpscale_noRtx,
    LocalUpscaleError.outOfMemory => l.localUpscale_outOfMemory,
    LocalUpscaleError.processFailed => l.localUpscale_processFailed,
    LocalUpscaleError.modelOperationFailed =>
      l.localUpscale_modelOperationFailed,
    LocalUpscaleError.timeout => l.localUpscale_timeout,
    LocalUpscaleError.busy => l.localUpscale_busy,
    LocalUpscaleError.cancelled => l.localUpscale_cancelled,
  };
}

String localUpscaleModelName(BuildContext context, LocalUpscaleModel model) =>
    switch (model.id) {
      'anime' => context.l10n.localUpscale_anime,
      'anime-fast' => context.l10n.localUpscale_animeFast,
      'general' => context.l10n.localUpscale_general,
      _ => model.name,
    };

class LocalUpscaleSettingsSection extends ConsumerStatefulWidget {
  const LocalUpscaleSettingsSection({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<LocalUpscaleSettingsSection> createState() =>
      _LocalUpscaleSettingsSectionState();
}

class _LocalUpscaleSettingsSectionState
    extends ConsumerState<LocalUpscaleSettingsSection> {
  bool _busy = false;
  String? _active;
  double? _progress;
  LocalUpscaleError? _error;
  CancelToken? _download;
  @override
  void dispose() {
    _download?.cancel();
    super.dispose();
  }

  Future<void> _operate(Future<void> Function() work, {String? active}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _active = active;
      _progress = null;
      _error = null;
    });
    try {
      await work();
    } on LocalUpscaleException catch (error) {
      if (mounted) setState(() => _error = error.code);
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _error = CancelToken.isCancel(error)
              ? LocalUpscaleError.cancelled
              : LocalUpscaleError.modelOperationFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = LocalUpscaleError.modelOperationFailed);
      }
    } finally {
      _download = null;
      if (mounted) ref.invalidate(localUpscaleModelsProvider);
      if (mounted) {
        setState(() {
          _busy = false;
          _active = null;
        });
      }
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['param', 'bin'],
      allowMultiple: true,
    );
    if (!mounted || picked == null) return;
    final params = picked.files
        .where(
          (file) =>
              file.extension?.toLowerCase() == 'param' && file.path != null,
        )
        .toList();
    final weights = picked.files
        .where(
          (file) => file.extension?.toLowerCase() == 'bin' && file.path != null,
        )
        .toList();
    if (picked.files.length != 2 || params.length != 1 || weights.length != 1) {
      setState(() => _error = LocalUpscaleError.invalidModel);
      return;
    }
    await _operate(() async {
      await ref
          .read(localUpscaleModelManagerProvider)
          .importPair(File(params.single.path!), File(weights.single.path!));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final models = ref.watch(localUpscaleModelsProvider);
    final install = ref.watch(advancedUpscaleInstallProvider);
    final blocked =
        _busy || install.running || ref.watch(localUpscaleTaskProvider).running;
    return ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(24),
      children: [
        Text(l.localUpscale_description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text(l.img2img_upscaleRegularModel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...models.when(
          data: (items) => items
              .where((m) => m.method == LocalUpscaleMethod.standard)
              .map(
                (model) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          model.installed
                              ? Icons.check_circle_outline
                              : Icons.download_outlined,
                          size: 22,
                          color: model.installed
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localUpscaleModelName(context, model),
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                model.name,
                                style: theme.textTheme.bodySmall,
                              ),
                              if (model.bundled)
                                Text(
                                  l.localUpscale_bundled,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!model.installed)
                          TextButton(
                            onPressed: blocked
                                ? null
                                : () => _operate(() async {
                                    _download = CancelToken();
                                    await ref
                                        .read(localUpscaleModelManagerProvider)
                                        .download(
                                          model.id,
                                          cancelToken: _download,
                                          onProgress: (received, total) {
                                            if (mounted) {
                                              setState(
                                                () => _progress = total > 0
                                                    ? received / total
                                                    : null,
                                              );
                                            }
                                          },
                                        );
                                  }, active: model.id),
                            child: Text(l.localUpscale_download),
                          ),
                        if (model.installed && !model.bundled)
                          IconButton(
                            onPressed: blocked
                                ? null
                                : () => _operate(
                                    () => ref
                                        .read(localUpscaleModelManagerProvider)
                                        .delete(model.id),
                                  ),
                            tooltip: l.common_delete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          loading: () => [const LinearProgressIndicator()],
          error: (error, _) => [
            Text(
              localUpscaleErrorText(
                context,
                error is LocalUpscaleException
                    ? error.code
                    : LocalUpscaleError.processFailed,
              ),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            TextButton(
              onPressed: () => ref.invalidate(localUpscaleModelsProvider),
              child: Text(l.common_retry),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _progress),
          Row(
            children: [
              Expanded(
                child: Text(
                  _active != null
                      ? l.localUpscale_downloadProgress
                      : l.localUpscale_preparing,
                ),
              ),
              if (_download != null)
                TextButton(
                  onPressed: () => _download?.cancel(),
                  child: Text(l.common_cancel),
                ),
            ],
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              localUpscaleErrorText(context, _error!),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: blocked ? null : _import,
            icon: const Icon(Icons.file_upload_outlined, size: 18),
            label: Text(l.localUpscale_importModel),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.localUpscale_importHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          l.localUpscale_optionalComponents,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l.localUpscale_noAutomaticDownload,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        AdvancedUpscaleComponents(blocked: blocked),
        if (install.error != null) ...[
          Text(
            install.error == LocalUpscaleError.cancelled
                ? localUpscaleErrorText(context, install.error!)
                : l.localUpscale_installFailed(switch (install.phase) {
                    'python' => l.localUpscale_installingPython,
                    'runtime' => l.localUpscale_installingRuntime,
                    'weights' => l.localUpscale_downloadProgress,
                    'checking' => l.localUpscale_checkingComponent,
                    _ => l.localUpscale_installingComponent,
                  }),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          if (install.error != LocalUpscaleError.cancelled)
            Text(
              localUpscaleErrorText(context, install.error!),
              style: theme.textTheme.bodySmall,
            ),
          if (install.details?.isNotEmpty == true)
            SelectableText(
              install.details!,
              key: const ValueKey('advanced-upscale-install-diagnostics'),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ],
    );
  }
}
