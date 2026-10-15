import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/rag/rag_gallery_search.dart';
import '../../../core/rag/rag_settings.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/gallery_rag_query_provider.dart';
import '../../providers/rag_provider.dart';
import '../common/rag_search_badge.dart';

final galleryRagImagePickerProvider = Provider<Future<String?> Function()>(
  (ref) => () async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return selected?.files.single.path;
  },
);

class GalleryRagSearchMenu extends ConsumerWidget {
  const GalleryRagSearchMenu({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(galleryRagQueryProvider);
    final status = ref
        .watch(ragControllerProvider)
        .forSource(RagSource.gallery);
    final l = context.l10n;
    final labels = {
      RagGalleryMode.mixed: l.rag_galleryMixed,
      RagGalleryMode.visual: l.rag_galleryVisual,
      RagGalleryMode.parameters: l.rag_galleryParameters,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (options.image.isNotEmpty)
          IconButton(
            key: const Key('gallery-rag-clear-image'),
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            tooltip: '${l.rag_galleryClearImage}: ${p.basename(options.image)}',
            icon: Icon(
              Icons.image_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () =>
                ref.read(galleryRagQueryProvider.notifier).clearImage(),
          ),
        PopupMenuButton<String>(
          key: const Key('gallery-rag-menu'),
          tooltip: l.rag_gallerySearchOptions,
          onSelected: (value) async {
            final controller = ref.read(galleryRagQueryProvider.notifier);
            if (value == 'image') {
              final path = await ref.read(galleryRagImagePickerProvider)();
              if (context.mounted && path != null) controller.setImage(path);
            } else {
              controller.setMode(RagGalleryMode.values.byName(value));
            }
          },
          itemBuilder: (context) => [
            for (final mode in RagGalleryMode.values)
              CheckedPopupMenuItem(
                value: mode.name,
                checked: options.mode == mode,
                child: Text(labels[mode]!),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'image',
              enabled:
                  !status.suspended &&
                  (status.details['visual_indexed'] ?? 0) > 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_search_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(l.rag_galleryChooseImage),
                ],
              ),
            ),
          ],
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RagSearchBadge(source: RagSource.gallery),
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.expand_more, size: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
