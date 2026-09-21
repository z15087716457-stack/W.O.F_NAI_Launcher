import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';

/// 建家族对话框的返回：家族名 + 追加的自定义父本串。
typedef ExploreCreateFamilyResult = ({String name, List<String> customStrings});

/// 建家族对话框（阶段 D）：命名 + 所选候选的父本串预览 + 可选自定义串。
///
/// 候选父本串 = 候选 roll 快照中全部遗传随机实例的 rolledText 合并串
/// （无有效串则回退正向全文，见 [exploreParentStringFor]）；自定义串可多条。
class ExploreCreateFamilyDialog extends StatefulWidget {
  const ExploreCreateFamilyDialog({super.key, required this.candidates});

  /// 画廊多选的候选（父本串来源）。
  final List<ExploreCandidate> candidates;

  static Future<ExploreCreateFamilyResult?> show(
    BuildContext context, {
    required List<ExploreCandidate> candidates,
  }) {
    return showDialog<ExploreCreateFamilyResult>(
      context: context,
      builder: (context) => ExploreCreateFamilyDialog(candidates: candidates),
    );
  }

  @override
  State<ExploreCreateFamilyDialog> createState() =>
      _ExploreCreateFamilyDialogState();
}

class _ExploreCreateFamilyDialogState extends State<ExploreCreateFamilyDialog> {
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _customControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _customControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasParent {
    for (final candidate in widget.candidates) {
      if (exploreParentStringFor(candidate).trim().isNotEmpty) return true;
    }
    for (final controller in _customControllers) {
      if (controller.text.trim().isNotEmpty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final candidateParents = [
      for (final candidate in widget.candidates)
        if (exploreParentStringFor(candidate).trim().isNotEmpty)
          exploreParentStringFor(candidate),
    ];

    return AlertDialog(
      key: const Key('explore-create-family-dialog'),
      title: Text(l10n.styleExplore_createFamily),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('explore-family-name'),
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.styleExplore_familyNameLabel,
                  hintText: l10n.styleExplore_familyNameHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.styleExplore_familyParentsTitle(
                  candidateParents.length + _customControllers.length,
                ),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              for (final text in candidateParents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              for (var i = 0; i < _customControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: Key('explore-custom-parent-$i'),
                          controller: _customControllers[i],
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.styleExplore_customParentLabel,
                            hintText: l10n.styleExplore_customParentHint,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.common_delete,
                        iconSize: 18,
                        onPressed: () => setState(() {
                          _customControllers.removeAt(i).dispose();
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                key: const Key('explore-add-custom-parent'),
                onPressed: () => setState(() {
                  _customControllers.add(TextEditingController());
                }),
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.styleExplore_addCustomParent),
              ),
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
          key: const Key('explore-create-family-confirm'),
          onPressed: !_hasParent
              ? null
              : () {
                  final customStrings = [
                    for (final controller in _customControllers)
                      if (controller.text.trim().isNotEmpty)
                        controller.text.trim(),
                  ];
                  Navigator.of(context).pop((
                    name: _nameController.text.trim(),
                    customStrings: customStrings,
                  ));
                },
          child: Text(l10n.styleExplore_createFamily),
        ),
      ],
    );
  }
}
