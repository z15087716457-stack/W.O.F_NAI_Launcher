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

test('a buffered response can exceed the legacy timeout before headers, complete, and send again', async () => {
  const fixture = await setup(async (_req, res) => {
    await new Promise(resolve => setTimeout(resolve, 400));
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    res.end('data: ' + JSON.stringify({ choices: [{ delta: { content: 'Finished' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
  }, { timeoutSeconds: .1 });
  try {
    await fixture.session.prompt('read state');
    assert.equal(fixture.requests.length, 1, JSON.stringify(fixture.session.messages.at(-1)));
    assert.equal(fixture.session.messages.at(-1).stopReason, 'stop');
    assert.ok(fixture.session.messages.at(-1).content.some(part => part.text === 'Finished'));
    assert.equal(fixture.session.isStreaming, false);
    await fixture.session.prompt('continue');
    assert.equal(fixture.session.messages.at(-1).stopReason, 'stop');
    assert.equal(fixture.requests.length, 2);
  } finally { await fixture.close(); }
});

test('streaming response progress completes normally', async () => {
  const fixture = await setup(async (_req, res) => {
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    for (let i = 0; i < 7; i++) {
      res.write('data: ' + JSON.stringify({ choices: [{ delta: { reasoning_content: 'thinking ' }, finish_reason: null }] }) + '\n\n');
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    res.end('data: ' + JSON.stringify({ choices: [{ delta: { content: 'Finished' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
  }, { timeoutSeconds: 1 });
  try {
    await fixture.session.prompt('long but active');
    const reply = fixture.session.messages.at(-1);
    assert.equal(reply.stopReason, 'stop', reply.errorMessage);
    assert.ok(reply.content.some(part => part.text === 'Finished'));
  } finally { await fixture.close(); }
});

test('a stalled partial response waits for manual Stop, retains text, and allows another send', async () => {
  const { promise: entered, resolve: enter } = Promise.withResolvers();
  const fixture = await setup(async (_req, res) => {
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    if (fixture.requests.length > 1) {
      res.end('data: ' + JSON.stringify({ choices: [{ delta: { content: 'Recovered' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
      return;
    }
    res.write('data: ' + JSON.stringify({ choices: [{ delta: { content: 'Partial' }, finish_reason: null }] }) + '\n\n');
    enter();
    await new Promise(resolve => res.on('close', resolve));
  }, { timeoutSeconds: .1 });
  try {
    const running = fixture.session.prompt('stall until manual stop');
    await entered;
    await new Promise(resolve => setTimeout(resolve, 400));
    assert.equal(fixture.session.isStreaming, true);
    await fixture.session.abort(); await running;
    const stopped = fixture.session.messages.at(-1);
    assert.equal(stopped.stopReason, 'aborted');
    assert.ok(stopped.content.some(part => part.text === 'Partial'));
    await fixture.session.prompt('continue after stop');
    assert.equal(fixture.session.messages.at(-1).stopReason, 'stop');
    assert.equal(fixture.requests.length, 2);
  } finally { await fixture.session.abort(); await fixture.close(); }
});

for (const reasoningOnly of [false, true]) {
  test(`empty final response becomes an explicit error (thinking only=${reasoningOnly})`, async () => {
    const fixture = await setup(async (_req, res) => {
      res.writeHead(200, { 'content-type': 'text/event-stream' });
      res.end('data: ' + JSON.stringify({ choices: [{ delta: reasoningOnly
        ? { reasoning_content: 'No final answer' } : { content: ' ' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
    });
    try {
      await fixture.session.prompt('empty');
      assert.equal(fixture.session.messages.at(-1).stopReason, 'error');
      assert.match(fixture.session.messages.at(-1).errorMessage, /STUDIO_EMPTY_RESPONSE/);
    } finally { await fixture.close(); }
  });
}

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
