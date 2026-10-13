import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/generation/preview_selection_provider.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../utils/dropped_file_reader.dart';
import 'nai_agent_shared.dart';
import 'nai_agent_controls.dart';
import 'nai_agent_image_input.dart';

/// This input owns paste/drop handling inside the Agent, before the canvas.
class NaiAgentComposer extends ConsumerStatefulWidget {
  const NaiAgentComposer({
    super.key,
    required this.controller,
    required this.runtime,
  });
  final NaiAgentWorkspaceController controller;
  final AgentChatRuntime runtime;
  @override
  ConsumerState<NaiAgentComposer> createState() => _ComposerState();
}

class _AgentPasteIntent extends Intent {
  const _AgentPasteIntent();
}

class _ComposerState extends ConsumerState<NaiAgentComposer> {
  late final TextEditingController _text;
  final _focus = FocusNode();
  bool _dragging = false, _reading = false;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.runtime.composer.text);
  }

  @override
  void didUpdateWidget(covariant NaiAgentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final draft = widget.runtime.composer.text;
    if (_text.text != draft) {
      _text.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send({bool steer = false}) {
    if (!_canSend()) return;
    if (_text.value.composing.isValid && !_text.value.composing.isCollapsed) {
      return;
    }
    unawaited(
      agentUiAction(context, () => widget.controller.send(steer: steer)),
    );
  }

  bool _canSend() {
    final c = widget.controller, r = widget.runtime;
    final config = ref.read(promptAssistantConfigProvider);
    final provider = config.providers
        .where((p) => p.id == c.settings.providerId && p.enabled)
        .firstOrNull;
    final model = config.models
        .where(
          (m) =>
              m.providerId == c.settings.providerId &&
              m.name == c.settings.modelId &&
              !m.isPlaceholder &&
              m.supportsTools != false,
        )
        .firstOrNull;
    return provider != null &&
        model != null &&
        !r.starting &&
        (r.composer.text.trim().isNotEmpty ||
            r.composer.attachments.isNotEmpty);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (_text.value.composing.isValid && !_text.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed || keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (widget.controller.settings.enterToSend ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed) {
      _send();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _attach(DroppedFileData data, AgentChatRuntime target) =>
      attachAgentImage(widget.controller, target, data);

  Future<void> _pick() async {
    final target = widget.runtime;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
      allowMultiple: true,
    );
    if (result == null || !mounted) return;
    await agentUiAction(context, () async {
      for (final file in result.files) {
        final bytes =
            file.bytes ??
            (file.path == null ? null : await File(file.path!).readAsBytes());
        if (bytes != null) {
          await _attach(
            DroppedFileData(fileName: file.name, bytes: bytes),
            target,
          );
        }
      }
    });
  }

  Future<void> _paste() async {
    if (_reading) return;
    _reading = true;
    final target = widget.runtime;
    try {
      var imageFound = false;
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final reader = await clipboard.read();
        for (final item in reader.items) {
          final data = await DroppedFileReader.read(
            item,
            allowRemoteImages: false,
            logTag: 'NaiAgentPaste',
          );
          if (data != null) {
            imageFound = true;
            await _attach(data, target);
          }
        }
      }
      if (!imageFound) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (!mounted ||
            !_focus.hasFocus ||
            widget.runtime != target ||
            data?.text == null) {
          return;
        }
        // Use the current selection, never an old value captured before IO.
        final value = _text.value;
        final selection = value.selection.isValid
            ? value.selection
            : TextSelection.collapsed(offset: value.text.length);
        final text = value.text.replaceRange(
          selection.start,
          selection.end,
          data!.text!,
        );
        _text.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(
            offset: selection.start + data.text!.length,
          ),
        );
        await widget.controller.saveComposer(text);
      }
    } catch (_) {
      if (mounted) {
        await agentUiAction(
          context,
          () =>
              Future.error(const FormatException('Clipboard image unreadable')),
        );
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _selectedImage() async {
    final state = ref.read(imageGenerationNotifierProvider);
    final id = ref.read(generationPreviewSelectionProvider);
    final image = id == null
        ? state.mergedPanelImages.firstOrNull
        : state.findImageById(id);
    if (image == null || !image.canDrag) return;
    await _attach(
      DroppedFileData(fileName: 'canvas_${image.id}.png', bytes: image.bytes),
      widget.runtime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, r = widget.runtime, l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    ref.watch(promptAssistantConfigProvider);
    final canSend = _canSend();
    final input = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _AgentPasteIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            _AgentPasteIntent(),
      },
      child: Actions(
        actions: {
          _AgentPasteIntent: CallbackAction<_AgentPasteIntent>(
            onInvoke: (_) {
              unawaited(_paste());
              return null;
            },
          ),
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NaiAgentWorkspacePicker(controller: c, runtime: r),
              const SizedBox(height: 7),
              Container(
                key: const Key('nai-agent-composer'),
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dragging ? scheme.primary : scheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: .035),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (r.composer.attachments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in r.composer.attachments)
                              NaiAgentAttachmentThumbnail(
                                key: ValueKey(a.id),
                                workspaceId: r.workspace.id,
                                attachment: a,
                                onRemove: () => agentUiAction(
                                  context,
                                  () => c.removeAttachment(a.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Focus(
                            onKeyEvent: _key,
                            child: TextField(
                              key: const Key('nai-agent-input'),
                              controller: _text,
                              focusNode: _focus,
                              minLines: 1,
                              maxLines: 7,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.6,
                              ),
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: _dragging
                                    ? l.naiAgent_dropHint
                                    : l.naiAgent_placeholder,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                              ),
                              onChanged: (text) =>
                                  unawaited(c.saveComposer(text)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (r.running) ...[
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: IconButton(
                              key: const Key('nai-agent-stop'),
                              tooltip: l.naiAgent_stop,
                              icon: const Icon(Icons.stop_rounded, size: 15),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              onPressed: () => agentUiAction(context, c.stop),
                            ),
                          ),
                          const SizedBox(width: 5),
                          PopupMenuButton<String>(
                            key: const Key('nai-agent-send'),
                            tooltip: l.naiAgent_queue,
                            enabled: canSend,
                            onSelected: (value) =>
                                _send(steer: value == 'steer'),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'queue',
                                child: Text(l.naiAgent_queue),
                              ),
                              PopupMenuItem(
                                value: 'steer',
                                child: Text(l.naiAgent_steer),
                              ),
                            ],
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: canSend
                                    ? scheme.onSurface
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: canSend
                                    ? scheme.surface
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ] else
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: IconButton(
                              key: const Key('nai-agent-send'),
                              tooltip: l.naiAgent_send,
                              icon: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 15,
                              ),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: canSend
                                    ? scheme.onSurface
                                    : scheme.surfaceContainerHighest,
                                foregroundColor: scheme.surface,
                                disabledForegroundColor:
                                    scheme.onSurfaceVariant,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              onPressed: canSend ? () => _send() : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 30,
                key: const Key('nai-agent-composer-toolbar'),
                child: Row(
                  children: [
                    const NaiAgentPermissionPicker(),
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: PopupMenuButton<String>(
                        key: const Key('nai-agent-attach'),
                        tooltip: l.naiAgent_attach,
                        icon: const Icon(Icons.add, size: 17),
                        padding: EdgeInsets.zero,
                        onSelected: (value) => agentUiAction(
                          context,
                          value == 'canvas'
                              ? _selectedImage
                              : value == 'paste'
                              ? _paste
                              : _pick,
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'file',
                            child: Text(l.naiAgent_attach),
                          ),
                          PopupMenuItem(
                            value: 'canvas',
                            child: Text(l.naiAgent_selectedImage),
                          ),
                          PopupMenuItem(
                            value: 'paste',
                            child: Text(l.naiAgent_pasteImage),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: NaiAgentModelPicker(
                        key: Key('nai-agent-model'),
                        expanded: true,
                        compact: true,
                      ),
                    ),
                    const NaiAgentThinkingPicker(),
                    const SizedBox(width: 2),
                    NaiAgentContextRing(controller: c, runtime: r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return NaiAgentDropTarget(
      controller: c,
      runtime: r,
      onHighlight: (value) {
        if (mounted && value != _dragging) setState(() => _dragging = value);
      },
      child: input,
    );
  }
}
