import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/models/prompt_block/pill_document.dart';
import '../../../../providers/prompt_translation_provider.dart';

/// Injectable for offline rendering/tests. Invoked only by the translate button.
final detailPromptTranslatorProvider =
    Provider<Future<PillDocument> Function(PillDocument, String)>(
      (ref) =>
          (document, sessionId) => ref
              .read(promptTranslationCoordinatorProvider)
              .translateDocument(document, sessionId: sessionId),
    );
