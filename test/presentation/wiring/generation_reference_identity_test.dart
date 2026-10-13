import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_identity.dart';

VibeReference vibe(Uint8List bytes) => VibeReference(
  displayName: 'same name',
  vibeEncoding: '',
  rawImageData: bytes,
);
void main() {
  test('修改 Vibe 强度、信息、启用与编码不换 ID', () {
    final ids = GenerationReferenceIdentity();
    final first = vibe(Uint8List.fromList([1]));
    ids.sync(ImageParams(vibeReferencesV4: [first]));
    final id = ids.vibes.single;
    ids.sync(
      ImageParams(
        vibeReferencesV4: [
          first.copyWith(
            strength: .2,
            infoExtracted: .3,
            enabled: false,
            vibeEncoding: 'encoded',
          ),
        ],
      ),
    );
    expect(ids.vibes.single, id);
  });
  test('删前项后旧索引 ID 不指向后面的图', () {
    final ids = GenerationReferenceIdentity();
    final first = vibe(Uint8List.fromList([1]));
    final second = vibe(Uint8List.fromList([2]));
    ids.sync(ImageParams(vibeReferencesV4: [first, second]));
    final old = ids.vibes.toList();
    ids.sync(ImageParams(vibeReferencesV4: [second]));
    expect(ids.vibeIndex(old[0]), -1);
    expect(ids.vibeIndex(old[1]), 0);
  });
  test('同名同字节重复条目先保留仍存在的具体对象', () {
    final ids = GenerationReferenceIdentity();
    final bytes = Uint8List.fromList([1]);
    final first = vibe(bytes);
    final second = vibe(bytes).copyWith(strength: .8);
    ids.sync(ImageParams(vibeReferencesV4: [first, second]));
    final old = ids.vibes.toList();
    ids.sync(
      ImageParams(vibeReferencesV4: [first.copyWith(strength: .4), second]),
    );
    expect(ids.vibes, old);
    ids.sync(ImageParams(vibeReferencesV4: [second]));
    expect(ids.vibes, [old[1]]);
  });
  test('移除再加同图不能复用旧 ID，重排则随对象移动', () {
    final ids = GenerationReferenceIdentity();
    final first = vibe(Uint8List.fromList([1]));
    final second = vibe(Uint8List.fromList([2]));
    ids.sync(ImageParams(vibeReferencesV4: [first, second]));
    final old = ids.vibes.toList();
    ids.sync(ImageParams(vibeReferencesV4: [second, first]));
    expect(ids.vibes, old.reversed.toList());
    ids.sync(ImageParams(vibeReferencesV4: [second]));
    ids.sync(ImageParams(vibeReferencesV4: [second, first]));
    expect(ids.vibes.last, isNot(old[0]));
  });
  test('精准参考改类型与保真仍指向原图，更换底图才换 ID', () {
    final ids = GenerationReferenceIdentity();
    final first = PreciseReference(
      image: Uint8List.fromList([1]),
      type: PreciseRefType.character,
    );
    ids.sync(ImageParams(preciseReferences: [first]));
    final id = ids.precise.single;
    ids.sync(
      ImageParams(
        preciseReferences: [
          first.copyWith(type: PreciseRefType.style, fidelity: .4),
        ],
      ),
    );
    expect(ids.precise.single, id);
    ids.sync(
      ImageParams(
        preciseReferences: [
          first.copyWith(image: Uint8List.fromList([2])),
        ],
      ),
    );
    expect(ids.precise.single, isNot(id));
  });
}
