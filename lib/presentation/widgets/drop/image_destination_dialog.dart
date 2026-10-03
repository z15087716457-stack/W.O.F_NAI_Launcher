import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/models/metadata/metadata_import_options.dart';
import '../../../data/models/vibe/vibe_reference.dart';
import '../common/studio_icons.dart';

enum ImageDestination {
  img2img,
  vibeTransfer,
  vibeTransferReuse,
  vibeTransferRaw,
  saveToVibeLibrary,
  characterReference,
  extractMetadata,
}

/// Selecting cards never mutates the workspace; only a confirmed result does.
class ImageDestinationResult {
  const ImageDestinationResult(this.destination, {this.selection});
  final ImageDestination destination;
  final OfficialMetadataImportSelection? selection;
}

/// Shared by dropped images and the gallery's metadata import action.
class ImageDestinationDialog extends StatefulWidget {
  const ImageDestinationDialog({
    super.key,
    required this.imageBytes,
    required this.fileName,
    this.metadata,
    this.detectedVibe,
    this.isBundle = false,
  });
  final Uint8List imageBytes;
  final String fileName;
  final NaiImageMetadata? metadata;
  final VibeReference? detectedVibe;
  final bool isBundle;

  static Future<ImageDestinationResult?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String fileName,
    NaiImageMetadata? metadata,
    VibeReference? detectedVibe,
    bool isBundle = false,
  }) => showDialog<ImageDestinationResult>(
    context: context,
    builder: (_) => ImageDestinationDialog(
      imageBytes: imageBytes,
      fileName: fileName,
      metadata: metadata,
      detectedVibe: detectedVibe,
      isBundle: isBundle,
    ),
  );

  @override
  State<ImageDestinationDialog> createState() => _ImageDestinationDialogState();
}

class _ImageDestinationDialogState extends State<ImageDestinationDialog> {
  late OfficialMetadataImportSelection _selection;
  @override
  void initState() {
    super.initState();
    final metadata = widget.metadata;
    _selection = OfficialMetadataImportSelection(
      importPrompt: metadata != null,
      importNegativePrompt: metadata?.negativePrompt.isNotEmpty ?? false,
      importGenerationParams: metadata != null && _hasGenerationData(metadata),
      importCharacters:
          (metadata?.characterPrompts.isNotEmpty ?? false) ||
          (metadata?.characterInfos.isNotEmpty ?? false),
      importVibeReferences: metadata?.vibeReferences.isNotEmpty ?? false,
      importPreciseReferences: metadata?.preciseReferences.isNotEmpty ?? false,
    );
  }

  void _choose(ImageDestination destination) => Navigator.of(context).pop(
    ImageDestinationResult(
      destination,
      selection: destination == ImageDestination.extractMetadata
          ? _selection
          : null,
    ),
  );

  bool get _hasSelection =>
      _selection.importPrompt ||
      _selection.importNegativePrompt ||
      _selection.importGenerationParams ||
      _selection.importSeed ||
      _selection.importCharacters ||
      _selection.importVibeReferences ||
      _selection.importPreciseReferences;

  List<_ImportChoice> _choices(BuildContext context) {
    final l10n = context.l10n;
    final metadata = widget.metadata!;
    final characterCount = math.max(
      metadata.characterPrompts.length,
      metadata.characterInfos.length,
    );
    final referenceCount =
        metadata.vibeReferences.length + metadata.preciseReferences.length;
    return [
      _ImportChoice(
        id: 'prompt',
        icon: Icons.description_outlined,
        label: l10n.metadataImport_mainPrompt,
        value: _selection.importPrompt,
        onChanged: (v) => _selection = _selection.copyWith(importPrompt: v),
      ),
      _ImportChoice(
        id: 'negative',
        icon: Icons.remove_circle_outline,
        label: l10n.metadataImport_negativePrompt,
        value: _selection.importNegativePrompt,
        onChanged: (v) =>
            _selection = _selection.copyWith(importNegativePrompt: v),
      ),
      _ImportChoice(
        id: 'settings',
        icon: Icons.tune,
        label: l10n.metadataImport_generationSection,
        value: _selection.importGenerationParams,
        enabled: _hasGenerationData(metadata),
        onChanged: (v) =>
            _selection = _selection.copyWith(importGenerationParams: v),
      ),
      _ImportChoice(
        id: 'seed',
        icon: Icons.numbers,
        label: l10n.metadataImport_seed,
        value: _selection.importSeed,
        enabled: metadata.seed != null,
        onChanged: (v) => _selection = _selection.copyWith(importSeed: v),
      ),
      _ImportChoice(
        id: 'characters',
        icon: Icons.people_outline,
        label: l10n.imageUse_characters,
        subtitle: characterCount == 0
            ? l10n.metadataImport_noCharactersReplaceClears
            : '$characterCount ${l10n.metadataImport_charactersCount}',
        value: _selection.importCharacters,
        onChanged: (v) => _selection = _selection.copyWith(importCharacters: v),
      ),
      _ImportChoice(
        id: 'references',
        icon: Icons.image_outlined,
        label: l10n.metadataImport_referenceSection,
        subtitle: referenceCount == 0
            ? l10n.metadataImport_noData
            : l10n.metadataImport_countUnit(referenceCount),
        value:
            _selection.importVibeReferences ||
            _selection.importPreciseReferences,
        enabled: referenceCount > 0,
        onChanged: (v) => _selection = _selection.copyWith(
          importVibeReferences: v && metadata.vibeReferences.isNotEmpty,
          importPreciseReferences: v && metadata.preciseReferences.isNotEmpty,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final choices = widget.metadata == null
        ? <_ImportChoice>[]
        : _choices(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: math.max(160, size.height - 48),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.imageUse_title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.common_close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerLowest,
                        child: SizedBox(
                          height: (size.height * .28).clamp(120.0, 220.0),
                          width: double.infinity,
                          child: Image.memory(
                            widget.imageBytes,
                            key: const Key('image-use-preview'),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.detectedVibe != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.drop_vibeDetected,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (choices.isEmpty)
                      Text(
                        l10n.metadataImport_noDataFound,
                        style: theme.textTheme.bodySmall,
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.imageUse_importContent,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('image-use-select-all'),
                            onPressed:
                                choices
                                    .where((c) => c.enabled)
                                    .every((c) => c.value)
                                ? null
                                : () => setState(() {
                                    for (final c in choices.where(
                                      (c) => c.enabled,
                                    )) {
                                      c.onChanged(true);
                                    }
                                  }),
                            child: Text(l10n.common_selectAll),
                          ),
                        ],
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 420 ? 3 : 2;
                          return Column(
                            children: [
                              for (
                                var start = 0;
                                start < choices.length;
                                start += columns
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: start + columns < choices.length
                                        ? 8
                                        : 0,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (
                                          var offset = 0;
                                          offset < columns;
                                          offset++
                                        ) ...[
                                          if (offset > 0)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: _ImportCard(
                                              choice: choices[start + offset],
                                              onTap:
                                                  choices[start + offset]
                                                      .enabled
                                                  ? () => setState(
                                                      () =>
                                                          choices[start +
                                                                  offset]
                                                              .onChanged(
                                                                !choices[start +
                                                                        offset]
                                                                    .value,
                                                              ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.imageUse_characterMode,
                            style: theme.textTheme.bodySmall,
                          ),
                          DropdownButton<OfficialCharacterImportMode>(
                            key: const Key('image-use-character-mode'),
                            value: _selection.characterMode,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: OfficialCharacterImportMode.replace,
                                child: Text(
                                  l10n.metadataImport_replaceCharacters,
                                ),
                              ),
                              DropdownMenuItem(
                                value: OfficialCharacterImportMode.append,
                                child: Text(
                                  l10n.metadataImport_appendCharacters,
                                ),
                              ),
                            ],
                            onChanged: !_selection.importCharacters
                                ? null
                                : (mode) {
                                    if (mode != null) {
                                      setState(
                                        () => _selection = _selection.copyWith(
                                          characterMode: mode,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          children: [
                            _action(
                              Icons.image_outlined,
                              l10n.drop_img2img,
                              ImageDestination.img2img,
                            ),
                            if (widget.detectedVibe == null)
                              _action(
                                StudioIcons.vibeLibrary,
                                l10n.drop_vibeTransfer,
                                ImageDestination.vibeTransfer,
                              )
                            else
                              _vibeMenu(context),
                            _action(
                              StudioIcons.preciseReference,
                              l10n.drop_characterReference,
                              ImageDestination.characterReference,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('image-use-import'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(72, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: widget.metadata != null && _hasSelection
                            ? () => _choose(ImageDestination.extractMetadata)
                            : null,
                        child: Text(l10n.common_import),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _actionStyle(BuildContext context) => TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.onSurface,
    textStyle: Theme.of(context).textTheme.labelMedium,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    minimumSize: const Size(0, 34),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );
  Widget _action(IconData icon, String label, ImageDestination destination) =>
      TextButton.icon(
        onPressed: () => _choose(destination),
        style: _actionStyle(context),
        icon: Icon(icon, size: 16),
        label: Text(label),
      );

  Widget _vibeMenu(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<ImageDestination>(
      key: const Key('image-use-vibe-menu'),
      onSelected: _choose,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: ImageDestination.vibeTransferReuse,
          child: Text(l10n.drop_reuseVibe),
        ),
        PopupMenuItem(
          value: ImageDestination.vibeTransferRaw,
          child: Text(l10n.drop_useAsRawImage),
        ),
        PopupMenuItem(
          value: ImageDestination.saveToVibeLibrary,
          child: Text(
            widget.isBundle
                ? l10n.drop_saveVibeBundle
                : l10n.vibe_saveToLibrary_title,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(StudioIcons.vibeLibrary, size: 16),
            const SizedBox(width: 4),
            Text(
              l10n.drop_vibeTransfer,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const Icon(Icons.keyboard_arrow_down, size: 14),
          ],
        ),
      ),
    );
  }

  static bool _hasGenerationData(NaiImageMetadata m) =>
      m.steps != null ||
      m.scale != null ||
      (m.width != null && m.height != null) ||
      m.sampler != null ||
      m.effectiveModel != null ||
      m.smea != null ||
      m.smeaDyn != null ||
      m.varietyPlus != null ||
      m.noiseSchedule != null ||
      m.cfgRescale != null ||
      m.qualityToggle != null ||
      m.qualityTagHint != null ||
      m.ucPreset != null ||
      m.ucPresetTagHint != null;
}

class _ImportChoice {
  const _ImportChoice({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });
  final String id;
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({required this.choice, this.onTap});
  final _ImportChoice choice;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = choice.enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: .38);
    return Semantics(
      label: [
        choice.label,
        if (choice.subtitle != null) choice.subtitle!,
      ].join(', '),
      checked: choice.value,
      enabled: choice.enabled,
      child: ExcludeSemantics(
        child: Material(
          color: choice.value
              ? scheme.primary.withValues(alpha: .07)
              : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: choice.value
                  ? scheme.primary.withValues(alpha: .4)
                  : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            key: Key('image-use-${choice.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(choice.icon, size: 18, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            choice.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          choice.value
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: choice.value
                              ? scheme.primary
                              : color.withValues(alpha: .5),
                        ),
                      ],
                    ),
                    if (choice.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        choice.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: choice.enabled
                              ? scheme.onSurfaceVariant
                              : color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
