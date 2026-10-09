import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../prompt_block_library/widgets/prompt_block_color_picker.dart';
import 'explore_artist_text.dart';
import 'explore_candidate_card.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';

class ExploreAdoptBlockResult {
  const ExploreAdoptBlockResult({
    required this.title,
    required this.content,
    required this.atoms,
    required this.color,
    this.folderId,
    this.iconName,
  });
  final String title, content, color;
  final List<String> atoms;
  final String? folderId, iconName;
}

List<String> exploreAdoptArtists(Iterable<ExploreCandidate> candidates) => {
  for (final candidate in candidates)
    for (final roll
        in candidate.rollSnapshot?.instanceRolls ?? <ExploreInstanceRoll>[])
      if (roll.lane == 'pos')
        ...PillRollEngine.splitTopLevelAtoms(roll.rolledText),
}.toList();
List<String> exploreAdoptPositive(Iterable<ExploreCandidate> candidates) =>
    PillRollEngine.splitTopLevelAtoms(
      mergeExploreRollPositives([
        for (final c in candidates)
          if (c.rollSnapshot?.positive case final positive?) positive,
      ]),
    );

class ExploreAdoptBlockDialog extends ConsumerStatefulWidget {
  const ExploreAdoptBlockDialog({
    super.key,
    required this.initialTitle,
    required this.candidates,
    this.sequenceNumber = 1,
  });
  final String initialTitle;
  final List<ExploreCandidate> candidates;
  final int sequenceNumber;
  static Future<ExploreAdoptBlockResult?> show(
    BuildContext context, {
    required String initialTitle,
    required List<ExploreCandidate> candidates,
    int sequenceNumber = 1,
  }) => showDialog<ExploreAdoptBlockResult>(
    context: context,
    builder: (_) => ExploreAdoptBlockDialog(
      initialTitle: initialTitle,
      candidates: candidates,
      sequenceNumber: sequenceNumber,
    ),
  );
  @override
  ConsumerState<ExploreAdoptBlockDialog> createState() => _AdoptState();
}

class _AdoptState extends ConsumerState<ExploreAdoptBlockDialog> {
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _hasDraws = widget.candidates.any(
    (c) => c.rollSnapshot?.instanceRolls.any((r) => r.lane == 'pos') == true,
  );
  late bool _artists = _hasDraws;
  final _removed = {true: <String>{}, false: <String>{}};
  Color _color = const Color(0xff6e56cf);
  String? _icon, _folder;
  List<String> get _allAtoms => _artists
      ? exploreAdoptArtists(widget.candidates)
      : exploreAdoptPositive(widget.candidates);
  List<String> get _atoms =>
      _allAtoms.where((a) => !_removed[_artists]!.contains(a)).toList();
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_title.text.trim().isEmpty || _atoms.isEmpty) return;
    final folders =
        ref.read(promptBlockLibraryNotifierProvider).valueOrNull?.folders ?? [];
    final atoms = List<String>.unmodifiable(_atoms);
    Navigator.pop(
      context,
      ExploreAdoptBlockResult(
        title: _title.text.trim(),
        content: atoms.join(', '),
        atoms: atoms,
        color: promptBlockColorToHex(_color),
        iconName: _icon,
        folderId: folders.any((f) => f.id == _folder) ? _folder : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        colors = theme.colorScheme,
        l10n = context.l10n;
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final folder = library?.folders.any((f) => f.id == _folder) == true
        ? _folder
        : null;
    return ExploreDialogFrame(
      key: const Key('explore-adopt-block-dialog'),
      width: 560,
      title: l10n.styleExplore_saveBlock,
      icon: 'box',
      subtitle: widget.candidates.length == 1
          ? l10n.styleExplore_saveSingleSubtitle(widget.sequenceNumber)
          : l10n.styleExplore_saveManySubtitle(widget.candidates.length),
      footer: OverflowBar(
        spacing: 8,
        overflowSpacing: 8,
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        children: [
          Text(
            l10n.styleExplore_saveHint,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: ExploreDialogFrame.buttonStyle(context),
                child: Text(l10n.common_cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('explore-adopt-block-confirm'),
                onPressed: _title.text.trim().isEmpty || _atoms.isEmpty
                    ? null
                    : _confirm,
                style: ExploreDialogFrame.buttonStyle(context).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.disabled)
                        ? colors.surfaceContainerHighest
                        : colors.primary,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (s) => s.contains(WidgetState.disabled)
                        ? colors.onSurfaceVariant
                        : colors.onPrimary,
                  ),
                ),
                child: Text(l10n.styleExplore_saveBlock),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in widget.candidates.take(8))
                SizedBox(
                  width: 44,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ExploreCandidateImage(
                      candidate: c,
                      sequenceNumber: widget.sequenceNumber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _label(l10n.styleExplore_saveContent),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final artists in [true, false])
                Tooltip(
                  message: artists && !_hasDraws
                      ? l10n.styleExplore_saveNoDraws
                      : '',
                  child: OutlinedButton(
                    key: Key(
                      artists ? 'explore-adopt-artists' : 'explore-adopt-full',
                    ),
                    onPressed: artists && !_hasDraws
                        ? null
                        : () => setState(() => _artists = artists),
                    style: ExploreDialogFrame.buttonStyle(context).copyWith(
                      backgroundColor: WidgetStatePropertyAll(
                        _artists == artists
                            ? colors.surfaceContainerHighest
                            : colors.surface,
                      ),
                    ),
                    child: Text(
                      artists
                          ? l10n.styleExplore_saveArtistsOnly
                          : l10n.styleExplore_saveFullPositive,
                    ),
                  ),
                ),
            ],
          ),
          if (!_hasDraws) ...[
            const SizedBox(height: 6),
            Text(
              l10n.styleExplore_saveNoDraws,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          _label(l10n.styleExplore_saveRemoveAtoms),
          Container(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [for (final atom in _atoms) _chip(atom)],
            ),
          ),
          if (_removed[_artists]!.isNotEmpty)
            Row(
              children: [
                Text(
                  l10n.styleExplore_saveRemoved(_removed[_artists]!.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  key: const Key('explore-adopt-restore'),
                  onPressed: () => setState(() => _removed[_artists]!.clear()),
                  child: Text(
                    l10n.styleExplore_saveRestore,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          _label(l10n.styleExplore_saveName),
          TextField(
            key: const Key('explore-adopt-block-name'),
            controller: _title,
            autofocus: true,
            decoration: ExploreDialogFrame.inputDecoration(context),
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(l10n.styleExplore_saveColor),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: PromptBlockColorPicker(
                      inline: true,
                      palette: const [
                        Color(0xff0064e2),
                        Color(0xff6e56cf),
                        Color(0xffd6336c),
                        Color(0xffe8590c),
                        Color(0xff2b9a66),
                        Color(0xff0e7490),
                        Color(0xff666666),
                      ],
                      selectedColor: _color,
                      onChanged: (c) => setState(() => _color = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(l10n.styleExplore_saveFolder),
                    DropdownButtonFormField<String>(
                      key: const Key('explore-adopt-folder'),
                      initialValue: folder ?? '',
                      isExpanded: true,
                      style: theme.textTheme.bodySmall,
                      decoration: ExploreDialogFrame.inputDecoration(context),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.styleExplore_saveRoot),
                        ),
                        for (final f in library?.folders ?? [])
                          DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              library!.folderPath(f.id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _folder = value == '' ? null : value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label(l10n.styleExplore_saveIcon),
          Align(
            alignment: Alignment.centerLeft,
            child: PromptBlockIconPicker(
              selected: _icon,
              onChanged: (v) => setState(() => _icon = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _chip(String raw) {
    final atom = parseExploreArtistAtom(raw),
        colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: raw,
      child: Container(
        height: 24,
        padding: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (atom.weight case final weight?) ...[
              Text(
                weight,
                style: StudioTypography.data.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                atom.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              key: ValueKey('explore-adopt-remove-$raw'),
              onTap: () => setState(() => _removed[_artists]!.add(raw)),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ExploreIcon(
                  'x',
                  size: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
