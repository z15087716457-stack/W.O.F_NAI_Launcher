part of 'explore_adopt_block_dialog.dart';

class _AdoptState extends _AdoptController {
  static const _colors = [
    Color(0xff0064e2),
    Color(0xff6e56cf),
    Color(0xffd6336c),
    Color(0xffe8590c),
    Color(0xff2b9a66),
    Color(0xff0e7490),
    Color(0xff666666),
  ];
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final folder = library?.folders.any((f) => f.id == _folder) == true
        ? _folder
        : null;
    return ExploreDialogFrame(
      key: const Key('explore-adopt-block-dialog'),
      width: 560,
      top: 150,
      title: l.styleExplore_saveDialogTitle,
      icon: 'box',
      titleIcon: PromptBlockIconPicker(
        compactLabel: l.styleExplore_saveIcon,
        selected: _icon,
        compactIcon: _icon == null
            ? const ExploreIcon('box', size: 20)
            : Icon(promptBlockIconFromName(_icon), size: 20),
        onChanged: (v) => setState(() => _icon = v),
      ),
      footer: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: 12,
        overflowSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExploreIcon('info', size: 13, color: c.onSurfaceVariant),
              const SizedBox(width: 6),
              ExploreText(
                l.styleExplore_saveHint,
                style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExploreButton(
                label: l.common_cancel,
                height: 36,
                fontSize: 13.5,
                horizontal: 14,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              ExploreButton(
                key: const Key('explore-adopt-block-confirm'),
                label: l.styleExplore_saveBlock,
                height: 36,
                fontSize: 13.5,
                horizontal: 14,
                fontWeight: FontWeight.w600,
                color: c.onPrimary,
                background: c.primary,
                border: c.primary,
                onPressed: _title.text.trim().isNotEmpty && _atoms.isNotEmpty
                    ? _confirm
                    : null,
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final candidate in widget.candidates.take(8)) ...[
                SizedBox(
                  width: 44,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ExploreCandidateImage(
                      candidate: candidate,
                      sequenceNumber: widget.sequenceNumber,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: ExploreText(
                  widget.candidates.length == 1
                      ? l.styleExplore_saveSingleSubtitle(widget.sequenceNumber)
                      : l.styleExplore_saveManySubtitle(
                          widget.candidates.length,
                        ),
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ExploreText(
                l.styleExplore_saveContent,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final artists in [true, false])
                        Tooltip(
                          message: artists && !_hasDraws
                              ? l.styleExplore_saveNoDraws
                              : '',
                          child: ExploreButton(
                            key: Key(
                              artists
                                  ? 'explore-adopt-artists'
                                  : 'explore-adopt-full',
                            ),
                            label: artists
                                ? l.styleExplore_saveArtistsOnly
                                : l.styleExplore_saveFullPositive,
                            height: 28,
                            ghost: true,
                            radius: 5,
                            horizontal: 9,
                            fontWeight: _artists == artists
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _artists == artists
                                ? c.onSurface
                                : c.onSurfaceVariant,
                            background: _artists == artists
                                ? ExploreStyle.raised(t)
                                : Colors.transparent,
                            onPressed: artists && !_hasDraws
                                ? null
                                : () => setState(() => _artists = artists),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_hasDraws)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExploreText(
                l.styleExplore_saveNoDraws,
                style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 14),
          _label(l.styleExplore_saveRemoveAtoms),
          Container(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: ExploreStyle.panel(t),
              border: Border.all(color: c.outlineVariant),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [for (final atom in _atoms) _chip(atom)],
            ),
          ),
          if (_removed[_artists]!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  ExploreText(
                    l.styleExplore_saveRemoved(_removed[_artists]!.length),
                    style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  ExploreButton(
                    key: const Key('explore-adopt-restore'),
                    height: 28,
                    fontSize: 12,
                    label: l.styleExplore_saveRestore,
                    ghost: true,
                    color: c.primary,
                    onPressed: () =>
                        setState(() => _removed[_artists]!.clear()),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          _label(l.styleExplore_saveName),
          ExploreDialogFocusRing(
            child: SizedBox(
              height: 38,
              child: TextField(
                key: const Key('explore-adopt-block-name'),
                controller: _title,
                autofocus: true,
                style: const TextStyle(fontSize: 14, height: 1.45),
                textAlignVertical: TextAlignVertical.center,
                decoration: ExploreDialogFrame.inputDecoration(context),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirm(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(l.styleExplore_saveColor),
                  SizedBox(
                    height: 34,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _colors.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              right: i < _colors.length - 1 ? 6 : 0,
                            ),
                            child: Semantics(
                              button: true,
                              selected: _color == _colors[i],
                              child: GestureDetector(
                                key: ValueKey(
                                  'prompt-block-color-option-${promptBlockColorToHex(_colors[i])}',
                                ),
                                onTap: () =>
                                    setState(() => _color = _colors[i]),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _colors[i],
                                    shape: BoxShape.circle,
                                    boxShadow: _color == _colors[i]
                                        ? [
                                            BoxShadow(
                                              color: _colors[i],
                                              spreadRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: ExploreStyle.raised(t),
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(l.styleExplore_saveFolder),
                    SizedBox(
                      height: 34,
                      child: DropdownButtonFormField<String>(
                        key: const Key('explore-adopt-folder'),
                        initialValue: folder ?? '',
                        isExpanded: true,
                        style: TextStyle(fontSize: 12.5, color: c.onSurface),
                        icon: const ExploreIcon('chevD', size: 14),
                        decoration: ExploreDialogFrame.inputDecoration(context)
                            .copyWith(
                              filled: true,
                              fillColor: c.surfaceContainerHighest,
                              prefixIcon: const Center(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: ExploreIcon('folder', size: 14),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 34,
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: ExploreText(l.styleExplore_saveRoot),
                          ),
                          for (final f in library?.folders ?? [])
                            DropdownMenuItem(
                              value: f.id,
                              child: ExploreText(
                                library!.folderPath(f.id),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _folder = value == '' ? null : value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: ExploreText(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _chip(String raw) {
    final c = Theme.of(context).colorScheme, atom = parseExploreArtistAtom(raw);
    return Tooltip(
      message: raw,
      child: Container(
        height: 24,
        padding: const EdgeInsets.only(left: 7, right: 3),
        decoration: BoxDecoration(
          color: ExploreStyle.raised(Theme.of(context)),
          border: Border.all(color: c.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (atom.weight != null) ...[
              ExploreText(
                atom.weight!,
                style: StudioTypography.data.copyWith(
                  fontSize: 11,
                  color: c.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: ExploreText(
                atom.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 2),
            ExploreIconButton(
              'x',
              key: ValueKey('explore-adopt-remove-$raw'),

              width: 18,
              height: 18,
              size: 11,
              tooltip: context.l10n.common_delete,
              onPressed: () => setState(() => _removed[_artists]!.add(raw)),
            ),
          ],
        ),
      ),
    );
  }
}
