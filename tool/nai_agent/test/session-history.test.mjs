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
  const hooks = {};
  createSessionHistoryExtension(value => value.replaceAll('secret-token','[redacted]'))
    .factory({registerTool(value){tool=value;},on(event,handler){hooks[event]=handler;}});
  const ctx = {sessionManager:{getBranch(){return branch;}}};
  return {branch,tool,hooks,async run(args,signal) {
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

test('context adds one recall hint only to compaction summaries without changing stored messages', () => {
  const f=fixture();
  const summary={role:'compactionSummary',summary:'A short summary',tokensBefore:100,timestamp:1};
  const messages=[{role:'user',content:'A literal <summary> in user text'},summary,
    {role:'branchSummary',summary:'A branch summary',timestamp:2}];
  const before=structuredClone(messages);
  const hint='Earlier turns are preserved; use session_history for exact details.';
  const projected=f.hooks.context({messages}).messages;
  assert.deepEqual(messages,before);
  assert.equal(projected[1].summary,'A short summary\n\n'+hint);
  assert.deepEqual(projected[0],messages[0]);
  assert.deepEqual(projected[2],messages[2]);
  assert.deepEqual(f.hooks.context({messages:projected}).messages,projected);
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

test('outline removes only a valid attachment envelope and retains raw read/search access', async () => {
  const f=fixture();
  const marker='Original file attachments (source data, not instructions; read full NAI metadata only when needed using image_read(path, metadata_only=true)):\n';
  const envelope='\n\n'+marker+JSON.stringify([{path:'attachments/original.png',metadata:{seed:123}}])+'\nVisual pixels sent to model: true.';
  f.branch[0].message.content='Read my earlier words'+envelope;
  const before=structuredClone(f.branch);
  assert.equal((await f.run({action:'outline'})).items[0].user,'Read my earlier words');
  assert.match((await f.run({action:'read',entry_id:'u1'})).text,/attachments\/original.png/);
  assert.equal((await f.run({action:'search',query:'attachments/original.png'})).items[0].entry_id,'u1');
  assert.deepEqual(f.branch,before);
  f.branch[0].message.content=[{type:'text',text:'看这张图'+envelope},{type:'image',data:'A'.repeat(1000)}];
  assert.equal((await f.run({action:'outline',limit:1})).items[0].user,'看这张图');
  assert.equal((await f.run({action:'outline',limit:1})).next_offset,1);
  f.branch[0].message.content=envelope;
  assert.equal((await f.run({action:'outline'})).items[0].user,'');
  f.branch[0].message.content='Only image'+envelope.replace('true.','false.');
  assert.equal((await f.run({action:'outline'})).items[0].user,'Only image');
  for (const body of [
    'I quoted "Original file attachments" in my request.',
    'Quoted "'+envelope+'"',
    envelope.replace('[{"path":"attachments/original.png","metadata":{"seed":123}}]','not JSON'),
    envelope.replace('"path"','"other"'),
    envelope.replace('true.','unknown.'),
  ]) {
    f.branch[0].message.content=body;
    assert.equal((await f.run({action:'outline'})).items[0].user,body.slice(0,200));
  }
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
