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

test('gallery batch schema exposes bounded IDs and per-image versions with batching guidance', async () => {
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
  assert.ok(tool.description.length <= 600);
  assert.match(tool.description, /ONE Studio confirmation per call/);
  assert.match(tool.description, /references\/gallery\.md/);
  const guide = await readFile(new URL('../skills/nai-studio/references/gallery.md',import.meta.url),'utf8');
  assert.match(guide, /one batch `move_file` per target folder/);
  assert.match(guide, /1\.\.20 `image_ids`/);
  // Exact-form/unique-ID/per-ID completeness validation belongs to Dart.
});

test('block schema accepts presets and occurrence-local content, rejects invalid values', async () => {
  const tool = domainTools.find(tool=>tool.name==='block_manage');
  for (const action of ['create','update']) {
    assert.equal(Value.Check(tool.parameters, {action,changes:{title:'preset',content:'text',generationSettings:{qualityPreset:'light',ucPreset:7,qualityCustomBlockId:'q',ucCustomBlockId:'u'}}}), true);
    for (const generationSettings of [{qualityPreset:'invalid'},{ucPreset:4},{ucPreset:1.5},{qualityCustomBlockId:5}]) {
      assert.equal(Value.Check(tool.parameters,{action,changes:{generationSettings}}),false);
    }
  }
  const guide = await readFile(new URL('../skills/nai-studio/references/blocks.md',import.meta.url),'utf8');
  assert.match(guide, /that occurrence into a temporary block, leaving the library entry intact/);
  assert.equal(Value.Check(tool.parameters,{action:'instance_update',marker:'x',occurrence:1,instance:{content:'new',negative_content:'UC'}}),true);
  assert.equal(Value.Check(tool.parameters,{action:'instance_update',instance:{content:42}}),false);
  assert.equal(Value.Check(tool.parameters,{action:'instance_update',occurrence:-1,instance:{content:'new'}}),false);
  const reading = {source:'brown cloak',zh:'棕色斗篷'};
  assert.equal(Value.Check(tool.parameters,{action:'instance_create',kind:'temporary',instance:{title:'服装',content:'brown cloak',translations:[reading]}}),true);
  assert.equal(Value.Check(tool.parameters,{action:'instance_update',instance:{translations:[],negative_translations:[reading]}}),true);
  for (const translations of ['reading',Array(65).fill(reading),[{...reading,language_code:'invalid'}]]) {
    assert.equal(Value.Check(tool.parameters,{action:'instance_update',instance:{translations}}),false);
  }
});

test('inline block schema stays one flat object with enums; per-action rules live in Dart', async () => {
  const tool = domainTools.find(tool=>tool.name==='block_manage');
  assert.equal(tool.parameters.type, 'object');
  assert.ok(!('anyOf' in tool.parameters) && !('allOf' in tool.parameters));
  assert.ok(tool.parameters.properties.action.enum.includes('instance_convert'));
  const segment = {kind:'temporary',anchor:{text:'中文😀',mode:'replace'},instance:{title:'one-off',color:'#80112233',icon:'star'}};
  assert.equal(Value.Check(tool.parameters,{action:'instance_convert',segments:[segment]}),true);
  assert.equal(Value.Check(tool.parameters,{action:'instance_create',kind:'translation',instance:{enabled:false},translation:{source:'rain',zh:'雨',language_code:'ja'}}),true);
  assert.equal(Value.Check(tool.parameters,{action:'instance_create',kind:'translation',translation:{source:'rain',zh:'雨',marks:[]}}),false);
  for (const segments of [[],Array(65).fill(segment),[{...segment,anchor:{text:'',mode:'replace'}}]]) {
    assert.equal(Value.Check(tool.parameters,{action:'instance_convert',segments}),false);
  }
  for (const instance of [{title:'x'.repeat(41)},{color:'blue'},{icon:7}]) {
    assert.equal(Value.Check(tool.parameters,{action:'instance_create',kind:'temporary',instance}),false);
  }
  assert.equal(Value.Check(tool.parameters,{action:'instance_create',translation:{language_code:'xx'}}),false);
  assert.equal(Value.Check(tool.parameters,{action:'instance_create',anchor:{text:'x',mode:'unknown'}}),false);
  assert.equal(Value.Check(tool.parameters,{action:'merge'}),false);
  for (const phrase of [/expected_library_version/, /references\/blocks\.md/]) assert.match(tool.description,phrase);
  assert.ok(tool.description.length <= 600);
  const promptDescription = studioTools(()=>{}).find(t=>t.name==='prompt_update').description;
  assert.match(promptDescription,/pill_conflict/);
  assert.match(promptDescription,/field_version/);
  assert.ok(promptDescription.length <= 400);
  const skill = await readFile(new URL('../skills/nai-studio/references/blocks.md',import.meta.url),'utf8');
  for (const phrase of [/1\.\.64 segments/, /`source` \(sent to generation\)/, /compose/]) assert.match(skill,phrase);
  assert.match(skill, /## Merging and splitting/);
  assert.match(skill, /Missing `needsReview` means false; missing `languageCode` means `zh`/);
  const icons = await readFile(new URL('../../../lib/presentation/widgets/prompt/blocks/prompt_block_icons.dart',import.meta.url),'utf8');
  for (const [,key] of icons.split('};')[0].matchAll(/'([a-z_]+)': Icons\./g)) assert.ok(skill.includes('`'+key+'`'),key);
});

test('every domain tool description stays compact and schemas avoid anyOf enums', () => {
  for (const tool of domainTools) {
    assert.ok(tool.description.length <= 600, tool.name);
    const json = JSON.stringify(tool.parameters);
    assert.ok(!/"anyOf":\[\{"type":"string","const"/.test(json), tool.name);
  }
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
