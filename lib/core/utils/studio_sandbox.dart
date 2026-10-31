import 'dart:io';

import 'package:path/path.dart' as p;
import '../storage/application_storage.dart';

/// Opt-in only. Invalid opt-in fails closed rather than accessing real data.
String? studioSandboxRoot([Map<String, String>? environment]) {
  final value = (environment ?? Platform.environment)['NAI_STUDIO_SANDBOX'];
  if (value == null) return null;
  if (value.isEmpty || !p.isAbsolute(value)) {
    throw ArgumentError('NAI_STUDIO_SANDBOX must be an absolute directory');
  }
  return p.normalize(value);
}

/// Synchronous fallback root for early logging and legacy path helpers. In
/// sandbox mode even error paths must not share the production temp namespace.
Directory studioTemporaryRoot() {
  final sandbox = studioSandboxRoot();
  return sandbox == null
      ? Directory.systemTemp
      : Directory(p.join(sandbox, 'user-data', 'temp'));
}

String studioWindowTitle(String title) =>
    studioSandboxRoot() == null ? title : '$title [sandbox]';

/// Windows SharedPreferences resolves AppData independently of our path helper.
/// Install before its first read; never migrate/copy the production preferences.
void initializeSandboxStorage({String? root}) {
  final directory = root ?? studioSandboxRoot();
  if (directory == null) return;
  initializeApplicationStorage(Directory(p.join(directory, 'user-data')));
}
