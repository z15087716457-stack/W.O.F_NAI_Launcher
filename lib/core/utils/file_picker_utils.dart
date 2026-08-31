import 'package:file_picker/file_picker.dart';

typedef DirectoryPathPicker =
    Future<String?> Function({
      String? dialogTitle,
      bool lockParentWindow,
      String? initialDirectory,
    });

class FilePickerUtils {
  FilePickerUtils._();

  /// Opens a native directory picker as a modal child of the app window.
  ///
  /// On Windows this avoids ownerless common dialogs, which can be unstable
  /// around Flutter window focus changes.
  static Future<String?> pickDirectoryModal({
    String? dialogTitle,
    String? initialDirectory,
    DirectoryPathPicker? picker,
  }) {
    final pickDirectory = picker ?? FilePicker.platform.getDirectoryPath;
    return pickDirectory(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      lockParentWindow: true,
    );
  }
}
