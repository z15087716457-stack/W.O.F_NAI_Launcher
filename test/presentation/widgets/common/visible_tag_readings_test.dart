import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/widgets/tag_chip.dart';

void main() {
  testWidgets(
    'tag chips join the visible-tag queue and show its translations',
    (tester) async {
      final readings = _Readings();
      Widget app(List<String> tags) => ProviderScope(
        overrides: [autoTagTranslationProvider.overrideWith((ref) => readings)],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final tag in tags) SimpleTagChip(key: Key(tag), tag: tag),
                const SimpleTagChip(tag: 'solo', translation: '单人'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(app(['blue_eyes']));
      await tester.pump();
      expect(readings.visible, {'blue_eyes'});
      expect(find.textContaining('蓝眼'), findsNothing);

      readings.reveal('blue_eyes', '蓝眼');
      await tester.pump();
      expect(find.textContaining('蓝眼'), findsOneWidget);
      // A stored translation is shown as is and never queued.
      expect(find.textContaining('单人'), findsOneWidget);
      expect(readings.observed, isNot(contains('solo')));

      await tester.pumpWidget(app(const []));
      await tester.pump();
      expect(readings.visible, isEmpty);
      expect(readings.cleared, isNotEmpty);
    },
  );
}

class _Readings extends AutoTagTranslationController {
  _Readings()
    : super(
        assistant: _Assistant(),
        wiki: _Wiki(),
        cache: VisibleTagTranslationCache(),
      );

  final Map<String, String> _shown = {};
  final Map<String, Set<String>> _bySurface = {};
  final Set<String> observed = {};
  final List<String> cleared = [];

  Set<String> get visible => {for (final tags in _bySurface.values) ...tags};

  void reveal(String tag, String name) {
    _shown[tag] = name;
    notifyListeners();
  }

  @override
  String? nameFor(String tag) => _shown[tag];

  @override
  void observe({
    required String surface,
    required String tag,
    required bool visible,
    String? existingNameZh,
    AutoTagTranslationContext? tagContext,
  }) {
    observed.add(tag);
    final tags = _bySurface.putIfAbsent(surface, () => {});
    visible ? tags.add(tag) : tags.remove(tag);
  }

  @override
  void clearSurface(String surface) {
    cleared.add(surface);
    _bySurface.remove(surface);
  }
}

class _Assistant extends Mock implements PromptAssistantService {}

class _Wiki implements TagWikiRepository {
  @override
  Future<TagWikiEntry?> find(String tag) async => null;
}
