import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { domainTools } from '../lib/domain-tools.mjs';
import { studioTools, studioToolMapFor } from '../lib/session.mjs';

test('Dart production catalog and Pi schemas expose exactly the same actual tools', async () => {
  const source = await readFile(new URL('../../../lib/core/nai_agent/tool_catalog.dart', import.meta.url), 'utf8');
  const dartNames = [...source.split('];')[0].matchAll(/'([a-z_]+)'/g)].map(match => match[1]);
  const actual = ['read', 'write', 'edit', 'bash',
    ...studioTools(() => {}, ['ask_user', ...domainTools.map(tool => tool.name)]).map(tool => tool.name)];
  assert.deepEqual(actual.toSorted(), dartNames.toSorted());
  const map = source.slice(source.indexOf("'''Tool map:") + 3, source.lastIndexOf("'''"));
  assert.equal(studioToolMapFor(['ask_user', ...domainTools.map(tool => tool.name)]), map);
});

test('only registered domain tools enter the Pi tool list and routing map', async () => {
  const calls = [];
  const tools = studioTools(async (...args) => { calls.push(args); return { content: [{ type: 'text', text: 'saved' }] }; },
    ['snapshot', 'not_implemented']);
  assert.deepEqual(tools.map(tool => tool.name), ['studio_context', 'image_read', 'prompt_update', 'snapshot']);
  assert.ok(studioToolMapFor(['snapshot']).includes('Generation configuration: snapshot'));
  assert.ok(!studioToolMapFor(['snapshot']).includes('wiki_query'));
  assert.ok(!studioToolMapFor(['not_implemented']).includes('not_implemented'));
  const signal = new AbortController().signal;
  await tools.at(-1).execute('call-1', { action: 'save', name: 'config' }, signal);
  assert.deepEqual(calls[0], ['snapshot', 'call-1', { action: 'save', name: 'config' }, signal]);
});
