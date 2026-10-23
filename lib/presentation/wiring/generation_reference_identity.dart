import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/nai_api_utils.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../providers/image_generation_provider.dart';

final generationReferenceIdentityProvider =
    Provider<GenerationReferenceIdentity>((ref) {
      final identity = GenerationReferenceIdentity();
      identity.sync(ref.read(generationParamsNotifierProvider));
      ref.listen(
        generationParamsNotifierProvider,
        (_, next) => identity.sync(next),
      );
      return identity;
    });

class GenerationReferenceIdentity {
  final _vibes = _ReferenceIds<VibeReference>(
    'vibe',
    (value) =>
        value.rawImageData ??
        value.thumbnail ??
        (value.vibeEncoding.isEmpty ? value : value.vibeEncoding),
  );
  final _precise = _ReferenceIds<PreciseReference>(
    'precise',
    (value) => NAIApiUtils.preciseReferenceIdentity(value.image),
  );

  void sync(ImageParams params) {
    _vibes.sync(params.vibeReferencesV4);
    _precise.sync(params.preciseReferences);
  }

  List<String> get vibes => _vibes.ids;
  List<String> get precise => _precise.ids;
  int vibeIndex(String id) => _vibes.ids.indexOf(id);
  int preciseIndex(String id) => _precise.ids.indexOf(id);
}

class _ReferenceIds<T> {
  _ReferenceIds(this.prefix, this.source);
  final String prefix;
  final Object Function(T) source;
  int _next = 0;
  List<(String, T)> _entries = [];
  List<String> get ids =>
      _entries.map((entry) => entry.$1).toList(growable: false);

  void sync(List<T> values) {
    final remaining = _entries.toList();
    final next = List<(String, T)?>.filled(values.length, null);
    for (var index = 0; index < values.length; index++) {
      final exact = remaining.indexWhere(
        (entry) => identical(entry.$2, values[index]),
      );
      if (exact >= 0) {
        next[index] = (remaining.removeAt(exact).$1, values[index]);
      }
    }
    for (var index = 0; index < values.length; index++) {
      if (next[index] != null) continue;
      final key = source(values[index]);
      final match = remaining.indexWhere((entry) => source(entry.$2) == key);
      next[index] = (
        match < 0 ? '$prefix:${++_next}' : remaining.removeAt(match).$1,
        values[index],
      );
    }
    _entries = next.cast<(String, T)>();
  }
}
