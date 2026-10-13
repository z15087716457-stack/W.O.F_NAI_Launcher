import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';

NaiAgentGenerationInput generationInput({
  ImageParams? raw,
  ImageParams? effective,
  String contextVersion = '',
  String version = 'draft-1',
  String account = 'account-1',
  String endpoint = 'local-test',
  int? balance = 100,
  int estimate = 12,
  String? blocked,
  Object? workflow,
}) => NaiAgentGenerationInput(
  raw: raw ?? const ImageParams(prompt: 'synthetic'),
  effective: effective ?? raw ?? const ImageParams(prompt: 'synthetic'),
  promptContextVersion: contextVersion,
  draftVersion: version,
  batchSize: 2,
  billing: {
    'estimated_anlas': estimate,
    'balance_anlas': balance,
    'per_request_anlas': estimate,
    'encoding_anlas': 0,
  },
  accountId: account,
  accountName: 'Local test account',
  endpoint: endpoint,
  blockedReason: blocked,
  workflowGuard: workflow,
);

void main() {
  late NaiAgentGenerationTools tools;
  late NaiAgentGenerationInput input;
  late DateTime now;
  late bool alive, admitted;
  late int approvals, backups, starts, cancels;
  Future<bool> Function()? approval;
  Future<void> Function()? duringBackup;
  late Completer<Map<String, dynamic>> completion;
  setUp(() {
    input = generationInput();
    now = DateTime(2026, 10, 7);
    alive = admitted = true;
    approvals = backups = starts = cancels = 0;
    approval = null;
    duringBackup = null;
    completion = Completer<Map<String, dynamic>>();
    tools = NaiAgentGenerationTools(
      readInput: (_) => input,
      clock: () => now,
      isAlive: () => alive,
      approve: (_, __, ___) async {
        approvals++;
        return await approval?.call() ?? true;
      },
      backup: (_) async {
        backups++;
        await duringBackup?.call();
        return 'synthetic-backup';
      },
      start: (_) {
        starts++;
        return admitted
            ? NaiAgentGenerationRun(
                id: 'own-run',
                completion: completion.future,
                cancel: () {
                  cancels++;
                  return true;
                },
              )
            : null;
      },
    );
  });
  Matcher error(String code) =>
      isA<NaiAgentToolError>().having((e) => e.code, 'code', code);
  Future<String> prepare([Map<String, dynamic> params = const {}]) async =>
      (await tools.prepare(
            params,
            NaiAgentCancellation(),
          ))['details']['quote']['quote_id']
          as String;
  Future<Map<String, dynamic>> run(String id, {NaiAgentCancellation? token}) =>
      tools.run({
        'quote_id': id,
        'authorized': true,
      }, token ?? NaiAgentCancellation());

  test(
    'prepare is read only and model authorization flags do not bypass the button',
    () async {
      final id = await prepare({'authorized': true});
      expect([approvals, backups, starts], [0, 0, 0]);
      final decision = Completer<bool>();
      approval = () => decision.future;
      final future = run(id);
      await Future<void>.delayed(Duration.zero);
      expect([approvals, backups, starts], [1, 0, 0]);
      decision.complete(false);
      expect((await future)['details']['status'], 'cancelled');
      expect(starts, 0);
      await expectLater(run(id), throwsA(error('quote_missing')));
    },
  );

  test(
    'one admitted run reports actual output and cannot replay its quote',
    () async {
      final id = await prepare();
      completion.complete({
        'status': 'completed',
        'images': [
          {'image_id': 'actual'},
        ],
      });
      final result = (await run(id))['details'] as Map;
      expect([approvals, backups, starts], [1, 1, 1]);
      expect(result['images'].single['image_id'], 'actual');
      expect(result['actual_anlas'], null);
      expect(result['estimated_anlas'], 12);
      expect(result['authorization']['source'], 'user_button');
      expect(tools.activeId, null);
      await expectLater(run(id), throwsA(error('quote_missing')));
    },
  );

  test(
    'parallel attempts reserve a quote before awaiting a human answer',
    () async {
      final id = await prepare();
      final decision = Completer<bool>();
      approval = () => decision.future;
      final first = run(id);
      await expectLater(run(id), throwsA(error('quote_in_use')));
      decision.complete(false);
      await first;
      expect(approvals, 1);
      expect(starts, 0);
    },
  );

  test(
    'quote expires and belongs only to the conversation that prepared it',
    () async {
      final id = await prepare();
      await expectLater(
        run('another-chat-id'),
        throwsA(error('quote_missing')),
      );
      now = now.add(const Duration(minutes: 5));
      await expectLater(run(id), throwsA(error('quote_expired')));
      expect(approvals, 0);
    },
  );

  test('invalid batches cannot prepare a quote', () async {
    for (final p in [
      {'requests': 0},
      {'requests': 1000},
      {'requests': 1.5},
      {'images_per_request': 5},
    ]) {
      await expectLater(prepare(p), throwsA(error('invalid_batch')));
    }
    await prepare({'requests': 999, 'images_per_request': 4});
    expect(starts, 0);
  });

  test(
    'draft, image bytes, effective prompt, account, endpoint and price changes invalidate approval',
    () async {
      final original = input;
      final alternatives = [
        generationInput(version: 'new draft'),
        generationInput(raw: const ImageParams(prompt: 'new prompt')),
        generationInput(account: 'other account'),
        generationInput(endpoint: 'other endpoint'),
        generationInput(estimate: 13),
        generationInput(balance: 99),
        generationInput(workflow: Object()),
        generationInput(contextVersion: 'changed alias definitions'),
      ];
      for (final next in alternatives) {
        input = original;
        final id = await prepare();
        input = next;
        await expectLater(run(id), throwsA(error('quote_changed')));
      }
      expect([approvals, backups, starts], [0, 0, 0]);
    },
  );

  test(
    'only advanced panel expansion can change without invalidating a quote',
    () async {
      final id = await prepare();
      input = generationInput(
        raw: input.raw.copyWith(advancedOptionsExpanded: true),
      );
      completion.complete({'status': 'completed'});
      await run(id);
      expect(starts, 1);
    },
  );
  test(
    'random alias projections do not invalidate unchanged definitions',
    () async {
      final id = await prepare();
      input = generationInput(
        effective: const ImageParams(prompt: 'another random selection'),
      );
      completion.complete({'status': 'completed'});
      await run(id);
      expect(starts, 1);
    },
  );

  test(
    'unavailable account/balance, insufficient funds, busy and cooldown stop before UI',
    () async {
      for (final reason in [
        'account_unavailable',
        'balance_unavailable',
        'insufficient_balance',
        'busy',
        'cooldown',
      ]) {
        input = generationInput(blocked: reason);
        final id = await prepare();
        await expectLater(run(id), throwsA(error(reason)));
      }
      expect([approvals, backups, starts], [0, 0, 0]);
    },
  );

  test('a fresh check after human approval rejects a changed draft', () async {
    final id = await prepare();
    approval = () async {
      input = generationInput(version: 'edited while waiting');
      return true;
    };
    await expectLater(run(id), throwsA(error('quote_changed')));
    expect([backups, starts], [0, 0]);
  });

  test(
    'cancel remains available even if the waiting quote became stale',
    () async {
      final id = await prepare();
      approval = () async {
        input = generationInput(version: 'edited');
        return false;
      };
      expect((await run(id))['details']['status'], 'cancelled');
      expect(starts, 0);
    },
  );

  test(
    'backup failure and changes during backup never start generation',
    () async {
      var id = await prepare();
      duringBackup = () async => throw StateError('disk failure');
      await expectLater(run(id), throwsStateError);
      expect(starts, 0);
      id = await prepare();
      duringBackup = () async {
        input = generationInput(version: 'user edit');
      };
      await expectLater(run(id), throwsA(error('quote_changed')));
      expect(starts, 0);
    },
  );

  test(
    'stopping during backup revokes approval and never starts generation',
    () async {
      final id = await prepare(), token = NaiAgentCancellation();
      duringBackup = () async {
        token.cancel();
      };
      await expectLater(run(id, token: token), throwsA(error('cancelled')));
      await expectLater(run(id), throwsA(error('quote_missing')));
      expect(starts, 0);
    },
  );

  test('binding disposal during backup never starts generation', () async {
    final id = await prepare();
    duringBackup = () async {
      alive = false;
    };
    await expectLater(run(id), throwsA(error('closed')));
    expect(starts, 0);
  });

  test(
    'a non-admitted native start can retry the unchanged approved quote',
    () async {
      final id = await prepare();
      admitted = false;
      await expectLater(run(id), throwsA(error('not_started')));
      admitted = true;
      completion.complete({'status': 'completed'});
      await run(id);
      expect(approvals, 1);
      expect(starts, 2);
    },
  );

  test(
    'an admitted native failure consumes approval and cannot run again',
    () async {
      final id = await prepare();
      final future = run(id);
      final assertion = expectLater(future, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      completion.completeError(StateError('synthetic native failure'));
      await assertion;
      await expectLater(run(id), throwsA(error('quote_missing')));
      expect(starts, 1);
      expect(tools.activeId, null);
    },
  );

  test(
    'stop cancels only the owned active run; late cancellation cannot touch a new run',
    () async {
      final id = await prepare(), token = NaiAgentCancellation();
      final running = run(id, token: token);
      await Future<void>.delayed(Duration.zero);
      expect(tools.activeId, 'own-run');
      await expectLater(
        tools.cancel({'run_id': 'manual-run'}, NaiAgentCancellation()),
        throwsA(error('run_not_owned')),
      );
      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(cancels, 1);
      completion.complete({'status': 'cancelled'});
      await running;
      expect(
        (await tools.cancel({}, NaiAgentCancellation()))['details']['status'],
        'already_finished',
      );
      expect(cancels, 1);
    },
  );
}
