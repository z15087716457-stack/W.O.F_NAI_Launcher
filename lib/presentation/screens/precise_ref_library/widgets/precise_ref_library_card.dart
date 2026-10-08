import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/precise_ref_type.dart';
import '../../../../core/extensions/precise_ref_type_extensions.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/precise_ref/precise_ref_library_entry.dart';
import '../../../../data/services/precise_ref_library_storage_service.dart';
import '../../../widgets/library/library_widgets.dart';

/// Library-only presentation wrapper. Selecting never sends an image.
class PreciseRefLibraryCard extends ConsumerStatefulWidget {
  const PreciseRefLibraryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.isSelected = false,
    this.checkbox,
    this.onSendToPreciseRef,
    this.onSendToImg2Img,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
  });
  final PreciseRefLibraryEntry entry;
  final VoidCallback? onTap,
      onDoubleTap,
      onLongPress,
      onSendToPreciseRef,
      onSendToImg2Img,
      onEdit,
      onDelete,
      onToggleFavorite;
  final GestureTapDownCallback? onSecondaryTapDown;
  final bool isSelected;
  final bool? checkbox;
  @override
  ConsumerState<PreciseRefLibraryCard> createState() =>
      _PreciseRefLibraryCardState();
}

class _PreciseRefLibraryCardState extends ConsumerState<PreciseRefLibraryCard> {
  Uint8List? _thumbnail;
  bool _requested = false, _failed = false;
  @override
  void didUpdateWidget(covariant PreciseRefLibraryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _thumbnail = null;
      _requested = false;
      _failed = false;
    }
  }

  void _load() {
    if (_requested) return;
    _requested = true;
    final id = widget.entry.id;
    ref
        .read(preciseRefLibraryStorageServiceProvider)
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
        });
  }

  @override
  Widget build(BuildContext context) {
    _load();
    final entry = widget.entry,
        colors = LibraryStatusColors(Theme.of(context)),
        l10n = context.l10n;
    final name = entry.type.getDisplayName(
      character: l10n.preciseRef_typeCharacter,
      style: l10n.preciseRef_typeStyle,
      characterAndStyle: l10n.preciseRef_typeCharacterAndStyle,
    );
    return LibraryCard(
      thumbnail: _thumbnail,
      title: entry.name,
      hasError: _failed,
      isSelected: widget.isSelected,
      checkbox: widget.checkbox,
      isFavorite: entry.isFavorite,
      imageAlignment: const Alignment(0, -.6),
      trailingBadge: LibraryStatusBadge(
        label: name,
        typeStyle: true,
        icon: switch (entry.type) {
          PreciseRefType.character => 'person',
          PreciseRefType.style => 'palette',
          PreciseRefType.characterAndStyle => 'both',
        },
        color: switch (entry.type) {
          PreciseRefType.character => colors.character,
          PreciseRefType.style => colors.style,
          PreciseRefType.characterAndStyle => colors.both,
        },
      ),
      metaLine: Text(
        '${l10n.library_strength} ${entry.strength.toStringAsFixed(2)}  ${l10n.library_fidelity} ${entry.fidelity.toStringAsFixed(2)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onFavoriteToggle: widget.onToggleFavorite,
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
                label: l10n.preciseRefLib_sendToPreciseRef,
                icon: 'plus',
                primary: true,
                onPressed: widget.onSendToPreciseRef,
              ),
            ),
          ),
          PopupMenuButton<int>(
            tooltip: l10n.library_more,
            onSelected: (i) => [
              widget.onSendToImg2Img,
              widget.onEdit,
              widget.onDelete,
            ][i]?.call(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 0,
                child: Text(l10n.preciseRefLib_sendToImg2Img),
              ),
              PopupMenuItem(
                value: 1,
                child: Text(l10n.preciseRefLib_editEntry),
              ),
              PopupMenuItem(value: 2, child: Text(l10n.common_delete)),
            ],
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Center(child: LibraryIcon('more', color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
