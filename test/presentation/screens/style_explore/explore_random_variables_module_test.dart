import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_random_variables_module.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

PromptBlockLibraryState variableFixtureLibrary({bool dark = false}) =>
    PromptBlockLibraryState(
      blocks: [
        PromptBlock(
          id: 'pool',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '400精选画师池',
          content: 'artist:a',
          atoms: List.generate(400, (i) => 'artist:a$i'),
          color: dark ? '#FFF06595' : '#FFD6336C',
        ),
        PromptBlock(
          id: 'favorite',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '收藏艺术家池',
          content: 'artist:b',
          atoms: List.generate(86, (i) => 'artist:b$i'),
          color: dark ? '#FF4DABF7' : '#FF1C7ED6',
        ),
        PromptBlock(
          id: 'negative',
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
          title: '负面随机池',
          content: 'lowres, blurry',
          color: '#FF0064E2',
        ),
      ],
      folders: [],
    );

PillDocument variableFixtureDocument(int count) => PillDocument(
  text: [
    for (var i = 0; i < count; i++) String.fromCharCode(0xe000 + i),
  ].join(' '),
  instances: {
    for (var i = 0; i < count; i++)
      String.fromCharCode(0xe000 + i): PillInstance(
        blockId: i == 0
            ? 'pool'
            : i == 1
            ? 'favorite'
            : 'negative',
        evolutionEnabled: true,
        settings: PillInstanceSettings(
          mode: i == 1 ? PillRollMode.sequential : PillRollMode.random,
        ),
      ),
  },
);

Widget variableFixtureApp({
  int count = 2,
  PillDocument? positive,
  PillDocument? negative,
  PromptBlockLibraryState? library,
  double width = 384,
  String locale = 'zh',
  bool dark = false,
  Key? captureKey,
  VoidCallback? onOpenLibrary,
}) => MaterialApp(
  theme: dark ? GeistTheme.dark : GeistTheme.light,
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: captureKey,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 13, 12),
            child: ExploreRandomVariablesView(
              positive: positive ?? variableFixtureDocument(count),
              negative: negative ?? PillDocument.empty(),
              library: library ?? variableFixtureLibrary(dark: dark),
              onOpenLibrary: onOpenLibrary ?? () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

class _EmptyWorkspace extends PillWorkspaceNotifier {
  @override
  PillWorkspaceState build(String scope) =>
      PillWorkspaceState(document: PillDocument.empty(), projection: '');
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => variableFixtureLibrary();
}

class _Storage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

void main() {
  testWidgets('empty module opens the actual shared block-library toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _Storage()),
          pillWorkspaceProvider.overrideWith(_EmptyWorkspace.new),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 384, child: ExploreRandomVariablesModule()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('提示词里还没有随机块，抽出来的图会很像'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExploreRandomVariablesModule)),
    );
    final subscription = container.listen(
      layoutStateNotifierProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);
    expect(
      container.read(layoutStateNotifierProvider).blockLibraryPanelExpanded,
      isFalse,
    );
    await tester.tap(find.text('打开块库'));
    await tester.pump();
    expect(
      container.read(layoutStateNotifierProvider).blockLibraryPanelExpanded,
      isTrue,
    );
  });

  testWidgets(
    'random and sequential variables keep snapshot order and one main target',
    (tester) async {
      await tester.pumpWidget(variableFixtureApp());
      await tester.pumpAndSettle();
      expect(find.text('池 400 项'), findsOneWidget);
      expect(find.text('池 86 项'), findsOneWidget);
      expect(find.text('· 进化目标'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('400精选画师池')).dy,
        lessThan(tester.getTopLeft(find.text('收藏艺术家池')).dy),
      );
    },
  );

  testWidgets(
    'disabled and fixed blocks are excluded; non-evolution random blocks remain visible',
    (tester) async {
      final doc = variableFixtureDocument(1);
      await tester.pumpWidget(
        variableFixtureApp(
          positive: doc.copyWith(
            instances: {
              ...doc.instances,
              'x': doc.instances.values.first.copyWith(enabled: false),
              'y': doc.instances.values.first.copyWith(evolutionEnabled: false),
              'z': doc.instances.values.first.copyWith(
                settings: PillInstanceSettings.fixedDefault,
              ),
            },
          ),
          negative: variableFixtureDocument(1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('400精选画师池'), findsNWidgets(3));
      expect(find.text('· 进化目标'), findsOneWidget);
      expect(find.text('· 负面'), findsOneWidget);
    },
  );

  testWidgets('missing block stays visible without changing its document', (
    tester,
  ) async {
    final document = variableFixtureDocument(1);
    await tester.pumpWidget(
      variableFixtureApp(
        positive: document,
        library: PromptBlockLibraryState(blocks: [], folders: []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('块已删除'), findsOneWidget);
    expect(find.text('池 0 项'), findsOneWidget);
    expect(document.instances.values.first.blockId, 'pool');
    expect(tester.takeException(), isNull);
  });
}
