import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_mapping.dart';

void main() {
  test('loading and missing metadata have different statuses', () {
    expect(
      viewerDetailOf('x', null, loading: true).status,
      ViewerMetaStatus.loading,
    );
    expect(viewerDetailOf('x', null).status, ViewerMetaStatus.none);
    expect(
      viewerDetailOf('x', const NaiImageMetadata(prompt: 'cat')).status,
      ViewerMetaStatus.ready,
    );
  });

  test(
    'main prompt does not include characters, coordinates retain fractions',
    () {
      final result = viewerDetailOf(
        'x',
        const NaiImageMetadata(
          prompt: 'main',
          negativePrompt: 'negative',
          characterInfos: [
            CharacterPromptInfo(
              prompt: 'character',
              negativePrompt: 'uc',
              centerX: 0.32,
              centerY: 0.87,
            ),
          ],
          preciseReferenceImages: ['one', 'two'],
        ),
      );
      expect(result.prompt, 'main');
      expect(result.characters.single.prompt, 'character');
      expect(result.characters.single.negative, 'uc');
      expect(result.characters.single.x, 0.32);
      expect(result.characters.single.y, 0.87);
      expect(result.preciseCount, 2);
    },
  );

  test(
    'legacy character strings remain readable and invalid coordinates omitted',
    () {
      final result = viewerDetailOf(
        'x',
        const NaiImageMetadata(
          characterPrompts: ['one', 'two'],
          characterNegativePrompts: ['uc'],
        ),
      );
      expect(result.characters.map((c) => c.negative), ['uc', '']);
      final invalid = viewerDetailOf(
        'x',
        const NaiImageMetadata(
          characterInfos: [
            CharacterPromptInfo(
              prompt: 'one',
              centerX: -1,
              centerY: double.nan,
            ),
          ],
        ),
      );
      expect(invalid.characters.single.x, isNull);
      expect(invalid.characters.single.y, isNull);
    },
  );

  test('SMEA only appears for V3, and dynamic takes priority', () {
    expect(
      viewerDetailOf(
        'x',
        const NaiImageMetadata(model: 'nai-diffusion-3', smea: true),
      ).smea,
      'ON',
    );
    expect(
      viewerDetailOf(
        'x',
        const NaiImageMetadata(model: 'nai-diffusion-3', smeaDyn: true),
      ).smea,
      'DYN',
    );
    expect(
      viewerDetailOf(
        'x',
        const NaiImageMetadata(model: 'nai-diffusion-4-5-full', smea: true),
      ).smea,
      isNull,
    );
  });

  test(
    'collection folders are not selectable but depth and tree order retained',
    () {
      ImageCollection node(String id, {String? parent, bool folder = false}) =>
          ImageCollection(
            id: id,
            name: id,
            parentId: parent,
            isFolder: folder,
            createdAt: DateTime(2026),
          );
      final result = viewerCollectionsOf(
        [
          node('child', parent: 'folder'),
          node('folder', folder: true),
          node('root'),
        ],
        {'child'},
      );
      expect(result.map((c) => c.id), ['child', 'root']);
      expect(result.first.depth, 1);
      expect(result.first.member, isTrue);
    },
  );

  test('all sort fields map to their contract counterparts', () {
    expect(GallerySortField.values.map(viewerSortOf), ViewerSort.values);
  });

  test('copy parts include individual character and seed with safe bounds', () {
    const metadata = NaiImageMetadata(
      prompt: 'main',
      negativePrompt: 'uc',
      seed: 42,
      characterPrompts: ['one'],
    );
    expect(viewerPartText(metadata, ViewerPart.prompt), 'main');
    expect(viewerPartText(metadata, ViewerPart.seed), '42');
    expect(viewerPartText(metadata, const ViewerPart.character(0)), 'one');
    expect(viewerPartText(metadata, const ViewerPart.character(-1)), isNull);
    expect(viewerPartText(metadata, const ViewerPart.character(10)), isNull);
  });

  test('custom bindings and explicit disabling preserve user preferences', () {
    final config = ShortcutConfig.createDefault()
        .setCustomShortcut(ShortcutIds.nextImage, 'ctrl+shift+n')
        .setEnabled(ShortcutIds.closeViewer, false);
    final keys = viewerKeysOf(config);
    expect(keys[ViewerCommand.next]!.single.trigger, LogicalKeyboardKey.keyN);
    expect(keys[ViewerCommand.next]!.single.control, isTrue);
    expect(keys[ViewerCommand.next]!.single.shift, isTrue);
    expect(keys[ViewerCommand.close], isEmpty);
    expect(keys.containsKey(ViewerCommand.first), isFalse);
    expect(
      viewerKeysOf(
        config.copyWith(enableShortcuts: false),
      ).values.every((value) => value.isEmpty),
      isTrue,
    );
  });
}
