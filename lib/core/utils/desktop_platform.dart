import 'dart:io';

import 'package:flutter/foundation.dart';

bool get isSupportedDesktop => Platform.isWindows || Platform.isMacOS;

bool get usesMacOSConventions => defaultTargetPlatform == TargetPlatform.macOS;
