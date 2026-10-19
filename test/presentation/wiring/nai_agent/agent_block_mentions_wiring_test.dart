import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock.create(
        title: 'recent',
        content: 'recent',
      ).copyWith(id: 'recent'),
      PromptBlock.create(
        title: 'popular',
        content: 'popular',
      ).copyWith(id: 'popular', useCount: 10),
    ],
    folders: const [],
  );
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final fail in [false, true]) {
    testWidgets(
      'block mentions remain available while preferences load, failure=$fail',
      (tester) async {
        final preferences = Completer<SharedPreferences>();
        final h = AgentWiringHarness();
        await tester.runAsync(
          () => h.init(
            overrides: [
              promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
              blocksSharedPreferencesProvider.overrideWithValue(
                preferences.future,
              ),
            ],
          ),
        );
        addTearDown(h.dispose);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(
          () => h.container.read(promptBlockLibraryNotifierProvider.future),
        );
        await h.pump(tester);
        List<String> ids() => h
            .panel(tester)
            .data
            .mentions
            .where((m) => m.kind == AgentMentionKind.block)
            .map((m) => m.id)
            .toList();
        expect(h.container.read(blocksPreferencesProvider).isLoading, isTrue);
        expect(ids(), ['block/popular', 'block/recent']);

        await tester.runAsync(() async {
          if (fail) {
            preferences.completeError(
              StateError('Synthetic preferences unavailable'),
            );
          } else {
            SharedPreferences.setMockInitialValues({
              'blocks_recent_ids': ['recent'],
            });
            preferences.complete(await SharedPreferences.getInstance());
          }
        });
        // The notifier was mounted in the widget test's fake-async zone.
        await tester.pumpAndSettle();
        expect(h.container.read(blocksPreferencesProvider).hasError, fail);
        expect(
          ids(),
          fail
              ? ['block/popular', 'block/recent']
              : ['block/recent', 'block/popular'],
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
