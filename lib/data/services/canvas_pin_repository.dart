import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../presentation/providers/generation/generation_models.dart';
import '../models/gallery/nai_image_metadata.dart';
import '../models/image/image_operation.dart';
import 'metadata/unified_metadata_parser.dart';

/// manifest 单条记录：pin 副本文件名 + 图像身份数据。
class CanvasPinRecord {
  const CanvasPinRecord({
    required this.imageId,
    required this.fileName,
    required this.width,
    required this.height,
    required this.createdAt,
    this.kind = GeneratedImageKind.completed,
    this.metadata,
    this.savedPath,
    this.operation,
    this.isVariationOriginal = false,
  });

  /// 图像 ID（沿用 GeneratedImage.id，不是路径的一部分）。
  final String imageId;

  /// pin 副本文件名（扁平 `sha256.png`，仅文件名，不含目录）。
  final String fileName;
  final int width;
  final int height;
  final DateTime createdAt;
  final GeneratedImageKind kind;
  final NaiImageMetadata? metadata;
  final String? savedPath;
  final ImageOperation? operation;
  final bool isVariationOriginal;

  Map<String, Object?> toJson() => {
    'id': imageId,
    'file': fileName,
    'width': width,
    'height': height,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'kind': kind.name,
    if (metadata != null) 'metadata': metadata!.toJson(),
    if (savedPath != null) 'savedPath': savedPath,
    if (operation != null) 'operation': operation!.name,
    if (isVariationOriginal) 'isVariationOriginal': true,
  };

  /// 宽容解析：字段缺失/类型错误返回 null，由调用方跳过该条。
  static CanvasPinRecord? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final file = raw['file'];
    final width = raw['width'];
    final height = raw['height'];
    final createdAt = raw['createdAt'];
    if (id is! String || id.isEmpty) return null;
    if (file is! String || file.isEmpty) return null;
    if (width is! num ||
        height is! num ||
        !width.isFinite ||
        !height.isFinite ||
        width < 1 ||
        height < 1) {
      return null;
    }
    if (createdAt is num &&
        (!createdAt.isFinite || createdAt.abs() > 8640000000000000)) {
      return null;
    }
    NaiImageMetadata? metadata;
    try {
      if (raw['metadata'] is Map) {
        metadata = NaiImageMetadata.fromJson(
          Map<String, dynamic>.from(raw['metadata'] as Map),
        );
      }
    } catch (_) {
      // A malformed optional metadata cache must not hide healthy image bytes.
    }
    return CanvasPinRecord(
      imageId: id,
      fileName: file,
      width: width.toInt(),
      height: height.toInt(),
      createdAt: createdAt is num
          ? DateTime.fromMillisecondsSinceEpoch(createdAt.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
      kind:
          GeneratedImageKind.values.asNameMap()[raw['kind']] ??
          GeneratedImageKind.completed,
      metadata: metadata,
      savedPath: raw['savedPath'] is String ? raw['savedPath'] as String : null,
      operation: ImageOperation.values.asNameMap()[raw['operation']],
      isVariationOriginal: raw['isVariationOriginal'] == true,
    );
  }
}

/// 画布钉图仓库：被钉图像的原始字节持久化到应用支持目录 `canvas_pins/`，
/// manifest（文件名 + 图像身份数据）存 [LocalStorageService] 的
/// `canvas_pin_records` 设置项，历史被清/应用重启后仍可还原钉板。
///
/// 设计要点：
/// - 文件名取字节内容的 SHA256（[fileNameForBytes]），确定性、只含安全
///   字符；相同像素内容的多个 pin 共用一份副本，绝不拿图像 id 当路径。
/// - 优先从原始字节恢复元数据；未嵌入图片的元数据另外保存在 manifest。
/// - 数量有界（[maxPins]，超出抛 [StateError]）；缺失/损坏/越界条目
///   逐条跳过，不拖垮健康记录，也不产生幽灵计数。
/// - 解除钉住只摘 manifest 成员，pin 副本文件保留不删。
/// - 无 manifest 时 [loadAll] 直接返回，完全不做文件系统 I/O。
class CanvasPinRepository {
  /// [storage] 走既有 LocalStorageService；[directory] 为测试注入的
  /// pin 目录（生产环境为 null，惰性解析应用支持目录）。
  CanvasPinRepository({
    required LocalStorageService storage,
    Directory? directory,
    this.maxPins = defaultMaxPins,
  }) : _storage = storage,
       _injectedDirectory = directory;

  /// manifest 设置键（区别于旧版 `canvas_pinned_images` 纯 id 列表）。
  static const String manifestKey = 'canvas_pin_records';
  static const String pinsDirectoryName = 'canvas_pins';
  static const int defaultMaxPins = 100;
  static const int _manifestVersion = 1;

  final LocalStorageService _storage;
  final Directory? _injectedDirectory;
  final int maxPins;
  Directory? _directory;

  /// pin 目录：注入优先，否则 `<appSupport>/canvas_pins`。惰性解析——
  /// 没有 manifest 的启动路径不会触到这里。
  Future<Directory> _pinDirectory({bool create = false}) async {
    final dir = _directory ??=
        _injectedDirectory ??
        Directory(
          p.join(
            (await getApplicationSupportDirectory()).path,
            pinsDirectoryName,
          ),
        );
    if (create) await dir.create(recursive: true);
    return dir;
  }

  /// 内容寻址文件名：`<sha256>.png`，确定性且只含十六进制安全字符。
  static String fileNameForBytes(Uint8List bytes) =>
      '${sha256.convert(bytes)}.png';

  /// 读取 manifest（仅设置读取，无文件 I/O）。坏记录逐条跳过、按 id 去重。
  List<CanvasPinRecord> readManifest() {
    final raw = _storage.getSetting<dynamic>(manifestKey);
    final entries = switch (raw) {
      final String encoded => _decodeManifestEntries(encoded),
      final List<dynamic> list => list,
      _ => null,
    };
    if (entries == null) return const [];
    final seen = <String>{};
    final records = <CanvasPinRecord>[];
    for (final entry in entries) {
      final record = CanvasPinRecord.tryParse(entry);
      if (record != null && seen.add(record.imageId)) {
        records.add(record);
      }
    }
    return records;
  }

  static List<dynamic>? _decodeManifestEntries(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        final records = decoded['records'];
        return records is List ? records : null;
      }
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeManifest(List<CanvasPinRecord> records) {
    return _storage.setSetting<String>(
      manifestKey,
      jsonEncode({
        'version': _manifestVersion,
        'records': [for (final record in records) record.toJson()],
      }),
    );
  }

  /// 钉住：写 pin 副本 + 登记 manifest，全部持久化成功后返回规范化的
  /// 钉图（`generationRunId` 置空防重启后批次 ID 撞车）。私有副本不
  /// 冒充用户已保存的图库路径。写盘失败原样抛出，manifest 不被污染。
  Future<GeneratedImage> addPin(GeneratedImage image) async {
    final records = readManifest().toList();
    final index = records.indexWhere((r) => r.imageId == image.id);
    if (index < 0 && records.length >= maxPins) {
      throw StateError('Canvas pin limit reached ($maxPins)');
    }
    final fileName = fileNameForBytes(image.bytes);
    final dir = await _pinDirectory(create: true);
    final path = p.join(dir.path, fileName);
    final file = File(path);
    final healthy =
        await file.exists() &&
        fileNameForBytes(await file.readAsBytes()) == fileName;
    if (!healthy) {
      final staging = await dir.createTemp('.pin-write-');
      try {
        // Stage beside the destination so rename stays on the same volume.
        final temporary = File(p.join(staging.path, fileName));
        try {
          await temporary.writeAsBytes(image.bytes, flush: true);
          await temporary.rename(path);
        } finally {
          if (await temporary.exists()) await temporary.delete();
        }
      } finally {
        await staging.delete();
      }
    }
    final embeddedMetadata = _parseMetadata(image.bytes);
    final record = CanvasPinRecord(
      imageId: image.id,
      fileName: fileName,
      width: image.width,
      height: image.height,
      createdAt: image.createdAt,
      kind: image.kind,
      metadata: embeddedMetadata == null ? image.metadata : null,
      savedPath: image.filePath,
      operation: image.operation,
      isVariationOriginal: image.isVariationOriginal,
    );
    if (index < 0) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _writeManifest(records);
    return _pinnedImage(
      record,
      image.bytes,
      embeddedMetadata ?? image.metadata,
    );
  }

  /// 解除钉住：仅摘 manifest 成员；pin 副本文件保留不删。
  Future<void> removePin(String imageId) async {
    final records = readManifest().toList()
      ..removeWhere((record) => record.imageId == imageId);
    await _writeManifest(records);
  }

  /// 还原全部健康钉图（manifest 顺序）。无 manifest 时零文件 I/O 直接
  /// 返回；缺失/损坏/越界条目逐条跳过。
  Future<List<GeneratedImage>> loadAll() async {
    final records = readManifest();
    if (records.isEmpty) return const [];
    final dir = await _pinDirectory();
    final images = <GeneratedImage>[];
    for (final record in records.take(maxPins)) {
      final image = await _loadRecord(dir, record);
      if (image != null) images.add(image);
    }
    return images;
  }

  /// 还原单条 manifest 记录；缺失/损坏返回 null。
  Future<GeneratedImage?> loadPin(CanvasPinRecord record) async =>
      _loadRecord(await _pinDirectory(), record);

  Future<GeneratedImage?> _loadRecord(
    Directory dir,
    CanvasPinRecord record,
  ) async {
    try {
      // 只接受 pin 目录内的扁平文件名，拒绝越界/外部路径。
      final name = record.fileName;
      if (p.basename(name) != name) return null;
      final dirPath = p.normalize(dir.path);
      final path = p.normalize(p.join(dirPath, name));
      if (!p.isWithin(dirPath, path)) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      // 文件名即内容哈希：不匹配视为损坏/被篡改，跳过。
      if (p.basenameWithoutExtension(name) !=
          sha256.convert(bytes).toString()) {
        return null;
      }
      return _pinnedImage(
        record,
        bytes,
        _parseMetadata(bytes) ?? record.metadata,
      );
    } catch (error) {
      AppLogger.w(
        'Skip broken canvas pin ${record.imageId}: $error',
        'CanvasPinRepository',
      );
      return null;
    }
  }

  /// 规范化钉图：保留原 id/字节/尺寸/创建时间；`generationRunId` 置空，
  /// 画布侧以 `pin:<id>` 独立分组，不与重启后的批次 runId 撞车。
  static GeneratedImage _pinnedImage(
    CanvasPinRecord record,
    Uint8List bytes,
    NaiImageMetadata? metadata,
  ) {
    return GeneratedImage(
      id: record.imageId,
      bytes: bytes,
      width: record.width,
      height: record.height,
      createdAt: record.createdAt,
      kind: record.kind,
      metadata: metadata,
      filePath: record.savedPath,
      operation: record.operation,
      isVariationOriginal: record.isVariationOriginal,
      generationRunId: null,
    );
  }

  static NaiImageMetadata? _parseMetadata(Uint8List bytes) {
    try {
      return UnifiedMetadataParser.parseFromImageBytes(bytes).metadata;
    } catch (_) {
      return null;
    }
  }
}
