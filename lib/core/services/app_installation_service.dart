import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:win32_registry/win32_registry.dart';

import '../utils/app_bundle_paths.dart';

part 'app_installation_service.g.dart';

enum AppInstallationType {
  windowsInstaller,
  windowsPortable,
  macosPortable,
  unsupported,
}

/// 判断当前应用是安装版还是便携版。
class AppInstallationService {
  /// New installations take priority; 1.x installations remain updatable.
  static const uninstallRegistryPaths = [
    r'Software\Microsoft\Windows\CurrentVersion\Uninstall\W.O.F NAI Studio',
    r'Software\Microsoft\Windows\CurrentVersion\Uninstall\Aaalice NAI Launcher',
  ];

  AppInstallationType getInstallationType() {
    if (AppBundlePaths.macBundle != null) {
      return AppInstallationType.macosPortable;
    }
    if (!Platform.isWindows) {
      return AppInstallationType.unsupported;
    }
    return _isInstalledWindowsApp()
        ? AppInstallationType.windowsInstaller
        : AppInstallationType.windowsPortable;
  }

  String getReleaseAssetPreference() {
    return switch (getInstallationType()) {
      AppInstallationType.windowsInstaller => 'windows-installer',
      AppInstallationType.windowsPortable => 'windows-portable',
      AppInstallationType.macosPortable => 'macos-portable',
      AppInstallationType.unsupported => 'unknown',
    };
  }

  bool get supportsInAppInstall =>
      getInstallationType() != AppInstallationType.unsupported;

  bool _isInstalledWindowsApp() {
    // Both versions may coexist in different directories. Match the running
    // executable, not merely the first registry key that exists.
    return uninstallRegistryPaths.any((path) {
      final location = _readInstallLocation(path);
      return location != null &&
          location.isNotEmpty &&
          isExecutableInsideInstallDir(
            executablePath: Platform.resolvedExecutable,
            installLocation: location,
          );
    });
  }

  String? readWindowsInstallLocation() {
    if (!Platform.isWindows) return null;
    for (final path in uninstallRegistryPaths) {
      final location = _readInstallLocation(path);
      if (location != null && location.isNotEmpty) return location;
    }
    return null;
  }

  static String? _readInstallLocation(String path) {
    RegistryKey? key;
    try {
      key = Registry.openPath(RegistryHive.currentUser, path: path);
      return key.getValueAsString('InstallLocation');
    } catch (_) {
      return null;
    } finally {
      key?.close();
    }
  }

  static bool isExecutableInsideInstallDir({
    required String executablePath,
    required String installLocation,
  }) {
    final normalizedExe = _normalizePath(executablePath);
    final normalizedInstall = _normalizePath(installLocation);
    return normalizedExe == normalizedInstall ||
        normalizedExe.startsWith('$normalizedInstall\\');
  }

  static String _normalizePath(String value) {
    var normalized = value.replaceAll('/', r'\').trim();
    while (normalized.endsWith(r'\')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized.toLowerCase();
  }
}

@riverpod
AppInstallationService appInstallationService(Ref ref) {
  return AppInstallationService();
}
