import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';

void main() {
  late Directory root;
  late BridgeDraftSnapshot draft;
  late NaiAgentStudioTools tools;
  late List<BridgeDraftSnapshot> backups;
  late bool busy;
  Future<void> Function()? onBackup;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-studio-tools-');
    draft = BridgeDraftSnapshot(
      fields: {'prompt': 'raw draft', 'negative_prompt': 'raw negative'},
    );
    backups = [];
    busy = false;
    onBackup = null;
    tools = NaiAgentStudioTools(
      workspaceDirectory: root,
      allowsImages: true,
      readDraft: () => draft,
      readSummary: () => {'page': '/generation'},
      isGenerating: () => busy,
      backupDraft: (value) async {
        backups.add(value);
        await onBackup?.call();
        return 'test-backup';
      },
      writeDraft: (patch) {
        draft = BridgeDraftSnapshot(fields: {...draft.fields, ...patch});
        return patch.keys.toList();
      },
      readImage: (_) => null,
    );
  });
  tearDown(() async => root.delete(recursive: true));
  final conflict = throwsA(
    isA<NaiAgentToolError>().having((e) => e.code, 'code', 'draft_conflict'),
  );

  test(
    'summary stays small; full raw draft and document versions are on demand',
    () async {
      final summary = await tools.execute(
        'studio_context',
        {},
        NaiAgentCancellation(),
      );
      expect(summary['details']['draft'], isNull);
      final actual = await tools.execute('studio_context', {
        'scope': 'draft',
      }, NaiAgentCancellation());
      expect(actual['details']['draft']['fields']['prompt'], 'raw draft');
      expect(actual['details']['draft']['field_versions'], draft.fieldVersions);
    },
  );
  test(
    'pill_conflict protects changed main/UC and removed or changed character lanes before backup',
    () async {
      const document = {
        'text': '\uE000',
        'instances': {
          '\uE000': {
            'blockId': '',
            'temp': {'content': 'words'},
          },
        },
      };
      final initial = BridgeDraftSnapshot(
        fields: {
          'prompt': 'words',
          'negative_prompt': 'words',
          'characters': [
            {'id': 'c1', 'prompt': 'words', 'uc': 'words'},
          ],
        },
        documents: {
          'prompt': document,
          'negative_prompt': document,
          'characters': {
            'lanes': {
              'c1': {'positive': document, 'negative': document},
            },
          },
        },
      );
      for (final changes in [
        {'prompt': 'new'},
        {'prompt': '\uE000'},
        {'negative_prompt': 'new'},
        {'clear_characters': true},
        {'characters': <dynamic>[]},
        {
          'characters': [
            {'id': 'c1', 'prompt': 'new', 'uc': 'words'},
          ],
        },
        {
          'characters': [
            {'id': 'c1', 'prompt': 'words'},
          ],
        },
        {
          'characters': [
            {'prompt': 'words', 'uc': 'words'},
          ],
        },
      ]) {
        draft = initial;
        await expectLater(
          tools.execute('prompt_update', {
            'changes': changes,
            'expected': draft.fieldVersions,
          }, NaiAgentCancellation()),
          throwsA(
            isA<NaiAgentToolError>().having(
              (e) => e.code,
              'code',
              'pill_conflict',
            ),
          ),
        );
        expect(backups, isEmpty);
      }
      draft = initial;
      await tools.execute('prompt_update', {
        'changes': {
          'prompt': 'words',
          'negative_prompt': 'words',
          'characters': [
            {'id': 'c1', 'prompt': 'words', 'uc': 'words', 'name': 'renamed'},
          ],
        },
        'expected': draft.fieldVersions,
      }, NaiAgentCancellation());
      expect(backups, hasLength(1));
    },
  );

  test(
    'backup precedes write and return value is actual post-write draft',
    () async {
      final old = draft;
      final result = await tools.execute('prompt_update', {
        'changes': {'prompt': 'new'},
        'expected': old.fieldVersions,
      }, NaiAgentCancellation());
      expect(backups.single, same(old));
      expect(result['details']['draft']['fields']['prompt'], 'new');
      expect(
        result['details']['draft']['field_versions']['prompt'],
        draft.fieldVersions['prompt'],
      );
      expect(result['details']['backup_path'], 'test-backup');
    },
  );
  test('stale or incomplete versions refuse before backup', () async {
    await expectLater(
      tools.execute('prompt_update', {
        'changes': {'prompt': 'new'},
        'expected': {},
      }, NaiAgentCancellation()),
      conflict,
    );
    expect(backups, isEmpty);
    expect(draft.fields['prompt'], 'raw draft');
  });
  test('changes during backup never overwrite the newer edit', () async {
    final before = draft;
    onBackup = () async {
      draft = BridgeDraftSnapshot(
        fields: {...draft.fields, 'prompt': 'human edit'},
      );
    };
    await expectLater(
      tools.execute('prompt_update', {
        'changes': {'prompt': 'agent edit'},
        'expected': before.fieldVersions,
      }, NaiAgentCancellation()),
      conflict,
    );
    expect(draft.fields['prompt'], 'human edit');
    expect(backups.single.fields['prompt'], 'raw draft');
  });
  test('cancel during backup prevents committing', () async {
    final token = NaiAgentCancellation();
    onBackup = () async => token.cancel();
    await expectLater(
      tools.execute('prompt_update', {
        'changes': {'prompt': 'agent edit'},
        'expected': draft.fieldVersions,
      }, token),
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    expect(draft.fields['prompt'], 'raw draft');
  });
  test('generation starting during backup prevents committing', () async {
    onBackup = () async => busy = true;
    await expectLater(
      tools.execute('prompt_update', {
        'changes': {'prompt': 'agent edit'},
        'expected': draft.fieldVersions,
      }, NaiAgentCancellation()),
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', 'busy')),
    );
    expect(draft.fields['prompt'], 'raw draft');
  });
  test(
    'bad later field refuses the whole patch; unaffected newer edits survive',
    () async {
      final before = draft;
      await expectLater(
        tools.execute('prompt_update', {
          'changes': {'prompt': 'new', 'width': -1},
          'expected': before.fieldVersions,
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'invalid_patch',
          ),
        ),
      );
      expect(backups, isEmpty);
      draft = BridgeDraftSnapshot(
        fields: {...draft.fields, 'negative_prompt': 'new negative'},
      );
      await tools.execute('prompt_update', {
        'changes': {'prompt': 'agent edit'},
        'expected': before.fieldVersions,
      }, NaiAgentCancellation());
      expect(draft.fields['negative_prompt'], 'new negative');
    },
  );
  test(
    'image_read returns actual selected pixels and original metadata without rewriting',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 3, height: 2)),
      );
      tools = NaiAgentStudioTools(
        workspaceDirectory: root,
        allowsImages: true,
        readDraft: () => draft,
        readSummary: () => {},
        isGenerating: () => false,
        backupDraft: (_) async => 'unused',
        writeDraft: (_) => [],
        readImage: (_) => NaiAgentImage(
          id: 'frozen-image',
          bytes: bytes,
          metadata: {'prompt': 'original image'},
        ),
      );
      final result = await tools.execute('image_read', {
        'image_id': 'selected',
      }, NaiAgentCancellation());
      expect(base64Decode(result['content'][1]['data']), bytes);
      expect(result['details']['image_id'], 'frozen-image');
      expect(result['details']['width'], 3);
      expect(result['details']['metadata']['prompt'], 'original image');
      expect(draft.fields['prompt'], 'raw draft');
    },
  );
  test(
    'workspace file reads preserve bytes, reject escaping paths and absolute paths',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 2, height: 1)),
      );
      final inside = File('${root.path}/sample.png');
      await inside.writeAsBytes(bytes);
      final result = await tools.execute('image_read', {
        'path': 'sample.png',
      }, NaiAgentCancellation());
      expect(base64Decode(result['content'][1]['data']), bytes);
      expect(await inside.readAsBytes(), bytes);
      await expectLater(
        tools.execute('image_read', {
          'path': inside.path,
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'path_outside_workspace',
          ),
        ),
      );
      final outside = File('${root.parent.path}/nai-agent-outside-test.png');
      await outside.writeAsBytes(bytes);
      try {
        await expectLater(
          tools.execute('image_read', {
            'path': '../nai-agent-outside-test.png',
          }, NaiAgentCancellation()),
          throwsA(
            isA<NaiAgentToolError>().having(
              (e) => e.code,
              'code',
              'path_outside_workspace',
            ),
          ),
        );
      } finally {
        await outside.delete();
      }
    },
  );
}
