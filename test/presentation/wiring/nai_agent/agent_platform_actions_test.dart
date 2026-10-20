import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

class _Picker extends FilePicker {
  String? target;
  FilePickerResult? files;
  List<String>? extensions;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    extensions = allowedExtensions;
    return target;
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    extensions = allowedExtensions;
    return files;
  }
}

class _Generation extends ImageGenerationNotifier {
  _Generation(this.image);
  final GeneratedImage image;
  @override
  ImageGenerationState build() =>
      ImageGenerationState(currentImages: [image], history: [image]);
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  late _Picker picker;
  FilePicker? original;
  setUp(() {
    h = AgentWiringHarness();
    try {
      original = FilePicker.platform;
    } catch (_) {
      original = null;
    }
    picker = _Picker();
    FilePicker.platform = picker;
  });
  tearDown(() async {
    if (original != null) FilePicker.platform = original!;
    await h.dispose();
  });
  testWidgets(
    'file picker uses image import and export keeps exact JSONL; cancel succeeds',
    (tester) async {
      await tester.runAsync(h.init);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pixels = img.encodePng(img.Image(width: 4, height: 3));
      picker.files = FilePickerResult([
        PlatformFile(name: 'test.png', size: pixels.length, bytes: pixels),
      ]);
      await h.pump(tester);
      expect(await tester.runAsync(h.panel(tester).actions.onPickImages), true);
      await h.finishFiles(tester);
      expect(h.c.selected!.composer.attachments.single.name, 'test.png');
      expect(picker.extensions, contains('png'));
      final r = h.c.selected!, old = r.chat;
      final text =
          '${jsonEncode({'type': 'session', 'cwd': r.workspace.directory.path})}\n{"type":"message","custom":"unchanged"}\n';
      File(
        '${r.workspace.sessions.path}/session.jsonl',
      ).writeAsStringSync(text);
      r.chat = AgentChat(
        id: old.id,
        workspaceId: old.workspaceId,
        title: old.title,
        createdAt: old.createdAt,
        sessionFile: 'sessions/session.jsonl',
      );
      picker.target = '${h.root.path}/export.jsonl';
      expect(await tester.runAsync(h.panel(tester).actions.onExport), true);
      expect(File(picker.target!).readAsStringSync(), text);
      expect(picker.extensions, ['jsonl']);
      picker.target = null;
      expect(await tester.runAsync(h.panel(tester).actions.onExport), true);
    },
  );
  testWidgets(
    'canvas and recent-image mentions attach by image id without generation',
    (tester) async {
      final image = GeneratedImage(
        id: 'recent',
        bytes: img.encodePng(img.Image(width: 4, height: 3)),
        width: 4,
        height: 3,
      );
      await tester.runAsync(
        () => h.init(
          overrides: [
            imageGenerationNotifierProvider.overrideWith(
              () => _Generation(image),
            ),
          ],
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final keep = h.container.listen(
        imageGenerationNotifierProvider,
        (_, __) {},
      );
      addTearDown(keep.close);
      await h.pump(tester);
      expect(h.panel(tester).data.composer.canAttachCanvas, true);
      expect(
        h
            .panel(tester)
            .data
            .mentions
            .where((m) => m.kind == view.AgentMentionKind.image)
            .single
            .id,
        'recent',
      );
      expect(
        await tester.runAsync(h.panel(tester).actions.onAttachCanvas),
        true,
      );
      expect(
        await tester.runAsync(
          () => h.panel(tester).actions.onAttachImage('recent'),
        ),
        true,
      );
      expect(h.c.selected!.composer.attachments, hasLength(2));
      expect(h.c.calls, isEmpty);
    },
  );
  testWidgets(
    'memory rules load locally and disabled/shadowed skills are absent',
    (tester) async {
      await tester.runAsync(
        () => h.init(
          skills: const NaiAgentSkillInventory(
            [
              NaiAgentSkill(
                key: 'global/on',
                name: 'on',
                source: 'global',
                state: 'active',
              ),
              NaiAgentSkill(
                key: 'global/off',
                name: 'off',
                source: 'global',
                state: 'active',
              ),
              NaiAgentSkill(
                key: 'builtin/shadowed',
                name: 'shadowed',
                source: 'builtin',
                state: 'shadowed',
              ),
            ],
            0,
            {},
          ),
        ),
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await h.c.updateSettings({
        'globalInstructions': 'global rule',
        'disabledSkills': ['global/off'],
      });
      File(
        '${h.c.selected!.workspace.directory.path}/instructions.md',
      ).writeAsStringSync('workspace rule');
      await h.pump(tester, files: true);
      expect(h.panel(tester).data.memory!.globalInstructions, 'global rule');
      expect(h.panel(tester).data.memory!.workspaceRules, 'workspace rule');
      expect(h.panel(tester).data.memory!.activeSkills, ['on']);
      expect(h.panel(tester).data.skills.map((s) => s.name), ['on']);
    },
  );
  testWidgets('settings and memory actions route to actual Agent sections', (
    tester,
  ) async {
    await tester.runAsync(h.init);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: AgentWiring()),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('settings target')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final target in view.AgentMemoryTarget.values) {
      h.panel(tester).actions.onEditMemory(target);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['section'],
        'agent',
      );
      expect(
        router.routeInformationProvider.value.uri.queryParameters['anchor'],
        switch (target) {
          view.AgentMemoryTarget.global => 'agentInstructions',
          view.AgentMemoryTarget.workspace => 'agentWorkspaceRules',
          view.AgentMemoryTarget.skills => 'agentSkills',
          view.AgentMemoryTarget.quick => 'agentQuick',
        },
      );
      router.go('/');
      await tester.pumpAndSettle();
    }
    h.panel(tester).actions.onOpenModelSettings();
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['section'],
      'models',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
