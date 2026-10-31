import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtemp, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { createStudioSession } from '../lib/session.mjs';
import { listenFetchTestServer } from './fixture-http.mjs';

async function fixture({ leafUser = false, rootUser = false, cancel = false, compact = false } = {}) {
  const root = await mkdtemp(join(tmpdir(), 'host-resend-'));
  const requests = [];
  const server = createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    res.writeHead(200, { 'content-type': 'text/event-stream; charset=utf-8', connection: 'close' });
    res.end('data: ' + JSON.stringify({ id: 'synthetic', object: 'chat.completion.chunk', model: 'test',
      choices: [{ index: 0, delta: { role: 'assistant', content: 'new answer' }, finish_reason: 'stop' }] })
      + '\n\ndata: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
  const options = {
    cwd: join(root, 'workspace'), agentDir: join(root, 'workspace', '.agent'),
    sessionDirectory: join(root, 'workspace', 'sessions'),
    systemPrompt: 'Synthetic resend test. Never use external services.',
    executeTool: async () => ({ content: [] }),
    config: { providerId: 'test', modelId: 'test', protocol: 'openaiChatCompletions',
      baseUrl: 'http://127.0.0.1:' + server.address().port, apiKey: 'synthetic', tools: true, vision: true },
  };
  const seeded = await createStudioSession(options);
  const usage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } };
  const m = seeded.manager;
  if (rootUser) m.resetLeaf();
  else {
    m.appendMessage({ role: 'user', timestamp: 1, content: 'earlier question' });
    m.appendMessage({ role: 'assistant', timestamp: 2, content: [{ type: 'text', text: 'parent answer' }],
      api: 'openai-completions', provider: 'test', model: 'test', stopReason: 'stop', usage });
  }
  const image = { type: 'image', mimeType: 'image/png',
    data: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=' };
  const parentId = m.getLeafId();
  const offBranch = m.appendMessage({ role: 'user', timestamp: 4, content: 'off-branch question' });
  if (parentId === null) m.resetLeaf();
  else m.branch(parentId);
  const userId = m.appendMessage({ role: 'user', timestamp: 3,
    content: [{ type: 'text', text: 'original question' }, image] });
  if (!leafUser) m.appendMessage({ role: 'assistant', timestamp: 5,
    content: [{ type: 'text', text: 'old answer' }], api: 'openai-completions',
    provider: 'test', model: 'test', stopReason: 'stop', usage });
  const historyBeforeCompaction = m.getBranch().filter(e => e.type === 'message').map(e => e.message);
  if (compact) m.appendCompaction('Synthetic summary boundary', userId, 131000);
  const sessionFile = seeded.session.sessionFile;
  await seeded.close();
  if (cancel) {
    const { writeFile } = await import('node:fs/promises');
    const extension = join(root, 'cancel.mjs');
    await writeFile(extension, "export default pi => pi.on('session_before_tree', async () => ({cancel: true}));");
    options.extensionPaths = [extension];
  }
  const child = spawn(process.execPath, [fileURLToPath(new URL('../host.mjs', import.meta.url))],
    { stdio: ['pipe', 'pipe', 'pipe'] });
  const lines = createInterface({ input: child.stdout });
  const pending = new Map();
  let sessionId, sequence = 0, diagnostics = '';
  child.stderr.on('data', data => { diagnostics += data; });
  const send = fields => child.stdin.write(JSON.stringify({ protocol: 1, workspaceId: 'fixture', sessionId, ...fields }) + '\n');
  lines.on('line', line => {
    const event = JSON.parse(line);
    if (event.type === 'ready') sessionId = event.sessionId;
    if (event.type === 'request_permit') send({ type: 'permit_result', requestId: event.requestId });
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
    const timer = setTimeout(() => reject(new Error(type + ' timed out\n' + diagnostics)), 30000);
    pending.set(id, { resolve, reject, timer });
    send({ id, type, ...fields });
  });
  const close = async () => {
    try { if (sessionId && child.exitCode === null) await request('shutdown'); }
    finally {
      child.kill(); lines.close();
      for (const entry of pending.values()) clearTimeout(entry.timer);
      server.closeAllConnections();
      await new Promise(resolve => server.close(resolve));
      await rm(root, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    }
  };
  try {
    const { executeTool, ...init } = options;
    const ready = await request('init', { ...init, sessionFile });
    return { request, ready, requests, userId, parentId, offBranch, image, sessionFile, close, historyBeforeCompaction };
  } catch (error) { await close(); throw error; }
}

test('host state exposes archived current-branch messages and a real Pi compaction boundary', async () => {
  const f = await fixture({compact:true});
  try {
    assert.ok(f.ready.historyMessages.some(m=>m.role==='user' && m.timestamp===1));
    assert.ok(!f.ready.messages.some(m=>m.role==='user' && m.timestamp===1));
    const marker = f.ready.historyMessages.find(m=>m.role==='compactionSummary');
    assert.equal(marker.summary,'Synthetic summary boundary');
    assert.equal(marker.tokensBefore,131000);
    assert.ok(Number.isFinite(marker.timestamp));
    assert.equal(marker.timestamp, f.ready.messages.find(m=>m.role==='compactionSummary').timestamp);
    assert.ok(!f.ready.historyMessages.some(m=>m.timestamp===4));
    assert.equal(f.requests.length,0);
    await f.request('prompt',{text:'Continue after compaction'});
    const sent=JSON.stringify(f.requests[0]);
    const hint='Earlier turns are preserved; use session_history for exact details.';
    assert.equal(sent.split(hint).length-1,1);
    const stored=await readFile(f.sessionFile,'utf8');
    assert.ok(!stored.includes(hint));
    const state=await f.request('state');
    assert.equal(state.messages.find(message=>message.role==='compactionSummary').summary,marker.summary);
  } finally { await f.close(); }
});

for (const options of [{}, { leafUser: true }, { leafUser: true, rootUser: true }]) {
  test('host resend navigates to parent then creates sibling, retaining abandoned history ' + JSON.stringify(options), async () => {
    const f = await fixture(options);
    try {
      assert.deepEqual(f.ready.historyMessages, f.historyBeforeCompaction);
      assert.ok(!f.ready.historyMessages.some(m => m.timestamp === 4));
      const entry = f.ready.entries.find(e => e.id === f.userId);
      assert.deepEqual(entry, { id: f.userId, parentId: f.parentId, role: 'user', timestamp: 3 });
      assert.ok(!('message' in entry));
      const menu = f.ready.userMessages.find(e => e.entryId === f.userId);
      assert.deepEqual(Object.keys(menu).sort(), ['entryId', 'text']);
      assert.ok(f.ready.userMessages.some(e => e.entryId === f.offBranch));
      assert.ok(!f.ready.entries.some(e => e.id === f.offBranch));
      await assert.rejects(f.request('navigate', { entryId: f.offBranch }), /current branch/);
      await assert.rejects(f.request('navigate', { entryId: 'missing' }), /current branch/);
      const navigated = await f.request('navigate', { entryId: f.userId });
      assert.equal(navigated.editorText, 'original question');
      assert.deepEqual(navigated.editorImages, [f.image]);
      assert.ok(!navigated.messages.some(m => m.timestamp === 3 || m.timestamp === 5));
      assert.equal(f.requests.length, 0);
      const result = await f.request('prompt', { text: 'edited question', images: [f.image] });
      assert.equal(f.requests.length, 1);
      const edited = result.entries.find(e => e.role === 'user' && e.id !== f.userId && e.timestamp !== 1);
      assert.ok(edited);
      assert.ok(!result.entries.some(e => e.id === f.userId));
      assert.match(JSON.stringify(f.requests[0]), /edited question/);
      assert.doesNotMatch(JSON.stringify(f.requests[0]), /original question|old answer|off-branch question/);
      const history = await readFile(f.sessionFile, 'utf8');
      assert.match(history, /original question/);
      assert.match(history, /edited question/);
      // Pi may insert system/tool-loadout records before the fresh prompt.
      // Follow those records: the fork still starts at the selected user's parent.
      const entries = new Map(history.trim().split('\n').map(line => JSON.parse(line))
        .filter(entry => entry.id).map(entry => [entry.id, entry]));
      let cursor = edited.parentId;
      while (cursor !== f.parentId) {
        assert.notEqual(cursor, f.userId);
        assert.notEqual(cursor, f.offBranch);
        assert.notEqual(cursor, null, 'new branch must descend from the original parent');
        const entry = entries.get(cursor);
        assert.ok(entry);
        if (entry.type === 'message') assert.equal(entry.message.role, 'system', JSON.stringify(entry));
        cursor = entry.parentId;
      }
    } finally { await f.close(); }
  });
}

test('extension-cancelled navigation leaves original branch intact', async () => {
  const f = await fixture({ cancel: true });
  try {
    const result = await f.request('navigate', { entryId: f.userId });
    assert.equal(result.cancelled, true);
    assert.ok(result.entries.some(e => e.id === f.userId));
    assert.equal(f.requests.length, 0);
  } finally { await f.close(); }
});
