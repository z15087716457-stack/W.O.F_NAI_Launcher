import 'package:flutter/material.dart';

import '../../../../core/enums/precise_ref_type.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/gallery/nai_image_metadata.dart';
import '../../../../data/models/metadata/metadata_import_options.dart';

/// 元数据导入对话框
///
/// 允许用户选择性地套用图片元数据中的参数
/// 新设计：按类型分组复选框，支持父子选项联动
class MetadataImportDialog extends StatefulWidget {
  final NaiImageMetadata metadata;

  const MetadataImportDialog({super.key, required this.metadata});

  /// 显示对话框并返回用户选择的导入选项
  static Future<MetadataImportOptions?> show(
    BuildContext context, {
    required NaiImageMetadata metadata,
  }) {
    return showDialog<MetadataImportOptions>(
      context: context,
      builder: (context) => MetadataImportDialog(metadata: metadata),
    );
  }

  /// 显示官网式的紧凑元数据导入框。
  static Future<OfficialMetadataImportSelection?> showOfficial(
    BuildContext context, {
    required NaiImageMetadata metadata,
  }) {
    return showDialog<OfficialMetadataImportSelection>(
      context: context,
      builder: (context) => _OfficialMetadataImportDialog(metadata: metadata),
    );
  }

  @override
  State<MetadataImportDialog> createState() => _MetadataImportDialogState();
}

class _MetadataImportDialogState extends State<MetadataImportDialog> {
  late MetadataImportOptions _options;

  @override
  void initState() {
    super.initState();
    _options = MetadataImportOptions.all();
    // 初始化选择列表
    _initializeSelections();
  }

  /// 初始化选择列表（默认全选）
  void _initializeSelections() {
    // 默认选择所有质量词
    final qualityTags = widget.metadata.qualityTags;
    // 默认选择所有角色
    final characterCount = widget.metadata.characterInfos.length;
    // 默认选择所有Vibe
    final vibeCount = widget.metadata.vibeReferences.length;
    // 默认选择所有精准参考
    final preciseReferenceCount = widget.metadata.preciseReferences.length;

    _options = _options.copyWith(
      selectedQualityTags: qualityTags.isNotEmpty ? List.from(qualityTags) : [],
      selectedCharacterIndices: characterCount > 0
          ? List.generate(characterCount, (i) => i)
          : [],
      selectedVibeIndices: vibeCount > 0
          ? List.generate(vibeCount, (i) => i)
          : [],
      selectedPreciseReferenceIndices: preciseReferenceCount > 0
          ? List.generate(preciseReferenceCount, (i) => i)
          : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selectedCount = _options.selectedCountFor(widget.metadata);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(l10n.metadataImport_title),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 600,
        child: Column(
          children: [
            // 快速预设按钮
            _buildQuickPresets(),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 8),
            // 可滚动的选项列表
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 提示词分组
                    _buildPromptSection(),
                    if (_hasReferenceData()) ...[
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 8),
                      _buildReferenceSection(),
                    ],
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 8),
                    // 生成参数分组
                    _buildGenerationSection(),
                  ],
                ),
              ),
            ),
            // 底部统计
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.metadataImport_selectedCount(selectedCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: selectedCount == 0
              ? null
              : () => Navigator.of(context).pop(_options),
          child: Text(l10n.common_confirm),
        ),
      ],
    );
  }

  /// 构建快速预设按钮区域
  Widget _buildQuickPresets() {
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.select_all, size: 18),
          label: Text(l10n.metadataImport_selectAll),
          onPressed: () => setState(() {
            _options = MetadataImportOptions.all();
            _initializeSelections();
          }),
        ),
        ActionChip(
          avatar: const Icon(Icons.text_fields, size: 18),
          label: Text(l10n.metadataImport_promptsOnly),
          onPressed: () => setState(() {
            _options = MetadataImportOptions.promptsOnly();
            _initializeSelections();
          }),
        ),
        ActionChip(
          avatar: const Icon(Icons.tune, size: 18),
          label: Text(l10n.metadataImport_generationOnly),
          onPressed: () => setState(() {
            _options = MetadataImportOptions.generationOnly();
            _initializeSelections();
          }),
        ),
        ActionChip(
          avatar: const Icon(Icons.deselect, size: 18),
          label: Text(l10n.metadataImport_clear),
          onPressed: () =>
              setState(() => _options = MetadataImportOptions.none()),
        ),
      ],
    );
  }

  /// 构建提示词分组
  Widget _buildPromptSection() {
    final l10n = context.l10n;
    final metadata = widget.metadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          l10n.metadataImport_promptsSection,
          Icons.text_fields,
        ),
        const SizedBox(height: 8),
        // 主提示词
        _buildCheckboxTile(
          title: l10n.metadataImport_mainPrompt,
          subtitle: _truncateText(metadata.mainPrompt, 50),
          value: _options.importPrompt,
          hasData: metadata.prompt.isNotEmpty,
          onChanged: (v) =>
              setState(() => _options = _options.copyWith(importPrompt: v)),
        ),
        // 固定词（带子选项）
        if (metadata.hasSeparatedFields) ...[
          _buildParentCheckboxTile(
            title: l10n.metadataImport_fixedTags,
            value: _options.importFixedTags,
            hasData:
                metadata.fixedPrefixTags.isNotEmpty ||
                metadata.fixedSuffixTags.isNotEmpty ||
                metadata.fixedNegativePrefixTags.isNotEmpty ||
                metadata.fixedNegativeSuffixTags.isNotEmpty,
            onChanged: (v) => setState(
              () => _options = _options.copyWith(importFixedTags: v),
            ),
            children: [
              if (metadata.fixedPrefixTags.isNotEmpty)
                _buildChildCheckboxTile(
                  title: l10n.metadataImport_fixedPrefix(
                    _truncateText(metadata.fixedPrefixTags.join(', '), 40),
                  ),
                  value: _options.importFixedPrefix,
                  onChanged: _options.importFixedTags
                      ? (v) => setState(
                          () => _options = _options.copyWith(
                            importFixedPrefix: v,
                          ),
                        )
                      : null,
                ),
              if (metadata.fixedSuffixTags.isNotEmpty)
                _buildChildCheckboxTile(
                  title: l10n.metadataImport_fixedSuffix(
                    _truncateText(metadata.fixedSuffixTags.join(', '), 40),
                  ),
                  value: _options.importFixedSuffix,
                  onChanged: _options.importFixedTags
                      ? (v) => setState(
                          () => _options = _options.copyWith(
                            importFixedSuffix: v,
                          ),
                        )
                      : null,
                ),
              if (metadata.fixedNegativePrefixTags.isNotEmpty)
                _buildChildCheckboxTile(
                  title: l10n.metadataImport_negativeFixedPrefix(
                    _truncateText(
                      metadata.fixedNegativePrefixTags.join(', '),
                      40,
                    ),
                  ),
                  value: _options.importFixedPrefix,
                  onChanged: _options.importFixedTags
                      ? (v) => setState(
                          () => _options = _options.copyWith(
                            importFixedPrefix: v,
                          ),
                        )
                      : null,
                ),
              if (metadata.fixedNegativeSuffixTags.isNotEmpty)
                _buildChildCheckboxTile(
                  title: l10n.metadataImport_negativeFixedSuffix(
                    _truncateText(
                      metadata.fixedNegativeSuffixTags.join(', '),
                      40,
                    ),
                  ),
                  value: _options.importFixedSuffix,
                  onChanged: _options.importFixedTags
                      ? (v) => setState(
                          () => _options = _options.copyWith(
                            importFixedSuffix: v,
                          ),
                        )
                      : null,
                ),
            ],
          ),
          // 质量词（带子选项）
          if (metadata.qualityTags.isNotEmpty)
            _buildParentCheckboxTile(
              title: l10n.metadataImport_qualityTagsCount(
                metadata.qualityTags.length,
              ),
              value: _options.importQualityTags,
              hasData: true,
              onChanged: (v) => setState(
                () => _options = _options.copyWith(importQualityTags: v),
              ),
              children: metadata.qualityTags.asMap().entries.map((entry) {
                final tag = entry.value;
                return _buildChildCheckboxTile(
                  title: tag,
                  value: _options.selectedQualityTags.contains(tag),
                  onChanged: _options.importQualityTags
                      ? (v) => setState(() {
                          final selected = List<String>.from(
                            _options.selectedQualityTags,
                          );
                          if (v) {
                            if (!selected.contains(tag)) selected.add(tag);
                          } else {
                            selected.remove(tag);
                          }
                          _options = _options.copyWith(
                            selectedQualityTags: selected,
                          );
                        })
                      : null,
                );
              }).toList(),
            ),
          // 角色提示词（带子选项）
          if (metadata.characterInfos.isNotEmpty)
            _buildParentCheckboxTile(
              title: l10n.metadataImport_characterPromptsCount(
                metadata.characterInfos.length,
              ),
              value: _options.importCharacterPrompts,
              hasData: true,
              onChanged: (v) => setState(
                () => _options = _options.copyWith(importCharacterPrompts: v),
              ),
              children: metadata.characterInfos.asMap().entries.map((entry) {
                final index = entry.key;
                final character = entry.value;
                return _buildChildCheckboxTile(
                  title: l10n.metadataImport_characterIndex(
                    index + 1,
                    _truncateText(character.prompt, 35),
                  ),
                  value: _options.selectedCharacterIndices.contains(index),
                  onChanged: _options.importCharacterPrompts
                      ? (v) => setState(() {
                          final selected = List<int>.from(
                            _options.selectedCharacterIndices,
                          );
                          if (v) {
                            if (!selected.contains(index)) {
                              selected.add(index);
                            }
                          } else {
                            selected.remove(index);
                          }
                          _options = _options.copyWith(
                            selectedCharacterIndices: selected,
                          );
                        })
                      : null,
                );
              }).toList(),
            ),
        ] else ...[
          // 旧数据：只显示角色提示词总开关
          if (metadata.characterPrompts.isNotEmpty)
            _buildCheckboxTile(
              title: l10n.metadataImport_characterPromptsCount(
                metadata.characterPrompts.length,
              ),
              value: _options.importCharacterPrompts,
              hasData: true,
              onChanged: (v) => setState(
                () => _options = _options.copyWith(importCharacterPrompts: v),
              ),
            ),
        ],
        // 负向提示词
        _buildCheckboxTile(
          title: l10n.metadataImport_negativePrompt,
          subtitle: _truncateText(metadata.displayNegativePrompt, 50),
          value: _options.importNegativePrompt,
          hasData: metadata.negativePrompt.isNotEmpty,
          onChanged: (v) => setState(
            () => _options = _options.copyWith(importNegativePrompt: v),
          ),
        ),
      ],
    );
  }

  bool _hasReferenceData() {
    final metadata = widget.metadata;
    return metadata.vibeReferences.isNotEmpty ||
        metadata.preciseReferences.isNotEmpty;
  }

  /// 构建参考图分组
  Widget _buildReferenceSection() {
    final l10n = context.l10n;
    final metadata = widget.metadata;
    final preciseReferences = metadata.preciseReferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          l10n.metadataImport_referenceSection,
          Icons.auto_awesome,
        ),
        const SizedBox(height: 8),
        if (metadata.vibeReferences.isNotEmpty)
          _buildParentCheckboxTile(
            title:
                'Vibe Transfer (${l10n.metadataImport_countUnit(metadata.vibeReferences.length)})',
            value: _options.importVibeReferences,
            hasData: true,
            onChanged: (v) => setState(
              () => _options = _options.copyWith(importVibeReferences: v),
            ),
            children: metadata.vibeReferences.asMap().entries.map((entry) {
              final index = entry.key;
              final vibe = entry.value;
              return _buildChildCheckboxTile(
                title: l10n.metadataImport_vibeDetail(
                  vibe.displayName,
                  (vibe.strength * 100).toStringAsFixed(0),
                  (vibe.infoExtracted * 100).toStringAsFixed(0),
                ),
                value: _options.selectedVibeIndices.contains(index),
                onChanged: _options.importVibeReferences
                    ? (v) => setState(() {
                        final selected = List<int>.from(
                          _options.selectedVibeIndices,
                        );
                        if (v) {
                          if (!selected.contains(index)) selected.add(index);
                        } else {
                          selected.remove(index);
                        }
                        _options = _options.copyWith(
                          selectedVibeIndices: selected,
                        );
                      })
                    : null,
              );
            }).toList(),
          ),
        if (preciseReferences.isNotEmpty)
          _buildParentCheckboxTile(
            title: l10n.metadataImport_preciseReferenceCount(
              preciseReferences.length,
            ),
            value: _options.importPreciseReferences,
            hasData: true,
            onChanged: (v) => setState(
              () => _options = _options.copyWith(importPreciseReferences: v),
            ),
            children: preciseReferences.asMap().entries.map((entry) {
              final index = entry.key;
              final reference = entry.value;
              return _buildChildCheckboxTile(
                title: l10n.metadataImport_preciseReferenceDetail(
                  index + 1,
                  reference.type.toApiString(),
                  (reference.strength * 100).toStringAsFixed(0),
                  (reference.fidelity * 100).toStringAsFixed(0),
                ),
                value: _options.selectedPreciseReferenceIndices.contains(index),
                onChanged: _options.importPreciseReferences
                    ? (v) => setState(() {
                        final selected = List<int>.from(
                          _options.selectedPreciseReferenceIndices,
                        );
                        if (v) {
                          if (!selected.contains(index)) selected.add(index);
                        } else {
                          selected.remove(index);
                        }
                        _options = _options.copyWith(
                          selectedPreciseReferenceIndices: selected,
                        );
                      })
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }

  /// 构建生成参数分组
  Widget _buildGenerationSection() {
    final l10n = context.l10n;
    final options = _buildGenerationImportOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.metadataImport_generationSection, Icons.tune),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options
              .where((option) => option.hasData)
              .map(
                (option) => _buildCompactCheckbox(
                  label: option.label,
                  value: option.value,
                  hasData: option.hasData,
                  onChanged: option.onChanged,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<_GenerationImportOption> _buildGenerationImportOptions() {
    final l10n = context.l10n;
    final metadata = widget.metadata;

    return [
      _GenerationImportOption(
        label: l10n.generation_seed,
        value: _options.importSeed,
        hasData: metadata.seed != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSeed: v)),
      ),
      _GenerationImportOption(
        label: _labelBeforeColon(l10n.generation_steps('')),
        value: _options.importSteps,
        hasData: metadata.steps != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSteps: v)),
      ),
      _GenerationImportOption(
        label: _labelBeforeColon(l10n.generation_cfgScale('')),
        value: _options.importScale,
        hasData: metadata.scale != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importScale: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_imageSize,
        value: _options.importSize,
        hasData: metadata.width != null && metadata.height != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSize: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_sampler,
        value: _options.importSampler,
        hasData: metadata.sampler != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSampler: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_model,
        value: _options.importModel,
        hasData: metadata.effectiveModel != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importModel: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_smea,
        value: _options.importSmea,
        hasData: metadata.smea == true || metadata.smeaDyn == true,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSmea: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_smeaDyn,
        value: _options.importSmeaDyn,
        hasData: metadata.smeaDyn == true,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importSmeaDyn: v)),
      ),
      _GenerationImportOption(
        label: 'Variety+',
        value: _options.importVarietyPlus,
        hasData: metadata.varietyPlus != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importVarietyPlus: v)),
      ),
      _GenerationImportOption(
        label: l10n.generation_noiseSchedule,
        value: _options.importNoiseSchedule,
        hasData: metadata.noiseSchedule != null,
        onChanged: (v) => setState(
          () => _options = _options.copyWith(importNoiseSchedule: v),
        ),
      ),
      _GenerationImportOption(
        label: _labelBeforeColon(l10n.generation_cfgRescale('')),
        value: _options.importCfgRescale,
        hasData: metadata.cfgRescale != null && metadata.cfgRescale! > 0,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importCfgRescale: v)),
      ),
      _GenerationImportOption(
        label: l10n.qualityTags_label,
        value: _options.importQualityToggle,
        hasData: metadata.qualityToggle != null,
        onChanged: (v) => setState(
          () => _options = _options.copyWith(importQualityToggle: v),
        ),
      ),
      _GenerationImportOption(
        label: l10n.ucPreset_label,
        value: _options.importUcPreset,
        hasData: metadata.ucPreset != null,
        onChanged: (v) =>
            setState(() => _options = _options.copyWith(importUcPreset: v)),
      ),
    ];
  }

  /// 构建分组标题
  Widget _buildSectionTitle(String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 构建复选框列表项
  Widget _buildCheckboxTile({
    required String title,
    String? subtitle,
    required bool value,
    required bool hasData,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: hasData ? null : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null && hasData
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : !hasData
          ? Text(
              context.l10n.metadataImport_noData,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      value: value && hasData,
      onChanged: hasData ? (v) => onChanged(v ?? false) : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  /// 构建父级复选框（带缩进子选项）
  Widget _buildParentCheckboxTile({
    required String title,
    required bool value,
    required bool hasData,
    required ValueChanged<bool> onChanged,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasData ? null : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          value: value && hasData,
          onChanged: hasData ? (v) => onChanged(v ?? false) : null,
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        // 子选项缩进显示
        if (value && hasData && children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    );
  }

  /// 构建子级复选框
  Widget _buildChildCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      title: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          color: onChanged != null
              ? null
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: value && onChanged != null,
      onChanged: onChanged != null ? (v) => onChanged(v ?? false) : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
    );
  }

  /// 构建紧凑复选框（用于生成参数）
  Widget _buildCompactCheckbox({
    required String label,
    required bool value,
    required bool hasData,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: hasData
              ? value
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      selected: value && hasData,
      onSelected: hasData ? onChanged : null,
      showCheckmark: true,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      disabledColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  /// 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _labelBeforeColon(String text) {
    final colonIndex = text.indexOf(':');
    if (colonIndex < 0) return text.trim();
    return text.substring(0, colonIndex).trim();
  }
}

class _GenerationImportOption {
  const _GenerationImportOption({
    required this.label,
    required this.value,
    required this.hasData,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool hasData;
  final ValueChanged<bool> onChanged;
}

class _OfficialMetadataImportDialog extends StatefulWidget {
  const _OfficialMetadataImportDialog({required this.metadata});

  final NaiImageMetadata metadata;

  @override
  State<_OfficialMetadataImportDialog> createState() =>
      _OfficialMetadataImportDialogState();
}

class _OfficialMetadataImportDialogState
    extends State<_OfficialMetadataImportDialog> {
  late OfficialMetadataImportSelection _selection;

  @override
  void initState() {
    super.initState();
    final metadata = widget.metadata;
    _selection = OfficialMetadataImportSelection(
      // Prompt is intentionally selected even when empty, because the official
      // reuse flow treats it as a complete replacement.
      importPrompt: true,
      importNegativePrompt: metadata.negativePrompt.isNotEmpty,
      importGenerationParams: _hasGenerationData(metadata),
      importCharacters: metadata.characterPrompts.isNotEmpty,
      importVibeReferences: metadata.vibeReferences.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.metadataImport_title)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(l10n.metadataImport_promptsSection),
            _buildCheckTile(
              title: l10n.metadataImport_mainPrompt,
              subtitle: widget.metadata.prompt.isEmpty
                  ? l10n.metadataImport_noData
                  : _preview(widget.metadata.prompt),
              value: _selection.importPrompt,
              onChanged: (value) =>
                  _selection = _selection.copyWith(importPrompt: value),
            ),
            _buildCheckTile(
              title: l10n.metadataImport_negativePrompt,
              subtitle: widget.metadata.negativePrompt.isEmpty
                  ? l10n.metadataImport_noData
                  : _preview(widget.metadata.displayNegativePrompt),
              value: _selection.importNegativePrompt,
              onChanged: (value) =>
                  _selection = _selection.copyWith(importNegativePrompt: value),
            ),
            const Divider(height: 20),
            _buildSectionLabel(l10n.settings_title),
            _buildCheckTile(
              title: l10n.metadataImport_generationSection,
              subtitle: _generationSummary(widget.metadata),
              value: _selection.importGenerationParams,
              enabled: _hasGenerationData(widget.metadata),
              onChanged: (value) => _selection = _selection.copyWith(
                importGenerationParams: value,
              ),
            ),
            _buildCheckTile(
              title: l10n.metadataImport_seed,
              subtitle: widget.metadata.seed == null
                  ? l10n.metadataImport_noData
                  : widget.metadata.seed.toString(),
              value: _selection.importSeed,
              enabled: widget.metadata.seed != null,
              onChanged: (value) =>
                  _selection = _selection.copyWith(importSeed: value),
            ),
            const Divider(height: 20),
            _buildSectionLabel(l10n.metadataImport_characterPrompts),
            _buildCheckTile(
              title: l10n.metadataImport_characterPrompts,
              subtitle: widget.metadata.characterPrompts.isEmpty
                  ? '无角色数据；替换模式会清空当前角色 / '
                        'No character data; replace clears current characters'
                  : '${widget.metadata.characterPrompts.length} '
                        '${l10n.metadataImport_charactersCount}',
              value: _selection.importCharacters,
              onChanged: (value) =>
                  _selection = _selection.copyWith(importCharacters: value),
            ),
            _buildCharacterModeOptions(),
            const Divider(height: 20),
            _buildSectionLabel(l10n.metadataImport_referenceSection),
            _buildCheckTile(
              title: l10n.vibe_title,
              subtitle: widget.metadata.vibeReferences.isEmpty
                  ? l10n.metadataImport_noData
                  : l10n.metadataImport_countUnit(
                      widget.metadata.vibeReferences.length,
                    ),
              value: _selection.importVibeReferences,
              onChanged: (value) =>
                  _selection = _selection.copyWith(importVibeReferences: value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _hasAnySelection()
              ? () => Navigator.of(context).pop(_selection)
              : null,
          child: Text(l10n.common_confirm),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: enabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.outline,
        ),
      ),
      value: value,
      onChanged: enabled
          ? (next) {
              if (next == null) return;
              setState(() => onChanged(next));
            }
          : null,
    );
  }

  Widget _buildCharacterModeOptions() {
    final enabled = _selection.importCharacters;
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<OfficialCharacterImportMode>(
          segments: const [
            ButtonSegment(
              value: OfficialCharacterImportMode.replace,
              label: Text('替换角色 / Replace'),
            ),
            ButtonSegment(
              value: OfficialCharacterImportMode.append,
              label: Text('追加角色 / Append'),
            ),
          ],
          selected: {_selection.characterMode},
          emptySelectionAllowed: false,
          onSelectionChanged: enabled
              ? (values) {
                  if (values.isEmpty) return;
                  setState(
                    () => _selection = _selection.copyWith(
                      characterMode: values.first,
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }

  bool _hasAnySelection() {
    return _selection.importPrompt ||
        _selection.importNegativePrompt ||
        _selection.importGenerationParams ||
        _selection.importSeed ||
        _selection.importCharacters ||
        _selection.importVibeReferences;
  }

  String _preview(String value) {
    final oneLine = value.replaceAll(RegExp(r'\\s+'), ' ').trim();
    if (oneLine.length <= 80) return oneLine;
    return '${oneLine.substring(0, 80)}...';
  }

  String _generationSummary(NaiImageMetadata metadata) {
    final l10n = context.l10n;
    final labels = <String>[
      if (metadata.steps != null) l10n.metadataImport_steps,
      if (metadata.scale != null) l10n.metadataImport_scale,
      if (metadata.width != null && metadata.height != null)
        l10n.metadataImport_size,
      if (metadata.sampler != null) l10n.metadataImport_sampler,
      if (metadata.effectiveModel != null) l10n.metadataImport_model,
      if (metadata.smea != null) l10n.metadataImport_smea,
      if (metadata.smeaDyn != null) l10n.metadataImport_smeaDyn,
      if (metadata.varietyPlus != null) 'Variety+',
      if (metadata.noiseSchedule != null) l10n.metadataImport_noiseSchedule,
      if (metadata.cfgRescale != null) l10n.metadataImport_cfgRescale,
      if (metadata.qualityToggle != null) l10n.metadataImport_qualityToggle,
      if (metadata.ucPreset != null) l10n.metadataImport_ucPreset,
    ];
    return labels.isEmpty ? l10n.metadataImport_noData : labels.join(' · ');
  }

  static bool _hasGenerationData(NaiImageMetadata metadata) {
    return metadata.steps != null ||
        metadata.scale != null ||
        (metadata.width != null && metadata.height != null) ||
        metadata.sampler != null ||
        metadata.effectiveModel != null ||
        metadata.smea != null ||
        metadata.smeaDyn != null ||
        metadata.varietyPlus != null ||
        metadata.noiseSchedule != null ||
        metadata.cfgRescale != null ||
        metadata.qualityToggle != null ||
        metadata.ucPreset != null;
  }
}
