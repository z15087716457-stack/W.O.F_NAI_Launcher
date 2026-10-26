import 'dart:async';
import 'dart:io';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/local_gallery_focus_provider.dart';
import '../../providers/local_gallery_provider.dart';
import '../../themes/studio_typography.dart';
import '../../utils/local_gallery_metadata_resolver.dart';
import '../common/app_toast.dart';
import '../common/studio_icons.dart';
import '../common/image_detail/components/detail_prompt_section.dart';
import 'local_image_context_menu.dart';

/// 详情面板宽度
const double galleryInspectorWidth = 340;

/// 本地画廊右侧详情面板：预览、文件信息、生成参数、提示词与复用入口。
///
/// 展示当前查看（单击）的图片；记录未加载时先读取，索引里没有元数据时
/// 再从文件解析。
class GalleryInspectorPanel extends ConsumerStatefulWidget {
  const GalleryInspectorPanel({
    super.key,
    required this.onAction,
    required this.onOpenViewer,
    required this.onClose,
    required this.onFavoriteMenu,
  });

  /// 复用参数、发送、在文件夹中显示、删除等操作（由宿主执行确认与跳转）
  final Future<void> Function(
    LocalImageRecord record,
    LocalImageContextAction action,
  )
  onAction;
  final void Function(String path) onOpenViewer;
  final VoidCallback onClose;
  final void Function(LocalImageRecord record, Offset anchor) onFavoriteMenu;

  @override
  ConsumerState<GalleryInspectorPanel> createState() =>
      _GalleryInspectorPanelState();
}

class _GalleryInspectorPanelState extends ConsumerState<GalleryInspectorPanel> {
  String? _loadedPath;
  LocalImageRecord? _loadedRecord;
  NaiImageMetadata? _metadata;
  bool _loading = false;
  bool _negativeExpanded = false;
  int _loadSerial = 0;

  void _ensureLoaded(String? path, LocalImageRecord? cached) {
    final pathChanged = path != _loadedPath;
    if (!pathChanged &&
        cached?.metadata == _loadedRecord?.metadata &&
        cached?.modifiedAt == _loadedRecord?.modifiedAt &&
        cached?.size == _loadedRecord?.size) {
      return;
    }
    _loadedPath = path;
    _loadedRecord = cached;
    final serial = ++_loadSerial;
    _metadata = cached?.metadata?.upgradeFromRawJsonIfNeeded();
    if (_metadata?.hasData != true) _metadata = null;
    if (pathChanged) _negativeExpanded = false;
    _loading = false;
    if (path == null || (!pathChanged && _metadata != null)) return;
    _loading = true;
    unawaited(() async {
      var record = cached;
      if (pathChanged || record == null) {
        final notifier = ref.read(localGalleryNotifierProvider.notifier);
        final records = await notifier.loadRecords([path]);
        if (!mounted || serial != _loadSerial) return;
        _loadedRecord = notifier.cachedRecord(path);
        record = _loadedRecord ?? records.firstOrNull;
      }
      var metadata = record?.metadata?.upgradeFromRawJsonIfNeeded();
      if (record != null && metadata?.hasData != true) {
        metadata = await resolveLocalGalleryMetadata(record);
      }
      if (!mounted || serial != _loadSerial) return;
      setState(() {
        _metadata = metadata?.hasData == true ? metadata : null;
        _loading = false;
      });
    }());
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppToast.success(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final focused = ref.watch(localGalleryFocusNotifierProvider);
    ref.watch(localGalleryNotifierProvider.select((s) => s.recordsRevision));
    final timeline = ref.watch(
      localGalleryNotifierProvider.select((s) => s.timeline),
    );
    final resultCount = ref.watch(
      localGalleryNotifierProvider.select((s) => s.resultCount),
    );
    final notifier = ref.read(localGalleryNotifierProvider.notifier);
    final cached = focused == null ? null : notifier.cachedRecord(focused);
    _ensureLoaded(focused, cached);
    final index = focused == null ? -1 : timeline.indexOfPath(focused);
    final record = focused == null
        ? null
        : cached ??
              (index >= 0 ? notifier.recordFor(timeline.entries[index]) : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          _buildHeader(context, record, index, resultCount),
          Expanded(
            child: record == null
                ? _buildEmpty(context)
                : _buildBody(context, record, index),
          ),
          if (record != null) _buildFooter(context, record),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LocalImageRecord? record,
    int index,
    int resultCount,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 6),
        child: Row(
          children: [
            Text(
              l10n.localGallery_inspectorTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (record != null && index >= 0) ...[
              const SizedBox(width: 8),
              Text(
                l10n.localGallery_inspectorPosition(
                  number.format(index + 1),
                  number.format(resultCount),
                ),
                style: StudioTypography.data.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            if (record != null) ...[
              Builder(
                builder: (buttonContext) => _HeaderButton(
                  icon: record.isFavorite
                      ? StudioIcons.galleryHeartFilled
                      : StudioIcons.galleryHeart,
                  tooltip: l10n.common_favorite,
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    widget.onFavoriteMenu(
                      record,
                      box.localToGlobal(Offset.zero),
                    );
                  },
                ),
              ),
              _HeaderButton(
                icon: StudioIcons.galleryReveal,
                tooltip: l10n.localGallery_showInFolder,
                onPressed: () => widget.onAction(
                  record,
                  LocalImageContextAction.showInFolder,
                ),
              ),
              _HeaderButton(
                icon: StudioIcons.galleryTrash,
                tooltip: l10n.common_delete,
                onPressed: () =>
                    widget.onAction(record, LocalImageContextAction.delete),
              ),
            ],
            _HeaderButton(
              icon: StudioIcons.galleryClose,
              tooltip: l10n.localGallery_hideInspector,
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              StudioIcons.galleryImage,
              size: 32,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.localGallery_inspectorEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.localGallery_inspectorEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LocalImageRecord record, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final metadata = _metadata;
    final timeline = ref.read(localGalleryNotifierProvider).timeline;
    final entry = index >= 0 ? timeline.entries[index] : null;
    final width = entry?.width ?? metadata?.width;
    final height = entry?.height ?? metadata?.height;
    final modified = record.size > 0 ? record.modifiedAt : entry?.modifiedAt;
    final folder = p.dirname(record.path);
    final mono = StudioTypography.data.copyWith(
      fontSize: 12.5,
      color: colors.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) => ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.94, 1],
          colors: [Colors.black, Colors.black, Colors.transparent],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _Preview(
              path: record.path,
              // 矮窗口压缩预览，给参数与提示词留出空间
              height: (constraints.maxHeight * 0.4).clamp(150.0, 250.0),
              onOpen: () => widget.onOpenViewer(record.path),
            ),
            const SizedBox(height: 12),
            SelectableText(
              p.basename(record.path),
              minLines: 1,
              maxLines: 2,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  StudioIcons.galleryFolder,
                  size: 13,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Tooltip(
                    message: folder,
                    waitDuration: const Duration(milliseconds: 600),
                    child: Text(
                      folder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoTable(
              rows: [
                if (width != null && height != null)
                  (l10n.gallery_metaResolution, '$width × $height', true),
                if (record.size > 0)
                  (l10n.detail_fileSize, _formatSize(record.size), true),
                if (modified != null)
                  (
                    l10n.detail_modifiedTime,
                    DateFormat('yyyy-MM-dd HH:mm', locale).format(modified),
                    true,
                  ),
                if (metadata != null && _modelName(metadata) != null)
                  (l10n.gallery_metaModel, _modelName(metadata)!, false),
              ],
            ),
            if (_loading && metadata == null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  l10n.detail_parsingMetadata,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else if (metadata == null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  l10n.detail_noMetadata,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              _SectionTitle(label: l10n.gallery_generationParams),
              _ParamGrid(
                items: [
                  if (metadata.seed != null)
                    (
                      l10n.gallery_metaSeed,
                      '${metadata.seed}',
                      () => _copy(
                        '${metadata.seed}',
                        l10n.localGallery_seedCopied,
                      ),
                    ),
                  if (metadata.sampler != null)
                    (
                      l10n.gallery_metaSampler,
                      Samplers.samplerDisplayNames[metadata.sampler] ??
                          metadata.displaySampler,
                      null,
                    ),
                  if (metadata.steps != null)
                    (l10n.gallery_metaSteps, '${metadata.steps}', null),
                  if (metadata.scale != null)
                    (
                      l10n.gallery_metaCfgScale,
                      _formatNumber(metadata.scale!),
                      null,
                    ),
                ],
                style: mono,
              ),
              if (metadata.prompt.isNotEmpty) ...[
                PromptSection(
                  key: ValueKey('gallery-prompt-${record.path}-positive'),
                  title: l10n.prompt_positivePrompt,
                  icon: Icons.text_fields,
                  content: metadata.prompt,
                  inspectorStyle: true,
                  contentStyle: mono,
                  onCopy: () =>
                      _copy(metadata.prompt, l10n.localGallery_promptCopied),
                ),
              ],
              for (var i = 0; i < metadata.characterPrompts.length; i++)
                if (metadata.characterPrompts[i].trim().isNotEmpty) ...[
                  PromptSection(
                    key: ValueKey('gallery-prompt-${record.path}-character-$i'),
                    title: l10n.character_number(i + 1),
                    icon: Icons.person_outline,
                    content: metadata.characterPrompts[i],
                    inspectorStyle: true,
                    contentStyle: mono,
                    onCopy: () => _copy(
                      metadata.characterPrompts[i],
                      l10n.toast_characterPromptCopied,
                    ),
                  ),
                ],
              if (metadata.displayNegativePrompt.isNotEmpty) ...[
                PromptSection(
                  key: ValueKey('gallery-prompt-${record.path}-negative'),
                  title: l10n.prompt_negativePrompt,
                  icon: Icons.block,
                  content: metadata.displayNegativePrompt,
                  inspectorStyle: true,
                  contentStyle: mono,
                  previewLines: _negativeExpanded ? null : 3,
                  onCopy: () =>
                      _copy(metadata.displayNegativePrompt, l10n.common_copied),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _negativeExpanded = !_negativeExpanded),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.bodySmall,
                    ),
                    child: Text(
                      _negativeExpanded
                          ? l10n.common_collapse
                          : l10n.common_expand,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, LocalImageRecord record) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).height < 820;
    final l10n = context.l10n;
    final isKritaConnected = ref.watch(
      kritaBridgeNotifierProvider.select(
        (state) => state.status == KritaBridgeStatus.connected,
      ),
    );
    Future<void> run(LocalImageContextAction action) =>
        widget.onAction(record, action);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('gallery-inspector-reuse'),
            onPressed: () => run(LocalImageContextAction.sendToTextToImage),
            icon: const Icon(StudioIcons.gallerySpark, size: 16),
            label: Text(l10n.localGallery_reuseParams),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: compact ? 2.3 : 1.75,
            children: [
              _ActionTile(
                icon: StudioIcons.imageToImage,
                label: l10n.localGallery_actionImg2Img,
                tooltip: l10n.localGallery_sendToImg2Img,
                onTap: () => run(LocalImageContextAction.sendToImg2Img),
              ),
              _ActionTile(
                icon: StudioIcons.styleTransfer,
                label: l10n.localGallery_actionStyleTransfer,
                tooltip: l10n.localGallery_sendToStyleTransfer,
                onTap: () => run(LocalImageContextAction.sendToStyleTransfer),
              ),
              _ActionTile(
                icon: StudioIcons.referenceFocus,
                label: l10n.localGallery_actionPreciseReference,
                tooltip: l10n.localGallery_sendToPreciseReference,
                onTap: () =>
                    run(LocalImageContextAction.sendToPreciseReference),
              ),
              _ActionTile(
                icon: StudioIcons.galleryBookmarkAdd,
                label: l10n.localGallery_actionSaveReference,
                tooltip: l10n.localGallery_saveToPreciseRefLibrary,
                onTap: () =>
                    run(LocalImageContextAction.saveToPreciseRefLibrary),
              ),
              _ActionTile(
                icon: StudioIcons.galleryBrush,
                label: l10n.localGallery_actionKrita,
                tooltip: l10n.localGallery_sendToKrita,
                onTap: isKritaConnected
                    ? () => run(LocalImageContextAction.sendToKrita)
                    : null,
              ),
              _ActionTile(
                icon: StudioIcons.galleryUpscale,
                label: l10n.gallery_upscale,
                tooltip: l10n.gallery_upscale,
                onTap: () => run(LocalImageContextAction.upscale),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _modelName(NaiImageMetadata metadata) {
    final model = metadata.effectiveModel;
    if (model != null && ImageModels.modelDisplayNames.containsKey(model)) {
      return ImageModels.modelDisplayNames[model];
    }
    final source = metadata.source?.trim();
    if (source != null && source.isNotEmpty) {
      return source.replaceAll(RegExp(r'\s+[0-9A-F]{8}$'), '');
    }
    return model;
  }

  static String _formatNumber(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.path,
    required this.height,
    required this.onOpen,
  });

  final String path;
  final double height;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          cursor: SystemMouseCursors.zoomIn,
          child: GestureDetector(
            key: const Key('gallery-inspector-preview'),
            onTap: onOpen,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image(
                image: ResizeImage(
                  FileImage(File(path)),
                  width: (width * dpr * 1.25).round(),
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.rows});

  /// (标签, 值, 是否等宽数字)
  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        for (final (label, value, mono) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: mono
                        ? StudioTypography.data.copyWith(
                            fontSize: 12.5,
                            color: colors.onSurface,
                          )
                        : theme.textTheme.bodySmall?.copyWith(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamGrid extends StatelessWidget {
  const _ParamGrid({required this.items, required this.style});

  /// (标签, 值, 复制回调)
  final List<(String, String, VoidCallback?)> items;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 6) / 2;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, value, onCopy) in items)
              Container(
                width: cellWidth,
                padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.copyWith(fontSize: 13),
                          ),
                        ),
                        if (onCopy != null)
                          InkWell(
                            onTap: onCopy,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                StudioIcons.galleryCopy,
                                size: 13,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;
    final foreground = enabled
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.5);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
