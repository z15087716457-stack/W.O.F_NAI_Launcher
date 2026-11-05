import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_support_directory.dart';
import 'studio_sandbox.dart';

abstract final class AppBundlePaths {
  static const macBundleId = 'com.wof.naiStudio';
  static final executableDirectory = p.dirname(Platform.resolvedExecutable);

  static String? get macBundle {
    if (!Platform.isMacOS || p.basename(executableDirectory) != 'MacOS') {
      return null;
    }
    final contents = p.dirname(executableDirectory);
    final bundle = p.dirname(contents);
    return p.basename(contents) == 'Contents' && bundle.endsWith('.app')
        ? bundle
        : null;
  }

  static String get toolsDirectory {
    final bundle = macBundle;
    return bundle == null
        ? p.join(executableDirectory, 'tools')
        : p.join(bundle, 'Contents', 'Resources', 'tools');
  }

  static String? _macSupport;

  static Future<void> prepare() async {
    if (Platform.isMacOS) {
      _macSupport = (await getApplicationSupportDirectory()).path;
    }
  }

  static String get agentDataDirectory {
    if (studioSandboxRoot() case final sandbox?) {
      return p.join(sandbox, 'agent-data');
    }
    final root = Platform.isMacOS
        ? _macSupport ??
              (Platform.environment['FLUTTER_TEST'] == 'true'
                  ? p.join(Directory.systemTemp.path, 'nai-launcher-test')
                  : throw StateError('Application data is not prepared'))
        : executableDirectory;
    return p.join(root, 'agent-data');
  }
}
