import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

/// The optional ffdkj Chinese tag dictionary was removed; tag readings now
/// come from the user's translation interface. Deletes only the dictionary
/// folder that earlier versions downloaded into application support.
Future<bool> removeRetiredZhDictionary({
  Future<Directory> Function() supportDirectory =
      getApplicationSupportDirectory,
}) async {
  final support = await supportDirectory();
  final folder = Directory(p.join(support.path, 'autocomplete', 'ffdkj'));
  if (!await folder.exists()) return false;
  await folder.delete(recursive: true);
  return true;
}
