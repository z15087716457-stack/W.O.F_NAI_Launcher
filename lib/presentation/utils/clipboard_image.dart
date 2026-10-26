import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:super_clipboard/super_clipboard.dart';
import '../../core/utils/localization_extension.dart';

/// 把图片字节写入系统剪贴板，统一规范化为 PNG。
///
/// 背景：本地画廊图片可能是 jpg/jpeg/webp/bmp/gif。若直接用 [Formats.png]
/// 写非 PNG 原始字节，剪贴板会把它们当成 PNG，导致粘贴到其它 app 时图片
/// 无效。原 Windows 端走 PowerShell + System.Drawing 能容忍任意格式，而
/// super_clipboard 要求字节与声明格式一致。所以这里写入前确保是 PNG：已是
/// PNG 原样透传，否则先解码再重新编码成 PNG，保证粘贴一定有效。
///
/// 无法解码时抛出 [FormatException]，由调用方走「复制失败」提示，而不是把
/// 损坏字节塞进剪贴板。当前平台无系统剪贴板时抛出 [UnsupportedError]。
Future<void> writeImageBytesToClipboardAsPng(
  Uint8List bytes, {
  Future<void> Function(Uint8List)? writePng,
}) async {
  if (writePng != null) {
    await writePng(await _ensurePngBytes(bytes));
    return;
  }
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    throw UnsupportedError(currentL10n.clipboard_unsupportedPlatform);
  }
  final png = await _ensurePngBytes(bytes);
  final item = DataWriterItem();
  item.add(Formats.png(png));
  await clipboard.write([item]);
}

/// 已是 PNG 则原样返回；否则在后台 isolate 解码后重新编码成 PNG，避免大图
/// 解码阻塞 UI 线程。
Future<Uint8List> _ensurePngBytes(Uint8List bytes) async {
  if (_looksLikePng(bytes)) {
    return bytes;
  }
  final decodeFailed = currentL10n.clipboard_decodeFailed;
  return Isolate.run(() {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw FormatException(decodeFailed);
    }
    return img.encodePng(decoded);
  });
}

bool _looksLikePng(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length < signature.length) {
    return false;
  }
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) {
      return false;
    }
  }
  return true;
}
