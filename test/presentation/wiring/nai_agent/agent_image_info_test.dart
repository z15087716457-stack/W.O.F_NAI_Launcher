import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_image_info.dart';

void main() {
  test('元数据收成悬停卡摘要：短模型名、参数、角色数、压平提示词', () {
    final info = agentImageInfo({
      'prompt': '1girl,\n  solo,   watercolor',
      'seed': 42,
      'steps': 28,
      'scale': 5.5,
      'sampler': 'k_euler',
      'model': 'nai-diffusion-4-5-full',
      'characterPrompts': ['a', 'b', 'c'],
      'rawJson': '{"huge": true}',
    })!;
    expect(info.model, isNot('nai-diffusion-4-5-full'));
    expect(info.model, isNotEmpty);
    expect(info.seed, 42);
    expect(info.steps, 28);
    expect(info.scale, 5.5);
    expect(info.sampler, 'k_euler');
    expect(info.characters, 3);
    expect(info.prompt, '1girl, solo, watercolor');
  });

  test('没有可显示的字段时返回 null', () {
    expect(agentImageInfo(null), isNull);
    expect(agentImageInfo(const {}), isNull);
    expect(agentImageInfo(const {'software': 'NovelAI'}), isNull);
  });
}
