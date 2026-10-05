import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// 模型导入失败(超限、IO 错误等)
class Model3dImportException implements Exception {
  final String message;

  const Model3dImportException(this.message);

  @override
  String toString() => 'Model3dImportException: $message';
}

/// 3D 模型库:按 SHA-256 内容寻址存储导入的模型文件
///
/// modelRef 约定:
/// - `builtin:mannequin` 内置程序化人偶(JS 侧生成,不占库文件)
/// - `lib:<sha256>`      库目录下 `<sha256>.glb`
class Model3dLibraryService {
  Model3dLibraryService({
    required this.libraryDir,
    this.maxFileBytes = 200 * 1024 * 1024,
  });

  static const builtinMannequinRef = 'builtin:mannequin';
  static const emptySceneRef = 'empty';
  static const _libPrefix = 'lib:';
  static final _hashPattern = RegExp(r'^[a-f0-9]{64}$');

  final Directory libraryDir;
  final int maxFileBytes;

  /// 导入模型:校验大小 → 流式 SHA-256 → 临时文件拷贝后原子改名(已存在则去重跳过)
  Future<String> importModel(File source) async {
    try {
      final length = await source.length();
      if (length > maxFileBytes) {
        throw Model3dImportException(
          'file too large: $length > $maxFileBytes bytes',
        );
      }
      final packed = p.extension(source.path).toLowerCase() == '.gltf'
          ? await _packGltf(source)
          : null;
      final digest = packed == null
          ? await sha256.bind(source.openRead()).first
          : sha256.convert(packed);
      final hash = digest.toString();
      final target = File(p.join(libraryDir.path, '$hash.glb'));
      if (!await target.exists()) {
        await libraryDir.create(recursive: true);
        final temp = File('${target.path}.tmp-$hash');
        try {
          if (packed == null) {
            await source.copy(temp.path);
          } else {
            await temp.writeAsBytes(packed, flush: true);
          }
          await temp.rename(target.path);
        } catch (_) {
          if (await temp.exists()) {
            await temp.delete();
          }
          rethrow;
        }
      }
      return '$_libPrefix$hash';
    } on FileSystemException catch (e) {
      throw Model3dImportException('io error: $e');
    } on FormatException catch (e) {
      throw Model3dImportException('invalid glTF: ${e.message}');
    } on TypeError {
      throw const Model3dImportException('invalid glTF structure');
    } on RangeError {
      throw const Model3dImportException('invalid glTF buffer reference');
    }
  }

  /// Bundle local/data URI buffers and textures before moving a JSON glTF into
  /// the content-addressed library. Never fetch remote URLs during an import.
  Future<Uint8List> _packGltf(File source) async {
    final document = (jsonDecode(await source.readAsString()) as Map)
        .cast<String, dynamic>();
    final binary = BytesBuilder(copy: false);
    int append(List<int> bytes) {
      while (binary.length % 4 != 0) {
        binary.addByte(0);
      }
      final offset = binary.length;
      if (offset + bytes.length > maxFileBytes) {
        throw const Model3dImportException('model resources exceed size limit');
      }
      binary.add(bytes);
      return offset;
    }

    Future<Uint8List> readUri(String value) async {
      final uri = Uri.parse(value);
      if (uri.scheme == 'data') return uri.data!.contentAsBytes();
      if (uri.hasScheme ||
          uri.hasAuthority ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const Model3dImportException(
          'model resources must be local files',
        );
      }
      final base = p.normalize(p.absolute(source.parent.path));
      final resolved = p.normalize(p.join(base, Uri.decodeComponent(value)));
      if (!p.isWithin(base, resolved)) {
        throw const Model3dImportException(
          'model resource is outside its folder',
        );
      }
      final file = File(resolved);
      if (await file.length() > maxFileBytes) {
        throw const Model3dImportException('model resource exceeds size limit');
      }
      return file.readAsBytes();
    }

    final offsets = <int>[];
    for (final buffer in (document['buffers'] as List? ?? [])) {
      offsets.add(append(await readUri(buffer['uri'] as String)));
    }
    final views = (document['bufferViews'] as List? ?? <dynamic>[]);
    for (final view in views) {
      view['byteOffset'] =
          (view['byteOffset'] as int? ?? 0) + offsets[view['buffer'] as int];
      view['buffer'] = 0;
    }
    for (final image in (document['images'] as List? ?? [])) {
      final uri = image.remove('uri') as String?;
      if (uri == null) continue;
      final bytes = await readUri(uri);
      image['bufferView'] = views.length;
      image['mimeType'] ??= uri.startsWith('data:')
          ? Uri.parse(uri).data!.mimeType
          : switch (p.extension(uri).toLowerCase()) {
              '.png' => 'image/png',
              '.webp' => 'image/webp',
              '.ktx2' => 'image/ktx2',
              _ => 'image/jpeg',
            };
      views.add({
        'buffer': 0,
        'byteOffset': append(bytes),
        'byteLength': bytes.length,
      });
    }
    while (binary.length % 4 != 0) {
      binary.addByte(0);
    }
    document['bufferViews'] = views;
    document['buffers'] = [
      {'byteLength': binary.length},
    ];
    final json = utf8.encode(jsonEncode(document));
    final jsonLength = (json.length + 3) & ~3;
    final length = 12 + 8 + jsonLength + 8 + binary.length;
    if (length > maxFileBytes) {
      throw const Model3dImportException('packed model exceeds size limit');
    }
    final output = Uint8List(length);
    final header = ByteData.sublistView(output);
    for (final entry in {
      0: 0x46546c67,
      4: 2,
      8: length,
      12: jsonLength,
      16: 0x4e4f534a,
      20 + jsonLength: binary.length,
      24 + jsonLength: 0x004e4942,
    }.entries) {
      header.setUint32(entry.key, entry.value, Endian.little);
    }
    output.fillRange(20, 20 + jsonLength, 32);
    output.setRange(20, 20 + json.length, json);
    output.setRange(28 + jsonLength, length, binary.takeBytes());
    return output;
  }

  /// modelRef → 本地服务 URL 路径(builtin、未知前缀与非法 hash 返回 null)
  String? urlPathFor(String modelRef) {
    if (!modelRef.startsWith(_libPrefix)) return null;
    final hash = modelRef.substring(_libPrefix.length);
    if (!_hashPattern.hasMatch(hash)) return null;
    return '/models/$hash.glb';
  }

  /// modelRef → 库文件(不检查存在性;builtin、未知前缀与非法 hash 返回 null)
  File? resolveFile(String modelRef) {
    if (!modelRef.startsWith(_libPrefix)) return null;
    final hash = modelRef.substring(_libPrefix.length);
    if (!_hashPattern.hasMatch(hash)) return null;
    return File(p.join(libraryDir.path, '$hash.glb'));
  }
}
