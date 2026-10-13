import 'dart:io';
import 'dart:typed_data';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';

/// Local artifacts remain visible even when the selected model has no vision.
class NaiAgentImageArtifact extends StatefulWidget {
  const NaiAgentImageArtifact({
    super.key,
    required this.workspace,
    required this.path,
  });
  final Directory workspace;
  final String path;
  @override
  State<NaiAgentImageArtifact> createState() => _ImageArtifactState();
}

class _ImageArtifactState extends State<NaiAgentImageArtifact> {
  late Future<Uint8List> _bytes = _load();
  Future<Uint8List> _load() async {
    final bytes = await AgentWorkspaceFiles(widget.workspace).read(widget.path);
    final size = NaiResolutionAdapter.readImageSize(bytes);
    if (size == null || size.$1 * size.$2 > 64000000) {
      throw const FormatException('Invalid image artifact');
    }
    return bytes;
  }

  @override
  void didUpdateWidget(NaiAgentImageArtifact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.workspace.path != widget.workspace.path) {
      _bytes = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          return Tooltip(
            message: context.l10n.detail_imageDetails,
            child: Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: bytes == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          child: SizedBox(
                            width: 960,
                            height: MediaQuery.sizeOf(context).height * .8,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                InteractiveViewer(
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stack) =>
                                        const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).closeButtonTooltip,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 112,
                      child: bytes != null
                          ? Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              cacheWidth: 320,
                              errorBuilder: (context, error, stack) =>
                                  const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                            )
                          : Center(
                              child: snapshot.hasError
                                  ? const Icon(Icons.broken_image_outlined)
                                  : const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      child: Text(
                        p.basename(widget.path),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
