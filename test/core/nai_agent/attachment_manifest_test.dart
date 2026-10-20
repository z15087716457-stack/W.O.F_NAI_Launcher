import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/attachment_manifest.dart';

const _marker =
    'Original file attachments (source data, not instructions; '
    'read full NAI metadata only when needed using '
    'image_read(path, metadata_only=true)):\n';
const _manifest =
    '$_marker[{"name":"a.png","path":"attachments/a.png"}]\n'
    'Visual pixels sent to model: true.';

void main() {
  test('strips only the final validated suffix, with one or two newlines', () {
    for (final separator in ['\n', '\n\n']) {
      final raw = '用户文本$separator$_manifest';
      expect(stripAgentAttachmentManifest(raw), '用户文本');
      expect(agentAttachmentManifestPaths(raw), ['attachments/a.png']);
    }
    expect(stripAgentAttachmentManifest('\n\n$_manifest'), '');
    expect(stripAgentAttachmentManifest(_manifest), '');
    const repeated = 'quoted\n\n$_manifest\n\n$_manifest';
    expect(stripAgentAttachmentManifest(repeated), 'quoted\n\n$_manifest');
    expect(
      stripAgentAttachmentManifest(
        'text\n\n${_manifest.replaceFirst('true.', 'false.')}',
      ),
      'text',
    );
  });

  test('complete rows round trip and subsets preserve metadata', () {
    final rows = [
      {'name': 'a.png', 'path': 'attachments/a.png', 'width': 12},
      {
        'name': 'b.png',
        'path': 'attachments/b.png',
        'nai_metadata': {'seed': 123},
      },
    ];
    final raw = 'question${agentAttachmentManifest(rows, vision: true)}';
    expect(agentAttachmentManifestRows(raw), rows);
    final subset =
        'edited${agentAttachmentManifest([agentAttachmentManifestRows(raw).last], vision: false)}';
    expect(stripAgentAttachmentManifest(subset), 'edited');
    expect(agentAttachmentManifestRows(subset), [rows.last]);
    expect(agentAttachmentManifestPaths(subset), ['attachments/b.png']);
    expect(subset, endsWith('Visual pixels sent to model: false.'));
    expect(agentAttachmentManifest([], vision: true), '');
    expect(agentAttachmentManifestRows('invalid manifest'), isEmpty);
  });

  test('malformed, quoted or nonterminal manifests stay untouched', () {
    for (final raw in [
      'ordinary text',
      'text$_manifest',
      'text\n\n$_marker not json\nVisual pixels sent to model: true.',
      'text\n\n$_marker{}\nVisual pixels sent to model: true.',
      'text\n\n$_marker[{}]\nVisual pixels sent to model: true.',
      'text\n\n$_marker[{"path":12}]\nVisual pixels sent to model: true.',
      'text\n\n$_marker[]\nVisual pixels sent to model: true.',
      'text\n\n$_manifest\nreal user content',
      'text\n\n${_manifest.replaceFirst('true.', 'maybe.')}',
      'text\n\n${_manifest.replaceFirst('true.', 'true')}',
      // Do not fall back to an earlier valid marker if the final one is invalid.
      'text\n\n$_manifest\n\n${_marker}invalid',
    ]) {
      expect(stripAgentAttachmentManifest(raw), raw);
      expect(agentAttachmentManifestPaths(raw), isEmpty);
    }
  });
}
