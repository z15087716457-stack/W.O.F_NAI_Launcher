import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdir, mkdtemp, access, readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { createStudioSession } from '../lib/session.mjs';

async function fixture({ mode = 'readonly', tool = 'write', params = { path: 'target.txt', content: 'synthetic' }, answer = 'DENY', execute } = {}) {
  await mkdir('.runs', { recursive: true });
  const root = resolve(await mkdtemp('.runs/permissions-'));
  const calls = [], requests = [];
  const server = createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    const delta = requests.length === 1
      ? { role: 'assistant', tool_calls: [{ index: 0, id: 'policy-test', type: 'function', function: { name: tool, arguments: JSON.stringify(params) } }] }
      : { role: 'assistant', content: 'done' };
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    res.end('data: ' + JSON.stringify({ id: 'test', object: 'chat.completion.chunk', model: 'test', choices: [{ index: 0, delta, finish_reason: requests.length === 1 ? 'tool_calls' : 'stop' }] }) + '\n\ndata: [DONE]\n\n');
  });
  await new Promise(done => server.listen(0, '127.0.0.1', done));
  const created = await createStudioSession({
    cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'Synthetic permission test.',
    config: { providerId: 'permissions', modelId: 'test', protocol: 'openaiChatCompletions', baseUrl: 'http://127.0.0.1:' + server.address().port, tools: true,
      permissionMode: mode, permissionLabels: { title: 'APPROVE', once: 'ONCE', session: 'SESSION', deny: 'DENY' } },
    extraToolNames: ['snapshot', 'gallery_manage'],
    executeTool: async (name, id, input, signal) => {
      calls.push({ name, id, input });
      if (execute) return execute(name, id, input, signal);
      return { content: [{ type: 'text', text: JSON.stringify(name === '_nai_extension_ui' ? { status: 'answered', value: answer } : { ok: true }) }] };
    },
  });
  return { ...created, root, calls, requests, target: join(root, 'workspace', 'target.txt'), close: async () => {
    await created.close(); server.closeAllConnections(); await new Promise(done => server.close(done));
  } };
}

const exists = async path => { try { await access(path); return true; } catch { return false; } };

test('readonly mode blocks an actual Pi write before any file is created', async () => {
  const f = await fixture();
  try {
    await f.session.prompt('Attempt the synthetic write.');
    assert.equal(await exists(f.target), false);
    assert.equal(f.calls.length, 0);
    assert.equal(f.session.messages.find(message => message.role === 'toolResult').isError, true);
  } finally { await f.close(); }
});

test('ask mode denial blocks the actual file write', async () => {
  const f = await fixture({ mode: 'ask' });
  try {
    await f.session.prompt('Attempt the synthetic write.');
    assert.equal(await exists(f.target), false);
    assert.equal(f.calls[0].name, '_nai_extension_ui');
    assert.equal(f.calls[0].input.kind, 'tool_approval');
  } finally { await f.close(); }
});

test('ask mode explicit approval executes one actual Pi file write', async () => {
  const f = await fixture({ mode: 'ask', answer: 'ONCE' });
  try {
    await f.session.prompt('Attempt the synthetic write.');
    assert.equal(await readFile(f.target, 'utf8'), 'synthetic');
    assert.equal(f.calls.length, 1);
  } finally { await f.close(); }
});

test('auto mode allows a workspace write but never grants a shell call silently', async () => {
  const f = await fixture({ mode: 'auto' });
  try {
    await f.session.prompt('Attempt the synthetic write.');
    assert.equal(await readFile(f.target, 'utf8'), 'synthetic');
    assert.equal(f.calls.length, 0);
  } finally { await f.close(); }
  const shell = await fixture({ mode: 'auto', tool: 'bash', params: { command: 'echo synthetic' } });
  try {
    await shell.session.prompt('Attempt the synthetic command.');
    assert.equal(shell.calls[0].name, '_nai_extension_ui');
    assert.equal(shell.session.messages.find(message => message.role === 'toolResult').isError, true);
  } finally { await shell.close(); }
});

test('readonly policy also blocks nested MCP edits inside CodeMode', async () => {
  const f = await fixture({ tool: 'codemode', params: { code: 'text(await tools.mcp__nai_studio__prompt_update({changes:{prompt:"synthetic"},expected:{prompt:"v1"}}));' } });
  try {
    await f.session.prompt('Attempt the nested synthetic edit.');
    assert.equal(f.calls.length, 0);
    assert.match(JSON.stringify(f.session.messages), /read.only|readonly/i);
  } finally { await f.close(); }
});

test('readonly still permits nested read-only Studio operations', async () => {
  const f = await fixture({ tool: 'codemode', params: { code: 'text(await tools.mcp__nai_studio__snapshot({action:"list"}));' } });
  try {
    await f.session.prompt('Read the synthetic snapshot list.');
    assert.deepEqual(f.calls.map(call => call.name), ['snapshot']);
  } finally { await f.close(); }
});

test('official CodeMode has no direct Node, file or network APIs', async () => {
  const f = await fixture({ tool: 'codemode', params: { code: 'text({process:typeof process,require:typeof require,fetch:typeof fetch}); let blocked=false; try {await import("node:fs/promises");} catch {blocked=true;} text({blocked});' } });
  try {
    await f.session.prompt('Check the synthetic sandbox boundary.');
    const text = JSON.stringify(f.session.messages.find(message => message.role === 'toolResult').content);
    assert.match(text, /process[^a-z]+undefined/);
    assert.match(text, /require[^a-z]+undefined/);
    assert.match(text, /fetch[^a-z]+undefined/);
    assert.match(text, /blocked[^a-z]+true/);
  } finally { await f.close(); }
});

test('auto mode requires approval for a nested gallery deletion', async () => {
  const f = await fixture({ mode: 'auto', tool: 'codemode', params: { code: 'text(await tools.mcp__nai_studio__gallery_manage({action:"delete",scope:"history",image_id:"synthetic",expected_image_version:"v1"}));' } });
  try {
    await f.session.prompt('Attempt the synthetic gallery deletion.');
    assert.deepEqual(f.calls.map(call => call.name), ['_nai_extension_ui']);
    assert.ok(f.calls[0].input.title.includes('gallery_manage'));
  } finally { await f.close(); }
});

test('a live switch to readonly cancels a pending approval without executing', async () => {
  let entered, release;
  const started = new Promise(done => entered = done);
  const f = await fixture({ mode: 'ask', execute: (_name, _id, _params, signal) => {
    entered();
    return new Promise((done, reject) => {
      release = () => done({ content: [{ type: 'text', text: JSON.stringify({ status: 'answered', value: 'ONCE' }) }] });
      signal.addEventListener('abort', () => reject(new Error('cancelled')), { once: true });
    });
  } });
  try {
    const prompt = f.session.prompt('Attempt a synthetic write and wait.');
    await started;
    f.setPermissionMode('readonly');
    release();
    await prompt;
    assert.equal(await exists(f.target), false);
  } finally { await f.close(); }
});
