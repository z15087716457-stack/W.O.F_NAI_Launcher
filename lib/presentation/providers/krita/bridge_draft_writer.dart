import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/enums/quality_tag_preset.dart';
import '../../../data/models/character/character_prompt.dart' as char_model;
import '../../../data/models/image/image_params.dart';
import '../image_generation_provider.dart';
import '../character_prompt_provider.dart';
import '../pill_workspace_provider.dart';

/// Shared synchronous writer. Callers validate, back up and compare versions
/// before invoking it; no asynchronous gap is permitted after that comparison.
typedef BridgeDraftWriter = List<String> Function(Map<String, dynamic> payload);
final bridgeDraftWriterProvider = Provider<BridgeDraftWriter>((ref) {
  return (payload) {
    final notifier = ref.read(generationParamsNotifierProvider.notifier);
    final applied = <String>[];
    String? str(String k) => payload[k] is String ? payload[k] as String : null;
    int? integer(String k) =>
        payload[k] is num ? (payload[k] as num).toInt() : null;
    double? dbl(String k) =>
        payload[k] is num ? (payload[k] as num).toDouble() : null;
    bool? flag(String k) => payload[k] is bool ? payload[k] as bool : null;

    void apply<T>(String key, T? value, void Function(T) setter) {
      if (value != null) {
        setter(value);
        applied.add(key);
      }
    }

    apply<String>('prompt', str('prompt'), notifier.updatePromptImmediately);
    apply<String>(
      'negative_prompt',
      str('negative_prompt'),
      notifier.updateNegativePromptImmediately,
    );
    apply<String>('model', str('model'), notifier.updateModel);
    apply<int>('steps', integer('steps'), notifier.updateSteps);
    apply<double>('cfg_scale', dbl('cfg_scale'), notifier.updateScale);
    apply<String>('sampler', str('sampler'), notifier.updateSampler);
    apply<int>('seed', integer('seed'), notifier.updateSeed);
    // 协议兼容：seed_lock 派生自 seed（有值即固定）。
    // true 且当前为随机 → 钉一个随机种子；false → 回随机
    final seedLock = flag('seed_lock');
    if (seedLock != null) {
      if (seedLock && ref.read(generationParamsNotifierProvider).seed == -1) {
        notifier.pinRandomSeed();
      } else if (!seedLock) {
        notifier.updateSeed(-1);
      }
      applied.add('seed_lock');
    }
    apply<int>('n_samples', integer('n_samples'), notifier.updateNSamples);
    apply<int>('uc_preset', integer('uc_preset'), notifier.updateUcPreset);
    if (payload.containsKey('quality_preset')) {
      final presetValue = str('quality_preset');
      final preset = QualityTagPreset.tryParse(presetValue);
      if (preset == null) {
        throw ArgumentError.value(
          payload['quality_preset'],
          'quality_preset',
          'Expected standard, light, or none',
        );
      }
      notifier.updateQualityPreset(preset);
      applied.add('quality_preset');
    } else {
      apply<bool>(
        'quality_toggle',
        flag('quality_toggle'),
        notifier.updateQualityToggle,
      );
    }
    apply<bool>(
      'transparent_background',
      flag('transparent_background'),
      notifier.updateTransparentBackground,
    );
    apply<double>('cfg_rescale', dbl('cfg_rescale'), notifier.updateCfgRescale);
    apply<String>(
      'noise_schedule',
      str('noise_schedule'),
      notifier.updateNoiseSchedule,
    );
    apply<bool>(
      'variety_plus',
      flag('variety_plus'),
      notifier.updateVarietyPlus,
    );
    apply<bool>('smea_auto', flag('smea_auto'), notifier.updateSmeaAuto);
    apply<bool>('smea', flag('smea'), notifier.updateSmea);
    apply<bool>('smea_dyn', flag('smea_dyn'), notifier.updateSmeaDyn);
    apply<bool>('use_coords', flag('use_coords'), notifier.updateUseCoords);

    final w = integer('width');
    final h = integer('height');
    if (w != null || h != null) {
      final cur = ref.read(generationParamsNotifierProvider);
      notifier.updateSize(w ?? cur.width, h ?? cur.height);
      if (w != null) applied.add('width');
      if (h != null) applied.add('height');
    }

    final chars = payload['characters'];
    if (chars is List) {
      // 双写：UI 角色系统（characterPromptNotifier，界面可见+UI生成用）
      //      + 生成参数态（generationParams.characters，桥接 generate 用）
      final uiChars = <char_model.CharacterPrompt>[];
      final paramChars = <CharacterPrompt>[];
      for (final entry in chars) {
        if (entry is! Map || entry['prompt'] is! String) continue;
        final prompt = entry['prompt'] as String;
        final uc = entry['uc'] is String ? entry['uc'] as String : '';
        final x = entry['x'] is num ? (entry['x'] as num).toDouble() : null;
        final y = entry['y'] is num ? (entry['y'] as num).toDouble() : null;
        final hasPos = x != null && y != null;
        final existing = ref
            .read(characterPromptNotifierProvider)
            .characters
            .where((c) => c.id == entry['id'])
            .firstOrNull;
        uiChars.add(
          (existing ??
                  char_model.CharacterPrompt(
                    id: entry['id'] is String
                        ? entry['id'] as String
                        : const Uuid().v4(),
                  ))
              .copyWith(
                name: entry['name'] is String
                    ? entry['name'] as String
                    : existing?.name ?? '',
                nameIsCustom: entry['name_is_custom'] is bool
                    ? entry['name_is_custom'] as bool
                    : existing?.nameIsCustom ??
                          (entry['name'] is String &&
                              (entry['name'] as String).isNotEmpty),
                prompt: prompt,
                negativePrompt: uc,
                enabled: entry['enabled'] is bool
                    ? entry['enabled'] as bool
                    : existing?.enabled ?? true,
                positionMode: hasPos
                    ? char_model.CharacterPositionMode.custom
                    : char_model.CharacterPositionMode.aiChoice,
                customPosition: hasPos
                    ? char_model.CharacterPosition(
                        mode: char_model.CharacterPositionMode.custom,
                        row: y,
                        column: x,
                      )
                    : null,
              ),
        );
        if (uiChars.last.enabled) {
          paramChars.add(
            CharacterPrompt(
              prompt: prompt,
              negativePrompt: uc,
              position: entry['position'] is String
                  ? entry['position'] as String
                  : null,
              positionX: x,
              positionY: y,
            ),
          );
        }
      }
      ref.read(characterPromptNotifierProvider.notifier).replaceAll(uiChars);
      for (final c in uiChars) {
        ref
            .read(pillWorkspaceProvider(PillScopes.charPos(c.id)).notifier)
            .syncFromPlainText(c.prompt);
        ref
            .read(pillWorkspaceProvider(PillScopes.charNeg(c.id)).notifier)
            .syncFromPlainText(c.negativePrompt);
      }
      notifier.clearCharacters();
      for (final c in paramChars) {
        notifier.addCharacter(c);
      }
      applied.add('characters(${uiChars.length})');
    } else if (flag('clear_characters') == true) {
      ref.read(characterPromptNotifierProvider.notifier).clearAllCharacters();
      notifier.clearCharacters();
      applied.add('clear_characters');
    }

    return applied;
  };
});
