import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/prompt_token_counter_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../core/utils/prompt_block_thumbnails.dart';
import '../../../../core/utils/thumbnail_image_normalizer.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/generation/generation_params_notifier.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/inset_shadow_container.dart';
import '../../../widgets/common/themed_input.dart';
import '../../../widgets/common/thumbnail_display.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../../widgets/common/thumbnail_crop_dialog.dart';
import '../../../widgets/prompt/prompt_token_count_bar.dart';
import 'atom_list_editor.dart';
import 'prompt_block_color_picker.dart';

class PromptBlockEditResult {
  const PromptBlockEditResult({
    required this.title,
    required this.content,
    required this.atoms,
    required this.negativeContent,
    required this.negativeAtoms,
    this.generationSettings,
    required this.folderId,
    required this.color,
    required this.iconName,
    this.thumbnail,
    this.thumbnailOffsetX = 0.0,
    this.thumbnailOffsetY = 0.0,
    this.thumbnailScale = 1.0,
  });

  final String title;
  final String content;
  final String negativeContent;
  final List<String> negativeAtoms;
  final PromptBlockGenerationSettings? generationSettings;

  /// 显式原子列表（FEAT-79）：编辑器保存口径，空白段已剔除；
  /// [content] 恒等于 `atoms.join(', ')`。
  final List<String> atoms;
  final String? folderId;
  final String color;
  final String? iconName;

  /// 应用目录内预览图路径；null = 无图。
  final String? thumbnail;
  final double thumbnailOffsetX;
  final double thumbnailOffsetY;
  final double thumbnailScale;
}

class PromptBlockEditDialog extends StatefulWidget {
  const PromptBlockEditDialog({
    super.key,
    required this.block,
    required this.folders,
    this.initialFolderId,
    this.initialTitle,
    this.initialContent,
    this.initialImageBytes,
    this.modelForTokenCount = ImageModels.animeDiffusionV5Full,
    this.tokenCounterService,
  });

  final PromptBlock? block;
  final List<PromptBlockFolder> folders;
  final String? initialFolderId;

  /// 新建模式下的初始标题（「存为块」入口预填名称）。
  final String? initialTitle;

  /// 新建模式下的初始正文（「存为块」入口预填提示词）。
  final String? initialContent;

  /// 新建模式下的初始预览图字节；打开弹窗时落盘为块缩略图。
  final Uint8List? initialImageBytes;

  /// 当前生成模型；块没有自带模型时用于编辑期的 token 上限。
  final String modelForTokenCount;
  final PromptTokenCounterService? tokenCounterService;

  static Future<PromptBlockEditResult?> show({
    required BuildContext context,
    PromptBlock? block,
    required List<PromptBlockFolder> folders,
    String? initialFolderId,
    String? initialTitle,
    String? initialContent,
    Uint8List? initialImageBytes,
    String modelForTokenCount = ImageModels.animeDiffusionV5Full,
    PromptTokenCounterService? tokenCounterService,
  }) {
    return showDialog<PromptBlockEditResult>(
      context: context,
      builder: (context) => PromptBlockEditDialog(
        block: block,
        folders: folders,
        initialFolderId: initialFolderId,
        initialTitle: initialTitle,
        initialContent: initialContent,
        initialImageBytes: initialImageBytes,
        modelForTokenCount: modelForTokenCount,
        tokenCounterService: tokenCounterService,
      ),
    );
  }

  /// 「存为块」统一入口：等块库就绪 → 打开编辑弹窗 → 确认后落库。
  ///
  /// 返回新建的块；用户取消返回 null。取代旧词库 EntryAddDialog 的
  /// 自选文本/图片/角色提示词入库路径。
  static Future<PromptBlock?> createWithDialog(
    BuildContext context,
    WidgetRef ref, {
    String? initialTitle,
    String? initialContent,
    Uint8List? initialImageBytes,
    String? initialFolderId,
  }) async {
    final library = await ref.read(promptBlockLibraryNotifierProvider.future);
    if (!context.mounted) return null;
    final result = await show(
      context: context,
      folders: library.folders,
      initialFolderId: initialFolderId,
      initialTitle: initialTitle,
      initialContent: initialContent,
      initialImageBytes: initialImageBytes,
      modelForTokenCount: ref.read(generationParamsNotifierProvider).model,
    );
    if (result == null) return null;
    final block = await ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .createBlock(
          title: result.title,
          content: result.content,
          atoms: result.atoms,
          negativeContent: result.negativeContent,
          negativeAtoms: result.negativeAtoms,
          generationSettings: result.generationSettings,
          folderId: result.folderId,
          color: result.color,
          iconName: result.iconName,
          thumbnail: result.thumbnail,
          thumbnailOffsetX: result.thumbnailOffsetX,
          thumbnailOffsetY: result.thumbnailOffsetY,
          thumbnailScale: result.thumbnailScale,
        );
    if (context.mounted) {
      AppToast.success(context, context.l10n.saveBlock_saved);
    }
    return block;
  }

  @override
  State<PromptBlockEditDialog> createState() => _PromptBlockEditDialogState();
}

class _PromptBlockEditDialogState extends State<PromptBlockEditDialog> {
  late final TextEditingController _titleController;
  late final AtomListEditorController _atomController;
  late final AtomListEditorController _negativeAtomController;
  late final TextEditingController _stepsController;
  late final TextEditingController _scaleController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _cfgRescaleController;
  String? _settingsModel;
  String? _settingsSampler;
  String? _settingsNoiseSchedule;
  int _contentTab = 0;
  late final Future<PromptTokenCounterService> _tokenService;
  late Future<PromptTokenUsage?> _tokenUsage;
  late String? _folderId;
  late Color _selectedColor;
  late String? _selectedIconName;

  /// 预览图当前路径：可能是应用目录内已存路径或本会话新落盘的选取图。
  String? _thumbnailPath;
  double _thumbnailOffsetX = 0.0;
  double _thumbnailOffsetY = 0.0;
  double _thumbnailScale = 1.0;

  /// 本会话选取时已落盘但尚未确认保存的新图；弹窗取消/丢弃时由
  /// [dispose] 统一回收，避免留下孤儿文件。
  final Set<String> _pendingThumbnailPaths = {};

  /// 保存确认后的最终路径；[_pendingThumbnailPaths] 里等于它的文件保留。
  String? _committedThumbnailPath;

  /// 保存进行中（落盘缩略图期间防重复提交）。
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.block?.title ?? widget.initialTitle ?? '',
    );
    // FEAT-79：正文进原子编辑器——旧块读显式 atoms、其余按顶层
    // 逗号预切（拍板②），保存时未块化文本自动收尾成原子。
    _atomController = AtomListEditorController(
      widget.block?.atomsOrSplit ??
          PillRollEngine.splitTopLevelAtoms(widget.initialContent ?? ''),
    );
    _negativeAtomController = AtomListEditorController(
      widget.block?.negativeAtomsOrSplit ?? const [],
    );
    final settings = widget.block?.generationSettings;
    _settingsModel = settings?.model;
    _settingsSampler = settings?.sampler;
    _settingsNoiseSchedule = settings?.noiseSchedule;
    _stepsController = TextEditingController(text: settings?.steps?.toString());
    _scaleController = TextEditingController(text: settings?.scale?.toString());
    _widthController = TextEditingController(text: settings?.width?.toString());
    _heightController = TextEditingController(
      text: settings?.height?.toString(),
    );
    _cfgRescaleController = TextEditingController(
      text: settings?.cfgRescale?.toString(),
    );
    _tokenService = widget.tokenCounterService == null
        ? PromptTokenCounterService.createDefault()
        : Future.value(widget.tokenCounterService);
    _atomController.addListener(_refreshTokenUsage);
    _negativeAtomController.addListener(_refreshTokenUsage);
    _tokenUsage = _countSelectedTokens();
    _folderId = widget.block?.folderId ?? widget.initialFolderId;
    _selectedColor = promptBlockColorFromString(
      widget.block?.color ?? '#FF607D8B',
    );
    _selectedIconName = widget.block?.iconName;
    _thumbnailPath = widget.block?.thumbnail;
    _thumbnailOffsetX = widget.block?.thumbnailOffsetX ?? 0.0;
    _thumbnailOffsetY = widget.block?.thumbnailOffsetY ?? 0.0;
    _thumbnailScale = widget.block?.thumbnailScale ?? 1.0;
    _persistInitialImageBytes();
  }

  /// 新建模式 + 外部传入图：先落盘为块缩略图并纳入 pending 回收表，
  /// 取消弹窗时由 [dispose] 清理，避免孤儿文件。
  void _persistInitialImageBytes() {
    final bytes = widget.initialImageBytes;
    if (widget.block != null || bytes == null || bytes.isEmpty) return;
    unawaited(() async {
      try {
        final savedPath = await savePromptBlockThumbnail(bytes);
        if (!mounted) {
          unawaited(deletePromptBlockThumbnail(savedPath));
          return;
        }
        _pendingThumbnailPaths.add(savedPath);
        setState(() => _thumbnailPath = savedPath);
      } catch (_) {
        // 预览图落盘失败不阻断正文编辑。
      }
    }());
  }

  @override
  void dispose() {
    for (final path in _pendingThumbnailPaths) {
      if (path != _committedThumbnailPath) {
        // 未确认的选取图：取消/放弃弹窗时回收落盘文件。
        unawaited(deletePromptBlockThumbnail(path));
      }
    }
    _titleController.dispose();
    _atomController.dispose();
    _negativeAtomController.dispose();
    _stepsController.dispose();
    _scaleController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _cfgRescaleController.dispose();
    super.dispose();
  }

  void _refreshTokenUsage() {
    _tokenUsage = _countSelectedTokens();
    if (mounted) setState(() {});
  }

  Future<PromptTokenUsage?> _countSelectedTokens() async {
    final negative = _contentTab == 1;
    final text = (negative ? _negativeAtomController : _atomController).atoms
        .join(', ');
    final model = _settingsModel ?? widget.modelForTokenCount;
    final limit = PromptTokenCounterService.tokenLimitForModel(model);
    if (limit == null) return null;
    final service = await _tokenService;
    final tokens = await service.countTokensForTexts([text]);
    return PromptTokenUsage(
      usedTokens: tokens == 0 ? 0 : tokens + 1,
      limit: limit,
      breakdown: tokens == 0
          ? const []
          : [
              PromptTokenBreakdownEntry(
                label: negative ? '负面提示词' : '提示词',
                tokens: tokens,
              ),
              const PromptTokenBreakdownEntry(label: '网页端校准', tokens: 1),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final folders = widget.folders.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });

    return AlertDialog(
      title: Text(
        widget.block == null
            ? l10n.promptBlockLibrary_newBlock
            : l10n.promptBlockLibrary_editBlock,
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedInput(
                controller: _titleController,
                autofocus: true,
                hintText: l10n.promptBlockLibrary_titleHint,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_blockTitle,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _folderId,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_folder,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.promptBlockLibrary_rootFolder),
                  ),
                  ...folders.map(
                    (folder) => DropdownMenuItem<String>(
                      value: folder.id,
                      child: Text(
                        _folderLabel(folder, folders),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _folderId = value),
              ),
              const SizedBox(height: 12),
              _buildThumbnailSection(theme, l10n),
              const SizedBox(height: 12),
              _buildContentPanel(theme, l10n),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_color,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockColorPicker(
                selectedColor: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_icon,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockIconPicker(
                selected: _selectedIconName,
                onChanged: (name) => setState(() => _selectedIconName = name),
              ),
              if (widget.block?.sourcePath case final sourcePath?) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${l10n.promptBlockLibrary_sourceFile}: ${_sourceFileName(sourcePath)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.block?.importedAt case final importedAt?)
                  Text(
                    '${l10n.promptBlockLibrary_importedAt}: ${_formatDateTime(importedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.common_save),
        ),
      ],
    );
  }

  Widget _buildContentPanel(ThemeData theme, AppLocalizations l10n) {
    return SizedBox(
      height: 320,
      child: InsetShadowContainer(
        borderRadius: 8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  _contentTabButton(0, l10n.promptBlockLibrary_basicPrompt),
                  const SizedBox(width: 4),
                  _contentTabButton(1, l10n.prompt_negativeTab),
                  const SizedBox(width: 4),
                  _contentTabButton(
                    2,
                    l10n.promptBlockLibrary_generationSettings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _contentTab,
                children: [
                  AtomListEditor(
                    key: const Key('block-positive-editor'),
                    controller: _atomController,
                    embedded: true,
                  ),
                  AtomListEditor(
                    key: const Key('block-negative-editor'),
                    controller: _negativeAtomController,
                    embedded: true,
                  ),
                  _buildSettingsPanel(l10n),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
              child: FutureBuilder<PromptTokenUsage?>(
                future: _tokenUsage,
                builder: (context, snapshot) {
                  final usage = snapshot.data;
                  if (usage == null) {
                    return const SizedBox(height: 14);
                  }
                  return PromptTokenCountBar(
                    key: const Key('block-token-count-bar'),
                    usage: usage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentTabButton(int index, String label) {
    final theme = Theme.of(context);
    final selected = _contentTab == index;
    return InkWell(
      key: Key('block-content-tab-$index'),
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        if (_contentTab == index) return;
        setState(() => _contentTab = index);
        _refreshTokenUsage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(AppLocalizations l10n) {
    final model = _settingsModel ?? widget.modelForTokenCount;
    final samplers = Samplers.samplersForModel(model);
    final modelChoices = {
      ...ImageModels.allModels,
      if (_settingsModel != null) _settingsModel!,
    };
    final samplerChoices = {
      ...samplers,
      if (_settingsSampler != null) _settingsSampler!,
    };
    return SingleChildScrollView(
      key: const Key('block-generation-settings'),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.promptBlockLibrary_settingsOptionalHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: const Key('block-setting-model'),
            initialValue: _settingsModel,
            decoration: InputDecoration(labelText: l10n.generation_model),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.promptBlockLibrary_notSpecified),
              ),
              for (final candidate in modelChoices)
                DropdownMenuItem<String?>(
                  value: candidate,
                  child: Text(
                    ImageModels.modelDisplayNames[candidate] ?? candidate,
                  ),
                ),
            ],
            onChanged: (value) {
              setState(() {
                _settingsModel = value;
                if (_settingsSampler != null &&
                    !Samplers.samplersForModel(
                      value ?? widget.modelForTokenCount,
                    ).contains(_settingsSampler)) {
                  _settingsSampler = null;
                }
              });
              _refreshTokenUsage();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _settingNumberField(
                  _stepsController,
                  l10n.promptBlockLibrary_stepsLabel,
                  key: const Key('block-setting-steps'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _settingNumberField(
                  _scaleController,
                  l10n.promptBlockLibrary_cfgLabel,
                  key: const Key('block-setting-scale'),
                  decimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _settingNumberField(
                  _widthController,
                  l10n.promptBlockLibrary_widthLabel,
                  key: const Key('block-setting-width'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _settingNumberField(
                  _heightController,
                  l10n.promptBlockLibrary_heightLabel,
                  key: const Key('block-setting-height'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: ValueKey('block-setting-sampler-$model'),
            initialValue: _settingsSampler,
            decoration: InputDecoration(labelText: l10n.generation_sampler),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.promptBlockLibrary_notSpecified),
              ),
              for (final sampler in samplerChoices)
                DropdownMenuItem<String?>(
                  value: sampler,
                  child: Text(Samplers.samplerDisplayNames[sampler] ?? sampler),
                ),
            ],
            onChanged: (value) => setState(() => _settingsSampler = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: const Key('block-setting-noise-schedule'),
            initialValue: _settingsNoiseSchedule,
            decoration: InputDecoration(
              labelText: l10n.promptBlockLibrary_noiseScheduleLabel,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.promptBlockLibrary_notSpecified),
              ),
              for (final schedule in NoiseSchedules.all)
                DropdownMenuItem<String?>(
                  value: schedule,
                  child: Text(
                    NoiseSchedules.displayNames[schedule] ?? schedule,
                  ),
                ),
            ],
            onChanged: (value) =>
                setState(() => _settingsNoiseSchedule = value),
          ),
          const SizedBox(height: 10),
          _settingNumberField(
            _cfgRescaleController,
            l10n.promptBlockLibrary_cfgRescaleLabel,
            key: const Key('block-setting-cfg-rescale'),
            decimal: true,
          ),
        ],
      ),
    );
  }

  Widget _settingNumberField(
    TextEditingController controller,
    String label, {
    Key? key,
    bool decimal = false,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  // ==================== 预览图区（FEAT-2） ====================

  /// 预览图小区块：无图 = 小横框内「+」提示；有图 = 缩略图 + 选项菜单。
  Widget _buildThumbnailSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.promptBlockLibrary_thumbnail,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isSaving
              ? null
              : (_thumbnailPath != null
                    ? _showThumbnailOptions
                    : _selectThumbnail),
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: _thumbnailPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: ThumbnailDisplay(
                          imagePath: _thumbnailPath!,
                          offsetX: _thumbnailOffsetX,
                          offsetY: _thumbnailOffsetY,
                          scale: _thumbnailScale,
                          width: 200,
                          height: 80,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          icon: const Icon(Icons.close, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(24, 24),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _isSaving ? null : _clearThumbnail,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: theme.colorScheme.outline,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedThumbnailImageExtensions,
        allowMultiple: false,
      );
      if (result == null) return;

      final selectedFile = result.files.single;
      final bytes =
          selectedFile.bytes ??
          (selectedFile.path == null
              ? null
              : await File(selectedFile.path!).readAsBytes());
      if (bytes == null) {
        throw const FileSystemException('无法读取所选图像');
      }

      // 归一化为 PNG 后直接落进块缩略图目录（与词库同策略）。
      final savedPath = await savePromptBlockThumbnail(bytes);
      if (!mounted) return;
      // 上一张本会话选取图已被换下 → 立即回收，不等 dispose。
      final replaced = _thumbnailPath;
      if (replaced != null && _pendingThumbnailPaths.contains(replaced)) {
        unawaited(deletePromptBlockThumbnail(replaced));
      }
      _pendingThumbnailPaths.add(savedPath);
      setState(() {
        _thumbnailPath = savedPath;
        _thumbnailOffsetX = 0.0;
        _thumbnailOffsetY = 0.0;
        _thumbnailScale = 1.0;
      });
      // 选完即出裁剪框做四周轻量裁剪。
      await _openCropDialog();
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.imagePicker_fileSelectionFailed(e.toString()),
        );
      }
    }
  }

  void _clearThumbnail() {
    setState(() {
      _thumbnailPath = null;
      _thumbnailOffsetX = 0.0;
      _thumbnailOffsetY = 0.0;
      _thumbnailScale = 1.0;
    });
  }

  void _showThumbnailOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(context.l10n.promptBlockLibrary_selectNewImage),
              onTap: () {
                Navigator.pop(sheetContext);
                _selectThumbnail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_free),
              title: Text(context.l10n.promptBlockLibrary_adjustDisplayRange),
              onTap: () {
                Navigator.pop(sheetContext);
                _openCropDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.common_delete),
              onTap: () {
                Navigator.pop(sheetContext);
                _clearThumbnail();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCropDialog() async {
    final path = _thumbnailPath;
    if (path == null) return;
    await showThumbnailCropDialog(
      context: context,
      imagePath: path,
      initialOffsetX: _thumbnailOffsetX,
      initialOffsetY: _thumbnailOffsetY,
      initialScale: _thumbnailScale,
      onConfirm: (result) {
        setState(() {
          _thumbnailOffsetX = result.offsetX;
          _thumbnailOffsetY = result.offsetY;
          _thumbnailScale = result.scale;
        });
      },
    );
  }

  /// 保存：外部新选图已在选取时落进块目录；此处只需清理被替换的旧图。
  Future<void> _save() async {
    if (_isSaving) return;
    final PromptBlockGenerationSettings? generationSettings;
    try {
      generationSettings = _readGenerationSettings();
    } on FormatException {
      AppToast.warning(
        context,
        context.l10n.promptBlockLibrary_invalidGenerationSettings,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final oldThumbnail = widget.block?.thumbnail;
      if (_thumbnailPath != oldThumbnail) {
        // 新选取图已在 _selectThumbnail 落目录；这里只回收被换下的旧图。
        await deletePromptBlockThumbnail(oldThumbnail);
      }
      _committedThumbnailPath = _thumbnailPath;
      if (!mounted) return;
      final atoms = _atomController.atoms;
      final negativeAtoms = _negativeAtomController.atoms;
      Navigator.of(context).pop(
        PromptBlockEditResult(
          title: _titleController.text.trim(),
          // FEAT-79：content 恒为 atoms 的 `, ` 拼接——插入/搜索/预览
          // 路径全部只读 content，抽取路径读显式 atoms。
          content: atoms.join(', '),
          atoms: atoms,
          negativeContent: negativeAtoms.join(', '),
          negativeAtoms: negativeAtoms,
          generationSettings: generationSettings,
          folderId: _folderId,
          color: promptBlockColorToHex(_selectedColor),
          iconName: _selectedIconName,
          thumbnail: _thumbnailPath,
          thumbnailOffsetX: _thumbnailOffsetX,
          thumbnailOffsetY: _thumbnailOffsetY,
          thumbnailScale: _thumbnailScale,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  PromptBlockGenerationSettings? _readGenerationSettings() {
    int? readInt(TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isEmpty) return null;
      return int.tryParse(value) ?? (throw const FormatException());
    }

    double? readDouble(TextEditingController controller) {
      final value = controller.text.trim();
      if (value.isEmpty) return null;
      final parsed = double.tryParse(value);
      if (parsed == null || !parsed.isFinite) throw const FormatException();
      return parsed;
    }

    final steps = readInt(_stepsController);
    final scale = readDouble(_scaleController);
    final width = readInt(_widthController);
    final height = readInt(_heightController);
    final cfgRescale = readDouble(_cfgRescaleController);
    if ((steps != null && (steps < 1 || steps > 50)) ||
        (scale != null && (scale < 1 || scale > 20)) ||
        (width == null) != (height == null) ||
        (width != null && (width <= 0 || width % 64 != 0)) ||
        (height != null && (height <= 0 || height % 64 != 0)) ||
        (cfgRescale != null && (cfgRescale < 0 || cfgRescale > 1))) {
      throw const FormatException();
    }
    final settings = PromptBlockGenerationSettings(
      model: _settingsModel,
      width: width,
      height: height,
      steps: steps,
      scale: scale,
      sampler: _settingsSampler,
      noiseSchedule: _settingsNoiseSchedule,
      cfgRescale: cfgRescale,
    );
    return settings.isEmpty ? null : settings;
  }

  String _sourceFileName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty);
    return segments.isEmpty ? sourcePath : segments.last;
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _folderLabel(
    PromptBlockFolder folder,
    List<PromptBlockFolder> folders,
  ) {
    var depth = 0;
    final byId = <String, PromptBlockFolder>{
      for (final item in folders) item.id: item,
    };
    final visited = <String>{};
    String? parentId = folder.parentId;
    while (parentId != null && visited.add(parentId)) {
      depth++;
      parentId = byId[parentId]?.parentId;
    }
    final name = folder.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedFolder
        : folder.name;
    return '${'  ' * depth}$name';
  }
}
