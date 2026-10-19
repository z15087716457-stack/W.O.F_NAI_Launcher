import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

async function fixture(mcp = {}) {
  const root = await mkdtemp(join(tmpdir(), 'host-mcp-status-'));
  const extension = join(root, 'notices.mjs');
  await writeFile(extension, `export default pi => {
    pi.registerCommand('notice', {handler: async (_, ctx) => {
      ctx.ui.notify('ordinary feedback');
      ctx.ui.notify('real warning', 'warning');
      ctx.ui.notify('real error', 'error');
    }});
  };`);
  const child = spawn(process.execPath, [fileURLToPath(new URL('../host.mjs', import.meta.url))],
    { stdio: ['pipe', 'pipe', 'pipe'] });
  const lines = createInterface({ input: child.stdout });
  const events = [], pending = new Map();
  let sessionId, sequence = 0;
  let diagnostics = '';
  child.stderr.on('data', data => { diagnostics += data; });
  lines.on('line', line => {
    const event = JSON.parse(line);
    events.push(event);
    if (event.type === 'ready') sessionId = event.sessionId;
    const request = pending.get(event.id);
    if (request && ['ready', 'response', 'error'].includes(event.type)) {
      pending.delete(event.id);
      clearTimeout(request.timer);
      if (event.type === 'error') request.reject(new Error(event.message));
      else request.resolve(event);
    }
  });
  const request = (type, fields = {}) => new Promise((resolve, reject) => {
    const id = String(++sequence);
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error('Host request timed out: ' + type + '\n' + diagnostics));
    }, 30000);
    pending.set(id, { resolve, reject, timer });
    child.stdin.write(JSON.stringify({ protocol: 1, workspaceId: 'fixture', sessionId, id, type, ...fields }) + '\n');
  });
  const close = async () => {
    try { if (sessionId && child.exitCode === null) await request('shutdown'); }
    finally {
      child.kill();
      lines.close();
      for (const entry of pending.values()) clearTimeout(entry.timer);
      await rm(root, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    }
  };
  try {
    await request('init', {
      cwd: join(root, 'workspace'), agentDir: join(root, 'agent'),
      systemPrompt: 'Synthetic MCP status test. Never call a model.',
      config: { providerId: 'synthetic', modelId: 'synthetic', protocol: 'openaiChatCompletions',
        baseUrl: 'http://127.0.0.1:1', tools: true },
      extensionPaths: [extension], mcp,
    });
    return { request, events, close };
  } catch (error) { await close(); throw error; }
}

const notices = events => events.filter(e => e.type === 'extension_ui' && e.method === 'notify');

test('host status reads only return mcpStatus; action feedback and other notices still reach Flutter', async () => {
  const f = await fixture();
  try {
    for (let i = 0; i < 2; i++) {
      const start = f.events.length;
      const result = await f.request('mcp_command', { action: 'status' });
      assert.match(result.mcpStatus, /nai_studio: connected, \d+ tools \(codemode\)/);
      assert.deepEqual(notices(f.events.slice(start)), []);
    }
    for (const [action, name, pattern] of [
      ['reconnect', 'nai_studio', /Reconnected to MCP server/],
      ['logout', 'nai_studio', /No stored credentials|Signed out/],
      ['login', 'missing', /No MCP server named/],
    ]) {
      const start = f.events.length;
      const result = await f.request('mcp_command', { action, name });
      assert.match(result.mcpStatus, /nai_studio: (connected|needs sign-in)/);
      const forwarded = notices(f.events.slice(start));
      assert.equal(forwarded.length, 1);
      assert.match(forwarded[0].message, pattern);
    }
    const start = f.events.length;
    await f.request('prompt', { text: '/notice' });
    assert.deepEqual(notices(f.events.slice(start)).map(e => [e.message, e.level]), [
      ['ordinary feedback', 'info'], ['real warning', 'warning'], ['real error', 'error'],
    ]);
    assert.ok(!f.events.some(e => e.type === 'request_permit'), 'status must never request a model');
  } finally { await f.close(); }
});

test('MCP connection warnings and action errors are not swallowed by status capture', async () => {
  const f = await fixture({ mcpServers: { broken: { command: 'synthetic-mcp-command-does-not-exist' } } });
  try {
    const status = await f.request('mcp_command', { action: 'status' });
    assert.match(status.mcpStatus, /broken: failed/);
    assert.ok(notices(f.events).some(e => e.level === 'warning' && /MCP servers need attention/.test(e.message)));
    const start = f.events.length;
    await f.request('mcp_command', { action: 'reconnect', name: 'missing' });
    const forwarded = notices(f.events.slice(start));
    assert.equal(forwarded.length, 1);
    assert.equal(forwarded[0].level, 'error');
    assert.match(forwarded[0].message, /No MCP server named/);
    assert.ok(!f.events.some(e => e.type === 'request_permit'));
  } finally { await f.close(); }
});
