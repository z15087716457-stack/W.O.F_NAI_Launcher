import '../../data/models/prompt_block/pill_document.dart';
import 'pill_document_editor.dart';

/// Pure, transactional edits. Callers validate the version of the whole face
/// before committing these documents, not merely the marker being edited.
abstract final class TranslationBlockEdit {
  static Map<String, PillDocument> apply(
    Map<String, PillDocument> documents,
    List<Map<String, dynamic>> operations,
  ) {
    final result = Map<String, PillDocument>.of(documents);
    for (final op in operations) {
      final scope = op['scope'];
      var doc = result[scope];
      if (doc == null) throw const FormatException('Unknown translation scope');
      PillInstance instance(String marker) {
        final value = doc!.instances[marker];
        if (value?.translation == null || !doc.text.contains(marker)) {
          throw const FormatException('Unknown translation marker; read again');
        }
        return value!;
      }

      String text(dynamic value) {
        if (value is! String ||
            value.trim().isEmpty ||
            PillDocumentEditor.stripMarkers(value) != value) {
          throw const FormatException('Expected nonempty text without markers');
        }
        return value;
      }

      final kind = op['op'];
      if (kind == 'merge') {
        final markers = (op['markers'] as List).cast<String>();
        if (markers.length < 2 || markers.toSet().length != markers.length) {
          throw const FormatException('Merge needs distinct markers');
        }
        final values = markers.map(instance).toList();
        if (values.any((value) => value.enabled != values.first.enabled)) {
          throw const FormatException(
            'Cannot merge enabled and disabled blocks',
          );
        }
        // Position is the first block in document order, not the supplied order.
        final ordered = [...markers]
          ..sort((a, b) => doc!.text.indexOf(a).compareTo(doc.text.indexOf(b)));
        final first = ordered.first;
        var body = doc.text;
        for (final marker in ordered.skip(1)) {
          // Remove only the delimiter adjacent to the removed occurrence. Do not
          // reformat unrelated text, weights, line breaks or library blocks.
          body = body.replaceAllMapped(
            RegExp(',[ \\t]*${RegExp.escape(marker)}'),
            (_) => '',
          );
          body = body.replaceAllMapped(
            RegExp('${RegExp.escape(marker)},[ \\t]*'),
            (_) => '',
          );
          body = body.replaceAll(marker, '');
        }
        final instances = Map<String, PillInstance>.of(doc.instances);
        for (final marker in ordered.skip(1)) {
          instances.remove(marker);
        }
        final base = instance(first);
        final source = text(op['source']);
        // Real batches can keep commas inside source rather than between markers.
        // Preserve the outgoing boundary at the surviving document position.
        final boundary = RegExp(
          r'[,，][ \t]*$',
        ).firstMatch(base.translation!.source)?.group(0);
        if (boundary != null && !RegExp(r'[,，]\s*$').hasMatch(source)) {
          body = body.replaceAllMapped(
            RegExp('${RegExp.escape(first)}(?=[^,，\\n])'),
            (_) => '$first$boundary',
          );
        }
        instances[first] = base.copyWith(
          translation: base.translation!.copyWith(
            source: source,
            zh: text(op['translation']),
            marks: const [],
            showOriginal: false,
            translationEdited: true,
          ),
        );
        doc = doc.copyWith(text: body, instances: instances);
      } else {
        final marker = op['marker'] as String;
        final base = instance(marker);
        final translation = base.translation!;
        switch (kind) {
          case 'retranslate':
            doc = doc.copyWith(
              instances: {
                ...doc.instances,
                marker: base.copyWith(
                  translation: translation.copyWith(
                    zh: text(op['translation']),
                    marks: const [],
                    showOriginal: false,
                    translationEdited: true,
                  ),
                ),
              },
            );
          case 'rejoin':
            doc = PillDocumentEditor.unwrapTranslation(
              doc,
              marker,
              source: translation.source,
            );
          case 'split':
            final parts = (op['parts'] as List).cast<Map>();
            if (parts.length < 2 ||
                parts.map((part) => text(part['source'])).join() !=
                    translation.source) {
              throw const FormatException(
                'Split sources must concatenate to the exact current source',
              );
            }
            var next = doc;
            final replacements = <String>[];
            for (var i = 0; i < parts.length; i++) {
              final key = i == 0
                  ? marker
                  : PillDocumentEditor.allocateMarker(next);
              replacements.add(key);
              next = next.copyWith(
                instances: {
                  ...next.instances,
                  key: base.copyWith(
                    translation: translation.copyWith(
                      source: parts[i]['source'] as String,
                      zh: text(parts[i]['translation']),
                      marks: const [],
                      showOriginal: false,
                      translationEdited: true,
                    ),
                  ),
                },
              );
            }
            doc = next.copyWith(
              text: next.text.replaceAll(marker, replacements.join()),
            );
          default:
            throw const FormatException('Unknown translation operation');
        }
      }
      result[scope as String] = doc;
    }
    return result;
  }
}
