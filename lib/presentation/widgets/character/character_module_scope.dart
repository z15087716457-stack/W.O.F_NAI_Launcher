import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// Enables the selected prototype only for cards inside the desktop module.
class CharacterModuleScope extends InheritedWidget {
  const CharacterModuleScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CharacterModuleScope>() !=
      null;

  @override
  bool updateShouldNotify(CharacterModuleScope oldWidget) => false;
}
