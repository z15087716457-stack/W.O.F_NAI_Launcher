import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_library_service.dart';

void main() {
  late Directory tempDir;
  late Directory libraryDir;
  late Model3dLibraryService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model3d_lib_test');
    libraryDir = Directory('${tempDir.path}/library');
    service = Model3dLibraryService(libraryDir: libraryDir);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<File> sourceFile(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  test('imports model and returns content-addressed ref', () async {
    final source = await sourceFile('a.glb', [1, 2, 3]);
    final ref = await service.importModel(source);
    expect(ref, startsWith('lib:'));
    final hash = ref.substring(4);
    expect(hash, hasLength(64));
    expect(File('${libraryDir.path}/$hash.glb').existsSync(), isTrue);
  });

  test('deduplicates identical content', () async {
    final s1 = await sourceFile('a.glb', [1, 2, 3]);
    final s2 = await sourceFile('b.glb', [1, 2, 3]);
    final ref1 = await service.importModel(s1);
    final ref2 = await service.importModel(s2);
    expect(ref1, ref2);
    expect(libraryDir.listSync().whereType<File>(), hasLength(1));
  });

  test(
    'packs external glTF buffer and texture into a standalone GLB',
    () async {
      await sourceFile('mesh.bin', [1, 2, 3, 4]);
      await sourceFile('color.png', [137, 80, 78, 71]);
      final source = await sourceFile(
        'scene.gltf',
        utf8.encode(
          jsonEncode({
            'asset': {'version': '2.0'},
            'buffers': [
              {'uri': 'mesh.bin', 'byteLength': 4},
            ],
            'bufferViews': [
              {'buffer': 0, 'byteLength': 4},
            ],
            'images': [
              {'uri': 'color.png'},
            ],
          }),
        ),
      );
      final ref = await service.importModel(source);
      final bytes = await service.resolveFile(ref)!.readAsBytes();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(0, Endian.little), 0x46546c67);
      final length = header.getUint32(12, Endian.little);
      final document =
          jsonDecode(utf8.decode(bytes.sublist(20, 20 + length))) as Map;
      expect(document['images'][0], {'bufferView': 1, 'mimeType': 'image/png'});
      expect(document['buffers'], [
        {'byteLength': 8},
      ]);
      expect(bytes.sublist(28 + length), [1, 2, 3, 4, 137, 80, 78, 71]);
      await File('${tempDir.path}/mesh.bin').delete();
      await File('${tempDir.path}/color.png').delete();
      expect(await service.resolveFile(ref)!.readAsBytes(), bytes);
    },
  );

  test('rejects remote and out-of-folder glTF resources', () async {
    for (final uri in ['https://example.com/private.bin', '../outside.bin']) {
      final source = await sourceFile(
        'bad.gltf',
        utf8.encode(
          jsonEncode({
            'asset': {'version': '2.0'},
            'buffers': [
              {'uri': uri, 'byteLength': 4},
            ],
          }),
        ),
      );
      await expectLater(
        service.importModel(source),
        throwsA(isA<Model3dImportException>()),
      );
    }
    expect(libraryDir.existsSync(), false);
  });

  test(
    'exports an embedded rig for browser validation after deleting its glTF resources',
    () async {
      final glb = await File(
        'test/fixtures/model3d_synthetic_rig.glb',
      ).readAsBytes();
      final jsonLength = ByteData.sublistView(glb).getUint32(12, Endian.little);
      final model =
          jsonDecode(utf8.decode(glb.sublist(20, 20 + jsonLength))) as Map;
      model['buffers'][0]['uri'] = 'rig.bin';
      await sourceFile('rig.bin', glb.sublist(28 + jsonLength));
      await sourceFile(
        'white.png',
        await File('test/fixtures/model3d_white.png').readAsBytes(),
      );
      model['images'] = [
        {'uri': 'white.png'},
      ];
      model['textures'] = [
        {'source': 0},
      ];
      model['materials'][0]['pbrMetallicRoughness']['baseColorTexture'] = {
        'index': 0,
      };
      final source = await sourceFile(
        'rig.gltf',
        utf8.encode(jsonEncode(model)),
      );
      final ref = await service.importModel(source);
      final packed = await service.resolveFile(ref)!.readAsBytes();
      await File('${tempDir.path}/rig.bin').delete();
      await File('${tempDir.path}/white.png').delete();
      expect(await service.resolveFile(ref)!.readAsBytes(), packed);
      if (Platform.environment['CAPTURE_STUDIO_UI'] == '1') {
        final output = File(
          '.dart_tool/model3d-official-20261005/web/packed-rig.glb',
        );
        await output.parent.create(recursive: true);
        await output.writeAsBytes(packed);
      }
    },
  );

  test('rejects oversized file', () async {
    final small = Model3dLibraryService(
      libraryDir: libraryDir,
      maxFileBytes: 2,
    );
    final source = await sourceFile('big.glb', [1, 2, 3]);
    expect(
      () => small.importModel(source),
      throwsA(isA<Model3dImportException>()),
    );
  });

  test('urlPathFor maps refs', () {
    final hash = 'c' * 64;
    expect(service.urlPathFor('lib:$hash'), '/models/$hash.glb');
    expect(
      service.urlPathFor(Model3dLibraryService.builtinMannequinRef),
      isNull,
    );
    expect(service.urlPathFor('bogus:x'), isNull);
  });

  test('resolveFile maps only lib refs', () {
    final hash = 'd' * 64;
    expect(service.resolveFile('lib:$hash')?.path, contains('$hash.glb'));
    expect(
      service.resolveFile(Model3dLibraryService.builtinMannequinRef),
      isNull,
    );
  });

  test('rejects path traversal and malformed lib refs', () {
    expect(service.urlPathFor('lib:../evil'), isNull);
    expect(service.resolveFile('lib:../evil'), isNull);
    expect(service.urlPathFor('lib:not-a-hash'), isNull);
    expect(service.resolveFile('lib:not-a-hash'), isNull);
  });

  test('rejects uppercase hex hash', () {
    final hash = 'C' * 64;
    expect(service.resolveFile('lib:$hash'), isNull);
  });

  test('import leaves only the final file and no temp files', () async {
    final source = await sourceFile('a.glb', [1, 2, 3]);
    final ref = await service.importModel(source);
    final hash = ref.substring(4);
    final files = libraryDir.listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    expect(files.single.path, endsWith('$hash.glb'));
    expect(files.single.path, isNot(contains('.tmp')));
  });
}
