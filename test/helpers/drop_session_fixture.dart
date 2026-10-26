import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'agent_data_reader.dart';

void prepareDropTestPlatform() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
}

/// Reject new reader requests after the simulated native callback returns.
/// Already requested file streams remain valid until consumed.
class HeldDropReader extends AgentFixtureDataReader {
  HeldDropReader({required Uint8List bytes, String name = 'image.png'})
    : super(bytes: bytes, fileName: name);

  final release = Completer<void>();
  bool callbackReturned = false;
  int names = 0;

  void _checkAlive() {
    if (callbackReturned) throw StateError('drop reader has expired');
  }

  @override
  Future<String?> getSuggestedName() {
    _checkAlive();
    names++;
    return Future.value(fileName);
  }

  @override
  ReadProgress? getFile(
    FileFormat? value,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    _checkAlive();
    return super.getFile(
      value,
      (file) => onFile(_HeldFile(file, release.future)),
      onError: onError,
      allowVirtualFiles: allowVirtualFiles,
      synthesizeFilesFromURIs: synthesizeFilesFromURIs,
    );
  }
}

class _HeldFile extends DataReaderFile {
  _HeldFile(this.file, this.release);
  final DataReaderFile file;
  final Future<void> release;
  @override
  String? get fileName => file.fileName;
  @override
  int? get fileSize => file.fileSize;
  @override
  Future<Uint8List> readAll() async {
    await release;
    return file.readAll();
  }

  @override
  Stream<Uint8List> getStream() => file.getStream();
  @override
  void close() => file.close();
}

class FixtureDropItem extends DropItem {
  FixtureDropItem(this.dataReader);
  @override
  DataReader? dataReader;
  @override
  bool canProvide(DataFormat format) => dataReader?.canProvide(format) ?? false;
  @override
  Object? get localData => null;
  @override
  List<PlatformFormat> get platformFormats => const [];
}

class FixtureDropSession extends DropSession {
  FixtureDropSession(List<DataReader> readers)
    : items = readers.map(FixtureDropItem.new).toList();
  @override
  final List<DropItem> items;
  @override
  final onDisposed = ChangeNotifier();
  @override
  Set<DropOperation> get allowedOperations => {DropOperation.copy};

  DropOverEvent over() => DropOverEvent(session: this, position: _position);
  PerformDropEvent perform() => PerformDropEvent(
    session: this,
    position: _position,
    acceptedOperation: DropOperation.copy,
  );

  static final _position = DropPosition(
    local: Offset.zero,
    global: Offset.zero,
  );
}
