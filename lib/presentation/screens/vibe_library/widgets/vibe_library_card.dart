import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/model_display.dart';
import '../../../../core/constants/model_spec.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/vibe/vibe_library_entry.dart';
import '../../../../data/models/vibe/vibe_reference.dart';
import '../../../../data/services/vibe_library_storage_service.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../widgets/library/library_widgets.dart';

enum VibeEncodingBadge { none, needsEncode, reencode, unavailable }

VibeEncodingBadge vibeEncodingBadgeFor(
  VibeLibraryEntry entry,
  ModelSpec modelSpec,
  String model, {
  bool? hasOriginalImage,
}) {
  if (!modelSpec.vibetransfer) return VibeEncodingBadge.none;
  if (entry.sourceType == VibeSourceType.rawImage) {
    return VibeEncodingBadge.needsEncode;
  }
  if (entry.encodingModel == null || entry.encodingModel == model) {
    return VibeEncodingBadge.none;
  }
  return hasOriginalImage == false
      ? VibeEncodingBadge.unavailable
      : VibeEncodingBadge.reencode;
}

class VibeLibraryCard extends ConsumerStatefulWidget {
  const VibeLibraryCard({
    super.key,
    required this.entry,
    this.isSelected = false,
    this.checkbox,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onFavoriteToggle,
    this.onSendToGeneration,
    this.onPreview,
    this.onMore,
  });
  final VibeLibraryEntry entry;
  final bool isSelected;
  final bool? checkbox;
  final VoidCallback? onTap,
      onDoubleTap,
      onLongPress,
      onFavoriteToggle,
      onSendToGeneration,
      onPreview,
      onMore;
  final GestureTapDownCallback? onSecondaryTapDown;
  @override
  ConsumerState<VibeLibraryCard> createState() => _VibeLibraryCardState();
}

class _VibeLibraryCardState extends ConsumerState<VibeLibraryCard> {
  Uint8List? _thumbnail;
  Future<void>? _pending;
  bool _requested = false, _failed = false;
  @override
  void didUpdateWidget(covariant VibeLibraryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _thumbnail = null;
      _pending = null;
      _requested = false;
      _failed = false;
    }
  }

  Uint8List? get _bytes {
    for (final bytes in [
      widget.entry.thumbnail,
      widget.entry.vibeThumbnail,
      _thumbnail,
    ]) {
      if (bytes != null && bytes.isNotEmpty) return bytes;
    }
    return null;
  }

  void _load() {
    if (_bytes != null || _pending != null || _requested) return;
    _requested = true;
    final id = widget.entry.id;
    _pending = ref
        .read(vibeLibraryStorageServiceProvider)
        .getDisplayThumbnail(id)
        .then((bytes) {
          if (mounted && widget.entry.id == id) {
            setState(() {
              _thumbnail = bytes;
              _failed = bytes == null;
            });
          }
        })
        .catchError((Object error) {
          if (mounted && widget.entry.id == id) setState(() => _failed = true);
        })
        .whenComplete(() {
          if (mounted && widget.entry.id == id) _pending = null;
        });
  }

  @override
  Widget build(BuildContext context) {
    _load();
    final params = ref.watch(generationParamsNotifierProvider);
    final entry = widget.entry, status = LibraryStatusColors(Theme.of(context));
    final badge = vibeEncodingBadgeFor(
      entry,
      ModelSpecs.of(params.model),
      params.model,
    );
    return LibraryCard(
      title: entry.displayName,
      thumbnail: _bytes,
      hasError: _failed,
      isSelected: widget.isSelected,
      checkbox: widget.checkbox,
      isFavorite: entry.isFavorite,
      bundleCount: entry.isBundle ? entry.bundledVibeCount : 0,
      bundleBackThumbnails: (entry.bundledVibePreviews ?? const <Uint8List>[])
          .take(2)
          .toList(),
      trailingBadge: badge == VibeEncodingBadge.none
          ? null
          : LibraryStatusBadge(
              label: switch (badge) {
                VibeEncodingBadge.needsEncode =>
                  context.l10n.library_encodeOnUse,
                VibeEncodingBadge.reencode => context.l10n.library_reencode,
                VibeEncodingBadge.unavailable =>
                  context.l10n.library_unusableModel(
                    ModelDisplay.shortNameOf(params.model),
                  ),
                VibeEncodingBadge.none => '',
              },
              color: badge == VibeEncodingBadge.unavailable
                  ? status.error
                  : status.warn,
              icon: 'bolt',
            ),
      metaLine: Text(
        '${context.l10n.library_strength} ${entry.strength.toStringAsFixed(2)}  '
        '${context.l10n.library_information} ${entry.infoExtracted.toStringAsFixed(2)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onFavoriteToggle: widget.onFavoriteToggle,
      onRetry: () => setState(() {
        _requested = false;
        _failed = false;
      }),
      hoverActions: LibraryHoverActionBar(
        children: [
          Expanded(
            child: LibraryActionButton(
              height: 28,
              action: LibraryAction(
                label: context.l10n.library_addToGeneration,
                icon: 'plus',
                onPressed: widget.onSendToGeneration,
                primary: true,
              ),
            ),
          ),
          LibraryActionButton(
            height: 28,
            iconOnly: true,
            dark: true,
            action: LibraryAction(
              label: context.l10n.library_preview,
              icon: 'eye',
              onPressed: widget.onPreview,
            ),
          ),
          Builder(
            builder: (buttonContext) => LibraryActionButton(
              height: 28,
              iconOnly: true,
              dark: true,
              action: LibraryAction(
                label: context.l10n.library_more,
                icon: 'more',
                onPressed: () {
                  final box = buttonContext.findRenderObject() as RenderBox?;
                  if (box != null && widget.onSecondaryTapDown != null) {
                    widget.onSecondaryTapDown!(
                      TapDownDetails(
                        globalPosition: box.localToGlobal(
                          Offset(0, box.size.height),
                        ),
                      ),
                    );
                  } else {
                    widget.onMore?.call();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
