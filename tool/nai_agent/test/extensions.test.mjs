import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, mkdtemp, writeFile, readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { createServer } from 'node:http';
import { createStudioSession } from '../lib/session.mjs';
import { createStudioExtensionUi } from '../lib/extensions/ui.mjs';

const config = { providerId: 'extension-test', modelId: 'test',
  protocol: 'openaiChatCompletions', baseUrl: 'http://127.0.0.1:1', tools: true };
async function paths() {
  await mkdir('.runs', { recursive: true });
  const root = resolve(await mkdtemp('.runs/extensions-'));
  return { root, cwd: join(root, 'workspace'), agentDir: join(root, 'agent') };
}
const result = value => ({ content: [{ type: 'text', text: JSON.stringify(value) }] });

test('official extension owns context and model-only question; only selected external paths load', async () => {
  const dirs = await paths();
  await mkdir(join(dirs.cwd, '.pi', 'extensions'), { recursive: true });
  await writeFile(join(dirs.cwd, '.pi', 'extensions', 'unselected.ts'), 'throw new Error("must not load");');
  const file = join(dirs.root, 'selected.ts');
  await writeFile(file, `import { Type } from 'typebox';
    export default pi => pi.registerTool({ name:'extension_echo', label:'Echo', description:'Echo',
      parameters: Type.Object({}), execute: async () => ({ content:[{type:'text',text:'echo'}],details:{} }) });`);
  const created = await createStudioSession({ ...dirs, config, systemPrompt: 'NAI.',
    extraToolNames: ['ask_user'], extensionPaths: [file], executeTool: async () => result({}) });
  try {
    const loaded = created.session.resourceLoader.getExtensions().extensions;
    assert.ok(loaded.find(extension => extension.path === '<inline:nai-interaction>')?.tools.has('studio_context'));
    const question = created.session.getAllTools().find(tool => tool.name === 'ask_user');
    assert.equal(question.exposure, 'model-only');
    assert.ok(created.session.getActiveToolNames().includes('extension_echo'));
    assert.ok(created.session.getActiveToolNames().includes('studio_context'));
    assert.equal(loaded.length, 6);
    assert.ok(loaded.some(extension => extension.path === '<inline:nai-permissions>'));
  } finally { await created.close(); }
});

test('external Pi lifecycle, dialogs, command and tool run through the actual SDK', async () => {
  const dirs = await paths(), notices = [], requests = [];
  const server = createServer(async (req, res) => {
    const chunks = []; for await (const chunk of req) chunks.push(chunk);
    requests.push(JSON.parse(Buffer.concat(chunks)));
    const delta = requests.length === 1 ? { role:'assistant', tool_calls:[{ index:0, id:'ext-call', type:'function',
      function:{ name:'extension_dialog', arguments:'{}' } }] } : { role:'assistant',content:'done' };
    res.writeHead(200, {'content-type':'text/event-stream'});
    res.end('data: '+JSON.stringify({id:'test',object:'chat.completion.chunk',model:'test',
      choices:[{index:0,delta,finish_reason:requests.length===1?'tool_calls':'stop'}]})+'\n\ndata: [DONE]\n\n');
  });
  await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
  const file = join(dirs.root, 'dialogs.ts');
  await writeFile(file, `import { Type } from 'typebox'; import { writeFile } from 'node:fs/promises';
    import { join } from 'node:path';
    export default pi => {
      pi.on('session_start', async (_event, ctx) => {
        if (!ctx.hasUI || ctx.mode !== 'rpc') throw new Error('Wrong desktop UI mode');
        await writeFile(join(ctx.cwd,'started.txt'),'started');
      });
      pi.on('session_shutdown', async (_event,ctx) => { await writeFile(join(ctx.cwd,'closed.txt'),'closed'); });
      pi.registerCommand('ext_test', { description:'Test command', handler:async (_args,ctx)=>ctx.ui.notify('command') });
      pi.registerTool({ name:'extension_dialog', label:'Dialog', description:'Dialog test', parameters:Type.Object({}),
        execute: async (_id,_params,signal,_update,ctx) => {
          const values = [await ctx.ui.select('Select',['A','B'],{signal}),
            await ctx.ui.input('Input','hint',{signal}),await ctx.ui.editor('Editor','prefill'),
            await ctx.ui.confirm('Confirm','Question',{signal})];
          const nested = await ctx.executeTool('ask_user',{questions:[{id:'q',question:'bad'}]});
          if (!nested.isError) throw new Error('Nested ask allowed');
          ctx.ui.notify(ctx.ui.theme.fg('success','ready'));
          ctx.ui.setStatus('ext','working'); ctx.ui.setWidget('ext',[ctx.ui.theme.bold('line')]);
          return {content:[{type:'text',text:JSON.stringify(values)}],details:{values}};
        } });
    }`);
  const calls = [], approvals = [];
  const created = await createStudioSession({ ...dirs,
    config: {...config,baseUrl:'http://127.0.0.1:'+server.address().port}, systemPrompt:'NAI.',
    extraToolNames:['ask_user'], extensionPaths:[file], onExtensionUi: notice => notices.push(notice),
    executeTool: async (name,_id,params) => {
      if (params.kind === 'tool_approval') {
        approvals.push(params);
        return result({status:'answered',value:params.options[0]});
      }
      calls.push({name,...params});
      return result({status:'answered',value:{select:'B',input:'text',editor:'line\n  code',confirm:true}[params.method]});
    },
  });
  try {
    await created.session.prompt('/ext_test');
    assert.equal(requests.length,0);
    await created.session.prompt('Call the dialog tool.');
    assert.equal(requests.length,2);
    assert.equal(approvals.length,1);
    assert.ok(approvals[0].title.includes('extension_dialog'));
    assert.ok(requests[0].tools.some(tool => tool.function?.name === 'extension_dialog'));
    const toolMessage = created.session.messages.find(message => message.role === 'toolResult');
    assert.deepEqual(JSON.parse(toolMessage.content[0].text),['B','text','line\n  code',true]);
    assert.deepEqual(calls.map(call => call.method),['select','input','editor','confirm']);
    assert.ok(calls.every(call => call.name === '_nai_extension_ui'));
    assert.ok(notices.some(notice => notice.message === 'command'));
    assert.ok(notices.some(notice => notice.method === 'setStatus'));
    assert.equal(await readFile(join(dirs.cwd,'started.txt'),'utf8'),'started');
  } finally {
    await created.close(); server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
  }
  assert.equal(await readFile(join(dirs.cwd,'closed.txt'),'utf8'),'closed');
});

test('dialog signal, timeout and host Stop release waiters; subsequent dialog works', async () => {
  const observed = [];
  let immediate = false;
  const ui = createStudioExtensionUi((_name,_id,_params,signal) => {
    observed.push(signal);
    if (immediate) return Promise.resolve(result({status:'answered',value:'next'}));
    return new Promise((_resolve,reject) => signal.addEventListener('abort',()=>reject(new Error('cancelled')),{once:true}));
  });
  const parent = new AbortController();
  const waiting = ui.context.input('Question','',{signal:parent.signal});
  parent.abort(); assert.equal(await waiting,undefined);
  assert.equal(await ui.context.input('Timeout','',{timeout:1}),undefined);
  const stopping = ui.context.confirm('Confirm',''); ui.cancel(); assert.equal(await stopping,false);
  assert.ok(observed.every(signal => signal.aborted));
  immediate=true; assert.equal(await ui.context.input('Next'), 'next');
  ui.cancel(true); assert.equal(await ui.context.input('Closed'),undefined);
});

test('broken paths and replacement of Studio tools fail visibly before model requests', async () => {
  const dirs = await paths();
  await assert.rejects(createStudioSession({...dirs, config,systemPrompt:'NAI.',executeTool:async()=>result({}),
    extensionPaths:['relative.ts']}),/absolute paths/);
  await assert.rejects(createStudioSession({...dirs, config,systemPrompt:'NAI.',executeTool:async()=>result({}),
    extensionPaths:[join(dirs.root,'missing.ts')]}),/does not exist/);
  const file=join(dirs.root,'replace.ts');
  await writeFile(file,`import { Type } from 'typebox'; export default pi =>
    pi.registerTool({name:'prompt_update',label:'replace',description:'replace',parameters:Type.Object({}),
      execute:async()=>({content:[],details:{}})});`);
  await assert.rejects(createStudioSession({...dirs,config,systemPrompt:'NAI.',executeTool:async()=>result({}),
    extensionPaths:[file]}),/replace Studio tool/);
});
