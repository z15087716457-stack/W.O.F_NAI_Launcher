import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../../../../core/utils/localization_extension.dart';
import 'explore_icon.dart';

Future<String?> chooseExploreFamilyAction(
  BuildContext context,
  Offset position,
) {
  final overlay = Overlay.of(context).context.findRenderObject();
  if (overlay is! RenderBox) return Future.value();
  final point = overlay.globalToLocal(position);
  final c = Theme.of(context).colorScheme;
  return showMenu<String>(
    context: context,
    constraints: const BoxConstraints(minWidth: 128, maxWidth: 200),
    menuPadding: const EdgeInsets.symmetric(vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: c.outlineVariant),
    ),
    position: RelativeRect.fromRect(
      Rect.fromPoints(point, point),
      Offset.zero & overlay.size,
    ),
    items: [
      PopupMenuItem(
        key: const Key('explore-family-menu-delete'),
        value: 'delete',
        height: 32,
        child: Row(
          children: [
            ExploreIcon('trash', size: 14, color: c.error),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.l10n.styleExplore_deleteFamily,
                style: TextStyle(fontSize: 12.5, color: c.error),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
