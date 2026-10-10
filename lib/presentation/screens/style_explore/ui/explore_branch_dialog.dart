import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import 'explore_controls.dart';
import 'explore_dialog_frame.dart';

Future<String?> showExploreBranchDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _BranchDialog());

class _BranchDialog extends StatefulWidget {
  const _BranchDialog();
  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends State<_BranchDialog> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme, l = context.l10n;
    return ExploreDialogFrame(
      width: 420,
      title: l.styleExplore_breedNext,
      icon: 'branch',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ExploreButton(
            label: l.common_cancel,
            height: 36,
            ghost: true,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ExploreButton(
            key: const Key('explore-branch-confirm'),
            label: l.common_confirm,
            height: 36,
            color: c.onPrimary,
            background: c.primary,
            border: c.primary,
            onPressed: () => Navigator.pop(context, _name.text),
          ),
        ],
      ),
      child: SizedBox(
        height: 38,
        child: TextField(
          key: const Key('explore-branch-name'),
          controller: _name,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: l.styleExplore_optionalName,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            filled: false,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
    );
  }
}
