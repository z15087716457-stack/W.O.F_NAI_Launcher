import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

test('host pushes usage on Pi 1.3 compaction_end, not retired auto_compaction_end', async () => {
  const source = await readFile(new URL('../host.mjs', import.meta.url), 'utf8');
  assert.match(source, /\['message_end', 'compaction_end', 'agent_settled'\]\.includes\(event\.type\)/);
  assert.doesNotMatch(source, /auto_compaction_end/);
});
