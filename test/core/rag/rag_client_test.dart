import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';

// A real child process exercises JSON framing, stream shutdown and cancellation
// without loading models, opening user databases or making network requests.
const _worker = r'''
import sys,json,threading,time
from pathlib import Path
lock=threading.Lock(); cancelled=[];shutdown={}
def emit(v):
 with lock: print(json.dumps(v,ensure_ascii=False),flush=True)
emit({'event':'ready','protocol':1})
for line in sys.stdin:
 r=json.loads(line);op=r['op']
 if op=='shutdown':
  time.sleep(shutdown.get('delay',0))
  if shutdown.get('noise'):
   sys.stderr.write('fixture drain\n'*20000);sys.stderr.flush()
   emit({'event':'draining','fixture':'x'*262144})
  if shutdown.get('marker'):Path(shutdown['marker']).write_text('saved')
  emit({'event':'shutdown','phase':'complete'})
  break
 if op=='cancel': cancelled.append(r['target']);continue
 i=r['id'];p=r.get('params',{})
 if op=='shutdown_setup': shutdown=p;emit({'id':i,'result':{}});continue
 if op=='configure':
  mode=p.get('mode','progress')
  def configure(i=i,mode=mode):
   import time
   for step in range(7):
    if mode in ('progress','wrong-owner','same-progress'):
     emit({'event':'initialization','request_id':i+(1 if mode=='wrong-owner' else 0),'phase':'restoring','processed':0 if mode=='same-progress' else step,'total':7})
    time.sleep(.04)
   emit({'id':i,'result':{'restored':True}})
  threading.Thread(target=configure,daemon=True).start();continue
 elif op=='delay': threading.Timer(.12,emit,args=[{'id':i,'result':p}]).start()
 elif op=='error': emit({'id':i,'error':{'code':'fixture_failure'}})
 elif op=='cancelled': emit({'id':i,'result':{'count':len(cancelled)}})
 elif op=='exit': break
 elif op=='broken': print('invalid-json',flush=True)
 else: emit({'id':i,'result':p})
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final python = Platform.environment['RAG_TEST_PYTHON'];
  late Directory directory;
  late RagClient client;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('studio-rag-ipc-');
    client = await RagClient.start(
      python: python!,
      directory: directory,
      loadAsset: (name) async => name.endsWith('worker.py') ? _worker : '',
    );
  });
  tearDown(() async {
    await client.close();
    await directory.delete(recursive: true);
  });
  group(
    'local JSON worker',
    () {
      test(
        'graceful close drains pipes and lets a checkpoint exceed three seconds',
        () async {
          final marker = File('${directory.path}/checkpoint-complete');
          await client.request('shutdown_setup', {
            'delay': 3.2,
            'noise': true,
            'marker': marker.path,
          });
          final pending = client.request('delay');
          final failed = expectLater(pending, throwsA(isA<RagException>()));
          final first = client.close();
          expect(client.close(), same(first));
          await failed;
          await first;
          expect(await marker.readAsString(), 'saved');
          expect(client.isClosed, isTrue);
        },
      );
      test(
        'a hung shutdown has a bounded deadline and cannot publish late state',
        () async {
          await client.close();
          client = await RagClient.start(
            python: python!,
            directory: directory,
            shutdownTimeout: const Duration(milliseconds: 200),
            loadAsset: (name) async =>
                name.endsWith('worker.py') ? _worker : '',
          );
          final marker = File('${directory.path}/must-not-exist');
          await client.request('shutdown_setup', {
            'delay': 60,
            'marker': marker.path,
          });
          final elapsed = Stopwatch()..start();
          await client.close();
          expect(elapsed.elapsed, lessThan(const Duration(seconds: 5)));
          expect(await marker.exists(), isFalse);
        },
      );
      test('configure progress renews only the idle budget', () async {
        final progress = <int>[];
        expect(
          await client.configure(
            {},
            idleTimeout: const Duration(milliseconds: 150),
            timeout: const Duration(seconds: 2),
            onProgress: (event) => progress.add(event['processed'] as int),
          ),
          {'restored': true},
        );
        expect(progress, [0, 1, 2, 3, 4, 5, 6]);
      });
      for (final mode in ['silent', 'wrong-owner']) {
        test(
          'configure $mode cannot bypass the no-progress deadline',
          () async {
            var callbacks = 0;
            await expectLater(
              client.configure(
                {'mode': mode},
                idleTimeout: const Duration(milliseconds: 120),
                onProgress: (_) => callbacks++,
              ),
              throwsA(
                isA<RagException>().having(
                  (e) => e.code,
                  'code',
                  'initialization_timeout',
                ),
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 350));
            expect(callbacks, 0);
            expect((await client.request('cancelled'))['count'], 1);
            expect(await client.request('echo'), isEmpty);
          },
        );
      }
      test(
        'configure still has a hard deadline despite continuous progress',
        () async {
          await expectLater(
            client.configure(
              {},
              timeout: const Duration(milliseconds: 150),
              idleTimeout: const Duration(seconds: 1),
            ),
            throwsA(
              isA<RagException>().having(
                (e) => e.code,
                'code',
                'initialization_timeout',
              ),
            ),
          );
        },
      );
      test(
        'repeated unchanged progress cannot hide a stalled initializer',
        () async {
          var callbacks = 0;
          await expectLater(
            client.configure(
              {'mode': 'same-progress'},
              idleTimeout: const Duration(milliseconds: 150),
              timeout: const Duration(seconds: 2),
              onProgress: (_) => callbacks++,
            ),
            throwsA(
              isA<RagException>().having(
                (e) => e.code,
                'code',
                'initialization_timeout',
              ),
            ),
          );
          expect(callbacks, 1);
        },
      );
      test(
        'configure cancellation releases progress ownership immediately',
        () async {
          final cancellation = RagCancellation();
          var callbacks = 0;
          final pending = client.configure(
            {},
            cancellation: cancellation,
            onProgress: (_) {
              callbacks++;
              cancellation.cancel();
            },
          );
          await expectLater(
            pending,
            throwsA(
              isA<RagException>().having((e) => e.code, 'code', 'cancelled'),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 350));
          expect(callbacks, 1);
          expect(client.isClosed, isFalse);
        },
      );
      test('Unicode and concurrent replies retain request ownership', () async {
        final slow = client.request('delay', {'text': '雨🌧，夜景'});
        expect(await client.request('echo', {'text': '角色负面'}), {
          'text': '角色负面',
        });
        expect(await slow, {'text': '雨🌧，夜景'});
      });
      test('cancelling one request leaves other requests usable', () async {
        final cancellation = RagCancellation();
        final pending = client.request('delay', {}, cancellation);
        final check = expectLater(
          pending,
          throwsA(
            isA<RagException>().having((e) => e.code, 'code', 'cancelled'),
          ),
        );
        cancellation.cancel();
        await check;
        expect((await client.request('cancelled'))['count'], 1);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        expect(await client.request('echo', {'valid': true}), {'valid': true});
      });
      test(
        'timeout cancels only that request and late replies are ignored',
        () async {
          await expectLater(
            client.request('delay', {}, null, const Duration(milliseconds: 15)),
            throwsA(
              isA<RagException>().having((e) => e.code, 'code', 'timeout'),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 180));
          expect((await client.request('cancelled'))['count'], 1);
          expect(await client.request('echo'), isEmpty);
        },
      );
      test(
        'backend errors preserve a bounded code and the process stays usable',
        () async {
          await expectLater(
            client.request('error'),
            throwsA(
              isA<RagException>().having(
                (e) => e.code,
                'code',
                'fixture_failure',
              ),
            ),
          );
          expect(await client.request('echo'), isEmpty);
        },
      );
      for (final op in ['exit', 'broken']) {
        test('$op completes pending requests and can be closed', () async {
          await expectLater(
            client.request(op),
            throwsA(
              isA<RagException>().having(
                (e) => e.code,
                'code',
                'worker_closed',
              ),
            ),
          );
          expect(client.isClosed, isTrue);
        });
      }
    },
    skip: python == null
        ? 'Set RAG_TEST_PYTHON to an isolated Python for IPC tests'
        : false,
  );
}
