import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Value } from 'typebox/value';
import { domainTools, promptSetIcons } from '../lib/domain-tools.mjs';
import { createNaiInteractionExtension } from '../lib/extensions/interaction.mjs';
import { createNaiPermissions } from '../lib/extensions/permissions.mjs';

const content = {kind:'Storyboard', kind_icon:'film', title:'Rain', unit:'scene', ordered:true,
  items:[{card_id:'rain',icon:'rain',title:'Rain',characters:['silver hair, running']},{card_id:'cafe',icon:'coffee',title:'Cafe'}]};

test('prompt_set schema bounds and exact Dart icon catalog (action requirements are enforced in Dart)', async () => {
  const tool = domainTools.find(t => t.name === 'prompt_set');
  assert.ok(tool.description.length <= 600);
  assert.ok(Value.Check(tool.parameters, {action:'create', ...content,
    items:content.items.map(item => ({...item, icon:'heart'}))}));
  const schema = tool.parameters;
  assert.ok(Value.Check(schema,{action:'create',...content}));
  assert.ok(Value.Check(schema,{action:'read',set_id:'012345abcdef'}));
  assert.ok(Value.Check(schema,{action:'update',set_id:'012345abcdef',expected_revision:1,...content}));
  const single = {...content.items[0], generation:{seed:0, cfg_scale:5.5, width:832}};
  assert.ok(Value.Check(schema,{action:'create',...content,items:[single]}));
  assert.ok(Value.Check(schema,{action:'update',set_id:'012345abcdef',expected_revision:1,card:single}));
  for (const bad of [
    {action:'create',...content,items:[]},
    {action:'create',...content,items:[{...single,generation:{seed:'0'}}]},
    {action:'create',...content,items:Array(25).fill(content.items[0])},
    {action:'create',...content,kind_icon:'alien'},
    {action:'create',...content,items:[{icon:'alien',title:'x'},content.items[1]]},
    {action:'create',...content,title:'x'.repeat(61)},
    {action:'create',...content,shared:{main:'x'.repeat(2001)}},
    {action:'read',set_id:'../outside'},
  ]) assert.equal(Value.Check(schema,bad),false,JSON.stringify(bad));
  const source = await readFile(new URL('../../../lib/core/nai_agent/prompt_set_icons.dart',import.meta.url),'utf8');
  const catalog = await readFile(new URL('../../../lib/core/utils/prompt_icon_catalog.dart',import.meta.url),'utf8');
  const names = raw => [...raw.matchAll(/'([a-z0-9_]+)'/g)].map(m=>m[1]);
  const legacy = names(source.match(/const agentPromptSetGlyphNames = \[([\s\S]*?)\];/)[1]);
  const extra = names(catalog.match(/const additionalPromptIconNames = <String>\[([\s\S]*?)\];/)[1]);
  assert.deepEqual([...legacy, ...extra],promptSetIcons);
  assert.equal(new Set(promptSetIcons).size,promptSetIcons.length);
  const glyphs = await readFile(new URL('../../../lib/presentation/ui/agent/agent_glyphs.dart',import.meta.url),'utf8');
  for (const name of legacy) assert.match(glyphs,new RegExp("'"+name+"' => AgentGlyphs\\."));
  assert.match(glyphs, /UiExtraIcons\.paths\[name\] \?\? AgentGlyphs\.book/);
  for (const icon of extra) {
    assert.ok(Value.Check(schema,{action:'create',...content,kind_icon:icon,items:[{card_id:'one',icon,title:'x'},content.items[1]]}), icon);
  }
});

test('prompt_set accepts optional per-character positions and rejects invalid shapes/ranges', () => {
  const schema = domainTools.find(t => t.name === 'prompt_set').parameters;
  for (const action of ['create', 'update']) {
    const base = {action, set_id:'012345abcdef', expected_revision:1, ...content};
    for (const positions of [[], [null], [{x:0,y:1}], [{x:0.25,y:0.75}]]) {
      const value = {...base,
        items:[{...content.items[0], positions}, content.items[1]]};
      assert.equal(Value.Check(schema,value),true,JSON.stringify(value));
    }
    for (const positions of [null, {}, [0], [[0,1]], [{x:0}], [{x:0,y:1,z:0}],
      [{x:-0.01,y:0}], [{x:0,y:1.01}], [{x:'0',y:0}], [{x:NaN,y:0}], [{x:0,y:Infinity}], Array(33).fill(null)]) {
      assert.equal(Value.Check(schema,{...base,items:[{...content.items[0],positions},content.items[1]]}),false);
    }
  }
});

test('prompt_set create/update projections are compact, read has no projection', () => {
  const handlers = new Map();
  createNaiInteractionExtension([]).factory({on:(name,handler)=>handlers.set(name,handler),registerTool:()=>{}});
  for (const action of ['create','update','read']) {
    const native={ok:true,set_id:'012345abcdef',revision:2,count:8,changed_items:[4],title:'Rain',...content,images:{0:[{path:'private'}]}};
    handlers.get('tool_result')({toolName:'mcp__nai_studio__prompt_set',toolCallId:action,parentToolCallId:'code',input:{action},structuredContent:{content:[],structuredContent:native}});
    const output=handlers.get('tool_result')({toolName:'codemode',toolCallId:'code',details:{}});
    if(action==='read') { assert.equal(output,undefined); continue; }
    assert.deepEqual(output.details.studio_results,[{tool:'mcp__nai_studio__prompt_set',tool_call_id:action,
      ok:true,set_id:'012345abcdef',revision:2,changed_items:[4],count:8,title:'Rain'}]);
  }
});

test('prompt_set is a non-destructive edit in auto and a read-only read in readonly', async () => {
  for (const name of ['prompt_set','mcp__nai_studio__prompt_set']) {
    for (const mode of ['auto','readonly']) {
      const handlers=new Map();
      createNaiPermissions({cwd:process.cwd(),mode}).extension.factory({on:(n,h)=>handlers.set(n,h)});
      for (const action of ['create','update','read']) {
        const result=await handlers.get('tool_call')({toolName:name,input:{action}}, {hasUI:false});
        assert.equal(result?.block, mode==='readonly' && action!=='read' ? true : undefined);
      }
    }
  }
});
