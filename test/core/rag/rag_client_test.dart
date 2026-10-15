import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';

// A real child process exercises JSON framing, stream shutdown and cancellation
// without loading models, opening user databases or making network requests.
const _worker = r'''
import sys,json,threading
lock=threading.Lock(); cancelled=[]
def emit(v):
 with lock: print(json.dumps(v,ensure_ascii=False),flush=True)
emit({'event':'ready','protocol':1})
for line in sys.stdin:
 r=json.loads(line);op=r['op']
 if op=='shutdown': break
 if op=='cancel': cancelled.append(r['target']);continue
 i=r['id'];p=r.get('params',{})
 if op=='delay': threading.Timer(.12,emit,args=[{'id':i,'result':p}]).start()
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
