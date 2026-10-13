import { listenFetchTestServer } from './fixture-http.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { createServer } from 'node:http';
import { createStudioSession } from '../lib/session.mjs';
import { validateStudioMcp } from '../lib/mcp.mjs';

async function fixture(code, options = {}) {
  await mkdir('.runs', { recursive: true });
  const root = resolve(await mkdtemp('.runs/mcp-'));
  const requests = [], calls = [];
  const server = createServer(async (req, res) => {
    const chunks = []; for await (const c of req) chunks.push(c);
    const body = JSON.parse(Buffer.concat(chunks)); requests.push(body);
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    const sse = delta => res.write('data: ' + JSON.stringify({ id: 'test', object: 'chat.completion.chunk',
      choices: [{ index: 0, delta, finish_reason: null }] }) + '\n\n');
    sse({ role: 'assistant' });
    if (requests.length === 1) sse({ tool_calls: [{ index: 0, id: 'script', type: 'function',
      function: options.firstTool ?? { name: 'codemode', arguments: JSON.stringify({ code }) } }] });
    else sse({ content: 'Completed.' });
    res.write('data: ' + JSON.stringify({ id: 'test', object: 'chat.completion.chunk',
      choices: [{ index: 0, delta: {}, finish_reason: requests.length === 1 ? 'tool_calls' : 'stop' }] }) + '\n\n');
    res.end('data: [DONE]\n\n');
  });
  await listenFetchTestServer(server);
  const input = {
    cwd: join(root, 'workspace'), agentDir: join(root, 'agent'), systemPrompt: 'NAI Agent.',
    config: { providerId: 'synthetic', modelId: 'synthetic', tools: true,
      protocol: 'openaiChatCompletions', baseUrl: 'http://127.0.0.1:' + server.address().port, apiKey: 'model-secret' },
    extraToolNames: ['ask_user', 'snapshot'],
    executeTool: async (name, id, params, signal) => {
      if (name === '_nai_extension_ui' && params.kind === 'tool_approval')
        return { content: [{ type: 'text', text: JSON.stringify({ status: 'answered', value: params.options[0] }) }] };
      calls.push({ name, id, params });
      return options.execute ? options.execute(name, id, params, signal)
        : { content: [{ type: 'text', text: name }], details: { name, params } };
    }, ...options.session,
  };
  const created = await createStudioSession(input);
  return { ...created, requests, calls, root, input, closeRuntime: created.close,
    result: () => created.session.messages.find(m => m.role === 'toolResult'),
    async close() { await created.close(); server.closeAllConnections(); await new Promise(r => server.close(r)); },
  };
}

test('only seven entry tools declared; official discovery and dependent MCP calls work in one sandbox', async () => {
  const f = await fixture(`
    text(await searchTools('patch draft', {namespace:'mcp__nai_studio'}));
    text(await describeTool('mcp__nai_studio__prompt_update'));
    const state = await tools.studio_context({scope:'draft'});
    const change = await tools.mcp__nai_studio__prompt_update({changes:{prompt:'new'},expected:{prompt:'v1'}});
    text(change.structuredContent);
    store('done', true);
  `);
  try {
    const events = [];
    f.session.subscribe(event => events.push(event));
    await f.session.prompt('perform test');
    assert.deepEqual(f.requests[0].tools.map(t => t.function.name).sort(),
      ['read','write','edit','bash','studio_context','ask_user','codemode'].sort());
    assert.ok(!JSON.stringify(f.requests[0].tools).includes('mcp__nai_studio__prompt_update'));
    assert.deepEqual(f.calls.map(c => c.name), ['studio_context', 'prompt_update']);
    assert.match(JSON.stringify(f.result()), /mcp__nai_studio__prompt_update/);
    assert.match(JSON.stringify(f.result()), /Script completed/);
    assert.ok(f.calls[1].id.includes('/'));
    assert.match(await readFile(f.session.sessionFile, 'utf8'), /codemode-store/);
    assert.equal(f.requests.length, 2);
    assert.equal(events.find(event => event.type === 'agent_settled').aborted, false);
    const end = events.find(event => event.type === 'tool_execution_end' && event.toolName === 'codemode');
    assert.ok(Number.isFinite(end.durationMs) && end.durationMs >= 0);
    assert.equal(f.result().durationMs, end.durationMs);
  } finally { await f.close(); }
});

test('model-only questions cannot be nested and MCP errors remain structured', async () => {
  const f = await fixture(`
    text(await searchTools('ask_user'));
    try { await tools.ask_user({questions:[]}); } catch(e) { text('blocked:' + e.message); }
    const result = await tools.mcp__nai_studio__prompt_update({changes:{},expected:{}});
    text({isError:result.isError, error:result.structuredContent.error});
  `, { execute: async () => { throw new Error('version conflict'); } });
  try {
    await f.session.prompt('perform test');
    assert.deepEqual(f.calls.map(c => c.name), ['prompt_update']);
    assert.match(JSON.stringify(f.result()), /blocked/);
    assert.match(JSON.stringify(f.result()), /version conflict/);
    assert.match(JSON.stringify(f.result()), /isError/);
  } finally { await f.close(); }
});

test('CodeMode retains native image artifacts in official Pi history without dumping nested results to the model', async () => {
  const f = await fixture('const result=await tools.mcp__nai_studio__snapshot({action:"list"}); text(result.isError);', {
    execute: async () => ({ content:[{type:'text',text:'native-large-result'}],
      details:{ok:true,artifacts:[{type:'image',path:'outputs/image.png'}]} }),
  });
  try {
    await f.session.prompt('perform test');
    assert.equal(f.result().details.artifacts[0].path,'outputs/image.png');
    assert.ok(!(f.result().content.map(block=>block.text??'').join('')).includes('native-large-result'));
    const entries=(await readFile(f.session.sessionFile,'utf8')).trim().split('\n').map(line=>JSON.parse(line));
    const message=entries.find(entry=>entry.message?.role==='toolResult').message;
    assert.equal(message.details.artifacts[0].path,'outputs/image.png');
  } finally {await f.close();}
});

test('direct and hidden exposures follow Pi loadouts, and disabled servers never start', async () => {
  const f = await fixture('text(await searchTools("snapshot"));', { session: { mcp: {
    builtinExposure: 'direct', mcpServers: { disabled: { command: 'does-not-exist', enabled: false } },
  } } });
  try {
    await f.session.prompt('perform test');
    assert.ok(f.requests[0].tools.some(t => t.function.name === 'mcp__nai_studio__snapshot'));
    assert.ok(!f.session.getAllTools().some(t => t.name.startsWith('mcp__disabled')));
  } finally { await f.close(); }
  const hidden = await fixture('text(await searchTools("snapshot"));',
    { session: { mcp: { builtinExposure: 'hidden' } } });
  try {
    await hidden.session.prompt('perform test');
    assert.ok(!hidden.session.getCallableToolNames().some(t => t.startsWith('mcp__nai_studio')));
  } finally { await hidden.close(); }
});

test('invalid and legacy SSE configurations fail before starting any server', () => {
  for (const mcpServers of [
    { 'nai-studio': { command:'node' } },
    { 'a-b': {command:'node'}, 'a_b': {command:'node'} },
    { a: {type:'sse', url:'http://localhost'} },
    { a: {url:'http://localhost', auth:{provider:'studio'}} },
  ]) assert.throws(() => validateStudioMcp({mcpServers}));
});

test('Stop propagates through CodeMode and MCP to the original Studio cancellation token', async () => {
  let entered, cancelled;
  const started = new Promise(resolve => { entered = resolve; });
  const stopped = new Promise(resolve => { cancelled = resolve; });
  const f = await fixture('text(await tools.mcp__nai_studio__snapshot({action:"list"}));', {
    execute: async (_, __, ___, signal) => {
      entered();
      return new Promise((resolve, reject) => {
        const stop = () => { cancelled(); reject(new Error('cancelled')); };
        if (signal.aborted) stop(); else signal.addEventListener('abort', stop, {once:true});
      });
    },
  });
  try {
    const events = [];
    f.session.subscribe(event => events.push(event));
    const run = f.session.prompt('perform test');
    await started;
    await f.session.abort();
    await Promise.race([stopped, new Promise((_,reject) => {
      const timer=setTimeout(()=>reject(new Error('Studio cancellation was not delivered')),2000); timer.unref();
    })]);
    await run;
    assert.equal(f.requests.length, 1);
    assert.equal(f.session.isStreaming, false);
    assert.equal(events.find(event => event.type === 'agent_settled').aborted, true);
  } finally { await f.close(); }
});

test('Pi 1.1 separates CodeMode text items and console output in the next model request', async () => {
  const f = await fixture('text("first"); text({step:2}); console.log("console-line"); text("third");');
  try {
    await f.session.prompt('perform test');
    const output = f.result().content.map(block => block.text ?? '').join('\n');
    assert.match(output, /==> text 1\/3 <==/);
    assert.match(output, /==> text 2\/3 <==/);
    assert.match(output, /==> text 3\/3 <==/);
    assert.match(output, /<console_output>/);
    assert.match(output, /console-line/);
    assert.match(JSON.stringify(f.requests[1]), /==> text 2\/3 <==/);
    const description = f.requests[0].tools.find(tool => tool.function.name === 'codemode').function.description;
    assert.match(description, /async/i);
  } finally { await f.close(); }
});

test('deferred MCP tools loaded by official search remain active after resuming the same Pi session', async () => {
  const f = await fixture('', {
    firstTool: {name:'tool_search', arguments:JSON.stringify({query:'snapshot',limit:1})},
    session: {mcp:{builtinExposure:'deferred'}},
  });
  let resumed;
  try {
    f.session.setActiveToolsByName([...f.session.getActiveToolNames(),'tool_search']);
    await f.session.prompt('perform test');
    assert.ok(f.requests[1].tools.some(tool => tool.function.name === 'mcp__nai_studio__snapshot'));
    const sessionFile = f.session.sessionFile;
    await f.closeRuntime();
    resumed = await createStudioSession({...f.input, sessionFile});
    // Pi reconnects MCP lazily. The native status command waits for discovery,
    // just like host mcp_command; restoring must never make a model request.
    await resumed.session.prompt('/mcp');
    assert.equal(f.requests.length, 2);
    assert.ok(resumed.session.getActiveToolNames().includes('mcp__nai_studio__snapshot'));
    await resumed.session.prompt('continue');
    assert.ok(f.requests[2].tools.some(tool => tool.function.name === 'mcp__nai_studio__snapshot'));
    await resumed.close();
    for (const mcp of [{builtinEnabled:false},{builtinExposure:'hidden'}]) {
      const restricted = await createStudioSession({...f.input, sessionFile, mcp});
      try {
        await restricted.session.prompt('/mcp');
        assert.ok(!restricted.session.getActiveToolNames().some(name => name.startsWith('mcp__nai_studio__')));
        assert.ok(!restricted.session.getCallableToolNames().some(name => name.startsWith('mcp__nai_studio__')));
      } finally { await restricted.close(); }
    }
  } finally {
    await resumed?.close();
    await f.close();
  }
});

test('shutdown cancels an official MCP OAuth login stalled during local metadata discovery', async () => {
  let metadataEntered;
  const entered = new Promise(resolve => { metadataEntered = resolve; });
  const server = createServer((req,res) => {
    if (req.url === '/metadata') { metadataEntered(); return; }
    if (req.url.startsWith('/.well-known/oauth-protected-resource')) {
      res.writeHead(200, {'content-type':'application/json'});
      res.end(JSON.stringify({resource:base+'/mcp',authorization_servers:[base]}));
      return;
    }
    res.writeHead(401, {'www-authenticate':'Bearer resource_metadata="'+base+'/.well-known/oauth-protected-resource"'});
    res.end();
  });
  await listenFetchTestServer(server);
  const base = 'http://127.0.0.1:'+server.address().port;
  const f = await fixture('', {session:{mcp:{mcpServers:{oauth:{url:base+'/mcp',
    oauth:{clientId:'synthetic-client',authServerMetadataUrl:base+'/metadata'}}}}}});
  try {
    const login = f.session.prompt('/mcp login oauth');
    await Promise.race([entered, new Promise((_,reject) => {
      const timer=setTimeout(()=>reject(new Error('Local OAuth metadata was not requested')),3000);timer.unref();
    })]);
    await f.closeRuntime();
    await login;
    assert.equal(f.requests.length,0);
  } finally {
    await f.close();
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});

test('official stdio MCP transport, redaction and close reach a real synthetic child', async () => {
  await mkdir('.runs', {recursive:true});
  const root=resolve(await mkdtemp('.runs/mcp-child-')), path=join(root,'server.mjs');
  await writeFile(path, `import {createInterface} from 'node:readline';
    createInterface({input:process.stdin}).on('line', line=>{
      const m=JSON.parse(line); if(m.id===undefined)return;
      const result=m.method==='initialize'?{protocolVersion:m.params.protocolVersion,capabilities:{tools:{}},serverInfo:{name:'fixture',version:'1'}}
        :m.method==='tools/list'?{tools:[{name:'echo',description:'echo',inputSchema:{type:'object',properties:{value:{type:'string'}}}}]}
        :{content:[{type:'text',text:process.env.MCP_TOKEN}],structuredContent:{value:m.params?.arguments?.value}};
      process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m.id,result})+'\\n');
    });`);
  const f = await fixture(`const result=await tools.mcp__echo__echo({value:'hello'}); text(result);`, {
    session:{mcp:{mcpServers:{echo:{command:process.execPath,args:[path],env:{MCP_TOKEN:'server-secret'}}}}},
  });
  try {
    await f.session.prompt('perform test');
    assert.match(JSON.stringify(f.result()), /hello/);
    assert.match(JSON.stringify(f.result()), /redacted/);
    assert.ok(!(await readFile(f.session.sessionFile, 'utf8')).includes('server-secret'));
  } finally { await f.close(); }
});

test('official Streamable HTTP uses private headers and exposes a server only on demand', async () => {
  const received = [];
  const server = createServer(async (req,res) => {
    if(req.method!=='POST'){ res.writeHead(405); res.end(); return; }
    const chunks=[]; for await(const c of req)chunks.push(c);
    const m=JSON.parse(Buffer.concat(chunks)); received.push({m,auth:req.headers.authorization});
    if(m.id===undefined){res.writeHead(202);res.end();return;}
    const result=m.method==='initialize'?{protocolVersion:m.params.protocolVersion,capabilities:{tools:{}},serverInfo:{name:'http',version:'1'}}
      :m.method==='tools/list'?{tools:[{name:'echo',description:'echo',inputSchema:{type:'object',properties:{}}}]}
      :{content:[{type:'text',text:'http-secret'}],structuredContent:{ok:true}};
    res.writeHead(200,{'content-type':'application/json'});res.end(JSON.stringify({jsonrpc:'2.0',id:m.id,result}));
  });
  await listenFetchTestServer(server);
  const f=await fixture(`text(await tools.mcp__http__echo({}));`,{session:{mcp:{mcpServers:{http:{
    url:'http://127.0.0.1:'+server.address().port+'/mcp',headers:{Authorization:'Bearer http-secret'},
  }}}}});
  try {
    await f.session.prompt('perform test');
    assert.ok(received.some(({m,auth})=>m.method==='tools/call'&&auth==='Bearer http-secret'));
    assert.match(JSON.stringify(f.result()), /redacted/);
    assert.ok(!JSON.stringify(f.requests[0]).includes('http-secret'));
    assert.ok(!(await readFile(f.session.sessionFile,'utf8')).includes('http-secret'));
  } finally {await f.close();server.closeAllConnections();await new Promise(r=>server.close(r));}
});
