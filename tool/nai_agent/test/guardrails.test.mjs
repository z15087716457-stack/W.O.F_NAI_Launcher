import { listenFetchTestServer } from './fixture-http.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdir, mkdtemp, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { createStudioSession } from '../lib/session.mjs';

async function setup(handler, config = {}) {
  const requests = [];
  const server = createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    await handler(req, res);
  });
  await listenFetchTestServer(server);
  await mkdir('.runs', { recursive: true });
  const root = await mkdtemp('.runs/guards-');
  const created = await createStudioSession({
    cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'NAI Agent.',
    config: { providerId: 'test', modelId: 'test-model', protocol: 'openaiChatCompletions',
      baseUrl: 'http://127.0.0.1:' + server.address().port,
      apiKey: 'synthetic-secret', tools: true, timeoutSeconds: 1, ...config },
    executeTool: async () => ({ content: [] }),
  });
  return { ...created, requests, close: async () => {
    created.session.dispose(); server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  } };
}

test('provider timeout aborts an actual pending HTTP stream', async () => {
  const fixture = await setup(async (req, res) => {
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    res.flushHeaders();
    await new Promise(resolve => res.on('close', resolve));
  });
  try {
    await fixture.session.prompt('read state');
    assert.equal(fixture.requests.length, 1);
    assert.equal(fixture.session.messages.at(-1).stopReason, 'aborted');
    assert.equal(fixture.session.isStreaming, false);
  } finally { await fixture.close(); }
});

test('provider errors that echo credentials are redacted before official session persistence', async () => {
  const fixture = await setup(async (req, res) => {
    res.writeHead(401, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: { message: 'Rejected synthetic-secret' } }));
  }, { timeoutSeconds: 5 });
  try {
    await fixture.session.prompt('read state');
    assert.equal(fixture.session.messages.at(-1).stopReason, 'error');
    assert.match(fixture.session.messages.at(-1).errorMessage, /\[redacted\]/);
    assert.ok(!(await readFile(fixture.session.sessionFile, 'utf8')).includes('synthetic-secret'));
  } finally { await fixture.close(); }
});

test('text-only model rejects pixels before any HTTP request', async () => {
  const fixture = await setup(async (req, res) => res.end(), { vision: false });
  try {
    await fixture.session.prompt('describe', {
      images: [{ type: 'image', mimeType: 'image/png', data: 'synthetic' }],
    });
    assert.equal(fixture.requests.length, 0);
    assert.match(fixture.session.messages.at(-1).errorMessage, /Image input is not enabled/);
  } finally { await fixture.close(); }
});
