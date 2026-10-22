import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { domainTools } from '../lib/domain-tools.mjs';
import { studioTools } from '../lib/session.mjs';
import { Value } from 'typebox/value';

test('Dart production catalog and Pi schemas expose exactly the same actual tools', async () => {
  const source = await readFile(new URL('../../../lib/core/nai_agent/tool_catalog.dart', import.meta.url), 'utf8');
  const dartNames = [...source.split('];')[0].matchAll(/'([a-z_]+)'/g)].map(match => match[1]);
  const actual = ['read', 'write', 'edit', 'bash',
    ...studioTools(() => {}, ['ask_user', ...domainTools.map(tool => tool.name)]).map(tool => tool.name)];
  assert.deepEqual(actual.toSorted(), dartNames.toSorted());
});

test('studio_search schema exposes only supported sources and bounded inputs', () => {
  const tool = domainTools.find(tool => tool.name === 'studio_search');
  assert.ok(tool);
  const schema = tool.parameters;
  for (const source of ['gallery', 'blocks', 'wiki', 'tags']) {
    assert.equal(Value.Check(schema, { source, query: 'a semantic description', limit: 20 }), true);
  }
  assert.equal(Value.Check(schema, { source: 'gallery', image_id: 'selected', mode: 'visual' }), true);
  assert.equal(Value.Check(schema, { source: 'gallery', path: 'attachments/chat/a.png', date_start: '2026-10-01' }), true);
  for (const params of [
    { source: 'other', query: 'rain' },
    { source: 'tags', query: 'x'.repeat(501) },
    { source: 'tags', query: 'rain', limit: 0 },
    { source: 'tags', query: 'rain', limit: 51 },
    { source: 'tags', query: 'rain', limit: 1.5 },
    { source: 'gallery', query: 'rain', mode: 'unknown' },
    { source: 'gallery', query: 'rain', date_start: '2026/10/01' },
  ]) assert.equal(Value.Check(schema, params), false, JSON.stringify(params));
  // Cross-field constraints (query/image, gallery-only options and real calendar
  // dates) are additionally enforced by the production Dart binding.
});

test('gallery batch schema exposes bounded IDs and per-image versions with batching guidance', () => {
  const tool = domainTools.find(tool => tool.name === 'gallery_manage');
  const schema = tool.parameters;
  assert.equal(schema.properties.image_ids.maxItems, 50);
  assert.equal(schema.properties.folder_ids.maxItems, 50);
  const image_ids = Array.from({length:50}, (_,i) => 'gallery:'+(i+1));
  assert.equal(Value.Check(schema, {action:'move_file', image_ids,
    expected_image_versions:Object.fromEntries(image_ids.map(id=>[id,'version'])), target_folder:'/library/target'}), true);
  assert.equal(Value.Check(schema, {action:'folder_delete_empty', folder_ids:['a','b'], expected_folder_version:'v'}), true);
  for (const image_ids of [[], Array.from({length:51}, (_,i)=>'gallery:'+i)]) {
    assert.equal(Value.Check(schema, {action:'move_file',image_ids}), false);
  }
  assert.equal(Value.Check(schema, {action:'move_file',expected_image_versions:{'gallery:1':42}}), false);
  assert.equal(Value.Check(schema, {action:'folder_delete_empty',folder_ids:[]}), false);
  assert.equal(Value.Check(schema, {action:'folder_delete_empty',folder_ids:Array(51).fill('a')}), false);
  assert.ok(tool.description.length <= 1300);
  assert.match(tool.description, /ONE Studio confirmation per call/);
  assert.match(tool.description, /never loop single-image calls/);
  assert.match(tool.description, /only 1\.\.20 image_ids/);
  // Exact-form/unique-ID/per-ID completeness validation belongs to Dart.
});

test('only registered domain tools enter the Pi tool list', async () => {
  const calls = [];
  const tools = studioTools(async (...args) => { calls.push(args); return { content: [{ type: 'text', text: 'saved' }] }; },
    ['snapshot', 'not_implemented']);
  assert.deepEqual(tools.map(tool => tool.name), ['studio_context', 'image_read', 'prompt_update', 'snapshot']);
  const signal = new AbortController().signal;
  await tools.at(-1).execute('call-1', { action: 'save', name: 'config' }, signal);
  assert.deepEqual(calls[0], ['snapshot', 'call-1', { action: 'save', name: 'config' }, signal]);
});
