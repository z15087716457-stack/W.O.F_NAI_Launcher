import 'package:flutter/foundation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/tag_normalizer.dart';
import '../../../core/wiki/auto_tag_translation_controller.dart';

/// Tag readings for widgets that show tags outside Wiki and tag expansion.
///
/// Displayed tags join the same visible-tag translation queue and cache, so
/// the shared automatic-translation switch decides whether the user's
/// translation interface is called; with it off only English tags show.
mixin VisibleTagReadings<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final String _readingSurface = 'tag-readings-${identityHashCode(this)}';
  AutoTagTranslationController? _readings;
  Set<String> _readingTags = const {};

  /// Call from build with the tags currently shown.
  void observeTagReadings(Iterable<String> tags) {
    final next = {
      for (final tag in tags)
        if (TagNormalizer.normalize(tag) case final canonical
            when canonical.isNotEmpty)
          canonical,
    };
    if (setEquals(next, _readingTags)) return;
    final previous = _readingTags;
    _readingTags = next;
    // Observing notifies listeners, which must not happen during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_readingTags, next)) return;
      // Kept for dispose, where ref may no longer be used.
      final AutoTagTranslationController readings = ref.read(
        autoTagTranslationProvider,
      );
      _readings = readings;
      for (final tag in previous.difference(next)) {
        readings.observe(surface: _readingSurface, tag: tag, visible: false);
      }
      for (final tag in next) {
        readings.observe(surface: _readingSurface, tag: tag, visible: true);
      }
    });
  }

  /// The translated reading for [tag]; rebuilds when it arrives.
  String? tagReading(String tag) =>
      ref.watch(autoTagTranslationProvider).nameFor(tag);

  @override
  void dispose() {
    _readings?.clearSurface(_readingSurface);
    super.dispose();
  }
}
