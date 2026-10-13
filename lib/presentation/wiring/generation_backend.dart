import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../providers/auth_provider.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/cost_estimate_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/generation/local_upscale_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/pill_workspace_provider.dart';
import '../ui/gen/gen_contract.dart';

final generationPlatformProvider = Provider<GenerationPlatform>(
  (ref) => const GenerationPlatform(),
);
final generationBackendProvider = Provider<GenerationBackend>(
  GenerationBackend.new,
);
final generationNegativeTabProvider = StateProvider<bool>((ref) => false);
final generationEncodingReferencesProvider = StateProvider<Set<String>>(
  (ref) => const {},
);

class GenerationPlatform {
  const GenerationPlatform();

  Future<void> backupDraft(String snapshot) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(p.join(root.path, 'draft-backups'));
    await directory.create(recursive: true);
    final file = File(
      p.join(
        directory.path,
        'before-generation-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(snapshot, flush: true);
  }
}

class GenerationPromptUndo {
  const GenerationPromptUndo({
    required this.scope,
    required this.before,
    required this.after,
    required this.ticket,
    required this.accountRevision,
    this.characterId,
    required this.negative,
  });
  final String scope;
  final PillDocument before;
  final PillDocument after;
  final int ticket;
  final int accountRevision;
  final String? characterId;
  final bool negative;
}

class GenerationBackend {
  GenerationBackend(this.ref) {
    ref.onDispose(() => _disposed = true);
    ref.listen(imagesPerRequestProvider, (_, _) => _intentRevision++);
    ref.listen(generationImg2ImgEnabledProvider, (_, _) => _intentRevision++);
    ref.listen(imageWorkflowControllerProvider, (_, _) => _intentRevision++);
    ref.listen(
      generationEncodingReferencesProvider,
      (_, _) => _encodingRevision++,
    );
    ref.listen(
      authNotifierProvider.select((state) => (state.accountId, state.status)),
      (_, _) {
        _intentRevision++;
        _accountRevision++;
        if (ref.read(imageGenerationNotifierProvider).isGenerating) {
          ref.read(imageGenerationNotifierProvider.notifier).cancel();
        }
      },
    );
    ref.listen(
      imageGenerationNotifierProvider.select(
        (state) => (state.generationRunId, state.status),
      ),
      (_, _) => _intentRevision++,
    );
  }
  final Ref ref;
  Future<void> _queue = Future<void>.value();
  bool _writing = false;
  bool _launching = false;
  bool _disposed = false;
  int _intentRevision = 0;
  int _encodingRevision = 0;
  int _accountRevision = 0;
  int _nextPromptTicket = 0;
  final _promptTickets = <String, int>{};

  bool get busy =>
      _disposed ||
      ref.read(imageGenerationNotifierProvider).isGenerating ||
      ref.read(imageWorkflowControllerProvider).isToolRunning ||
      (ref.exists(kritaBridgeNotifierProvider) &&
          ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) ||
      (ref.exists(localUpscaleTaskProvider) &&
          ref.read(localUpscaleTaskProvider).running);

  Future<void> mutate(void Function() write, {bool Function()? alive}) {
    final operation = _queue.then((_) => captureDraft(alive: alive)(write));
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  Future<void> Function(void Function()) captureDraft({
    bool Function()? alive,
  }) {
    if (_disposed) throw StateError(currentL10n.bridge_conflict);
    final intent = _intentRevision;
    final params = ref.read(generationParamsNotifierProvider);
    final version = ref.read(bridgeDraftVersionProvider);
    final workflow = ref.read(imageWorkflowControllerProvider);
    final auth = ref.read(authNotifierProvider);
    void check() {
      if (_disposed ||
          alive?.call() == false ||
          intent != _intentRevision ||
          params != ref.read(generationParamsNotifierProvider) ||
          version != ref.read(bridgeDraftVersionProvider) ||
          !identical(workflow, ref.read(imageWorkflowControllerProvider)) ||
          auth.accountId != ref.read(authNotifierProvider).accountId ||
          auth.status != ref.read(authNotifierProvider).status) {
        throw StateError(currentL10n.bridge_conflict);
      }
      if (busy) throw StateError(currentL10n.kritaBridge_busyGenerating);
    }

    check();
    final snapshot = _snapshot();
    return (write) async {
      if (_writing) throw StateError(currentL10n.bridge_conflict);
      _writing = true;
      try {
        check();
        await ref.read(generationPlatformProvider).backupDraft(snapshot);
        check();
        write();
      } finally {
        _writing = false;
      }
    };
  }

  Future<void> generate({
    required Future<bool> Function(int cost) confirm,
    bool Function()? alive,
    void Function()? onStarted,
  }) async {
    if (_launching ||
        ref.read(generationEncodingReferencesProvider).isNotEmpty ||
        busy ||
        ref.read(generationCooldownProvider).isActive ||
        alive?.call() == false) {
      return;
    }
    _launching = true;
    try {
      final request = ref.read(generationRequestParamsProvider);
      if (request.prompt.trim().isEmpty) return;
      final version = ref.read(bridgeDraftVersionProvider);
      final workflow = ref.read(imageWorkflowControllerProvider);
      final auth = ref.read(authNotifierProvider);
      final count = ref.read(imagesPerRequestProvider);
      final cost = ref.read(estimatedCostProvider);
      final intent = _intentRevision;
      final encodingRevision = _encodingRevision;
      bool valid() =>
          !_disposed &&
          encodingRevision == _encodingRevision &&
          ref.read(generationEncodingReferencesProvider).isEmpty &&
          intent == _intentRevision &&
          alive?.call() != false &&
          !busy &&
          !ref.read(generationCooldownProvider).isActive &&
          request == ref.read(generationRequestParamsProvider) &&
          version == ref.read(bridgeDraftVersionProvider) &&
          identical(workflow, ref.read(imageWorkflowControllerProvider)) &&
          auth.accountId == ref.read(authNotifierProvider).accountId &&
          auth.status == ref.read(authNotifierProvider).status &&
          count == ref.read(imagesPerRequestProvider) &&
          cost == ref.read(estimatedCostProvider);
      if (!await confirm(cost) || !valid()) return;
      await ref.read(generationPlatformProvider).backupDraft(_snapshot());
      if (!valid()) return;
      onStarted?.call();
      await ref
          .read(imageGenerationNotifierProvider.notifier)
          .generate(request, imagesPerRequestOverride: count);
    } finally {
      _launching = false;
    }
  }

  Future<void> retry({
    required Future<bool> Function(int cost) confirm,
    bool Function()? alive,
  }) async {
    if (_launching ||
        busy ||
        alive?.call() == false ||
        ref.read(generationCooldownProvider).isActive ||
        ref.read(generationEncodingReferencesProvider).isNotEmpty) {
      return;
    }
    final notifier = ref.read(imageGenerationNotifierProvider.notifier);
    final request = notifier.lastRequest;
    if (request == null ||
        request.accountId != ref.read(authNotifierProvider).accountId ||
        ref.read(imageGenerationNotifierProvider).status !=
            GenerationStatus.error) {
      return;
    }
    final write = captureDraft(alive: alive);
    final account = _accountRevision;
    final intent = _intentRevision;
    final encoding = _encodingRevision;
    final params = ref.read(generationParamsNotifierProvider);
    final version = ref.read(bridgeDraftVersionProvider);
    int cost() => generationRequestCost(
      request.params,
      request.workflow,
      ref.read(subscriptionNotifierProvider).subscription,
      request.count,
    );
    final quoted = cost();
    bool valid() =>
        !_disposed &&
        alive?.call() != false &&
        !busy &&
        account == _accountRevision &&
        intent == _intentRevision &&
        encoding == _encodingRevision &&
        params == ref.read(generationParamsNotifierProvider) &&
        version == ref.read(bridgeDraftVersionProvider) &&
        identical(notifier.lastRequest, request) &&
        quoted == cost();
    _launching = true;
    try {
      if (!await confirm(quoted) || !valid()) return;
      await write(() {});
      if (valid()) await notifier.retry(request);
    } finally {
      _launching = false;
    }
  }

  Future<GenerationPromptUndo?> clearPrompt(
    GenEditorTarget target, {
    bool Function()? alive,
  }) async {
    final characters = ref.read(characterPromptNotifierProvider).characters;
    final index = target.character;
    if (index != null && (index < 0 || index >= characters.length)) return null;
    final character = index == null ? null : characters[index];
    final scope = character == null
        ? target.negative
              ? PillScopes.negative
              : PillScopes.main
        : target.negative
        ? PillScopes.charNeg(character.id)
        : PillScopes.charPos(character.id);
    final raw = character == null
        ? target.negative
              ? ref.read(generationParamsNotifierProvider).negativePrompt
              : ref.read(generationParamsNotifierProvider).prompt
        : target.negative
        ? character.negativePrompt
        : character.prompt;
    final before = _document(scope, raw);
    if (before.text.isEmpty && before.instances.isEmpty && raw.isEmpty) {
      return null;
    }
    final write = captureDraft(alive: alive);
    late GenerationPromptUndo undo;
    await write(() {
      final accountRevision = _accountRevision;
      _writePrompt(scope, character?.id, target.negative, PillDocument.empty());
      final ticket = ++_nextPromptTicket;
      _promptTickets[scope] = ticket;
      undo = GenerationPromptUndo(
        scope: scope,
        before: before,
        after: ref.read(pillWorkspaceProvider(scope)).document,
        ticket: ticket,
        accountRevision: accountRevision,
        characterId: character?.id,
        negative: target.negative,
      );
    });
    return undo;
  }

  Future<void> undoPrompt(
    GenerationPromptUndo undo, {
    bool Function()? alive,
  }) async {
    void check() {
      if (_disposed ||
          _accountRevision != undo.accountRevision ||
          _promptTickets[undo.scope] != undo.ticket ||
          !identical(_document(undo.scope, ''), undo.after)) {
        throw StateError(currentL10n.bridge_conflict);
      }
      final character = undo.characterId == null
          ? null
          : ref
                .read(characterPromptNotifierProvider)
                .findCharacterById(undo.characterId!);
      final raw = undo.characterId == null
          ? undo.negative
                ? ref.read(generationParamsNotifierProvider).negativePrompt
                : ref.read(generationParamsNotifierProvider).prompt
          : undo.negative
          ? character?.negativePrompt
          : character?.prompt;
      if (raw != '') throw StateError(currentL10n.bridge_conflict);
    }

    check();
    await captureDraft(alive: alive)(() {
      check();
      _writePrompt(undo.scope, undo.characterId, undo.negative, undo.before);
      _promptTickets[undo.scope] = ++_nextPromptTicket;
    });
  }

  PillDocument _document(String scope, String fallback) =>
      ref.exists(pillWorkspaceProvider(scope))
      ? ref.read(pillWorkspaceProvider(scope)).document
      : ref.read(pillWorkspaceStorageProvider).tryLoadSync(scope) ??
            PillDocument(text: fallback, instances: const {});

  void _writePrompt(
    String scope,
    String? characterId,
    bool negative,
    PillDocument document,
  ) {
    if (characterId != null &&
        ref
                .read(characterPromptNotifierProvider)
                .findCharacterById(characterId) ==
            null) {
      throw StateError(currentL10n.bridge_conflict);
    }
    ref.read(pillWorkspaceProvider(scope).notifier).restoreDocument(document);
    final value = ref.read(pillWorkspaceProvider(scope)).projection;
    if (characterId == null) {
      final notifier = ref.read(generationParamsNotifierProvider.notifier);
      if (negative) {
        notifier.updateNegativePromptImmediately(value);
      } else {
        notifier.updatePromptImmediately(value);
      }
    } else {
      final character = ref
          .read(characterPromptNotifierProvider)
          .findCharacterById(characterId)!;
      ref
          .read(characterPromptNotifierProvider.notifier)
          .updateCharacter(
            negative
                ? character.copyWith(negativePrompt: value)
                : character.copyWith(prompt: value),
          );
    }
  }

  String _snapshot() {
    final params = ref.read(generationParamsNotifierProvider);
    final workflow = ref.read(imageWorkflowControllerProvider);
    return jsonEncode({
      ...readBridgeDraft(ref).toJson(),
      'generation': params.toJson(),
      'img2imgEnabled': ref.read(generationImg2ImgEnabledProvider),
      'sourceImage': params.sourceImage == null
          ? null
          : base64Encode(params.sourceImage!),
      'maskImage': params.maskImage == null
          ? null
          : base64Encode(params.maskImage!),
      'vibes': [
        for (final vibe in params.vibeReferencesV4)
          {
            ...vibe.toJson(),
            'rawImageData': vibe.rawImageData == null
                ? null
                : base64Encode(vibe.rawImageData!),
            'thumbnail': vibe.thumbnail == null
                ? null
                : base64Encode(vibe.thumbnail!),
          },
      ],
      'precise': [
        for (final reference in params.preciseReferences)
          {
            'image': base64Encode(reference.image),
            'type': reference.type.name,
            'strength': reference.strength,
            'fidelity': reference.fidelity,
            'enabled': reference.enabled,
          },
      ],
      'workflow': {
        'mode': workflow.mode.name,
        'sourceWidth': workflow.sourceWidth,
        'sourceHeight': workflow.sourceHeight,
        'sourceImageWidth': workflow.sourceImageWidth,
        'sourceImageHeight': workflow.sourceImageHeight,
        'baseWidth': workflow.baseWidth,
        'baseHeight': workflow.baseHeight,
        'baseStrength': workflow.baseStrength,
        'baseNoise': workflow.baseNoise,
        'isPanelExpanded': workflow.isPanelExpanded,
        'isOutpaint': workflow.isOutpaint,
        'temporaryEnhanceSource': workflow.temporaryEnhanceSource == null
            ? null
            : base64Encode(workflow.temporaryEnhanceSource!),
        'enhanceUsesGenerationSize': workflow.enhanceUsesGenerationSize,
        'enhance': {
          'magnitude': workflow.enhance.magnitude,
          'individualSettings': workflow.enhance.showIndividualSettings,
          'strength': workflow.enhance.strength,
          'noise': workflow.enhance.noise,
          'upscaleFactor': workflow.enhance.upscaleFactor,
          'maxUpscale': workflow.enhance.maxUpscale,
          'localUpscale': workflow.enhance.localUpscale,
        },
        'upscale': {
          'backend': workflow.upscale.backend.name,
          'localModel': workflow.upscale.localModel,
          'localScale': workflow.upscale.localScale,
          'localSeedvr2Model': workflow.upscale.localSeedvr2Model,
          'localSeedvr2Options': {
            for (final entry in workflow.upscale.localSeedvr2Options.entries)
              entry.key: entry.value.toJson(),
          },
          'comfyModule': workflow.upscale.comfyModule.name,
          'comfyScale': workflow.upscale.comfyScale,
          'comfyModel': workflow.upscale.comfyModel,
          'comfyRegularModel': workflow.upscale.comfyRegularModel,
          'comfySeedvr2Model': workflow.upscale.comfySeedvr2Model,
          'seedvr2VaeTileSize': workflow.upscale.seedvr2VaeTileSize,
          'seedvr2Tiled': workflow.upscale.seedvr2Tiled,
          'seedvr2TileSize': workflow.upscale.seedvr2TileSize,
          'seedvr2BlocksToSwap': workflow.upscale.seedvr2BlocksToSwap,
        },
      },
    });
  }
}
