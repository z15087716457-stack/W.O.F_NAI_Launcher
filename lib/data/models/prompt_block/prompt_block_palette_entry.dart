import 'pill_document.dart';

/// An ordered palette item, containing either a library reference or a temp.
class PromptBlockPaletteEntry {
  const PromptBlockPaletteEntry.library(this.id) : temp = null;

  const PromptBlockPaletteEntry.temporary({
    required this.id,
    required PillTempContent this.temp,
  });

  final String id;
  final PillTempContent? temp;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (temp != null) 'temp': temp!.toJson(),
  };

  factory PromptBlockPaletteEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final temp = json['temp'] as Map<String, dynamic>?;
    return temp == null
        ? PromptBlockPaletteEntry.library(id)
        : PromptBlockPaletteEntry.temporary(
            id: id,
            temp: PillTempContent.fromJson(temp),
          );
  }
}
