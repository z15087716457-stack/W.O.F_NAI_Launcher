import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { listenFetchTestServer } from './fixture-http.mjs';

// Exercise the actual JSONL host and MCP -> Dart-shaped executor round trip.
test('translation host seeds exact history, exposes only block tools and persists no session', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'translation-host-'));
  const requests = [], calls = [];
  const server = createServer(async (request, response) => {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    const body = JSON.parse(Buffer.concat(chunks));
    requests.push(body);
    const turn = requests.length;
    response.writeHead(200, { 'content-type': 'text/event-stream', connection: 'close' });
    const send = (delta, finish_reason = null) => response.write('data: ' + JSON.stringify({
      id: 'fixture', object: 'chat.completion.chunk', model: 'test-model',
      choices: [{ index: 0, delta, finish_reason }],
    }) + '\n\n');
    const tools = body.tools ?? [];
    const read = tools.find(tool => tool.function.name.endsWith('translation_blocks_read'))?.function.name;
    const edit = tools.find(tool => tool.function.name.endsWith('translation_blocks_edit'))?.function.name;
    send({ role: 'assistant' });
    if (turn <= 2) {
      send({ tool_calls: [{ index: 0, id: 'call_' + turn, type: 'function', function: {
        name: turn === 1 ? read : edit,
        arguments: JSON.stringify(turn === 1 ? {} : { expected_version: 'v1', operations: [{
          scope: 'main', op: 'retranslate', marker: '\ue000', translation: 'new reading',
        }] }),
      } }] });
      send({}, 'tool_calls');
    } else { send({ content: 'Adjusted.' }); send({}, 'stop'); }
    response.end('data: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
  const host = spawn(process.execPath, [new URL('../host.mjs', import.meta.url).pathname.replace(/^\/(\w:)/, '$1')], { stdio: ['pipe', 'pipe', 'pipe'] });
  let sessionId, sequence = 0;
  const pending = new Map();
  const send = message => host.stdin.write(JSON.stringify({ protocol: 1, workspaceId: 'translation-test', sessionId, ...message }) + '\n');
  const request = message => new Promise((resolve, reject) => {
    const id = String(++sequence);
    pending.set(id, { resolve, reject }); send({ ...message, id });
  });
  const lines = createInterface({ input: host.stdout });
  lines.on('line', line => {
    const message = JSON.parse(line);
    if (message.type === 'ready') sessionId = message.sessionId;
    if (message.type === 'request_permit') send({ type: 'permit_result', requestId: message.requestId });
    if (message.type === 'tool_request') {
      calls.push(message);
      send({ type: 'tool_result', toolCallId: message.toolCallId,
        result: { content: [{ type: 'text', text: '{"version":"v1","blocks":[]}' }], details: { version: 'v1', blocks: [] } } });
    }
    if (['ready', 'response', 'error'].includes(message.type)) {
      const item = pending.get(message.id); pending.delete(message.id);
      if (message.type === 'error') item?.reject(new Error(message.message)); else item?.resolve(message);
    }
  });
  try {
    const ready = await request({ type: 'init', sessionKind: 'translation', cwd: join(directory, 'workspace'), agentDir: join(directory, 'agent'),
      systemPrompt: 'Adjust translation only. Use tools.', seedSystemPrompt: 'Original translation system.',
      seedMessages: [{ role: 'user', content: '{"original_request":true}' }, { role: 'assistant', content: '{"original_reply":true}' }],
      // Malicious general tool configuration must be ignored by this loadout.
      extraToolNames: ['generation_run'], extensionPaths: ['/does-not-exist'],
      config: { providerId: 'fake', modelId: 'test-model', protocol: 'openaiChatCompletions',
        baseUrl: 'http://127.0.0.1:' + server.address().port, apiKey: 'fake', tools: true, maxTokens: 1024 },
    });
    assert.equal(ready.sessionFile, undefined);
    assert.equal(ready.messages.filter(message => message.role === 'user').length, 1);
    await request({ type: 'prompt', text: 'Adjust the current blocks.' });
    assert.equal(requests.length, 3, JSON.stringify(requests));
    const first = requests[0];
    assert.equal(first.messages[0].role, 'system');
    assert.equal(first.messages[0].content, 'Original translation system.');
    const userIndex = first.messages.findIndex(message => message.role === 'user');
    assert.equal(first.messages[userIndex].content, '{"original_request":true}');
    assert.equal(first.messages[userIndex + 1].role, 'assistant');
    assert.equal(first.messages[userIndex + 1].content, '{"original_reply":true}');
    assert.ok(JSON.stringify(first.messages).includes('Original translation system.'));
    assert.deepEqual(first.tools.map(tool => tool.function.name).sort(), [
      'mcp__nai_studio__translation_blocks_edit', 'mcp__nai_studio__translation_blocks_read',
    ]);
    assert.deepEqual(calls.map(call => call.name), ['translation_blocks_read', 'translation_blocks_edit']);
    assert.equal(calls[1].params.expected_version, 'v1');
    await request({ type: 'shutdown' });
  } finally {
    host.kill(); lines.close(); server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await rm(directory, { recursive: true, force: true });
  }
});
