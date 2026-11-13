import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../core/enums/precise_ref_type.dart';
import '../../../core/extensions/precise_ref_type_extensions.dart';
import '../../../core/utils/localization_extension.dart';
import '../../ui/kit/ui_colors.dart';
import '../../ui/kit/ui_keycap.dart';
import '../../ui/kit/ui_text.dart';
import 'studio_icons.dart';

class PreciseReferenceTypeDialog extends StatelessWidget {
  const PreciseReferenceTypeDialog({super.key});

  static Future<PreciseRefType?> show(BuildContext context) {
    return showDialog<PreciseRefType>(
      context: context,
      builder: (context) => const PreciseReferenceTypeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    void cancel() => Navigator.of(context).pop();
    return Focus(
      autofocus: true,
      skipTraversal: true,
      child: Dialog(
        backgroundColor: c.raised,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          key: const Key('precise-reference-type-dialog'),
          width: 368,
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  key: const Key('precise-reference-type-header'),
                  height: 60,
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          StudioIcons.preciseReference,
                          size: 18,
                          color: c.accent,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.preciseRef_importTitle,
                          maxLines: 2,
                          style: UiText.sans(
                            14,
                            weight: FontWeight.w600,
                            height: 1.4,
                            color: c.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('precise-reference-type-close'),
                        tooltip: l.common_close,
                        onPressed: cancel,
                        icon: const Icon(Icons.close, size: 17),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(28, 28),
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: c.faint,
                          hoverColor: c.hover,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Text(
                            l.preciseRef_importTypePrompt,
                            style: UiText.sans(12, height: 1.5, color: c.muted),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          child: Column(
                            spacing: 6,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final type in PreciseRefType.values)
                                _ReferenceTypeButton(
                                  type: type,
                                  title: type.getDisplayName(
                                    character: l.preciseRef_typeCharacter,
                                    style: l.preciseRef_typeStyle,
                                    characterAndStyle:
                                        l.preciseRef_typeCharacterAndStyle,
                                  ),
                                  description: switch (type) {
                                    PreciseRefType.character =>
                                      l.preciseRef_characterDescription,
                                    PreciseRefType.style =>
                                      l.preciseRef_styleDescription,
                                    PreciseRefType.characterAndStyle =>
                                      l.preciseRef_characterAndStyleDescription,
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  key: const Key('precise-reference-type-footer'),
                  constraints: const BoxConstraints(minHeight: 43),
                  padding: const EdgeInsets.fromLTRB(16, 7, 12, 7),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Text(
                          l.preciseRef_importTypeHint,
                          style: UiText.sans(11, height: 1.5, color: c.faint),
                        ),
                      ),
                      TextButton(
                        key: const Key('precise-reference-type-cancel'),
                        onPressed: cancel,
                        style: TextButton.styleFrom(
                          foregroundColor: c.muted,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 7,
                          children: [
                            Text(
                              l.common_cancel,
                              style: UiText.sans(
                                12,
                                height: 1.5,
                                color: c.muted,
                              ),
                            ),
                            const ExcludeSemantics(
                              child: UiKeycap(
                                'Esc',
                                style: UiKeycapStyle.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceTypeButton extends StatelessWidget {
  const _ReferenceTypeButton({
    required this.type,
    required this.title,
    required this.description,
  });

  final PreciseRefType type;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    bool highlighted(Set<WidgetState> states) =>
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    return TextButton(
      key: ValueKey('precise-reference-type-${type.name}'),
      onPressed: () => Navigator.of(context).pop(type),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 65)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) =>
              BorderSide(color: highlighted(states) ? c.accent : c.line),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => highlighted(states)
              ? c.accent.withValues(alpha: .1)
              : Colors.transparent,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => highlighted(states) ? c.accent : c.muted,
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.control,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(type.icon, size: 18),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  title,
                  style: UiText.sans(
                    13,
                    weight: FontWeight.w500,
                    height: 1.4,
                    color: c.ink,
                  ),
                ),
                Text(
                  description,
                  style: UiText.sans(11, height: 1.5, color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14, child: Icon(Icons.chevron_right, size: 17)),
        ],
      ),
    );
  }
}
