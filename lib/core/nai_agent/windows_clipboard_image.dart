import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'attachment_image.dart';

/// Wraps native DIB pixels without re-encoding them. Bitmap clipboard payloads
/// have no original encoded file; real file and PNG readers take precedence.
Uint8List agentBitmapFromDib(Uint8List dib) {
  if (dib.length < 12) throw const AgentImageInputException('invalid');
  final data = ByteData.sublistView(dib);
  final header = data.getUint32(0, Endian.little);
  final core = header == 12;
  if (!core && (header < 40 || header > dib.length)) {
    throw const AgentImageInputException('invalid');
  }
  final width = core
      ? data.getUint16(4, Endian.little)
      : data.getInt32(4, Endian.little);
  final height =
      (core
              ? data.getUint16(6, Endian.little)
              : data.getInt32(8, Endian.little))
          .abs();
  final bits = data.getUint16(core ? 10 : 14, Endian.little);
  final usedColors = core ? 0 : data.getUint32(32, Endian.little);
  final colors = usedColors != 0 ? usedColors : (bits <= 8 ? 1 << bits : 0);
  final compression = core ? 0 : data.getUint32(16, Endian.little);
  final masks = header == 40
      ? (compression == 3
            ? 12
            : compression == 6
            ? 16
            : 0)
      : 0;
  final offset = header + colors * (core ? 3 : 4) + masks;
  if (width <= 0 || height == 0 || offset >= dib.length) {
    throw const AgentImageInputException('invalid');
  }
  if (width * height > agentAttachmentMaxPixels ||
      dib.length + 14 > agentAttachmentMaxBytes) {
    throw const AgentImageInputException('oversized');
  }
  final bmp = Uint8List(dib.length + 14)..setRange(14, dib.length + 14, dib);
  final file = ByteData.sublistView(bmp);
  file.setUint16(0, 0x4d42, Endian.little);
  file.setUint32(2, bmp.length, Endian.little);
  file.setUint32(10, offset + 14, Endian.little);
  return bmp;
}

/// Reads the original HBITMAP with GDI. The locked plugin filters TYMED_GDI
/// from its OLE format list. This fallback never changes the clipboard and
/// releases all allocations/locks; encoded file/PNG data always takes priority.
Future<Uint8List?> readAgentWindowsClipboardBitmap() async {
  if (!Platform.isWindows) return null;
  return Isolate.run(() {
    final user = DynamicLibrary.open('user32.dll');
    final available = user
        .lookupFunction<Int32 Function(Uint32), int Function(int)>(
          'IsClipboardFormatAvailable',
        );
    if (available(2) == 0) return null; // CF_BITMAP
    final open = user.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
      'OpenClipboard',
    );
    final close = user.lookupFunction<Int32 Function(), int Function()>(
      'CloseClipboard',
    );
    final get = user.lookupFunction<IntPtr Function(Uint32), int Function(int)>(
      'GetClipboardData',
    );
    if (open(0) == 0) throw const AgentImageInputException('unreadable');
    try {
      final bitmap = get(2);
      if (bitmap == 0) throw const AgentImageInputException('unreadable');
      final gdi = DynamicLibrary.open('gdi32.dll');
      final getObject = gdi
          .lookupFunction<
            Int32 Function(IntPtr, Int32, Pointer<Void>),
            int Function(int, int, Pointer<Void>)
          >('GetObjectW');
      final createDC = gdi
          .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
            'CreateCompatibleDC',
          );
      final deleteDC = gdi
          .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
            'DeleteDC',
          );
      final getBits = gdi
          .lookupFunction<
            Int32 Function(
              IntPtr,
              IntPtr,
              Uint32,
              Uint32,
              Pointer<Void>,
              Pointer<Void>,
              Uint32,
            ),
            int Function(int, int, int, int, Pointer<Void>, Pointer<Void>, int)
          >('GetDIBits');
      final object = calloc<Uint8>(64); // room for BITMAP on both Windows ABIs
      try {
        if (getObject(bitmap, 64, object.cast()) < 12) {
          throw const AgentImageInputException('unreadable');
        }
        final dimensions = ByteData.sublistView(object.asTypedList(64));
        final width = dimensions.getInt32(4, Endian.little);
        final height = dimensions.getInt32(8, Endian.little).abs();
        if (width <= 0 || height == 0) {
          throw const AgentImageInputException('invalid');
        }
        final pixels = width * height * 4;
        if (width * height > agentAttachmentMaxPixels ||
            pixels + 54 > agentAttachmentMaxBytes) {
          throw const AgentImageInputException('oversized');
        }
        final dib = calloc<Uint8>(40 + pixels);
        final dc = createDC(0);
        try {
          if (dc == 0) throw const AgentImageInputException('unreadable');
          final bytes = dib.asTypedList(40 + pixels);
          final header = ByteData.sublistView(bytes);
          header.setUint32(0, 40, Endian.little);
          header.setInt32(4, width, Endian.little);
          header.setInt32(8, height, Endian.little);
          header.setUint16(12, 1, Endian.little);
          header.setUint16(14, 32, Endian.little);
          header.setUint32(20, pixels, Endian.little);
          if (getBits(
                dc,
                bitmap,
                0,
                height,
                (dib + 40).cast(),
                dib.cast(),
                0,
              ) !=
              height) {
            throw const AgentImageInputException('unreadable');
          }
          return agentBitmapFromDib(bytes);
        } finally {
          if (dc != 0) deleteDC(dc);
          calloc.free(dib);
        }
      } finally {
        calloc.free(object);
      }
    } finally {
      close();
    }
  });
}
