import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';
import 'file_system_utils.dart';

/// 精准参考库路径管理助手
///
/// 精准参考原图默认放在应用数据目录，已有条目保留其原图路径。
class PreciseRefLibraryPathHelper {
  PreciseRefLibraryPathHelper._();

  static final PreciseRefLibraryPathHelper instance =
      PreciseRefLibraryPathHelper._();

  static const String _defaultFolderName = 'precise_refs';
  static const String _tag = 'PreciseRefLibrary';

  String? getCustomPath() => LocalStorageService().getSetting<String>(
    StorageKeys.preciseRefLibrarySavePath,
  );

  Future<String> getPath() async {
    final custom = getCustomPath();
    return custom != null && custom.isNotEmpty ? custom : getDefaultPath();
  }

  Future<String> getDefaultPath() => getUserAssetPath(_defaultFolderName);

  /// Include the former default when reconciling interrupted imports/deletes.
  Future<List<String>> getReadPaths() async {
    final current = await getPath();
    final legacy = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'NAI_Launcher',
      _defaultFolderName,
    );
    return [
      current,
      if (legacy != current && await Directory(legacy).exists()) legacy,
    ];
  }

  /// 确保路径存在（如果不存在则创建）
  Future<bool> ensurePathExists(String path) async {
    return FileSystemUtils.ensureDirectory(path, logTag: _tag);
  }
}
