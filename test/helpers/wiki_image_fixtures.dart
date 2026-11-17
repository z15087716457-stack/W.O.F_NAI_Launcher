import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const wikiImageSource = '''
h4. Definition
A single visible person. Keep this definition.
h4. Examples
* !post #11: Single person in a landscape
* !asset #12: A single character
h4. Non-examples
* !post #13: Other people are also visible
''';

const wikiImageTranslation = '''
## 定义
画面里只有一个人物。保留这段判定说明。
## 示例
* post #11：场景中的单个人物
* !asset #12：单个人物
## 非示例
* !post #13：画面中还有其他人物
''';

Map<String, dynamic> wikiImageMetadata(int id, {bool asset = false}) {
  final variants = [
    {
      'type': '360x360',
      'url': 'https://cdn.donmai.us/${asset ? 'asset' : 'post'}/$id.jpg',
    },
    {
      'type': '720x720',
      'url': 'https://cdn.donmai.us/${asset ? 'asset' : 'post'}/$id.webp',
    },
  ];
  return asset
      ? {'id': id, 'status': 'active', 'variants': variants}
      : {
          'id': id,
          'media_asset': {'variants': variants},
        };
}

class WikiImageFixtureCache extends Fake implements BaseCacheManager {
  WikiImageFixtureCache(this.bytes);
  final Uint8List bytes;
  final fetched = <String>[];
  static Future<WikiImageFixtureCache> load() async => WikiImageFixtureCache(
    (await rootBundle.load(
      'assets/images/explore-example-c01.jpg',
    )).buffer.asUint8List(),
  );
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    fetched.add(url);
    yield FileInfo(
      MemoryFileSystem().file('fixture.jpg')..writeAsBytesSync(bytes),
      FileSource.Cache,
      DateTime(2030),
      url,
    );
  }

  @override
  Future<void> removeFile(String key) async {}
}

Future<void> settleWikiImageFixtures(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    if (i >= 5 && !tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle();
}

Future<void> captureWikiImageLayout(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  final sidePreview = Platform.environment['CAPTURE_WIKI_SIDE_PREVIEW'] == '1';
  if (!sidePreview && Platform.environment['CAPTURE_WIKI_IMAGE_PANEL'] != '1') {
    return;
  }
  await tester.pump();
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory(
      sidePreview
          ? '.dart_tool/wiki-side-preview-20261116/captures'
          : '.dart_tool/wiki-image-implementation-20261116/captures',
    )..createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
    if (sidePreview &&
        find
            .byKey(const Key('wiki-image-preview-panel'))
            .evaluate()
            .isNotEmpty) {
      final geometry = <String, Object>{};
      for (final key in [
        'tag-expansion-popup',
        'tag-expansion-wiki-panel',
        'tag-expansion-image-panel',
        'wiki-image-preview-panel',
        'wiki-preview-header',
        'wiki-preview-image',
        'wiki-preview-details',
        'wiki-viewer-source',
        'wiki-viewer-close',
        'wiki-viewer-prev',
        'wiki-viewer-next',
        'wiki-viewer-caption',
        'wiki-viewer-reset-zoom',
      ]) {
        final target = find.byKey(Key(key));
        if (target.evaluate().isEmpty) continue;
        final rect = tester.getRect(target);
        geometry[key] = {
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        };
      }
      File(
        '${folder.path}/$name.geometry.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(geometry));
    }
  });
}
