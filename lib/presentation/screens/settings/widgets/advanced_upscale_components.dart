import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/upscale/local_upscale_models.dart';
import '../../../providers/generation/local_upscale_provider.dart';
import 'local_upscale_brand_logo.dart';

/// Component management keeps its viewed model separate from generation settings.
class AdvancedUpscaleComponents extends ConsumerStatefulWidget {
  const AdvancedUpscaleComponents({super.key, required this.blocked});
  final bool blocked;

  @override
  ConsumerState<AdvancedUpscaleComponents> createState() =>
      _AdvancedUpscaleComponentsState();
}

class _AdvancedUpscaleComponentsState
    extends ConsumerState<AdvancedUpscaleComponents> {
  String _seedvr2Model = 'seedvr2-3b';

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(localUpscaleModelsProvider).valueOrNull ?? [];
    final install = ref.watch(advancedUpscaleInstallProvider);
    final blocked = widget.blocked || install.running;
    final available = [
      for (final catalog in advancedUpscaleCatalog)
        models.where((model) => model.id == catalog.id).firstOrNull ?? catalog,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _seedvr2Card(
          context,
          available
              .where((m) => m.method == LocalUpscaleMethod.seedvr2)
              .toList(),
          install,
          blocked,
        ),
        for (final model in available.where(
          (m) => m.method != LocalUpscaleMethod.seedvr2,
        ))
          _componentCard(context, model, install, blocked),
      ],
    );
  }

  Widget _seedvr2Card(
    BuildContext context,
    List<LocalUpscaleModel> variants,
    AdvancedUpscaleInstallState install,
    bool blocked,
  ) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final selected = variants.firstWhere((model) => model.id == _seedvr2Model);
    return Card(
      key: const ValueKey('seedvr2-family-card'),
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LocalUpscaleBrandLogo(
                            method: LocalUpscaleMethod.seedvr2,
                          ),
                          const SizedBox(width: 8),
                          Text('SeedVR2', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      SizedBox(
                        width: constraints.maxWidth < 360 ? 150 : 190,
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('seedvr2-management-model'),
                          initialValue: selected.id,
                          isExpanded: true,
                          style: theme.textTheme.bodySmall,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final model in variants)
                              DropdownMenuItem(
                                value: model.id,
                                child: Text(
                                  '${model.name.replaceFirst('SeedVR2 ', '')} · ${model.installed ? l.localUpscale_installed : l.localUpscale_notInstalledShort}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: blocked
                              ? null
                              : (id) {
                                  if (id != null) {
                                    setState(() => _seedvr2Model = id);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  selected.id == 'seedvr2-7b-sharp'
                      ? l.localUpscale_seedvr2SharpSummary
                      : selected.isSeedvr2Seven
                      ? l.localUpscale_seedvr2SevenSummary
                      : l.localUpscale_seedvr2ThreeSummary,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${l.localUpscale_modelWeights} ≈ ${selected.isSeedvr2Seven ? '8.2' : '3.4'} GB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _componentActions(context, selected, blocked),
                _installProgress(context, selected, install),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.localUpscale_seedvr2SharedHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _licenseButton(context, selected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentCard(
    BuildContext context,
    LocalUpscaleModel model,
    AdvancedUpscaleInstallState install,
    bool blocked,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LocalUpscaleBrandLogo(method: model.method),
                const SizedBox(width: 12),
                Expanded(child: Text('RTX', style: theme.textTheme.titleSmall)),
                if (model.installed)
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.localUpscale_rtxHelp,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _componentActions(context, model, blocked, license: true),
            _installProgress(context, model, install),
          ],
        ),
      ),
    );
  }

  Widget _licenseButton(
    BuildContext context,
    LocalUpscaleModel model,
  ) => TextButton(
    onPressed: () => launchUrl(
      Uri.parse(
        model.method == LocalUpscaleMethod.seedvr2
            ? 'https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler/blob/4490bd1f482e026674543386bb2a4d176da245b9/LICENSE'
            : 'https://developer.nvidia.com/rtx-video-sdk',
      ),
      mode: LaunchMode.externalApplication,
    ),
    child: Text(context.l10n.localUpscale_license),
  );

  Widget _componentActions(
    BuildContext context,
    LocalUpscaleModel model,
    bool blocked, {
    bool license = false,
  }) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: [
        if (model.installed) ...[
          if (model.method == LocalUpscaleMethod.seedvr2) ...[
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              '${l.localUpscale_installed} · ${(model.diskBytes / 1024 / 1024).round()} MB',
              style: theme.textTheme.labelMedium,
            ),
          ),
        ] else
          Expanded(
            child: Text(
              l.localUpscale_notInstalledShort,
              style: theme.textTheme.labelMedium,
            ),
          ),
        if (license) _licenseButton(context, model),
        if (model.installed)
          IconButton(
            key: ValueKey('upscale-management-delete-${model.id}'),
            onPressed: blocked
                ? null
                : () => ref
                      .read(advancedUpscaleInstallProvider.notifier)
                      .delete(model.id),
            tooltip: l.common_delete,
            icon: const Icon(Icons.delete_outline),
          )
        else
          TextButton(
            key: ValueKey('upscale-management-install-${model.id}'),
            onPressed: blocked || !Platform.isWindows
                ? null
                : () => ref
                      .read(advancedUpscaleInstallProvider.notifier)
                      .install(model.id),
            child: Text(
              model.method == LocalUpscaleMethod.seedvr2
                  ? l.localUpscale_download
                  : l.localUpscale_installComponent,
            ),
          ),
      ],
    );
  }

  Widget _installProgress(
    BuildContext context,
    LocalUpscaleModel model,
    AdvancedUpscaleInstallState install,
  ) {
    if (install.id != model.id) return const SizedBox.shrink();
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: install.cancelling ? null : install.fraction,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                install.cancelling
                    ? l.localUpscale_cancelling
                    : switch (install.phase) {
                        'python' => l.localUpscale_installingPython,
                        'runtime' => l.localUpscale_installingRuntime,
                        'weights' => l.localUpscale_downloadProgress,
                        'checking' => l.localUpscale_checkingComponent,
                        _ => l.localUpscale_installingComponent,
                      },
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: install.cancelling
                  ? null
                  : ref.read(advancedUpscaleInstallProvider.notifier).cancel,
              child: Text(l.common_cancel),
            ),
          ],
        ),
      ],
    );
  }
}
