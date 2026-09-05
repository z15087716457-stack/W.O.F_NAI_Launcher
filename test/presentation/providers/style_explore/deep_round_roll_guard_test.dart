import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/providers/style_explore/deep_round_roll_guard.dart';

void main() {
  const marker = '\uE000';
  const otherMarker = '\uE001';

  PillInstance randomInstance({
    String blockId = 'pool',
    String? roll = 'before',
    bool locked = false,
  }) {
    return PillInstance(
      blockId: blockId,
      currentRoll: roll,
      locked: locked,
      evolutionEnabled: true,
      settings: const PillInstanceSettings(mode: PillRollMode.random),
    );
  }

  test('overlay distinguishes missing, locked-empty, and explicit values', () {
    final controller = DeepRoundRollGuardController();
    final guard = DeepRoundRollGuard.capture(
      ownerId: 'owner-a',
      runId: 'run-a',
      roundId: 'round-a',
      documents: {
        'main': PillDocument(
          text: '$marker$otherMarker',
          instances: {
            marker: randomInstance(),
            otherMarker: randomInstance(roll: 'locked-before', locked: true),
          },
        ),
        'negative': PillDocument(
          text: marker,
          instances: {marker: randomInstance(roll: 'negative-before')},
        ),
      },
    );

    expect(controller.install(guard), isTrue);
    expect(controller.guard!.overlay.containsKey('main'), isTrue);
    expect(controller.guard!.overlay['main']![marker], isNull);
    expect(
      controller.updateCandidate(
        ownerId: 'owner-a',
        runId: 'run-a',
        roundId: 'round-a',
        targetScope: 'main',
        targetMarker: marker,
        mutatedText: 'child',
      ),
      isTrue,
    );

    final active = controller.guard!;
    expect(active.overlay['main']![marker], 'child');
    expect(active.overlay['negative']![marker], isNull);
    expect(active.overlay['main']!.containsKey(otherMarker), isFalse);
    expect(controller.effectiveRoll('main', marker, randomInstance()), 'child');
    expect(
      controller.effectiveRoll(
        'negative',
        marker,
        randomInstance(roll: 'negative-before'),
      ),
      isNull,
    );
  });

  test(
    'a user lock acquired after installation restores the entering roll',
    () {
      final controller = DeepRoundRollGuardController();
      expect(
        controller.install(
          DeepRoundRollGuard.capture(
            ownerId: 'owner-a',
            runId: 'run-a',
            roundId: 'round-a',
            documents: {
              'main': PillDocument(
                text: marker,
                instances: {marker: randomInstance()},
              ),
            },
          ),
        ),
        isTrue,
      );
      controller.updateCandidate(
        ownerId: 'owner-a',
        runId: 'run-a',
        roundId: 'round-a',
        targetScope: 'main',
        targetMarker: otherMarker,
        mutatedText: 'not-present',
      );

      final lockedLater = randomInstance(locked: true);
      expect(controller.effectiveRoll('main', marker, lockedLater), 'before');
    },
  );

  test('stale owner cleanup cannot clear a newer guard', () {
    final controller = DeepRoundRollGuardController();
    final first = DeepRoundRollGuard.capture(
      ownerId: 'owner-a',
      runId: 'run-a',
      roundId: 'round-a',
      documents: const {},
    );
    final second = DeepRoundRollGuard.capture(
      ownerId: 'owner-b',
      runId: 'run-b',
      roundId: 'round-b',
      documents: const {},
    );
    expect(controller.install(first), isTrue);
    expect(controller.install(second), isFalse);
    expect(
      controller.clear(ownerId: 'owner-b', runId: 'run-b', roundId: 'round-b'),
      isFalse,
    );
    expect(controller.guard, same(first));
    expect(
      controller.clear(ownerId: 'owner-a', runId: 'run-a', roundId: 'round-a'),
      isTrue,
    );
  });
}
