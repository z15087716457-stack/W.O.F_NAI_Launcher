import test from 'node:test';
import assert from 'node:assert/strict';
import { createSessionHistoryExtension } from '../lib/extensions/session-history.mjs';

const message = (id,role,content) => ({id,type:'message',timestamp:'2026-10-31T00:00:00Z',message:{role,content}});
function fixture() {
  const branch = [
    message('u1','user','Find exact old wording'),
    message('a1','assistant',[
      {type:'thinking',thinking:'hidden deliberation'},
      {type:'text',text:'school_uniform 12345 secret-token'},
      {type:'toolCall',id:'t1',name:'tag_query',arguments:{query:'school_uniform',data:{seed:123},bytes:512}},
    ]),
    message('t1','toolResult',[
      {type:'text',text:'old result school_uniform'},
      {type:'image',data:'A'.repeat(2000),mimeType:'image/png'},
    ]),
    message('u2','user','Keep this turn'),
    {id:'compact',type:'compaction',firstKeptEntryId:'u2',summary:'A short summary'},
    message('a2','assistant',[{type:'text',text:'New reply'}]),
  ];
  let tool;
  createSessionHistoryExtension(value => value.replaceAll('secret-token','[redacted]'))
    .factory({registerTool(value){tool=value;}});
  const ctx = {sessionManager:{getBranch(){return branch;}}};
  return {branch,tool,async run(args,signal) {
    const result = await tool.execute('call',args,signal,undefined,ctx);
    return JSON.parse(result.content[0].text);
  }};
}

test('history is deferred, reads current branch, and outlines compacted turns', async () => {
  const f=fixture();
  assert.equal(f.tool.exposure,'deferred');
  const all=await f.run({action:'outline'});
  assert.deepEqual(all.items.map(row=>[row.turn,row.entry_id,row.compacted,row.tool_calls]),
    [[1,'u1',true,1],[2,'u2',false,0]]);
  const before=await f.run({action:'outline',before_compaction_only:true,limit:1});
  assert.equal(before.items.length,1);
  assert.equal(before.items[0].user,'Find exact old wording');
  await assert.rejects(f.run({action:'read',entry_id:'other-branch'}),/current branch/);
});

test('search and reads retain exact text, redact secrets, omit thinking and binary', async () => {
  const f=fixture();
  const hits=await f.run({action:'search',query:'school_uniform',limit:1});
  assert.equal(hits.items[0].entry_id,'a1');
  assert.equal(hits.next_offset,1);
  const next=await f.run({action:'search',query:'school_uniform',offset:1});
  assert.equal(next.items[0].entry_id,'t1');
  const turn=await f.run({action:'read_turn',turn:1,max_chars:20000});
  assert.match(turn.text,/school_uniform 12345 \[redacted\]/);
  assert.match(turn.text,/image omitted/);
  assert.match(turn.text,/"seed":123/);
  assert.match(turn.text,/"bytes":512/);
  assert.doesNotMatch(turn.text,/hidden deliberation|secret-token|AAAAA/);
  const page=await f.run({action:'read',entry_id:'a1',max_chars:20});
  const rest=await f.run({action:'read',entry_id:'a1',offset:page.next_offset,max_chars:20000});
  const full=await f.run({action:'read',entry_id:'a1',max_chars:20000});
  assert.equal(page.text+rest.text,full.text);
  await assert.rejects(f.run({action:'search',query:' '}),/nonempty/);
});

test('history follows branch changes and cancellation without retaining an archive', async () => {
  const f=fixture();
  f.branch.splice(1);
  assert.equal((await f.run({action:'outline'})).items.length,1);
  await assert.rejects(f.run({action:'read',entry_id:'a1'}),/current branch/);
  const controller=new AbortController();controller.abort();
  await assert.rejects(f.run({action:'outline'},controller.signal),{name:'AbortError'});
});

test('redaction precedes pagination and serialized results remain bounded', async () => {
  const f=fixture();
  f.branch[1].message.content=[{type:'text',text:'prefix secret-token suffix '+ '"\\\n'.repeat(15000)}];
  const first=await f.run({action:'read',entry_id:'a1',max_chars:24});
  const next=await f.run({action:'read',entry_id:'a1',offset:first.next_offset,max_chars:20000});
  assert.doesNotMatch(first.text+next.text,/secret-token|secret-to|ret-token/);
  assert.ok(JSON.stringify(next).length <= 20000);
  assert.ok(next.next_offset > first.next_offset);
});
