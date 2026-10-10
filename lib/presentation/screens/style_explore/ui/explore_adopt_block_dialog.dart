import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import 'explore_artist_text.dart';
import 'explore_candidate_card.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';
import 'explore_controls.dart';
import 'explore_text.dart';
import 'explore_style.dart';

part 'explore_adopt_dialog_view.dart';

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

abstract class _AdoptController extends ConsumerState<ExploreAdoptBlockDialog> {
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
}
