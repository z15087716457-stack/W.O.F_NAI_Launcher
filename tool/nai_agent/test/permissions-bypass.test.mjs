import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createNaiPermissions } from '../lib/extensions/permissions.mjs';

async function policy(mode = 'bypass') {
  const root = await mkdtemp(join(tmpdir(), 'nai-bypass-'));
  const cwd = join(root, 'workspace');
  await mkdir(cwd);
  const handlers = {}, prompts = [];
  const permissions = createNaiPermissions({ cwd, mode, labels: { once: 'ONCE', session: 'SESSION', deny: 'DENY' } });
  permissions.extension.factory({ on: (name, handler) => { handlers[name] = handler; } });
  const ctx = { hasUI: true, ui: { select: async (...args) => { prompts.push(args); return 'SESSION'; } } };
  return { ...permissions, root, cwd, prompts, ctx,
    call: (toolName, input = {}, context = ctx) => handlers.tool_call({ toolName, input }, context),
    close: () => rm(root, { recursive: true, force: true }) };
}

for (const [kind, tool, input] of [
  ['edit', 'write', { path: 'test.txt', content: 'x' }],
  ['danger', 'bash', { command: 'not executed' }],
  ['unknown', 'mcp__external__tool', {}],
  ['external-read', 'read', { path: '../outside.txt' }],
  ['native-confirmation', 'generation_run', {}],
  ['native-confirmation image', 'mcp__nai_studio__image_generate', { action: 'run' }],
  ['read', 'read', { path: 'test.txt' }],
  ['studio search', 'mcp__nai_studio__studio_search', { query: 'synthetic' }],
]) {
  test(`bypass allows ${kind} without a host UI approval, also headless`, async () => {
    const p = await policy();
    try {
      assert.equal(await p.call(tool, input), undefined);
      assert.equal(await p.call(tool, input, { hasUI: false }), undefined);
      assert.equal(p.prompts.length, 0);
    } finally { await p.close(); }
  });
}

test('bypass skips oversized previews but still blocks classification failures', async () => {
  const p = await policy();
  try {
    assert.equal(await p.call('write', { path: 'large.txt', content: 'x'.repeat(65000) }), undefined);
    // A NUL target makes canonicalization throw (not an unknown-tool approval).
    assert.equal((await p.call('read', { path: '\0invalid' })).block, true);
    assert.equal(p.prompts.length, 0);
  } finally { await p.close(); }
});

test('ask -> bypass -> ask invalidates identical-call approvals', async () => {
  const p = await policy('ask');
  const input = { path: 'test.txt', content: 'x' };
  try {
    await p.call('write', input);
    await p.call('write', input);
    assert.equal(p.prompts.length, 1);
    p.setMode('bypass');
    await p.call('write', input);
    p.setMode('ask');
    await p.call('write', input);
    assert.equal(p.prompts.length, 2);
  } finally { await p.close(); }
});

test('switch to bypass aborts an existing dialog, requiring an explicit retry', async () => {
  const p = await policy('ask');
  let entered;
  const started = new Promise(resolve => { entered = resolve; });
  p.ctx.ui.select = async (_title, _options, { signal }) => {
    entered();
    await new Promise(resolve => signal.addEventListener('abort', resolve, { once: true }));
    return 'ONCE';
  };
  try {
    const pending = p.call('write', { path: 'test.txt' });
    await started;
    p.setMode('bypass');
    assert.equal((await pending).block, true);
    assert.equal(await p.call('write', { path: 'test.txt' }, { hasUI: false }), undefined);
  } finally { await p.close(); }
});

test('readonly keeps blocking edits and paid calls, studio_search stays read-only', async () => {
  const p = await policy('readonly');
  try {
    assert.equal((await p.call('write', { path: 'test.txt' })).block, true);
    assert.equal((await p.call('generation_run')).block, true);
    assert.equal(await p.call('studio_search', { query: 'test' }), undefined);
    assert.equal(p.prompts.length, 0);
  } finally { await p.close(); }
});

test('readonly treats image_generate status/cancel as reads, like image_tool and explore_manage', async () => {
  const p = await policy('readonly');
  try {
    for (const action of ['prepare', 'status', 'cancel']) {
      assert.equal(await p.call('mcp__nai_studio__image_generate', { action }), undefined, action);
    }
    const blocked = await p.call('mcp__nai_studio__image_generate', { action: 'run' });
    assert.equal(blocked?.block, true);
    assert.equal(p.prompts.length, 0);
  } finally { await p.close(); }
});
