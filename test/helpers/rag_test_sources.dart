import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

/// Isolated source data for controller tests that do not exercise block storage.
class EmptyRagBlocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}
