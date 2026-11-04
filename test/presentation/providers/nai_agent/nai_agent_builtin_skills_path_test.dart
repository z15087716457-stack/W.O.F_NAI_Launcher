import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_bundle_paths.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  // macOS 的 agent-data 在「应用支持」里，内置技能在包里的 Contents/Resources/tools；
  // Windows 两者都在 exe 旁边。两边都得指到运行时那份 skills。
  test('built-in skills come from the bundled runtime, not next to the data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final store = container.read(naiAgentWorkspaceStoreProvider);
    final runtime = container.read(naiAgentRuntimePathsProvider);

    expect(store.root.path, AppBundlePaths.agentDataDirectory);
    expect(
      p.normalize(store.builtinSkillsDirectory.path),
      p.normalize(p.join(p.dirname(runtime.host), 'skills')),
    );
  });
}
