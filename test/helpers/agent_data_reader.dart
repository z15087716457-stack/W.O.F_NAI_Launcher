import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';

class AgentFixtureDataReader extends DataReader {
  AgentFixtureDataReader({
    this.fileUri,
    this.bytes,
    this.fileName = 'image.png',
    this.format = Formats.png,
  });
  final Uri? fileUri;
  final Uint8List? bytes;
  final String fileName;
  final FileFormat format;
  int fileReads = 0;
  @override
  bool canProvide(DataFormat value) =>
      (fileUri != null && value == Formats.fileUri) ||
      (bytes != null && value == format);
  @override
  List<DataFormat> getFormats(List<DataFormat> formats) =>
      formats.where(canProvide).toList();
  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> value,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    if ((value as DataFormat) != Formats.fileUri) return null;
    scheduleMicrotask(() => onValue(fileUri as T?));
    return _FixtureProgress();
  }

  @override
  ReadProgress? getFile(
    FileFormat? value,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    fileReads++;
    if (bytes == null || value != format) return null;
    scheduleMicrotask(() => onFile(_FixtureFile(fileName, bytes!)));
    return _FixtureProgress();
  }

  @override
  bool isSynthesized(DataFormat format) => bytes != null;
  @override
  bool isVirtual(DataFormat format) => bytes != null;
  @override
  Future<String?> getSuggestedName() async => fileName;
  @override
  Future<VirtualFileReceiver?> getVirtualFileReceiver({
    FileFormat? format,
  }) async => null;
  @override
  List<PlatformFormat> get platformFormats => const [];
}

class _FixtureFile extends DataReaderFile {
  _FixtureFile(this.fileName, this.bytes);
  @override
  final String fileName;
  final Uint8List bytes;
  @override
  int get fileSize => bytes.length;
  @override
  Stream<Uint8List> getStream() => Stream.value(bytes);
  @override
  void close() {}
  @override
  Future<Uint8List> readAll() async => bytes;
}

class _FixtureProgress extends ReadProgress {
  final _fraction = ValueNotifier<double?>(1);
  final _cancellable = ValueNotifier<bool>(false);
  @override
  ValueListenable<double?> get fraction => _fraction;
  @override
  ValueListenable<bool> get cancellable => _cancellable;
  @override
  void cancel() {}
}
