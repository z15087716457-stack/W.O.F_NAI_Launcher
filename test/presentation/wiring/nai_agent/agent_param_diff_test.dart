import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_param_diff.dart';

void main() {
  Map<String, dynamic> draft(String model, [Map<String, dynamic>? x]) => {
    'model': model,
    'width': 832,
    'height': 1216,
    'steps': 28,
    'cfg_scale': 5.0,
    'cfg_rescale': 0.0,
    'sampler': 'k_euler_ancestral',
    'noise_schedule': 'karras',
    'seed': -1,
    'n_samples': 1,
    'variety_plus': false,
    'smea_auto': false,
    'smea': false,
    'smea_dyn': false,
    'quality_preset': 'standard',
    'uc_preset': 0,
    'transparent_background': false,
    ...?x,
  };

  test('lists only changed, applicable params with display values', () {
    const v45 = 'nai-diffusion-4-5-full';
    final changes = agentParamChanges(
      [
        'steps',
        'cfg_scale',
        'sampler',
        'seed',
        'cfg_rescale',
        'smea',
        'prompt',
      ],
      draft(v45),
      draft(v45, {
        'steps': 32,
        'cfg_scale': 5.5,
        'sampler': 'k_dpmpp_2m_sde',
        'seed': 1814808702,
        'cfg_rescale': 0.18,
        'smea': true, // V4.5 没有 SMEA：不列
      }),
    );
    expect(changes.map((c) => c.param), [
      AgentParam.steps,
      AgentParam.guidance,
      AgentParam.rescale,
      AgentParam.sampler,
      AgentParam.seed,
    ]);
    expect(changes[0].before.text, '28');
    expect(changes[0].after.text, '32');
    expect(changes[1].after.text, '5.5');
    expect(changes[3].after.text, 'DPM++ 2M SDE');
    expect(changes[4].before.word, AgentParamWord.random);
    expect(changes[4].after.text, '1814808702');
  });

  test('seed_lock counts as a seed change; untouched keys are ignored', () {
    const v5 = 'nai-diffusion-5-full';
    final changes = agentParamChanges(
      ['seed_lock'],
      draft(v5),
      draft(v5, {'seed': 42, 'steps': 99}),
    );
    expect(changes.single.param, AgentParam.seed);
  });

  test('model specific: legacy SMEA and V4 noise schedule, V5 hides them', () {
    const v3 = 'nai-diffusion-3';
    final legacy = agentParamChanges(
      ['smea', 'smea_dyn'],
      draft(v3),
      draft(v3, {'smea': true, 'smea_dyn': true}),
    );
    expect(legacy.single.param, AgentParam.smea);
    expect(legacy.single.after.text, 'SMEA DYN');
    const v5 = 'nai-diffusion-5-full';
    expect(
      agentParamChanges(
        ['noise_schedule', 'variety_plus'],
        draft(v5),
        draft(v5, {'noise_schedule': 'exponential', 'variety_plus': true}),
      ),
      isEmpty,
    );
    final size = agentParamChanges(
      ['width', 'height'],
      draft(v5),
      draft(v5, {'width': 1216, 'height': 832}),
    );
    expect(size.single.param, AgentParam.size);
    expect(size.single.after.text, '1216×832');
  });

  test('restore keys cover every card row', () {
    expect(
      agentParamRestoreKeys(const [
        AgentParamChange(
          AgentParam.size,
          AgentParamValue.text('a'),
          AgentParamValue.text('b'),
        ),
        AgentParamChange(
          AgentParam.smea,
          AgentParamValue.text('a'),
          AgentParamValue.text('b'),
        ),
      ]),
      ['width', 'height', 'smea_auto', 'smea', 'smea_dyn'],
    );
  });
}
