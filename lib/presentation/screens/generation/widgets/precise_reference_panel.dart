import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../../../core/enums/precise_ref_type.dart';
import '../../../../../core/extensions/precise_ref_type_extensions.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/image_params.dart';
import '../../../../data/services/precise_ref_library_storage_service.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/precise_ref_library_provider.dart';
import '../../../utils/dropped_file_reader.dart';
import '../../../utils/precise_ref_library_import_helper.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/editable_double_field.dart';
import '../../../widgets/common/hover_image_preview.dart';
import '../../../widgets/common/precise_reference_type_dialog.dart';
import '../../../widgets/common/themed_divider.dart';
import '../../../widgets/common/collapsible_image_panel.dart';
import '../../../widgets/common/decoded_memory_image.dart';
import '../../precise_ref_library/widgets/precise_ref_selector_dialog.dart';

const double _disabledPreciseReferenceCardOpacity = 0.48;

/// Precise Reference 面板 - 支持多参考、类型选择、独立参数控制
///

/// 功能特性：
/// - 支持添加多个参考图（类似 Vibe Transfer）
/// - 每个参考可独立设置：类型、强度、保真度
/// - 类型可选：Character / Style / Character & Style
/// - 不与 Vibe Transfer 互斥，可同时使用
class PreciseReferencePanel extends ConsumerStatefulWidget {
  const PreciseReferencePanel({super.key});

  @override
  ConsumerState<PreciseReferencePanel> createState() =>
      _PreciseReferencePanelState();
}

class _PreciseReferencePanelState extends ConsumerState<PreciseReferencePanel> {
  bool _isExpanded = false;
  bool _isFileDraggingOver = false;
  bool _isProcessingDroppedFiles = false;

  @override
  Widget build(BuildContext context) {
    // Precise Reference 仅 V4.5 家族支持（V4.0 与 V5 均无此能力），
    // 不支持时整行隐藏（官网式：不渲染不可用的参考行）。
    final supportsPreciseRef = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.modelSpec.characterReferences,
      ),
    );
    if (!supportsPreciseRef) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final references = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.preciseReferences,
      ),
    );
    final hasReferences = references.isNotEmpty;
    final activeReferenceCount = references
        .where((reference) => reference.enabled)
        .length;
    final hasActiveReferences = activeReferenceCount > 0;

    // 判断是否显示背景（折叠且有数据时显示）
    final showBackground = hasReferences && !_isExpanded;

    return CollapsibleImagePanel(
      title: context.l10n.preciseRef_title,
      subtitle: context.l10n.preciseRef_subtitle,
      icon: Icons.person_pin,
      iconAsset: 'assets/icons/nai-icon-precise-reference.svg',
      isExpanded: _isExpanded,
      onToggle: () => setState(() => _isExpanded = !_isExpanded),
      hasData: hasReferences,
      headerActions: _buildHeaderActions(
        theme,
        showBackground: showBackground,
        hasReferences: hasReferences,
      ),
      backgroundImage: showBackground
          ? (references.length == 1
                ? DecodedMemoryImage(
                    bytes: references.first.image,
                    fit: BoxFit.cover,
                    decodeScale: 0.75,
                  )
                : Row(
                    children: references.map((ref) {
                      return Expanded(
                        child: DecodedMemoryImage(
                          bytes: ref.image,
                          fit: BoxFit.cover,
                          decodeScale: 0.75,
                        ),
                      );
                    }).toList(),
                  ))
          : null,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: showBackground
              ? Colors.white.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${references.length}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: showBackground
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ),
      // 当有参考图时显示点数消耗提示（显眼样式）
      trailing: hasActiveReferences
          ? Tooltip(
              message: context.l10n.preciseRef_costHint,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: showBackground
                      ? Colors.orange.withValues(alpha: 0.9)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: showBackground
                        ? Colors.orange.shade300
                        : Colors.orange.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: showBackground
                          ? Colors.white
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      context.l10n.preciseRef_costBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: showBackground
                            ? Colors.white
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThemedDivider(),

            // 说明文字
            Text(
              context.l10n.preciseRef_description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),

            // 参考列表
            if (hasReferences) ...[
              ...List.generate(references.length, (index) {
                return _PreciseReferenceCard(
                  index: index,
                  reference: references[index],
                  onRemove: () => _removeReference(index),
                  onSaveToLibrary: () =>
                      _saveSingleReferenceToLibrary(references[index]),
                  onEnabledChanged: (value) =>
                      _updateReferenceEnabled(index, value),
                  onTypeChanged: (type) => _updateReferenceType(index, type),
                  onStrengthChanged: (value) =>
                      _updateReferenceStrength(index, value),
                  onFidelityChanged: (value) =>
                      _updateReferenceFidelity(index, value),
                );
              }),
              const SizedBox(height: 8),
            ],

            // 添加按钮
            _buildAddReferenceDropTarget(
              child: OutlinedButton.icon(
                onPressed: _addReference,
                icon: Icon(
                  _isFileDraggingOver ? Icons.file_download_rounded : Icons.add,
                  size: 16,
                ),
                label: Text(
                  _isFileDraggingOver
                      ? context.l10n.preciseRef_dropToAdd
                      : context.l10n.preciseRef_addReference,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 34),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

            // 清除全部按钮
            if (hasReferences) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _clearAllReferences,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text(context.l10n.preciseRef_clearAll),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 头部操作列：保存到库（文本钮）+ 方形“添加”钮（弹出 添加参考图/从库导入）。
  List<Widget> _buildHeaderActions(
    ThemeData theme, {
    required bool showBackground,
    required bool hasReferences,
  }) {
    final foreground = showBackground
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;
    return [
      TextButton.icon(
        key: const Key('precise-ref-panel-save-to-library'),
        onPressed: hasReferences ? _saveReferencesToLibrary : null,
        icon: SvgPicture.asset(
          'assets/icons/nai-icon-save.svg',
          width: 13,
          height: 13,
          colorFilter: ColorFilter.mode(
            hasReferences ? foreground : foreground.withValues(alpha: 0.38),
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          context.l10n.preciseRefLib_saveCurrentToLibrary,
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: showBackground
              ? Colors.white
              : theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      Builder(
        builder: (buttonContext) => PanelHeaderIconButton(
          key: const Key('precise-ref-panel-add-menu'),
          iconAsset: 'assets/icons/nai-icon-rounded-plus.svg',
          tooltip: context.l10n.preciseRef_addReference,
          color: foreground,
          onPressed: () => _showAddMenu(buttonContext),
        ),
      ),
    ];
  }

  /// 方形钮正下方弹出 添加参考图 / 从库导入 菜单（官网式）。
  void _showAddMenu(BuildContext buttonContext) {
    final overlayBox =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()
            as RenderBox;
    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    // 锚点矩形必须在 overlay 坐标系内（ancestor: overlayBox）；
    // 用全局坐标而 overlay 有偏移时菜单会整体向右下方漂移。
    var triggerRect = Rect.fromPoints(
      buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      buttonBox.localToGlobal(
        buttonBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    );

    showMenu<String>(
      context: buttonContext,
      constraints: const BoxConstraints.tightFor(width: 208),
      // The plus sits on the right of the sidebar: align the menu's right edge
      // to it, instead of letting a wide window place the menu outside the pane.
      positionBuilder: (context, constraints) {
        if (buttonBox.attached) {
          triggerRect = Rect.fromPoints(
            buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
            buttonBox.localToGlobal(
              buttonBox.size.bottomRight(Offset.zero),
              ancestor: overlayBox,
            ),
          );
        }
        return RelativeRect.fromRect(
          Rect.fromLTWH(
            triggerRect.right - 208,
            triggerRect.bottom + 4,
            208,
            0,
          ),
          Offset.zero & overlayBox.size,
        );
      },
      items: [
        PopupMenuItem<String>(
          value: 'add',
          height: 40,
          child: Text(context.l10n.preciseRef_addReference),
        ),
        PopupMenuItem<String>(
          key: const Key('precise-ref-panel-from-library'),
          value: 'library',
          height: 40,
          child: Text(context.l10n.preciseRefLib_fromLibrary),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      switch (value) {
        case 'add':
          unawaited(_addReference());
        case 'library':
          unawaited(_importFromLibrary());
      }
    });
  }

  Widget _buildAddReferenceDropTarget({required Widget child}) {
    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (_isProcessingDroppedFiles) {
          return DropOperation.none;
        }
        if (event.session.allowedOperations.contains(DropOperation.copy)) {
          if (!_isFileDraggingOver) {
            setState(() => _isFileDraggingOver = true);
          }
          return DropOperation.copy;
        }
        return DropOperation.none;
      },
      onDropLeave: (_) {
        if (_isFileDraggingOver) {
          setState(() => _isFileDraggingOver = false);
        }
      },
      onPerformDrop: (event) async {
        setState(() => _isFileDraggingOver = false);
        unawaited(_handleDroppedReferences(event));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: _isFileDraggingOver
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: child,
      ),
    );
  }

  /// 从精准参考库导入条目（套用条目记住的类型与参数）
  Future<void> _importFromLibrary() async {
    final selected = await PreciseRefSelectorDialog.show(context);
    if (selected == null || selected.isEmpty || !mounted) return;

    final storage = ref.read(preciseRefLibraryStorageServiceProvider);
    final notifier = ref.read(generationParamsNotifierProvider.notifier);
    final libraryNotifier = ref.read(
      preciseRefLibraryNotifierProvider.notifier,
    );

    final futures = <Future<void>>[];
    var added = 0;
    for (final entry in selected) {
      final bytes = await storage.readImageBytes(entry.id);
      if (bytes == null) continue;
      futures.add(
        notifier.addPreciseReferenceFromImage(
          bytes,
          type: entry.type,
          strength: entry.strength,
          fidelity: entry.fidelity,
        ),
      );
      unawaited(libraryNotifier.recordUsage(entry.id));
      added++;
    }
    await Future.wait(futures);

    if (!mounted) return;
    if (added > 0) {
      AppToast.success(context, context.l10n.preciseRef_addedCount(added));
    }
    if (added < selected.length) {
      AppToast.warning(context, context.l10n.preciseRefLib_imageMissing);
    }
  }

  /// 把单张参考图（含类型与参数）保存到精准参考库
  Future<void> _saveSingleReferenceToLibrary(PreciseReference reference) async {
    try {
      final entry = await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .importFromBytes(
            reference.image,
            name: defaultPreciseRefName(),
            type: reference.type,
            strength: reference.strength,
            fidelity: reference.fidelity,
          );
      if (!mounted) return;
      AppToast.success(context, context.l10n.preciseRefLib_saved(entry.name));
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, preciseRefImportErrorMessage(context, e));
    }
  }

  /// 把当前参考图（含各自类型与参数）保存到精准参考库
  Future<void> _saveReferencesToLibrary() async {
    final references = ref
        .read(generationParamsNotifierProvider)
        .preciseReferences;
    if (references.isEmpty) return;

    final PreciseRefLibraryBatchImportResult batch;
    try {
      batch = await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .importMany([
            for (final reference in references)
              PreciseRefLibraryImportSource(
                loadBytes: () async => reference.image,
                name: defaultPreciseRefName(),
                type: reference.type,
                strength: reference.strength,
                fidelity: reference.fidelity,
              ),
          ]);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, preciseRefImportErrorMessage(context, e));
      return;
    }

    if (!mounted) return;
    if (batch.importedCount > 0) {
      AppToast.success(
        context,
        context.l10n.preciseRefLib_saveCurrentCount(batch.importedCount),
      );
    }
    if (batch.failedCount > 0) {
      AppToast.error(
        context,
        context.l10n.preciseRefLib_importFailedCount(batch.failedCount),
      );
    }
  }

  Future<void> _addReference() async {
    // 先选择类型
    final selectedType = await PreciseReferenceTypeDialog.show(context);
    if (selectedType == null) return; // 用户取消了类型选择

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final notifier = ref.read(generationParamsNotifierProvider.notifier);
        final addOperations = <Future<void>>[];

        for (final file in result.files) {
          final bytes = await _readPickedImageBytes(file);
          if (bytes == null) {
            continue;
          }

          addOperations.add(
            notifier.addPreciseReferenceFromImage(
              bytes,
              type: selectedType,
              strength: 1.0,
              fidelity: 1.0,
            ),
          );
        }

        await Future.wait(addOperations);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.img2img_selectFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _handleDroppedReferences(PerformDropEvent event) async {
    if (_isProcessingDroppedFiles) {
      return;
    }

    setState(() => _isProcessingDroppedFiles = true);
    try {
      final files = <DroppedFileData>[];
      for (final item in event.session.items) {
        final reader = item.dataReader;
        if (reader == null) {
          continue;
        }

        final file = await DroppedFileReader.read(
          reader,
          logTag: 'PreciseReferenceDrop',
        );
        if (file != null) {
          files.add(file);
        }
      }

      if (!mounted) {
        return;
      }

      if (files.isEmpty) {
        AppToast.warning(context, context.l10n.preciseRef_dropNoReadableImage);
        return;
      }

      final selectedType = await PreciseReferenceTypeDialog.show(context);
      if (selectedType == null || !mounted) {
        return;
      }

      final notifier = ref.read(generationParamsNotifierProvider.notifier);
      final addOperations = files.map(
        (file) => notifier.addPreciseReferenceFromImage(
          file.bytes,
          type: selectedType,
          strength: 1.0,
          fidelity: 1.0,
        ),
      );
      await Future.wait(addOperations);

      if (mounted) {
        AppToast.success(
          context,
          context.l10n.preciseRef_addedCount(files.length),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.img2img_selectFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingDroppedFiles = false);
      }
    }
  }

  Future<Uint8List?> _readPickedImageBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes;
    }

    final path = file.path;
    if (path == null) {
      return null;
    }

    return File(path).readAsBytes();
  }

  void _removeReference(int index) {
    ref
        .read(generationParamsNotifierProvider.notifier)
        .removePreciseReference(index);
  }

  void _updateReferenceType(int index, PreciseRefType type) {
    ref
        .read(generationParamsNotifierProvider.notifier)
        .updatePreciseReferenceType(index, type);
  }

  void _updateReferenceEnabled(int index, bool value) {
    ref
        .read(generationParamsNotifierProvider.notifier)
        .updatePreciseReference(index, enabled: value);
  }

  void _updateReferenceStrength(int index, double value) {
    ref
        .read(generationParamsNotifierProvider.notifier)
        .updatePreciseReference(index, strength: value);
  }

  void _updateReferenceFidelity(int index, double value) {
    ref
        .read(generationParamsNotifierProvider.notifier)
        .updatePreciseReference(index, fidelity: value);
  }

  void _clearAllReferences() {
    final params = ref.read(generationParamsNotifierProvider);
    final count = params.preciseReferences.length;

    ref
        .read(generationParamsNotifierProvider.notifier)
        .clearPreciseReferences();

    if (mounted && count > 0) {
      AppToast.success(context, context.l10n.preciseRef_removedCount(count));
    }
  }
}

/// Precise Reference 卡片组件
class _PreciseReferenceCard extends StatelessWidget {
  final int index;
  final PreciseReference reference;
  final VoidCallback onRemove;
  final VoidCallback onSaveToLibrary;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<PreciseRefType> onTypeChanged;
  final ValueChanged<double> onStrengthChanged;
  final ValueChanged<double> onFidelityChanged;

  const _PreciseReferenceCard({
    required this.index,
    required this.reference,
    required this.onRemove,
    required this.onSaveToLibrary,
    required this.onEnabledChanged,
    required this.onTypeChanged,
    required this.onStrengthChanged,
    required this.onFidelityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: AnimatedOpacity(
        key: ValueKey('precise-reference-enabled-opacity-$index'),
        opacity: reference.enabled ? 1.0 : _disabledPreciseReferenceCardOpacity,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部行：缩略图、类型选择、删除按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：缩略图
                _buildThumbnail(theme),
                const SizedBox(width: 10),

                // 中间：类型选择
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEnabledToggle(context, theme),
                      const SizedBox(height: 6),
                      _buildTypeDropdown(context, theme),
                    ],
                  ),
                ),

                // 右侧：保存到库 + 删除按钮
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    key: Key('precise-reference-save-to-library-$index'),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.bookmark_add_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onSaveToLibrary,
                    tooltip: context.l10n.preciseRefLib_saveCurrentToLibrary,
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onRemove,
                    tooltip: context.l10n.preciseRef_remove,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 强度滑条
            _buildSliderRow(
              context,
              theme,
              label: context.l10n.preciseRef_strength,
              value: reference.strength,
              onChanged: onStrengthChanged,
            ),

            // 保真度滑条
            _buildSliderRow(
              context,
              theme,
              label: context.l10n.preciseRef_fidelity,
              value: reference.fidelity,
              onChanged: onFidelityChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 56,
        height: 56,
        color: theme.colorScheme.surfaceContainerHighest,
        child: DecodedMemoryImage(
          bytes: reference.image,
          fit: BoxFit.cover,
          maxLogicalWidth: 56,
          maxLogicalHeight: 56,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(theme);
          },
        ),
      ),
    );

    return HoverImagePreview(imageBytes: reference.image, child: thumbnail);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(Icons.person, size: 22, color: theme.colorScheme.outline),
    );
  }

  Widget _buildEnabledToggle(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.reference_enabled,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: reference.enabled
              ? context.l10n.reference_disable
              : context.l10n.reference_enable,
          child: Transform.scale(
            scale: 0.75,
            child: Switch(
              key: ValueKey('precise-reference-enabled-switch-$index'),
              value: reference.enabled,
              onChanged: onEnabledChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(BuildContext context, ThemeData theme) {
    return DropdownButtonFormField<PreciseRefType>(
      initialValue: reference.type,
      isDense: true,
      decoration: InputDecoration(
        labelText: context.l10n.preciseRef_referenceType,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      items: PreciseRefType.values.map((type) {
        return DropdownMenuItem<PreciseRefType>(
          value: type,
          child: Text(
            type.getDisplayName(
              character: context.l10n.preciseRef_typeCharacter,
              style: context.l10n.preciseRef_typeStyle,
              characterAndStyle: context.l10n.preciseRef_typeCharacterAndStyle,
            ),
            style: theme.textTheme.bodySmall,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onTypeChanged(value);
        }
      },
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final sliderValue = value.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签 + 数值
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            EditableDoubleField(
              value: value,
              decimals: 2,
              width: 64,
              onChanged: onChanged,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        // 滑条
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
          ),
          child: Slider(
            value: sliderValue,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
