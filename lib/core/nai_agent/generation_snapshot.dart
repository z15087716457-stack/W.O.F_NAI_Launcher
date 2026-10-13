import 'dart:convert';
import 'dart:typed_data';
import '../enums/precise_ref_type.dart';
import '../utils/inpaint_focus_region.dart';
import '../utils/nai_api_utils.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/vibe/vibe_reference.dart';

/// ImageParams deliberately omits image-tool fields from its ordinary JSON.
/// An explicit Agent snapshot keeps them, including reusable Vibe encodings.
Map<String, dynamic> encodeAgentImageParams(ImageParams value) => {
  'params': value.toJson(),
  'extra': {
    'extraNoiseSeed': value.extraNoiseSeed,
    'enhanceWorkflow': value.enhanceWorkflow,
    'sourceImage': _image(value.sourceImage),
    'maskImage': _image(value.maskImage),
    'focus': value.inpaintFocusRegion == null
        ? null
        : {
            'x': value.inpaintFocusRegion!.x,
            'y': value.inpaintFocusRegion!.y,
            'width': value.inpaintFocusRegion!.width,
            'height': value.inpaintFocusRegion!.height,
            'context': value.inpaintFocusRegion!.context,
          },
    'maskClosing': value.inpaintMaskClosingIterations,
    'maskExpansion': value.inpaintMaskExpansionIterations,
    'isOutpaint': value.isOutpaint,
    'vibes': [
      for (final vibe in value.vibeReferencesV4)
        {
          ...vibe.toJson(),
          'thumbnail': _image(vibe.thumbnail),
          'rawImageData': _image(vibe.rawImageData),
        },
    ],
    'precise': [
      for (final reference in value.preciseReferences)
        {
          'image': _image(reference.image),
          'type': reference.type.name,
          'strength': reference.strength,
          'fidelity': reference.fidelity,
          'enabled': reference.enabled,
          'normalizedPng': NAIApiUtils.isKnownNormalizedPreciseReferencePng(
            reference.image,
          ),
        },
    ],
    'characters': [
      for (final character in value.characters)
        {
          'prompt': character.prompt,
          'negativePrompt': character.negativePrompt,
          'positionX': character.positionX,
          'positionY': character.positionY,
          'position': character.position,
        },
    ],
  },
};

ImageParams decodeAgentImageParams(Map<String, dynamic> value) {
  final params = ImageParams.fromJson(_map(value['params']));
  final extra = _map(value['extra']);
  final focus = extra['focus'] == null ? null : _map(extra['focus']);
  final vibes = _list(extra['vibes']).map((raw) {
    final json = _map(raw);
    return VibeReference.fromJson(json).copyWith(
      thumbnail: _bytes(json['thumbnail']),
      rawImageData: _bytes(json['rawImageData']),
    );
  }).toList();
  final precise = _list(extra['precise']).map((raw) {
    final json = _map(raw);
    final bytes = _bytes(json['image']);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Precise reference image is missing');
    }
    final type = PreciseRefType.values.asNameMap()[json['type']];
    if (type == null) {
      throw const FormatException('Unknown precise reference type');
    }
    return PreciseReference(
      image: json['normalizedPng'] == true
          ? NAIApiUtils.markNormalizedPreciseReferencePng(bytes)
          : bytes,
      type: type,
      strength: (json['strength'] as num).toDouble(),
      fidelity: (json['fidelity'] as num).toDouble(),
      enabled: json['enabled'] as bool,
    );
  }).toList();
  final characters = _list(extra['characters']).map((raw) {
    final json = _map(raw);
    return CharacterPrompt(
      prompt: json['prompt'] as String,
      negativePrompt: json['negativePrompt'] as String,
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      position: json['position'] as String?,
    );
  }).toList();
  return params.copyWith(
    extraNoiseSeed: extra['extraNoiseSeed'] as int?,
    enhanceWorkflow: extra['enhanceWorkflow'] as bool,
    sourceImage: _bytes(extra['sourceImage']),
    maskImage: _bytes(extra['maskImage']),
    inpaintFocusRegion: focus == null
        ? null
        : InpaintFocusRegion(
            x: focus['x'] as int,
            y: focus['y'] as int,
            width: focus['width'] as int,
            height: focus['height'] as int,
            context: focus['context'] as int,
          ),
    inpaintMaskClosingIterations: extra['maskClosing'] as int,
    inpaintMaskExpansionIterations: extra['maskExpansion'] as int,
    isOutpaint: extra['isOutpaint'] as bool,
    vibeReferencesV4: vibes,
    preciseReferences: precise,
    characters: characters,
  );
}

String? _image(Uint8List? bytes) {
  if (bytes == null) return null;
  if (bytes.length > 64 * 1024 * 1024) {
    throw const FormatException('Snapshot image exceeds 64 MiB');
  }
  return base64Encode(bytes);
}

Uint8List? _bytes(Object? value) {
  if (value == null) return null;
  if (value is! String || value.length > 90 * 1024 * 1024) {
    throw const FormatException('Invalid snapshot image');
  }
  final bytes = base64Decode(value);
  if (bytes.length > 64 * 1024 * 1024) {
    throw const FormatException('Snapshot image exceeds 64 MiB');
  }
  return bytes;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected snapshot object');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Expected snapshot list');
  return value;
}
