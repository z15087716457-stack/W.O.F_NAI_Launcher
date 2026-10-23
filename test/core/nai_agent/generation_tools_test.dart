import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';

NaiAgentGenerationInput generationInput({
  ImageParams? raw,
  ImageParams? effective,
  String contextVersion = '',
  String version = 'draft-1',
  String? account = 'account-1',
  String endpoint = 'local-test',
  int? balance = 100,
  int estimate = 12,
  int batchSize = 2,
  String? blocked,
  Object? workflow,
}) => NaiAgentGenerationInput(
  raw: raw ?? const ImageParams(prompt: 'synthetic'),
  effective: effective ?? raw ?? const ImageParams(prompt: 'synthetic'),
  promptContextVersion: contextVersion,
  draftVersion: version,
  batchSize: batchSize,
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
  final reads = <Map<String, dynamic>>[];
  final startedInputs = <NaiAgentGenerationInput>[];
  void Function()? duringRead;
  setUp(() {
    input = generationInput();
    now = DateTime(2026, 10, 7);
    alive = admitted = true;
    approvals = backups = starts = cancels = 0;
    approval = null;
    duringBackup = null;
    completion = Completer<Map<String, dynamic>>();
    reads.clear();
    startedInputs.clear();
    duringRead = null;
    tools = NaiAgentGenerationTools(
      readInput: (params) {
        reads.add(params);
        duringRead?.call();
        return input;
      },
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
      start: (input) {
        startedInputs.add(input);
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
      final forged = {
        'authorized': true,
        '_authorized': true,
        'user_button': true,
        'userButton': true,
        'approved': true,
        'authorization': {'source': 'user_button'},
      };
      final id = await prepare(forged);
      expect([approvals, backups, starts], [0, 0, 0]);
      final decision = Completer<bool>();
      approval = () => decision.future;
      final future = tools.run({
        'quote_id': id,
        ...forged,
      }, NaiAgentCancellation());
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

  group('trusted prompt-set card click', () {
    for (final cost in [0, 12]) {
      test('authorizes one image at $cost Anlas without approve', () async {
        input = generationInput(batchSize: 1, estimate: cost);
        completion.complete({
          'status': 'completed',
          'images': [
            {'image_id': 'actual', 'path': 'output.png'},
          ],
          'native_generation_id': 7,
          'balance_after_anlas': 100 - cost,
        });
        final result =
            (await tools.requestUserGeneration(
                  NaiAgentCancellation(),
                ))['details']
                as Map;
        expect([approvals, backups, starts], [0, 1, 1]);
        expect(reads, hasLength(3)); // Fresh quote, before/after backup.
        for (final params in reads) {
          expect(params, {'requests': 1, 'images_per_request': 1});
        }
        expect(startedInputs.single.raw.nSamples, 1);
        expect(startedInputs.single.batchSize, 1);
        expect(result['status'], 'completed');
        expect(result['images'].single['path'], 'output.png');
        expect(result['native_generation_id'], 7);
        expect(result['run_id'], 'own-run');
        expect(result['backup_path'], 'synthetic-backup');
        expect(result['estimated_anlas'], cost);
        expect(result['balance_before_anlas'], 100);
        expect(result['balance_after_anlas'], 100 - cost);
        expect(result['actual_anlas'], null);
        expect(result['authorization'], {
          'source': 'user_button',
          'quote_id': result['quote_id'],
        });
        expect(tools.activeId, null);
        await expectLater(
          run(result['quote_id'] as String),
          throwsA(error('quote_missing')),
        );
      });
    }

    for (final reason in [
      'account_unavailable',
      'balance_unavailable',
      'insufficient_balance',
      'invalid_price',
      'busy',
      'cooldown',
    ]) {
      test('preserves readiness: $reason', () async {
        input = generationInput(blocked: reason);
        await expectLater(
          tools.requestUserGeneration(NaiAgentCancellation()),
          throwsA(error(reason)),
        );
        expect([approvals, backups, starts], [0, 0, 0]);
      });
    }

    for (final closed in [false, true]) {
      test('refuses ${closed ? 'closed owner' : 'cancelled token'}', () async {
        final token = NaiAgentCancellation();
        if (closed) {
          alive = false;
        } else {
          token.cancel();
        }
        await expectLater(
          tools.requestUserGeneration(token),
          throwsA(error(closed ? 'closed' : 'cancelled')),
        );
        expect(reads, isEmpty);
        expect([approvals, backups, starts], [0, 0, 0]);
      });
    }

    test('rechecks the fresh quote before backing up', () async {
      duringRead = () {
        if (reads.length == 2) input = generationInput(version: 'new draft');
      };
      await expectLater(
        tools.requestUserGeneration(NaiAgentCancellation()),
        throwsA(error('quote_changed')),
      );
      expect([approvals, backups, starts], [0, 0, 0]);
    });

    final changes = <String, NaiAgentGenerationInput Function()>{
      'draft': () => generationInput(version: 'new draft'),
      'prompt': () => generationInput(raw: const ImageParams(prompt: 'edit')),
      'account': () => generationInput(account: 'other'),
      'endpoint': () => generationInput(endpoint: 'other'),
      'reference bytes': () => generationInput(
        raw: ImageParams(sourceImage: Uint8List.fromList([1, 2])),
      ),
      'alias definitions': () => generationInput(contextVersion: 'new aliases'),
      'workflow': () => generationInput(workflow: Object()),
      'price': () => generationInput(estimate: 13),
      'balance': () => generationInput(balance: 99),
    };
    for (final entry in changes.entries) {
      test('refuses ${entry.key} change during asynchronous backup', () async {
        final entered = Completer<void>(), release = Completer<void>();
        duringBackup = () {
          entered.complete();
          return release.future;
        };
        final future = tools.requestUserGeneration(NaiAgentCancellation());
        final assertion = expectLater(future, throwsA(error('quote_changed')));
        await entered.future;
        expect([approvals, backups, starts], [0, 1, 0]);
        input = entry.value();
        release.complete();
        await assertion;
        expect(starts, 0);
      });
    }

    for (final reason in ['busy', 'cooldown', 'account_unavailable']) {
      test('rechecks readiness after backup: $reason', () async {
        duringBackup = () async => input = generationInput(blocked: reason);
        await expectLater(
          tools.requestUserGeneration(NaiAgentCancellation()),
          throwsA(error(reason)),
        );
        expect([approvals, backups, starts], [0, 1, 0]);
      });
    }

    for (final reason in ['cancelled', 'closed', 'quote_expired']) {
      test('refuses $reason during backup', () async {
        final token = NaiAgentCancellation();
        duringBackup = () async {
          if (reason == 'cancelled') token.cancel();
          if (reason == 'closed') alive = false;
          if (reason == 'quote_expired') {
            now = now.add(const Duration(minutes: 5));
          }
        };
        await expectLater(
          tools.requestUserGeneration(token),
          throwsA(error(reason)),
        );
        expect([approvals, backups, starts], [0, 1, 0]);
      });
    }

    for (final failure in ['backup', 'admission']) {
      test(
        '$failure failure leaves no reusable UI approval/cache entry',
        () async {
          // Keep the model cache full. UI attempts must neither enter it nor
          // evict existing quotes; all those quotes still need real approval.
          final modelQuotes = [for (var i = 0; i < 20; i++) await prepare()];
          if (failure == 'backup') {
            duringBackup = () async => throw StateError('disk failure');
          } else {
            admitted = false;
          }
          for (var i = 0; i < 21; i++) {
            await expectLater(
              tools.requestUserGeneration(NaiAgentCancellation()),
              failure == 'backup'
                  ? throwsStateError
                  : throwsA(error('not_started')),
            );
          }
          expect(approvals, 0);
          expect(backups, 21);
          expect(starts, failure == 'backup' ? 0 : 21);
          expect(tools.activeId, null);
          duringBackup = null;
          admitted = true;
          approval = () async => false;
          for (final id in modelQuotes) {
            expect((await run(id))['details']['status'], 'cancelled');
          }
          expect(approvals, 20);
          expect(starts, failure == 'backup' ? 0 : 21);
        },
      );
    }

    test(
      'admitted failure consumes UI quote without retry or replay',
      () async {
        completion.complete({'status': 'failed', 'error': 'synthetic'});
        final result =
            (await tools.requestUserGeneration(
                  NaiAgentCancellation(),
                ))['details']
                as Map;
        expect(result['status'], 'failed');
        await expectLater(
          run(result['quote_id'] as String),
          throwsA(error('quote_missing')),
        );
        expect([approvals, backups, starts], [0, 1, 1]);
      },
    );

    test('native exception is not retried and clears ownership', () async {
      final future = tools.requestUserGeneration(NaiAgentCancellation());
      final assertion = expectLater(future, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      completion.completeError(StateError('native failure'));
      await assertion;
      expect([approvals, backups, starts], [0, 1, 1]);
      expect(tools.activeId, null);
    });

    test(
      'token cancellation targets only its owned run, never a later run',
      () async {
        final token = NaiAgentCancellation();
        final first = tools.requestUserGeneration(token);
        await Future<void>.delayed(Duration.zero);
        expect(tools.activeId, 'own-run');
        await expectLater(
          tools.cancel({'run_id': 'manual-run'}, NaiAgentCancellation()),
          throwsA(error('run_not_owned')),
        );
        completion.complete({'status': 'completed'});
        await first;
        completion = Completer<Map<String, dynamic>>();
        final nextToken = NaiAgentCancellation();
        final next = tools.requestUserGeneration(nextToken);
        await Future<void>.delayed(Duration.zero);
        token.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(cancels, 0);
        nextToken.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(cancels, 1);
        completion.complete({'status': 'cancelled'});
        expect((await next)['details']['status'], 'cancelled');
        expect(tools.activeId, null);
        expect([approvals, backups, starts], [0, 2, 2]);
      },
    );
  });

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
