import { listenFetchTestServer } from './fixture-http.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { createStudioSession } from '../lib/session.mjs';
import { endpointRoot, requestPatch, redactor, publicModel } from '../lib/model.mjs';

export async function httpFixture(protocol, handler) {
  const requests = [];
  const server = createServer(async (request, response) => {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    const body = JSON.parse(Buffer.concat(chunks));
    requests.push({ path: request.url, headers: request.headers, body });
    response.writeHead(200, { 'content-type': 'text/event-stream', connection: 'close' });
    if (handler) await handler(requests.length, response, body);
    else respond(protocol, response, requests.length === 1);
    response.end();
  });
  await listenFetchTestServer(server);
  return {
    requests, baseUrl: 'http://127.0.0.1:' + server.address().port,
    close: async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); },
  };
}
const sse = (res, data, event) => res.write((event ? 'event: ' + event + '\n' : '') + 'data: ' + JSON.stringify(data) + '\n\n');
export function respond(protocol, res, tool, name = 'studio_context', args = { scope: 'summary' }) {
  if (protocol === 'openaiChatCompletions' || protocol === 'ollamaChatCompletions') {
    const chunk = (delta, finish_reason = null) => sse(res, {
      id: 'test-request', object: 'chat.completion.chunk', model: 'test-model',
      choices: [{ index: 0, delta, finish_reason }],
    });
    chunk({ role: 'assistant' });
    chunk(tool ? { tool_calls: [{ index: 0, id: 'call_context', type: 'function',
      function: { name, arguments: JSON.stringify(args) } }] } : { content: '已读取上下文。' });
    chunk({}, tool ? 'tool_calls' : 'stop');
    sse(res, { choices: [], usage: { prompt_tokens: 12, completion_tokens: 6, total_tokens: 18 } });
    res.write('data: [DONE]\n\n');
  } else if (protocol === 'anthropicMessages') {
    const emit = (type, fields) => sse(res, { type, ...fields }, type);
    emit('message_start', { message: { id: 'msg_test', type: 'message', role: 'assistant',
      model: 'test-model', content: [], usage: { input_tokens: 12, output_tokens: 0 } } });
    emit('content_block_start', { index: 0, content_block: tool
      ? { type: 'tool_use', id: 'call_context', name, input: {} }
      : { type: 'text', text: '' } });
    emit('content_block_delta', { index: 0, delta: tool
      ? { type: 'input_json_delta', partial_json: JSON.stringify(args) }
      : { type: 'text_delta', text: '已读取上下文。' } });
    emit('content_block_stop', { index: 0 });
    emit('message_delta', { delta: { stop_reason: tool ? 'tool_use' : 'end_turn' }, usage: { output_tokens: 6 } });
    emit('message_stop', {});
  } else if (protocol === 'geminiGenerateContent') {
    sse(res, { candidates: [{ content: { role: 'model', parts: tool
      ? [{ functionCall: { name, args } }] : [{ text: '已读取上下文。' }] },
      finishReason: 'STOP' }], usageMetadata: { promptTokenCount: 12, candidatesTokenCount: 6, totalTokenCount: 18 } });
  } else if (protocol === 'openaiResponses') {
    const emit = (type, fields) => sse(res, { type, ...fields }, type);
    const item = tool ? { type: 'function_call', id: 'fc_test', call_id: 'call_context',
      name, arguments: JSON.stringify(args), status: 'completed' }
      : { type: 'message', id: 'msg_test', role: 'assistant', status: 'completed',
        content: [{ type: 'output_text', text: '已读取上下文。', annotations: [] }] };
    emit('response.created', { response: { id: 'resp_test', status: 'in_progress', output: [] } });
    emit('response.output_item.added', { output_index: 0, item: tool ? { ...item, arguments: '' } : { ...item, content: [] } });
    if (tool) emit('response.function_call_arguments.delta', { item_id: 'fc_test', output_index: 0, delta: JSON.stringify(args) });
    else {
      emit('response.content_part.added', { item_id: 'msg_test', output_index: 0, content_index: 0,
        part: { type: 'output_text', text: '', annotations: [] } });
      emit('response.output_text.delta', { item_id: 'msg_test', output_index: 0, content_index: 0, delta: '已读取上下文。' });
    }
    emit('response.output_item.done', { output_index: 0, item });
    emit('response.completed', { response: { id: 'resp_test', status: 'completed', output: [item],
      usage: { input_tokens: 12, output_tokens: 6, total_tokens: 18 } } });
  }
}

export async function sessionFixture(protocol, server, options = {}) {
  await mkdir('.runs', { recursive: true });
  const root = await mkdtemp('.runs/protocol-');
  return createStudioSession({
    cwd: join(root, 'workspace'), agentDir: join(root, 'agent'),
    systemPrompt: '你是 NAI Agent。按需读取 Studio 状态。',
    config: { providerId: 'test', modelId: 'test-model', protocol, baseUrl: server.baseUrl,
      apiKey: 'synthetic-key', headers: { 'x-studio-test': 'synthetic-header' },
      temperature: 0.2, tools: true, vision: true, maxTokens: 4096,
      payloadParameters: protocol === 'geminiGenerateContent'
        ? { generationConfig: { topP: 0.6 } } : { top_p: 0.6 },
      ...options.config },
    executeTool: options.executeTool ?? (async (name, id, params) => ({
      content: [{ type: 'text', text: JSON.stringify({ name, id, params, selected_image: 'synthetic' }) }],
      details: { synthetic: true },
    })),
  });
}

// 侧栏「最高」：Studio 把服务商勾选的档位写进请求体；Pi 内部档位虽被收成 high，
// 发给服务商的仍是所选档位（2026-10-20 曾误判为“最高 = 高”）。
test('selected max reasoning effort reaches the DeepSeek request body', async () => {
  const server = await httpFixture('openaiChatCompletions');
  const created = await sessionFixture('openaiChatCompletions',
    { ...server, baseUrl: server.baseUrl + '/deepseek.com' }, { config: {
      reasoning: true, thinkingLevel: 'xhigh',
      payloadParameters: { thinking: { type: 'enabled' }, reasoning_effort: 'max' } } });
  try {
    await created.session.prompt('hi');
    const body = server.requests[0].body;
    assert.deepEqual(body.thinking, { type: 'enabled' });
    assert.equal(body.reasoning_effort, 'max');
  } finally { await created.close(); await server.close(); }
});

for (const protocol of ['openaiChatCompletions', 'openaiResponses', 'anthropicMessages',
  'geminiGenerateContent', 'ollamaChatCompletions']) {
  for (const custom of [false, true]) {
    test(protocol + ': new Studio config omits sampling unless supplied in custom body=' + custom, async () => {
      const server = await httpFixture(protocol, (_, res) => respond(protocol, res, false));
      const body = protocol === 'geminiGenerateContent'
        ? {generationConfig:{temperature:0.25,topP:0.75}} : {temperature:0.25,top_p:0.75};
      const created = await sessionFixture(protocol, server, {config:{
        temperature:undefined, allowsSampling:undefined, payloadParameters:{}, body:custom ? body : {},
      }});
      try {
        await created.session.prompt('test sampling policy');
        assert.equal(created.session.messages.at(-1).stopReason,'stop');
        const payload = server.requests[0].body;
        const sampling = protocol === 'geminiGenerateContent' ? payload.generationConfig ?? {} : payload;
        assert.equal(sampling.temperature, custom ? 0.25 : undefined);
        assert.equal(sampling[protocol === 'geminiGenerateContent' ? 'topP' : 'top_p'], custom ? 0.75 : undefined);
      } finally { await created.close(); await server.close(); }
    });
  }
  test(protocol + ': official CodeMode → Studio MCP → follow-up request', async () => {
    const server = await httpFixture(protocol, (turn, res) => respond(protocol, res, turn === 1,
      'codemode', { code: 'const result = await tools.mcp__nai_studio__prompt_update({changes:{},expected:{}}); text(result.structuredContent);' }));
    const created = await sessionFixture(protocol, server, {
      executeTool: async name => ({content:[{type:'text',text:name}],details:{native:name}}),
    });
    try {
      await created.session.prompt('perform synthetic test');
      assert.equal(server.requests.length, 2);
      assert.ok(JSON.stringify(server.requests[1].body).includes('prompt_update'));
      assert.ok(JSON.stringify(server.requests[1].body).includes('Script completed'));
      assert.equal(created.session.messages.at(-1).stopReason, 'stop');
    } finally { await created.close(); await server.close(); }
  });
  test(protocol + ': official stream → real tool → follow-up request', async () => {
    const server = await httpFixture(protocol);
    const { session } = await sessionFixture(protocol, server);
    const events = [];
    session.subscribe(event => events.push(event));
    try {
      await session.prompt('请读取当前 Studio 上下文。');
      const last = session.messages.at(-1);
      assert.equal(last.stopReason, 'stop', last.errorMessage);
      assert.match(last.content.map(part => part.text ?? '').join(''), /已读取/);
      assert.equal(server.requests.length, 2);
      assert.ok(events.some(event => event.type === 'message_update'));
      assert.ok(events.some(event => event.type === 'tool_execution_end' && !event.isError), JSON.stringify(session.messages));
      const first = server.requests[0];
      assert.equal(first.headers['x-studio-test'], 'synthetic-header');
      assert.equal(first.body.model ?? (protocol === 'geminiGenerateContent' ? 'test-model' : undefined), 'test-model');
      assert.ok(JSON.stringify(server.requests[1].body).includes('selected_image'));
      assert.ok(JSON.stringify(first.body).includes('studio_context'));
      if (protocol === 'geminiGenerateContent') {
        assert.match(first.path, /\/v1beta\/models\/test-model:streamGenerateContent/);
        assert.equal(first.body.generationConfig.topP, 0.6);
      } else {
        assert.equal(first.body.stream, true);
        assert.equal(first.body.top_p, 0.6);
        assert.equal(first.path.split('?')[0], protocol === 'openaiResponses' ? '/v1/responses'
          : protocol === 'anthropicMessages' ? '/v1/messages' : '/v1/chat/completions');
      }
      const file = await readFile(session.sessionFile, 'utf8');
      assert.ok(!file.includes('synthetic-key'));
      assert.ok(!file.includes('synthetic-header'));
    } finally { session.dispose(); await server.close(); }
  });
}

test('override controls, root mapping, redaction and unknown capabilities stay explicit', () => {
  assert.equal(endpointRoot('http://localhost:123/v1/chat/completions', 'openaiChatCompletions'), 'http://localhost:123/v1');
  assert.equal(endpointRoot('https://test/api/v1/messages', 'anthropicMessages'), 'https://test/api');
  assert.throws(() => requestPatch({ body: { messages: [] } }), /protocol field/);
  assert.throws(() => requestPatch({ allowsSampling: false, body: { generationConfig: { topP: 1 } } }), /disabled/);
  assert.deepEqual(requestPatch({ modelId: 'a', body: { model: 'a', stream: false, foo: 1 } }), { foo: 1 });
  assert.equal(publicModel({}).tools, null);
  assert.equal(publicModel({}).costKnown, false);
  assert.deepEqual(redactor({ apiKey: 'fake-secret' })({ message: 'oops fake-secret' }), { message: 'oops [redacted]' });
});

test('SDK sees Studio conflicts as tool errors, rather than success text', async () => {
  const server = await httpFixture('openaiChatCompletions');
  const { session } = await sessionFixture('openaiChatCompletions', server, {
    executeTool: async () => { throw new Error('draft_conflict: read again'); },
  });
  try {
    await session.prompt('读取状态。');
    assert.equal(session.messages.find(message => message.role === 'toolResult').isError, true);
    assert.ok(JSON.stringify(server.requests[1].body).includes('draft_conflict'), JSON.stringify(session.messages));
  } finally { session.dispose(); await server.close(); }
});
