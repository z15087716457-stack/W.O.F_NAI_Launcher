import 'dart:async';
import 'dart:io';

/// 文件拷贝字节与完整性校验函数类型
typedef FileCopyValidator = FutureOr<bool> Function(File src, File dst);

/// 默认字节数比对校验器
Future<bool> defaultByteCountValidator(File src, File dst) async {
  try {
    final srcLen = await src.length();
    final dstLen = await dst.length();
    return srcLen == dstLen;
  } catch (_) {
    return false;
  }
}

/// 静默清理文件，避免异常扩散
Future<void> _cleanupFileSilently(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
}

/// 跨卷移动回退流程：
/// copy → 校验字节数与源一致 → setLastModified(源文件 mtime) → delete 源
/// 任一步失败：清理残留副本、绝不删源文件、返回 null。成功返回目标路径。
Future<String?> moveFileCrossVolumeFallback(
  File srcFile,
  File dstFile, {
  FileCopyValidator? validator,
}) async {
  try {
    if (!await srcFile.exists()) {
      return null;
    }

    final parentDir = dstFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final srcMtime = await srcFile.lastModified();
    await srcFile.copy(dstFile.path);

    final check = validator ?? defaultByteCountValidator;
    final isValid = await check(srcFile, dstFile);
    if (!isValid) {
      await _cleanupFileSilently(dstFile);
      return null;
    }

    await dstFile.setLastModified(srcMtime);
    await srcFile.delete();
    return dstFile.path;
  } catch (_) {
    await _cleanupFileSilently(dstFile);
    return null;
  }
}

/// 跨卷移动文件
///
/// 先试 [File.rename]；
/// 捕到 [FileSystemException] 时回退：copy → 校验字节数与源一致 → 保留源文件 mtime → delete 源。
/// 任一步失败：清理残留副本、绝不删源文件、返回 null。
/// 成功返回 [dst]。
/// rename 前就确认源存在，源不存在返回 null。
Future<String?> moveFileCrossVolume(
  String src,
  String dst, {
  FileCopyValidator? validator,
}) async {
  final srcFile = File(src);
  if (!await srcFile.exists()) {
    return null;
  }

  final dstFile = File(dst);
  final parentDir = dstFile.parent;
  if (!await parentDir.exists()) {
    try {
      await parentDir.create(recursive: true);
    } catch (_) {
      return null;
    }
  }

  try {
    await srcFile.rename(dst);
    return dst;
  } on FileSystemException {
    return await moveFileCrossVolumeFallback(
      srcFile,
      dstFile,
      validator: validator,
    );
  } catch (_) {
    return null;
  }
}

/// 复制文件并赋予最新修改时间（防扫描器签名撞车）
///
/// copy → 校验字节数 → setLastModified(DateTime.now())。
/// 失败清理副本返回 null。
Future<String?> copyFileWithFreshMtime(
  String src,
  String dst, {
  FileCopyValidator? validator,
}) async {
  final srcFile = File(src);
  final dstFile = File(dst);

  try {
    if (!await srcFile.exists()) {
      return null;
    }

    final parentDir = dstFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    await srcFile.copy(dstFile.path);

    final check = validator ?? defaultByteCountValidator;
    final isValid = await check(srcFile, dstFile);
    if (!isValid) {
      await _cleanupFileSilently(dstFile);
      return null;
    }

    await dstFile.setLastModified(DateTime.now());
    return dst;
  } catch (_) {
    await _cleanupFileSilently(dstFile);
    return null;
  }
}
