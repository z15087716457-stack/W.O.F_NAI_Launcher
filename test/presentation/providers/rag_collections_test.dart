import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/core/rag/rag_gallery_search.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';

const _worker = r'''
import sys,json,threading
lock=threading.Lock();sources={};suspended=False
def emit(v):
 with lock:print(json.dumps(v),flush=True)
def status():
 tags=sources.get('tags',{'indexed':0,'total':0,'complete':False})
 return {**tags,'sources':sources,'jobs':[],'suspended':suspended}
emit({'event':'ready','protocol':1})
for line in sys.stdin:
 r=json.loads(line);op=r['op'];p=r.get('params',{});source=p.get('source','tags')
 if op=='shutdown':break
 if op=='cancel':continue
 i=r['id']
 if op=='configure':
  sources={s:{'indexed':8,'total':8,'complete':True,'partial':False,'building':False,'paused':False,'auto_update_allowed':False} for s in p['sources']};result=status()
 elif op=='status':result=status()
 elif op=='preview':result={'plan_id':source,'documents':2,'total':8}
 elif op=='start':
  emit({'event':'index','source':source,'job_id':source,'phase':'complete',**sources[source]});result={'job_id':source}
 elif op=='clear':
  sources[source]={'indexed':0,'total':8,'complete':False,'building':False};result=sources[source]
 elif op=='suspend':suspended=True;result=status()
 elif op=='release':suspended=False;result={}
 elif op=='text_search':
  result={'items':[{'id':source+'-hit','title':'Saved','snippet':'rain','section':'article'}]}
  if p['query']=='delay':threading.Timer(.2,emit,args=[{'id':i,'result':result}]).start();continue
 elif op=='gallery_search':
  with open(p['scope'],encoding='utf-8') as f:paths=json.load(f)
  result={'items':[{'id':'gallery-hit','path':paths[0],'channel':'visual'}] if paths else []}
 else:result={}
 emit({'id':i,'result':result})
''';

class _Settings extends RagSettingsController {
  @override
  RagSettings build() => RagSettings(
    enabled: true,
    tagsEnabled: false,
    wikiEnabled: true,
    blocksEnabled: true,
    embedding: 'fixture',
    reranker: 'fixture',
    python: Platform.environment['RAG_TEST_PYTHON']!,
  );
  @override
  Future<void> update(RagSettings value) async {
    state = value;
  }
}

class _Blocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock.create(
        id: 'saved',
        title: 'Storm',
        content: 'rain',
        thumbnail: 'C:/private/not-exported.png',
      ),
    ],
    folders: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final python = Platform.environment['RAG_TEST_PYTHON'];
  late Directory root;
  late ProviderContainer container;
  late RagController controller;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('rag-collections-');
    container = ProviderContainer(
      overrides: [
        ragSettingsProvider.overrideWith(_Settings.new),
        promptBlockLibraryNotifierProvider.overrideWith(_Blocks.new),
        ragDirectoryProvider.overrideWithValue(() async => root),
        ragSourcePathsProvider.overrideWithValue(
          () async => (catalog: 'fixture', runtime: '', wiki: 'fixture'),
        ),
        ragGalleryRootsProvider.overrideWithValue(() async => [root.path]),
        ragClientStarterProvider.overrideWithValue(
          ({required python, required directory}) => RagClient.start(
            python: python,
            directory: directory,
            loadAsset: (name) async =>
                name.endsWith('worker.py') ? _worker : '',
          ),
        ),
      ],
    );
    controller = container.read(ragControllerProvider.notifier);
    await controller.refresh();
  });
  tearDown(() async {
    await DesktopAppShutdownService.prepareBackgroundShutdown();
    container.dispose();
    await root.delete(recursive: true);
  });
  group(
    'collection routing with a real JSON child',
    () {
      test(
        'discarded and consumed plans cannot start or clear a live index',
        () async {
          final plan = await controller.preview(source: RagSource.wiki);
          controller.discardPlan(plan['plan_id'] as String);
          await expectLater(
            controller.start(
              plan['plan_id'] as String,
              rebuild: true,
              source: RagSource.wiki,
            ),
            throwsA(isA<RagException>()),
          );
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.wiki)
                .indexed,
            8,
          );
          final next = await controller.preview(source: RagSource.wiki);
          await controller.start(
            next['plan_id'] as String,
            source: RagSource.wiki,
          );
          await expectLater(
            controller.start(
              next['plan_id'] as String,
              rebuild: true,
              source: RagSource.wiki,
            ),
            throwsA(isA<RagException>()),
          );
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.wiki)
                .indexed,
            8,
          );
        },
      );
      test('a plan cannot be used for another collection', () async {
        final plan = await controller.preview(source: RagSource.wiki);
        await expectLater(
          controller.start(
            plan['plan_id'] as String,
            rebuild: true,
            source: RagSource.blocks,
          ),
          throwsA(isA<RagException>()),
        );
        expect(
          container
              .read(ragControllerProvider)
              .forSource(RagSource.blocks)
              .indexed,
          8,
        );
      });
      test(
        'gallery transport uses an ephemeral scope and independent status',
        () async {
          await container
              .read(ragSettingsProvider.notifier)
              .update(
                container
                    .read(ragSettingsProvider)
                    .copyWith(galleryEnabled: true),
              );
          await controller.preview(source: RagSource.gallery);
          final result = await controller.searchGallery(
            query: 'private-gallery-query',
            allowed: ['${root.path}/image.png'],
            mode: RagGalleryMode.visual,
            cancellation: RagCancellation(),
          );
          expect(result.single.path, '${root.path}/image.png');
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.gallery)
                .searching,
            0,
          );
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.wiki)
                .indexed,
            8,
          );
          expect(
            await Directory('${root.path}/search-scopes').list().toList(),
            isEmpty,
          );
          expect(
            await File(
              '${root.path}/sources/gallery-roots.json',
            ).readAsString(),
            isNot(contains('private-gallery-query')),
          );
        },
      );
      test(
        'Wiki and blocks are usable with tag recommendations disabled',
        () async {
          final state = container.read(ragControllerProvider);
          expect(state.runtimeReady, isTrue);
          expect(state.indexed, 0);
          expect(state.forSource(RagSource.wiki).available, isTrue);
          expect(state.forSource(RagSource.blocks).available, isTrue);
          final result = await controller.searchText(
            RagTextQuery(source: RagSource.blocks, query: 'storm'),
            cancellation: RagCancellation(),
          );
          expect(result.single.id, 'blocks-hit');
          final raw = await File(
            '${root.path}/sources/blocks.json',
          ).readAsString();
          expect(raw, contains('rain'));
          expect(raw, isNot(contains('not-exported')));
        },
      );
      test(
        'a completion in the same frame as start cannot leave a phantom build',
        () async {
          final plan = await controller.preview(source: RagSource.wiki);
          await controller.start(
            plan['plan_id'] as String,
            source: RagSource.wiki,
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
          final state = container
              .read(ragControllerProvider)
              .forSource(RagSource.wiki);
          expect(state.busy, isFalse);
          expect(state.jobId, isNull);
          expect(state.complete, isTrue);
        },
      );
      test(
        'cancellation and counters belong only to the querying source',
        () async {
          final cancellation = RagCancellation();
          final search = controller.searchText(
            RagTextQuery(source: RagSource.wiki, query: 'delay'),
            cancellation: cancellation,
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
          final state = container.read(ragControllerProvider);
          expect(state.searching, 0);
          expect(state.forSource(RagSource.wiki).searching, 1);
          expect(state.forSource(RagSource.blocks).searching, 0);
          cancellation.cancel();
          expect(await search, isEmpty);
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.wiki)
                .searching,
            0,
          );
        },
      );
      test(
        'clearing Wiki preserves blocks; GPU suspension covers every source',
        () async {
          await controller.clear(source: RagSource.wiki);
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.wiki)
                .indexed,
            0,
          );
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.blocks)
                .indexed,
            8,
          );
          await controller.suspendForGpu();
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.blocks)
                .available,
            isFalse,
          );
          expect(
            await controller.searchText(
              RagTextQuery(source: RagSource.blocks, query: 'storm'),
              cancellation: RagCancellation(),
            ),
            isEmpty,
          );
          await controller.releaseGpu();
          expect(
            container
                .read(ragControllerProvider)
                .forSource(RagSource.blocks)
                .available,
            isTrue,
          );
        },
      );
      test(
        'disabling a source stops queries and retains its saved snapshot',
        () async {
          await container
              .read(ragSettingsProvider.notifier)
              .update(
                container
                    .read(ragSettingsProvider)
                    .copyWith(blocksEnabled: false),
              );
          expect(
            await controller.searchText(
              RagTextQuery(source: RagSource.blocks, query: 'storm'),
              cancellation: RagCancellation(),
            ),
            isEmpty,
          );
          expect(
            await File('${root.path}/sources/blocks.json').exists(),
            isTrue,
          );
          await controller.refresh();
        },
      );
    },
    skip: python == null
        ? 'Set RAG_TEST_PYTHON for isolated process integration'
        : false,
  );
}
