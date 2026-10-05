import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/upscale/local_upscale_models.dart';

/// Private versioned files, independent of ComfyUI paths, ports and settings.
class LocalUpscaleModelManager {
  LocalUpscaleModelManager({
    Future<Directory> Function()? rootDirectory,
    Future<Uint8List> Function(String)? loadAsset,
    Dio? dio,
  }) : _rootDirectory = rootDirectory ?? _defaultDirectory,
       _loadAsset = loadAsset ?? _bundleBytes,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(minutes: 2),
             ),
           );

  static const manifestSha256 =
      'bceed7d6dc52eac1ea510bdb35e5617742f6d8029f5cf04e820f7c48a014135b';
  final Future<Directory> Function() _rootDirectory;
  final Future<Uint8List> Function(String) _loadAsset;
  final Dio _dio;
  Future<void>? _initializing;
  late Directory directory;
  late Map<String, dynamic> _manifest;
  bool _ready = false;
  bool _mutating = false;
  String? _lockedModelId;

  void claimInference(String id) {
    if (_mutating || _lockedModelId != null) {
      throw const LocalUpscaleException(LocalUpscaleError.busy);
    }
    _lockedModelId = id;
  }

  void releaseInference() => _lockedModelId = null;
  void dispose() => _dio.close(force: true);

  Future<void> _removeOwned(Directory target) async {
    if (!await target.exists()) return;
    if (!p.isWithin(
      await directory.resolveSymbolicLinks(),
      await target.resolveSymbolicLinks(),
    )) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
    }
    await target.delete(recursive: true);
  }

  static void _checkDownload(CancelToken? token) {
    if (token?.isCancelled ?? false) throw token!.cancelError!;
  }

  static Future<Directory> _defaultDirectory() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'upscale', 'v020'),
  );
  static Future<Uint8List> _bundleBytes(String path) async =>
      (await rootBundle.load(
        'assets/local_upscale/$path',
      )).buffer.asUint8List();

  Future<void> initialize() async {
    if (_ready) return;
    if (_initializing != null) return _initializing!;
    final future = _initialize();
    _initializing = future;
    try {
      await future;
      _ready = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    final manifest = await _loadAsset('manifest.json');
    if (sha256.convert(manifest).toString() != manifestSha256) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    _manifest = jsonDecode(utf8.decode(manifest)) as Map<String, dynamic>;
    directory = await _rootDirectory();
    await directory.create(recursive: true);
    for (final item
        in (_manifest['engine_files'] as List).cast<Map<String, dynamic>>()) {
      final relative = item['path'] as String;
      await _installBundled(
        relative,
        File(p.join(directory.path, relative)),
        item['sha256'] as String,
      );
    }
    for (final item in _filesFor(localUpscaleCatalog.first)) {
      final relative = item['name'] as String;
      await _installBundled(
        relative,
        File(p.join(_modelDirectory('anime').path, p.basename(relative))),
        item['sha256'] as String,
      );
    }
  }

  Future<void> _installBundled(
    String asset,
    File destination,
    String expected,
  ) async {
    if (await destination.exists() && await _hash(destination) == expected) {
      return;
    }
    final bytes = await _loadAsset(asset);
    if (sha256.convert(bytes).toString() != expected) {
      throw const LocalUpscaleException(LocalUpscaleError.integrity);
    }
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.${const Uuid().v4()}.part');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (await destination.exists()) await destination.delete();
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  static Future<String> _hash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  Directory _modelDirectory(String id) {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
    }
    return Directory(p.join(directory.path, 'models', id));
  }

  List<Map<String, dynamic>> _filesFor(LocalUpscaleModel model) =>
      (_manifest['model_files'] as List).cast<Map<String, dynamic>>().where((
        item,
      ) {
        final stem = p.basenameWithoutExtension(item['name'] as String);
        return model.engineName == 'realesr-animevideov3'
            ? model.scales.any((scale) => stem == '${model.engineName}-x$scale')
            : stem == model.engineName;
      }).toList();

  Future<List<LocalUpscaleModel>> models() async {
    await initialize();
    final models = <LocalUpscaleModel>[];
    for (final model in localUpscaleCatalog) {
      final files = _filesFor(model);
      var installed = files.isNotEmpty;
      for (final file in files) {
        installed &= await File(
          p.join(
            _modelDirectory(model.id).path,
            p.basename(file['name'] as String),
          ),
        ).exists();
      }
      models.add(model.withInstalled(installed));
    }
    final root = Directory(p.join(directory.path, 'models'));
    if (await root.exists()) {
      await for (final entry in root.list(followLinks: false)) {
        if (entry is! Directory ||
            !p.basename(entry.path).startsWith('custom-')) {
          continue;
        }
        try {
          final info =
              jsonDecode(
                    await File(p.join(entry.path, 'model.json')).readAsString(),
                  )
                  as Map<String, dynamic>;
          final id = p.basename(entry.path);
          models.add(
            LocalUpscaleModel(
              id: id,
              name: info['name'] as String,
              engineName: 'realesrgan-x4plus',
              scales: const [4],
              custom: true,
              installed:
                  await File(
                    p.join(entry.path, 'realesrgan-x4plus.bin'),
                  ).exists() &&
                  await File(
                    p.join(entry.path, 'realesrgan-x4plus.param'),
                  ).exists(),
            ),
          );
        } catch (_) {
          // A partial or unsupported import is never exposed as a usable model.
        }
      }
    }
    return models;
  }

  Future<(String, String, LocalUpscaleModel)> resolve(String id) async {
    await initialize();
    for (final item
        in (_manifest['engine_files'] as List).cast<Map<String, dynamic>>()) {
      final file = File(p.join(directory.path, item['path'] as String));
      if (!await file.exists()) {
        throw const LocalUpscaleException(LocalUpscaleError.engineMissing);
      }
      if (await _hash(file) != item['sha256']) {
        throw const LocalUpscaleException(LocalUpscaleError.integrity);
      }
    }
    final available = await models();
    final matches = available.where(
      (model) => model.id == id && model.installed,
    );
    if (matches.isEmpty) {
      throw const LocalUpscaleException(LocalUpscaleError.modelMissing);
    }
    final model = matches.first;
    final folder = _modelDirectory(id);
    if (model.custom) {
      final info =
          jsonDecode(
                await File(p.join(folder.path, 'model.json')).readAsString(),
              )
              as Map<String, dynamic>;
      for (final extension in ['bin', 'param']) {
        if (await _hash(
              File(p.join(folder.path, 'realesrgan-x4plus.$extension')),
            ) !=
            info['${extension}Sha256']) {
          throw const LocalUpscaleException(LocalUpscaleError.integrity);
        }
      }
    } else {
      for (final file in _filesFor(model)) {
        if (await _hash(
              File(p.join(folder.path, p.basename(file['name'] as String))),
            ) !=
            file['sha256']) {
          throw const LocalUpscaleException(LocalUpscaleError.integrity);
        }
      }
    }
    return (
      p.join(directory.path, 'windows', 'realesrgan-ncnn-vulkan.exe'),
      folder.path,
      model,
    );
  }

  void _claimMutation() {
    if (_mutating || _lockedModelId != null) {
      throw const LocalUpscaleException(LocalUpscaleError.busy);
    }
    _mutating = true;
  }

  Future<void> download(
    String id, {
    void Function(int, int)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await initialize();
    final model = localUpscaleCatalog
        .where((model) => model.id == id && !model.bundled)
        .firstOrNull;
    if (model == null) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
    }
    _claimMutation();
    final staging = Directory(
      p.join(directory.path, 'models', 'staging-${const Uuid().v4()}'),
    );
    try {
      final cache = File(p.join(directory.path, 'official-models.zip'));
      if (!await cache.exists() ||
          await _hash(cache) != _manifest['model_archive_sha256']) {
        final response = await _dio.get<List<int>>(
          _manifest['model_archive_url'] as String,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancelToken,
          onReceiveProgress: onProgress,
        );
        _checkDownload(cancelToken);
        final bytes = response.data!;
        if (sha256.convert(bytes).toString() !=
            _manifest['model_archive_sha256']) {
          throw const LocalUpscaleException(LocalUpscaleError.integrity);
        }
        await cache.writeAsBytes(bytes, flush: true);
      }
      _checkDownload(cancelToken);
      final compressed = await cache.readAsBytes();
      final wanted = _filesFor(model);
      final extracted = await Isolate.run(() {
        final archive = ZipDecoder().decodeBytes(compressed);
        return wanted.map((file) {
          final item = archive.findFile(file['name'] as String);
          if (item == null) {
            throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
          }
          final bytes = Uint8List.fromList(item.content as List<int>);
          if (sha256.convert(bytes).toString() != file['sha256']) {
            throw const LocalUpscaleException(LocalUpscaleError.integrity);
          }
          return (p.basename(item.name), bytes);
        }).toList();
      });
      await staging.create(recursive: true);
      for (final item in extracted) {
        _checkDownload(cancelToken);
        await File(
          p.join(staging.path, item.$1),
        ).writeAsBytes(item.$2, flush: true);
      }
      _checkDownload(cancelToken);
      final target = _modelDirectory(id);
      await _removeOwned(target);
      await staging.rename(target.path);
    } finally {
      _mutating = false;
      await _removeOwned(staging);
    }
  }

  Future<String> importPair(File param, File weights) async {
    await initialize();
    _claimMutation();
    final id = 'custom-${const Uuid().v4()}';
    final target = _modelDirectory(id);
    try {
      if (p.extension(param.path).toLowerCase() != '.param' ||
          p.extension(weights.path).toLowerCase() != '.bin' ||
          p.basenameWithoutExtension(param.path) !=
              p.basenameWithoutExtension(weights.path) ||
          await param.length() > 1024 * 1024 ||
          await weights.length() == 0 ||
          await weights.length() > 256 * 1024 * 1024) {
        throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
      }
      final content = await param.readAsString();
      if (!content.trimLeft().startsWith('7767517') ||
          !RegExp(r'\bInput\s').hasMatch(content) ||
          !RegExp(r'\bdata\b').hasMatch(content) ||
          !RegExp(r'\boutput\b').hasMatch(content)) {
        throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
      }
      await target.create(recursive: true);
      // Copy first, then hash the copies, so concurrent source-file edits cannot
      // produce a manifest that describes different weights.
      final copiedParam = await param.copy(
        p.join(target.path, 'realesrgan-x4plus.param'),
      );
      final copiedBin = await weights.copy(
        p.join(target.path, 'realesrgan-x4plus.bin'),
      );
      await File(p.join(target.path, 'model.json')).writeAsString(
        jsonEncode({
          'name': p.basenameWithoutExtension(param.path),
          'paramSha256': await _hash(copiedParam),
          'binSha256': await _hash(copiedBin),
        }),
        flush: true,
      );
      return id;
    } catch (_) {
      await _removeOwned(target);
      rethrow;
    } finally {
      _mutating = false;
    }
  }

  Future<void> delete(String id) async {
    await initialize();
    if (localUpscaleCatalog.any((model) => model.id == id && model.bundled)) {
      return;
    }
    if (!(await models()).any((model) => model.id == id)) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
    }
    _claimMutation();
    try {
      final target = _modelDirectory(id);
      if (await target.exists() &&
          !p.isWithin(
            await directory.resolveSymbolicLinks(),
            await target.resolveSymbolicLinks(),
          )) {
        throw const LocalUpscaleException(LocalUpscaleError.invalidModel);
      }
      await _removeOwned(target);
    } finally {
      _mutating = false;
    }
  }
}
