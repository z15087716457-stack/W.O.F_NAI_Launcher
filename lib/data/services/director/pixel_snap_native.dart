part of 'pixel_snap_service.dart';

typedef _NativeSpreadSignature =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32,
      ffi.Pointer<ffi.Uint32>,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Pointer<ffi.Float>,
    );

typedef _DartSpreadSignature =
    int Function(
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Uint8>,
      int,
      int,
      int,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Uint8>,
      int,
      ffi.Pointer<ffi.Uint32>,
      int,
      int,
      int,
      ffi.Pointer<ffi.Float>,
    );

// The Windows bundle includes our own spread library. A missing library (for
// example in widget tests or on another platform) keeps the original Dart path.
final _DartSpreadSignature? _nativeSpread = () {
  if (!Platform.isWindows) return null;
  try {
    return ffi.DynamicLibrary.open(
      'pixel_snap_spread.dll',
    ).lookupFunction<_NativeSpreadSignature, _DartSpreadSignature>(
      'pixel_snap_spread_v1',
    );
  } on Object {
    return null;
  }
}();

Float32List? _tryNativeSpread(
  _Intervals inner,
  _Intervals outer,
  Uint32List sat,
  int stride,
  bool innerIsColumn,
) {
  final spread = _nativeSpread;
  if (spread == null) return null;
  assert(outer.b == inner.b && outer.p == 1);

  return using((arena) {
    final innerStart = arena<ffi.Int32>(inner.a.length);
    final innerEnd = arena<ffi.Int32>(inner.z.length);
    final innerSelected = arena<ffi.Uint8>(inner.sel.length);
    final outerStart = arena<ffi.Int32>(outer.a.length);
    final outerEnd = arena<ffi.Int32>(outer.z.length);
    final outerSelected = arena<ffi.Uint8>(outer.sel.length);
    final satData = arena<ffi.Uint32>(sat.length);
    final outputLength = inner.b * inner.p;
    final output = arena<ffi.Float>(outputLength);
    innerStart.asTypedList(inner.a.length).setAll(0, inner.a);
    innerEnd.asTypedList(inner.z.length).setAll(0, inner.z);
    innerSelected.asTypedList(inner.sel.length).setAll(0, inner.sel);
    outerStart.asTypedList(outer.a.length).setAll(0, outer.a);
    outerEnd.asTypedList(outer.z.length).setAll(0, outer.z);
    outerSelected.asTypedList(outer.sel.length).setAll(0, outer.sel);
    satData.asTypedList(sat.length).setAll(0, sat);
    final status = spread(
      innerStart,
      innerEnd,
      innerSelected,
      inner.b,
      inner.p,
      inner.k,
      outerStart,
      outerEnd,
      outerSelected,
      outer.k,
      satData,
      sat.length,
      stride,
      innerIsColumn ? 1 : 0,
      output,
    );
    if (status != 0) {
      throw StateError('Native Pixel Snap spread failed: $status');
    }
    return Float32List.fromList(output.asTypedList(outputLength));
  });
}
