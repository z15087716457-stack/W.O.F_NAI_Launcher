import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import 'explore_variables_view.dart';
export 'explore_variables_view.dart';

class ExploreRandomVariablesModule extends ConsumerWidget {
  const ExploreRandomVariablesModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ExploreRandomVariablesView(
        positive: ref.watch(pillWorkspaceProvider(PillScopes.main)).document,
        negative: ref
            .watch(pillWorkspaceProvider(PillScopes.negative))
            .document,
        library: ref.watch(promptBlockLibraryNotifierProvider).valueOrNull,
        onOpenLibrary: () => ref
            .read(layoutStateNotifierProvider.notifier)
            .toggleBlockLibraryPanel(),
      );
}
