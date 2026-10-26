import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { listenFetchTestServer } from './fixture-http.mjs';

for (const withImage of [false, true]) test(`queue events consume steer then followUp, image=${withImage}`, async () => {
  const root = await mkdtemp(join(tmpdir(), 'host-queue-'));
  const responses = [];
  const server = createServer(async (req, res) => {
    for await (const _ of req) { /* drain */ }
    responses.push(res);
  });
  await listenFetchTestServer(server);
  const child = spawn(process.execPath, [fileURLToPath(new URL('../host.mjs', import.meta.url))]);
  const lines = createInterface({ input: child.stdout });
  const events = [], pending = new Map();
  let sessionId, seq = 0, diagnostic = '';
  child.stderr.on('data', data => { diagnostic += data; });
  const send = fields => child.stdin.write(JSON.stringify({protocol:1, workspaceId:'fixture', sessionId, ...fields})+'\n');
  lines.on('line', line => {
    const event = JSON.parse(line); events.push(event);
    if (event.type === 'ready') sessionId = event.sessionId;
    if (event.type === 'request_permit') send({type:'permit_result',requestId:event.requestId});
    if (['ready','response','error'].includes(event.type) && pending.has(event.id)) {
      const p = pending.get(event.id); pending.delete(event.id);
      event.type === 'error' ? p.reject(new Error(event.message)) : p.resolve(event);
    }
  });
  const request = (type, fields={}) => new Promise((resolve,reject) => {
    const id = String(++seq); pending.set(id,{resolve,reject}); send({id,type,...fields});
  });
  const wait = async predicate => {
    for (let i=0;i<1000;i++) { if (predicate()) return; await new Promise(r=>setTimeout(r,10)); }
    throw new Error('Timed out: '+diagnostic);
  };
  const finish = index => responses[index].end('data: '+JSON.stringify({id:'test',object:'chat.completion.chunk',model:'test',
    choices:[{index:0,delta:{role:'assistant',content:'done'},finish_reason:'stop'}]})+'\n\ndata: [DONE]\n\n');
  try {
    await request('init',{cwd:join(root,'workspace'),agentDir:join(root,'agent'),
      sessionDirectory:join(root,'sessions'),systemPrompt:'Synthetic queue test.',
      config:{providerId:'test',modelId:'test',protocol:'openaiChatCompletions',
        baseUrl:'http://127.0.0.1:'+server.address().port,apiKey:'synthetic',tools:true,vision:true}});
    const run = request('prompt',{text:'start',queueId:'first'});
    await wait(()=>responses.length===1);
    const images = withImage ? [{type:'image',mimeType:'image/png',data:'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII='}] : undefined;
    await request('prompt',{text:'same text\nattachment manifest',queueId:'steer',behavior:'steer',images});
    await request('prompt',{text:'same text\nattachment manifest',queueId:'follow',behavior:'followUp',images});
    finish(0);
    await wait(()=>responses.length===2);
    assert.ok(events.some(e=>e.type==='queue' && e.consumedQueueIds.includes('steer') && e.queue.some(q=>q.queueId==='follow')));
    finish(1);
    await wait(()=>responses.length===3);
    assert.ok(events.some(e=>e.type==='queue' && e.consumedQueueIds.includes('follow') && e.queue.length===0));
    finish(2); await run;
    await request('shutdown');
  } finally {
    child.kill(); lines.close(); server.closeAllConnections();
    await new Promise(resolve=>server.close(resolve));
    await rm(root,{recursive:true,force:true,maxRetries:20,retryDelay:100});
  }
});
