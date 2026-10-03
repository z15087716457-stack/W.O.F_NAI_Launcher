import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/bulk_metadata_edit_dialog.dart';
import 'package:nai_launcher/presentation/widgets/tag_expansion/tag_expansion_wrapper.dart';

void main() {
  testWidgets('picked tag keeps other comma-separated bulk edit drafts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTagExpansionServiceProvider.overrideWithValue(
            LocalTagExpansionService(
              catalog: const _BlueHairSource(),
              relatedTags: const _EmptySource(),
              substringSearch: (input, {limit = 20}) async => const [],
              popularSearch: ({limit = 12}) async => const [],
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BulkMetadataEditDialog()),
        ),
      ),
    );
    await tester.pump();
    final input = find.descendant(
      of: find.byType(TagExpansionWrapper).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'red, blu');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(input);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(
      find.byKey(const Key('tag-expansion-search')),
      'blue',
    );
    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('red'), findsOneWidget);
    expect(find.text('blue_hair'), findsOneWidget);
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
  });
}

class _BlueHairSource implements CompletionSource {
  const _BlueHairSource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async => [
    const CompletionCandidate(
      canonicalTag: 'blue_hair',
      category: TagCategory.general,
      postCount: 100,
      matchKind: CompletionMatchKind.englishPrefix,
      sources: {CompletionSourceKind.base},
    ),
  ];
}

class _EmptySource implements CompletionSource {
  const _EmptySource();

  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async =>
      const [];
}
