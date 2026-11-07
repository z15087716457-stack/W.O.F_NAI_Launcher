import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { studioChatGpt } from '../lib/model.mjs';
import { createStudioSession } from '../lib/session.mjs';

const accessToken = 'synthetic-subscription-token';
const modelId = 'gpt-6.1-sol';

test('subscription catalog uses the account token and Pi model capabilities', async t => {
  const fetch = t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, 'https://api.openai.com/v1/models');
    assert.equal(options.headers.Authorization, 'Bearer ' + accessToken);
    assert.equal(options.redirect, 'error');
    return Response.json({ models: [
      { slug: modelId, display_name: 'Account model', visibility: 'list' },
      { slug: 'gpt-6-astra', visibility: 'hidden' },
      { slug: 'unrecognized-model', visibility: 'list' },
    ] });
  });
  const result = await studioChatGpt({ action: 'models', accessToken });
  assert.equal(fetch.mock.callCount(), 1);
  assert.deepEqual(result.models.map(({ id, name }) => ({ id, name })),
    [{ id: modelId, name: 'Account model' }]);
  assert.ok(result.models[0].contextWindow > 0);
  assert.ok(result.models[0].efforts.includes('high'));
});

test('Agent subscription inference uses Pi Responses and runs Studio tools', async t => {
  const root = await mkdtemp(join(tmpdir(), 'studio-chatgpt-'));
  const requests = [], tools = [];
  let acquired = 0, released = 0;
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(options.redirect, 'error');
    const body = JSON.parse(options.body);
    requests.push({ url: String(url), authorization: new Headers(options.headers).get('authorization'), body });
    if (requests.length === 3) return Response.json({ error: { message: accessToken } }, { status: 400 });
    const tool = requests.length === 1;
    const item = tool
      ? { type: 'function_call', id: 'fc_test', call_id: 'call_test',
        name: 'studio_context', arguments: '{}', status: 'completed' }
      : { type: 'message', id: 'msg_test', role: 'assistant', status: 'completed',
        content: [{ type: 'output_text', text: 'done', annotations: [] }] };
    const sse = (type, fields) => `event: ${type}\ndata: ${JSON.stringify({ type, ...fields })}\n\n`;
    return new Response([
      sse('response.created', { response: { id: 'resp_test', status: 'in_progress', output: [] } }),
      sse('response.output_item.added', { output_index: 0, item: tool
        ? { ...item, arguments: '' } : { ...item, content: [] } }),
      tool
        ? sse('response.function_call_arguments.delta', { item_id: item.id, output_index: 0, delta: '{}' })
        : sse('response.content_part.added', { item_id: item.id, output_index: 0, content_index: 0,
          part: { type: 'output_text', text: '', annotations: [] } }) +
          sse('response.output_text.delta', { item_id: item.id, output_index: 0, content_index: 0, delta: 'done' }),
      sse('response.output_item.done', { output_index: 0, item }),
      sse('response.completed', { response: { id: 'resp_test', status: 'completed', output: [item],
        usage: { input_tokens: 12, output_tokens: 6, total_tokens: 18 } } }),
    ].join(''), { headers: { 'content-type': 'text/event-stream' } });
  });
  let created;
  try {
    created = await createStudioSession({
      cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'Synthetic test.',
      config: { chatGptSubscription: true, providerId: 'openai-chatgpt', modelId,
        protocol: 'openaiResponses', vision: true, tools: true, nextSuggestion: false,
        cacheWarming: 'off', baseUrl: 'https://not-openai.invalid', temperature: 0.3,
        headers: { authorization: 'synthetic-override' },
        payloadParameters: { max_output_tokens: 500, metadata: { test: true } } },
      acquireRequest: async () => {
        acquired++;
        return { accessToken, release: () => { released++; } };
      },
      executeTool: async name => {
        tools.push(name);
        return { content: [{ type: 'text', text: 'synthetic tool result' }] };
      },
    });
    await created.session.prompt('Call the local tool.');
    assert.equal(requests.length, 2, JSON.stringify(created.session.messages.at(-1)));
    assert.deepEqual(tools, ['studio_context']);
    assert.ok(requests[1].body.input.some(item => item.type === 'function_call_output' &&
      JSON.stringify(item.output).includes('synthetic tool result')));
    for (const { url, authorization, body } of requests) {
      assert.equal(url, 'https://api.openai.com/v1/responses');
      assert.equal(authorization, 'Bearer ' + accessToken);
      assert.equal(body.model, modelId);
      assert.equal(body.stream, true);
      assert.equal(body.store, false);
      assert.equal(body.max_output_tokens, undefined);
      assert.equal(body.metadata, undefined);
      assert.equal(body.temperature, undefined);
      assert.equal(body.tools, undefined);
      assert.ok(body.input.some(item => item.type === 'additional_tools' &&
        item.tools.some(tool => tool.name === 'studio_context')));
    }
    assert.equal(created.session.messages.at(-1).content[0].text, 'done');
    await created.session.prompt('Simulate an error.');
    assert.equal(acquired, released);
    const error = created.session.messages.at(-1);
    assert.equal(error.stopReason, 'error');
    assert.ok(error.errorMessage.includes('[redacted]'));
    assert.ok(!JSON.stringify(created.manager.getBranch()).includes(accessToken));
  } finally {
    await created?.close();
    await rm(root, { recursive: true, force: true, maxRetries: 10, retryDelay: 100 });
  }
});
