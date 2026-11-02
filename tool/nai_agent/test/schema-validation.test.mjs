import test from 'node:test';
import assert from 'node:assert/strict';
import { validateToolArguments } from '@earendil-works/pi-ai';
import { domainTools } from '../lib/domain-tools.mjs';
import { studioTools } from '../lib/session.mjs';
import { hostFixture, finishReply } from './fixture-host.mjs';

const related = domainTools.find(tool => tool.name === 'tag_related');
const validate = (tool, args) => validateToolArguments(tool, { id: 'schema-test', name: tool.name, arguments: args });

test('Pi coerces Studio TypeBox and plain MCP schemas consistently without mutating tool-call history', () => {
  for (const parameters of [related.parameters, JSON.parse(JSON.stringify(related.parameters))]) {
    const args = { tags: 'long_hair', exclude: '1girl', categories: 'general', limit: '3.5' };
    const before = structuredClone(args);
    assert.deepEqual(validate({ ...related, parameters }, args), {
      tags: ['long_hair'], exclude: ['1girl'], categories: ['general'], limit: 3,
    });
    assert.deepEqual(args, before);
  }
});

test('Pi still rejects missing tags, unknown enums, oversized limits and undeclared fields', () => {
  for (const args of [{}, { tags: [] }, { tags: ['hair'], categories: ['unknown'] },
    { tags: ['hair'], limit: 51 }, { tags: ['hair'], unexpected: true }]) {
    assert.throws(() => validate(related, args), /Validation failed/);
  }
});

test('prompt patches retain raw values, characters and string field versions under pi-schema', () => {
  const tool = studioTools(() => {}).find(tool => tool.name === 'prompt_update');
  const args = { changes: { prompt: '1.5, null, false', seed: -1, quality_preset: false,
    characters: [{ prompt: 'girl', enabled: true }], optional_value: null },
    expected: { prompt: '7', seed: '8', characters: '9' } };
  const parsed = validate(tool, args);
  assert.deepEqual(parsed, args);
  assert.notEqual(parsed, args);
  assert.notEqual(parsed.changes, args.changes);
});

test('the actual host returns invalid tool arguments to the model before calling Studio', async () => {
  let requests = 0;
  const f = await hostFixture({ config: { nextSuggestion: false, cacheWarming: 'off' },
    respond(response) {
      if (++requests > 1) { finishReply(response); return; }
      response.end('data: ' + JSON.stringify({ id: 'schema-test', choices: [{ index: 0,
        delta: { role: 'assistant', tool_calls: [{ index: 0, id: 'invalid-context', type: 'function',
          function: { name: 'studio_context', arguments: '{"scope":"invalid"}' } }] },
        finish_reason: 'tool_calls' }] }) + '\n\ndata: [DONE]\n\n');
    } });
  try {
    await f.request('prompt', { text: 'Synthetic validation check' });
    assert.equal(requests, 2);
    assert.ok(!f.events.some(event => event.type === 'tool_request'));
    assert.ok(f.requests[1].messages.some(message => message.role === 'tool'
      && JSON.stringify(message.content).includes('Validation failed')
      && JSON.stringify(message.content).includes('scope')));
  } finally { await f.close(); }
});
